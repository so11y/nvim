; extends
(attribute (attribute_name) @name (#eq? @name "v-for")) @loop.outer
(attribute (attribute_name) @name (#any-of? @name "v-if" "v-else-if" "v-else")) @conditional.outer
(element) @statement.outer
