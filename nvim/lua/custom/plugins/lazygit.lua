-- nvim v0.8.0
return {
  'kdheepak/lazygit.nvim',
  version = '*', -- Use latest stable version
  lazy = true,
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  cmd = {
    'LazyGit',
    'LazyGitConfig',
    'LazyGitCurrentFile',
    'LazyGitFilter',
    'LazyGitFilterCurrentFile',
  },
  opts = {
    floating_window_winblend = 0,
    floating_window_scaling_factor = 0.9,
    floating_window_border = {
      '╭',
      '─',
      '╮',
      '│',
      '╯',
      '─',
      '╰',
      '│',
    },
    lazygit_floating_window_use_plenary = true,
  },
  keys = {
    { '<leader>gg', '<cmd>LazyGit<cr>', desc = 'LazyGit (full)' },
    { '<leader>gf', '<cmd>LazyGitCurrentFile<cr>', desc = 'LazyGit Current File' },
    { '<leader>gl', '<cmd>LazyGitFilter<cr>', desc = 'LazyGit Log (all commits)' },
    { '<leader>gc', '<cmd>LazyGitConfig<cr>', desc = 'LazyGit Config' },
  },
}
