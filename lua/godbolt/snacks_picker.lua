local snacks = require("snacks")

--- Return to normal mode
local function return_to_normal_mode()
  local mode = vim.fn.mode():lower()
  if mode:find("[vV]") then
    vim.cmd([[execute "normal! \<Esc>"]])
  end
  vim.cmd("stopinsert")
end
local M = {}

--- Pick an action from a list of actions
function M.pick(callback, pick_actions, opts)
  return_to_normal_mode()
  opts = vim.tbl_extend("force", {
    items = vim.tbl_map(function(name)
      return {
        id = name,
        text = pick_actions[name],
        file = pick_actions[name],
        preview = {
          text = pick_actions[name],
          ft = "text",
        },
      }
    end, vim.tbl_keys(pick_actions)),
    layout = "select",
    title = "pick compiler",
    confirm = function(picker)
      picker:close()
      local selected = picker:current()
      if selected then
        local action = pick_actions[selected.id]
        Snacks.notify.info(action)
        vim.defer_fn(function()
          callback(selected.id)
        end, 0)
      end
    end,
  }, opts or {})

  snacks.picker(opts)
end

return M
