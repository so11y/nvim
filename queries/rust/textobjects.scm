; extends

; Closures supplement the upstream function captures.
(closure_expression) @function.outer
(closure_expression body: (_) @function.inner)

; Keep empty loops available to movement and selection.
[
  (for_expression)
  (while_expression)
  (loop_expression)
] @loop.outer

; Macro arguments can also use square or curly delimiters.
((macro_invocation (token_tree) @call.inner)
  (#offset! @call.inner 0 1 0 -1))

; Include declarations and compound statements as movement targets.
[
  (if_expression)
  (match_expression)
  (for_expression)
  (while_expression)
  (loop_expression)
  (function_item)
  (impl_item)
  (mod_item)
  (use_declaration)
  (match_arm)
  (let_declaration)
  (const_item)
  (static_item)
  (struct_item)
  (enum_item)
  (type_item)
  (expression_statement)
  (return_expression)
  (break_expression)
  (continue_expression)
] @statement.outer

; Strings are not defined by the upstream Rust textobjects query.
(string_literal) @string.outer
((string_literal) @string.inner (#offset! @string.inner 0 1 0 -1))
(raw_string_literal) @string.outer
(raw_string_literal (string_content) @string.inner)
