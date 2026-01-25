; extends

; --- 技巧：不要直接绑定到整个 script_element ---
; 我们把它绑定到标签名 (tag_name) 上，即 "script" 这几个字母
; 这样做有两个好处：
; 1. 激活了 vas/vis 菜单。
; 2. 因为这个节点很小，当你按下 vas 时，Treesitter 会发现内部注入的 TS 节点更匹配，
;    从而“穿透”到内部去选 const。

;(script_element (start_tag (tag_name) @statement.combined))
;(script_element (start_tag (tag_name) @statement.combined.inner))
(script_element (start_tag (tag_name) @conditional.outer))
(script_element (start_tag (tag_name) @conditional.inner))
(script_element (start_tag (tag_name) @loop.outer))
(script_element (start_tag (tag_name) @loop.inner))
(script_element (start_tag (tag_name) @string.outer))
(script_element (start_tag (tag_name) @string.inner))