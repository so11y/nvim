;; extends

; Keep template tag names above LSP semantic colors.
((tag_name) @tag
  (#set! priority 130))

; The parser treats .Drawer (and further members) as a directive.
([
  (start_tag
    (tag_name)
    .
    (directive_attribute) @tag)
  (self_closing_tag
    (tag_name)
    .
    (directive_attribute) @tag)
] @_tag
  ; Whitespace distinguishes a real property binding: <input .value="value">.
  (#lua-match? @_tag "^<[^%s>]+%.")
  (#set! priority 130))

; The Vue parser represents the suffix in </Dialog.Drawer> as an error node.
(end_tag
  (tag_name)
  .
  (ERROR
    ".") @tag
  (#set! priority 130))

((directive_name) @keyword.conditional
  (#any-of? @keyword.conditional "v-if" "v-else-if" "v-else")
  (#set! priority 105))

((directive_name) @keyword.repeat
  (#eq? @keyword.repeat "v-for")
  (#set! priority 105))

("@"
  .
  (directive_value) @tag.attribute.event
  (#set! priority 105))

("#"
  .
  (directive_value) @tag.attribute.slot
  (#set! priority 105))
