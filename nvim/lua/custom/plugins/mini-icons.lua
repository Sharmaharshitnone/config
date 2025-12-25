return {
  {
    'echasnovski/mini.icons',
    version = false,
    lazy = false, -- Load immediately so it can mock nvim-web-devicons
    priority = 1000,
    config = function()
      require('mini.icons').setup()
      require('mini.icons').mock_nvim_web_devicons()
    end,
  },
  { 'nvim-tree/nvim-web-devicons', enabled = false },
}
