;; extends

((import_statement
  (import_clause
    (identifier) @variable.import)
  source: (string
    (string_fragment) @_source))
  (#lua-match? @_source "%.vue$")
  (#set! priority 105))

((member_expression
  property: (property_identifier) @vscode.member) @_member
  (#not-has-parent? @_member call_expression new_expression)
  (#not-lua-match? @vscode.member "^_*[A-Z]")
  ; Above property tokens (125), below readonly modifiers (127).
  (#set! priority 126))
