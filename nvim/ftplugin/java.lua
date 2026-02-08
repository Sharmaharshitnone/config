-- Resolve jdtls path before config
local jdtls_path
local ok_registry, registry = pcall(require, 'mason-registry')
if ok_registry then
  local success_pkg, pkg = pcall(function()
    return registry.get_package and registry.get_package('jdtls')
  end)

  if success_pkg and pkg then
    -- Prefer the official API method if available
    if type(pkg.get_install_path) == 'function' then
      jdtls_path = pkg:get_install_path() .. '/bin/jdtls'
    -- Fallback to common field name used by some versions
    elseif pkg.install_path then
      jdtls_path = pkg.install_path .. '/bin/jdtls'
    else
      jdtls_path = vim.fn.stdpath('data') .. '/mason/bin/jdtls'
    end
  else
    jdtls_path = vim.fn.stdpath('data') .. '/mason/bin/jdtls'
  end
else
  jdtls_path = vim.fn.stdpath('data') .. '/mason/bin/jdtls'
end

-- ── Resolve java-debug-adapter and java-test bundles ────────────
-- These JARs are required for nvim-dap to debug Java via jdtls.
local bundles = {}
local mason_path = vim.fn.stdpath 'data' .. '/mason/packages'

-- java-debug-adapter
local java_dbg_jar = vim.fn.glob(mason_path .. '/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar', true)
if java_dbg_jar ~= '' then
  table.insert(bundles, java_dbg_jar)
end

-- java-test (vscode-java-test)
local java_test_jars = vim.fn.glob(mason_path .. '/java-test/extension/server/*.jar', true, true)
if java_test_jars then
  for _, jar in ipairs(java_test_jars) do
    -- Exclude the runner JAR (it's not a bundle, it's launched separately)
    if not vim.endswith(jar, 'com.microsoft.java.test.runner-jar-with-dependencies.jar') then
      table.insert(bundles, jar)
    end
  end
end

local config = {
  name = 'jdtls',

  -- `cmd` must be a table of strings, not a function
  cmd = { jdtls_path },

  -- `root_dir` must point to the root of your project.
  -- See `:help vim.fs.root`
  root_dir = vim.fs.root(0, { 'gradlew', '.git', 'mvnw' }),

  -- Load java-debug + java-test bundles for DAP integration
  init_options = {
    bundles = bundles,
  },
}

-- Use protected call to require jdtls
local ok, jdtls = pcall(require, 'jdtls')
if not ok then
  vim.notify('nvim-jdtls not found! Please install it with :Lazy sync', vim.log.levels.ERROR)
  return
end

-- Check if jdtls executable exists
local jdtls_cmd = vim.fn.expand('~/.local/share/nvim/mason/bin/jdtls')
if vim.fn.executable(jdtls_cmd) == 0 then
  vim.notify('jdtls executable not found at: ' .. jdtls_cmd .. '\nPlease install it with :MasonInstall jdtls', vim.log.levels.ERROR)
  return
end

jdtls.start_or_attach(config)

-- Register DAP configurations after jdtls attaches
-- This enables :RustLsp debuggables-style workflow for Java
vim.api.nvim_create_autocmd('LspAttach', {
  pattern = '*.java',
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == 'jdtls' then
      -- Setup DAP for Java (requires java-debug-adapter bundle)
      pcall(jdtls.setup_dap, { hotcodereplace = 'auto' })

      -- Java debug keymaps
      local opts = { buffer = args.buf, noremap = true, silent = true }
      vim.keymap.set('n', '<leader>jt', function() jdtls.test_nearest_method() end, vim.tbl_extend('force', opts, { desc = 'Java: Debug Test Method' }))
      vim.keymap.set('n', '<leader>jT', function() jdtls.test_class() end, vim.tbl_extend('force', opts, { desc = 'Java: Debug Test Class' }))
      vim.keymap.set('n', '<leader>jo', function() jdtls.organize_imports() end, vim.tbl_extend('force', opts, { desc = 'Java: Organize Imports' }))
    end
  end,
  once = false,
})
