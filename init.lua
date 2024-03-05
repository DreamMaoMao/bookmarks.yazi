-- stylua: ignore
local SUPPORTED_KEYS = {
	"a","s","d","j","k","l","p", "b", "e", "t",  "o", "i", "n", "r", "h","c",
	"u", "m", "f", "g", "w", "v", "x", "z", "y", "q"
}

local save_bookmark = ya.sync(function(state,message)
	local folder = Folder:by_kind(Folder.CURRENT)
	local under_cursor_file = folder.window[folder.cursor - folder.offset + 1]
	local find = false

	if state.bookmarks == nil then 
		state.bookmarks = {}
	end

	-- avoid add exists url
	for y, cand in ipairs(state.bookmarks) do
		if tostring(under_cursor_file.url) == cand.desc then
			return 
		end
	end

	-- find a key to bind from begin SUPPORTED_KEYS
	for i, key in ipairs(SUPPORTED_KEYS) do
		if find then
			break
		end

		for y, cand in ipairs(state.bookmarks) do
			if key == cand.on then
				goto continue
			end
		end

		-- if input message is empty,set message to file url
		if message == nil or message == "" then
			message = under_cursor_file.url
		end

		state.bookmarks[#state.bookmarks + 1] = {
			on = key,
			cwd = tostring(folder.cwd),
			desc = tostring(message),
			cursor = folder.cursor,
		}

		find = true

		::continue::
	end

end)

local all_bookmarks = ya.sync(function(state) return state.bookmarks or {} end)

local delete_bookmark = ya.sync(function(state,idx) 
	ya.notify {
		title = "Bookmark",
		content = "Bookmark:<"..state.bookmarks[idx].desc .."> deleted",
		timeout = 4,
		level = "info",
	}
	table.remove(state.bookmarks, idx) 
end)

local delete_all_bookmarks = ya.sync(function(state)
	ya.notify {
		title = "Bookmark",
		content = "Bookmark:all bookmarks has been deleted",
		timeout = 4,
		level = "info",
	}
	state.bookmarks = nil 
end)

return {
	entry = function(_,args)
		local action = args[1]
		if not action then
			return
		end

		if action == "save" then
			local value, event = ya.input({
				realtime = false,
				title = "set bookmark message:",
				position = { "top-center", y = 3, w = 40 },
			})
			save_bookmark(value)
			ya.notify {
				title = "Bookmark",
				content = "Bookmark:<"..value.."> saved",
				timeout = 4,
				level = "info",
			}
			return
		end

		if action == "delete_all" then
			return delete_all_bookmarks()
		end


		if action == "jump" then
			local bookmarks = all_bookmarks()
			
			if #bookmarks == 0 then
				return
			end

			local selected = ya.which { cands = bookmarks }

			if selected == nil then
				ya.manager_emit("plugin", { "bookmarks", sync = false, args = "jump" })
				return
			end

			ya.manager_emit("cd", { bookmarks[selected].cwd })
			ya.manager_emit("arrow", { -99999999 })
			ya.manager_emit("arrow", { bookmarks[selected].cursor })
			return
		elseif action == "delete" then
			local bookmarks = all_bookmarks()

			if #bookmarks == 0 then
				return
			end

			local selected = ya.which { cands = bookmarks }
			
			if selected == nil then
				ya.manager_emit("plugin", { "bookmarks", sync = false, args = "delete" })
			end
			delete_bookmark(selected)
			return
		end
	end,
}
