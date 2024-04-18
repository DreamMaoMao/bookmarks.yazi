-- stylua: ignore
local SUPPORTED_KEYS = {
	"a","s","d","j","k","l","p", "b", "e", "t",  "o", "i", "n", "r", "h","c",
	"u", "m", "f", "g", "w", "v", "x", "z", "y", "q"
}

local SERIALIZE_PATH = os.getenv("HOME") .. "/.config/yazi/plugins/bookmarks.yazi/bookmarkcache"

local function string_split(input,delimiter)

	local result = {}

	for match in (input..delimiter):gmatch("(.-)"..delimiter) do
	        table.insert(result, match)
	end
	return result
end

local function delete_lines_by_content(file_path, pattern)
    local lines = {}
    local file = io.open(file_path, "r")

    -- Read all lines and store those that do not match the pattern
    for line in file:lines() do
        if not line:find(pattern) then
            table.insert(lines, line)
        end
    end
    file:close()

    -- Write back the lines that don't match the pattern
    file = io.open(file_path, "w")
    for i, line in ipairs(lines) do
        file:write(line .. "\n")
    end
    file:close()
end

-- save table to file
local save_to_file = ya.sync(function(state,filename)
    local file = io.open(filename, "w+")
	for i, f in ipairs(state.bookmarks) do
		file:write(string.format("%s###%s###%s###%d",f.on,f.file_url,f.desc,f.cursor), "\n")
	end
    file:close()
end)

-- load from file to state
local laod_file_to_state = ya.sync(function(state,filename)
	if state.cache_loaded ~=nil and state.cache_loaded == true then
		return
	end

	if state.bookmarks == nil then 
		state.bookmarks = {}
	end

    local file = io.open(filename, "r")
	if file == nil then 
		return
	end

	for line in file:lines() do
		line = line:gsub("[\r\n]", "")
		local bookmark = string_split(line,"###")
		state.bookmarks[#state.bookmarks + 1] = {
			on = bookmark[1],
			file_url = bookmark[2],
			desc = bookmark[3],
			cursor = tonumber(bookmark[4]),
		}
	end
    file:close()
	state.cache_loaded = true
end)



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
			file_url = tostring(under_cursor_file.url),
			desc = tostring(message),
			cursor = folder.cursor,
		}

		ya.notify {
			title = "Bookmark",
			content = "Bookmark:<"..message.."> saved",
			timeout = 2,
			level = "info",
		}
	
		find = true

		::continue::
	end

	save_to_file(SERIALIZE_PATH)
end)

local all_bookmarks = ya.sync(function(state) return state.bookmarks or {} end)

local delete_bookmark = ya.sync(function(state,idx) 
	ya.notify {
		title = "Bookmark",
		content = "Bookmark:<"..state.bookmarks[idx].desc .."> deleted",
		timeout = 2,
		level = "info",
	}
	delete_lines_by_content(SERIALIZE_PATH,string.format("%s###%s###%s###%d",state.bookmarks[idx].on,state.bookmarks[idx].file_url,state.bookmarks[idx].desc,state.bookmarks[idx].cursor))
	table.remove(state.bookmarks, idx) 
end)

local delete_all_bookmarks = ya.sync(function(state)
	ya.notify {
		title = "Bookmark",
		content = "Bookmark:all bookmarks has been deleted",
		timeout = 2,
		level = "info",
	}
	state.bookmarks = nil
	delete_lines_by_content(SERIALIZE_PATH,".*")
end)

return {
	entry = function(_,args)
		local action = args[1]
		if not action then
			return
		end

		laod_file_to_state(SERIALIZE_PATH)

		if action == "save" then
			local value, event = ya.input({
				realtime = false,
				title = "set bookmark message:",
				position = { "top-center", y = 3, w = 40 },
			})
			save_bookmark(value)
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

			ya.manager_emit(bookmarks[selected].file_url:match("[/\\]$") and "cd" or "reveal", { bookmarks[selected].file_url })

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
