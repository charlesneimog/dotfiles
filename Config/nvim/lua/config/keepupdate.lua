local vim = vim

local function notifyUntrackedFiles()
	-- notify that we will update dotfiles
	vim.notify("Syncing dotfiles with GitHub...", vim.log.levels.INFO, {
		title = "Dotfiles",
	})
	local result = vim.fn.system("cd " .. "~/.config/nvim" .. ' && git status --porcelain 2>/dev/null | grep -c "^??"')
	if result == "1\n" then
		vim.fn.system('notify-send "Git Status" "There are untracked files in your dotfiles repository."')
	end
end

local function gitAutomaticCommit()
	vim.fn.jobstart(
		"cd " .. "~/Documents/Git/dotfiles/" .. ' && git add . && git commit -m "Update dotfiles" && git push'
	)
end

vim.defer_fn(notifyUntrackedFiles, 4000)
vim.defer_fn(gitAutomaticCommit, 8000)
