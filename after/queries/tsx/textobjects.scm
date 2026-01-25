; extends

; 将 while 循环关联到 loop 标签
(while_statement) @loop.outer
(while_statement) @loop.inner

; 将 do...while 循环也关联上（可选）
(do_statement) @loop.outer

(for_in_statement) @loop.outer


; --- 字符串支持 (String) ---
; --- 1. 外部 (Outer): 整个字符串 ---
(string) @string.outer
(template_string) @string.outer
; --- 2. 内部 (Inner): 字符串内容 ---
(string (string_fragment) @string.inner)
((template_string) @string.inner
 (#offset! @string.inner 0 1 0 -1))



 ; 下面这些节点，统统算作 @statement.combined
(lexical_declaration) @statement.combined
(variable_declaration) @statement.combined
(if_statement) @statement.combined
(return_statement) @statement.combined
(if_statement) @statement.combined
(for_statement) @statement.combined
(while_statement) @statement.combined
(switch_statement) @statement.combined
(try_statement) @statement.combined