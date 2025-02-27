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
		"linrongbin16/lsp-progress.nvim",
		config = function()
			require("lsp-progress").setup()
		end,
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim", -- Mason is a build tool for Neovim plugins
		},

		keys = {
			{
				"<leader>rn",
				function()
					vim.lsp.buf.rename()
				end,
				mode = "n",
				desc = "[R]ename [N]ode",
			},
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
			local mason_lspconfig = require("mason-lspconfig")
			local cmp_nvim_lsp = require("cmp_nvim_lsp")
			local lspconfig = require("lspconfig")

			-- automatic install
			local masonrequirements = {}
			for _, server in ipairs(vim.tbl_keys(servers)) do
				table.insert(masonrequirements, server)
			end

			mason_lspconfig.setup({
				ensure_installed = masonrequirements,
				automatic_installation = true,
			})

			--
			local capabilities = cmp_nvim_lsp.default_capabilities()
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
