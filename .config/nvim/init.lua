-- ============================================================================
-- init.lua — Minimal Neovim config for R / Stan / C++ / Web
-- ============================================================================
-- Principles:
--   If it can be done as well in a terminal/tmux pane, it doesn't belong here.
--   Zero persistent UI. Popups only (which-key, completion, LSP hover).
--   Harpoon marks 2-5 files; <leader>1..<leader>5 hops directly.
--   which-key provides on-demand shortcut discovery.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Bootstrap lazy.nvim
-- ---------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ---------------------------------------------------------------------------
-- 2. Options
-- ---------------------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = ","

local o = vim.opt
o.autoread = true
o.completeopt = { "menuone", "noinsert", "popup" }
o.expandtab = true
o.ignorecase = true
o.inccommand = "split"
o.mouse = ""
o.number = true
o.relativenumber = true
o.scrolloff = 6
o.shiftwidth = 2
o.smartcase = true
o.softtabstop = 2
o.splitbelow = true
o.splitright = true
o.tabstop = 2
o.termguicolors = true
o.timeoutlen = 400
o.undofile = true
o.updatetime = 250
o.wrap = false

vim.diagnostic.config({
  severity_sort = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  virtual_text = { spacing = 2, source = "if_many" },
})

-- ---------------------------------------------------------------------------
-- 3. Filetype associations
-- ---------------------------------------------------------------------------
vim.filetype.add({
  extension = {
    qmd = "quarto", stan = "stan",
    ltx = "tex", sty = "tex", cls = "tex",
    duck = "duckdb",
  },
  pattern = {
    [".*/%.Rprofile"] = "r",
    [".*/%.Renviron"] = "sh",
  },
})

-- ---------------------------------------------------------------------------
-- 4. Autocmds
-- ---------------------------------------------------------------------------
local augroup = vim.api.nvim_create_augroup

-- Auto-create parent directories when saving a new file
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("min_mkparents", { clear = true }),
  callback = function()
    local dir = vim.fn.fnamemodify(vim.fn.expand("<afile>:p"), ":h")
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
  end,
})

-- Filetype-specific settings (commentstring, indentation, Stan makeprg)
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("min_ftsettings", { clear = true }),
  pattern = { "cpp", "quarto", "r", "sql", "stan" },
  callback = function()
    local ft = vim.bo.filetype
    local cs = ({ cpp = "// %s", stan = "// %s", sql = "-- %s", r = "# %s", quarto = "<!-- %s -->" })[ft]
    if cs then vim.bo.commentstring = cs end
    vim.bo.shiftwidth, vim.bo.softtabstop, vim.bo.tabstop = 2, 2, 2
    vim.bo.expandtab = true
    if ft == "quarto" then vim.wo.conceallevel = 0 end
    if ft == "stan" then
      local checker = ".pi/bin/stanc-check"
      vim.bo.makeprg = (vim.fn.executable(checker) == 1 and checker or "stanc") .. " %"
      vim.keymap.set("n", "<leader>cm", ":w<cr>:make<cr>", { buffer = true, desc = "Stan check" })
    end
  end,
})

-- ---------------------------------------------------------------------------
-- 5. Keymaps (no plugin dependency)
-- ---------------------------------------------------------------------------
local map = vim.keymap.set

map("n", "<leader>cm", function()
  vim.cmd("write"); pcall(vim.cmd, "make")
  if #vim.fn.getqflist() > 0 then vim.cmd("copen") end
end, { desc = "Write and make" })

map("n", "<leader>p", "]p", { desc = "Paste with indent (below)" })
map("n", "<leader>P", "[p", { desc = "Paste with indent (above)" })

map("n", "<leader>gw", function()
  local w = vim.fn.expand("<cword>")
  if w == "" then return end
  local lines = vim.fn.systemlist({ "rg", "--line-number", "--column", "--no-heading", w, "." })
  vim.fn.setqflist({}, "r", { title = "rg: " .. w, lines = lines, efm = "%f:%l:%c:%m" })
  if #vim.fn.getqflist() > 0 then vim.cmd("copen") end
end, { desc = "Grep word to quickfix" })

map("n", "<leader>rj", function()
  local file, lnum, col = vim.fn.getline("."):match("([^:]+):(%d+):(%d+):")
  if not file then file, lnum = vim.fn.getline("."):match("([^:]+):(%d+):") end
  if file and lnum then
    vim.cmd("edit " .. file); vim.fn.cursor(tonumber(lnum), tonumber(col or 1))
  end
end, { desc = "Jump to file:line under cursor" })

-- Diagnostic navigation
map("n", "[d", function() vim.diagnostic.goto_prev({ float = false }) end, { desc = "Prev diagnostic" })
map("n", "]d", function() vim.diagnostic.goto_next({ float = false }) end, { desc = "Next diagnostic" })
map("n", "<leader>ld", function() vim.diagnostic.open_float({ source = true }) end, { desc = "Diagnostic float" })

-- ---------------------------------------------------------------------------
-- 6. Inline statistics helpers
-- ---------------------------------------------------------------------------

-- Documentation (open in browser)
map("n", "<leader>dr", function()
  local word = vim.fn.expand("<cword>")
  local pkg, fun = word:match("([%w.]+)::([%w.]+)")
  if pkg and fun then
    vim.ui.open("https://search.r-project.org/CRAN/refmans/"
      .. pkg .. "/html/" .. fun .. ".html")
  else
    vim.ui.open("https://search.r-project.org/?q=" .. word)
  end
end, { desc = "R help for word" })

map("n", "<leader>ds", function()
  vim.ui.open("https://mc-stan.org/docs/")
end, { desc = "Stan documentation" })

map("n", "<leader>df", function()
  vim.ui.open("https://mc-stan.org/docs/functions-reference/")
end, { desc = "Stan functions reference" })

-- Data inspection (send to R/Python REPL via vim-slime)
local function send_repl(text)
  pcall(vim.fn["slime#send"], text .. "\n")
end

local function word_or_fallback(fb)
  local w = vim.fn.expand("<cword>")
  return w ~= "" and w or fb
end

map("n", "<leader>ig", function()
  send_repl(word_or_fallback("df") .. " |> glimpse()")
end, { desc = "Inspect: glimpse" })

map("n", "<leader>is", function()
  send_repl(word_or_fallback("df") .. " |> summary()")
end, { desc = "Inspect: summary" })

map("n", "<leader>ih", function()
  send_repl(word_or_fallback("df") .. " |> head()")
end, { desc = "Inspect: head" })

map("n", "<leader>iS", function()
  send_repl("str(" .. word_or_fallback("df") .. ")")
end, { desc = "Inspect: str" })

map("n", "<leader>id", function()
  send_repl("dim(" .. word_or_fallback("df") .. ")")
end, { desc = "Inspect: dim" })

-- ---------------------------------------------------------------------------
-- 7. DuckDB SQL runner
-- ---------------------------------------------------------------------------
map("x", "<leader>sq", function()
  local _, ls, cs = unpack(vim.fn.getpos("'<"))
  local _, le, ce = unpack(vim.fn.getpos("'>"))
  local lines = vim.fn.getline(ls, le)
  if ls == le then lines[1] = lines[1]:sub(cs, ce) end
  local sql = table.concat(lines, "\n")
  vim.fn.jobstart({ "duckdb", "-c", sql, "-nullvalue", "NULL", "-separator", "|" }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if not data then return end
      local buf = vim.api.nvim_create_buf(false, true)
      vim.bo[buf].buftype = "nofile"
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, data)
      vim.api.nvim_open_win(buf, true, {
        relative = "editor", width = math.min(100, vim.o.columns - 4),
        height = math.min(30, vim.o.lines - 4), row = 2, col = 2,
        border = "rounded",
      })
    end,
  })
end, { desc = "Run SQL with DuckDB" })

-- ---------------------------------------------------------------------------
-- 8. Plugin specifications
-- ---------------------------------------------------------------------------
require("lazy").setup({

  --------------------------------------------------
  -- Colorscheme
  --------------------------------------------------
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = { flavour = "mocha" },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  --------------------------------------------------
  -- Completion (blink.cmp)
  --------------------------------------------------
  {
    "saghen/blink.cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    version = "*",
    dependencies = {
      "Kaiser-Yang/blink-cmp-dictionary",
    },
    opts = {
      keymap = {
        preset = "default",
        ["<A-y>"] = { "show" },
      },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        ghost_text = { enabled = true },
        trigger = { prefetch_on_insert = true },
        menu = {
          auto_show = true,
          border = "rounded",
          max_height = 10,
          scrolloff = 2,
          scrollbar = true,
          draw = {
            columns = { { "kind_icon" }, { "label", "label_description", gap = 1 } },
            snippet_indicator = "~",
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 500,
        },
      },
      signature = {
        enabled = true,
        window = { border = "rounded" },
      },
      sources = {
        default = { "lsp", "minuet", "path", "snippets", "buffer" },
        providers = {
          snippets = {
            name = "snippets",
            opts = { snippet_engine = "luasnip" },
          },
          minuet = {
            name = "minuet",
            module = "minuet.blink",
            async = true,
            timeout_ms = 3000,
            score_offset = 1,
          },
          dictionary = {
            module = "blink-cmp-dictionary",
            name = "Dict",
            min_keyword_length = 2,
            opts = {
              dictionary_files = {
                vim.fn.expand("~/.config/nvim/tidywordlist/functions.dict"),
              },
            },
          },
          latex = {
            name = "latex",
            module = "blink_latex",
            async = true,
          },
        },
        per_filetype = {
          r      = { "lsp", "minuet", "dictionary", "snippets", "path", "buffer" },
          rmd    = { "lsp", "minuet", "dictionary", "snippets", "path", "buffer" },
          quarto = { "lsp", "minuet", "dictionary", "snippets", "latex", "path", "buffer" },
          stan   = { "lsp", "minuet", "snippets", "path", "buffer" },
          tex    = { "lsp", "minuet", "snippets", "path", "buffer" },
        },
      },
      cmdline = {
        enabled = true,
        keymap = { preset = "cmdline" },
        sources = { "buffer", "cmdline" },
        completion = {
          menu = { auto_show = true },
          ghost_text = { enabled = true },
        },
      },
    },
  },

  --------------------------------------------------
  -- AI code completion (minuet-ai)
  --------------------------------------------------
  {
    "milanglacier/minuet-ai.nvim",
    event = "InsertEnter",
    config = function()
      local utils = require("minuet.utils")

      -- Per-filetype context window (in characters).
      -- FIM completions don't use system prompts, so "varying the prompt"
      -- means adjusting context size, trigger conditions, and the FIM
      -- template which injects language-aware comments into the context.
      local context_by_ft = {
        stan = 8000, r = 8000, cpp = 12000, c = 12000,
        duckdb = 6000, quarto = 10000,
      }

      -- Filetype-specific instructions injected as comments before the
      -- cursor context.  The FIM model sees these as part of the code.
      local ft_instructions = {
        r = "# Prefer the tidyverse (dplyr, ggplot2, tidyr, readr, purrr,\n# tibble, stringr, forcats) for data manipulation and visualization.\n# Use base R only when no tidyverse equivalent exists.\n# Write generated assets (ggsave, write_csv, saveRDS, etc.) to disk\n# rather than returning objects to the REPL. Prefer ggsave() over\n# print() for plots, and write_csv() / write_parquet() over return().",
        stan = "// Focus on statistical modeling, probability distributions, and\n// Bayesian inference with Hamiltonian Monte Carlo (HMC).\n// Use vectorized expressions, _lp functions, and generated quantities\n// blocks for posterior predictive checks where appropriate.",
        cpp = "// C++ for statistical computing / HPC.\n// Prefer Stan Math, Eigen, and Boost libraries over raw loops.\n// Follow the Rule of 5 (or 0): define or delete copy/move constructors,\n// copy/move assignment, and destructor when managing resources.\n// Use RAII, constexpr where possible, and avoid raw pointers.",
        duckdb = "-- DuckDB SQL for analytical / OLAP queries.\n-- Use columnar operations, window functions, and CTEs.\n-- Prefer duckdb-specific extensions (parquet, json, arrow) over\n-- manual parsing.  Set sensible PRAGMA settings for memory/threads.",
      }

      -- FIM prompt template: prepends language metadata and optional
      -- filetype-specific instructions to the context-before-cursor.
      local function fim_prompt(context_before_cursor, _, _)
        local lang  = utils.add_language_comment()
        local tab   = utils.add_tab_comment()
        local extra = ft_instructions[vim.bo.filetype]
        if extra then
          return lang .. "\n" .. extra .. "\n" .. tab .. "\n" .. context_before_cursor
        end
        return lang .. "\n" .. tab .. "\n" .. context_before_cursor
      end

      local function fim_suffix(_, context_after_cursor, _)
        return context_after_cursor
      end

      -- Check if cursor is inside a Quarto/Rmd code chunk
      local function in_code_chunk()
        local lnum = vim.fn.line(".")
        for i = lnum, 1, -1 do
          local line = vim.fn.getline(i)
          if line:match("^```%s*$") then return false end
          if line:match("^```%{") then return true end
        end
        return false
      end

      require("minuet").setup({
        provider = "openai_fim_compatible",
        context_window = context_by_ft[vim.bo.filetype] or 10000,
        enable_predicates = {
          function()
            local ft = vim.bo.filetype
            if ft == "stan" or ft == "r" or ft == "cpp" or ft == "c" or ft == "duckdb" then
              return true
            end
            if ft == "quarto" then return in_code_chunk() end
            return false
          end,
        },
        provider_options = {
          openai_fim_compatible = {
            api_key = "DEEPSEEK_API_KEY",
            name = "deepseek",
            end_point = "https://api.deepseek.com/beta/completions",
            model = "deepseek-v4-flash",
            stream = true,
            template = {
              prompt = fim_prompt,
              suffix = fim_suffix,
            },
            optional = {
              max_tokens = 256,
              top_p = 0.9,
            },
          },
        },
      })
    end,
  },

  --------------------------------------------------
  -- Snippets (luasnip)
  --------------------------------------------------
  {
    "L3MON4D3/LuaSnip",
    lazy = false,
    priority = 800,
    config = function()
      local ls = require("luasnip")
      require("snippets.stats")
      require("snippets.r")
      require("snippets.stan")
      -- .Rmd files inherit R snippets
      ls.filetype_extend("rmd", { "r" })
    end,
  },

  --------------------------------------------------
  -- Treesitter (syntax highlighting, indentation)
  --------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    lazy = false,
    priority = 900,
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        "r", "python", "bash", "sql", "cpp",
        "html", "javascript", "latex", "css",
        "markdown", "markdown_inline",
      },
      auto_install = false,
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  --------------------------------------------------
  -- LSP servers (R, Stan, C++, Web, SQL, JSON)
  --------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "saghen/blink.cmp" },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()
      local lsp_dir = vim.fn.stdpath("data") .. "/lazy/nvim-lspconfig/lsp/"

      local servers = { "r_language_server", "marksman", "clangd", "ts_ls", "jsonls", "sqls", "stan_ls" }
      for _, name in ipairs(servers) do
        local ok, default = pcall(dofile, lsp_dir .. name .. ".lua")
        if not ok then
          vim.notify("Failed to load LSP config: " .. name, vim.log.levels.WARN)
        else
          default.capabilities = capabilities
          if name == "r_language_server" then
            default.filetypes = { "r", "rmd", "quarto" }
            default.root_dir = function(bufnr, cb)
              cb(vim.fs.root(bufnr, { "DESCRIPTION", "NAMESPACE", ".Rbuildignore" }) or vim.uv.os_homedir())
            end
          end
          if name == "ts_ls" then
            default.filetypes = { "javascript", "jsx", "typescript", "typescriptreact" }
          end
          if name == "jsonls" then
            default.settings = {
              json = {
                schemas = {
                  { description = "Vega-Lite", fileMatch = { "*.vl.json", "*.vega-lite.json" }, url = "https://vega.github.io/schema/vega-lite/v6.json" },
                  { description = "Vega", fileMatch = { "*.vega.json", "vega*.json" }, url = "https://vega.github.io/schema/vega/v6.json" },
                },
                validate = { enable = true },
              },
            }
          end
          if name == "stan_ls" then
            default.cmd = { "bun", vim.fn.expand("~/.bun/bin/stan-language-server"), "--stdio" }
          end
          if name == "marksman" then
            default.filetypes = { "markdown", "quarto", "rmd" }
          end
          vim.lsp.config[name] = default
          vim.lsp.enable(name)
        end
      end

      -- LSP keymaps (per-buffer)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = augroup("min_lsp_attach", { clear = true }),
        callback = function(ev)
          local buf, client = ev.buf, vim.lsp.get_client_by_id(ev.data.client_id)
          if not client then return end
          map("n", "K", vim.lsp.buf.hover, { buffer = buf, desc = "LSP: hover" })
          map("n", "gd", vim.lsp.buf.definition, { buffer = buf, desc = "LSP: go to definition" })
          map("n", "gr", vim.lsp.buf.references, { buffer = buf, desc = "LSP: references" })
          map("n", "<leader>lr", vim.lsp.buf.rename, { buffer = buf, desc = "LSP: rename" })
          map({ "n", "x" }, "<leader>la", vim.lsp.buf.code_action, { buffer = buf, desc = "LSP: code action" })
          if client.server_capabilities.inlayHintProvider then
            vim.lsp.inlay_hint.enable(true, { bufnr = buf })
          end
          -- LSP restart
          map("n", "<leader>lR", function()
            pcall(vim.lsp.restart, { bufnr = buf })
          end, { buffer = buf, desc = "LSP: restart" })
          -- Document highlight (highlight references under cursor)
          if client.server_capabilities.documentHighlightProvider then
            vim.api.nvim_create_autocmd("CursorHold", {
              buffer = buf,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd("CursorMoved", {
              buffer = buf,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })
    end,
  },

  --------------------------------------------------
  -- Embedded LSP: otter.nvim (Quarto code blocks)
  --------------------------------------------------
  {
    "jmbuhr/otter.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "quarto", "rmd", "markdown" },
        callback = function() pcall(function() require("otter").activate() end) end,
      })
    end,
  },

  --------------------------------------------------
  -- Quarto
  --------------------------------------------------
  {
    "quarto-dev/quarto-nvim",
    ft = { "quarto", "rmd", "markdown" },
    dependencies = { "jmbuhr/otter.nvim" },
    config = function()
      require("quarto").setup({ lspFeatures = { enabled = true }, codeRunner = { enabled = false } })
      map("n", "]c", function() require("quarto").nav_next() end, { desc = "Next chunk" })
      map("n", "[c", function() require("quarto").nav_prev() end, { desc = "Previous chunk" })
    end,
  },

  --------------------------------------------------
  -- which-key: on-demand shortcut discovery
  --------------------------------------------------
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    dependencies = { "echasnovski/mini.icons" },
    opts = {
      preset = "modern",
      delay = function(ctx) return ctx.plugin and 0 or 400 end,
      plugins = {
        marks = true, registers = true,
        spelling = { enabled = true, suggestions = 20 },
        presets = { operators = true, motions = true, text_objects = true, windows = true, nav = true, z = true, g = true },
      },
    },
  },

  --------------------------------------------------
  -- Harpoon: mark 2-5 files, hop with <leader>1..<leader>5
  --------------------------------------------------
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>a", desc = "Harpoon: add file" },
      { "<leader>hm", desc = "Harpoon: menu" },
      { "<leader>1", desc = "Harpoon: file 1" },
      { "<leader>2", desc = "Harpoon: file 2" },
      { "<leader>3", desc = "Harpoon: file 3" },
      { "<leader>4", desc = "Harpoon: file 4" },
      { "<leader>5", desc = "Harpoon: file 5" },
    },
    config = function()
      local hp = require("harpoon")
      hp:setup()
      map("n", "<leader>a", function() hp:list():add() end, { desc = "Harpoon: add file" })
      map("n", "<leader>hm", function() hp.ui:toggle_quick_menu(hp:list()) end, { desc = "Harpoon: menu" })
      for i = 1, 5 do
        map("n", "<leader>" .. i, function() hp:list():select(i) end, { desc = "Harpoon: file " .. i })
      end
    end,
  },

  --------------------------------------------------
  -- vim-slime: send code to tmux pane (R REPL, etc.)
  --------------------------------------------------
  {
    "jpalardy/vim-slime",
    event = "VeryLazy",
    config = function()
      vim.g.slime_target = "tmux"
      vim.g.slime_no_mappings = 1
      vim.g.slime_bracketed_paste = 1
      vim.g.slime_default_config = { socket_name = "default", target_pane = "{last}" }
      vim.g.slime_cell_delimiter = '^```{'

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "r" },
        callback = function() vim.b.slime_cell_delimiter = "^#%%" end,
      })

      -- Extract Quarto/Rmd code chunk text
      local function chunk_text()
        local ft = vim.bo.filetype
        if ft ~= "quarto" and ft ~= "rmd" and ft ~= "markdown" then return nil end
        local s = vim.fn.line(".")
        while s > 0 and not vim.fn.getline(s):match("^```%{") do s = s - 1 end
        if s == 0 then return nil end
        local e = s + 1
        while e <= vim.fn.line("$") and not vim.fn.getline(e):match("^```%s*$") do e = e + 1 end
        return table.concat(vim.fn.getline(s + 1, e - 1), "\n")
      end

      map("n", "<leader>ss", function() vim.cmd("normal! <Plug>SlimeLineSend") end, { desc = "Send line to tmux" })
      map("x", "<leader>ss", function() vim.cmd("normal! '<,'>SlimeRegionSend") end, { desc = "Send selection to tmux" })
      map("n", "<leader>sc", function()
        local t = chunk_text()
        if t then vim.fn.writefile(vim.split(t, "\n"), vim.g.slime_paste_file or "/tmp/slime-paste") end
        vim.cmd("normal! <Plug>SlimeSendCell")
      end, { desc = "Send code chunk to tmux" })
      map("n", "<leader>sf", function() vim.cmd("%SlimeSend") end, { desc = "Send file to tmux" })
      map("n", "<leader>sC", "<cmd>SlimeConfig<cr>", { desc = "Select tmux target pane" })
    end,
  },

  --------------------------------------------------
  -- Autoformat on save (conform.nvim)
  --------------------------------------------------
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre", "BufReadPre" },
    opts = {
      formatters_by_ft = {
        r = { "styler" },
        cpp = { "clang-format" },
        c = { "clang-format" },
        lua = { "stylua" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        markdown = { "prettier" },
        quarto = { "prettier" },
        sql = { "sqlfluff" },
      },
      formatters = {
        ["clang-format"] = {
          command = "clang-format-18",
        },
      },
      format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
    },
    keys = {
      { "<leader>f", function() require("conform").format() end, desc = "Format buffer" },
    },
  },

  --------------------------------------------------
  -- Project search/replace (grug-far.nvim)
  --------------------------------------------------
  {
    "MagicDuck/grug-far.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>sr", function() require("grug-far").open() end, desc = "Search and replace" },
    },
    opts = {
      engine = "ripgrep",
      useGlobbing = true,
      showHiddenFiles = false,
      resultsStyle = "split",
      keymaps = {
        replace = { n = "<C-s>" },
        qflist = { n = "<C-q>" },
      },
    },
  },

  --------------------------------------------------
  -- Fuzzy finder (telescope.nvim)
  --------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    tag = "v0.2.2",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function() return vim.fn.executable("make") == 1 end,
      },
    },
    keys = {
      { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find files" },
      { "<leader>fg", function() require("telescope.builtin").live_grep() end, desc = "Live grep" },
      { "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Buffers" },
      { "<leader>fs", function() require("telescope.builtin").lsp_document_symbols() end, desc = "LSP symbols" },
      { "<leader>fS", function() require("telescope.builtin").lsp_workspace_symbols() end, desc = "LSP workspace symbols" },
      { "<leader>fr", function() require("telescope.builtin").resume() end, desc = "Resume telescope" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          file_ignore_patterns = { "^.git/", "node_modules", "__pycache__", ".venv", ".drake" },
        },
        pickers = {
          find_files = { hidden = true, no_ignore = false },
        },
      })
      pcall(function() require("telescope").load_extension("fzf") end)
    end,
  },

  --------------------------------------------------
  -- Multicursor (vim-visual-multi)
  --------------------------------------------------
  {
    "mg979/vim-visual-multi",
    event = "VeryLazy",
    init = function()
      vim.g.VM_default_mappings = 0
      vim.g.VM_maps = {
        ["Find Under"] = "<C-n>",
        ["Add Cursor Up"] = "<C-Up>",
        ["Add Cursor Down"] = "<C-Down>",
      }
    end,
  },

  --------------------------------------------------
  -- Autopairs + HTML tag autoclose
  --------------------------------------------------
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      check_ts = true,
      ts_config = {
        lua = { "string" },
        javascript = { "template_string" },
      },
      enable_filetype = {
        tex = false,
        plaintex = false,
      },
    },
    config = function(_, opts)
      require("nvim-autopairs").setup(opts)
    end,
  },
  {
    "windwp/nvim-ts-autotag",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      enable_filetype = { "html", "javascript", "javascriptreact", "typescriptreact", "xml" },
    },
  },

})

-- Quarto render keymap (outside lazy setup to avoid table parsing issues)
map("n", "<leader>qr", function()
  vim.cmd("write")
  local file = vim.fn.expand("%:p")
  vim.fn.jobstart({ "quarto", "render", file }, {
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("Quarto render: " .. vim.fn.fnamemodify(file, ":t"), vim.log.levels.INFO)
      end
    end,
  })
end, { desc = "Quarto render" })
