-- lua/utils/compat.lua
-- Centralised Neovim version-compatibility helpers.
-- Usage:  local compat = require("utils.compat")
--         if compat.nvim_011 then ... end

local M = {}

--- @param feature string  e.g. "nvim-0.10", "nvim-0.11"
M.has = function(feature)
    return vim.fn.has(feature) == 1
end

M.nvim_010 = M.has("nvim-0.10")
M.nvim_011 = M.has("nvim-0.11")

--- Portable diagnostic enable/disable.
--- nvim 0.10+ deprecated vim.diagnostic.disable() in favour of
--- vim.diagnostic.enable(false, …).
M.diagnostic_disable = function(bufnr)
    if M.nvim_010 then
        vim.diagnostic.enable(false, bufnr and { bufnr = bufnr } or nil)
    else
        ---@diagnostic disable-next-line: deprecated
        vim.diagnostic.disable(bufnr)
    end
end

M.diagnostic_enable = function(bufnr)
    if M.nvim_010 then
        vim.diagnostic.enable(true, bufnr and { bufnr = bufnr } or nil)
    else
        vim.diagnostic.enable(bufnr)
    end
end

--- Setup an LSP server in a way that works on nvim 0.10 (lspconfig) AND
--- nvim 0.11+ (native vim.lsp.config / vim.lsp.enable).
---
--- @param name   string   LSP server name, e.g. "ts_ls"
--- @param opts   table    Options forwarded to the setup call
M.lsp_setup = function(name, opts)
    if M.nvim_011 and vim.lsp.config then
        -- On 0.11+ with lspconfig installed, just call vim.lsp.config().
        -- lspconfig hooks into the native API and calls vim.lsp.enable
        -- automatically for all known servers — calling it again ourselves
        -- can interfere with mason-lspconfig's lifecycle.
        vim.lsp.config(name, opts)
    else
        local ok, lspconfig = pcall(require, "lspconfig")
        if ok and lspconfig[name] then
            lspconfig[name].setup(opts)
        else
            vim.notify(
                ("lsp_setup: server '%s' not found"):format(name),
                vim.log.levels.WARN
            )
        end
    end
end

return M
