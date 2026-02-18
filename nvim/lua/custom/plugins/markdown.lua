-- render-markdown.nvim — Rich markdown rendering in Neovim
-- Tuned for Kanagawa Dragon palette with transparent background
-- https://github.com/MeanderingProgrammer/render-markdown.nvim
--
-- Highlights use Kanagawa Dragon colors directly so everything stays
-- cohesive even when the terminal bg is transparent or changes.

return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    enabled = true,
    ft = { 'markdown', 'codecompanion' },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },

    config = function()
      -- ── Kanagawa Dragon Palette Reference ──────────────────────
      -- Sourced from rebelot/kanagawa.nvim dragon variant + user overrides
      local p = {
        bg      = '#181616',  -- dragonBlack3 (base, transparent)
        bg_dim  = '#1D1C19',  -- dragonBlack2
        bg_m1   = '#12120f',  -- dragonBlack1
        bg_p1   = '#282727',  -- dragonBlack4
        bg_p2   = '#393836',  -- dragonBlack5
        dim     = '#625e5a',  -- dragonBlack6
        fg      = '#d4d8d4',  -- dragonWhite (lifted)
        ash     = '#8a9490',  -- dragonAsh   (comments, lifted)
        gray    = '#b0b0a6',  -- dragonGray  (params, lifted)
        nontext = '#7a7a72',  -- line numbers (custom)
        red     = '#c4746e',  -- dragonRed
        orange  = '#b6927b',  -- dragonOrange
        yellow  = '#c4b28a',  -- dragonYellow
        green   = '#87a987',  -- dragonGreen
        green2  = '#8a9a7b',  -- dragonGreen2
        teal    = '#949fb5',  -- dragonTeal
        aqua    = '#8ea4a2',  -- dragonAqua
        blue    = '#8ba4b0',  -- dragonBlue
        blue2   = '#a3d4d5',  -- dragonBlue2
        violet  = '#8992a7',  -- dragonViolet
        pink    = '#a292a3',  -- dragonPink
      }

      local hl = vim.api.nvim_set_hl

      -- ── Heading Foregrounds (warm → cool gradient) ─────────────
      hl(0, 'RenderMarkdownH1', { fg = p.red,    bold = true })
      hl(0, 'RenderMarkdownH2', { fg = p.yellow, bold = true })
      hl(0, 'RenderMarkdownH3', { fg = p.green,  bold = true })
      hl(0, 'RenderMarkdownH4', { fg = p.blue,   bold = true })
      hl(0, 'RenderMarkdownH5', { fg = p.pink })
      hl(0, 'RenderMarkdownH6', { fg = p.ash })

      -- ── Heading Backgrounds (~10% fg tint over #181616) ────────
      -- Intentionally low-contrast for transparent backgrounds
      hl(0, 'RenderMarkdownH1Bg', { bg = '#2a1f1f' })
      hl(0, 'RenderMarkdownH2Bg', { bg = '#292620' })
      hl(0, 'RenderMarkdownH3Bg', { bg = '#1f251f' })
      hl(0, 'RenderMarkdownH4Bg', { bg = '#1f2226' })
      hl(0, 'RenderMarkdownH5Bg', { bg = '#231f23' })
      hl(0, 'RenderMarkdownH6Bg', { bg = '#1e1e1e' })

      -- ── Code ───────────────────────────────────────────────────
      hl(0, 'RenderMarkdownCode',       { bg = p.bg_dim })
      hl(0, 'RenderMarkdownCodeInline', { bg = p.bg_p1, fg = p.orange })

      -- ── Structural ─────────────────────────────────────────────
      hl(0, 'RenderMarkdownBullet', { fg = p.blue })
      hl(0, 'RenderMarkdownDash',   { fg = p.bg_p2 })

      -- ── Links ──────────────────────────────────────────────────
      hl(0, 'RenderMarkdownLink',     { fg = p.aqua,  underline = true })
      hl(0, 'RenderMarkdownWikiLink', { fg = p.blue2, underline = true })

      -- ── Tables ─────────────────────────────────────────────────
      hl(0, 'RenderMarkdownTableHead', { fg = p.yellow, bold = true })
      hl(0, 'RenderMarkdownTableRow',  { bg = p.bg_dim })
      hl(0, 'RenderMarkdownTableFill', { bg = 'NONE' })

      -- ── Checkboxes ─────────────────────────────────────────────
      hl(0, 'RenderMarkdownUnchecked', { fg = p.ash })
      hl(0, 'RenderMarkdownChecked',   { fg = p.green })
      hl(0, 'RenderMarkdownTodo',      { fg = p.yellow })

      -- ── Quotes ─────────────────────────────────────────────────
      hl(0, 'RenderMarkdownQuote1', { fg = p.dim })
      hl(0, 'RenderMarkdownQuote2', { fg = p.dim })
      hl(0, 'RenderMarkdownQuote3', { fg = p.dim })
      hl(0, 'RenderMarkdownQuote4', { fg = p.dim })
      hl(0, 'RenderMarkdownQuote5', { fg = p.dim })
      hl(0, 'RenderMarkdownQuote6', { fg = p.dim })

      -- ── Callout Semantic Colors ────────────────────────────────
      hl(0, 'RenderMarkdownInfo',    { fg = p.blue })
      hl(0, 'RenderMarkdownSuccess', { fg = p.green })
      hl(0, 'RenderMarkdownWarn',    { fg = p.yellow })
      hl(0, 'RenderMarkdownError',   { fg = p.red })
      hl(0, 'RenderMarkdownHint',    { fg = p.aqua })

      -- ── Misc ───────────────────────────────────────────────────
      hl(0, 'RenderMarkdownMath',            { fg = p.teal })
      hl(0, 'RenderMarkdownSign',            { fg = p.nontext })
      hl(0, 'RenderMarkdownInlineHighlight', { bg = p.bg_p1, fg = p.yellow })
      hl(0, 'RenderMarkdownIndent',          { fg = p.bg_p2 })

      -- ── Plugin Setup ───────────────────────────────────────────
      require('render-markdown').setup {

        -- ── Headings ──────────────────────────────────────────────
        heading = {
          enabled = true,
          sign = false,
          icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
          position = 'inline',
          width = 'full',
          left_pad = 0,
          right_pad = 0,
          min_width = 0,
          border = false,
          backgrounds = {
            'RenderMarkdownH1Bg', 'RenderMarkdownH2Bg', 'RenderMarkdownH3Bg',
            'RenderMarkdownH4Bg', 'RenderMarkdownH5Bg', 'RenderMarkdownH6Bg',
          },
          foregrounds = {
            'RenderMarkdownH1', 'RenderMarkdownH2', 'RenderMarkdownH3',
            'RenderMarkdownH4', 'RenderMarkdownH5', 'RenderMarkdownH6',
          },
        },

        -- ── Code Blocks ───────────────────────────────────────────
        code = {
          enabled = true,
          sign = false,
          style = 'full',           -- icon + language name + background
          position = 'left',
          language_icon = true,
          language_name = true,
          border = 'thin',           -- subtle top/bottom border
          width = 'block',           -- bg matches text width, not full window
          left_pad = 2,
          right_pad = 2,
          min_width = 40,
          highlight = 'RenderMarkdownCode',
          highlight_inline = 'RenderMarkdownCodeInline',
          disable_background = { 'diff' },
          inline = true,
        },

        -- ── Bullets ───────────────────────────────────────────────
        bullet = {
          enabled = true,
          icons = { '●', '○', '◆', '◇' },
          left_pad = 0,
          right_pad = 1,
          highlight = 'RenderMarkdownBullet',
        },

        -- ── Checkboxes ────────────────────────────────────────────
        checkbox = {
          enabled = true,
          unchecked = {
            icon = '󰄱 ',
            highlight = 'RenderMarkdownUnchecked',
          },
          checked = {
            icon = '󰱒 ',
            highlight = 'RenderMarkdownChecked',
            scope_highlight = '@markup.strikethrough',
          },
          custom = {
            todo = {
              raw = '[-]',
              rendered = '󰥔 ',
              highlight = 'RenderMarkdownTodo',
            },
            important = {
              raw = '[!]',
              rendered = '󰓎 ',
              highlight = 'RenderMarkdownError',
            },
            in_progress = {
              raw = '[~]',
              rendered = '󰔟 ',
              highlight = 'RenderMarkdownWarn',
            },
          },
        },

        -- ── Pipe Tables ───────────────────────────────────────────
        pipe_table = {
          enabled = true,
          preset = 'round',          -- rounded corners
          style = 'full',            -- top + bottom borders
          cell = 'padded',
          padding = 1,
          min_width = 0,
          alignment_indicator = '━',
          head = 'RenderMarkdownTableHead',
          row = 'RenderMarkdownTableRow',
          filler = 'RenderMarkdownTableFill',
        },

        -- ── Links ─────────────────────────────────────────────────
        link = {
          enabled = true,
          footnote = {
            enabled = true,
            superscript = true,
          },
          image = '󰥶 ',
          email = '󰀓 ',
          hyperlink = '󰌹 ',
          highlight = 'RenderMarkdownLink',
          wiki = {
            icon = '󱗖 ',
            highlight = 'RenderMarkdownWikiLink',
          },
          custom = {
            web    = { pattern = '^http',           icon = '󰖟 ' },
            github = { pattern = 'github%.com',     icon = '󰊤 ' },
            yt     = { pattern = 'youtube%.com',    icon = '󰗃 ' },
            reddit = { pattern = 'reddit%.com',     icon = '󰑍 ' },
            arch   = { pattern = 'archlinux%.org',  icon = '󰣇 ' },
            rust   = { pattern = 'rust%-lang%.org', icon = ' ' },
            crates = { pattern = 'crates%.io',      icon = '󰏗 ' },
          },
        },

        -- ── Horizontal Rules ──────────────────────────────────────
        dash = {
          enabled = true,
          icon = '─',
          width = 'full',
          highlight = 'RenderMarkdownDash',
        },

        -- ── Block Quotes ──────────────────────────────────────────
        quote = {
          enabled = true,
          icon = '▋',
          repeat_linebreak = false,
          highlight = 'RenderMarkdownQuote1',
        },

        -- ── Inline Highlights (==text==) ──────────────────────────
        inline_highlight = {
          enabled = true,
          highlight = 'RenderMarkdownInlineHighlight',
        },

        -- ── LaTeX ─────────────────────────────────────────────────
        latex = {
          enabled = true,
          converter = { 'utftex', 'latex2text' },
          highlight = 'RenderMarkdownMath',
        },

        -- ── Sign Column ───────────────────────────────────────────
        sign = { enabled = false },

        -- ── Indentation ───────────────────────────────────────────
        indent = { enabled = false },

        -- ── Anti-Conceal ──────────────────────────────────────────
        -- Show raw markdown on cursor line so editing is seamless
        anti_conceal = {
          enabled = true,
          above = 0,
          below = 0,
          ignore = {
            code_background = true,
            sign = true,
          },
        },

        -- ── Window Options ────────────────────────────────────────
        win_options = {
          conceallevel = {
            default = vim.o.conceallevel,
            rendered = 2,
          },
          concealcursor = {
            default = vim.o.concealcursor,
            rendered = '',
          },
        },

        -- ── Padding ───────────────────────────────────────────────
        padding = { highlight = 'Normal' },
      }
    end,
  },
}
