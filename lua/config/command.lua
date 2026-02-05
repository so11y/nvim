vim.api.nvim_create_user_command("ToggleZen", function()
	if vim.opt.number:get() then
		vim.opt.number = false
		vim.opt.relativenumber = false
		vim.opt.signcolumn = "no"
	else
		vim.opt.number = true
		vim.opt.relativenumber = true
		vim.opt.signcolumn = "yes"
	end
end, {})

-- local timer = vim.loop.new_timer()
-- local last_recorded_pos = { -1, -1 }
--
-- vim.api.nvim_create_autocmd("CursorMoved", {
-- 	group = vim.api.nvim_create_augroup("VSCodeJumplist", { clear = true }),
-- 	callback = function()
-- 		timer:stop()
-- 		timer:start(
-- 			250,
-- 			0,
-- 			vim.schedule_wrap(function()
-- 				local win = vim.api.nvim_get_current_win()
-- 				local buf = vim.api.nvim_get_current_buf()
-- 				if not vim.api.nvim_win_is_valid(win) or not vim.api.nvim_buf_is_valid(buf) then
-- 					return
-- 				end
-- 				if vim.bo[buf].buftype ~= "" then
-- 					return
-- 				end
--
-- 				local cursor = vim.api.nvim_win_get_cursor(win)
-- 				local r, c = cursor[1], cursor[2]
--
-- 				-- 1. 检查是否真的移动了坐标
-- 				if r == last_recorded_pos[1] and c == last_recorded_pos[2] then
-- 					return
-- 				end
--
-- 				-- 2. 关键：获取跳转列表，判断是否在“翻阅历史”
-- 				local jl = vim.fn.getjumplist()
-- 				local list, idx = jl[1], jl[2]
--
-- 				if idx < #list then
-- 					local history_point = list[idx + 1]
-- 					-- 如果当前坐标正好等于跳转列表里的那个历史点，说明你刚 Ctrl-o 回来，没动
-- 					-- 此时为了保留 Ctrl-i 的功能，不打标记
-- 					if history_point.lnum == r and history_point.col == c and history_point.bufnr == buf then
-- 						return
-- 					end
-- 				end
--
-- 				vim.cmd.mark("'")
--
-- 				-- 更新记录
-- 				last_recorded_pos = { r, c }
-- 			end)
-- 		)
-- 	end,
-- })
