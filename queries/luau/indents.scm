[
  (fn_stmt)
  (callback)
  (local_fn_stmt)
  (do_stmt)
  (while_stmt)
  (repeat_stmt)
  (if_stmt)
  (for_in_stmt)
  (for_range_stmt)
  (table)
  (tbtype)
  (arglist)
] @indent

[
 "end"
 ")"
 "}"
] @indent_end

(ret_stmt
  (call_stmt)) @dedent

[
 "end"
 "then"
 "until"
 "}"
 ")"
 "elseif"
 (elseif_clause)
 "else"
 (else_clause)
] @branch

(comment) @auto

(string) @auto
