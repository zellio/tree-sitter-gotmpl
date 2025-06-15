;; Keywords
["if" "else" "end" "range" "break" "continue" "template" "block" "define" "with"] @keyword

;; Constants
[(nil) "true" "false"] @constant.builtin

;; Variable
(variable (identifier) @variable)
(assignment left: (variable (identifier) @variable))

;; Property
(field (identifier) @property)
(key (identifier) @property)

;; Functions
(function_call function: (identifier) @function)
(function_call function: (builtin) @function.builtin)

;; String
(string) @string

;; Character
(rune) @character

(string (escape_sequence) @string.escape)

;; Number
[(integer) (float) (imaginary)] @number

;; Operators
[":=" "=" "|"] @operator

;; Brackets
["{{" "}}" "{{- " " -}}" "(" ")"] @punctuation.bracket

;; Delimiters
["."] @punctuation.delimiter

;; Comments
(comment) @comment

;; Errors
(ERROR) @error
