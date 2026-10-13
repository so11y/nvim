; Include empty loops and bodies without braces.
(for_statement) @loop.outer
(while_statement) @loop.outer
(do_statement) @loop.outer
(for_in_statement) @loop.outer

; Preserve parenthesized arguments, including empty calls.
(call_expression arguments: (arguments) @call.inner)

; Statements and declarations not captured by upstream ecma.
(switch_default) @statement.outer
(switch_case) @statement.outer
(switch_statement) @statement.outer
(try_statement) @statement.outer
(function_declaration) @statement.outer
(method_definition) @statement.outer
(arrow_function) @statement.outer
(import_statement) @statement.outer

(variable_declaration) @statement.outer
(class_declaration) @statement.outer
