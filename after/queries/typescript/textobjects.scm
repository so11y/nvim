; extends

; --- 循环 ---
(while_statement) @loop.outer
(do_statement) @loop.outer
(for_statement) @loop.outer
(for_in_statement) @loop.outer
(while_statement body: (_) @loop.inner)
(do_statement body: (_) @loop.inner)
(for_statement body: (_) @loop.inner)
(for_in_statement body: (_) @loop.inner)

; --- 语句 ---
(lexical_declaration) @statement.combined
(variable_declaration) @statement.combined
(expression_statement) @statement.combined
(import_statement) @statement.combined
(export_statement) @statement.combined
(if_statement) @statement.combined
(return_statement) @statement.combined
(for_statement) @statement.combined
(while_statement) @statement.combined
(switch_statement) @statement.combined

; --- 字符串 
(string) @string.outer
(template_string) @string.outer
(string (string_fragment) @string.inner)
((template_string) @string.inner (#offset! @string.inner 0 1 0 -1))