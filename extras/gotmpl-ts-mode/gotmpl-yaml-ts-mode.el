;;; gotmpl-yaml-ts-mode.el --- YAML Go Template tree-sitter major mode. -*- lexical-binding: t -*-

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
(declare-function treesit-merge-font-lock-feature-list "treesit")

(require 'gotmpl-ts-mode)
(defvar gotmpl-ts-mode-parser-language)

(require 'yaml-ts-mode)
(defvar yaml-ts-mode--font-lock-settings)
(defvar yaml-ts-mode--font-lock-feature-list)

;;;###autoload
(define-derived-mode gotmpl-yaml-ts-mode gotmpl-ts-mode "GoTmpl[YAML]"
  "Major mode for golang templates within YAML, powered by tree-sitter."
  (when (treesit-ready-p 'yaml)
    (treesit-parser-create 'yaml)
    (setq-local
     treesit-range-settings (append treesit-range-settings
                                    (treesit-range-rules
                                     :embed 'yaml
                                     :host gotmpl-ts-mode-parser-language
                                     '((text) @capture)))
     treesit-font-lock-settings (append treesit-font-lock-settings
                                        yaml-ts-mode--font-lock-settings)
     treesit-font-lock-feature-list (treesit-merge-font-lock-feature-list
                                     treesit-font-lock-feature-list
                                     yaml-ts-mode--font-lock-feature-list))))

(provide 'gotmpl-ts-mode)

;;; gotmpl-yaml-ts-mode.el ends here
