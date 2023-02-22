; defined in part due to:
; (1) https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/lua/locals.scm
; global spec:
; (2) https://tree-sitter.github.io/tree-sitter/using-parsers#pattern-matching-with-queries
; nvim extended spec:
; (3) https://github.com/nvim-treesitter/nvim-treesitter/blob/master/CONTRIBUTING.md#parser-configurations

; Scopes

[
 (chunk)
 (do_stmt)
 (if_stmt)
 (while_stmt)
 (repeat_stmt)
 (for_range_stmt)
 (for_in_stmt)
 (fn_stmt)
 (local_fn_stmt)
 (callback)
] @local.scope

; Definitions

(var_stmt
  (var (name) @local.definition))

(local_var_stmt
  (binding (name) @local.definition))

;(var_stmt
;  (var
;    table: (name)
;    (field (name) @definition.associated)
;    name: (name) @definition.var .))

(fn_stmt
  . name: (name) @local.definition)
  (#set! definition.function.scope "parent")

(local_fn_stmt
  (name) @local.definition)

(fn_stmt
  method: (name) @definition.function)
  (#set! definition.method.scope "parent")

(for_in_stmt
  (binding (name) @local.definition))

(for_range_stmt
  . (binding (name) @local.definition))

(param (name) @local.definition)

(param (vararg) @local.definition)

; References

[
  (name)
] @local.reference
