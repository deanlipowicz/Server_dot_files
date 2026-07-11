-- blink.cmp source for LaTeX math commands in Quarto $ / $$ blocks.

local latex_cmds = require("latex_cmds")

---Check whether the cursor is inside a $...$ or $$...$$ math region on the
---current line (a simple heuristic that works for typical Quarto usage).
local function in_math_on_line()
  local lnum = vim.fn.line(".")
  local col  = vim.fn.col(".") - 1 -- 0-indexed column
  local line = vim.fn.getline(lnum)

  -- Scan the line character by character tracking $ pairs.
  -- $$ is treated as display-math delimiters (two adjacent $).
  local i = 1
  while i <= #line do
    -- Skip escaped $
    if i < #line and line:sub(i, i) == "\\" and line:sub(i + 1, i + 1) == "$" then
      i = i + 2
    -- Display math $$...$$
    elseif i < #line and line:sub(i, i + 1) == "$$" then
      local close = line:find("%$%$", i + 2)
      if close then
        -- inside display math: after opening $$, before closing $$
        if col > i and col <= close - 2 then return true end
        i = close + 2
      else
        -- Unclosed display math — assume rest of line is math
        if col > i then return true end
        return false
      end
    -- Inline math $...$
    elseif line:sub(i, i) == "$" then
      -- Find next non-escaped, non-$$ $ as closing delimiter
      local close
      local search_start = i + 1
      while true do
        close = line:find("%$", search_start)
        if not close then break end
        -- Skip escaped \$
        if close > 1 and line:sub(close - 1, close - 1) == "\\" then
          search_start = close + 1
        -- Skip $$ (first $ of another display-math pair)
        elseif close < #line and line:sub(close + 1, close + 1) == "$" then
          search_start = close + 2
        else
          break -- found a valid closing single $
        end
      end
      if close then
        -- inside inline math: after opening $, before closing $
        if col >= i and col <= close - 2 then return true end
        i = close + 1
      else
        -- Unclosed inline math
        if col >= i then return true end
        return false
      end
    end
    i = i + 1
  end
  return false
end

local M = {}

function M.get_trigger_characters()
  return { "\\" }
end

function M.new()
  return setmetatable({}, { __index = M })
end

function M:get_completions(ctx, callback)
  -- Only activate inside math regions on the current line
  if not in_math_on_line() then
    callback()
    return
  end

  -- Only activate when the prefix starts with \
  local prefix = ctx.prefix or ""
  if prefix:sub(1, 1) ~= "\\" then
    callback()
    return
  end

  local items = {}
  for _, cmd in ipairs(latex_cmds) do
    -- Compare against the label (which starts with \) or the label without the leading backslash
    if cmd.label:find(prefix, 1, true) == 1 then
      table.insert(items, {
        label = cmd.label,
        insertText = cmd.insert,
        detail = cmd.detail,
        kind_name = "Latex",
        kind_hl = "BlinkCmpItemKindLatex",
      })
    end
  end

  if #items == 0 then
    callback()
    return
  end

  -- Sort: exact prefix match first, then alphabetical
  table.sort(items, function(a, b)
    if a.label == prefix then return true end
    if b.label == prefix then return false end
    return a.label < b.label
  end)

  callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = items })
end

return M
