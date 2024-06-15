local vim = vim

return {
	{
		"folke/twilight.nvim",
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
	},
	{
		"DreamMaoMao/yazi.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"nvim-lua/plenary.nvim",
		},
	},
	{
		"mateusbraga/vim-spell-pt-br",
	},
	{
		"Pocco81/true-zen.nvim",
		config = function()
			require("true-zen").setup({})
		end,
	},
	{
		"gbprod/yanky.nvim",
		dependencies = { { "kkharji/sqlite.lua", enabled = not jit.os:find("Windows") } },

		keys = {
			{
				"<leader>p",
				function()
					require("telescope").extensions.yank_history.yank_history({})
				end,
				desc = "Open Yank History",
			},
		},
		opts = {
			{
				highlight = { timer = 200 },
				ring = { storage = jit.os:find("Windows") and "shada" or "sqlite" },
			},
		},
	},
	{
		"martineausimon/nvim-bard",
		dependencies = "MunifTanjim/nui.nvim",
		event = "VeryLazy",
		config = function()
			vim.api.nvim_create_user_command("BardLogin", function()
				local bitwarden_pass = vim.fn.inputsecret("Bitwarden password: ")
				local bitwarden_key = vim.fn.system('bw unlock "' .. bitwarden_pass .. '" --raw')
				local token = bitwarden_key:match("\n(.*)")
				local bardTokens = vim.fn.system("bw get item bard.google.com --session " .. token)
				local parsedJson = vim.json.decode(bardTokens).fields
				local psid = parsedJson[1].value
				local psidcc = parsedJson[2].value
				local psidts = parsedJson[3].value
				require("nvim-bard").setup({
					bard_api_key = {
						psid = psid,
						psidcc = psidcc,
						psidts = psidts,
					},
				})
				-- print(bitwarden_pass)
			end, {})
		end,
	},
	{
		"LudoPinelli/comment-box.nvim",
		config = function()
			require("comment-box").setup({
				doc_width = 40, -- width of the document
				box_width = 40, -- width of the boxes
			})
		end,
	},
	{
		"carbon-steel/detour.nvim",
		config = function()
			vim.keymap.set("n", "<leader>w", ":Detour<cr>")
		end,
	},
}
