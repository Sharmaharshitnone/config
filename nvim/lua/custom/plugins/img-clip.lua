-- img-clip.nvim — Effortless image embedding for any markup language
-- https://github.com/HakonHarnes/img-clip.nvim
--
-- Design principles:
--   1. Assets live NEXT TO the file (relative_to_current_file), not CWD
--   2. Images are auto-compressed via ImageMagick (strip EXIF, optimize PNG)
--   3. Drag-and-drop works in both normal AND insert mode (Kitty + X11)
--   4. Filetype templates are production-grade (proper alt-text, captions)
--   5. Multiple keymaps: paste, paste-as-base64, paste-from-url

return {
  'HakonHarnes/img-clip.nvim',
  event = 'VeryLazy',

  opts = {
    default = {
      -- ── File & Directory ─────────────────────────────────────────
      dir_path = 'assets', ---@type string
      extension = 'png', ---@type string
      file_name = '%Y-%m-%d-%H-%M-%S', ---@type string

      -- Assets folder is created relative to the CURRENT FILE, not CWD.
      -- This keeps images co-located with the document that references them.
      relative_to_current_file = true, ---@type boolean
      use_absolute_path = false, ---@type boolean

      -- ── Logging ──────────────────────────────────────────────────
      verbose = true, ---@type boolean

      -- ── Template ────────────────────────────────────────────────
      template = '$FILE_PATH', ---@type string
      url_encode_path = false, ---@type boolean
      relative_template_path = true, ---@type boolean
      use_cursor_in_template = true, ---@type boolean
      insert_mode_after_paste = true, ---@type boolean
      insert_template_after_cursor = true, ---@type boolean

      -- ── Prompt ──────────────────────────────────────────────────
      prompt_for_file_name = true, ---@type boolean
      show_dir_path_in_prompt = true, ---@type boolean

      -- ── Base64 ──────────────────────────────────────────────────
      max_base64_size = 10, ---@type number (KB)
      embed_image_as_base64 = false, ---@type boolean

      -- ── Image Processing (requires ImageMagick) ─────────────────
      -- Strip EXIF metadata + optimize PNG compression.
      -- Keeps file sizes sane without visible quality loss.
      process_cmd = 'convert - -strip -quality 90 png:-', ---@type string
      copy_images = false, ---@type boolean
      download_images = true, ---@type boolean

      -- Accepted image formats (incl. modern formats)
      formats = { 'png', 'jpg', 'jpeg', 'gif', 'webp', 'avif', 'bmp', 'tiff' },

      -- ── Drag & Drop ─────────────────────────────────────────────
      -- Kitty on X11/Wayland supports file + URL drag-and-drop.
      -- Enable in insert mode too for frictionless workflows.
      drag_and_drop = {
        enabled = true, ---@type boolean
        insert_mode = true, ---@type boolean
      },
    },

    -- ── Filetype-Specific Overrides ─────────────────────────────────
    filetypes = {
      markdown = {
        url_encode_path = true, ---@type boolean
        template = '![$CURSOR]($FILE_PATH)', ---@type string
        download_images = true, ---@type boolean
      },

      vimwiki = {
        url_encode_path = true, ---@type boolean
        template = '![$CURSOR]($FILE_PATH)', ---@type string
        download_images = true, ---@type boolean
      },

      html = {
        template = '<img src="$FILE_PATH" alt="$CURSOR" loading="lazy" />', ---@type string
      },

      tex = {
        relative_template_path = false, ---@type boolean
        template = [[
\begin{figure}[htbp]
  \centering
  \includegraphics[width=0.8\textwidth]{$FILE_PATH}
  \caption{$CURSOR}
  \label{fig:$LABEL}
\end{figure}
    ]], ---@type string
        formats = { 'jpeg', 'jpg', 'png', 'pdf', 'eps' },
      },

      typst = {
        template = [[
#figure(
  image("$FILE_PATH", width: 80%),
  caption: [$CURSOR],
) <fig-$LABEL>
    ]], ---@type string
      },

      rst = {
        template = [[
.. image:: $FILE_PATH
   :alt: $CURSOR
   :width: 80%
    ]], ---@type string
      },

      asciidoc = {
        template = 'image::$FILE_PATH[width=80%, alt="$CURSOR"]', ---@type string
      },

      org = {
        template = [=[
#+BEGIN_FIGURE
[[file:$FILE_PATH]]
#+CAPTION: $CURSOR
#+NAME: fig:$LABEL
#+END_FIGURE
    ]=], ---@type string
      },
    },
  },

  keys = {
    -- Primary: paste image from system clipboard
    { '<leader>p', '<cmd>PasteImage<cr>', desc = 'Paste image from clipboard' },

    -- Paste as inline base64 (useful for single-file HTML/markdown)
    {
      '<leader>P',
      function()
        require('img-clip').paste_image { embed_image_as_base64 = true }
      end,
      desc = 'Paste image as base64',
    },

    -- Debug: show img-clip config + shell output for troubleshooting
    { '<leader>iD', '<cmd>ImgClipDebug<cr>', desc = 'img-clip: debug log' },
    { '<leader>iC', '<cmd>ImgClipConfig<cr>', desc = 'img-clip: show config' },
  },
}
