local M = {}

local config = require("project_tree.config")

M.window_id = nil
M.buffer_id = nil

local function find_project_root()
	local current_dir = vim.uv.cwd() or vim.fn.getcwd()
	if not current_dir or current_dir == "" then
		return vim.uv.cwd() or vim.fn.getcwd()
	end

	while current_dir and current_dir ~= "" do
		for _, marker in ipairs({ ".git", ".hg", "flake.nix" }) do
			if vim.fn.isdirectory(current_dir .. "/" .. marker) == 1 then
				return current_dir
			end
		end

		local parent = current_dir:match("^(.*)/[^/]*$")
		if parent == nil or parent == current_dir then
			break
		end
		current_dir = parent
	end

	return vim.uv.cwd() or vim.fn.getcwd()
end

local function build_tree_command()
	local state = config.get()
	local args = { "tree", "-C", "--dirsfirst" }

	if state.gitignore then
		table.insert(args, "--gitignore")
	end
	if state.hidden then
		table.insert(args, "-a")
	end
	if state.dirs_only then
		table.insert(args, "-d")
	end
	if state.human_size then
		table.insert(args, "-h")
	end

	if state.permissions then
		table.insert(args, "-p")
	end
	if state.depth > 0 then
		table.insert(args, "-L")
		table.insert(args, tostring(state.depth))
	end
	if state.prune then
		table.insert(args, "--prune")
	end
	if state.pattern ~= "" then
		table.insert(args, "-P")
		-- Wrap pattern with wildcards if not already a glob
		local pattern = state.pattern
		if not pattern:match("%*") then
			pattern = "*" .. pattern .. "*"
		end
		table.insert(args, pattern)
	end
	if state.du then
		table.insert(args, "--du")
	end

	table.insert(args, find_project_root())
	return args
end

local function build_legend()
	local state = config.get()

	local function opt(key, desc)
		local status = state[key] and "✓" or "○"
		return status .. desc
	end

	return string.format(
		"[ g:%s a:%s d:%s s:%s p:%s L:%s P:%s u:%s f:%s ]",
		opt("gitignore", " gitignore"),
		opt("hidden", " hidden"),
		opt("dirs_only", " dirs"),
		opt("human_size", " size"),
		opt("permissions", " perms"),
		state.depth > 0 and tostring(state.depth) or "all",
		opt("prune", " prune"),
		opt("du", " du"),
		opt("pattern", " filter")
	)
end

local function set_window_keymaps()
	local function map(mode, lhs, rhs, opts)
		local options = opts or {}
		options.buffer = M.buffer_id
		vim.keymap.set(mode, lhs, rhs, options)
	end

	map("n", "q", function()
		M.close()
	end, { desc = "Close project tree", silent = true })
	map("n", "<Esc>", function()
		M.close()
	end, { desc = "Close project tree", silent = true })
	map("n", "g", function()
		config.set("gitignore", not config.get().gitignore)
		M.refresh()
	end, { desc = "Toggle gitignore", silent = true })
	map("n", "a", function()
		config.set("hidden", not config.get().hidden)
		M.refresh()
	end, { desc = "Toggle hidden files", silent = true })
	map("n", "d", function()
		config.set("dirs_only", not config.get().dirs_only)
		M.refresh()
	end, { desc = "Toggle directories only", silent = true })
	map("n", "s", function()
		config.set("human_size", not config.get().human_size)
		M.refresh()
	end, { desc = "Toggle human-readable sizes", silent = true })

	map("n", "p", function()
		config.set("permissions", not config.get().permissions)
		M.refresh()
	end, { desc = "Toggle permissions", silent = true })
	map("n", "L", function()
		config.cycle_depth()
		M.refresh()
	end, { desc = "Cycle tree depth", silent = true })
	map("n", "P", function()
		config.set("prune", not config.get().prune)
		M.refresh()
	end, { desc = "Toggle prune", silent = true })
	map("n", "u", function()
		config.set("du", not config.get().du)
		M.refresh()
	end, { desc = "Toggle cumulative sizes", silent = true })
	map("n", "f", function()
		vim.ui.input({ prompt = "Pattern: " }, function(input)
			if input ~= nil then
				config.set("pattern", input)
				M.refresh()
			end
		end)
	end, { desc = "Set file pattern", silent = true })
	map("n", "R", function()
		M.refresh()
	end, { desc = "Refresh project tree", silent = true })
	map("n", "<C-f>", function()
		vim.api.nvim_set_current_win(M.window_id)
		vim.cmd("normal! <C-f>")
	end, { desc = "Scroll down", silent = true })
	map("n", "<C-b>", function()
		vim.api.nvim_set_current_win(M.window_id)
		vim.cmd("normal! <C-b>")
	end, { desc = "Scroll up", silent = true })
end

local function open_window()
	local width = math.floor(vim.o.columns * 0.85)
	local height = math.floor(vim.o.lines * 0.80)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	M.window_id = vim.api.nvim_open_win(M.buffer_id, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = build_legend(),
		title_pos = "center",
	})

	vim.api.nvim_win_set_option(M.window_id, "wrap", false)
	vim.api.nvim_win_set_option(M.window_id, "cursorline", false)
	vim.api.nvim_win_set_option(M.window_id, "number", false)
	vim.api.nvim_win_set_option(M.window_id, "relativenumber", false)
	vim.api.nvim_win_set_option(M.window_id, "foldenable", false)

	set_window_keymaps()
end

local function run_terminal()
	vim.fn.termopen(build_tree_command(), { cwd = find_project_root() })
end

function M.open()
	if M.window_id ~= nil and vim.api.nvim_win_is_valid(M.window_id) then
		vim.api.nvim_set_current_win(M.window_id)
		return
	end

	M.buffer_id = vim.api.nvim_create_buf(false, false)
	vim.api.nvim_buf_set_name(M.buffer_id, "ProjectTree")

	open_window()
	run_terminal()
end

function M.refresh()
	if M.window_id == nil or not vim.api.nvim_win_is_valid(M.window_id) then
		vim.notify("Project tree terminal is not open", vim.log.levels.WARN)
		return
	end

	vim.api.nvim_win_close(M.window_id, true)
	M.window_id = nil

	if M.buffer_id ~= nil and vim.api.nvim_buf_is_valid(M.buffer_id) then
		vim.api.nvim_buf_delete(M.buffer_id, { force = true })
	end

	M.open()
end

function M.close()
	if M.window_id ~= nil and vim.api.nvim_win_is_valid(M.window_id) then
		vim.api.nvim_win_close(M.window_id, true)
	end

	if M.buffer_id ~= nil and vim.api.nvim_buf_is_valid(M.buffer_id) then
		vim.api.nvim_buf_delete(M.buffer_id, { force = true })
	end

	M.window_id = nil
	M.buffer_id = nil
end

M.open = M.open
M.close = M.close
M.refresh = M.refresh
M.toggle_flag = M.toggle_flag
M.cycle_depth = M.cycle_depth

return M
