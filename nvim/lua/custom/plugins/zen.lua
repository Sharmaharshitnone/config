local function get_visual_selection()
  -- Exit visual mode to update the '< and '> marks
  vim.cmd('noau normal! "vy')
  local text = vim.fn.getreg("v")
  vim.fn.setreg("v", {}) -- Clear the register to be clean
  return text
end

return {
-- Helper function to get visually selected text

-- Keymap: <leader>z to search Zeal (Supports Normal & Visual modes)
vim.keymap.set({"n", "v"}, "<leader>z", function()
  local query = ""
  local mode = vim.fn.mode()

  -- 1. Determine what to search
  if mode == "v" or mode == "V" or mode == "\22" then
    -- If in Visual mode, get the selection
    query = get_visual_selection()
    -- Clean up newlines for multi-line selections (flatten them)
    query = string.gsub(query, "\n", " ")
  else
    -- If in Normal mode, just get the word under cursor
    query = vim.fn.expand("<cword>")
  end

  -- 2. Map Neovim filetypes to Zeal Docset prefixes
  local docset_map = {
    cpp = "Cpp:",
    c = "c++:",
    cmake = "cmake:",
    python = "python:",
    sh = "bash:",
    lua = "lua:",
    rust = "rust:",
    go = "go:"
  }

  -- 3. Build the final query
  local ft = vim.bo.filetype
  local prefix = docset_map[ft] or ""
  -- Trim whitespace from the query
  query = string.gsub(query, "^%s*(.-)%s*$", "%1")
  local final_query = prefix .. query

  -- 4. Execute Zeal silently
  vim.fn.jobstart({"zeal", final_query}, { detach = true })

end, { desc = "[Z]eal Search (Word/Selection)" })
}

