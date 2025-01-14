local fun = vim.fn
local pre_display = require("godbolt.assembly")["pre-display"]
local execute = require("godbolt.execute").execute

local function transform(entry)
  return {value = vim.split(entry, " ")[1], display = entry, ordinal = entry}
end

local function telescope(entries, begin, _end, options, exec, reuse_3f)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local actions_state = require("telescope.actions.state")
  local function _7_(prompt_bufnr, _map)
    local function _8_()
      actions.close(prompt_bufnr)
      local compiler = actions_state.get_selected_entry().value
      pre_display(begin, _end, compiler, options, reuse_3f)
      if exec then
        return execute(begin, _end, compiler, options)
      else
        return nil
      end
    end
    return actions.select_default:replace(_8_)
  end
  return pickers.new({}, {prompt_title = "Choose compiler", finder = finders.new_table({results = entries, entry_maker = transform}), sorter = conf.generic_sorter(nil), attach_mappings = _7_}):find()
end
local function fzf_lua(entries, begin, _end, options, exec, reuse_3f)
  local callback = function(selected)
    local compiler = vim.split(selected[1], " ")[1]
    pre_display(begin, _end, compiler, options, reuse_3f)
    if exec then
      return execute(begin, _end, compiler, options)
    else
      return nil
    end
  end
  require("godbolt.fzflua").pick(callback, entries)
end

local function fuzzy(picker, ft, begin, _end, options, exec, reuse_3f)
  local ft0
  if (ft == "cpp") then
    ft0 = "c++"
  elseif (nil ~= ft) then
    local x = ft
    ft0 = x
  else
    ft0 = nil
  end
  local url = require("godbolt").config.url
  local cmd = string.format("curl %s/api/compilers/%s", url, ft0)
  local output = {}
  local function _14_(_, data, _0)
    return vim.list_extend(output, data)
  end
  local function _15_(_, _0, _1)
    local entries
    do
      local tbl_21_auto = {}
      local i_22_auto = 0
      for k, v in ipairs(output) do
        local val_23_auto
        if (k ~= 1) then
          val_23_auto = v
        else
          val_23_auto = nil
        end
        if (nil ~= val_23_auto) then
          i_22_auto = (i_22_auto + 1)
          tbl_21_auto[i_22_auto] = val_23_auto
        else
        end
      end
      entries = tbl_21_auto
    end
    local _18_
    if (picker == "telescope") then
      _18_ = telescope
    elseif (picker == "fzflua") then
      _18_ = fzf_lua
    else
      _18_ = nil
    end
    return _18_(entries, begin, _end, options, exec, reuse_3f)
  end
  return fun.jobstart(cmd, {on_stdout = _14_, on_exit = _15_, stdout_buffered = true})
end
return {fuzzy = fuzzy}
