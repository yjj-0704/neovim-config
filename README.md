# Neovim Config

一个聚焦 **AI 驱动开发** 的 Neovim 配置：传统 LSP 补全 + 多 provider AI 内联补全（Trae / Copilot 风格），开箱支持 Java / C/C++ / Python / Go / Lua。

## 特性

- **LSP**：Mason + lspconfig，自动安装 jdtls / clangd / pyright / gopls / lua-language-server
- **补全**：nvim-cmp + LuaSnip，Tab 确认，`Esc` 拒绝
- **AI 内联补全**：多 provider（MiniMax / GLM / DeepSeek）流式响应，输入停顿 500ms 自动出现灰色 ghost text
- **Treesitter**：语法高亮 + 缩进 + 文本对象
- **文件树**：nvim-tree + devicons
- **诊断 UI**：trouble.nvim

## 目录结构

```
~/.config/nvim/
├── init.lua                      # 主入口：bootstrap lazy.nvim + 加载 core/*
├── lazy-lock.json                # 插件版本锁（应提交到 git）
├── .env                          # API key（⚠️ 不要提交）
└── lua/
    ├── core/
    │   ├── options.lua           # 编辑器基础选项
    │   ├── keymaps.lua           # 全局键映射
    │   └── ai.lua                # AI 补全核心（ghost text / 流式 / 键映射）
    └── plugins/
        ├── init.lua              # lazy.nvim 入口，合并加载以下文件
        ├── cmp.lua               # nvim-cmp 配置（Tab 确认、AI ghost 协作）
        ├── lsp.lua               # Mason + lspconfig
        └── treesitter.lua        # 语法解析器
```

## 安装

### 1. 备份并克隆

```bash
# 备份旧配置（如果有）
mv ~/.config/nvim ~/.config/nvim.bak

# 克隆本仓库
git clone <your-repo-url> ~/.config/nvim
```

### 2. 配置 API key

AI 补全需要至少一个 provider 的 API key。复制模板：

```bash
cp .env.example ~/.config/nvim/.env
vim ~/.config/nvim/.env
```

填入 key：

```bash
MINIMAX_API_KEY=your_minimax_key
GLM_API_KEY=your_glm_key         # 可选
DS_API_KEY=your_deepseek_key     # 可选
```

### 3. 启动 Neovim

```bash
nvim
```

首次启动会自动：
- clone `lazy.nvim` 到 `~/.local/share/nvim/lazy/lazy.nvim`
- 安装所有插件（~ 30s）
- 通过 Mason 下载 LSP server（jdtls/clangd/pyright/gopls/lua-language-server，按需 2-5 min）

### 4. Go 用户额外步骤

Mason 通过 `go install` 构建 gopls，需要 Go 1.22+：

```bash
# Debian / Ubuntu
sudo apt install -y golang-go

# 或者新版 Go
curl -fsSL https://go.dev/dl/go1.24.linux-amd64.tar.gz | sudo tar -C /usr/local -xz
export PATH=$PATH:/usr/local/go/bin
```

国内网络需要配置 Go proxy：

```bash
mkdir -p ~/.config/go
cat > ~/.config/go/env <<'EOF'
GOPROXY=https://goproxy.cn,direct
GOSUMDB=sum.golang.google.cn
EOF
```

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
| `Tab` | 确认当前项（nvim-cmp 选中项 或 AI ghost） |
| `<S-Tab>` | 上一项 / 拒绝 AI ghost |
| `<CR>` | 确认（不改变选中项） |
| `<C-Space>` | 手动触发补全 |
| `<C-n>` / `<C-p>` | 下一项 / 上一项 |
| `<C-d>` / `<C-u>` | 文档向下/向上滚动 |
| `<C-e>` | 取消补全 |
| `<Esc>` | 拒绝 AI ghost |

### AI 补全

| 键 | 模式 | 功能 |
|---|---|---|
| `<C-F1>` | i/n | 立即强制触发 AI |
| `<C-S-Tab>` | i/n | 拒绝 AI ghost / 取消在飞请求 |
| `<C-S-F1>` | i/n | 同上（部分终端备选） |
| `<Space>ai` | n | 切换 provider |
| `<Space>as` | n | 显示所有 provider 状态 |
| `<C-x><C-a>` | i | AI 立即插入（跳过 ghost 预览） |

## AI 补全行为

- **自动触发**：insert 模式下停顿 500ms 自动发起请求
- **流式响应**：使用 SSE，边收 token 边渲染 ghost text（首 token 通常 < 1s）
- **去抖**：连续打字会重置定时器，不会乱发请求
- **避让**：LSP 弹窗在场时不触发 AI；用户继续输入时自动取消在飞请求
- **不触发场景**：光标在空白行 / buffer 只读 / 不在 insert 模式

## AI Provider 切换

`<Space>ai` 循环切换：MiniMax → GLM → DeepSeek → ...

`<Space>as` 查看所有 provider 状态：

```
AI providers status:
  ✓ minimax  MiniMax  MiniMax-Text-01
  ✗ glm      GLM      missing GLM_API_KEY
  ✓ ds       DeepSeek deepseek-coder
  current: minimax
```

## 环境变量

写在 `~/.config/nvim/.env`（格式 `KEY=value`，每行一个）：

### 必填（至少一个）

```bash
MINIMAX_API_KEY=...
GLM_API_KEY=...
DS_API_KEY=...
```

### 可选：覆盖默认 endpoint / model

```bash
MINIMAX_BASE_URL=https://api.minimax.chat/v1
MINIMAX_MODEL=MiniMax-Text-01
GLM_BASE_URL=https://open.bigmodel.cn/api/paas/v4
GLM_MODEL=glm-4-plus
DS_BASE_URL=https://api.deepseek.com/v1
DS_MODEL=deepseek-coder
```

### 可选：调优 AI 行为

```bash
AI_AUTOTRIGGER_MS=500      # 自动触发防抖（毫秒）；0 = 关闭自动触发
AI_MAX_TOKENS=96           # 单次响应 token 上限
AI_CTX_BEFORE=25           # 发送给 AI 的光标前行数
AI_CTX_AFTER=10            # 发送给 AI 的光标后行数
AI_STREAM=1                # 1=流式（默认），0=一次性响应
AI_TEMP=0.1                # 采样温度
AI_TIMEOUT=30              # 单次请求超时（秒）
```

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

## 常见问题

### Mason 装 gopls 失败

```
[mason-lspconfig.nvim] failed to install gopls
```

1. 确认 `go version` 输出正常
2. 配置 Go proxy（见上文）
3. `:Mason` 打开 UI 重试，或 `:MasonInstall gopls`

### 自动触发没反应

1. `:checkhealth` 看 LSP 是否 attach
2. `<Space>as` 看 AI 是否 ready
3. 临时关闭再开：`AI_AUTOTRIGGER=1 nvim`

### Tab 键不工作

确认你在 insert 模式下，且 `lua/plugins/cmp.lua` 已加载（`:Lazy` 查看）。

### ghost text 位置错乱

已用 `safe_cursor()` 钳制越界光标。如果还出现，`:lua print(vim.inspect(vim.api.nvim_win_get_cursor(0)))` 看光标位置。

## 手动管理插件

```vim
:Lazy            " 打开插件管理 UI
:Lazy update     " 更新所有插件
:Lazy sync       " 同步（安装缺失 + 更新 + 清理）
:Lazy clean      " 清理未使用的插件

:Mason           " 打开 Mason UI
:MasonInstall gopls
:MasonLog        " 查看 Mason 日志

:LspInfo         " 查看当前 buffer 的 LSP 状态
```

## 致谢

- [lazy.nvim](https://github.com/folke/lazy.nvim) — 插件管理
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) — 补全引擎
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) + [mason.nvim](https://github.com/williamboman/mason.nvim) — LSP
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) — 语法高亮
- [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) — 文件树
- [trouble.nvim](https://github.com/folke/trouble.nvim) — 诊断 UI
