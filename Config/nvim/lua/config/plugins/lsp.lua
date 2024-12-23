local vim = vim

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
		},
		config = function()
			local mason_lspconfig = require("mason-lspconfig")
			local cmp_nvim_lsp = require("cmp_nvim_lsp")
			local lspconfig = require("lspconfig")

			local capabilities = cmp_nvim_lsp.default_capabilities()

			-- Ensure Installed
			mason_lspconfig.setup({
				ensure_installed = vim.tbl_keys(servers),
				automatic_installation = true,
			})

			mason_lspconfig.setup_handlers({
				function(server_name)
					local server = servers[server_name]
					server.capabilities = capabilities
					lspconfig[server_name].setup(server)
				end,
			})
		end,
	},

	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = "williamboman/mason.nvim",
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					"stylua",
					"isort",
					"black",
					"clang-format",
					"yamlfmt",
					"shfmt",
				},
				run_on_start = true,
			})
		end,
	},
}
