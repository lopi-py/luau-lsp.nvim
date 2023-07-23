;; Keywords

"return" @keyword.return

[
 "in"
 "local"
] @keyword

(break_stmt) @keyword
(continue_stmt) @keyword

(do_stmt
[
  "do"
  "end"
] @keyword)

(while_stmt
[
  "while"
  "do"
  "end"
] @repeat)

(repeat_stmt
[
  "repeat"
  "until"
] @repeat)

(if_stmt
[
  "if"
  "elseif"
  "else"
  "then"
  "end"
] @conditional)

(elseif_clause
[
  "elseif"
  "then"
  "end"
] @conditional)

(else_clause
[
  "else"
  "end"
] @conditional)

(for_in_stmt
[
  "for"
  "do"
  "end"
] @repeat)

(for_range_stmt
[
  "for"
  "do"
  "end"
] @repeat)

(fn_stmt
[
  "function"
  "end"
] @keyword.function)

(local_fn_stmt
[
 "function"
 "end"
] @keyword.function)

(anon_fn
[
  "function"
  "end"
] @keyword.function)

;; Operators

[
 "and"
 "not"
 "or"
] @keyword.operator

(ifexp
[
 "if"
 "then"
 "elseif"
 "else"
] @keyword.operator)

(type_stmt
[
 "export"
 "type"
] @keyword)

[
  "+"
  "-"
  "*"
  "/"
  "%"
  "^"
  "#"
  "=="
  "~="
  "<="
  ">="
  op: "<"
  op: ">"
  "="
  "&"
  "|"
  "+="
  "-="
  "*="
  "/="
  "%="
  "^="
  "->"
  "::"
  ".."
] @operator

;; Punctuations
[
  ";"
  ":"
  ","
  "."
] @punctuation.delimiter

;; Brackets

[
 "("
 ")"
 "["
 "]"
 "{"
 "}"
] @punctuation.bracket

;; Variables

(var (name) @variable)

((var (name) @variable.global
  (#any-of? @variable.global
  "_G" "_VERSION")))
((var (name) @variable.builtin
  (#any-of? @variable.builtin
  "self")))

;; Constants

((name) @constant
 (#lua-match? @constant "^[A-Z][A-Z_0-9]*$"))

(exp (vararg) @constant)

(nil) @constant.builtin

(boolean) @boolean

;; Tables

(field key: (name) @field)

(var field: (name) @field)

(table
[
  "{"
  "}"
] @constructor)

;; Types

; declaration
(type_stmt (name) @type.definition)

(generic (name) @type.qualifier)

(namedtype . (name) @type.builtin !module
  (#any-of? @type.builtin
    "number" "string" "any" "never" "unknown" "boolean" "thread" "userdata"))
(namedtype . module: (name) @namespace . (name) @type)
(namedtype . (name) @type !module)

(tbtype prop: (name) @property)

;; Top-level functions

(var . (name) @function.builtin !table
  (#any-of? @function.builtin
    "assert" "collectgarbage" "error" "gcinfo" "getfenv" "getmetatable" "ipairs"
    "loadstring" "next" "newproxy" "pairs" "pcall" "print"
    "rawequal" "rawget" "rawlen" "rawset" "require" "select" "setfenv" "setmetatable"
    "tonumber" "tostring" "type" "typeof" "unpack" "xpcall"))
; bit32
(_ table: (name) @variable.builtin
     (#eq? @variable.builtin "bit32")
     field: (name) @function.builtin
     (#any-of? @function.builtin
      "arshift" "lrotate" "lshift" "replace" "rrotate" "rshift"
      "btest" "bxor" "band" "bnot" "bor" "countlz" "countrz" "extract"))
; coroutine
(_ table: (name) @variable.builtin
     (#eq? @variable.builtin "coroutine")
     field: (name) @function.builtin
     (#any-of? @function.builtin
      "close" "create" "isyieldable" "resume" "running"
      "status" "wrap" "yield"))
; debug
(_ table: (name) @variable.builtin
     (#eq? @variable.builtin "debug")
     field: (name) @function.builtin
     (#any-of? @function.builtin
      "info" "traceback" "profilebegin" "profileend"
      "resetmemorycategory" "setmemorycategory"))
; math
(_ table: (name) @variable.builtin
     (#eq? @variable.builtin "math")
      field: (name) @function.builtin
      (#any-of? @function.builtin
       "abs" "acos" "asin" "atan" "atan2" "ceil" "clamp" "cos"
       "cosh" "deg" "exp" "floor" "fmod" "frexp" "ldexp" "log"
       "log10" "max" "min" "modf" "noise" "pow" "rad" "random"
       "randomseed" "round" "sign" "sin" "sinh" "sqrt" "tan" "tanh"))
; math constants
(_ table: (name) @variable.builtin
     (#eq? @variable.builtin "math")
     field: (name) @constant.builtin
      (#any-of? @constant.builtin
       "huge" "pi"))
; os
(_ table: (name) @variable.builtin
     (#eq? @variable.builtin "os")
     field: (name) @function.builtin
     (#any-of? @function.builtin
      "clock" "date" "difftime" "time"))
; string
(_ table: (name) @variable.builtin
     (#eq? @variable.builtin "string")
     field: (name) @function.builtin
     (#any-of? @function.builtin
      "byte" "char" "find" "format" "gmatch" "gsub" "len" "lower"
      "match" "pack" "packsize" "rep" "reverse" "split" "sub" "unpack" "upper"))
; table
(_ table: (name) @variable.builtin
     (#eq? @variable.builtin "table")
     field: (name) @function.builtin
     (#any-of? @function.builtin
      "create" "clear" "clone" "concat" "foreach" "foreachi" "find" "freeze"
      "getn" "insert" "isfrozen" "maxn" "move" "pack" "remove" "sort" "unpack"))
; task
(_ table: (name) @variable.builtin
     (#eq? @variable.builtin "task")
     field: (name) @function.builtin
     (#any-of? @function.builtin
      "cancel" "defer" "delay" "desynchronze" "spawn" "wait"))
; utf8
(_ table: (name) @variable.builtin
     (#eq? @variable.builtin "utf8")
     field: (name) @function.builtin
     (#any-of? @function.builtin
      "char" "codepoint" "codes" "len" "offset" "graphemes" "nfcnormalize" "nfdnormalize"))

(_ table: (name) @variable.builtin 
   (#eq? @variable.builtin "utf8")
   . (name) @constant.builtin
   (#eq? @constant.builtin "charpattern"))

;; Functions

(param (name) @parameter)

(call_stmt invoked: (var (name) @function.call .))
(call_stmt method: (name) @method.call)
(fn_stmt name: (name) @function)
(fn_stmt method: (name) @method)
(local_fn_stmt (name) @function)      

;(var table: (name) @variable.builtin
;  (#any-of? @variable.builtin
;    "bit32" "coroutine" "debug" "math" "os" "string" "table" "utf8"))

;; Others

(comment) @comment @spell

; (hash_bang_line) @comment

(number) @number

(interp_start) @punctuation
(interp_content) @string
(interp_brace_open) @punctuation.bracket
(interp_brace_close) @punctuation.bracket
(interp_end) @punctuation
(string) @string @spell

;; Error
(ERROR) @error
