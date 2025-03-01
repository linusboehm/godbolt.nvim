M = {}

---@param opts table
local function display_output(response, opts)
  local function collect_output(output)
    local result = {}
    for _, v in pairs(output) do
      if v.text then
        table.insert(result, v.text)
      end
    end
    return result
  end

  local stdout = collect_output(response.stdout)
  local stderr = collect_output(response.stderr)
  stdout = (stdout and next(stdout) ~= nil) and stdout or {"---"}
  stderr = (stderr and next(stderr) ~= nil) and stderr or {"---"}

  local lines = {
    "exit code: " .. response.code,
    "stdout:",
    table.unpack(stdout),
    "stderr:",
    table.unpack(stderr),
  }
  vim.api.nvim_buf_set_lines(opts.buf, 0, -1, false, lines)
end

---@param opts table
function M.execute(begin, _end, compiler, options, opts)
  local lines = vim.api.nvim_buf_get_lines(0, (begin - 1), _end, true)
  local text = vim.fn.join(lines, "\n")
  options["compilerOptions"] = { executorRequest = true }
  local cmd = require("godbolt.cmd").build_cmd(compiler, text, options, "exec")
  local function _5_(_, _0, _1)
    local file = io.open("godbolt_response_exec.json", "r")
    local response = file:read("*all")
    file:close()
    os.remove("godbolt_request_exec.json")
    os.remove("godbolt_response_exec.json")
    return display_output(vim.json.decode(response), opts)
  end
  return vim.fn.jobstart(cmd, { on_exit = _5_ })
end

return M
