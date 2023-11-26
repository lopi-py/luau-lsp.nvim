[
  (fn_stmt)
  (anon_fn)
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
] @indent.begin

[
 "end"
 ")"
 "}"
] @indent.end

(ret_stmt
  (call_stmt)) @indent.dedent

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
] @indent.branch

(comment) @indent.auto

(string) @indent.auto
