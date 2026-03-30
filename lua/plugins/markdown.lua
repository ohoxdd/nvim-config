-- lua/plugins/markdown.lua
--
-- Markdown support:
--   • render-markdown.nvim  — rich in-buffer rendering (headers, code blocks,
--                             checkboxes, tables) without leaving nvim
--   • markdown-preview.nvim — browser preview via <leader>mp

return {
    -- In-buffer rich rendering ------------------------------------------------
    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons",
        },
        ft = { "markdown", "md" },
        opts = {
            -- Show rendered view by default; toggle with :RenderMarkdown toggle
            enabled = true,
            render_modes = { "n", "c" },
            heading = {
                enabled = true,
                -- Distinct background per heading level
                backgrounds = {
                    "RenderMarkdownH1Bg",
                    "RenderMarkdownH2Bg",
                    "RenderMarkdownH3Bg",
                    "RenderMarkdownH4Bg",
                    "RenderMarkdownH5Bg",
                    "RenderMarkdownH6Bg",
                },
                foregrounds = {
                    "RenderMarkdownH1",
                    "RenderMarkdownH2",
                    "RenderMarkdownH3",
                    "RenderMarkdownH4",
                    "RenderMarkdownH5",
                    "RenderMarkdownH6",
                },
            },
            code = {
                enabled   = true,
                sign      = true,
                style     = "full",
                width     = "full",
            },
            checkbox = { enabled = true },
            bullet   = { enabled = true },
        },
        config = function(_, opts)
            require("render-markdown").setup(opts)
            -- Toggle rendered view on/off
            vim.keymap.set("n", "<leader>mr", "<cmd>RenderMarkdown toggle<CR>",
                { desc = "Toggle markdown render" })
        end,
    },

    -- Browser preview (optional, only loads when markdown file is opened) ------
    {
        "iamcco/markdown-preview.nvim",
        cmd   = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
        ft    = { "markdown" },
        -- build runs only once; works without Node installed at plugin-load time
        build = function()
            -- Prefer the bundled install script; falls back gracefully
            local ok = pcall(vim.fn["mkdp#util#install"])
            if not ok then
                vim.notify(
                    "markdown-preview: run :call mkdp#util#install() manually",
                    vim.log.levels.WARN
                )
            end
        end,
        config = function()
            vim.g.mkdp_auto_close  = 1   -- close preview when leaving md buffer
            vim.g.mkdp_open_to_the_world = 0

            vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>",
                { desc = "Markdown browser preview" })
        end,
    },
}
