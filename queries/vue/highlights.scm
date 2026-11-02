;; extends

; Dotted component members are parsed as directives on opening tags and errors
; on closing tags. Give both the same syntax color, excluding <input .value>.
([
  (start_tag
    (tag_name)
    .
    (directive_attribute) @variable.member)
  (self_closing_tag
    (tag_name)
    .
    (directive_attribute) @variable.member)
  (end_tag
    (tag_name)
    .
    (ERROR) @variable.member)
] @_tag
  (#lua-match? @_tag "^</?[^%s/>]+%.")
  (#set! priority 105))

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
