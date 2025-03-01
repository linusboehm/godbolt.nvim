local M = {}

function M.build_cmd(compiler, text, options, exec_asm_3f)
  local json = vim.json.encode({ source = text, options = options })
  local url = require("godbolt").config.url
  local file = io.open(string.format("godbolt_request_%s.json", exec_asm_3f), "w")
  file:write(json)
  io.close(file)
  return string.format(
    (
      'curl %s/api/compiler/"%s"/compile'
      .. " --data-binary @godbolt_request_%s.json"
      .. ' --header "Accept: application/json"'
      .. ' --header "Content-Type: application/json"'
      .. " --output godbolt_response_%s.json"
    ),
    url,
    compiler,
    exec_asm_3f,
    exec_asm_3f
  )
end

---@param begin integer
---@param end_line integer
---@param compiler string
---@param opts table
function M.godbolt(begin, end_line, opts)
  local ft = vim.bo.filetype
  if opts and opts.ft then
    ft = opts.ft
  end
  if opts.fuzzy then
    return require("godbolt.fuzzy").fuzzy(ft, begin, end_line, opts)
  else
    return require("godbolt.assembly").pre_display(ft, begin, end_line, opts)
  end
end
return M
