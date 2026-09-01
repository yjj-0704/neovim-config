-- ~/.config/nvim/lua/plugins/treesitter.lua
-- 语法高亮（java / cpp / python / go 等）
return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      local ok, parsers = pcall(require, "nvim-treesitter.parsers")
      if not ok then return end
      local config = require("nvim-treesitter.configs")
      config.setup({
        ensure_installed = {
          "java", "c", "cpp",
          "python", "go", "lua",
          "json", "yaml", "toml", "html", "css", "javascript", "typescript",
        },
        highlight = { enable = true, additional_vim_regex_highlighting = false },
        indent = { enable = true },
        incremental_selection = { enable = true, keymaps = { init_selection = "<C-space>" } },
        textobjects = {
          select = {
            keymaps = {
              ["af"] = "@function.outer", ["if"] = "@function.inner",
              ["ac"] = "@class.outer",    ["ic"] = "@class.inner",
              ["aa"] = "@parameter.outer", ["ia"] = "@parameter.inner",
            },
          },
        },
      })
    end,
  },
}
