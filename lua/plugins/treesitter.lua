-- lua/plugins/treesitter.lua
--
-- nvim-treesitter main-branch (post v0.9.3) API:
--   • highlight / indent are handled by Neovim core — no config needed here
--   • parsers are installed with :TSInstall or the install() function
--   • the only setup() option is install_dir
return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").setup({
            install_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site/"),
        })

        -- Auto-install missing parsers asynchronously on startup.
        local needed = {
            "java", "lua", "vim", "vimdoc", "query",
            "html", "css", "javascript", "typescript",
            "markdown", "markdown_inline",
            "bash", "json", "yaml", "toml",
        }
        local installed = require("nvim-treesitter.config").get_installed()
        local missing = vim.tbl_filter(function(lang)
            return not vim.list_contains(installed, lang)
        end, needed)
        if #missing > 0 then
            vim.schedule(function()
                require("nvim-treesitter.install").install(missing, { summary = true })
            end)
        end
    end,
}
