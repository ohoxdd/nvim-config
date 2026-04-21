return {
	"nvimtools/none-ls.nvim",
	config = function()
		local null_ls = require("null-ls")
		local sources = {}

		if vim.fn.executable("stylua") == 1 then
			table.insert(sources, null_ls.builtins.formatting.stylua)
		end
		if vim.fn.executable("prettier") == 1 then
			table.insert(sources, null_ls.builtins.formatting.prettier)
		end

		if #sources > 0 then
			null_ls.setup({ sources = sources })
		end

		vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
	end,
}
