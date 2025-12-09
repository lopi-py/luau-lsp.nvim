rockspec_format = "3.0"
package = "luau-lsp.nvim"
version = "scm-1"

source = {
  url = "git://github.com/lopi-py/luau-lsp.nvim",
}

dependencies = {
  "lua == 5.1",
  "plenary.nvim",
}

test_dependencies = {
  "nlua",
}
