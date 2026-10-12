;; extends

((tag_name) @tag
  ; Keep template tag names above LSP semantic colors.
  (#set! priority 130))

([
  (start_tag
    (tag_name) @tag.component
    .
    (directive_attribute) @tag.component)
  (self_closing_tag
    (tag_name) @tag.component
    .
    (directive_attribute) @tag.component)
] @_tag
  ; The Vue parser treats .Drawer in <Dialog.Drawer> as a directive.
  (#lua-match? @_tag "^<[^%s>]+%.")
  (#set! priority 131))

((end_tag
  (tag_name) @tag.component
  .
  (ERROR) @tag.component) @_tag
  ; The same component suffix is an error node in </Dialog.Drawer>.
  (#lua-match? @_tag "^</[^%s>]+%.")
  (#set! priority 131))

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
