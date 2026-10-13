; extends

((element
  (_ (directive_attribute (directive_name) @_directive))) @loop.outer
  (#eq? @_directive "v-for"))

((element
  (start_tag (directive_attribute (directive_name) @_directive)) @_start
  (end_tag) @_end) @loop.inner
  (#eq? @_directive "v-for")
  (#textobject-between! @loop.inner @_start @_end))

((element
  (_ (directive_attribute (directive_name) @_directive))) @conditional.outer
  (#any-of? @_directive "v-if" "v-else-if" "v-else"))

((element
  (start_tag (directive_attribute (directive_name) @_directive)) @_start
  (end_tag) @_end) @conditional.inner
  (#any-of? @_directive "v-if" "v-else-if" "v-else")
  (#textobject-between! @conditional.inner @_start @_end))

(element) @statement.outer
