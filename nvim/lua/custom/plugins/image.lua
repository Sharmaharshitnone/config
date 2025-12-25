return {
  {
    '3rd/image.nvim',
    enabled = true,
    ft = { 'markdown', 'neorg' }, -- Lazy-load on markdown/neorg files
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      -- HACK: Force image.nvim to think we are in Kitty even if Tmux stripped the env var
      if vim.env.KITTY_WINDOW_ID == nil then
        vim.env.KITTY_WINDOW_ID = '1' -- Dummy ID to satisfy checks
      end
      
      local backend = 'kitty'

      require('image').setup {
        backend = backend,
        kitty_method = 'normal',
        processor = 'magick_cli', -- uses ImageMagick (magick/convert/identify)
        integrations = {
          markdown = {
            enabled = true,
            clear_in_insert_mode = false,
            download_remote_images = true,
            only_render_image_at_cursor = false,
            filetypes = { 'markdown' },
          },
          neorg = { enabled = true, clear_in_insert_mode = false },
        },
        max_width_window_percentage = 100,
        max_height_window_percentage = 100,
        tmux_show_only_in_active_window = true,
        window_overlap_clear_enabled = false,

        -- IMPORTANT: don't replace buffers in fixed windows (prevents E5153)
        hijack_file_patterns = {},
      }

      -- :ImageHealth -> quick diagnostics for binaries/env/backend
      vim.api.nvim_create_user_command('ImageHealth', function()
        local function ok(bin)
          return (vim.fn.executable(bin) == 1) and '✓' or '✗'
        end
        local lines = {
          'image.nvim health:',
          '  backend: ' .. backend,
          '  TERM=' .. (vim.env.TERM or 'nil'),
          '  TMUX=' .. (vim.env.TMUX and 'yes' or 'no'),
          '  Kitty=' .. (is_kitty and 'yes' or 'no'),
          '  chafa: ' .. ok 'chafa',
          '  magick: ' .. ok 'magick' .. '  convert: ' .. ok 'convert' .. '  identify: ' .. ok 'identify',
          '  plugin loaded: ' .. (package.loaded['image'] and '✓' or '✗'),
        }
        vim.notify(table.concat(lines, '\n'))
      end, {})
    end,
  },
}
