return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		local install_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site")
		vim.opt.rtp:prepend(install_dir)

		require("nvim-treesitter.configs").setup({
			ensure_installed = {
				"lua", "vim", "vimdoc", "python", "c", "html", "css",
				"javascript", "typescript", "json", "markdown",
				"ruby", "rust", "go", "bash", "yaml",
			},
			sync_install = false,
			auto_install = true,
		})
	end,
}