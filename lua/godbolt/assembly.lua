M = {}

local fmt = string.format
local term_escapes = "[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]"
local map = {}
local nsid_static = vim.api.nvim_create_namespace("godbolt_highlight")
local nsid = vim.api.nvim_create_namespace("godbolt_cursor")
local timer = nil

local function get_highlight(field)
  local highlight = require("godbolt").config.highlight
  if type(highlight) == "table" then
    return highlight[field]
  end
end
local function set_highlight_group(group_name, highlight)
  if type(highlight) ~= "string" then
  elseif string.sub(highlight, 1, 1) == "#" then
    vim.api.nvim_set_hl(0, group_name, { bg = highlight })
    return group_name
  elseif not vim.tbl_isempty(vim.api.nvim_get_hl(0, { name = highlight })) then
    vim.api.nvim_set_hl(0, group_name, { link = highlight })
    return group_name
  end
end
local function get_highlight_groups(highlights)
  local tbl_21_auto = {}
  for i, hl in ipairs(highlights) do
    local val_23_auto = set_highlight_group(("Godbolt" .. i), hl)
    if val_23_auto then
      table.insert(tbl_21_auto, val_23_auto)
    end
  end
  return tbl_21_auto
end
local function get_entry_source_line(entry, asm_line)
  local source
  source = entry and entry.asm and entry.asm[asm_line] and entry.asm[asm_line].source
  if source and (type(source) == "table") and (source.file == vim.NIL) then
    return (source.line + (entry.offset - 1))
  end
end
local function get_source_line(source_buffer, asm_buffer, asm_line)
  local _11_ = map and map[source_buffer] and map[source_buffer][asm_buffer]
  return get_entry_source_line(_11_, asm_line)
end
local function cyclic_lookup(array, index)
  return array[(1 + (index % #array))]
end
local function get_source_highlights(source_buffer, namespace_id)
  local extmarks = vim.api.nvim_buf_get_extmarks(
    source_buffer,
    namespace_id,
    0,
    -1,
    { type = "highlight", details = false, hl_name = false, overlap = false }
  )
  local tbl_21_auto = {}
  for _, _14_ in ipairs(extmarks) do
    local line = _14_[2]
    if line then
      table.insert(tbl_21_auto, line)
    end
  end
  return tbl_21_auto
end
local function update_cursor(source_buffer, cursor_line)
  vim.api.nvim_buf_clear_namespace(source_buffer, nsid, 0, -1)
  local source_highlights = get_source_highlights(source_buffer, nsid)
  local group = set_highlight_group("GodboltCursor", get_highlight("cursor"))
  for asm_buffer, entry in pairs(map[source_buffer]) do
    vim.api.nvim_buf_clear_namespace(asm_buffer, nsid, 0, -1)
    for asm_line, _ in ipairs(entry.asm) do
      local source_line = get_entry_source_line(entry, asm_line)
      if source_line and (cursor_line == source_line) then
        vim.api.nvim_buf_add_highlight(asm_buffer, nsid, group, (asm_line - 1), 0, -1)
        if not vim.tbl_contains(source_highlights, (source_line - 1)) then
          vim.api.nvim_buf_add_highlight(source_buffer, nsid, group, (source_line - 1), 0, -1)
          table.insert(source_highlights, (source_line - 1))
        end
      end
    end
  end
end
local function update_source(source_buf)
  return update_cursor(source_buf, vim.api.nvim_win_get_cursor(0)[1])
end
local function init_highlight(source_buffer, asm_buffer)
  vim.api.nvim_buf_clear_namespace(asm_buffer, nsid_static, 0, -1)
  local source_highlights = get_source_highlights(source_buffer, nsid_static)
  local highlights = get_highlight_groups(get_highlight("static"))
  local entry = map[source_buffer][asm_buffer]
  for asm_line, _ in ipairs(entry.asm) do
    local source_line = get_entry_source_line(entry, asm_line)
    if source_line then
      local group = cyclic_lookup(highlights, source_line)
      vim.api.nvim_buf_add_highlight(asm_buffer, nsid_static, group, (asm_line - 1), 0, -1)
      if not vim.tbl_contains(source_highlights, (source_line - 1)) then
        vim.api.nvim_buf_add_highlight(source_buffer, nsid_static, group, (source_line - 1), 0, -1)
        table.insert(source_highlights, (source_line - 1))
      end
    end
  end
end
local function remove_source(source_buffer)
  vim.api.nvim_buf_clear_namespace(source_buffer, nsid_static, 0, -1)
  vim.api.nvim_buf_clear_namespace(source_buffer, nsid, 0, -1)
  vim.api.nvim_clear_autocmds({ group = "Godbolt", buffer = source_buffer })
  if require("godbolt").config.auto_cleanup and map[source_buffer] then
    for asm_buffer, _ in pairs(map[source_buffer]) do
      vim.api.nvim_buf_delete(asm_buffer, {})
    end
  end
  map[source_buffer] = nil
end
local function update_asm(source_buffer, asm_buffer)
  local asm_line = vim.api.nvim_win_get_cursor(0)[1]
  local source_line = get_source_line(source_buffer, asm_buffer, asm_line)
  return update_cursor(source_buffer, source_line)
end
local function remove_asm(source_buffer, asm_buffer)
  vim.api.nvim_buf_clear_namespace(asm_buffer, nsid_static, 0, -1)
  vim.api.nvim_buf_clear_namespace(asm_buffer, nsid, 0, -1)
  map[source_buffer][asm_buffer] = nil
  if require("godbolt").config.auto_cleanup and (0 == vim.tbl_count(map[source_buffer])) then
    return remove_source(source_buffer)
  end
end
local function setup_aucmd(source_buf, asm_buf)
  local group = vim.api.nvim_create_augroup("Godbolt", { clear = false })
  local cursor = set_highlight_group("GodboltCursor", get_highlight("cursor"))
  if 0 == #vim.api.nvim_get_autocmds({ group = group, buffer = source_buf }) then
    if cursor then
      vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter" }, {
        group = group,
        callback = function()
          update_source(source_buf)
        end,
        buffer = source_buf,
      })
    end
    vim.api.nvim_create_autocmd({ "BufUnload" }, {
      group = group,
      callback = function()
        remove_source(source_buf)
      end,
      buffer = source_buf,
    })
  end
  if cursor then
    vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter" }, {
      group = group,
      callback = function()
        update_asm(source_buf, asm_buf)
      end,
      buffer = asm_buf,
    })
  end
  vim.api.nvim_create_autocmd({ "BufUnload", "BufHidden" }, {
    group = group,
    callback = function()
      remove_asm(source_buf, asm_buf)
    end,
    buffer = asm_buf,
  })
end
local function make_qflist(err, bufnr)
  if next(err) then
    local tbl_21_auto = {}
    for i, v in ipairs(err) do
      local entry = { text = string.gsub(v.text, term_escapes, ""), bufnr = bufnr }
      if v.tag then
        entry["col"] = v.tag.column
        entry["lnum"] = v.tag.line
      end
      table.insert(tbl_21_auto, entry)
    end
    return tbl_21_auto
  end
end
---@param opts table
local function display(response, begin, opts)
  local asm
  if vim.tbl_isempty(response.asm) then
    asm = fmt("No assembly to display (~%d lines filtered)", response.filteredCount)
  else
    local str = {}
    for _, v in pairs(response.asm) do
      if v.text then
        table.insert(str, v.text)
      end
    end
    asm = table.concat(str, "\n")
  end
  local config = require("godbolt").config
  local source_buf = vim.fn.bufnr()
  local qflist = make_qflist(response.stderr, source_buf)
  local asm_buf = opts.buf
  vim.api.nvim_buf_set_lines(asm_buf, 0, -1, true, vim.split(asm, "\n", { trimempty = true }))
  vim.bo[asm_buf]["filetype"] = (vim.b.asmsyntax or vim.g.asmsyntax or "asm")
  if qflist and config.quickfix.enable then
    vim.fn.setqflist(qflist)
    if config.quickfix.auto_open then
      vim.cmd.copen()
      vim.fn.win_getid()
    end
  end
  if not vim.tbl_isempty(response.asm) and ("<Compilation failed>" == response.asm[1].text) then
    return vim.notify("godbolt.nvim: Compilation failed")
  else
    opts = opts or {}
    opts.win = opts.win or -1
    local asm_winid = opts.win
    if not map[source_buf] then
      map[source_buf] = {}
    end
    map[source_buf][asm_buf] = { asm = response.asm, offset = begin, winid = asm_winid }
    if not vim.tbl_isempty(response.asm) then
      if get_highlight("static") then
        init_highlight(source_buf, asm_buf)
      end
      return setup_aucmd(source_buf, asm_buf)
    end
  end
end

local function start_spinner(text)
  local frames = { "⣼", "⣹", "⢻", "⠿", "⡟", "⣏", "⣧", "⣶" }
  local interval = 100

  local i = 1
  timer = (vim.uv or vim.loop).new_timer()
  timer:start(0, interval, function()
    i = (i == #frames) and 1 or (i + 1)
    local msg = text .. " " .. frames[i]
    vim.schedule(function()
      vim.api.nvim_echo({ { msg, "None" } }, false, {})
    end)
  end)
end

local function stop_spinner()
  vim.api.nvim_echo({ { "", "None" } }, false, {})
  timer:stop()
  timer:close()
end

---@param begin integer
---@param end_line integer
---@param opts table
function M.pre_display(ft, begin, end_line, opts)
  local config = require("godbolt").config
  local options = config.languages[ft] and vim.deepcopy(config.languages[ft].options) or {}
  opts.flags = opts.flags or vim.fn.input({ prompt = "Flags: ", default = (options.userArguments or "") })
  options["userArguments"] = opts.flags
  local lines = vim.api.nvim_buf_get_lines(0, (begin - 1), end_line, true)
  local text = vim.fn.join(lines, "\n")
  opts.compiler = opts.compiler or config.languages[ft].compiler
  local curl_cmd = require("godbolt.cmd").build_cmd(opts.compiler, text, options, "asm")
  local function _42_()
    stop_spinner()
    local file = io.open("godbolt_response_asm.json", "r")
    local response = file:read("*all")
    file:close()
    os.remove("godbolt_request_asm.json")
    os.remove("godbolt_response_asm.json")
    display(vim.json.decode(response), begin, opts.asm)
    if opts and opts.exec then
      return require("godbolt.execute").execute(begin, end_line, opts.compiler, options, opts.out)
    end
  end
  start_spinner("compiling")
  vim.fn.jobstart(curl_cmd, { on_exit = _42_ })
  return opts
end

return M
