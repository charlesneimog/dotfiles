local lsp_commands = require("ltex_extra.commands-lsp")

function AddWordUnderCursorToDictionary()
	local word = vim.fn.expand("<cword>")
	if not word or word == "" then
		vim.notify("Nenhuma palavra encontrada sob o cursor.", vim.log.levels.WARN)
		return
	end
	local client = lsp_commands.catch_ltex()
	if not client then
		vim.notify("Cliente LTeX não encontrado.", vim.log.levels.ERROR)
		return
	end
	local lang = client.config.settings.ltex.language
	if not lang then
		vim.notify("Idioma do LTeX não configurado.", vim.log.levels.ERROR)
		return
	end
	lsp_commands.add_to_dictionary({
		arguments = {
			{ words = { [lang] = { word } } },
		},
	})

	vim.notify("Palavra '" .. word .. "' adicionada ao dicionário para o idioma: " .. lang)
end

return {
	{
		"barreiroleo/ltex_extra.nvim",
		ft = { "markdown", "tex" }, -- Especifica os tipos de arquivos
		dependencies = { "neovim/nvim-lspconfig" }, -- LSP necessário
		config = function()
			local ltex_config = require("ltex_extra_config")

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
