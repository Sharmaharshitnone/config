return {
  'kawre/leetcode.nvim',
  -- NOTE: :TSUpdate removed in Neovim 0.11+, use native API in post-build
  build = function()
    -- Install html parser for leetcode descriptions using native API
    pcall(function() require('nvim-treesitter').install { 'html' } end)
  end,
  dependencies = {
    'nvim-telescope/telescope.nvim',
    -- "ibhagwan/fzf-lua",
    'nvim-lua/plenary.nvim',
    '3rd/image.nvim',
    'MunifTanjim/nui.nvim',
  },
  config = function(_, opts)
    -- Auto-create the leetcode directory if it doesn't exist
    local leet_home = vim.fn.expand '~/work/language/Cpp/leetcode'
    if vim.fn.isdirectory(leet_home) == 0 then
      vim.fn.mkdir(leet_home, 'p')
    end
    require('leetcode').setup(opts)

    -- CRITICAL FIX: Force wrap on in description buffers
    -- leetcode.nvim hardcodes `wrap = not image_support`, but image.nvim v1.4.0+ supports wrap
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'leetcode.description',
      callback = function()
        vim.wo.wrap = true
        vim.wo.linebreak = true
      end,
      desc = 'Enable text wrapping in LeetCode descriptions (image.nvim v1.4.0+ compatible)',
    })
  end,
  opts = {
    lang = 'cpp',
    image_support = true, -- Fixed in image.nvim v1.4.0 (PR #266) - wrap now works with images
    storage = {
      home = vim.fn.expand '~/work/language/Cpp/leetcode',
      cache = vim.fn.stdpath 'cache' .. '/leetcode',
    },
  },

}

