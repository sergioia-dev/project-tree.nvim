local M = {}

-- Default state for all toggleable tree flags.
-- `depth` is a numeric level; `cycle` cycles through these values.
local DEFAULTS = {
	gitignore = true,
	hidden = false,
	dirs_only = false,
	human_size = false,
	dirsfirst = false,
	permissions = false,
	depth = 3,
	prune = false,
	pattern = "",
	du = false,
}

-- Depth cycle order (0 means unlimited: omit -L entirely).
local DEPTH_CYCLE = { 0, 1, 2, 3, 5 }

local state = {}
for k, v in pairs(DEFAULTS) do
	state[k] = v
end

-- Merge user-provided options into state.
function M.setup(opts)
	if type(opts) ~= "table" then
		return
	end
	for key, value in pairs(opts) do
		if DEFAULTS[key] ~= nil then
			state[key] = value
		end
	end
end

function M.get()
	return state
end

function M.set(key, value)
	if DEFAULTS[key] ~= nil then
		state[key] = value
	end
end

function M.cycle_depth()
	local current = state.depth
	for index, level in ipairs(DEPTH_CYCLE) do
		if level == current then
			local next_level = DEPTH_CYCLE[index + 1]
			if next_level ~= nil then
				state.depth = next_level
			else
				state.depth = DEPTH_CYCLE[1]
			end
			return
		end
	end
	-- Fallback: current value not in cycle, wrap to first.
	state.depth = DEPTH_CYCLE[1]
end

return M
