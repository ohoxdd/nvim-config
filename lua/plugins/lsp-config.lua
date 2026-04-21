-- lua/plugins/lsp-config.lua
--
-- Works on nvim 0.9 / 0.10 (lspconfig) and nvim 0.11+ (native vim.lsp.config).
-- Deprecation warnings from lspconfig on 0.11 are suppressed by routing
-- through utils.compat.lsp_setup.

return {
    -- Mason: LSP/tool installer ------------------------------------------------
    {
        "williamboman/mason.nvim",
        lazy = false,
        config = function()
            require("mason").setup()
        end,
    },

    -- mason-lspconfig: bridge between mason and lspconfig / native LSP ---------
    {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        opts = {
            auto_install = true,
            -- Keep ensure_installed in sync with the servers configured below.
            ensure_installed = {
                "ts_ls", "html", "lua_ls", "clangd",
                "marksman",   -- Markdown LSP
            },
        },
    },

    -- LSP configuration --------------------------------------------------------
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        config = function()
            local compat = require("utils.compat")

            -- Build capabilities once, reuse everywhere.
            local capabilities = {}
            local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
            if ok_cmp then
                capabilities = cmp_lsp.default_capabilities()
            end

            -- List every server + its options here.
            local servers = {
                ts_ls      = { capabilities = capabilities },
                solargraph = { capabilities = capabilities },
                html       = { capabilities = capabilities },
                clangd     = { capabilities = capabilities },
                marksman   = { capabilities = capabilities },   -- Markdown
                lua_ls     = {
                    capabilities = capabilities,
                    settings = {
                        Lua = {
                            -- Silence "undefined global vim" warnings
                            diagnostics = { globals = { "vim" } },
                            workspace = { checkThirdParty = false },
                            telemetry = { enable = false },
                        },
                    },
                },
            }

            for name, opts in pairs(servers) do
                if compat.nvim_011 then
                    vim.lsp.config(name, opts)
                else
                    compat.lsp_setup(name, opts)
                end
            end

            -- ── Shared LSP keymaps ────────────────────────────────────────────
            vim.keymap.set("n", "K",           vim.lsp.buf.hover,       { desc = "LSP hover" })
            vim.keymap.set("n", "<leader>gd",  vim.lsp.buf.definition,  { desc = "Go to definition" })
            vim.keymap.set("n", "<leader>gr",  vim.lsp.buf.references,  { desc = "Go to references" })
            vim.keymap.set("n", "<leader>ca",  vim.lsp.buf.code_action, { desc = "Code action" })
            vim.keymap.set("n", "<leader>rn",  vim.lsp.buf.rename,      { desc = "Rename symbol" })

            -- ── Diagnostics toggle ────────────────────────────────────────────
            vim.g.diagnostics_active = true

            vim.keymap.set("n", "<leader>xd", function()
                if vim.g.diagnostics_active then
                    vim.g.diagnostics_active = false
                    compat.diagnostic_disable()
                else
                    vim.g.diagnostics_active = true
                    compat.diagnostic_enable()
                end
            end, { noremap = true, silent = true, desc = "Toggle diagnostics" })
        end,
    },
}
