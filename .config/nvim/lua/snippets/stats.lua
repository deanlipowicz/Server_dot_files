local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local fmta = require("luasnip.extras.fmt").fmta

-- math-mode detection (same logic as blink_latex)

local function in_math()
  local col  = vim.fn.col(".") - 1
  local line = vim.fn.getline(".")

  local idx = 1
  while idx <= #line do
    if idx < #line and line:sub(idx, idx) == "\\" and line:sub(idx + 1, idx + 1) == "$" then
      idx = idx + 2
    elseif idx < #line and line:sub(idx, idx + 1) == "$$" then
      local close = line:find("%$%$", idx + 2)
      if close then
        -- inside display math: after opening $$, before closing $$
        if col > idx and col <= close - 2 then return true end
        idx = close + 2
      else
        -- unclosed $$: cursor after opening
        if col > idx then return true end
        return false
      end
    elseif line:sub(idx, idx) == "$" then
      -- Find next non-escaped, non-$$ $ as closing delimiter
      local close
      local search_start = idx + 1
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
        if col >= idx and col <= close - 2 then return true end
        idx = close + 1
      else
        -- unclosed inline math: cursor after opening $ is inside
        if col >= idx then return true end
        return false
      end
    end
    idx = idx + 1
  end
  return false
end

local m = { snippetType = "autosnippet", condition = in_math }

-- Helpers for capture-based snippets: returns capture text for a given index
local function cap(n)
  return function(_, snip) return snip.captures[n] end
end

-- ---- R ----

ls.add_snippets("r", {
  s({ trig = "|>", snippetType = "autosnippet" }, t(" |> ")),
  s("{", fmta("{{\n  <>\n}}", { i(0) })),
})

-- ---- Quarto general + Obsidian LaTeX Suite snippets ----

ls.add_snippets("quarto", {
  -- general
  s({ trig = "|>", snippetType = "autosnippet" }, t(" |> ")),
  s("rc", fmta("```{{r}}\n<>\n```", { i(0) })),
  s("pyc", fmta("```{{python}}\n<>\n```", { i(0) })),
  s("ojs", fmta("```{{ojs}}\n<>\n```", { i(0) })),
  s("dm", { t("$$"), i(1), t({ "", "$$" }), i(0) }),
  s("mk", { t("$$"), i(1), t({ "", "$$" }), i(0) }),
  s("im", { t("$"), i(1), t("$"), i(0) }),

  -- Greek letters (@ prefix)
  s("@a",  { t("\\alpha ") }, m),
  s("@b",  { t("\\beta ") }, m),
  s("@g",  { t("\\gamma ") }, m),
  s("@G",  { t("\\Gamma ") }, m),
  s("@d",  { t("\\delta ") }, m),
  s("@D",  { t("\\Delta ") }, m),
  s("@e",  { t("\\epsilon ") }, m),
  s(":e",  { t("\\varepsilon ") }, m),
  s("@z",  { t("\\zeta ") }, m),
  s("@h",  { t("\\eta ") }, m),
  s("@t",  { t("\\theta ") }, m),
  s("@T",  { t("\\Theta ") }, m),
  s(":t",  { t("\\vartheta ") }, m),
  s("@i",  { t("\\iota ") }, m),
  s("@k",  { t("\\kappa ") }, m),
  s("@l",  { t("\\lambda ") }, m),
  s("@L",  { t("\\Lambda ") }, m),
  s("@m",  { t("\\mu ") }, m),
  s("@n",  { t("\\nu ") }, m),
  s("@x",  { t("\\xi ") }, m),
  s("@X",  { t("\\Xi ") }, m),
  s("@p",  { t("\\pi ") }, m),
  s("@P",  { t("\\Pi ") }, m),
  s("@r",  { t("\\rho ") }, m),
  s("@s",  { t("\\sigma ") }, m),
  s("@S",  { t("\\Sigma ") }, m),
  s("@u",  { t("\\upsilon ") }, m),
  s("@U",  { t("\\Upsilon ") }, m),
  s("@ph", { t("\\phi ") }, m),
  s("@Ph", { t("\\Phi ") }, m),
  s("@c",  { t("\\chi ") }, m),
  s("@ps", { t("\\psi ") }, m),
  s("@Ps", { t("\\Psi ") }, m),
  s("@o",  { t("\\omega ") }, m),
  s("@O",  { t("\\Omega ") }, m),

  -- Basic operations
  s("sr",   { t("^{2}") }, m),
  s("cb",   { t("^{3}") }, m),
  s("rd",   fmta("^{<>}<>",      { i(1), i(0) }), m),
  s("_",    fmta("_{<>}<>",      { i(1), i(0) }), m),
  s("sts",  fmta("_\\text{<>}",  { i(1) }), m),
  s("sq",   fmta("\\sqrt{<>}<>", { i(1), i(0) }), m),
  s("//",   fmta("\\frac{<>}{<>}<>", { i(1), i(2), i(0) }), m),
  s("ee",   fmta("e^{<>}<>",     { i(1), i(0) }), m),
  s("invs", { t("^{-1}") }, m),
  s("conj", { t("^{*}") }, m),

  -- Text
  s("text", fmta("\\text{<>}<>", { i(1), i(0) }), m),
  s("\"",   fmta("\\text{<>}<>", { i(1), i(0) }), m),

  -- Accents (letter + command)
  s({ trig = "([A-Za-z])hat",  regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("\\hat{<>}", { f(cap(1)) })),
  s({ trig = "([A-Za-z])bar",  regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("\\bar{<>}", { f(cap(1)) })),
  s({ trig = "([A-Za-z])dot",  regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("\\dot{<>}", { f(cap(1)) })),
  s({ trig = "([A-Za-z])ddot", regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("\\ddot{<>}", { f(cap(1)) })),
  s({ trig = "([A-Za-z])tilde", regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("\\tilde{<>}", { f(cap(1)) })),
  s({ trig = "([A-Za-z])und",  regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("\\underline{<>}", { f(cap(1)) })),
  s({ trig = "([A-Za-z])vec",  regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("\\vec{<>}", { f(cap(1)) })),

  -- Standalone accents
  s("hat",   fmta("\\hat{<>}<>",      { i(1), i(0) }), m),
  s("bar",   fmta("\\bar{<>}<>",      { i(1), i(0) }), m),
  s("dot",   fmta("\\dot{<>}<>",      { i(1), i(0) }), m),
  s("ddot",  fmta("\\ddot{<>}<>",    { i(1), i(0) }), m),
  s("tilde", fmta("\\tilde{<>}<>",   { i(1), i(0) }), m),
  s("und",   fmta("\\underline{<>}<>", { i(1), i(0) }), m),
  s("vec",   fmta("\\vec{<>}<>",     { i(1), i(0) }), m),
  s("bf",    fmta("\\mathbf{<>}<>",  { i(1), i(0) }), m),
  s("rm",    fmta("\\mathrm{<>}<>",  { i(1), i(0) }), m),

  -- Auto subscript: letter + digit -> letter_{digit}
  s({ trig = "([A-Za-z])(\\d)", regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("<>_{<>}", { f(cap(1)), f(cap(2)) })),
  -- Extended subscript: x_{3}4 -> x_{34}
  s({ trig = "([A-Za-z]){(\\d+)}(\\d)", regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("<>_{<><>}", { f(cap(1)), f(cap(2)), f(cap(3)) })),

  -- Functions
  s("Re",    { t("\\mathrm{Re} ") }, m),
  s("Im",    { t("\\mathrm{Im} ") }, m),
  s("trace", { t("\\mathrm{Tr} ") }, m),
  s("pmod",  fmta("\\pmod{<>}<>", { i(1, "n"), i(0) }), m),

  -- Brackets
  s("avg",   fmta("\\langle <> \\rangle <>", { i(1), i(0) }), m),
  s("norm",  fmta("\\lvert <> \\rvert <>",   { i(1), i(0) }), m),
  s("Norm",  fmta("\\lVert <> \\rVert <>",   { i(1), i(0) }), m),
  s("ceil",  fmta("\\lceil <> \\rceil <>",   { i(1), i(0) }), m),
  s("floor", fmta("\\lfloor <> \\rfloor <>", { i(1), i(0) }), m),
  s("lr(",   fmta("\\left( <> \\right) <>",  { i(1), i(0) }), m),
  s("lr{",   fmta("\\left\\{ <> \\right\\} <>", { i(1), i(0) }), m),
  s("lr[",   fmta("\\left[ <> \\right] <>",  { i(1), i(0) }), m),
  s("lr|",   fmta("\\left| <> \\right| <>",  { i(1), i(0) }), m),
  s("lra",   fmta("\\left<< <> \\right>> <>",  { i(1), i(0) }), m),

  -- Environments
  s({ trig = "([pbBvV]mat)",  regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("\\begin{<>}\n<>\n\\end{<>}", { f(cap(1)), i(1), f(cap(1)) })),
  s({ trig = "(matrix|cases|align|array)", regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("\\begin{<>}\n<>\n\\end{<>}", { f(cap(1)), i(1), f(cap(1)) })),
})

-- ---- tex -- same LaTeX Suite snippets ----

ls.add_snippets("tex", {
  -- display / inline math (no math condition -- these ENTER math mode)
  s("dm", { t("$$"), i(1), t({ "", "$$" }), i(0) }),
  s("mk", { t("$$"), i(1), t({ "", "$$" }), i(0) }),
  s("im", { t("$"), i(1), t("$"), i(0) }),

  -- Greek
  s("@a",  { t("\\alpha ") }, m),
  s("@b",  { t("\\beta ") }, m),
  s("@g",  { t("\\gamma ") }, m),
  s("@G",  { t("\\Gamma ") }, m),
  s("@d",  { t("\\delta ") }, m),
  s("@D",  { t("\\Delta ") }, m),
  s("@e",  { t("\\epsilon ") }, m),
  s(":e",  { t("\\varepsilon ") }, m),
  s("@z",  { t("\\zeta ") }, m),
  s("@h",  { t("\\eta ") }, m),
  s("@t",  { t("\\theta ") }, m),
  s("@T",  { t("\\Theta ") }, m),
  s(":t",  { t("\\vartheta ") }, m),
  s("@i",  { t("\\iota ") }, m),
  s("@k",  { t("\\kappa ") }, m),
  s("@l",  { t("\\lambda ") }, m),
  s("@L",  { t("\\Lambda ") }, m),
  s("@m",  { t("\\mu ") }, m),
  s("@n",  { t("\\nu ") }, m),
  s("@x",  { t("\\xi ") }, m),
  s("@X",  { t("\\Xi ") }, m),
  s("@p",  { t("\\pi ") }, m),
  s("@P",  { t("\\Pi ") }, m),
  s("@r",  { t("\\rho ") }, m),
  s("@s",  { t("\\sigma ") }, m),
  s("@S",  { t("\\Sigma ") }, m),
  s("@u",  { t("\\upsilon ") }, m),
  s("@U",  { t("\\Upsilon ") }, m),
  s("@ph", { t("\\phi ") }, m),
  s("@Ph", { t("\\Phi ") }, m),
  s("@c",  { t("\\chi ") }, m),
  s("@ps", { t("\\psi ") }, m),
  s("@Ps", { t("\\Psi ") }, m),
  s("@o",  { t("\\omega ") }, m),
  s("@O",  { t("\\Omega ") }, m),

  -- Basic operations
  s("sr",   { t("^{2}") }, m),
  s("cb",   { t("^{3}") }, m),
  s("rd",   fmta("^{<>}<>",    { i(1), i(0) }), m),
  s("_",    fmta("_{<>}<>",    { i(1), i(0) }), m),
  s("sts",  fmta("_\\text{<>}", { i(1) }), m),
  s("sq",   fmta("\\sqrt{<>}<>", { i(1), i(0) }), m),
  s("//",   fmta("\\frac{<>}{<>}<>", { i(1), i(2), i(0) }), m),
  s("ee",   fmta("e^{<>}<>",   { i(1), i(0) }), m),
  s("invs", { t("^{-1}") }, m),
  s("conj", { t("^{*}") }, m),

  -- Text
  s("text", fmta("\\text{<>}<>", { i(1), i(0) }), m),
  s("\"",   fmta("\\text{<>}<>", { i(1), i(0) }), m),

  -- Accents (letter + command)
  s({ trig = "([A-Za-z])hat",  regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("\\hat{<>}", { f(cap(1)) })),
  s({ trig = "([A-Za-z])bar",  regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("\\bar{<>}", { f(cap(1)) })),
  s({ trig = "([A-Za-z])dot",  regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("\\dot{<>}", { f(cap(1)) })),
  s({ trig = "([A-Za-z])ddot", regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("\\ddot{<>}", { f(cap(1)) })),
  s({ trig = "([A-Za-z])tilde", regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("\\tilde{<>}", { f(cap(1)) })),
  s({ trig = "([A-Za-z])und",  regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("\\underline{<>}", { f(cap(1)) })),
  s({ trig = "([A-Za-z])vec",  regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("\\vec{<>}", { f(cap(1)) })),

  -- Standalone accents
  s("hat",   fmta("\\hat{<>}<>",      { i(1), i(0) }), m),
  s("bar",   fmta("\\bar{<>}<>",      { i(1), i(0) }), m),
  s("dot",   fmta("\\dot{<>}<>",      { i(1), i(0) }), m),
  s("ddot",  fmta("\\ddot{<>}<>",    { i(1), i(0) }), m),
  s("tilde", fmta("\\tilde{<>}<>",   { i(1), i(0) }), m),
  s("und",   fmta("\\underline{<>}<>", { i(1), i(0) }), m),
  s("vec",   fmta("\\vec{<>}<>",     { i(1), i(0) }), m),
  s("bf",    fmta("\\mathbf{<>}<>",  { i(1), i(0) }), m),
  s("rm",    fmta("\\mathrm{<>}<>",  { i(1), i(0) }), m),

  -- Auto subscript
  s({ trig = "([A-Za-z])(\\d)", regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("<>_{<>}", { f(cap(1)), f(cap(2)) })),
  s({ trig = "([A-Za-z]){(\\d+)}(\\d)", regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("<>_{<><>}", { f(cap(1)), f(cap(2)), f(cap(3)) })),

  -- Functions
  s("Re",    { t("\\mathrm{Re} ") }, m),
  s("Im",    { t("\\mathrm{Im} ") }, m),
  s("trace", { t("\\mathrm{Tr} ") }, m),
  s("pmod",  fmta("\\pmod{<>}<>", { i(1, "n"), i(0) }), m),

  -- Brackets
  s("avg",   fmta("\\langle <> \\rangle <>", { i(1), i(0) }), m),
  s("norm",  fmta("\\lvert <> \\rvert <>",   { i(1), i(0) }), m),
  s("Norm",  fmta("\\lVert <> \\rVert <>",   { i(1), i(0) }), m),
  s("ceil",  fmta("\\lceil <> \\rceil <>",   { i(1), i(0) }), m),
  s("floor", fmta("\\lfloor <> \\rfloor <>", { i(1), i(0) }), m),
  s("lr(",   fmta("\\left( <> \\right) <>",  { i(1), i(0) }), m),
  s("lr{",   fmta("\\left\\{ <> \\right\\} <>", { i(1), i(0) }), m),
  s("lr[",   fmta("\\left[ <> \\right] <>",  { i(1), i(0) }), m),
  s("lr|",   fmta("\\left| <> \\right| <>",  { i(1), i(0) }), m),
  s("lra",   fmta("\\left<< <> \\right>> <>",  { i(1), i(0) }), m),

  -- Environments
  s({ trig = "([pbBvV]mat)",  regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("\\begin{<>}\n<>\n\\end{<>}", { f(cap(1)), i(1), f(cap(1)) })),
  s({ trig = "(matrix|cases|align|array)", regTrig = true, snippetType = "autosnippet", condition = in_math },
    fmta("\\begin{<>}\n<>\n\\end{<>}", { f(cap(1)), i(1), f(cap(1)) })),
})
