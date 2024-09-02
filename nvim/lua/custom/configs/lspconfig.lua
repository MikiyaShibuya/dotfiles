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
          reportUnusedCallResult = false,
          reportUnknownArgumentType = false,
          reportImplicitOverride = false,
          reportUnnecessaryIsInstance = false,
          reportUnreachable = 'warning',
          reportAny = false,
          reportUnnecessaryComparison = false,
          reportMissingTypeArgument = false,
          reportUnusedParameter = 'warning',
          reportUnusedImport = 'warning',
          reportConstantRedefinition = 'warning',
        },
      }
    }
  }
})

lspconfig.tsserver.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = {"javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx"},
})

-- Enable inlay hint
vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })

-- Disable virtual text
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics,
  {
    virtual_text = false,
    signs = true,
    update_in_insert = false,
    underline = true,
  }
)

-- Show diagnostics on cursor hold; no focusable, only show at cursor
-- https://github.com/neovim/nvim-lspconfig/wiki/UI-Customization#show-line-diagnostics-automatically-in-hover-window
vim.o.updatetime = 250
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  group = vim.api.nvim_create_augroup("float_diagnostic", { clear = true }),
  callback = function ()
    vim.diagnostic.open_float(nil, {focus=false, scope="cursor"})
  end
})
