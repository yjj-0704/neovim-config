-- ~/.config/nvim/lua/plugins/lsp.lua
-- Mason + lspconfig：jdtls / clangd / pyright
return {
  -- Mason 自身
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        ui = { border = "rounded" },
        log_level = vim.log.levels.INFO,
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "jdtls",    -- Java
          "clangd",   -- C/C++
          "pyright",  -- Python
        },
        automatic_installation = true,
        automatic_enable = true,
      })
    end,
  },
  -- lspconfig
  {
    "neovim/nvim-lspconfig",
    event = { "InsertEnter", "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "mason-lspconfig.nvim",
    },
    config = function()
      local lspconfig = require("lspconfig")
      local cmp_nvim_lsp = require("cmp_nvim_lsp")
      local capabilities = cmp_nvim_lsp.default_capabilities()

      -- 统一 on_attach
      local on_attach = function(client, bufnr)
        local nmap = function(keys, rhs) vim.keymap.set("n", keys, rhs, { buffer = bufnr, silent = true }) end
        nmap("gd", vim.lsp.buf.definition)
        nmap("gr", vim.lsp.buf.references)
        nmap("gi", vim.lsp.buf.implementation)
        nmap("K",  vim.lsp.buf.hover)
        nmap("<leader>rn", vim.lsp.buf.rename)
        nmap("<leader>ca", vim.lsp.buf.code_action)
        nmap("<leader>f",  function() vim.lsp.buf.format({ async = true }) end)
      end

      -- Java (jdtls)
      lspconfig.jdtls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        cmd = { "jdtls" },
        filetypes = { "java" },
        root_dir = function(fname)
          local util = require("lspconfig.util")
          return util.root_pattern("pom.xml", "build.gradle", "build.gradle.kts", ".git")(fname)
        end,
        settings = {
          java = { format = { url = "http://localhost:8010/" } },
        },
        init_options = {
          eclipse = { downloadSources = true },
        },
      })

      -- C/C++ (clangd)
      lspconfig.clangd.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        cmd = { "clangd", "--background-index", "--clang-tidy" },
        filetypes = { "c", "cpp", "objc", "objcpp" },
        root_dir = function(fname)
          local util = require("lspconfig.util")
          return util.root_pattern("compile_commands.json", "Makefile", ".clangd", ".git")(fname)
        end,
      })

      -- Python (pyright)
      lspconfig.pyright.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          pyright = { disable = false, useLibraryCodeForTypes = true },
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "openFilesOnly",
            },
          },
        },
      })

    end,
  },

  -- Diagnostic UI
  {
    "folke/trouble.nvim",
    cmd = { "Trouble", "TroubleToggle" },
    dependencies = { "nvim-tree/nvim-web-devicons", "nvim-lua/plenary.nvim" },
    opts = { use_diagnostic_signs = true, icons = true },
  },
}
