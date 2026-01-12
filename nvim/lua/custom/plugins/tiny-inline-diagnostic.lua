return {
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy", -- Or "LspAttach"
    priority = 1000, -- Needs to be high priority to load before other diagnostic plugins
    config = function()
      require("tiny-inline-diagnostic").setup({
        -- 1. Configuration: Presets & Styling
        preset = "modern", -- Options: "modern", "classic", "minimal", "powerline", "ghost", "simple", "nonerdfont", "amongus"
        
        options = {
          -- 2. Configuration: Display & Wrapping
          show_source = true, -- Show the source of the diagnostic (e.g., "lua_ls")
          use_icons_from_diagnostic = false, -- Use preset icons
          
          -- "Power User" Setting: Wrap long messages so you can read them without scrolling
          softwrap = 30, -- Wrap text after 30 characters
          overflow = {
              mode = "wrap", -- "wrap" | "none" | "oneline"
          },
          
          -- Break long messages into multiple lines automatically
          break_line = {
              enabled = true,
              after = 30,
          },
  
          -- 4. Power User: Multiline & Performance
          multilines = {
              enabled = true,
              always_show = true, -- Always show all lines of the error
          },
          
          -- Performance: Throttle updates (in ms). Set to 0 for instant updates if your machine is fast.
          throttle = 20, 
          
          -- Show all diagnostics on the current line, not just the one under the cursor
          show_all_diags_on_cursorline = true,
          
          -- Disable in insert mode for cleaner editing experience
          enable_on_insert = false,
          enable_on_select = false,
        },
      })
  
      -- 3. Disable default vim diagnostics virtual text
      -- This is crucial to avoid duplicate messages (one from Neovim, one from this plugin)
      vim.diagnostic.config({ virtual_text = false })
  
      -- 4. Power User: Keybinds
      -- Toggle diagnostics quickly
      vim.keymap.set("n", "<leader>td", "<cmd>TinyInlineDiag toggle<cr>", { desc = "Toggle Inline Diagnostics" })
    end,
  },
}
