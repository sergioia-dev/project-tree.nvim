local M = {}

-- :ProjectTree - toggle the floating window.
vim.api.nvim_create_user_command("ProjectTree", function()
	require("project_tree").toggle()
end, { desc = "Toggle project tree floating window" })

-- :ProjectTreeRefresh - re-render the tree from the current root.
vim.api.nvim_create_user_command("ProjectTreeRefresh", function()
	require("project_tree").refresh()
end, { desc = "Refresh project tree" })

return M