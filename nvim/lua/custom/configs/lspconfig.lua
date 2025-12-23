-- basedpyright server configuration
vim.lsp.config("basedpyright", {
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
          reportUnannotatedClassAttribute = false,
          reportExplicitAny = 'warning',
          reportUnknownLambdaType = false,
        },
      }
    }
  }
})

vim.lsp.enable("basedpyright")

-- ts_ls server configuration
vim.lsp.config("ts_ls", {
  filetypes = {"javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx"},
})

vim.lsp.enable("ts_ls")

-- clangd server configuration
vim.lsp.config("clangd", {})

vim.lsp.enable("clangd")

-- Server-specific LspAttach handlers
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("custom_lsp_attach", { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    -- Enable inlay hints for basedpyright
    if client.name == "basedpyright" then
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
    end

  end,
})

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
    -- Skip if in command-line mode (e.g., during search) or visual mode
    local mode = vim.api.nvim_get_mode().mode
    if mode:match("[cCtv]") then
      return
    end
    vim.diagnostic.open_float(nil, {focus=false, scope="cursor"})
  end
})
