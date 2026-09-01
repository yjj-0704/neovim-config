-- ~/.config/nvim/lua/core/keymaps.lua
local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- 基础
keymap.set("n", "<Esc>", "<cmd>noh<cr>", opts)
keymap.set("n", "<C-s>", "<cmd>w<cr>", opts)
keymap.set("n", "<C-q>", "<cmd>qa<cr>", opts)

-- 窗口
keymap.set("n", "<C-h>", "<C-w>h", opts)
keymap.set("n", "<C-l>", "<C-w>l", opts)
keymap.set("n", "<C-j>", "<C-w>j", opts)
keymap.set("n", "<C-k>", "<C-w>k", opts)

-- 移动（保持光标居中）
keymap.set("n", "<C-d>", "<C-d>zz", opts)
keymap.set("n", "<C-u>", "<C-u>zz", opts)
keymap.set("n", "n", "nzzzv", opts)
keymap.set("n", "N", "Nzzzv", opts)

-- Leader 快捷键提示
keymap.set("n", "<leader>", "<cmd>Lazy<cr>", { desc = "Lazy" })
keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "File tree" })
keymap.set("n", "<leader>w", "<cmd>w<cr>", opts)

-- AI provider 切换（normal 模式）
keymap.set("n", "<leader>aa", function() require("core.ai").cycle() end, { desc = "Cycle AI provider" })
keymap.set("n", "<leader>as", function() require("core.ai").status() end, { desc = "AI status" })
-- 插入模式下手动触发 AI（Tab 行为外的显式触发）
keymap.set("i", "<C-x><C-a>", function() require("core.ai").insert() end, { desc = "AI complete (insert)" })

-- LSP
keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Goto definition" })
keymap.set("n", "gr", vim.lsp.buf.references, { desc = "References" })
keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
keymap.set("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, { desc = "Format" })

-- Tab 键：交给 nvim-cmp 接管（trae 风格）
-- 见 plugins/cmp.lua
