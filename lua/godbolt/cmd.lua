local function build_cmd(compiler, text, options, exec_asm_3f)
  local json = vim.json.encode({source = text, options = options})
  local config = require("godbolt").config
  local file = io.open(string.format("godbolt_request_%s.json", exec_asm_3f), "w")
  file:write(json)
  io.close(file)
  return string.format(("curl %s/api/compiler/\"%s\"/compile" .. " --data-binary @godbolt_request_%s.json" .. " --header \"Accept: application/json\"" .. " --header \"Content-Type: application/json\"" .. " --output godbolt_response_%s.json"), config.url, compiler, exec_asm_3f, exec_asm_3f)
end
---@param opts? table
local function godbolt(begin, _end, reuse_3f, compiler, opts)
  local pre_display = require("godbolt.assembly")["pre-display"]
  local execute = require("godbolt.execute").execute
  local fuzzy = require("godbolt.fuzzy").fuzzy
  local ft = vim.bo.filetype
  if opts and opts.ft then
    ft = opts.ft
  end
  local config = require("godbolt").config
  local compiler0 = (compiler or config.languages[ft].compiler)
  local options
  if config.languages[ft] then
    options = vim.deepcopy(config.languages[ft].options)
  else
    options = {}
  end
  local flags = opts.flags or vim.fn.input({prompt = "Flags: ", default = (options.userArguments or "")})
  options["userArguments"] = flags
  local fuzzy_3f
  do
    local matches = false
    for _, v in pairs({"telescope", "fzflua", "snacks_picker"}) do
      if (v == compiler0) then
        matches = true
      else
        matches = matches
      end
    end
    fuzzy_3f = matches
  end
  if fuzzy_3f then
    return fuzzy(compiler0, ft, begin, _end, options, (true == vim.b.godbolt_exec), reuse_3f)
  else
    opts = opts or {}
    opts.asm = opts.asm or {}
    pre_display(begin, _end, compiler0, options, reuse_3f, opts.asm)
    if opts and opts.exec then
      opts = opts or {}
      opts.out = opts.out or {}
      return execute(begin, _end, compiler0, options, reuse_3f, opts.out)
    else
      return nil
    end
  end
end
return {["build-cmd"] = build_cmd, godbolt = godbolt}
