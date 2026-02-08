-- kanagawa.lua — Kanagawa Dragon theme with transparent background
-- https://github.com/rebelot/kanagawa.nvim
--
-- Dragon: dark, warm, muted palette inspired by Katsushika Hokusai's ink paintings.
-- Wave: deep blue, high contrast (classic). Lotus: light theme.

return {
  'rebelot/kanagawa.nvim',
  lazy = false, -- load at startup
  priority = 1000, -- before all other plugins

  config = function()
    require('kanagawa').setup {
      compile = true, -- enable compiled colorscheme for faster startup
      undercurl = true,
      commentStyle = { italic = true },
      functionStyle = {},
      keywordStyle = { italic = true },
      statementStyle = { bold = true },
      typeStyle = {},

      transparent = true, -- transparent background
      dimInactive = false,
      terminalColors = true,

      theme = 'dragon', -- default theme when `background` is not set
      background = {
        dark = 'dragon',
        light = 'lotus',
      },

      colors = {
        palette = {
          -- Brighten the Dragon palette's dim defaults
          -- Default dragonWhite=#c5c9c5 → lifted to near-fujiWhite brightness
          dragonWhite = '#d4d8d4',
          -- Default dragonAsh=#737c73 (comments) → more readable
          dragonAsh = '#8a9490',
          -- Default dragonGray=#a6a69c (parameters) → slightly lifted
          dragonGray = '#b0b0a6',
        },
        theme = {
          all = {
            ui = {
              bg_gutter = 'none', -- remove gutter background
            },
          },
          dragon = {
            ui = {
              -- Default nontext=dragonBlack6=#625e5a → brighter line numbers
              nontext = '#7a7a72',
            },
          },
        },
      },

      ---@param colors KanagawaColors
      overrides = function(colors)
        local theme = colors.theme
        local palette = colors.palette

        return {
          -- ── Borderless Telescope ──────────────────────────────────
          TelescopeTitle = { fg = theme.ui.special, bold = true },
          TelescopePromptNormal = { bg = theme.ui.bg_p1 },
          TelescopePromptBorder = { fg = theme.ui.bg_p1, bg = theme.ui.bg_p1 },
          TelescopeResultsNormal = { fg = palette.fujiWhite, bg = theme.ui.bg_m1 },
          TelescopeResultsBorder = { fg = theme.ui.bg_m1, bg = theme.ui.bg_m1 },
          TelescopePreviewNormal = { bg = theme.ui.bg_dim },
          TelescopePreviewBorder = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },

          -- ── Dark completion menu (Pmenu) ──────────────────────────
          Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1 },
          PmenuSel = { fg = 'NONE', bg = theme.ui.bg_p2 },
          PmenuSbar = { bg = theme.ui.bg_m1 },
          PmenuThumb = { bg = theme.ui.bg_p2 },

          -- ── Floating windows ──────────────────────────────────────
          NormalFloat = { bg = 'none' },
          FloatBorder = { bg = 'none' },
          FloatTitle = { bg = 'none' },

          -- ── Transparent Normal ────────────────────────────────────
          Normal = { bg = 'none' },
          NormalNC = { bg = 'none' },
          SignColumn = { bg = 'none' },

          -- ── Diagnostic tints using palette ────────────────────────
          DiagnosticVirtualTextHint = { bg = 'none', fg = palette.dragonAqua },
          DiagnosticVirtualTextInfo = { bg = 'none', fg = palette.dragonTeal },
          DiagnosticVirtualTextWarn = { bg = 'none', fg = palette.carpYellow },
          DiagnosticVirtualTextError = { bg = 'none', fg = palette.samuraiRed },

          -- ── NeoTree transparent ───────────────────────────────────
          NeoTreeNormal = { bg = 'none' },
          NeoTreeNormalNC = { bg = 'none' },
          NeoTreeEndOfBuffer = { bg = 'none' },

          -- ── WhichKey transparent ──────────────────────────────────
          WhichKeyFloat = { bg = 'none' },
          WhichKey = { bg = 'none' },
          WhichKeyBorder = { bg = 'none' },

          -- ── Line numbers ──────────────────────────────────────────
          CursorLineNr = { fg = palette.carpYellow, bold = true },
          LineNr = { fg = theme.ui.nontext },

          -- ── Cursorline (subtle highlight, no solid bg) ────────────
          CursorLine = { bg = theme.ui.bg_p1 },
        }
      end,
    }

    -- Apply the colorscheme
    vim.cmd.colorscheme 'kanagawa-dragon'

    -- Recompile when config changes for instant startup
    -- Run :KanagawaCompile after changing this file
  end,
}
