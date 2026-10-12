;; extends

; The Vue parser represents the suffix in </Dialog.Drawer> as an error node.
(end_tag
  (tag_name)
  .
  (ERROR
    "."
    .
    (ERROR) @tag.component)
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
