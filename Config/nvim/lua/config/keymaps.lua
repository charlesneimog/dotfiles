local vim = vim

vim.keymap.set("n", "<leader>m", function()
	local buffers = vim.api.nvim_list_bufs()
	if #buffers == 2 then
		vim.notify("Just one buffer open!", "info", { title = "Buffers", timeout = 1500 })
		vim.cmd("bnext")
	else
		vim.cmd("bnext")
	end
end, { desc = "[M]Previous Buffer" })

vim.keymap.set("n", "<leader>n", function()
	local buffers = vim.api.nvim_list_bufs()
	if #buffers == 2 then
		vim.notify("Just one buffer open!", "info", { title = "Buffers", timeout = 1500 })
		vim.cmd("bprevious")
	else
		vim.cmd("bprevious")
	end
end, { desc = "[N]ext Buffer" })
