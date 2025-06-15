;;; gotmpl-ts-mode.el --- Go Templates tree-sitter major mode. -*- lexical-binding: t -*-

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
(declare-function treesit-ready-p "treesit")

(defcustom gotmpl-ts-mode-parser-language 'gotmpl
  "Tree sitter grammar language name."
  :type 'symbol
  :safe 'symbolp
  :group 'go)

(defcustom gotmpl-ts-mode-indent-offset 0
  "Number of spaces for each indentation step in `gotmpl-ts-mode'."
  :type 'integer
  :safe 'integerp
  :group 'go)


;;; Indentation

(defconst gotmpl-ts-mode--simple-indent-rules
  `((gotmpl ((parent-is "source_file") column-0 0)))
  "`treesit-simple-indent-rules' for `gotmpl-ts-mode'.")

;;; Font lock

(defconst gotmpl-ts-mode--font-lock-settings
  `(:language ,gotmpl-ts-mode-parser-language
    :feature keyword
    (["if" "else" "end" "range" "break" "continue" "template" "block" "define" "with"]
     @font-lock-keyword-face)

    :language ,gotmpl-ts-mode-parser-language
    :feature constant
    ([(nil) "true" "false"] @font-lock-constant-face)

    :language ,gotmpl-ts-mode-parser-language
    :feature variable
    ((variable (identifier) @font-lock-variable-use-face)
     (assignment left: (variable (identifier) @font-lock-variable-name-face)))

    :language ,gotmpl-ts-mode-parser-language
    :feature property
    ((field (identifier) @font-lock-property-use-face)
     (key (identifier) @font-lock-property-use-face))

    :language ,gotmpl-ts-mode-parser-language
    :feature function
    ((function_call function: (identifier) @font-lock-function-call-face)
     (function_call function: (builtin) @font-lock-builtin-face))

    :language ,gotmpl-ts-mode-parser-language
    :feature string
    ([(rune) (string)] @font-lock-string-face)

    :language ,gotmpl-ts-mode-parser-language
    :override t
    :feature escape-sequence
    ((string (escape_sequence) @font-lock-escape-face))

    :language ,gotmpl-ts-mode-parser-language
    :feature number
    ([(integer) (float) (imaginary)] @font-lock-number-face)

    :language ,gotmpl-ts-mode-parser-language
    :feature operator
    ((assignment operator: [":=" "=" "|"] @font-lock-operator-face))

    :language ,gotmpl-ts-mode-parser-language
    :feature bracket
    (["{{" "}}" "{{- " " -}}" "(" ")"] @font-lock-bracket-face)

    :language ,gotmpl-ts-mode-parser-language
    :feature delimiter
    (["."] @font-lock-delimiter-face)

    :language ,gotmpl-ts-mode-parser-language
    :override t
    :feature comment
    ((comment) @font-lock-comment-face)

    :language ,gotmpl-ts-mode-parser-language
    :override t
    :feature error
    ((ERROR) @font-lock-warning-face))
  "`treesit-font-lock-rules' for `gotmpl-ts-mode'.")

(defconst gotmpl-ts-mode--font-lock-feature-list
  '((comment)
    (keyword string)
    (builtin constant escape-sequence number)
    (bracket delimiter error function  property operator variable))
  "`treesit-font-lock-feature-list' for `gotmpl-ts-mode'.")

;;; Imenu

(defun gotmpl-ts-mode--simple-node-ident (node)
  "Extract Action type of NODE."
  (car (split-string (treesit-node-type node) "_")))

(defconst gotmpl-ts-mode--simple-imenu-settings
  `(("Action" ,(rx "_action" string-end) nil gotmpl-ts-mode--simple-node-ident)
    ("Text" ,(rx string-start "text" string-end) nil nil))
  "`treesit-simple-imenu-settings' for `gotmpl-ts-mode'.")

;;; Outline minor mode

(defun gotmpl-ts-mode--outline-predicate (_node)
  "Match outlines when NODE is a block opener.")

;;; Things

(defconst gotmpl-ts-mode--thing-settings
  `((gotmpl
     (comment ,(rx string-start "comment" string-end))
     (string ,(rx string-start "string" string-end))
     (text ,(rx string-start (or "comment" "string") string-end))
     (sexp ,(rx string-start "statement" string-end))
     (sentence
      ,(rx (or (seq "_action" string-end)
               (seq string-start (or "statement" "text") string-end))))))
  "`treesit-thing-settings' for `gotmpl-ts-mode'.")

;;; Mode

(defvar-keymap gotmpl-ts-mode-map
  :doc "Keymap for `gotmpl-ts-mode'."
  :parent prog-mode-map)

;;;###autoload
(define-derived-mode gotmpl-ts-mode prog-mode "GoTmpl"
  "Major mode for editing golang templates, powered by tree-sitter."
  :group 'go
  :syntax-table nil
  (when (treesit-ready-p 'gotmpl)
    (treesit-parser-create 'gotmpl)

    (setq-local
     treesit-font-lock-settings (apply #'treesit-font-lock-rules gotmpl-ts-mode--font-lock-settings)
     treesit-font-lock-feature-list gotmpl-ts-mode--font-lock-feature-list
     treesit-simple-indent-rules gotmpl-ts-mode--simple-indent-rules
     treesit-simple-imenu-settings gotmpl-ts-mode--simple-imenu-settings
     treesit-defun-type-regexp nil
     treesit-defun-name-function nil
     treesit-outline-predicate #'gotmpl-ts-mode--outline-predicate
     treesit-thing-settings gotmpl-ts-mode--thing-settings)

    (treesit-major-mode-setup)))

(provide 'gotmpl-ts-mode)

;;; gotmpl-ts-mode.el ends here
