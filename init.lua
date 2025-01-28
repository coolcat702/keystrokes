local M = {}
local config = {
	timeout = 2000, -- Amount of time (ms) before window hides
	key_amount = 6, -- Max amount of keystrokes the window can hold
	excluded_modes = {}, -- Modes to exclude
	style = "rounded", -- none, rounded, single, double, solid, shadow, array (border section of :h nvim_open_win)
	special_formats = { -- Format for special characters - MUST HAVE NERD FONT
		["<BS>"] = "󰁮 ",
		["<CR>"] = "󰌑 ",
		["<Esc>"] = "󰿅 ",
		["<Space>"] = "󱁐",
		["<Tab>"] = "",
		["<Up>"] = "",
		["<Down>"] = "",
		["<Left>"] = "",
		["<Right>"] = "",
		["<M>"] = "󰘵 ",
		["<C>"] = "",
		["<S>"] = "󰘶",
	},
}
local state = {
	keys = {},
	window_options = {
		relative = "editor",
		style = "minimal",
		width = 1,
		height = 1,
		row = 1,
		col = 0,
		zindex = 100,
	},
}
local ns = vim.api.nvim_create_namespace("keystrokes")

local function update_display()
	local lines, cols = vim.o.lines, vim.o.columns
	local width = #state.keys + 1 + (2 * #state.keys)
	for _, v in ipairs(state.keys) do
		width = width + vim.fn.strwidth(v.txt)
	end
	state.window_options.width = width
	state.window_options.row = lines - 5
	state.window_options.col = cols - width - 3

	if state.win then
		vim.api.nvim_win_set_config(state.win, state.window_options)
	end

	local virt_texts = {}
	for i, val in ipairs(state.keys) do
		local hl = i == #state.keys and "SkActive" or "SkInactive"
		table.insert(virt_texts, { " " .. val.txt .. " ", hl })
		table.insert(virt_texts, { " " })
	end

	if not state.extmark_id then
		vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, { " " })
	end
	local opts = { virt_text = virt_texts, virt_text_pos = "overlay", id = state.extmark_id }
	state.extmark_id = vim.api.nvim_buf_set_extmark(state.buf, ns, 0, 1, opts)
end

local function process_key(char)
	if vim.tbl_contains(config.excluded_modes, vim.api.nvim_get_mode().mode) then
		if state.win then
			M.close()
		end
		return
	end

	local key = vim.fn.keytrans(char)
	if
		key:match("Space") and key ~= "<Space>"
		or (key:match("<Up>") and key ~= "<Up>")
		or (key:match("<Down>") and key ~= "<Down>")
		or key:match("Mouse")
		or key:match("Scroll")
		or key:match("Drag")
		or key:match("Release")
		or key == ""
	then
		return
	end

	local formatted = config.special_formats[key] or key
	local modifier, rest = key:match("<([^%-]+)%-(.+)>")
	if modifier then
		local mod_symbol = config.special_formats["<" .. modifier .. ">"] or ("<" .. modifier .. ">")
		key = mod_symbol .. " + " .. rest:lower()
	else
		key = formatted
	end

	local last_key = state.keys[#state.keys]
	if last_key and key == last_key.key then
		local count = (last_key.count or 1) + 1
		state.keys[#state.keys] = { key = key, txt = count .. "(" .. key .. ")", count = count }
	else
		if #state.keys == config.key_amount then
			table.remove(state.keys, 1)
		end
		table.insert(state.keys, { key = key, txt = key })
	end
	update_display()
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})
	state.window_options.border = config.style
end

function M.open()
	state.buf = vim.api.nvim_create_buf(false, true)
	vim.bo[state.buf].ft = "keystrokes"

	state.timer = vim.uv.new_timer()
	state.on_key = vim.on_key(function(_, char)
		if not state.win then
			state.win = vim.api.nvim_open_win(state.buf, false, state.window_options)
			vim.api.nvim_set_option_value("winhl", "FloatBorder:Comment,Normal:Normal", { win = state.win })
		end

		process_key(char)

		state.timer:stop()
		state.timer:start(config.timeout, 0, function()
			vim.schedule(M.hide)
		end)
	end)
	vim.api.nvim_set_hl(0, "SkInactive", { default = true, link = "Visual" })
	vim.api.nvim_set_hl(0, "SkActive", { default = true, link = "PmenuSel" })

	local augroup = vim.api.nvim_create_augroup("KeystrokesAu", { clear = true })
	vim.api.nvim_create_autocmd("VimResized", {
		group = augroup,
		callback = function()
			if state.win then
				update_display()
			end
		end,
	})
	vim.api.nvim_create_autocmd("WinClosed", {
		group = augroup,
		callback = function()
			if state.win then
				M.close()
				M.open()
			end
		end,
		buffer = state.buf,
	})
end

function M.hide()
	if state.win then
		vim.api.nvim_win_hide(state.win)
	end
	state.window_options.width = 1
	state.keys = {}
	state.extmark_id = nil
end

function M.close()
	vim.api.nvim_del_augroup_by_name("KeystrokesAu")
	if state.timer then
		state.timer:stop()
	end
	M.hide()
	if state.buf then
		vim.api.nvim_buf_delete(state.buf, { force = true })
	end
	if state.on_key then
		vim.on_key(nil, state.on_key)
	end
	state.win = nil
	state.buf = nil
end

function M.toggle()
	if state.win then
		M.close()
	else
		M.open()
	end
end

vim.api.nvim_create_user_command("KeystrokesOpen", function()
	require("keystrokes").open()
end, { desc = "Open Keystrokes Window" })

vim.api.nvim_create_user_command("KeystrokesClose", function()
	require("keystrokes").close()
end, { desc = "Close Keystrokes Window" })

vim.api.nvim_create_user_command("KeystrokesToggle", function()
	require("keystrokes").toggle()
end, { desc = "Toggle Keystrokes Window" })

return M
