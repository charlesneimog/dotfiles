return {
	{
		"linrongbin16/lsp-progress.nvim",
		config = function()
			require("lsp-progress").setup()
		end,
	},
	{
		"mason-org/mason-lspconfig.nvim",
		opts = {},
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"neovim/nvim-lspconfig",
		},
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"vimls",
					"clangd",
					"pyright",
					"html",
					"ltex",
					"ts_ls",
				},
				automatic_enable = {
					"lua_ls",
					"vimls",
					"clangd",
					"pyright",
					"html",
					"ltex",
					"ts_ls",
				},
			})
			vim.api.nvim_set_keymap(
				"n",
				"<leader>rn",
				"<cmd>lua vim.lsp.buf.rename()<CR>",
				{ noremap = true, silent = true, desc = "[R]ename [N]ode" }
			)

			vim.api.nvim_set_keymap(
				"n",
				"<leader>v",
				"<cmd>lua vim.diagnostic.open_float()<CR>",
				{ noremap = true, silent = true, desc = "[V]iew [D]iagnostics" }
			)

			vim.api.nvim_set_keymap(
				"n",
				"ca",
				"<cmd>lua vim.lsp.buf.code_action()<CR>",
				{ noremap = true, silent = true, desc = "Code [A]ction" }
			)
		end,
	},
}
