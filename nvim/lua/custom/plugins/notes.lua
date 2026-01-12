return {
  {
    'nvim-lua/plenary.nvim', -- Dependency
    config = function()
      local builtin = require('telescope.builtin')
      local notes_root = vim.fn.expand('~/notes')

      -- Helper: Create dir if missing and edit file
      local function create_and_edit(subdir, prompt_title)
        vim.ui.input({ prompt = prompt_title }, function(name)
          if name and name ~= '' then
            -- Auto-replace spaces with dashes for clean filenames
            local fname = name:gsub(" ", "-") .. ".md"
            local full_path = notes_root .. "/" .. subdir .. "/" .. fname
            
            -- Ensure directory exists
            local dir = vim.fn.fnamemodify(full_path, ":h")
            vim.fn.mkdir(dir, "p")
            
            vim.cmd('edit ' .. full_path)
          end
        end)
      end

      -- === SEARCH ===
      -- FIX: Search ONLY .md files using ripgrep
      vim.keymap.set('n', '<leader>ns', function()
        builtin.find_files {
          cwd = notes_root,
          prompt_title = "Search All Notes",
          find_command = { "rg", "--files", "--type", "md", "--hidden", "--glob", "!**.git/*" },
        }
      end, { desc = 'Notes: Search All (.md)' })

      -- FIX: Search specifically in Projects (Description/Name search)
      vim.keymap.set('n', '<leader>nps', function()
        builtin.find_files {
          cwd = notes_root .. "/30_personal/projects",
          prompt_title = "Search Projects",
          find_command = { "rg", "--files", "--type", "md" },
        }
      end, { desc = 'Notes: Search Projects' })

      -- === CREATION ===
      -- 1. Inbox (Quick Capture) - Mapped to <leader>n
      vim.keymap.set('n', '<leader>n', function()
        create_and_edit("00_inbox", "New Inbox Note: ")
      end, { desc = 'Notes: Inbox (Quick)' })

      -- 2. Personal (Projects, Areas, Journal)
      vim.keymap.set('n', '<leader>npp', function()
        create_and_edit("30_personal/projects", "New Project Note: ")
      end, { desc = 'Notes: New Personal Project' })

      vim.keymap.set('n', '<leader>npa', function()
        create_and_edit("30_personal/areas", "New Personal Area: ")
      end, { desc = 'Notes: New Personal Area' })

      vim.keymap.set('n', '<leader>npj', function()
        create_and_edit("30_personal/journal", "New Journal Entry: ")
      end, { desc = 'Notes: New Personal Journal' })

      -- 3. Work (Reference, Projects, Meetings, Languages)
      vim.keymap.set('n', '<leader>nwn', function()
        create_and_edit("20_work/reference", "New Work Reference: ")
      end, { desc = 'Notes: New Work Ref' })

      vim.keymap.set('n', '<leader>nwp', function()
        create_and_edit("20_work/active_projects", "New Work Project: ")
      end, { desc = 'Notes: New Work Project' })

      vim.keymap.set('n', '<leader>nwm', function()
        create_and_edit("20_work/meetings", "New Meeting Note: ")
      end, { desc = 'Notes: New Work Meeting' })

      vim.keymap.set('n', '<leader>nwl', function()
        -- Tip: Type "rust/borrow_checker" to auto-create subfolder
        create_and_edit("20_work/languages", "Language Note (lang/name): ")
      end, { desc = 'Notes: New Language Note' })

      -- 4. System (Arch, Logs) - Mapped to <leader>nS (Shift+S)
      vim.keymap.set('n', '<leader>nSa', function()
        create_and_edit("40_system/arch_maintenance", "Arch Note: ")
      end, { desc = 'Notes: System Arch' })

      vim.keymap.set('n', '<leader>nSt', function()
        create_and_edit("40_system/troubleshooting_logs", "Log Name: ")
      end, { desc = 'Notes: System Log' })

      -- 5. Archive/Further Notes
      vim.keymap.set('n', '<leader>na', function()
        create_and_edit("99_archive", "Archive Note: ")
      end, { desc = 'Notes: Archive/Further' })

      -- === DAILY ===
      -- Unified Daily Note: 10_daily/YYYY/YYYY-MM-DD.md
      vim.keymap.set('n', '<leader>nd', function()
        local year = os.date('%Y')
        local date = os.date('%Y-%m-%d')
        local subdir = "10_daily/" .. year
        local full_path = notes_root .. "/" .. subdir .. "/" .. date .. ".md"
        
        vim.fn.mkdir(notes_root .. "/" .. subdir, "p")
        vim.cmd('edit ' .. full_path)
      end, { desc = 'Notes: Today\'s Daily' })

      -- Legacy / External
      vim.keymap.set('n', '<leader>ngd', function()
        vim.cmd('edit ~/gdrive/Notes/daily/' .. os.date('%Y-%m-%d') .. '.md')
      end, { desc = 'Notes: GDrive Daily' })

      vim.keymap.set('n', '<leader>nbc', function()
        vim.cmd('edit ~/bot/cp_journey/progress_log.md')
      end, { desc = 'Notes: CP Journey Log' })

      -- === WHICH-KEY REGISTRATION ===
      local ok, wk = pcall(require, "which-key")
      if ok then
        if wk.add then
            -- WhichKey v3
            wk.add({
                { "<leader>n", group = "Notes / Inbox" },
                { "<leader>na", group = "Archive" },
                { "<leader>nb", group = "Bot" },
                { "<leader>ng", group = "GDrive" },
                { "<leader>np", group = "Personal" },
                { "<leader>nS", group = "System" },
                { "<leader>nw", group = "Work" },
            })
        else
            -- WhichKey v2
            wk.register({
                ["<leader>n"] = {
                    name = "+Notes / Inbox",
                    a = { name = "+Archive" },
                    b = { name = "+Bot" },
                    g = { name = "+GDrive" },
                    p = { name = "+Personal" },
                    S = { name = "+System" },
                    w = { name = "+Work" },
                }
            })
        end
      end
    end,
  },
}
