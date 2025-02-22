local vim = vim

local function setmytheme(switcher)
	if switcher == vim.g.wezterm_theme then
		return
	end
	vim.g.wezterm_theme = switcher
	vim.env.WEZTERM_THEME = switcher
	local mytheme
	if switcher == "dark" then
		mytheme = require("lualine.themes.onedark")
		mytheme.normal.c.bg = nil
	else
		mytheme = require("lualine.themes.onelight")
		mytheme.normal.c.bg = nil
	end

	-- vim.notify(vim.inspect(mytheme))

	require("lualine").setup({
		options = {
			theme = mytheme,
		},
	})

	if switcher == "dark" then
		vim.cmd("colorscheme onedark")
	else
		vim.cmd("colorscheme onelight")
	end

	for _, kind in ipairs({ "Add", "Change", "Delete" }) do
		local group = "Diff" .. kind

		local bg
		if switcher == "light" then
			bg = "#E6E6E6"
		else
			bg = "#484848"
		end

		local color = ""
		if group == "DiffAdd" then
			color = vim.api.nvim_get_hl_by_name("lualine_a_buffers_active", true)["background"]
		elseif group == "DiffChange" then
			color = "#E1AD0F"
		elseif group == "DiffDelete" then
			color = "#A90000"
		end

		vim.api.nvim_set_hl(0, group, { fg = color, bg = bg })
	end
end

vim.api.nvim_create_user_command(
	"SetMyTheme",
	function(opts)
		vim.env.NVIM_LISTEN_ADDRESS = vim.v.servername
		setmytheme(opts.args)
	end,
	{ nargs = 1 } -- This specifies that the command takes exactly 1 argument
)

return {
	{
		"olimorris/onedarkpro.nvim",
		priority = 1000,
		config = function()
			local theme = vim.env.WEZTERM_THEME
			require("onedarkpro").setup({
				colors = {
					onedark = { bg = "#303030", fg = "#ffffff", float_bg = "#2e2e2e" },
					onelight = { bg = "#FFFFFF", fg = "#000000", float_bg = "#fcfcfc" },
				},
			})
			if theme == "dark" then
				vim.cmd("colorscheme onedark")
			else
				vim.cmd("colorscheme onelight")
			end
		end,
	},
}
