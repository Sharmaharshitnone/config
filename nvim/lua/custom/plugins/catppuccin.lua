return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      require('catppuccin').setup {
        flavour = 'mocha', -- standard clean dark base
        transparent_background = true, -- allow kitty background to show through
        term_colors = true,
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          telescope = true,
          notify = false,
          mini = false,
          native_lsp = {
            enabled = true,
            virtual_text = {
              errors = { 'italic' },
              hints = { 'italic' },
              warnings = { 'italic' },
              information = { 'italic' },
            },
            underlines = {
              errors = { 'undercurl' },
              hints = { 'undercurl' },
              warnings = { 'undercurl' },
              information = { 'undercurl' },
            },
            inlay_hints = {
              background = true,
            },
          },
        },
        custom_highlights = function(colors)
          return {
            -- Hybrid Overrides: Gruvbox Red Accents
            -- Primary Highlights
            Cursor = { fg = colors.base, bg = '#fb4934' },
            CursorLineNr = { fg = '#fb4934', style = { 'bold' } },
            
            -- Search & Visual
            Search = { fg = colors.base, bg = '#fabd2f' }, -- Gruvbox Yellow for search
            Visual = { bg = '#45475a' }, -- Subtle visual selection

            -- Borders (Sharp Red)
            FloatBorder = { fg = '#fb4934' },
            TelescopeBorder = { fg = '#fb4934' },
            NeoTreeWinSeparator = { fg = '#fb4934' },
            WinSeparator = { fg = '#fb4934' },

            -- Status Line Accents
            StatusLine = { bg = 'NONE', fg = '#cdd6f4' },
            StatusLineNC = { bg = 'NONE', fg = '#585b70' },
          }
        end,
      }
      -- Apply the colorscheme
      vim.cmd.colorscheme 'catppuccin'
    end,
  },
}
