;; extends

((import_statement
  "type"
  (import_clause
    (identifier) @type))
  (#set! priority 110))

((union_type
  "|" @operator)
  (#set! priority 105))

((intersection_type
  "&" @operator)
  (#set! priority 105))
