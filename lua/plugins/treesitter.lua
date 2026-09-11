-- ~/.config/nvim/lua/plugins/treesitter.lua
-- 仅做语法高亮：python / java / c / cpp
return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local ok, parsers = pcall(require, "nvim-treesitter.parsers")
      if not ok then return end
      local config = require("nvim-treesitter.configs")
      config.setup({
        ensure_installed = { "python", "java", "c", "cpp" },
        highlight = { enable = true, additional_vim_regex_highlighting = false },
      })
    end,
  },
}
