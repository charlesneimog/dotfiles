local vim = vim

--╭─────────────────────────────────────╮
--│         LSP Configurations          │
--╰─────────────────────────────────────╯
local servers = {
	clangd = {
		cmd = {
			"clangd",
			"--offset-encoding=utf-16",
		},
	},
	pyright = {},
	html = {},
	lua_ls = {},
	ltex = {
		autostart = true,
		filetypes = { "markdown", "tex", "txt" },
		settings = {
			ltex = {
				language = "pt-BR",
				diagnosticSeverity = "information",
				additionalRules = {
					enablePickyRules = true,
				},
			},
		},
	},
}

return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim", -- Mason is a build tool for Neovim plugins
		},
		keys = {
			{
				"<leader>v",
				function()
					vim.diagnostic.open_float()
				end,
				mode = "n",
				desc = "[V]iew [D]iagnostics",
			},
			{
				"ca",
				function()
					vim.lsp.buf.code_action()
				end,
				mode = "n",
				desc = "Code [A]ction",
			},
		},
		config = function()
			local mason = require("mason")
			local mason_lspconfig = require("mason-lspconfig")
			local cmp_nvim_lsp = require("cmp_nvim_lsp")
			local lspconfig = require("lspconfig")

			mason.setup({
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})

			local capabilities = cmp_nvim_lsp.default_capabilities()

			-- Ensure Installed
			mason_lspconfig.setup({
				ensure_installed = vim.tbl_keys(servers),
				automatic_installation = true,
			})

			mason_lspconfig.setup_handlers({
				function(server_name)
					lspconfig[server_name].setup({
						capabilities = capabilities,
						settings = servers[server_name],
					})
				end,
			})
		end,
	},
}
