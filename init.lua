-- ~/.config/nvim/init.lua
-- 主入口：最顶层的加载顺序
require("core.options")
require("core.keymaps")
require("core.ai")   -- 提前加载（注册 provider + API key 读取）

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 加载 .env（API key）
local env_path = vim.fn.stdpath("config") .. "/.env"
local f = io.open(env_path, "r")
if f then
  for line in f:lines() do
    local k, v = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
    if k and v and not vim.env[k] then
      vim.env[k] = v
    end
  end
  f:close()
end

-- 启动插件
require("lazy").setup("plugins", {
  ui = { border = "rounded" },
  install = { missing = true },
  change_detection = { enabled = false, notify = false },
})
