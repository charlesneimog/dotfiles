local vim = vim

local function getGnomeThemeMode()
	local cmd = vim.fn.system("gsettings get org.gnome.desktop.interface color-scheme")
	vim.g.gnome_theme_mode = cmd:match("dark") and "dark" or "light"
	return cmd:match("dark") and "dark" or "light"
end

local GnomeThemeMode = getGnomeThemeMode()

return {
	"olimorris/onedarkpro.nvim",
	tag = "treesitter-0.9.2",
	config = function()
		if GnomeThemeMode == "dark" then
			require("onedarkpro").setup({
				theme = "onedark",
				colors = {
					float_bg = "#2e2e2e",
					bg = "#303030",
					fg = "#ffffff",
					mydark = "#FFFFFF",
					almostdark = "#eeeeee",
					mydarkred = "#191919",
					myred = "#A90000",
					rederror = "#FF0000",
					myblue = "#0000FF",
					myorange = "#E1AD0F",
					mypurple = "#800080",
					myconstant = "#FC600A",
					myif = "#E1AD0F",
					myint = "#8a8106",
					mynumber = "#2C2A67",
					pyclass = "#09799c",
					pymethod = "#4ca6ff",
					mypink = "#b02c79",
					dark_blue = "#012363",
					my_is_not = "#C99B0D",
					myloop = "#8000FF",
				},
				highlights = {
					Error = { fg = "${rederror}", style = "italic" },
				},
				options = {
					transparency = false,
				},
			})
			vim.cmd("colorscheme onedark")
		else
			require("onedarkpro").setup({
				theme = "onelight",
				colors = {
					float_bg = "#fcfcfc",
					bg = "#ffffff",
					fg = "#191919",
					white = "#ffffff",
					mydark = "#000000",
					mywhite = "#ffffff",
					almostdark = "#3F3F3F",
					mydarkred = "#191919",
					myred = "#A90000",
					rederror = "#FF0000",
					myblue = "#0000FF",
					myorange = "#E1AD0F",
					mypurple = "#800080",
					myconstant = "#FC600A",
					myif = "#E1AD0F",
					myint = "#8a8106",
					mynumber = "#2C2A67",
					pyclass = "#09799c",
					pymethod = "#4ca6ff",
					mypink = "#b02c79",
					dark_blue = "#012363",
					my_is_not = "#C99B0D",
					myloop = "#8000FF",
				},
				highlights = {
					Error = {
						fg = "${rederror}",
						style = "italic",
					},

					-- ===== LATEX ====
					["texArg"] = { fg = "${dark_blue}" },
					--

					["@text"] = { fg = "${mydark}" },
					["@constant"] = { fg = "${dark_blue}" },
					["@conditional"] = { fg = "${myif}", style = "bold" },
					["@field"] = { fg = "${mypink}" }, -- NOTE: For example, neoscore.defult
					["@keyword"] = { fg = "${mypurple}", style = "bold" },
					["@keyword.function"] = { fg = "${myred}", style = "bold" },
					["@keyword.return"] = { fg = "${mypurple}", style = "bold" },
					["@number"] = { fg = "${mydark}" },
					["@punctuation.bracket"] = { fg = "${mydark}" },
					["@repeat"] = { fg = "${myloop}" }, -- keywork for Loops
					["@variable"] = { fg = "${mydarkred}" },
					["@builtin.type.python"] = { fg = "#000000" },
					["@conditional.python"] = { fg = "${myif}" }, -- NOTE: if and others
					["@constructor.python"] = { fg = "${pyclass}" }, -- NOTE: if tambem
					["@keyword.function.python"] = { fg = "${myred}", style = "bold" }, -- NOTE: def of one function
					["@keyword.operator.python"] = { fg = "${my_is_not}" }, -- NOTE: is not
					["@function.builtin.python"] = { fg = "${myint}" }, -- NOTE: int, float, etc.
					["@method.call.python"] = { fg = "${pymethod}" }, -- NOTE: method, for example, random.randint the {randint} is the method
					["@preproc.python"] = { fg = "${mydark}" }, -- NOTE:
					["@variable.builtin.python"] = { fg = "${mypink}", style = "italic" }, -- Must be variables of packages.
				},
				options = {
					transparency = false,
				},
			})
			vim.cmd("colorscheme onelight")
		end
	end,
}
