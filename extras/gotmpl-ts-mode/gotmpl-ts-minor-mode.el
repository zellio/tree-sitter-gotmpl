;;; gotmpl-ts-minor-mode.el --- Go Template tree-sitter minor mode -*- lexical-binding: t -*-

;; Author: Zachary Elliott <contact@zell.io>
;; Maintainer: Zachary Elliott <contact@zell.io>
;; Version: 0.1.0
;; Package-Requires: ((emacs "30"))
;; Homepage: https://github.com/zellio/tree-sitter-gotmpl
;; Keywords: go gotemplate gotmpl languages tree-sitter

;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This mode is tightly coupled to the parent tree-sitter grammar.

;;; Code:

(require 'treesit)
(eval-when-compile (require 'rx))

(declare-function treesit-major-mode-setup "treesit")
(declare-function treesit-merge-font-lock-feature-list "treesit")
(declare-function treesit-node-at "treesit")
(declare-function treesit-node-type "treesit.c")
(declare-function treesit-parser-create "treesit.c")
(declare-function treesit-parser-delete "treesit.c")
(declare-function treesit-parser-language "treesit.c")
(declare-function treesit-range-rules "treesit")

(require 'gotmpl-ts-mode)
(defvar gotmpl-ts-mode-parser-language)
(defvar gotmpl-ts-mode--font-lock-settings)
(defvar gotmpl-ts-mode--font-lock-feature-list)

(defcustom gotmpl-ts-minor-mode-name-transform-function #'gotmpl-ts-minor-mode-name-transform-default
  "A function that returns a transformed mode NAME.

This is used by `gotmpl-ts-minor-mode' to transform the parent
major-mode display name to indicate minor-mode operation.

The function is called with one argument, generally the current value of
`mode-name'."
  :type 'function
  :group 'go)

(defun gotmpl-ts-minor-mode-name-transform-default (name)
  "Default function for `gotmpl-ts-minor-mode-name-tranform'.

Returns the current NAME wrapped in \"GoTmpl[]\""
  (format "GoTmpl[%s]" name))

(defun gotmpl-ts-minor-mode--range-settings (&optional language)
  "Generate `treesit-range-settings' for `gotmpl-ts-minor-mode' from LANGUAGE."
  (treesit-range-rules
   :embed language
   :host gotmpl-ts-mode-parser-language
   '((text) @capture)))

(defvar gotmpl-ts-minor-mode--embedded-language nil)

(defun gotmpl-ts-minor-mode--language-at-point (point)
  "Identify the target language at POINT.

Used for `treesit-language-at-point-function' in `gotmpl-ts-minor-mode'.

Anything which is within a \"text\" node is considered the original
buffer language, everything else is `gotmpl'."
  (let* ((node (treesit-node-at point gotmpl-ts-mode-parser-language)))
    (pcase (treesit-node-type node)
      ("text" gotmpl-ts-minor-mode--embedded-language)
      (_ gotmpl-ts-mode-parser-language))))

(defvar gotmpl-ts-minor-mode--state nil)

(defun gotmpl-ts-minor-mode--capture-buffer (&optional buffer)
  "Inject `gotmpl-ts-minor-mode' ontop of current BUFFER tree-sitter mode."
  (with-current-buffer (or buffer (current-buffer))
    (let* ((parser treesit-primary-parser)
           (language (treesit-parser-language parser)))
      (setq-local
       gotmpl-ts-minor-mode--state
       (buffer-local-set-state
        gotmpl-ts-minor-mode--embedded-language language
        treesit-range-settings (gotmpl-ts-minor-mode--range-settings language)
        treesit-language-at-point-function #'gotmpl-ts-minor-mode--language-at-point
        treesit-font-lock-settings (append (apply #'treesit-font-lock-rules gotmpl-ts-mode--font-lock-settings) treesit-font-lock-settings)
        treesit-font-lock-feature-list (treesit-merge-font-lock-feature-list treesit-font-lock-feature-list gotmpl-ts-mode--font-lock-feature-list)
        mode-name (funcall gotmpl-ts-minor-mode-name-transform-function mode-name)))
      (treesit-parser-delete parser)
      (setq-local treesit-primary-parser (treesit-parser-create gotmpl-ts-mode-parser-language))
      (treesit-parser-create language)
      (treesit-major-mode-setup)
      (font-lock-update))))

(defun gotmpl-ts-minor-mode--release-buffer (&optional buffer)
  "Remove `gotmpl-ts-minor-mode' from current BUFFER tree-sitter mode."
  (with-current-buffer (or buffer (current-buffer))
    (treesit-parser-delete (treesit-parser-create gotmpl-ts-minor-mode--embedded-language))
    (treesit-parser-delete treesit-primary-parser)
    (setq-local treesit-primary-parser (treesit-parser-create gotmpl-ts-minor-mode--embedded-language))
    (buffer-local-restore-state gotmpl-ts-minor-mode--state)
    (treesit-major-mode-setup)
    (font-lock-update)))

;;;###autoload
(define-minor-mode gotmpl-ts-minor-mode
  "Minor mode for editing golang templates, powered by tree-sitter."
  :group 'go
  :global nil
  :lighter ""
  (if gotmpl-ts-minor-mode
      (gotmpl-ts-minor-mode--capture-buffer)
    (gotmpl-ts-minor-mode--release-buffer)))

(provide 'gotmpl-ts-minor-mode)

;;; gotmpl-ts-minor-mode.el ends here
