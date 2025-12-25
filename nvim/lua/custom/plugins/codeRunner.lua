return {
  {
    'CRAG666/code_runner.nvim',
    config = function()
      local ok, code_runner = pcall(require, 'code_runner')
      if not ok then
        vim.notify('code_runner.nvim not installed', vim.log.levels.WARN)
        return
      end

      -- Modern project root finder
      local function find_project_root()
        local root_files = {
          -- Java
          'gradlew', 'mvnw', 'pom.xml', 'build.gradle',
          -- JS/TS (Bun removed)
          'package.json', 'deno.json', 'nx.json', 'turbo.json',
          -- Rust/Go
          'Cargo.toml', 'go.mod',
          -- C/C++
          'CMakeLists.txt', 'Makefile'
        }

        -- Search upward from the *current buffer's* directory
        local current_dir = vim.fn.expand('%:p:h')
        local root = vim.fs.find(root_files, { path = current_dir, upward = true })[1]

        if root then
          return vim.fs.dirname(root)
        end
        return nil
      end

      code_runner.setup({
        mode = 'float',
        focus = true,
        startinsert = false,
        float = { border = 'rounded', width = 0.9, height = 0.8 },
        term = { clean = true, init = 1 },

        before_run_filetype = function()
          if vim.fn.bufname('%') ~= "" then
            pcall(vim.cmd, 'write')
          end
        end,

        filetype = {
          java = function()
            local root = find_project_root()
            if root then
              local cd_cmd = 'cd ' .. root
              -- Use 'sh' for wrappers to avoid permission issues
              if vim.fn.filereadable(root .. '/gradlew') == 1 then
                return cd_cmd .. ' && sh ./gradlew run'
              elseif vim.fn.filereadable(root .. '/mvnw') == 1 then
                return cd_cmd .. ' && sh ./mvnw -q -DskipTests package && java -jar target/*.jar'
              elseif vim.fn.filereadable(root .. '/pom.xml') == 1 then
                return cd_cmd .. ' && mvn -q -DskipTests package && java -jar target/*.jar'
              end
            end
            -- Single file fallback
            -- For Java 21+ (Bleeding Edge), you can just run 'java filename.java' directly.
            -- This command supports both old and new ways:
            return 'javac $fileName && java -cp $dir $fileNameWithoutExt'
          end,

          typescript = function()
            local root = find_project_root()
            -- We want to run command typically from the project root if found,
            -- otherwise we use current file directory or global scope.

            -- 1. Deno Project
            if root and (vim.fn.filereadable(root .. '/deno.json') == 1 or vim.fn.filereadable(root .. '/deno.jsonc') == 1) then
              return 'deno run --allow-all $file'
            end

            -- 2. Local Project Context (node_modules)
            -- This ensures we use the project's installed 'tsx' version and configuration.
            if root then
                local local_tsx = root .. '/node_modules/.bin/tsx'
                if vim.fn.filereadable(local_tsx) == 1 then
                    -- Run using the local binary, relative to CWD might be needed or full path
                    return local_tsx .. ' $file'
                end
                
                local local_tsnode = root .. '/node_modules/.bin/ts-node'
                if vim.fn.filereadable(local_tsnode) == 1 then
                    return local_tsnode .. ' $file'
                end
            end

            -- 3. Global / Scratch File Fallbacks
            if vim.fn.executable('pnpm') == 1 then
              return 'pnpm dlx tsx $file'
            end
            
            if vim.fn.executable('npx') == 1 then
              return 'npx tsx $file'
            end
            
            -- 4. Final Fallback
            return 'tsc $fileName && node $dir/$fileNameWithoutExt.js && rm $dir/$fileNameWithoutExt.js'
          end,

          javascript = function()
            return 'node $file'
          end,

          -- Bleeding Edge C++ (C++23)
          cpp = function()
            local f = vim.fn.expand('%:p')
            -- Output binary to /tmp to keep project clean
            local out = '/tmp/' .. vim.fn.fnamemodify(f, ':t:r')
            return {
              'g++ -std=c++23 -O3 -march=native -Wall -Wextra -DLOCAL ' .. vim.fn.shellescape(f) .. ' -o ' .. out .. ' &&',
              out
            }
          end,

          -- Bleeding Edge C (C23)
          c = function()
            local f = vim.fn.expand('%:p')
            local out = '/tmp/' .. vim.fn.fnamemodify(f, ':t:r')
            return {
              'gcc -std=c23 -O3 -march=native -Wall -Wextra -DLOCAL ' .. vim.fn.shellescape(f) .. ' -o ' .. out .. ' &&',
              out
            }
          end,

          rust = function()
            local root = find_project_root()
            if root and vim.fn.filereadable(root .. '/Cargo.toml') == 1 then
              return 'cd ' .. root .. ' && cargo run'
            end
            -- Single file rust: compile to tmp and run
            local f = vim.fn.expand('%:p')
            local out = '/tmp/' .. vim.fn.fnamemodify(f, ':t:r')
            return 'rustc ' .. vim.fn.shellescape(f) .. ' -o ' .. out .. ' && ' .. out
          end,

          python = function()
            return 'python3 -u ' .. vim.fn.shellescape(vim.fn.expand('%:p'))
          end,

          go = function()
            local root = find_project_root()
            if root and vim.fn.filereadable(root .. '/go.mod') == 1 then
              return 'cd ' .. root .. ' && go run .'
            end
            return 'go run ' .. vim.fn.shellescape(vim.fn.expand('%:p'))
          end
        },

        focus_on_run = true,
        hot_reload = false,
      })

      -- Keymaps
      local opts = { noremap = true, silent = true }
      vim.keymap.set('n', '<leader>r', ':RunCode<CR>', opts)
      vim.keymap.set('n', '<leader>rf', ':RunFile<CR>', opts)
      vim.keymap.set('n', '<leader>rp', ':RunProject<CR>', opts)
      vim.keymap.set('n', '<leader>rc', ':RunClose<CR>', opts)
    end,
  },
}
