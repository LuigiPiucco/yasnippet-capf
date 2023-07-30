;;; yasnippet-capf.el --- A completion-at-point-function for Yasnippet -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2023 Luigi Sartor Piucco
;;
;; Author: Luigi Sartor Piucco <luigipiucco@gmail.com>
;; Maintainer: Luigi Sartor Piucco <luigipiucco@gmail.com>
;; Created: July 29, 2023
;; Modified: July 30, 2023
;; Version: 0.1.0
;; Keywords: abbrev convenience snippets
;; Homepage: https://github.com/LuigiPiucco/yasnippet-capf
;; Package-Requires: ((emacs "26.1") (yasnippet "0.14.0"))
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; A completion-at-point-function for Yasnippet.
;;
;; Provides the function `yasnippet-capf' to be added to
;; `completion-at-point-functions'. It will add completion candidates to any
;; CAPF based system. There is support for documentation display as well, it
;; shows what the snippet expands to (verbatim).
;;
;;; Code:

(require 'subr-x)
(require 'thingatpt)
(require 'yasnippet)

(defconst yasnippet-capf--buffer-name "*cape-yasnippet expansion*")

(defvar yasnippet-capf--properties
  (list :annotation-function #'yasnippet-capf--annotate
        :company-kind (lambda (_) 'snippet)
        :company-doc-buffer #'yasnippet-capf--doc-buffer
        :exit-function #'yasnippet-capf--exit
        :exclusive 'no)
  "Return a list of extra properties for snippet completions.")

(defun yasnippet-capf--exit (_ status)
  "Actually expand the snippet, if STATUS is \"finished\"."
  (when (string= "finished" status)
    (yas-expand)))

(defun yasnippet-capf--doc-buffer (cand)
  "Calculate the expansion of the snippet for CAND.
Returns a buffer to be displayed by popupinfo."
  (when-let ((maj-mode major-mode)
             (buf (get-buffer-create yasnippet-capf--buffer-name)))
    (with-current-buffer buf
      (erase-buffer)
      (funcall maj-mode)
      (yas-minor-mode)
      (save-excursion
        (insert cand)
        (yas-expand)
        (when-let ((snips (yas-active-snippets)))
            (dolist (snip snips)
              (yas-exit-snippet snip)))
        (font-lock-ensure))
      (insert "Expands to:" ?\n ?\n)
      (current-buffer))))

(defun yasnippet-capf--annotate (cand)
  "Return annotation for CAND."
  (format " (Expand \"%s\")" (substring-no-properties cand)))

(defun yasnippet-capf--eval-const (fun)
  "Evaluate FUN and return a function which always gives back the result.
The returned function may take any number of arguments, it will ignore them."
  (let ((ev (funcall fun)))
    (lambda (&rest _) ev)))

;;;###autoload
(defun yasnippet-capf (&optional interactive)
  "Complete with yasnippet at point.
If INTERACTIVE is nil the function acts like a CAPF."
  (interactive (list t))
  (if interactive
      (let ((completion-at-point-functions #'yasnippet-capf))
        (unless (completion-at-point)
          (user-error "yasnippet-capf: No completions")))
    (when (thing-at-point-looking-at "\\(?:\\sw\\|\\s_\\)+")
      (let ((beg (match-beginning 0))
            (end (match-end 0)))
        `(,beg ,end
          ,(completion-table-dynamic (yasnippet-capf--eval-const #'yas-active-keys) t)
          ,@yasnippet-capf--properties)))))

(provide 'yasnippet-capf)
;;; yasnippet-capf.el ends here
