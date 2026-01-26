; extends
(attribute (attribute_name) @name (#eq? @name "v-for")) @loop.outer
(attribute (attribute_name) @name (#any-of? @name "v-if" "v-else-if" "v-else")) @conditional.outer
(element) @statement.outer
(quoted_attribute_value) @string.outer
(attribute_value) @string.inner

(script_element (start_tag (tag_name) @string.outer))
(script_element (start_tag (tag_name) @string.inner))