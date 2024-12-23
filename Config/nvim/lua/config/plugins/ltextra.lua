return {
	{
		"barreiroleo/ltex_extra.nvim",
		ft = { "markdown", "tex" }, -- Especifica os tipos de arquivos
		dependencies = { "neovim/nvim-lspconfig" }, -- LSP necessário
		keys = {
			{
				"aw",
				function()
					-- check if _ltex.addToDictionary is on the commands list
					local commands = vim.lsp.commands
					if commands["_ltex.addToDictionary"] then
						local command = commands["_ltex.addToDictionary"]
						command.callback({
							words = vim.fn.expand("<cword>"),
						})
					end
				end,
				mode = { "n" },
				desc = "Add word to dictionary",
			},
		},
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities() -- Para autocompletar avançado (se estiver usando nvim-cmp)
			require("ltex_extra").setup({

				server_opts = {
					capabilities = capabilities,
					settings = {
						ltex = {
							language = "pt-BR", -- Idioma principal (pode ser ajustado)
							additionalLanguages = { "pt-BR" }, -- Idiomas extras
							dictionary = {
								["en-US"] = { "customword" },
								["pt-BR"] = { "exemplo", "latex" },
							},
							disabledRules = {
								["en-US"] = { "PROFANITY" }, -- Regras desativadas em inglês
								["pt-BR"] = { "TIPO", "ACENTUACAO" }, -- Regras desativadas em português
							},
							hiddenFalsePositives = {},
						},
					},
				},
			})
		end,
	},

	-- {
	-- 	"charlesneimog/ltextra.nvim",
	-- 	-- dir = "~/Documents/Git/ltextra.nvim",
	-- 	keys = {
	-- 		{
	-- 			"aw",
	-- 			function()
	-- 				require("ltextra.actions").add_word()
	-- 			end,
	-- 			mode = "n",
	-- 			desc = "Add word to dictionary",
	-- 		},
	-- 		{
	-- 			"dr",
	-- 			function()
	-- 				require("ltextra.actions").disable_rule()
	-- 			end,
	-- 			mode = "n",
	-- 			desc = "Disable rule",
	-- 		},
	-- 		{
	-- 			"ic",
	-- 			function()
	-- 				require("ltextra.actions").ignore_command()
	-- 			end,
	-- 			mode = "n",
	-- 			desc = "Ignore Command",
	-- 		},
	-- 		{
	-- 			"<leader>hf",
	-- 			function()
	-- 				require("ltextra.actions").hidden_false_positive()
	-- 			end,
	-- 			mode = "n",
	-- 			desc = "Hide False Positives",
	-- 		},
	-- 		{
	-- 			"<leader>r",
	-- 			function()
	-- 				require("ltextra.actions").print_rule_under_cursor()
	-- 			end,
	-- 			mode = "n",
	-- 			desc = "Print Rule Under Cursor",
	-- 		},
	-- 	},
	-- 	event = "BufRead *.tex",
	-- 	config = function()
	-- 		require("ltextra").setup({
	-- 			language = "pt-BR",
	-- 		})
	-- 	end,
	-- },
}
