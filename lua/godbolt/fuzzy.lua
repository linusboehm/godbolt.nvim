local M = {}
local function snacks_picker(ft, entries, begin, _end, opts)
  local win = vim.api.nvim_get_current_win()
  local callback = function(selected)
    vim.api.nvim_set_current_win(win)
    opts.compiler = vim.split(entries[selected], " ")[1]
    if opts.on_picked then
      opts.on_picked()
    end
    return require("godbolt.assembly").pre_display(ft, begin, _end, opts)
  end
  require("godbolt.snacks_picker").pick(callback, entries)
end

function M.fuzzy(ft, begin, _end, opts)
  curl_ft = ft
  if ft == "cpp" then
    curl_ft = "c++"
  end
  local url = require("godbolt").config.url
  local cmd = string.format("curl %s/api/compilers/%s", url, curl_ft)
  local output = {}
  local function run_picker()
    local entries = {}
    for k, v in ipairs(output) do
      if k ~= 1 then
        table.insert(entries, v)
      end
    end
    return snacks_picker(ft, entries, begin, _end, opts)
  end
  vim.fn.jobstart(cmd, {
    on_stdout = function(_, data, _)
      return vim.list_extend(output, data)
    end,
    on_exit = run_picker,
    stdout_buffered = true,
  })
  return opts
end

return M
