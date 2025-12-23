dofile(vim.g.base46_cache .. "lsp")
require "nvchad.lsp"

local utils = require "core.utils"

-- Capabilities for LSP servers
local capabilities = vim.lsp.protocol.make_client_capabilities()

capabilities.textDocument.completion.completionItem = {
  documentationFormat = { "markdown", "plaintext" },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  },
}

-- Global LspAttach autocmd (replaces on_attach and on_init)
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("nvchad_lsp_attach", { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local bufnr = ev.buf

    -- Load keymappings
    utils.load_mappings("lspconfig", { buffer = bufnr })

    -- Signature help (skip for clangd - it returns boolean instead of table)
    if client.server_capabilities.signatureHelpProvider
       and type(client.server_capabilities.signatureHelpProvider) == "table"
       and client.name ~= "clangd" then
      require("nvchad.signature").setup(client)
    end

    -- Disable semantic tokens if configured
    if not utils.load_config().ui.lsp_semantic_tokens
       and client.supports_method "textDocument/semanticTokens" then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
})

-- Global capabilities for all servers
vim.lsp.config("*", {
  capabilities = capabilities,
})

-- lua_ls server configuration
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = {
          [vim.fn.expand "$VIMRUNTIME/lua"] = true,
          [vim.fn.expand "$VIMRUNTIME/lua/vim/lsp"] = true,
          [vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types"] = true,
          [vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy"] = true,
        },
        maxPreload = 100000,
        preloadFileSize = 10000,
      },
    },
  },
})

vim.lsp.enable("lua_ls")
