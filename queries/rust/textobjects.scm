; --- 函数 (Functions) ---
; 普通函数 fn foo() {}
(function_item) @function.outer
(function_item body: (block) @function.inner)

; 闭包 (类似箭头函数) |x| { ... }
(closure_expression) @function.outer
(closure_expression body: (_) @function.inner)

; --- 循环 (Loops) ---
(for_expression) @loop.outer
(while_expression) @loop.outer
(loop_expression) @loop.outer ; 对应 loop {} 无限循环

; --- 条件 (Conditionals) ---
(if_expression) @conditional.outer
(match_expression) @conditional.outer ; 对应 JS 的 switch

; --- 调用 (Calls) ---
; 普通函数调用 foo()
(call_expression) @call.outer
(call_expression arguments: (arguments) @call.inner)

; 宏调用 println!() - Rust 特有
(macro_invocation) @call.outer
(macro_invocation (token_tree) @call.inner)


; --- 语句 (Statements) ---
; 1. 也是先写带大括号的结构 (保证 ]s 跳转体验)
(if_expression) @statement.outer
(match_expression) @statement.outer
(for_expression) @statement.outer
(while_expression) @statement.outer
(loop_expression) @statement.outer
(function_item) @statement.outer     ; 让函数也能被 ]s 跳到
(impl_item) @statement.outer         ; impl 块
(mod_item) @statement.outer          ; mod 模块定义
(use_declaration) @statement.outer   ; import 语句

; match 的分支 (类似 case)
(match_arm) @statement.outer

; 2. 变量定义
(let_declaration) @statement.outer
(const_item) @statement.outer
(static_item) @statement.outer
(struct_item) @statement.outer
(enum_item) @statement.outer
(type_item) @statement.outer       ; type alias

; 3. 基础语句
(expression_statement) @statement.outer ; 带分号的表达式
(return_expression) @statement.outer    ; return
(break_expression) @statement.outer
(continue_expression) @statement.outer

; --- 参数 (Parameters) ---
(parameters) @parameter.outer
(parameter) @parameter.inner

; --- 字符串 (Strings) ---
(string_literal) @string.outer
; Rust 的 raw string r#"..."#
(raw_string_literal) @string.outer

; --- 注释 (Comments) ---
(line_comment) @comment.outer
(block_comment) @comment.outer
