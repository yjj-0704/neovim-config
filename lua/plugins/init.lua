-- ~/.config/nvim/lua/plugins/init.lua
-- lazy.nvim 入口：合并加载 plugins/*.lua
local function merge(...)
  local out = {}
  for _, spec in ipairs({...}) do
    if type(spec) == "table" then
      for _, p in ipairs(spec) do out[#out + 1] = p end
    end
  end
  return out
end

return merge(
  require("plugins.cmp"),
  require("plugins.lsp"),
  require("plugins.treesitter"),
  {
    {
      "nvim-tree/nvim-tree.lua",
      dependencies = {
        "nvim-tree/nvim-web-devicons",
        config = function()
          require("nvim-tree.api").configure.defaults()
        end,
      },
      cmd = { "NvimTreeToggle", "NvimTreeFindFile" },
      opts = {
        view = { width = 30 },
        renderer = { indent_markers = { enable = false } },
      },
      keymap = { vim.api.nvim_replace_termcodes("<C-n>", true, true, true) },
    },
  }
)
