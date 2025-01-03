return {
	"rcarriga/nvim-notify",
	config = function()
		local notify = require("notify")
		notify.setup({
			stages = "static",
			fps = 60,
			render = "compact",
			top_down = false,
			-- background_colour = "NotifyBackground",
		})
		vim.notify = notify
	end,
}
