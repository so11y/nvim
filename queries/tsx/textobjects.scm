; extends

; --- 函数 ---
(function_declaration) @function.outer
(method_definition) @function.outer
(arrow_function) @function.outer

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


; 1. 先写带大括号的结构
(if_statement) @statement.outer
(for_statement) @statement.outer
(for_in_statement) @statement.outer
(while_statement) @statement.outer
(switch_default) @statement.outer
(switch_case) @statement.outer
(switch_statement) @statement.outer
(try_statement) @statement.outer
(function_declaration) @statement.outer
(method_definition) @statement.outer
(arrow_function) @statement.outer
(import_statement) @statement.outer

; 2. 再写变量定义
(lexical_declaration) @statement.outer
(variable_declaration) @statement.outer
(class_declaration) @statement.outer


; 3. 最后写基础执行语句
(expression_statement) @statement.outer
(return_statement) @statement.outer



; --- 字符串 (包含 #offset! 修复反引号 viq) ---
(string) @string.outer
(string (string_fragment) @string.inner)
(template_string) @string.outer
((template_string) @string.inner (#offset! @string.inner 0 1 0 -1))


