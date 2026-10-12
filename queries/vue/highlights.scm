;; extends

([
  (start_tag
    (tag_name)
    .
    (directive_attribute
      "."
      .
      (directive_value) @tag.component))
  (self_closing_tag
    (tag_name)
    .
    (directive_attribute
      "."
      .
      (directive_value) @tag.component))
] @_tag
  ; The Vue parser treats .Drawer in <Dialog.Drawer> as a directive.
  (#lua-match? @_tag "^<[^%s>]+%.")
  (#set! priority 131))

((end_tag
  (tag_name)
  .
  (ERROR
    "."
    .
    (ERROR) @tag.component)) @_tag
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
