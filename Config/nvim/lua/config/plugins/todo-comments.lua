local function excludeGitSubmodules()
	local excludedDirs = {}
	local gitSubmodules = vim.fn.systemlist("grep path .gitmodules | sed 's/.*= //'")
	table.insert(excludedDirs, "--color=never")
	table.insert(excludedDirs, "--no-heading")
	table.insert(excludedDirs, "--with-filename")
	table.insert(excludedDirs, "--line-number")
	table.insert(excludedDirs, "--column")
	for _, dir in ipairs(gitSubmodules) do
		table.insert(excludedDirs, "--glob=!" .. dir .. "/*")
	end
	return excludedDirs
end

return {
	"folke/todo-comments.nvim",
	dependencies = "nvim-lua/plenary.nvim",
	-- keys = { BUG:
	-- 	{
	-- 		"<leader>T",
	-- 		function()
	-- 			vim.cmd("TodoTelescope keywords=TODO,BUG")
	-- 		end,
	-- 		desc = "[T]odo Toogle",
	-- 		mode = { "n", "v" },
	-- 	},
	-- },

	opts = {
		signs = true, -- show icons in the signs column
		sign_priority = 8, -- sign priority
		highlight = {
			multiline = false,
			pattern = [[.*<(KEYWORDS)\s*:]],
		},
		colors = {
			neimogFIX = { "neimogFIX", "#DB463B" },
			neimogERROR = { "neimogERROR", "#DB463B" },
			neimogTODO = { "neimogTODO", "#2196F3" },
			neimogWARN = { "neimogWARN", "#FFA500" },
			neimogPERF = { "neimogPERF", "#F9D0C4" },
			neimogNOTE = { "neimogNOTE", "#d6c306" },
			neimogTEST = { "neimogTEST", "#43A047" },
			neimogDOC = { "neimogDOC", "#F9D0C4" },
		},
		search = {
			command = "rg",
			args = excludeGitSubmodules(),
			pattern = [[\b(KEYWORDS):]],
		},
		keywords = {
			FIX = { icon = " ", color = "neimogFIX", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
			TODO = { icon = " ", color = "neimogTODO", alt = { "TODO", "TO-DO" } },
			ERROR = { icon = " ", color = "neimogERROR", alt = { "HACK", "TEMP", "TEMPORARY" } },
			WARN = { icon = " ", color = "neimogWARN", alt = { "WARNING", "WARN" } },
			NOTE = { icon = "󱓧 ", color = "neimogNOTE", alt = { "INFO", "NOTE" } },
			TEST = { icon = "󰙨 ", color = "neimogTEST", alt = { "TESTING", "PASSED", "FAILED" } },
			DOC = { icon = "󱪝 ", color = "hint", alt = { "DOCUMENTATION", "DOC" } },
		},
	},
}
