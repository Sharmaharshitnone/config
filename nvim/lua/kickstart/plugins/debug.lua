-- debug.lua
--
-- Unified DAP configuration for: Go, Python, C, C++, Rust, Java
-- Adapters: delve, debugpy, codelldb, java-debug-adapter, java-test
-- All installed automatically via mason-nvim-dap.

return {
  'mfussenegger/nvim-dap',
  dependencies = {
    -- Core DAP UI
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',

    -- Mason integration — auto-installs debug adapters
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Language-specific DAP extensions
    'leoluz/nvim-dap-go', -- Go (delve)
    'mfussenegger/nvim-dap-python', -- Python (debugpy)
    'theHamsta/nvim-dap-virtual-text', -- Inline variable display
  },

  keys = {
    -- ── Session control ─────────────────────────────────────────────
    { '<F5>', function() require('dap').continue() end, desc = 'Debug: Start/Continue' },
    { '<F17>', function() require('dap').terminate() end, desc = 'Debug: Terminate (Shift+F5)' }, -- Shift+F5 = F17
    { '<F1>', function() require('dap').step_into() end, desc = 'Debug: Step Into' },
    { '<F2>', function() require('dap').step_over() end, desc = 'Debug: Step Over' },
    { '<F3>', function() require('dap').step_out() end, desc = 'Debug: Step Out' },

    -- ── Breakpoints ─────────────────────────────────────────────────
    { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'Debug: Toggle [B]reakpoint' },
    { '<M-.>', function() require('dap').toggle_breakpoint() end, desc = 'Debug: Toggle Breakpoint (Alt)' },
    { '<leader>dC', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, desc = 'Debug: [C]onditional Breakpoint' },
    { '<M->>', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, desc = 'Debug: Conditional Breakpoint (Alt)' },
    {
      '<leader>dl',
      function() require('dap').set_breakpoint(nil, nil, vim.fn.input 'Log message: ') end,
      desc = 'Debug: [L]og Point',
    },
    { '<leader>dB', function() require('dap').clear_breakpoints() end, desc = 'Debug: Clear All [B]reakpoints' },
    { '<leader>dt', function() require('dap').terminate() end, desc = 'Debug: [T]erminate' },

    -- ── UI ──────────────────────────────────────────────────────────
    { '<F7>', function() require('dapui').toggle() end, desc = 'Debug: Toggle DAP UI' },
    { '<leader>de', function() require('dapui').eval() end, desc = 'Debug: Eval Expression', mode = { 'n', 'v' } },

    -- ── Navigation ──────────────────────────────────────────────────
    { '<leader>dr', function() require('dap').run_last() end, desc = 'Debug: Run Last' },
    { '<leader>dp', function() require('dap').pause() end, desc = 'Debug: Pause' },
    { '<leader>dc', function() require('dap').run_to_cursor() end, desc = 'Debug: Run to Cursor' },
    { '<leader>dk', function() require('dap').up() end, desc = 'Debug: Stack Up' },
    { '<leader>dj', function() require('dap').down() end, desc = 'Debug: Stack Down' },

    -- ── Python-specific ─────────────────────────────────────────────
    { '<leader>dm', function() require('dap-python').test_method() end, desc = 'Debug: Python Test Method' },
    { '<leader>df', function() require('dap-python').test_class() end, desc = 'Debug: Python Test Class' },
  },

  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 1. BREAKPOINT SIGNS — Standard Unicode (Nerd Font PUA rejected by nvim 0.11)
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DiagnosticError', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DiagnosticWarn', linehl = '', numhl = '' })
    vim.fn.sign_define('DapLogPoint', { text = '◆', texthl = 'DiagnosticInfo', linehl = '', numhl = '' })
    vim.fn.sign_define('DapStopped', { text = '→', texthl = 'DiagnosticOk', linehl = 'DapStoppedLine', numhl = '' })
    vim.fn.sign_define('DapBreakpointRejected', { text = '✖', texthl = 'DiagnosticError', linehl = '', numhl = '' })

    -- Subtle highlight for the current stopped line
    vim.api.nvim_set_hl(0, 'DapStoppedLine', { bg = '#2a2a37' }) -- kanagawa dragon bg_p1 approx

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 2. MASON — auto-install all debug adapters
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    local mason_bin = vim.fn.stdpath 'data' .. '/mason/bin/'

    require('mason-nvim-dap').setup {
      automatic_installation = true,
      handlers = {
        -- Default handler for all adapters not explicitly overridden
        function(config)
          require('mason-nvim-dap').default_setup(config)
        end,

        -- codelldb: override because vim.fn.exepath('codelldb') fails
        -- when ~/.local/share/nvim/mason/bin is not on $PATH
        codelldb = function(config)
          config.adapters = {
            type = 'server',
            port = '${port}',
            executable = {
              command = mason_bin .. 'codelldb',
              args = { '--port', '${port}' },
            },
          }
          require('mason-nvim-dap').default_setup(config)
        end,
      },
      ensure_installed = {
        'delve', -- Go
        'python', -- debugpy (Python)
        'codelldb', -- C, C++, Rust, Zig
        'javadbg', -- java-debug-adapter
        'javatest', -- java-test
      },
    }

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 3. DAP UI — professional layout
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    dapui.setup {
      icons = { expanded = '▾', collapsed = '▸', current_frame = '▶' },
      controls = {
        enabled = true,
        element = 'repl',
        icons = {
          pause = '',
          play = '▶',
          step_into = '󰆹',
          step_over = '',
          step_out = '󰆸',
          step_back = '',
          run_last = '󰜎',
          terminate = '✖',
          disconnect = '',
        },
      },
      layouts = {
        { -- Left sidebar: scopes + breakpoints + stacks + watches
          elements = {
            { id = 'scopes', size = 0.35 },
            { id = 'breakpoints', size = 0.15 },
            { id = 'stacks', size = 0.25 },
            { id = 'watches', size = 0.25 },
          },
          position = 'left',
          size = 40,
        },
        { -- Bottom panel: REPL + console
          elements = {
            { id = 'repl', size = 0.5 },
            { id = 'console', size = 0.5 },
          },
          position = 'bottom',
          size = 12,
        },
      },
      floating = {
        border = 'rounded',
        max_height = 0.8,
        max_width = 0.8,
      },
    }

    -- Auto open/close DAP UI on debug session lifecycle
    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 4. VIRTUAL TEXT — inline variable values while debugging
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    require('nvim-dap-virtual-text').setup {
      enabled = true,
      enabled_commands = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = false,
      show_stop_reason = true,
      commented = true, -- prefix with comment syntax: // x = 42
      virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'inline'
    }

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 5. LANGUAGE-SPECIFIC CONFIGURATIONS
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    -- ── Go (delve) ──────────────────────────────────────────────────
    require('dap-go').setup {
      delve = {
        -- Use the delve installed by mason
        path = vim.fn.stdpath 'data' .. '/mason/bin/dlv',
        initialize_timeout_sec = 20,
        port = '${port}',
      },
    }

    -- ── Python (debugpy) ────────────────────────────────────────────
    -- Uses the debugpy-adapter installed by mason. Automatically detects
    -- virtualenvs (venv, conda, poetry, pyenv).
    require('dap-python').setup(vim.fn.stdpath 'data' .. '/mason/packages/debugpy/venv/bin/python')
    require('dap-python').test_runner = 'pytest' -- or 'unittest'

    -- ── C / C++ / Rust (codelldb) ───────────────────────────────────
    -- mason-nvim-dap auto-configures codelldb via the empty handlers = {} above.
    -- We just need to set up the DAP configurations for each filetype.
    -- codelldb adapter is registered automatically by mason-nvim-dap.

    -- C++ launch configuration
    dap.configurations.cpp = {
      {
        name = 'Launch (C++)',
        type = 'codelldb',
        request = 'launch',
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = function()
          local input = vim.fn.input 'Arguments: '
          return vim.split(input, ' ', { trimempty = true })
        end,
      },
      {
        name = 'Attach to process (C++)',
        type = 'codelldb',
        request = 'attach',
        pid = require('dap.utils').pick_process,
        cwd = '${workspaceFolder}',
      },
    }

    -- C shares the same config as C++
    dap.configurations.c = dap.configurations.cpp

    -- Rust — codelldb is also used by rustaceanvim's :RustLsp debuggables.
    -- This manual config is a fallback for when you want plain dap.continue().
    dap.configurations.rust = {
      {
        name = 'Launch (Rust)',
        type = 'codelldb',
        request = 'launch',
        program = function()
          -- Try to find the binary in target/debug
          local cwd = vim.fn.getcwd()
          local project_name = vim.fn.fnamemodify(cwd, ':t')
          local default_path = cwd .. '/target/debug/' .. project_name
          return vim.fn.input('Path to executable: ', default_path, 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
      },
    }

    -- ── Java (java-debug-adapter + java-test) ──────────────────────
    -- Java debugging is handled via nvim-jdtls. The debug adapters
    -- (java-debug-adapter, java-test) are JAR bundles loaded by jdtls.
    -- See ftplugin/java.lua for bundle configuration.
    -- mason-nvim-dap installs the JARs; jdtls loads them at attach time.

    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 6. WHICH-KEY GROUP REGISTRATION
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    local ok_wk, wk = pcall(require, 'which-key')
    if ok_wk then
      wk.add {
        { '<leader>d', group = '[D]ebug' },
      }
    end
  end,
}
