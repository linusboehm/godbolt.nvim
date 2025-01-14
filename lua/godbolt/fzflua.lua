local fzflua = require('fzf-lua')

--- Return to normal mode
local function return_to_normal_mode()
  local mode = vim.fn.mode():lower()
  if mode:find("[vV]") then
    vim.cmd([[execute "normal! \<Esc>"]])
  end
  vim.cmd('stopinsert')
end
local M = {}

--- Pick an action from a list of actions
---@param opts table?: fzf-lua options
function M.pick(callback, pick_actions, opts)

  return_to_normal_mode()
  opts = vim.tbl_extend('force', {
    prompt = "pick" .. '> ',
    actions = {
      ['default'] = function(selected)
        if not selected or vim.tbl_isempty(selected) then
          return
        end
        callback(selected)
      end,
    },
  }, opts or {})

  fzflua.fzf_exec(pick_actions, opts)
end

return M
