return {
  'kawre/leetcode.nvim',
  build = ':TSUpdate html',
  dependencies = {
    'nvim-telescope/telescope.nvim',
    -- "ibhagwan/fzf-lua",
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
  },
  config = function(_, opts)
    -- Auto-create the leetcode directory if it doesn't exist
    local leet_home = vim.fn.expand('~/work/language/Cpp/leetcode')
    if vim.fn.isdirectory(leet_home) == 0 then
      vim.fn.mkdir(leet_home, 'p')
    end
    require('leetcode').setup(opts)
  end,
  opts = {
    lang = 'cpp',
    cn = { enabled = false },
    storage = {
      home = vim.fn.expand('~/work/language/Cpp/leetcode'),
      cache = vim.fn.stdpath('cache') .. '/leetcode',
    },
  },
}

