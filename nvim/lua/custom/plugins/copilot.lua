return {
  -- GitHub Copilot
  {
    'github/copilot.vim',
    lazy = true,
    event = { 'InsertEnter', 'CmdlineEnter' },
    config = function()
      -- disable copilot's default Tab mapping
      vim.g.copilot_no_tab_map = true
      -- Map Tab: when popup menu visible, use completion next; otherwise accept Copilot suggestion
      vim.api.nvim_set_keymap('i', '<Tab>', 'pumvisible() ? "\\<C-n>" : copilot#Accept("\\<CR>")', { expr = true, noremap = true, silent = true })
    end,
  },

  -- Copilot Chat plugin
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      'github/copilot.vim',
      { 'nvim-lua/plenary.nvim', branch = 'master' },
    },
    build = 'make tiktoken', -- Only needed on MacOS or Linux
    opts = {
      model = 'gpt-5-mini',
      --[[     model = 'claude-3.7-sonnet-thought', ]]
      -- Configuration for the chat window
      window = {
        layout = 'vertical', -- Change to vertical split for side window
        position = 'right', -- Position on the right side (change to 'left' for left side)
        -- width = 40, -- Fixed width in characters (adjust as needed)
        -- height = 0.8,
        border = 'rounded',
        title = 'Copilot Chat',
      },
      -- Smart selection function that tries visual selection first, then falls back to buffer
      selection = function(source)
        return require('CopilotChat.select').visual(source) or require('CopilotChat.select').buffer(source)
      end,
    },
    -- Properly organized keymaps with which-key compatible format
    keys = {
      -- Group leader
      { '<M-/>c', '<cmd>CopilotChat<cr>', desc = 'Copilot Chat', mode = { 'n', 'v' } },
      -- { '<M-/>q', '<cmd>CopilotChatQuestion<cr>', desc = 'Copilot Chat', mode = { 'n', 'v' } },

      -- commands with descriptive names
      { '<M-/>e', '<cmd>CopilotChatExplain<cr>', desc = 'Explain Code' },
      { '<M-/>f', '<cmd>CopilotChatFix<cr>', desc = 'Fix Issues' },
      { '<M-/>t', '<cmd>CopilotChatTests<cr>', desc = 'Generate Tests' },
      { '<M-/>d', '<cmd>CopilotChatDocs<cr>', desc = 'Write Documentation' },
      { '<M-/>o', '<cmd>CopilotChatOptimize<cr>', desc = 'Optimize Code' },
      { '<M-/>r', '<cmd>CopilotChatReview<cr>', desc = 'Code Review' },
      { '<M-/>s', '<cmd>CopilotChatSave<cr>', desc = 'Save/Search' },
    },
  },
}
