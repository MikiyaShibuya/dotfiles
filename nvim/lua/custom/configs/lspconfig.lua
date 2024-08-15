local config = require("plugins.configs.lspconfig")

local on_attach = config.on_attach
local capabilities = config.capabilities

local lspconfig = require("lspconfig")

lspconfig.basedpyright.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = {"python"},
  settings = {
    pyright = {
      autoImportCompletion = true,
      useLibraryCodeForTypes = true
    },
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = 'openFilesOnly',
        useLibraryCodeForTypes = true,
        typeCheckingMode = 'off'
      }
    },
    basedpyright = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = 'openFilesOnly',
        useLibraryCodeForTypes = true,
        typeCheckingMode = 'all',
        autoImportCompletions = true,
        diagnosticSeverityOverrides = {
          reportMissingTypeStubs = false,
          reportUnknownParameterType = false,
          reportUnknownVariableType = false,
          reportUnknownMemberType = false,
        },
      }
    }
  }
})

vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
