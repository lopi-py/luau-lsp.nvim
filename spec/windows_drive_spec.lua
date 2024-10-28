local util = require "luau-lsp.util"

describe("Windows drive letter", function()
  it("should lower the drive letter on Windows", function()
    util.is_windows = true

    assert.same("c:/foo/bar", util.lower_case_drive "C:/foo/bar")
    assert.same(nil, util.lower_case_drive(nil))
  end)

  it("should not modify anything if not Windows", function()
    util.is_windows = false

    assert.same("C:/foo/bar", util.lower_case_drive "C:/foo/bar")
    assert.same(nil, util.lower_case_drive(nil))
  end)
end)
