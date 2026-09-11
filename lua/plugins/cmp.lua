-- ~/.config/nvim/lua/plugins/cmp.lua
-- nvim-cmp 基本补全：LSP + buffer + path + snippet
return {
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "neovim/nvim-lspconfig",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      local cmp = require("cmp")

      cmp.setup({
        completion = { completeopt = "menu,menuone,noinsert,noselect" },
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 },
          { name = "buffer",   priority =  500, keyword_length = 2 },
          { name = "path",     priority =  300 },
          { name = "luasnip",  priority = 2000 },
        }),
        snippet = {
          expand = function(args) require("luasnip").lsp_expand(args.body) end,
        },
        window = {
          completion    = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-n>"]     = cmp.mapping.select_next_item({ select = false }),
          ["<C-p>"]     = cmp.mapping.select_prev_item({ select = false }),
          ["<C-d>"]     = cmp.mapping.scroll_docs(4),
          ["<C-u>"]     = cmp.mapping.scroll_docs(-4),
          ["<C-e>"]     = cmp.mapping.abort(),
          ["<CR>"]      = cmp.mapping.confirm({ select = false }),
          ["<Tab>"]     = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.confirm({ select = true }) else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"]   = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item() else fallback() end
          end, { "i", "s" }),
        }),
        experimental = { ghost_text = false },
      })

      local function hi(g, o) o.default = true; vim.api.nvim_set_hl(0, g, o) end
      hi("Pmenu",        { fg = "#d4d4d4", bg = "#1e1e1e" })
      hi("PmenuSel",     { fg = "#ffffff", bg = "#094771", bold = true })
      hi("PmenuSbar",    { bg = "#2d2d2d" })
      hi("PmenuThumb",   { bg = "#007acc" })
      hi("PmenuKind",    { fg = "#9cdcfe", bg = "#1e1e1e" })
      hi("PmenuKindSel", { fg = "#ffffff", bg = "#094771" })
      hi("PmenuExtra",   { fg = "#858585", bg = "#1e1e1e" })
      hi("PmenuExtraSel",{ fg = "#ffffff", bg = "#094771" })
      hi("NormalFloat",  { bg = "#1e1e1e" })
      hi("FloatBorder",  { fg = "#3c3c3c"  })
    end,
  },

  {
    "L3MON4D3/LuaSnip",
    dependencies = "rafamadriz/friendly-snippets",
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
}
