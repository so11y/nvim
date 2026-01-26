; extends

; --- 函数 ---
(function_declaration) @function.outer
(function_declaration) @function.inner
(method_definition) @function.outer
(method_definition) @function.inner
(arrow_function) @function.outer
(arrow_function) @function.inner

; --- 循环 (包含 for 和 while) ---
(for_statement) @loop.outer
(while_statement) @loop.outer
(do_statement) @loop.outer
(for_in_statement) @loop.outer

; --- 条件 (包含 if 和 switch) ---
(if_statement) @conditional.outer
(switch_statement) @conditional.outer

; --- 方法调用 ---
(call_expression) @call.outer
(call_expression arguments: (arguments) @call.inner)

; --- 语句 (用于 as/is) ---
(expression_statement) @statement.outer
(variable_declaration) @statement.outer
(lexical_declaration) @statement.outer
(return_statement) @statement.outer

; --- 字符串 (包含 #offset! 修复反引号 viq) ---
(string) @string.outer
(string (string_fragment) @string.inner)
(template_string) @string.outer
((template_string) @string.inner (#offset! @string.inner 0 1 0 -1))