local M = {}
local config = require("project_tree.config")
local ui = require("project_tree.ui")

function M.setup(opts)
	config.setup(opts)

	-- Set up toggle keymaps in global scope, not just within the plugin
	local function map(mode, lhs, rhs, opts)
		vim.keymap.set(mode, lhs, rhs, opts)
	end

	map("n", "<leader>ft", function() M.toggle() end, { desc = "Toggle project tree floating window", silent = true })
end

function M.open()
	ui.open()
end

function M.close()
	ui.close()
end

function M.refresh()
	ui.refresh()
end

function M.toggle()
	if ui.window_id ~= nil and vim.api.nvim_win_is_valid(ui.window_id) then
		M.close()
	else
		M.open()
	end
end

function M.toggle_flag(key)
	config.set(key, not config.get()[key])
	ui.refresh()
end

function M.cycle_depth()
	config.cycle_depth()
	ui.refresh()
end

return M