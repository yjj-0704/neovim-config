# Neovim Config

一个精简的 Neovim 配置：LSP 补全 + nvim-cmp，聚焦 **Python / Java / C / C++** 四种语言的语法高亮与基本提示。

## 特性

- **LSP**：Mason + lspconfig，自动安装 jdtls / clangd / pyright
- **补全**：nvim-cmp + LuaSnip（LSP / buffer / path / snippet 四源），Tab 确认
- **Treesitter**：语法高亮（python / java / c / cpp）
- **文件树**：nvim-tree + devicons
- **诊断 UI**：trouble.nvim

## 目录结构

```
~/.config/nvim/
├── init.lua                      # 主入口：bootstrap lazy.nvim + 加载 core/*
├── lazy-lock.json                # 插件版本锁（应提交到 git）
└── lua/
    ├── core/
    │   ├── options.lua           # 编辑器基础选项
    │   └── keymaps.lua           # 全局键映射
    └── plugins/
        ├── init.lua              # lazy.nvim 入口，合并加载以下文件
        ├── cmp.lua               # nvim-cmp 配置
        ├── lsp.lua               # Mason + lspconfig
        └── treesitter.lua        # 语法解析器
```

## 安装

### 1. 备份并克隆

```bash
mv ~/.config/nvim ~/.config/nvim.bak
git clone <your-repo-url> ~/.config/nvim
```

### 2. 启动 Neovim

```bash
nvim
```

首次启动会自动：

- clone `lazy.nvim` 到 `~/.local/share/nvim/lazy/lazy.nvim`
- 安装所有插件（~ 30s）
- 通过 Mason 下载 LSP server（jdtls / clangd / pyright，按需 2-5 min）

## 键映射

### 编辑器

| 键 | 模式 | 功能 |
|---|---|---|
| `<Space>` | n | 打开 Lazy 插件管理 |
| `<Space>e` | n | 打开/关闭文件树 |
| `<Space>w` | n | 保存 |
| `<C-s>` | n | 保存 |
| `<C-q>` | n | 退出 |
| `<Esc>` | n | 清除搜索高亮 |

### 窗口

| 键 | 功能 |
|---|---|
| `<C-h/j/k/l>` | 切换窗口 |
| `<C-d>` / `<C-u>` | 向下/向上翻页（保持光标居中） |

### LSP

| 键 | 功能 |
|---|---|
| `gd` | 跳转到定义 |
| `gr` | 查找引用 |
| `K` | 显示 hover 文档 |
| `<Space>rn` | 重命名 |
| `<Space>ca` | 代码动作 |
| `<Space>f` | 格式化 |

### 补全（nvim-cmp）

| 键 | 功能 |
|---|---|
| `Tab` | 确认当前项 |
| `<S-Tab>` | 上一项 |
| `<CR>` | 确认（不改变选中项） |
| `<C-Space>` | 手动触发补全 |
| `<C-n>` / `<C-p>` | 下一项 / 上一项 |
| `<C-d>` / `<C-u>` | 文档向下/向上滚动 |
| `<C-e>` | 取消补全 |

## 主题

当前使用 `default` colorscheme。`lua/core/options.lua` 末尾改：

```lua
vim.cmd("colorscheme tokyonight")
```

需要先安装主题插件，例如在 `lua/plugins/` 下新增：

```lua
return {
  { "folke/tokyonight.nvim", lazy = false, priority = 1000, config = function() vim.cmd("colorscheme tokyonight") end },
}
```

## 手动管理插件

```vim
:Lazy            " 打开插件管理 UI
:Lazy update     " 更新所有插件
:Lazy sync       " 同步（安装缺失 + 更新 + 清理）
:Lazy clean      " 清理未使用的插件

:Mason           " 打开 Mason UI
:MasonInstall clangd
:MasonLog        " 查看 Mason 日志

:LspInfo         " 查看当前 buffer 的 LSP 状态
```

## 常见问题

### Tab 键不工作

确认你在 insert 模式下，且 `lua/plugins/cmp.lua` 已加载（`:Lazy` 查看）。

### jdtls 起不来

确保项目根目录有 `pom.xml` / `build.gradle` / `build.gradle.kts` 之一。

### clangd 找不到头文件

项目根目录放一份 `compile_commands.json`，或加 `.clangd` 文件指明 include 路径。

## 致谢

- [lazy.nvim](https://github.com/folke/lazy.nvim) — 插件管理
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) — 补全引擎
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) + [mason.nvim](https://github.com/williamboman/mason.nvim) — LSP
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) — 语法高亮
- [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) — 文件树
- [trouble.nvim](https://github.com/folke/trouble.nvim) — 诊断 UI
