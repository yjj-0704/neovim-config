-- ~/.config/nvim/lua/core/options.lua
local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.colorcolumn = "80"
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.breakindent = true
opt.confirm = true
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 250
opt.timeoutlen = 400
opt.splitbelow = true
opt.splitright = true
opt.termguicolors = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.showmode = false

opt.fillchars = { eob = " ", fold = " " }

-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 默认主题（在 lazy 里覆盖为 onedark/tokyonight 也可）
vim.cmd("colorscheme default")
