-- do return end
global = {lagControl = true}
awaken = setmetatable({}, {__call = table.insert})
--
inext = ipairs()
toboolean = |var| var and true or false
bit = bit32
--
awaken(function()
	gui = {
		NextItemWidth = "SetNextItemWidth",
		NextWindowSize = "SetNextWindowSize",
		NextWindowSizeClamp = "SetNextWindowSizeConstraints",
		PullCol = "PopStyleColor",
		PullStyleCol = "PopStyleColor",
		PullTree = "TreePop",
		PullVar = "PopStyleVar",
		PushCol = "PushStyleColor",
		PushStyleCol = "PushStyleColor",
		PushTree = "TreePush",
		PushVar = "PushStyleVar",
		SetTableColumn = "TableSetColumnIndex",
		TableSetColumn = "TableSetColumnIndex",
		TextFormatless = "TextUnformatted",
		TextWrap = "TextWrapped",
		Undent = "Unindent",
		}
	for key, val in pairs(gui) do gui[key:lower()] = val end
	setmetatable(gui, {
		__index = function(self, INDEX)
			local key = string.lower(INDEX)
			key = key:gsub("^pull", "pop", 1)
			key = key:gsub("^close", "end", 1)
			if rawget(gui, key) or imgui[key] then
				rawset(self, INDEX, rawget(gui, key) or imgui[key])
				return self[INDEX]
			end
		end,
		__newindex = function(self, INDEX, VALUE)
			rawset(self, INDEX:lower(), VALUE)
		end
	})
	for i, v in pairs(gui) do
		gui[i] = imgui[v]
	end
	gui.Scale = state.Scale
	gui.FontSize = gui.GetFontSize()
	function gui.ButtonDisabled(TEXT, SIZE)
		gui.BeginDisabled()
		gui.Button(TEXT, SIZE)
		gui.CloseDisabled()
	end
	--[=[ str, num, num, ¿num, ¿num, ¿format, ¿imgui_slider_flags ]=] 
	--[=[ nil|num ]=] 
	function gui.SliderScale(LABEL, VALUE, STEP, MIN, MAX, ROUND, FLAGS)
		local Active, Output = gui.SliderInt(
			LABEL,
			(VALUE - MIN)/STEP,
			0,
			(MAX - MIN)/STEP,
			VALUE
		)
		if Active then
			local cval = MIN + Output*STEP
			if ROUND then
				cval = math.round(cval, ROUND)
			end
			if VALUE ~= cval then
				return cval
			end
		end
	end
	function gui.InputClamp(LABEL, VALUE, MIN, MAX, MINSTEP, MAXSTEP, FORMAT, FLAGS)
		local Active, Output = gui.InputFloat(
			LABEL,
			VALUE,
			MINSTEP,
			MAXSTEP,
			FORMAT,
			FLAGS
		)
		if Active then
			return math.clamp(Output, MIN, MAX), true
		end
	end
	function gui.HistoPlot(DATA, MIN, MAX, SIZE, SPACE, FORMAT)
		SIZE[1] = SIZE[1] == -1 and gui.GetWindowRegionAvailWidth() or SIZE[1]
		SIZE[2] = SIZE[2] == -1 and gui.GetWindowRegionAvailHeight() or SIZE[2]
		SPACE = SPACE or 0
		local mini = gui.GetCursorScreenPos()
		local maxi = table.add(mini, SIZE)
		
		local len = #DATA

		local ImDraw = gui.GetWindowDrawList()
		ImColor.FrameBg = gui.GetColorU32("FrameBg")
		ImColor.PlotHistogram = gui.GetColorU32("PlotHistogram")
		
		ImDraw:AddRectFilled(mini, maxi, ImColor.FrameBg)
		local pad = ImStyle.CalcFramePad()
		local inMini = table.add(mini, pad)
		local inSize = { SIZE[1] - pad[1]*2, SIZE[2] - pad[2]*2 }
		local width = inSize[1]/(len)
		if width - SPACE <= 4 then SPACE = 0 end
		local inMaxi = table.add(inMini, inSize)
		ImDraw:PushClipRect(mini, maxi, false)
		local mousehov = gui.IsMouseHoveringRect(mini, maxi)
		for i = 0, len - 1 do
			local x = inMini[1] + width*(i)
			local y = inMaxi[2] - ((DATA[i + 1] - MIN)/(MAX - MIN))*inSize[2]
			local mix, max = math.minmax(x, inMini[1] + width*(i + 1) - SPACE)
			local miy, may = math.minmax(y, inMaxi[2] - inSize[2]/2)
			local pl = {mix, miy}
			local pr = {max, may}
			local color 
			if mousehov then
				local x = gui.GetMousePos()[1]
				if x >= mix and x <= max then
					gui.BeginToolTip()
					gui.Value(i + 1, DATA[i + 1], FORMAT or "%g")
					gui.CloseToolTip()
					color = gui.GetColorU32("PlotHistogramHovered")
					mousehov = false -- cancel checks for other posi's
				end
			end
			ImDraw:AddRectFilled(pl, pr, color or ImColor.PlotHistogram, 0, 0)
		end
		ImDraw:PopClipRect()
		gui.Dummy(SIZE)
	end
	function gui.LinePlot(DATA, MIN, MAX, SIZE, THICKNESS)
		SIZE[1] = SIZE[1] == -1 and gui.GetWindowRegionAvailWidth() or SIZE[1]
		SIZE[2] = SIZE[2] == -1 and gui.GetWindowRegionAvailHeight() or SIZE[2]
		local mini = gui.GetCursorScreenPos()
		local maxi = table.add(mini, SIZE)
		
		local len = #DATA

		local ImDraw = gui.GetWindowDrawList()
		ImColor.FrameBg = gui.GetColorU32("FrameBg")
		ImColor.PlotLines = gui.GetColorU32("PlotLines")
		
		ImDraw:AddRectFilled(mini, maxi, ImColor.FrameBg)
		local BoarderSize = 1
		local pad = ImStyle.CalcFramePad()
		local inMini = table.add(mini, pad)
		local inSize = { SIZE[1] - pad[1]*2, SIZE[2] - pad[2]*2 }
		local scaleX = inSize[1]/(len - 1)
		local inMaxi = table.add(inMini, inSize)
		ImDraw:PushClipRect(mini, maxi, false)
		for i = 0, len - 2 do
			local x1 = inMini[1] + scaleX*(i + 0)
			local x2 = inMini[1] + scaleX*(i + 1)

			local y1 = inMaxi[2] - ((DATA[i + 1] - MIN)/(MAX - MIN))*inSize[2]
			local y2 = inMaxi[2] - ((DATA[i + 2] - MIN)/(MAX - MIN))*inSize[2]

			ImDraw:AddLine({x1, y1}, {x2, y2}, ImColor.PlotLines, THICKNESS or 1)
		end
		ImDraw:PopClipRect()
		gui.Dummy(SIZE)
	end
	local events = {}
	function gui_button(SEND, NAME, SIZE)
		local name = SEND
		SEND = SEND and hotkey[SEND] or SEND
		if SEND and SEND("down") then
			local col = gui.GetColorU32(imgui_col.ButtonActive)
			gui.PushStyleCol(imgui_col.Button, col)
		else
			SEND = false
		end
		local button = gui.Button(NAME, SIZE) or SEND and SEND("press")
		-- gui.SameLine()
		if SEND then
			gui.PullStyleCol(1)
		end
		return button
	end
	function gui_ComboList(NAME, LIST, FLAGS, LABEL)
		if not(gui.BeginCombo(NAME, LABEL or LIST.string, FLAGS)) then return end
		for num, str in ipairs(LIST) do
			if gui.Selectable(str, num == LIST.number) and num ~= LIST.number then
				LIST.string, LIST.number = str, num
				gui.CloseCombo()
				return str, idx
			end
		end
		gui.CloseCombo()
	end
	function gui_CheckBoxtbl(LABLE, TABLE, KEY)
	if gui.Checkbox(LABLE, TABLE[KEY]) then
		TABLE[KEY] = not(TABLE[KEY])
		return true
	end
	function gui.SelectableText(TEXT)
		gui.InputText("##"..TEXT, TEXT, 100, 512 + 4096) -- ReadOnly + AutoSelectAll
	end
end
end)

awaken(function()
	quaver = table.meta:lower{
		IsKeyDown = utils.IsKeyDown,

		captas = || map.Bookmarks,
		factors = || map.ScrollSpeedFactors,
		groups = || map.TimingGroups,
		layers = || map.EditorLayers,
		objects = || map.HitObjects,
		scrolls = || map.ScrollVelocities,
		tempos = || map.TimingPoints,

		GetGroupIds = map.GetTimingGroupIds,
		GetCaptaAt = map.GetBookmarkAt,
		GetFactorAt = map.GetScrollSpeedFactorAt,
		GetScrollAt = map.GetScrollVelocityAt,
		GetTempoAt = map.GetTimingPointAt,
		
		Size = state.WindowSize,
		}
end)
awaken(function()
	editor = table.meta:lower{
		time = state.SongTime,

		captas = map.Bookmarks,
		groups = map.TimingGroups,
		layers = map.EditorLayers,
		objects = map.HitObjects,
		tempos = map.TimingPoints,

		defaultlayer = map.DefaultLayer,
		
		CreateFactor = utils.CreateScrollSpeedFactor,
		CreateScroll = utils.CreateScrollVelocity,
		CreateObject = utils.CreateHitObject,
		CreateTempo = utils.CreateTimingPoint,
		CreateCapta = utils.CreateBookmark,
		CreateAction = utils.CreateEditorAction,
		ObjectKeys = {"StartTime", "Lane", "EndTime", "HitSound", "Type", "EditorLayer", "TimingGroup", "IsLongNote", "JudgementCount"},
		}
	local function EditorCreate(TYPE, KEYS)
		for i, v in ipairs(KEYS) do
			KEYS[i] = "v["..i.."] or v."..v
		end
		KEYS = table.concat(KEYS, ",")
		return eval([[
			return function(DATA)
				for i, v in ipairs(DATA) do
					DATA[i] = ]]..TYPE.."("..KEYS..")"..[[
				end
				return DATA
			end
		]])
	end

	editor.CreateTempos = EditorCreate("editor.CreateTempo", {"StartTime", "Bpm", "Signature", "Hidden"})
	editor.CreateCapTas = EditorCreate("editor.CreateCapTa", {"StartTime", "Note"})
	
	editor.CreateObjects = EditorCreate("editor.CreateObject", {"StartTime", "Lane", "EndTime", "HitSound", "EditorLayer", "Type", "TimingGroup"})
	editor.CreateScrolls = EditorCreate("editor.CreateScroll", {"StartTime", "Multiplier"})
	editor.CreateFactors = EditorCreate("editor.CreateFactor", {"StartTime", "Multiplier"})
	
	editor.RemoveFactors = actions["RemoveScrollSpeedFactorBatch"]
	editor.RemoveScrolls = actions["RemoveScrollVelocityBatch"]
	editor.RemoveObjects = actions["RemoveHitObjectBatch"]
	editor.PlaceObjects = |DATA| actions["PlaceHitObjectBatch"]
	function editor.Decode(DATA, TYPE)
		if not(DATA) then return {} end
		local data, idx = {}, 0
		local gmatch = DATA:gmatch(TYPE)
		repeat
			idx = idx + 1
			data[idx] =	{gmatch()}
		until data[idx][1] == nil
		data[idx] = nil
		return data
	end
	local template = [[
	return function(DATA)
		local copy = {}
		for i, v in ipairs(DATA or @Data) do
			copy[i] = @Copy
		end
		return @Output
	end
	]]
	function editor.CustomEncode(TYPE, COPY)
		if type(TYPE) == "table" then
			return eval(template:gsub("@(%w+)", TYPE))
		else
			return eval(template:gsub("@(%w+)", {Data = "quaver."..TYPE.."()", Copy = COPY, Output = "\""..TYPE..":\"..table.concat(copy, \"|\")"}))
		end
	end
	editor.EncodeCaptas = editor.CustomEncode(
		"captas", [[v.StartTime..","..(v.Note:gsub("𓁹", "𓁹𓁹"):gsub("|", "𓁹"):gsub("\n", [=[\n𓁹]=]))]]
	)
	editor.EncodeFactors = editor.CustomEncode(
		"factors", [[v.StartTime..","..v.Multiplier]]
	)
	function editor.EncodeObjects(DATA)
		local group = chart.CurrentGroupId
		local tbl, idx = {}, 0
		for i, v in ipairs(DATA or editor.objects) do
			if group == v.TimingGroup then
				local long = v.EndTime > 0
				idx = idx + 1
				tbl[idx] = v.StartTime..","..v.Lane..","..(v.Type == 1 and -1 or 1)*(long and 2 or 1)..(long and ","..v.EndTime or "")
			end
		end
		return "objects:"..table.concat(tbl, "|")
	end
	editor.EncodeScrolls = editor.CustomEncode(
		"scrolls", [[v.StartTime..","..v.Multiplier]]
	)
	editor.EncodeTempos = editor.CustomEncode(
		"tempos", [[v.StartTime..","..v.Bpm..","..(v.Hidden and 0 or 1)]]
	)
end)
awaken(function()
	local meta = {}
	chart = {}
	
	local GetUserGroup = function(TAG, NAME)
		local r, g, b = string.match(TAG.ColorRgb or "255,255,255", "([^,]+),([^,]+),([^,]+)")
		return {
			Name = NAME or TAG.Name,
			Tag = TAG,
			Hidden = TAG.Hidden,
			ColorNum = color.rgb_num(r, g, b, 255),
			ColorTbl = {r, g, b, 255},
		}
	end

	local load = {}
	function load.groups()
		chart.groups = {}
		local idx = 0
		for str, tag in pairs(editor.groups) do
			idx = idx + 1
			tag = GetUserGroup(tag, str)
			chart.groups[str] = tag
			chart.groups[idx] = tag
		end
		table.sort(chart.groups, |A, B| A.Name < B.Name)
	end
	function load.layers()
		chart.layers = {GetUserGroup(editor.defaultlayer)}
		local idx = 1
		for str, tag in ipairs(editor.layers) do
			idx = idx + 1
			str = tag.Name
			tag = GetUserGroup(tag, str)
			chart.layers[tostring(str)] = tag
			chart.layers[idx] = tag
		end
	end
	-- load.notes()
	load.groups()
	load.layers()
	-- load.scrolls()
	-- load.factors()
	-- load.notes()
	-- load.captas()
	-- load.tempos()
	
	listen(function(EVENT)
		local typ = tostring(EVENT.Type):lower()
		editor.scrolls = quaver.scrolls()
		editor.factors = quaver.factors()
		if typ == "batch" then
			load.groups()
			load.layers()
			return end --[[kill]]
		if typ:has("group") then
			load.groups()
			return end --[[kill]]
		if typ:has("layer") then
			load.layers()
			return end --[[kill]]
	end)
	
	chart.KeyCount = map.GetKeyCount()
	editor.KeyCount = map.GetKeyCount()
	editor.Artist, editor.Title, chart.Title = tostring(map):match("([^%-]*)%s+%-%s+([^%[]*)%s+%[([^%]]*)%]")
	-- print(editor.Artist, editor.Title, chart.Title)
end)

action = {}
function action.BreakLeave(BOOL)-- break quaver on leaving the editor (or plugin reload)
	if BOOL then
		for i = 1, 1000000 do
			listen(function() end)
		end
	end
end

function action.Break(BOOL)-- break the editor
	if BOOL == true then
		local function Break()
			actions.PlaceHitObject(1, 1)
			Break() -- :^c
		end
		Break()
	end
end

function action.Crash(BOOL)-- crash quaver
	if BOOL == true then
		local function crash()
			actions.PlaceHitObject(utils.CreateHitObject(math.random(0, map.TrackLength), math.random(1, tonumber(map.Mode))))

			crash(crash(crash())) -- ;3c
		end
		crash()
	end
end

function action.MoveToLayer(INDEX)
	if INDEX == "Default Layer" then INDEX = 1 end
	if type(INDEX) ~= "number" then
		for i, v in ipairs(editor.layers) do
			if v.Name == INDEX then INDEX = i + 1 break end
		end
	end
	if type(INDEX) ~= "number" then error("cannot switch layer to: "..tostring(INDEX)) end
	actions.CreateLayer(utils.CreateEditorLayer(), INDEX)
	actions.RemoveLayer(map.EditorLayers[INDEX])
end
function action.MoveToGroup(INDEX)
	if type(INDEX) ~= "string" then
		for i, v in ipairs(editor.groups) do
			if i == INDEX then INDEX = v break end
		end
	end
	if type(INDEX) ~= "string" then error("cannot switch group to: "..tostring(INDEX)) end
	state.SelectedScrollGroupId = INDEX
end
function action.GetNotesUnsnapped(TIME, SNAP)
	TIME = TIME or 1
	local select = editor.objects
	if not(select[1]) then return end
	-- local tempo = state.CurrentTimingPoint
	SNAP = SNAP or {state.CurrentSnap}
	if type(SNAP) ~= "table" then SNAP = {SNAP} end
	local unsnapped = {}
	local tbl, idx = {}, 0
	local len = #SNAP
	for i, v in ipairs(select) do
		local timeA = v.StartTime
		local timeE = v.EndTime
		local snapBody = true
		local Snap
		for i = 1, len do
			Snap = SNAP[i]
			local timeB = map.GetNearestSnapTimeFromTime(true, Snap, timeA - TIME) 
			if timeA == math.floor(timeB) or timeA == math.ceil(timeB) then
				snapBody = true
				break
			end
			snapBody = false
		end
		if not(snapBody) then
			idx = idx + 1
			tbl[idx] = {i = i, time = timeA, snap = Snap, lane = v.Lane}
		end
		if timeE > 0 then
			local snapHeld = true
			for i = 1, len do
				Snap = SNAP[i]
				local timeB = map.GetNearestSnapTimeFromTime(true, Snap, timeE - TIME) 
				if timeE == math.floor(timeB) or timeE == math.ceil(timeB) then
					snapHeld = true
					break
				end
				snapHeld = false
			end
			if not(snapHeld) then
				if snapBody then
					idx = idx + 1
					tbl[idx] = {i = i, hold = timeE, holdsnap = Snap, lane = v.Lane}
				else
					tbl[idx].hold = timeE
					tbl[idx].holdsnap = Snap
				end
			end
		end
	end
	return tbl
end
function action.Delete(TYPE, DATA)
	local len = #DATA
	if len == 0 then return end
	editor["Remove"..TYPE](DATA)
	print("Deleted:\n"..TYPE.." - "..len)
end

util = {
	GetOffsets = function(data, key) return utils.ToFloat(data[1][key or "StartTime"]), utils.ToFloat(data[#data][key or "StartTime"]) end
	}
function util.getbetween(DATA, START, CLOSE)
	if not(DATA) then error("util.getbetween", DATA) end
	local i, j = 1, #DATA
	i = toolbox.SearchLower(DATA, START, "StartTime", nil, nil, i, j)
	if DATA[i] and DATA[i].StartTime < START then
		i = i + 1
	end
	j = toolbox.SearchUpper(DATA, CLOSE, "StartTime", nil, nil, i > 0 and i or 1, j)
	if DATA[j] and DATA[j].StartTime > CLOSE then
		j = j - 1
	end
	local tbl, idx = {}, 0
	for i = i, j do
		idx = idx + 1
		tbl[idx] = DATA[i]
	end
	return tbl, i, j
end
function util.GetLaneObjects(OBJECTS)
	local unique = {}
	local holder = {}
	local idx = 0
	for i, v in ipairs(OBJECTS) do
		local time = v.StartTime
		if holder[time] ~= true then
			holder[time] = true
			idx = idx + 1
			unique[idx] = {v}
		else
			table.insert(unique[idx], v)
		end
	end
	return unique
end
awaken(function() table.meta:lower(util) end)

global.advanced = true
global.step = 5
global.noteinfo = false
plugin = {
	name = "ADDtHER!Al",
	flag = 8 + 64,
	width = 280,
	size = {280, 0},
	render = {},
	renderOnPlugin = {},
	}
awaken(function()
	plugin.width = plugin.width*gui.scale
	plugin.mini = {plugin.width, 0}
	plugin.maxi = {plugin.width, -1}
	plugin.size = table.mul(plugin.size, gui.scale)
end)
math.randomseed(os.time())
clock = {}
awaken(function()
	clock.StartTime = os.time()
	clock.EditorTime = gui.GetTime
	clock.QuaverTime = os.clock
	local deltatime = os.time
	clock.PluginTime = || deltatime() - clock.StartTime
end)
do -- color.
local meta = {}
function meta:__call(IDX, VAL, FLIP)
	if VAL then
		if FLIP then
			IDX, VAL = VAL, IDX
		end
		self[IDX] = VAL
		return function(COL)
			self[COL] = VAL
		end
	else
		return self[IDX]
	end
end
color = {
	str = setmetatable({}, meta),
	num = setmetatable({}, meta),
	vec = setmetatable({}, meta),
	}
color.num(0x00000001, "RMask", true)
color.num(0x00000100, "GMask", true)
color.num(0x00010000, "BMask", true)
color.num(0x00010101, "WhiteMask", true)
color.num(0x01000000, "AlphaMask", true)

color.alpha = color.num.AlphaMask
color.red = color.num.RMask
color.green = color.num.GMask
color.blue = color.num.BMask
color.white = color.num.WhiteMask

local band, rshift, lshift = bit32.band, bit32.rshift, bit32.lshift
color.num_hex = |num| string.format("%08X", num)
color.num_rgb = function(num) return band(rshift(num, 24), 255), band(rshift(num, 16), 255), band(rshift(num, 08), 255), band(num, 255) end

color.rgb_num = |r, g, b, a| lshift(a or (not(g) and r[4]) or 255, 24) + lshift(b or r[3] or 0, 16) + lshift(g or r[2] or 0, 8) + (g and r or r[1] or 0)
function color.AlterAlpha(U32, ALTER)
	local a = bit.band(bit.rshift(U32, 24), 255)
	return U32 - bit.lshift(a*ALTER, 24)
end

---Alters opacity of a given color.
---@param col integer
---@param additiveOpacity integer A number corresponding to the addition to the alpha channel (0-255).
---@return number
---@overload fun(col: Vector4, additiveOpacity: number): Vector4
function color.alterOpacity(col, additiveOpacity)
	if type(col) ~= "number" then
		col[4] = col[4] + additiveOpacity
		return col
	end
	return col + math.floor(additiveOpacity)*color.alpha
end
local function CreateColorVector(R, G, B, A)
	return {r = r or 0, g = g or 0, b = b or 0, a = a or 1}
end
end -- do color.

toolbox = {}
function toolbox.search(TABLE, TIME, KEY, I, J)
	local lower, upper = I or 1, J or #TABLE
	local middle, value
	while lower <= upper do
		middle = floor((lower + upper)/2)
		value = TABLE[middle]
		if value and (value[KEY] <= TIME) then
			lower = middle + 1
		else
			upper = middle - 1
	end end
	value = TABLE[lower]
	if value and value[KEY] > TIME then
		return lower - 2
	end
	return lower - 1
end

do -- board.
local tbl = {__call = |self, idx| self[idx]}
function tbl:__index(INDEX)
	if INDEX == "any" then
		for key, bool in pairs(self) do
			if bool then return key end
		end
		return
	end
	if INDEX == "all" then
		local idx, tbl = 0
		for key, bool in pairs(self) do
			if bool then
				tbl = tbl or {}
				idx = idx + 1
				tbl[idx] = key
		end end
		return tbl
	end
end
board = {
	press = setmetatable({}, tbl),
	release = setmetatable({}, tbl),
	down = setmetatable({}, tbl),
	check = {}
	}
board.setcheck = function(BOOL, ...)
	if not(...) then return end
	BOOL = BOOL or nil
	if (...) == "all" then
		for _, key in ipairs(keys) do
			board.check[tostring(key)] = BOOL
		end
		return
	end
	local tbl = {...}
	for i = 1, #tbl do
		board.check[tbl[i]] = BOOL
	end
end
board.setevent = board.setcheck
local last = {}
board.event = function()
	local keydown = utils.IsKeyDown
	local D_ = board.down
	local P_ = board.press
	local R_ = board.release
	for key in pairs(board.check) do
		local down = keydown(key)
		P_[key] = down and not(D_[key])
		R_[key] = not(down) and D_[key]
		D_[key] = down
	end
end
board.shift = || board.down["LeftShift"] or board.down["RightShift"]
board.alt = || board.down["LeftAlt"] or board.down["RightAlt"]
board.ctrl = || board.down["LeftControl"] or board.down["RightControl"]
hotkey = {}
-- T|Shift+T|S|N|R|B|M|V|G|Ctrl+Alt+L|Ctrl+Alt+E|O
awaken(function()
	board.setcheck(true, "LeftShift", "RightShift", "LeftAlt", "RightAlt", "LeftControl", "RightControl")
	board.setcheck(true, "Up", "Down")
	board.setcheck(true, "T", "S", "R", "N", "O")
end)

hotkey.Alternative = || board["Shift"]()
hotkey.Increase = |typ| board[typ or "press"]["Up"] and not(gui.IsAnyItemActive())
hotkey.Decrease = |typ| board[typ or "press"]["Down"] and not(gui.IsAnyItemActive())

hotkey["exec0"] = |typ| board[typ or "press"]["T"] and not(board.shift()) and not(gui.IsAnyItemActive())
hotkey["nega0"] = |typ| board[typ or "press"]["N"] and not(board.shift()) and not(gui.IsAnyItemActive())
hotkey["rest0"] = |typ| board[typ or "press"]["R"] and not(board.shift()) and not(gui.IsAnyItemActive())
hotkey["swap0"] = |typ| board[typ or "press"]["S"] and not(board.shift()) and not(board.ctrl()) and not(gui.IsAnyItemActive())

hotkey["exec1"] = |typ| board[typ or "press"]["T"] and board.shift() and not(gui.IsAnyItemActive())
hotkey["nega1"] = |typ| board[typ or "press"]["N"] and board.shift() and not(gui.IsAnyItemActive())
hotkey["rest1"] = |typ| board[typ or "press"]["R"] and board.shift() and not(gui.IsAnyItemActive())
hotkey["swap1"] = |typ| board[typ or "press"]["S"] and board.shift() and not(board.ctrl()) and not(gui.IsAnyItemActive())

hotkey.go_to_prev_tg = |typ| nil
hotkey.go_to_next_tg = |typ| nil
hotkey.exec_vibrato = |typ| nil
hotkey.go_to_note_tg = |typ| nil
hotkey.toggle_note_lock = |typ| nil
hotkey.toggle_end_offset = |typ| nil

hotkey.move_selection_to_tg = |typ| board[typ or "press"]["O"]
end -- do -- board.
-- json
-- math
-- string
-- table
-- yaml
json.decode = json.parse
json.encode = json.serialize
do -- math.
math.inf = 1/0 -- infinity
math.nan = 0/0 -- Not a Number (NaN)
math.tiny = 5E-324 -- Smallest possiable number

---Restricts num to be within min and max.
--[=[ num, num, num ]=]
--[=[ num ]=]
math.clamp = |num, min, max| min > num and min or max < num and max or num
math.avg = |...| table.avg{ ... }

---returns the major of num
--[=[ num ]=]
--[=[ num ]=]
math.major = |num| num < 0 and math.ceil(num) or math.floor(num)
math.majorlen = |num| #string.gsub(num, "([^%.]*).*", "%1")

--[=[ num1 [, num2, ...] ]=]
--[=[ num, num ]=]
math.minmax = function(...) return math.min(...), math.max(...) end

---returns the minor of num
--[=[ num ]=]
--[=[ num ]=]
math.minor = |num| num - (num < 0 and math.ceil(num) or math.floor(num))
math.minorlen = |num| #string.gsub(num, "[^%.]+%.", "")

math.len = |num| #string.gsub(num, "[^%.]+%.", "")

---Evaluates a simplified one-dimensional hermite related (?) spline for SV purposes
---@param m1 number
---@param m2 number
---@param y2 number
---@param t number
---@return number
function math.hermite(m1, m2, y2, t)
	local a = m1 + m2 - 2*y2
	local b = 3*y2 - 2*m1 - m2
	local c = m1
	return a*t^3 + b*t^2 + c*t
end

---Returns a number that is `(i*100)%` of the way from travelling between `x` and `y`.
 -- linear interpolation
--[=[ num, num, num ]=]
--[=[ num ]=]
math.lerp = |x, y, i| x + (y - x)*i

---Rounds NUM to DECIMAL decimal places.
--[=[ num, ¿num ]=]
--[=[ num ]=]
function math.round(NUM, DECIMAL)
	if not(DECIMAL) then return math.floor(NUM + 0.5) end
	local notation = 10^DECIMAL
	return math.floor(NUM*notation + 0.5)/notation
end
end -- do -- math.
do -- string.
function pluralize(str, val, pos)
	if pos then
		str = str:sub(1, pos)
	end
	if val == 1 then return not(pos) and str or str..(str:sub(pos + 1, -1) or "") end
	local lastLetter = str:sub(-1):upper()
	local secondToLastLetter = str:sub(-2, -2):upper()
	if lastLetter == "X" and secondToLastLetter:find("[IE]") then
		return str:sub(1, -2).."ices"
	end
	if (lastLetter == "Y" and table.find(CONSONANTS, secondToLastLetter)) or str:sub(-3):upper() == "QUY" then
		return str:sub(1, -2).."ies"
	end
	if lastLetter:find("[JSXZ]") or str:sub(-2):upper():find("[SC]H") then
		return str.."es"
	end
	if (lastLetter == "E" and secondToLastLetter == "F") or lastLetter == "F" then
		return str:sub(1, -2).."ves"
	end
	return str.."s"
end


--Capitalizes the first letter of the given string.
---If `lower`; all letters beyound the first will be lowercase.
--[=[ str, bool ]=]
--[=[ str ]=]
string.capitalize = |str, lower| str:sub(1, 1):upper() .. (lower and str:sub(2):lower() or str:sub(2))

function string.has(STRING, ITEM, AT, BOOL)
	BOOL = not BOOL
	if AT then return STRING:find(ITEM, AT, BOOL) == AT end
	return STRING:find(ITEM, nil, BOOL) and true or false
end

function string.ordinal(STR)
	STR = tostring(STR)
	local num
	num = tonumber(STR:sub(-2))
	if 4 <= num and num <= 20 then
		return STR.."th"
	elseif num == 0 then
		return STR
	end
	num = tonumber(STR:sub(-1))
	if num == 0 or (4 <= num and num <= 9) then
		return STR.."th"
	end
	if num == 1 then return STR.."st" end
	if num == 2 then return STR.."nd" end
	if num == 3 then return STR.."rd" end
	return STR
end

--[=[ str, str, ¿num ]=]
--[=[ str, num ]=]
string.remove = |str, itm, cnt| string.gsub(str, itm, "", cnt)

--splits STRING into a table via FORMAT.
--[=[ str, str ]=]
--[=[ str ]=]
function string.split(STRING, FORMAT)
	local tbl, i = {}, 0
	for v in STRING:gmatch(FORMAT) do
		i = i + 1
		tbl[i] = v
	end
	return tbl
end
end -- do -- string.
do -- table.
--[=[ key1 [, key2, ...] ]=] -- input
--[=[ func ]=] -- output
local function SplitKeys(...)
	if (...) == nil then return |x| x end
	local a, b = ...
	if a and type(a) == "table" then
		local keys = a
		return function(X)
			local tbl = {}
			for old, new in pairs(keys) do
				tbl[new] = X[old]
			end
			return tbl
		end
	elseif b == nil then
		local key = a
		return |x| x[key]
	end

	local keys = {...}
	return function(X)
		local tbl = {}
		for _, key in ipairs(keys) do
			tbl[key] = X[key]
		end
		return tbl
	end
end

local template = [[
return function(X, Y, ...)
	local tbl = {}
	if type(Y) == "number" then
		for i = 1, #X do
			tbl[i] = X[i] @Math Y
		end
	else
		for i = 1, #X do
			tbl[i] = X[i] @Math Y[i]
		end
	end
	return ... and table.@Self(tbl, ...) or tbl
end
]]
table.add = eval(template:gsub("@(%w+)", {Math = "+", Self = "add"}))
table.div = eval(template:gsub("@(%w+)", {Math = "/", Self = "div"}))
table.mod = eval(template:gsub("@(%w+)", {Math = "%", Self = "mod"}))
table.mul = eval(template:gsub("@(%w+)", {Math = "*", Self = "mul"}))
table.sub = eval(template:gsub("@(%w+)", {Math = "-", Self = "sub"}))
function table.unm(TBL)
	local tbl = {}
	for i = 1, #TBL do
		tbl[i] = -TBL[i]
	end
	return tbl
end

function table.clamp(X, MIN, MAX)
	X = table.copy(X, ipairs)
	if type(MIN) == "number" then
		for i = 1, #X do
			X[i] = math.max(X[i], MIN)
		end
	else
		for i = 1, #MIN do
			X[i] = math.max(X[i], MIN[i])
		end
	end
	if type(MAX) == "number" then
		for i = 1, #X do
			X[i] = math.min(X[i], MAX)
		end
	else
		for i = 1, #MAX do
			X[i] = math.min(X[i], MAX[i])
		end
	end
	return X
end

function table.avg(TBL, LEN)
	local avg = 0
	local len = LEN or #TBL
	for i = 1, len do
		avg = avg + TBL[i]
	end
	return avg/len
end
function table.max(TBL)
	local max = -math.inf
	for i = 1, #TBL do
		local v = TBL[i]
		if max < v then max = v end
	end
	return max
end
function table.min(TBL)
	local min = math.inf
	for i = 1, #TBL do
		local v = TBL[i]
		if min > v then min = v end
	end
	return min
end
function table.minmax(TBL, LEN)
	local max = -math.inf
	local min = math.inf
	for i = 1, LEN or #TBL do
		local v = TBL[i]
		if min > v then min = v end
		if max < v then max = v end
	end
	return min, max
end


--insert TABLE2's values into TABLE1.
--[=[ tbl, tbl ]=]-- input
--[=[ tbl ]=]-- output
function table.combine(TABLE1, TABLE2)
	for i, v in pairs(TABLE2) do
		TABLE1[i] = TABLE1[i] or v
	end
	return TABLE1
end
--insert TABLE2's values into TABLE1.
--[=[ tbl, tbl ]=]-- input
--[=[ tbl ]=]-- output
function table.icombine(TABLE1, TABLE2)
	local len = #TABLE1
	for i = 1, #TABLE2 do
		TABLE1[i + len] = TABLE2[i]
	end
	return TABLE1
end
--create a copy of TABLE.
--[=[ tbl, ¿func ]=] -- input
--[=[ tbl ]=] -- output
function table.copy(TABLE, FUNC)
	local tbl = {}
	for i, v in (FUNC or pairs)(TABLE) do
		tbl[i] = type(v) == "table" and table.copy(v) or v
	end
	return tbl
end
 -- KEYS -> {new_key = old_key, ...}
--[=[ tbl, tbl, tbl ]=]
--[=[ tbl ]=]
table.rekey = function(OLD, NEW, KEYS)
	if KEYS == nil then
		KEYS = NEW
		NEW = {}
	end
	for i = 1, #OLD do
		local v = OLD[i]
		local tbl = {}
		NEW[i] = tbl
		for new, old in pairs(KEYS) do
			tbl[new] = v[old]
		end
	end
	return NEW
end

--copy TABLE to a new table, including its metatable.
--[=[ tbl, ¿func ]=] -- input
--[=[ tbl ]=] -- output
function table.clone(TABLE, TYPE)
	local clone = {}
	for i, v in (TYPE or pairs)(TABLE) do
		if type(v) == "table" then
			local meta = getmetatable(v)
			clone[i] = setmetatable(table.copy(v), meta and table.copy(meta) or nil)
		else
			clone[i] = v
		end
	end
	return setmetatable(clone, getmetatable(TABLE))
end

--find ITEM within TABLE.
--[=[ tbl, var, ¿func ]=] -- input
--[=[ var|bool ]=] -- output
function table.find(TABLE, ITEM, PAIR)
	for i, v in (PAIR or ipairs)(TABLE) do
		if v == ITEM then return i end
	end
	return false
end

---In a nested TABLE, returns a table of property values with keys in `...`.
--[=[ tbl, key1 [, key2, ...] ]=]
--[=[ tbl ]=]
function table.gather(TABLE, ...)
	local tbl = {}
	local split = SplitKeys(...)
	for i, v in ipairs(TABLE) do
		tbl[i] = split(v)
	end
	return tbl
end

--ouput is a table containing all the keys from TABLE.
--[=[ tbl ]=] -- input
--[=[ tbl ]=] -- output
function table.keys(TABLE)
	local idx = 0
	local keys = {}
	local holder = {} -- don't repeat keys
	for key in pairs(TABLE) do
		if not(holder[key]) then
			holder[key] = true
			idx = idx + 1
			keys[idx] = key
		end
	end
	return keys
end

---Normalizes a table of numbers to achieve a target average.
---@param values number[] The table to normalize.
---@param targetAverage number The desired average value.
---@return number[]
function table.normalize(TABLE, AVERAGE)
	local avg = table.avg(TABLE)
	for i, v in inext, TABLE, 1 - 1 do
		TABLE[i] = (v*AVERAGE)/avg
	end
	return TABLE
end


table.meta = {}
function table.meta:lower(TBL)
	local meta = {}
	for i, v in pairs(TBL) do
		if type(i) == "string" then
			TBL[i:lower()] = v
	end end
	function meta:__index(IDX)
		local key = string.lower(IDX)
		if key then
			local val = rawget(self, key)
			if val then
				rawset(self, IDX, val)
				return val
	end end end
	meta.__newindex = |self, idx, val| rawset(self, string.lower(idx) or idx, val)
	return setmetatable(TBL, meta)
end
function table.meta:call(TBL, FNC)
	if not(FNC) and TBL then TBL, FNC = {}, TBL end
	if not(TBL) then TBL = {} end
	local meta = getmetatable(TBL) or {}
	meta.__call = FNC
	return setmetatable(TBL, meta)
end

---repeat ITEM CNT times into a table
--[=[ var, num ]=] -- input
--[=[ tbl ]=] -- output
function table.rep(ITEM, CNT)
	local tbl = {}
	for i = 1, CNT do
		tbl[i] = ITEM
	end
	return tbl
end

--reverses TABLE starting from I[or 1] ending at J[or #TABLE].
--[=[ tbl, ¿num, ¿num ]=]
--[=[ tbl ]=]
function table.reverse(TABLE, I, J)
	local lower, upper = I or 1, J or #TABLE
	while lower < upper do
		TABLE[lower], TABLE[upper] = TABLE[upper], TABLE[lower]
		lower = lower + 1
		upper = upper - 1
	end
	return TABLE
end

--in a linear values of TABLE, searches for the closest number to ITEM.
--[=[ tbl, var, ¿var, ¿num, ¿num ]=]
--[=[ num ]=]
function table.search(TABLE, ITEM, KEY, I, J)
	local lower, upper = (I or 1), (J or #TABLE)
	local middle
	local split = SplitKeys(KEY)
	while lower <= upper do
		middle = math.floor((lower + upper)/2)
		if split(TABLE[middle]) <= ITEM then
			lower = middle + 1
		else
			upper = middle - 1
	end end
	return lower - 1
end

--removes any duplicate values in TABLE.
--[=[ tbl ]=]
--[=[ tbl ]=]
table.unique = function(TABLE)
	local tbl, Holder = {}, {}
	local idx = 1
	for _, v in ipairs(TABLE) do
		if not(Holder[v]) then
			Holder[v] = true
			tbl[idx] = v
			idx = idx + 1
		end
	end
	return tbl
end
end -- do -- table.
do -- yaml.
yaml = {}
yaml.read = read
yaml.write = write
end
ALPHABET_LIST = string.split("ABCDEFGHIJKLMNOPQRSTUVWXYZ", ".")
CONSONANTS = string.split("BCDFGHJKLMNPQRSTVWXZ", ".")

local search = [[
return function(TABLE, VAL1, KEY1, VAL2, KEY2, I, J)
	local lower, upper = I or 1, J or #TABLE
	local middle, value
	local floor = math.floor
	while lower <= upper do
		middle = floor((lower + upper)/2)
		value = TABLE[middle]
		if value and (value[KEY1] %s VAL1) then
			lower = middle + 1
		else
			upper = middle - 1
	end end
	%s
	if KEY2 then
		value = TABLE[lower]
		if VAL2 == value[KEY2] then return lower, true end
		while VAL1 == value[KEY1] do
			lower = lower - 1
			value = TABLE[lower]
			if not(value) then
				lower = lower + 1
				break
			end
			if VAL2 == value[KEY2] then return lower, true end
		end
		value = TABLE[lower]
		while VAL1 == value[KEY1] do
			lower = lower + 1
			value = TABLE[lower]
			if not(value) then
				lower = lower - 1
				break
			end
			if VAL2 == value[KEY2] then return lower, true end
		end
	end
	return lower
end
]]
toolbox.SearchUpper = eval(search:format("<=", "lower = lower - 1"))
toolbox.SearchLower = eval(search:format("<", ""))

function ToolTip(TEXT)
	gui.PushCol("PopupBg", color.AlterAlpha(gui.GetColorU32("PopupBg"), .2))
	gui.BeginTooltip()
	gui.PullCol()
	gui.PushTextWrapPos(gui.FontSize*30)
	gui.TextFormatless(TEXT)
	gui.PullTextWrapPos()
	gui.CloseTooltip()
end
--[[ str ]]-- show TEXT (as a tooltip) when you hover over something
function HoverToolTip(TEXT, FLAG)
	if gui.IsItemHovered(FLAG) then
		gui.BeginTooltip()
		gui.PushTextWrapPos(gui.FontSize*30)
		gui.TextFormatless(TEXT)
		gui.PullTextWrapPos()
		gui.CloseTooltip()
	end
end
--[[ ? ]]-- show TEXT (as a tooltip) when you hover over "(?)"
function DrawHoverHelp(FLAG)
	gui.Sameline()
	gui.TextDisabled[[(?)]]
	return gui.IsItemHovered(FLAG)
end
--[[ str, ? ]]-- show TEXT (as a tooltip) when you hover over "(?)"
function HoverHelpTip(TEXT, FLAG)
	gui.Sameline()
	gui.TextDisabled[[(?)]]
	if gui.IsItemHovered(FLAG) then
		gui.BeginTooltip()
		gui.PushTextWrapPos(gui.FontSize*30)
		gui.TextFormatless(TEXT)
		gui.PullTextWrapPos()
		gui.CloseTooltip()
	end
end
__emoticon = {
	-- ⪩ ⪨ ꠹
	default = [=[( - _ - )]=],
	circular = [=[8>v<8]=],
	custom = [=[-* . *-]=],
	exponential = [=[-^ _ ^-]=],
	hermite = [=[ > ~ <')]=],
	random = [=[o _ o]=],
	teleport = [=[(,  -  ')]=],
	animated = nil
	}

awaken(function()
	local pos = {0, 0}
	local Im = {}
	local ImC = gui.GetIO()
	Im.C = {
		boardevent = ImC.AddKeyEvent,
		focusevent = ImC.AddFocusEvent,
		inputevent = ImC.AddInputCharactersUTF8,
		}
	ImDraw = gui.GetOverlayDrawlist()
	local ImCmd = ImDraw.CmdBuffer[0]
	Im.Cmd = {
		-- ImCmd.
		}
	Im.Style = {
		FramePad = {4, 3}
		}
		local win = 0
		local oldwin = gui.Close
		
		local newwin = function(NAME, FOLL)
			gui.SetNextWindowSize{200, 200}
			if FOLL then
				pos[1] = pos[1] + 200
				gui.SetNextWindowPos(pos)
			end
			win = win + 1
			gui.Begin(tostring(NAME or win), 256)
		end
		local size = Im.Style
		newwin("Region + Title size", true)
		local min = gui.GetWindowContentRegionMin()
		local max = gui.GetWindowContentRegionMax()
		size.WindowPad = {200 - max[1], 200 - max[2]}
		size.WindowTit = min[2] - size.WindowPad[2]
		oldwin()

		newwin("Item Padding", true)
		size.ItemPad = {}
		gui.Button("", {20, 20})
		gui.SameLine()
		gui.NextItemWidth(-1)
		gui.InputTextMultiline("##ff", "", 0, {-1, 20})
		local RectA = gui.GetItemRectSize()
		size.ItemPad[1] = ((180 - (RectA[1] + 1))/2 - size.WindowPad[1])*2
		gui.InputTextMultiline("##fff", "", 0, {-1, -1})
		local RectB = gui.GetItemRectSize()
		size.ItemPad[2] = ((180 - (RectB[2] + 1))/2 - size.WindowPad[2])*2 - size.WindowTit
		oldwin()
		newwin("Cell Padding", true)
		size.CellPad = {}
		gui.BeginTable("Menu", 1, 1920)
		gui.TableNextRow()
		gui.TableNextColumn()
		gui.InputTextMultiline("##ff", "", 0, {-1, -1})
		local Rect = gui.GetItemRectSize()
		size.CellPad[1] = (200 - (Rect[1] + 1))/2 - size.WindowPad[1] - 1
		size.CellPad[2] = ((200 - size.WindowTit) - (Rect[2] + 1))/2 - size.WindowPad[2]
		gui.CloseTable()
		oldwin()

		newwin("Display")
		pos = gui.GetWindowPos()
		gui.Value("Window Pad X", size.WindowPad[1])
		gui.Value("Window Pad Y", size.WindowPad[2])
		gui.Value("Window Title Y", size.WindowTit)
		gui.Value("Item Pad X", size.ItemPad[1])
		gui.Value("Item Pad Y", size.ItemPad[2])
		gui.Value("Cell Pad X", size.CellPad[1])
		gui.Value("Cell Pad Y", size.CellPad[2]) 
		oldwin()
	local _ = gui.GetStyle
	function Im.Style.calcwinpad()
		gui.SetNextWindowSize{200, 200}
		gui.SetNextWindowPos{200, 200}
		gui.Begin("ImStyleCalcWinPad", 32 + 256)
		local ppp = gui.GetWindowContentRegionMin()
		ppp[2] = ppp[2] - gui.GetFrameHeight()
		gui.End()
		return ppp
	end
	function Im.Style.calcframepad()
		local FramePad = {}
		gui.SetNextWindowSize{200, 200}
		gui.SetNextWindowPos{-200, -200}
		gui.Begin("ImStyle##CalcFramePad", 32 + 256)
		local WinTit = gui.GetFrameHeight()
		gui.Button("")
		local BtnSiz = gui.GetItemRectSize()[1]
		
		gui.PushStyleVar(11, {0, 0})
		local WinTit1 = gui.GetFrameHeight()
		
		gui.PushStyleVar(11, {0, 20})
		local WinTit2 = gui.GetFrameHeight()
		
		gui.PopStyleVar(2)
		
		local scaleY = (WinTit2 - WinTit1)/20
		gui.Text(scaleY)
		local x = BtnSiz/scaleY
		local y = (WinTit - WinTit1)/scaleY
		gui.End()
		return {x, y}
	end
	for i, v in next, Im do
		_G["Im"..i] = table.meta:lower(v)
	end
	do return end
	render("ffff", function()
		if gui.Begin("StyleEditor") then
			gui.ShowStyleEditor()
			gui.Close()
		end
		do return end
		local win = 0
		local oldwin = gui.Close
		
		local newwin = function(NAME, FOLL)
			gui.SetNextWindowSize{200, 200}
			if FOLL then
				pos[1] = pos[1] + 200
				gui.SetNextWindowPos(pos)
			end
			win = win + 1
			gui.Begin(tostring(NAME or win), 256)
		end
		local size = {}
		newwin("Region + Title size", true)
		local min = gui.GetWindowContentRegionMin()
		local max = gui.GetWindowContentRegionMax()
		size.WindowPad = {200 - max[1], 200 - max[2]}
		size.WindowTit = min[2] - size.WindowPad[2]
		oldwin()

		newwin("Item Padding", true)
		size.ItemPad = {}
		gui.Button("", {20, 20})
		gui.SameLine()
		gui.NextItemWidth(-1)
		gui.InputTextMultiline("##ff", "", 0, {-1, 20})
		local RectA = gui.GetItemRectSize()
		size.ItemPad[1] = ((180 - (RectA[1] + 1))/2 - size.WindowPad[1])*2
		gui.InputTextMultiline("##fff", "", 0, {-1, -1})
		local RectB = gui.GetItemRectSize()
		size.ItemPad[2] = ((180 - (RectB[2] + 1))/2 - size.WindowPad[2])*2 - size.WindowTit
		oldwin()
		-- print(map.TimingPoints[1])
		newwin("Cell Padding", true)
		size.CellPad = {}
		gui.BeginTable("Menu", 1, 1920)
		gui.TableNextRow()
		gui.TableNextColumn()
		gui.InputTextMultiline("##ff", "", 0, {-1, -1})
		local Rect = gui.GetItemRectSize()
		size.CellPad[1] = (200 - (Rect[1] + 1))/2 - size.WindowPad[1] - 1
		size.CellPad[2] = ((200 - size.WindowTit) - (Rect[2] + 1))/2 - size.WindowPad[2]
		-- table.sub(Rect, )
		gui.CloseTable()
		oldwin()
		
		
		newwin("Display")
		pos = gui.GetWindowPos()
		gui.Value("Window Pad X", size.WindowPad[1])
		gui.Value("Window Pad Y", size.WindowPad[2])
		gui.Value("Window Title Y", size.WindowTit)
		gui.Value("Item Pad X", size.ItemPad[1])
		gui.Value("Item Pad Y", size.ItemPad[2])
		gui.Value("Cell Pad X", size.CellPad[1])
		gui.Value("Cell Pad Y", size.CellPad[2]) 
		oldwin()
	end)
end)

local SVstatsTime = os.clock()
local function RenderSVStats(ENUM)
	gui.Begin("SV Stats", 2 + 8)
	if gui.IsWindowCollapsed() then
		gui.Close()
		return
	end
		
	local Plot = ENUM.PlotData
	local Line = ENUM.LineData
	local avgData = ENUM.avgData
	local minPlot = ENUM.minPlot
	local maxPlot = ENUM.maxPlot
	
	local minLine = ENUM.minLine
	local maxLine = ENUM.maxLine

	local scale = plugin.width/200
	local height = plugin.width/scale
	local width = plugin.width/scale
	local infosize = {-1, (height/(200/100))*gui.scale}
	gui.SetWindowSize{ width*gui.scale, 0 }
	local time = SVstatsTime or os.clock()
	local min, max = minLine, maxLine
	local posi = gui.getWindowPos()
	local size = gui.getWindowSize()
	local tick = ((#Plot/2)*(os.clock() - time))%(#Plot + 1)
	local i = math.floor(tick)
	local major = tick - i
	
	local v1 = Line[i + 0] or 0
	local v2 = Line[i + 1] or 0
	local value = (v1 + (v2 - v1)*major)
	local t2 = (posi[2] + size[2]) - ((value - min)/(max - min))*size[2]
	--
	local v1 = Line[i + 1] or v1 or 0
	local v2 = Line[i + 2] or v2 or 0
	local value = v1 + (v2 - v1)*major
	local t1 = (posi[2] + size[2]) - ((value - min)/(max - min))*size[2]
	--
	local ImDraw = gui.GetForegroundDrawList()
	ImDraw:AddLine({posi[1], t2}, {posi[1], t1}, 0xFFFFFFFF, 3*gui.scale)
	local value = Line[1]
	local v0 = (posi[2] + size[2]) - ((value - min)/(max - min))*size[2]
	ImDraw:AddCircleFilled({posi[1], v0}, 2*gui.scale, 0xFFFFFFFF)
	
	local posi = gui.GetCursorPos()
	
	gui.PushVar("FrameBorderSize", 1)
	local maxi = math.max(-minPlot, maxPlot)
	gui.HistoPlot(Plot, -maxi, maxi, infosize, math.ceil(gui.scale), "%.4gx")
	
	gui.SetCursorPos(posi)
	gui.PushCol(7, 0x00000000)
	local maxi = math.max(-minLine, maxLine)
	gui.LinePlot(Line, -maxi, maxi, infosize, 3*gui.scale)
	gui.PullCol(1)
	
	gui.PullVar(1)
	gui.Value("Average", avgData, "%g")
	gui.Value("Minimum", minPlot, "%gx")
	gui.Value("Maximum", maxPlot, "%gx")
	gui.Close()
end
function GatherSVStatsData(ENUM)
	local Data = ENUM.Data
	local Line = {0}
	local len = #Data
	local sum = 0
	if len > 100 then
		local Dta = {}
		local i = 1
		local idx = 0
		for j = 1, len, len/100 do
			j = math.floor(j + 0.5)
			for i2 = i, j do
				sum = sum + Data[i2]
			end
			i = j
			idx = idx + 1
			Dta[idx] = Data[j]
			Line[idx] = -sum
		end
		Data = Dta
	else
		for i = 1, len do
			sum = sum + Data[i]
			Line[i + 1] = -sum
		end
	end
	
	ENUM.avgData = sum == 0 and 0 or math.round(sum/len, 8)
	ENUM.minPlot, ENUM.maxPlot = table.minmax(Data)
	ENUM.minLine, ENUM.maxLine = table.minmax(Line)
	ENUM.PlotData = Data
	ENUM.LineData = Line
	SVstatsTime = os.clock()
end

ImColor = {}

local time = os.clock()
function calcDisplacement(SCROLLS, START, CLOSE)
	local OFFSETS = {START, CLOSE}
	local total = 0
	local tbl = {}
	SCROLLS[#SCROLLS + 1] = editor.CreateScroll(OFFSETS[#OFFSETS], 0)
	local j = 1
	for i = 1, #SCROLLS - 1 do
		local this = SCROLLS[i]
		local next = SCROLLS[i + 1]
		
		while next.StartTime > OFFSETS[j] do
			local svToOffsetTime = OFFSETS[j] - this.StartTime
			local disp = total
			if svToOffsetTime > 0 then
				disp = disp + this.Multiplier*svToOffsetTime
			end
			table.insert(tbl, disp)
			j = j + 1
		end
		local diff = next.StartTime - this.StartTime
		if diff > 0 then
			total = total + diff*this.Multiplier
		end
	end
	SCROLLS[#SCROLLS] = nil
	table.insert(tbl, total)
	return tbl[2]
end
function calcDisplacement(SCROLLS, START, CLOSE)
    local total = 0

    for i = 1, #SCROLLS do
        local this = SCROLLS[i]
        local nextTime = SCROLLS[i + 1] and SCROLLS[i + 1].StartTime or CLOSE

        local from = math.max(START, this.StartTime)
        local to = math.min(CLOSE, nextTime)

        if to > from then
            total = total + (to - from) * this.Multiplier
        end
    end

    return total
end

local stx = {}
local vui = {}
local size = {sml = 0.13, lrg = 0.26}
local menu

local function listable(DATA, ACTIVE)
	ACTIVE = ACTIVE == nil and 1 or ACTIVE
	local oldmeta = getmetatable(DATA) or {}
	local meta = {}
	
	local typ = type(ACTIVE)
	if typ == "string" then
		DATA.string = ACTIVE
		DATA.number = false
	elseif typ == "number" then
		DATA.string = false
		DATA.number = ACTIVE
	end
	function meta:__newindex(INDEX, VALUE)
		rawset(self, #self + 1, INDEX)
		if typ == "string" then
			self.number = table.find(self, ACTIVE)
		elseif typ == "number" then
			self.string = self[ACTIVE]
		end
		rawset(self, INDEX, VALUE)
	end
	function meta:__index(ITEM)
		ITEM = string.lower(ITEM)
		if not(ITEM) then return end
		if ITEM == "kill" then return |self| setmetatable(self, oldmeta) end
	end
	for i, v in pairs(oldmeta) do
		if not(meta[i]) then meta[i] = v end
	end
	return setmetatable(DATA, meta)
end

function stx.nega(TBL, KYS)
	local act
	if TBL[KYS] then 
		local v = TBL[KYS]
		if v ~= 0 then
			act = true
			TBL[KYS] = -v
		end
	else
		local k, v
		for i = 1, #KYS do
			k = KYS[i]
			v = TBL[k]
			if v ~= 0 then
				act = true
				TBL[k] = -v
		end end
	end
	if act then return true end
end
function stx.rest(TBL, KYS)
	local act
	local k, v1, v2
	for i = 1, #KYS do
		k = KYS[i]
		v1 = TBL[k]
		v2 = KYS[k]
		if v1 ~= v2 then
			act = true
			TBL[k] = v2
	end end
	if act then return true end
end
function stx.step(TBL, KYS, STP, TYP)
	local act
	if TBL[KYS] then 
		local v = TBL[KYS]
		if TYP == 1 or v ~= 0 then
			v = TYP == 1 and (v + STP) or math.floor(v*STP)
			if v >= 0 then
				act = true
				TBL[KYS] = v
			end
		end
	else
		local k, v
		for i = 1, #KYS do
			k = KYS[i]
			v = TBL[k]
			if TYP == 1 or v ~= 0 then
				v = TYP == 1 and (v + STP) or math.floor(v*STP)
				if v >= 0 then
					act = true
					TBL[KYS] = v
				end
			end
		end
	end
	if act then return true end
end
function stx.swap(TBL, KYS)
	local act = false
	local kys = table.reverse(table.copy(KYS, ipairs))
	for i = 1, #KYS/2 do
		local k1, k2 = KYS[i], kys[i]
		local v1, v2 = TBL[k1], TBL[k2]
		if v1 ~= v2 then
			act = true
			TBL[k1] = v2
			TBL[k2] = v1
		end
	end
	if act then return true end
end
function stx.bool(TBL, KEY)
	TBL[KEY] = not(TBL[KEY])
	return true
end

function vui.steps(SIZE, SUB, ADD, DIV, MUL)
	if board.ctrl() then 
		local div = gui.Button("/", SIZE); gui.Sameline()
		local mul = gui.Button("x", SIZE); gui.Sameline()
		if mul or div then
			return div and DIV or mul and MUL, 2
		end
	else
		gui.PushButtonRepeat()
		local sub = gui.Button("-", SIZE); gui.Sameline()
		local add = gui.Button("+", SIZE); gui.Sameline()
		if add or sub then
			return sub and SUB or add and ADD, 1
		end
		gui.PullButtonRepeat()
	end
end
local function settingGeneral(ENUM)
	gui.Text"General"
	local active = false
	
	if active then return active end
end
local function settingGlobal(ENUM)
	-- gui.Text "Global"
	local active = false
	
	local Active = gui.Checkbox("Advanced", global.advanced)
	active = Active and (stx.bool(global, "advanced") or true) or active
	
	gui.NextItemWidth(gui.GetItemRectSize()[1])
	local Active, Output = gui.InputInt("Slider Step Size", global.step, 1, 0, 1)
	if Active then active, global.step = true, math.clamp(Output, 1, 33) end
	
	if active then return active end
end
local function settingWidgets(ENUM)
	-- gui.Text"Widgets"
	local active = false
	
	local Active, Output = gui.Checkbox("Note Info Widget", global.noteinfo or false)
	if Active then
		render("NoteInfoWidget", Output and addon.NoteInfoWidget or nil)
		active, global.noteinfo = true, Output
	end
	if active then return active end
end
local setting = listable({}, "Global")
-- setting["General"] = table.meta:call({}, settingGeneral)
setting["Global"] = table.meta:call({}, settingGlobal)
setting["Widgets"] = table.meta:call({}, settingWidgets)
setting:kill()

local ISX, ISY = 12, 4; local FR = 5; local FBS = 0
local function renderSettingLog()
	local acti, open = gui.Begin("Setting Log##Log", true, 2 + 256)
	if not(acti) then return end
	if not(open) then
		render("Setting Log", nil)
		gui.Close()
		return
	end
	local width = gui.GetWindowRegionAvailWidth()
	gui.BeginTable("SettingLog", 2, 1920)
	gui.TableSetupColumn(1, 16, width*(1/4))
	gui.TableSetupColumn(2, 16, width*(3/4))
	gui.TableNextRow()
	gui.TableNextColumn()
	
	local self = setting
	for i = 1, #self do
		if gui.Selectable(self[i], i == self.number) and not(i == self.number) then
			self.number = i
			self.string = self[i]
		end
	end
	gui.TableNextColumn()
	gui.BeginChild("SettingLog")
	
	local active = self[self.string](width*(2/3))

	gui.CloseChild()
	
	gui.CloseTable()
	
	if active then
		local read = read() or {}
		read["noteinfo"] = global.noteinfo
		read["advanced"] = global.advanced
		read["step"] = global.step
		write(read)
	end
	gui.Close()
end

local function renderChangeLog()
	local acti, open = gui.Begin("Change Log##Log", true, 256)
	if not(acti) then return end
	if not(open) then
		render("Change Log", nil)
		gui.Close()
	end
	gui.Close()
end

local function InfoTab(WIDTH)
	local bigwidth = (WIDTH - ImStyle.ItemPad[1])/2
	gui.TextFormatless(plugin.menutext)
	gui.Spacing()
	if gui.Button("Settings", {bigwidth, 0}) then
		local cord = table.div(quaver.Size, 2)
		local size = table.mul(plugin.size, 1.5)
		size[2] = size[1]*(1/2)
		cord = table.sub(cord, table.div(size, 2))
		
		gui.Begin("Setting Log##Log", false, 2 + 256)
			gui.SetWindowPos
				(cord)
			gui.SetWindowSize
				(size)
			gui.SetWindowCollapsed
				(false)
		gui.Close()
		gui.SetWindowFocus()
		render("Setting Log", renderSettingLog)
	end
	--[=[
	gui.Sameline()
	if gui.Button("Updates", {bigwidth, 0}) then
		local cord = table.div(quaver.Size, 2)
		local size = table.rep(1.25*plugin.size[1], 2)
		cord = table.sub(cord, table.div(size, 2))
		
		gui.Begin("Change Log##Log", false, 256)
			gui.SetWindowPos
				(cord)
			gui.SetWindowSize
				(size)
			gui.SetWindowCollapsed
				(false)
		gui.Close()
		gui.SetWindowFocus()
		render("Change Log", renderChangeLog)
	end
	--]=]
	gui.TextFormatless[[Version: ]]; gui.Sameline(0, 0)
	gui.TextLinkOpenURL("1.0", "https://codeberg.org/SociallyKent/ADDtHERAl/releases/tag/v1.0")
	if gui.IsItemActive() then
		global.lagControl = false -- skip next frame lagControl
	end
end
local function SelectTab(self, WIDTH)
	gui.NextItemWidth(WIDTH*(5/8))
	gui_ComboList("##Select", self)
	gui.Sameline()
	if gui.Button("Reset", {WIDTH/6, 0}) then
		self.Active = true
		local enum = def_menu["Select"]
		local self = self
		self[self.string] = setmetatable(table.copy(enum[self.string]), getmetatable(self[self.string]))
	end

	self[self.string](WIDTH, self.PushGather and chart.SelectedObjects)

	local disable = not(chart.SelectedObjects[2])
	_ = disable and gui.BeginDisabled()
	self.PushGather = gui_button("exec0", "Gather", {WIDTH*(1/2), 0})
	if disable then gui.SetItemTooltip[[Select 2 or more Notes!]] end
	_ = disable and gui.CloseDisabled()
end
local function CreateTab(self, WIDTH)
	gui.NextItemWidth(WIDTH*(5/8))
	gui_ComboList("##Create", self)
	gui.Sameline()
	if gui.Button("Reset", {WIDTH/6, 0}) then
		self.Active = true
		local enum = def_menu["Create"]
		local self = self
		enum = enum[self.string]
		self = self[self.string]

		self[self.string] = setmetatable(table.copy(enum[self.string]), getmetatable(self[self.string]))
	end
	self[self.string](WIDTH)
end
local function EditorTab(self, WIDTH)
	gui.BeginTable("Menu", 2, 0)
	gui.TableSetupColumn(1, 16, WIDTH*(5/8))
	gui.TableSetupColumn(2, 16, WIDTH*(3/8))

	gui.TableNextRow()
	gui.TableNextColumn()
	gui.NextItemWidth(-1)
	gui_ComboList("##Editor", self)
	gui.TableNextColumn()
	if gui.Button("Reset", {WIDTH/6, 0}) then
		self.Active = true
		local enum = def_menu["Editor"]
		local self = self
		if type(self[self.string]) == "table" then
			local enum = table.copy(enum[self.string])
			if self[self.string].Types then
				menu["Editor"].Types = table.copy(def_menu["Editor"].Types)
				enum.Types = menu["Editor"].Types
			end
			
			self[self.string] = setmetatable(enum, getmetatable(self[self.string]))
	end end
	
	gui.PushItemWidth(-1)
	
	gui.TableNextRow()
	gui.TableNextColumn()
	self[self.string](WIDTH*(5/8))
	
	gui.PullItemWidth()

	gui.CloseTable()
end

addon = {}
function addon.NoteInfoWidget()
	local select = chart.SelectedObjects
	if select[1] and not(select[2]) then
		select = select[1]
		local objects = editor.objects
		gui.PushVar("Alpha", 0.5)
		gui.BeginTooltip()
		gui.PullVar(1)
		gui.Spacing()
		gui.Value("StartTime", select.StartTime)
		if select.EndTime > 0 then
			gui.Value("EndTime", select.EndTime)
		end
		gui.Spacing()
		local group = select.TimingGroup
		local layer = select.EditorLayer
		if not(group:startsWith("$")) then -- not any default group
			gui.Text("Group: "..select.TimingGroup)
		end
		if layer ~= 0 then -- not Default Layer
			gui.Text("Layer: "..chart.layers[layer + 1].Name)
		end
		gui.CloseTooltip()
	end
end

local function createStandardMenu(ENUM, WIDTH)
	local Create = menu["Create"]
	local active = false
	
	if ENUM.Data then RenderSVStats(ENUM) end

	local emoticon = __emoticon[ENUM.string:lower()] or __emoticon.default
	gui.BeginDisabled()
	gui.Button(emoticon, {WIDTH/6, 0}); gui.Sameline()
	gui.CloseDisabled()
	gui.NextItemWidth(WIDTH*(5/8))
	local combo = gui_ComboList("##CreateMenu", ENUM, 8)
	if combo then
		Create.Active = true
	end

	gui.BeginTable("Menu", 2, 512)
	gui.TableSetupColumn(1, 16, WIDTH*(5/8))
	gui.TableSetupColumn(2, 16, WIDTH*(3/8))
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local Output = ENUM[ENUM.string](WIDTH*(5/8), Create.Active)
	if Output then
		ENUM.Data = Output
		GatherSVStatsData(ENUM)
	end
	Create.Active = false
	
	local final = Create.final

	gui.TableNextRow()
	gui.TableNextColumn()
	if final.string == "Custom" or final.string == "Overwrite" then
		gui.NextItemWidth(WIDTH*(5/8)*0.3)
		local Active, Output = gui.InputFloat("SV", final.Value, 0, 0, "%.2fx", 1)
		if Active then active, final.Value = true, Output end
		gui.Sameline()
	else
		gui.BeginDisabled(true)
		gui.NextItemWidth(WIDTH*(5/8)*0.3)
		gui.InputFloat("SV", final.Value, 0, 0, final.toto or "", 512)
		gui.CloseDisabled()
		gui.Sameline()
	end
	gui.Indent(WIDTH*(5/8)*0.5)
	gui.NextItemWidth(-1)
	active = gui_ComboList("##Final SV", final) or active
	gui.Undent(WIDTH*(5/8)*0.5)
	gui.TableNextColumn()
	gui.TextFormatless[[Final SV]]

	local Interlace = Create.Interlace
	gui.TableNextRow()
	gui.TableNextColumn()
	local Active, Output = gui.CheckBox("Interlace", Interlace.Bool or false)
	if Active then
		Create.Active = true
		active, Interlace.Bool = true, Output
	end
	if Output then
		gui.Sameline()
		gui.NextItemWidth(-1)
		local Active, Output = gui.Inputfloat("##Ratio", Interlace.Ratio, 0, 0, "%g", 1)
		if Active then
			Create.Active = true
			active, Interlace.Ratio = true, Output
		end
		gui.TableNextColumn()
		gui.TextFormatless[[Ratio]]
	end
	gui.CloseTable()
	
	local disable = not(chart.SelectedObjects[1])
	if disable then
		gui.BeginDisabled()
		gui.BeginGroup()
	end
	local asScroll = gui_button("exec0", "Place As Scrolls", {WIDTH*(5/8), 0})
	gui.Sameline()
	_ = gui.Button("Delete##Scrolls", {WIDTH/6, 0}) and action.Delete("Scrolls", util.getbetween(quaver.scrolls(), util.GetOffsets(chart.SelectedObjects, "StartTime")))
	local asFactor = gui_button("exec1", "Place As Factors", {WIDTH*(5/8), 0})
	gui.Sameline()
	_ = gui.Button("Delete##Factors", {WIDTH/6, 0}) and action.Delete("Factors", util.getbetween(quaver.factors(), util.GetOffsets(chart.SelectedObjects, "StartTime")))
	if disable then
		gui.CloseDisabled()
		gui.CloseGroup()
		gui.SetItemTooltip[[Select Some Notes!]]
	end
	if asScroll and not(disable) then
		global.lagControl = false -- skip next frame lagControl
		local select = chart.SelectedObjects
		local Start = utils.ToFloat(select[1].StartTime)
		local Close = utils.ToFloat(select[#select].StartTime)
		
		local Addite = {}
		local Remite = util.getbetween(quaver.scrolls(), Start, Close)
		local lin = Linear(Start, Close, #ENUM.Data + 1)
		for i = 1, #lin - 1 do
			Addite[i] = editor.CreateScroll(lin[i], ENUM.Data[i])
		end
		
		local fin = Create.final
		if fin.string == "None" then
			local RemClose = Remite[#Remite]
			if RemClose and RemClose.StartTime == Close then
				Remite[#Remite] = nil
			end
		else
			local RemClose = Remite[#Remite]
			if RemClose and RemClose.StartTime == Close then
				Remite[#Remite] = nil
			else
				local idx = #Addite + 1
				Addite[idx] = editor.CreateScroll(lin[idx], fin.Value)
			end
		end
		
		local str =  "Scrolls:"
		local tbl = {}
		if Addite[1] then
			table.insert(tbl, editor.CreateAction("AddScrollVelocityBatch", Addite))
			local AddY = #Addite - #ENUM.Data
			local AddX = #Addite - AddY
			local AddStr = AddY > 0 and AddX.." + "..AddY or AddX
			str = str.."\nAdded - "..AddStr
		end
		if Remite[1] then
			table.insert(tbl, editor.CreateAction("RemoveScrollVelocityBatch", Remite))
			str = str.."\nDeleted - "..#Remite
		end
		if tbl[1] then
			actions.PerformBatch(tbl)
			print(str)
		end
	end
	if asFactor and not(disable) then
		global.lagControl = false -- skip next frame lagControl
		local select = chart.SelectedObjects
		local Start = utils.ToFloat(select[1].StartTime)
		local Close = utils.ToFloat(select[#select].StartTime)
		
		local Addite = {}
		local Remite = util.getbetween(quaver.factors(), Start, Close)
		local lin = Linear(Start, Close, #ENUM.Data + 1)
		for i = 1, #lin - 1 do
			Addite[i] = editor.CreateFactor(lin[i], ENUM.Data[i])
		end
		
		local fin = Create.final
		if fin.string == "None" then
			local RemFinal = Remite[#Remite]
			if RemFinal and RemFinal.StartTime == Close then
				Remite[#Remite] = nil
			end
		else
			local RemFinal = Remite[#Remite]
			if RemFinal and RemFinal.StartTime == Close then
				Remite[#Remite] = nil
			else
				local idx = #Addite + 1
				Addite[idx] = editor.CreateFactor(lin[idx], fin.Value)
			end
		end
		
		local str =  "Factors:"
		local tbl = {}
		if Addite[1] then
			table.insert(Addite, 1, editor.CreateFactor(Start, 1))
			table.insert(tbl, editor.CreateAction("AddScrollSpeedFactorBatch", Addite))
			local AddY = #Addite - #ENUM.Data
			local AddX = #Addite - AddY
			local AddStr = AddY > 0 and AddX.." + "..AddY or AddX
			str = str.."\nAdded - "..AddStr
		end
		if Remite[1] then
			table.insert(tbl, editor.CreateAction("RemoveScrollSpeedFactorBatch", Remite))
			str = str.."\nDeleted - "..#Remite
		end
		if tbl[1] then
			actions.PerformBatch(tbl)
			print(str)
		end
	end
end
local function createSpecialMenu(ENUM, WIDTH)
	local active = false

	local emoticon = __emoticon[ENUM.string:lower()] or __emoticon.default
	gui.BeginDisabled()
	gui.Button(emoticon, {WIDTH/6, 0}); gui.Sameline()
	gui.CloseDisabled()
	gui.Sameline()
	
	gui.NextItemWidth(WIDTH*(5/8))
	active = gui_ComboList("##CreateMenu", ENUM, 8) or active
	
	gui.BeginTable("Menu", 2, 512)
	gui.TableSetupColumn(1, 16, WIDTH*(5/8))
	gui.TableSetupColumn(2, 16, WIDTH*(3/8))

	gui.TableNextRow()
	gui.TableNextColumn()
	local Output = ENUM[ENUM.string](WIDTH*(5/8))

	gui.CloseTable()
end
local function createVibratoMenu(ENUM, WIDTH)
	local active = false

	gui.Button(": )", {WIDTH/6, 0})
	gui.Sameline()
	gui.NextItemWidth(WIDTH*(5/8))
	active = gui_ComboList("##CreateMenu", ENUM, 8) or active
	
	gui.BeginTable("Menu", 2, 1920)
	gui.TableSetupColumn(1, 16, WIDTH*(5/8))
	gui.TableSetupColumn(2, 16, WIDTH*(3/8))

	gui.TableNextRow()
	gui.TableNextColumn()
	ENUM[ENUM.string](WIDTH)
	
	gui.CloseTable()
end

menu = listable({}, "Info")
menu["Info"] = InfoTab
menu["Select"] = table.meta:call({}, SelectTab)
menu["Create"] = table.meta:call({}, CreateTab)
menu["Editor"] = table.meta:call({}, EditorTab)
menu:kill()
--
menu["Select"].PushGather = false
local function SelectCycleMenu(ENUM, WIDTH, gather)
	gui.BeginTable("Menu", 2, 512)
	gui.TableSetupColumn(1, 16, WIDTH*(1/2))
	gui.TableSetupColumn(2, 16, WIDTH*(1/2))
	gui.TableNextRow()
	gui.TableNextColumn()
	
	WIDTH = WIDTH*(1/2)
	gui.PushItemWidth(-1)

	local Active, Output = gui.InputInt("##every", ENUM.Every, 1, 0)
	if Active then
		ENUM.Every = math.max(Output, 1)
		ENUM.After = math.min(ENUM.After, ENUM.Every)
	end
	gui.TableNextColumn()
	if ENUM.Every <= 1 then
		gui.TextFormatless[[every note]]
	else
		gui.Text([[every ]]..string.ordinal(ENUM.Every)..[[ note]])
	end
	
	gui.BeginDisabled(ENUM.Every == 1)
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local Active, Output = gui.InputInt("##after", ENUM.After, 1, 0, 1)
	if Active then ENUM.After = math.clamp(Output, 1, ENUM.Every) end
	gui.TableNextColumn()
	gui.Text([[starting from the ]]..string.ordinal(ENUM.After))
	
	gui.CloseDisabled()
	gui.PullItemWidth()
	gui.CloseTable()
	if gather then
		local unqiue = util.GetLaneObjects(gather)
		local tbl = {}
		for i = ENUM.After, math.inf, ENUM.Every do
			local v = unqiue[i]
			if not(v) then break end
			table.icombine(tbl, v)
		end
		-- print(tbl)
		actions.SetHitObjectSelection(tbl)
	end
end
local function SelectSizeMenu(ENUM, WIDTH, gather)
	local clip = WIDTH*(5/8) - ImStyle.ItemPad[1] + WIDTH/6
	for i = 1, editor.KeyCount do
		if gui.GetCursorPosX() >= (clip) then
			gui.Newline()
		end
		_, ENUM[i] = gui.Checkbox(i, ENUM[i] ~= nil and ENUM[i])
		gui.Sameline()
	end
	gui.Newline()
	if gather then
		local unique = util.GetLaneObjects(gather)
		local tbl = {}
		for i = 1, math.inf do
			local v = unique[i]
			if v == nil then break end
			local size = #v
			for i2 = 1, editor.KeyCount do
				if i2 == size then
					if ENUM[i2] then
						for i2 = 1, size do
							table.icombine(tbl, v)
					end end
					break
		end end end
		actions.SetHitObjectSelection(tbl)
	end
end
local function SelectTypeMenu(ENUM, WIDTH, gather)
	gui.BeginTable("Menu", 2, 512)
	gui.TableSetupColumn(1, 16, WIDTH*(5/8)/2)
	gui.TableSetupColumn(2, 16, WIDTH)
	
	gui.TableNextRow()
	gui.TableNextColumn()
	_, ENUM.DoRice = gui.CheckBox("Rice", ENUM.DoRice)
	gui.TableNextColumn()
	_, ENUM.DoHeld = gui.CheckBox("Held", ENUM.DoHeld)
	
	gui.TableNextRow()
	gui.TableNextColumn()
	if gui.RadioButton("Note", ENUM.DoNote) then ENUM.DoNote = not(ENUM.DoNote) end
	gui.TableNextColumn()
	if gui.RadioButton("Mine", ENUM.DoMine) then ENUM.DoMine = not(ENUM.DoMine) end
	
	gui.CloseTable()
	if gather then
		local Rice, Held = ENUM.DoRice, ENUM.DoHeld
		local Note, Mine = ENUM.DoNote, ENUM.DoMine
		local tbl = {}
		for _, v in ipairs(gather) do
			local type = (v.Type == hitobject_type.Mine and 2 or 1)
			local note = (0 < v.EndTime and 2 or 1)
			type = (Note and type == 1 or Mine and type == 2)
			note = (Rice and note == 1 or Held and note == 2)
			_ = note and type and table.insert(tbl, v)
		end
		actions.SetHitObjectSelection(tbl)
end end
listable(menu["Select"], "Cycle")
menu["Select"]["Cycle"] = table.meta:call({
	Every = 1,
	After = 1,
}, SelectCycleMenu)
-- menu["Select"]["Group / Layer"] = table.meta:call({}, || gui.Text[[Group / Layer]])
menu["Select"]["Chord Size"] = table.meta:call({
	Size = 1,
}, SelectSizeMenu)
menu["Select"]["Type"] = table.meta:call({
	DoHeld = false,
	DoRice = true,
	DoNote = true,
	DoMine = false,
}, SelectTypeMenu)
menu["Select"]:kill()

listable(menu["Create"], "Standard")
menu["Create"]["Standard"] = table.meta:call({}, createStandardMenu)
menu["Create"]["Special"] = table.meta:call({}, createSpecialMenu)
-- menu["Create"]["Vibrato"] = table.meta:call({}, createVibratoMenu)
menu["Create"]:kill()

menu["Create"].Interlace = {Ratio = -0.5, Bool = false}

menu["Create"].final = listable({Value = 1}, "Custom")
-- menu["Create"].final["Normal"] = nil
menu["Create"].final["None"] = nil
menu["Create"].final["Custom"] = nil
-- menu["Create"].final["Overwrite"] = nil
menu["Create"].final:kill()
function calcDisplacement(TABLE, TIMES)
	local dist = 0
	for i = 1, #TABLE - 1 do
		local this = TABLE[i + 0]
		local next = TABLE[i + 1]
		local offset = TIMES[i + 1] - TIMES[i]
		dist = dist + this*(offset)
	end
	return dist
end
function calcDisplacementSV(time, displacement, duration)
    local Mult = 1/duration
	local current = (quaver.GetScrollAt(time) or {Multiplier = 1}).Multiplier
    return current + Mult*displacement
end

function calcChinchilla(ENUM) end
function calcCircular(ENUM)
	local Cnt = ENUM.Count
	local Arc = ENUM.ArcPercent
	Arc = math.pi*Arc/100
	if global.advanced then
		local Type = ENUM.Type.string
		if Type == "Start / End" then
			local Str, End = ENUM.Start, ENUM.End
			local SlowDown = ENUM.Behavior.string == "Slow Down"
			if SlowDown then Str, End = End, Str end
			local data = seCircular(Str, End, Arc, Cnt)
			return SlowDown and table.reverse(data) or data
		end
	end
	local Avg = ENUM.Average
	local Shift = ENUM.Shift
	Avg = Avg - Shift
	local t = Linear(0, Arc, Cnt + 1)
	local y = Circular(Avg, Cnt + 1, t)
	
	local data = {}
	local sum = (y[1] - y[Cnt + 1])*(Cnt)
	local scale = Avg*Cnt/sum
	for i = 1, Cnt do
		local sv = (y[i] - y[i + 1])*(Cnt)
		data[i] = sv*scale + Shift
	end

	if ENUM.Behavior.string == "Speed Up" then
		data = table.reverse(data)
	end
	
	return data
end
function calcExponential(ENUM)
	local Cnt = ENUM.Count
	local Int = ENUM.Intensity/5
	
	if global.advanced then
		local Type = ENUM.Type.string
		if Type == "Start / End" then
			local Str, End = ENUM.Start, ENUM.End
			local SlowDown = ENUM.Behavior.string == "Slow Down"
			if SlowDown then Str, End = End, Str end
			local data = seExponential(Str, End, Int, Cnt)
			return SlowDown and table.reverse(data) or data
		end
	end
	local Shift = ENUM.Shift
	local Avg = ENUM.Average
	local data = {}
	Avg = Avg - Shift
	local t = Linear(0, 1, Cnt + 1)
	local y = Exponential(Avg, Int, Cnt + 1, t)
	
	local sum = (y[1] - y[Cnt + 1])*(Cnt)
	local scale = Avg*Cnt/sum
	for i = 1, Cnt do
		local sv = (y[i] - y[i + 1])*(Cnt)
		data[i] = sv*scale + Shift
	end
	if ENUM.Behavior.string == "Slow Down" then
		data = table.reverse(data)
	end
	return data
end
function calcHermite(ENUM)
	local Str, End, Avg, Cnt = ENUM.Start, ENUM.End, ENUM.Average, ENUM.Count
	Avg = Avg - ENUM.Shift
	
	local t = Linear(0, 1, Cnt + 1)
	local y = Hermite(Str, End, Avg, Cnt + 1, t)
	
	local data = {}
	for i = 1, Cnt do
		local sv = (y[i + 1] - y[i])*(Cnt)
		data[i] = sv + ENUM.Shift
	end
	
	return data
end
function calcLinear(ENUM)
	if global.advanced then
		local Type = ENUM.Type.string
		if Type == "Start / Average" then
			local STR, AVG = ENUM.Start, ENUM.Average
			return Linear(STR, 2*AVG - STR, ENUM.Count)
		elseif Type == "End / Average" then
			local END, AVG = ENUM.End, ENUM.Average
			return Linear(2*AVG - END, END, ENUM.Count)
		end
	end
	local STR, END, CNT = ENUM.Start, ENUM.End, ENUM.Count
	return Linear(STR, END, CNT)
end

function calcInterlace(ENUM, TABLE)
	local Behavior = ENUM.Behavior
	local Type = ENUM.Type
	
	local Start
	if Behavior and Behavior.string:has("Speed") then
		Start = 1
	else
		Start = 2
	end
	Interlace(TABLE, menu["Create"].Interlace.Ratio, Start)
	if Type and Type.string:has("Average") then
		table.normalize(TABLE)
	end
	return TABLE
end

function seCircular(STR, FIN, ARC, CNT)
	local cos, sqrt = math.cos, math.sqrt
    local data = {}
    local k = (FIN - STR)/sqrt(1 - cos(ARC)^2)

    for i = 0, CNT - 1 do
        local x = i / (CNT - 1)
        data[i + 1] = STR + k*sqrt(1 - cos(ARC*x)^2)
    end

    return data
end
function Circular(AVG, CNT, TBL)
	local cata = {}
	for i = 1, CNT do
		cata[i] = -AVG*(1 - math.cos(TBL[i])^2)^0.5
	end
	return cata
end
function seExponential(STR, FIN, INT, CNT)
	local data = {}
	local k = (FIN - STR)/(math.exp(INT) - 1)
	for i = 0, CNT - 1 do
		local x = i/(CNT - 1)
		data[i + 1] = k*math.exp(INT*x) + STR - k
	end
	return data
end
function Exponential(AVG, INT, CNT, TBL)
	local cata = {}
	for i = 1, CNT do
		cata[i] = -AVG*(1 - math.exp(i*INT/CNT))
	end
	return cata
end
function Hermite(STR, FIN, AVG, CNT, TBL)
	local data = {}
	for i = 1, CNT do
		data[i] = math.hermite(STR, FIN, AVG, TBL[i])
	end
	return data
end
function Linear(STR, FIN, CNT)
	if CNT < 2 then return CNT == 1 and {STR} or {} end
	local data = {}
	local step = (FIN - STR)/(CNT - 1)
	for i = 0, CNT - 1 do
		data[i + 1] = STR + i*step
	end
	return data
end

function Interlace(TABLE, RATIO, START)
	for i = START or 2, #TABLE, 2 do
		TABLE[i] = TABLE[i]*RATIO
	end
	return TABLE
end

--[[ Menu Create ]]
local function CreateStandardBezier(ENUM, WIDTH, active)
	gui.PushItemWidth(-1)
	
	local nega = gui.Button("Neg.", {WIDTH*size.lrg, 0}); gui.Sameline()
	active = nega and stx.nega(ENUM, "Average") or active
	local Active, Output = gui.InputFloat("##Average", ENUM.Average, 0, 0, "%.2f", 1)
	gui.TableNextColumn()
	gui.TextFormatless[[SV Average]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local rest = gui.Button("R", {WIDTH*size.sml, 0}); gui.Sameline()
	local nega = gui.Button("N", {WIDTH*size.sml, 0}); gui.Sameline()
	active = rest and stx.rest(ENUM, {"Shift", Shift = 0}) or active
	active = nega and stx.nega(ENUM, "Shift") or active
	local Active, Output = gui.InputFloat("##Shift", ENUM.Shift, 0, 0, "%.2fx", 1)
	if Active then active, ENUM.Shift = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Shift]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local step, type = vui.steps({WIDTH*size.sml, 0}, -1, 1, 0.5, 2)
	active = step and stx.step(ENUM, "Count", step, type) or active
	local Active, Output = gui.InputInt("##Count", ENUM.Count or 16, 0, 0, 1)
	if Active then active, ENUM.Count = true, math.max(1, Output) end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Points]]
	
	gui.PullItemWidth()
	if active then print("Bezier") end
end
local function CreateStandardChinchilla(ENUM, WIDTH, active)
	local Behavior = ENUM.Behavior
	local Type = ENUM.Type
	gui.PushItemWidth(-1)
	
	local swap = gui_button("swap0", "Swap", {WIDTH*size.lrg, 0}); gui.Sameline()
	if swap then; active = true
		Behavior.number = Behavior.number == 1 and 2 or 1
		Behavior.string = Behavior[Behavior.number]
	end
	active = gui_ComboList("##Behavior", Behavior) or active
	gui.TableNextColumn()
	gui.TextFormatless[[Behavior]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	active = gui_ComboList("##Type", Type) or active
	-- gui.TableNextColumn()
	-- gui.TextFormatless[[Type]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local Output = gui.SliderScale("##Intensity", ENUM.Intensity, global.step*0.1, 0, 10, 2)
	if Output then active, ENUM.Intensity = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[Intensity]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local nega = gui.Button("Neg.", {WIDTH*size.lrg, 0}); gui.Sameline()
	active = nega and stx.nega(ENUM, "Average") or active
	local Active, Output = gui.InputFloat("##Average", ENUM.Average, 0, 0, "%.2f", 1)
	if Active then active, ENUM.Average = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Average]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local rest = gui.Button("R", {WIDTH*size.sml, 0}); gui.Sameline()
	local nega = gui.Button("N", {WIDTH*size.sml, 0}); gui.Sameline()
	active = rest and stx.rest(ENUM, {"Shift", Shift = 0}) or active
	active = nega and stx.nega(ENUM, "Shift") or active
	local Active, Output = gui.InputFloat("##Shift", ENUM.Shift, 0, 0, "%.2fx", 1)
	if Active then active, ENUM.Shift = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Shift]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local step, type = vui.steps({WIDTH*size.sml, 0}, -1, 1, 0.5, 2)
	active = step and stx.step(ENUM, "Count", step, type) or active
	local Active, Output = gui.InputInt("##Count", ENUM.Count or 16, 0, 0, 1)
	if Active then active, ENUM.Count = true, math.max(1, Output) end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Points]]
	
	gui.PullitemWidth()
	return active and (calcChinchilla(ENUM) or nil)
end
local function CreateStandardCircular(ENUM, WIDTH, active)
	local Behavior = ENUM.Behavior
	local Type = ENUM.Type
	gui.PushItemWidth(-1)
	
	local swap = gui_button("swap0", "Swap", {WIDTH*size.lrg, 0}); gui.Sameline()
	if swap then; active = true
		Behavior.number = Behavior.number == 1 and 2 or 1
		Behavior.string = Behavior[Behavior.number]
	end
	gui_ComboList("##Behavior", Behavior)
	gui.TableNextColumn()
	gui.TextFormatless[[Behavior]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local step = global.step
	local Output = gui.SliderScale("##ArcPercent", ENUM.ArcPercent, step, 0 + step, 100 - step, 0)
	if Output then active, ENUM.ArcPercent = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[% Arc]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	if global.advanced then
		active = gui_ComboList("##Type", Type) or active
		-- gui.TableNextColumn()
		-- gui.TextFormatless[[Type]]
		
		gui.TableNextRow()
		gui.TableNextColumn()
		active = Type[Type.string](ENUM, WIDTH) or active
	else
		active = Type["Average / Shift"](ENUM, WIDTH) or active
	end
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local step, type = vui.steps({WIDTH*size.sml, 0}, -1, 1, 0.5, 2)
	active = step and stx.step(ENUM, "Count", step, type) or active
	local Active, Output = gui.InputInt("##Count", ENUM.Count or 16, 0, 0, 1)
	if Active or step then active, ENUM.Count = Output >= 1, math.max(1, Output) end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Points]]
	
	gui.PullItemWidth()
	if active then
		local data = calcCircular(ENUM)
		local lace = menu["Create"].Interlace
		if lace.Bool then
			Interlace(data, lace.Ratio, Behavior.string == "Speed Up" and 1)
			if Type.string:has("Average") then
				table.normalize(data, ENUM.Average)
		end end
		return data
	end
end
local function CreateStandardExponential(ENUM, WIDTH, active)
	local Behavior = ENUM.Behavior
	local Type = ENUM.Type
	gui.PushItemWidth(-1)
	
	local swap = gui_button("swap0", "Swap", {WIDTH*size.lrg, 0}); gui.Sameline()
	if swap then; active = true
		Behavior.number = Behavior.number == 1 and 2 or 1
		Behavior.string = Behavior[Behavior.number]
	end
	active = gui_ComboList("##Behavior", Behavior) or active
	gui.TableNextColumn()
	gui.TextFormatless[[Behavior]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local step = global.step
	local Output = gui.SliderScale("##Intensity", ENUM.Intensity, 5, 0 + step, 100 - step, 2)
	if Output then active, ENUM.Intensity = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[% Intensity]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	if global.advanced then
		active = gui_ComboList("##Type", Type) or active
		-- gui.TableNextColumn()
		-- gui.TextFormatless[[Type]]
		
		gui.TableNextRow()
		gui.TableNextColumn()
		active = Type[Type.string](ENUM, WIDTH) or active
	else
		active = Type["Average / Shift"](ENUM, WIDTH) or active
	end
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local step, type = vui.steps({WIDTH*size.sml, 0}, -1, 1, 0.5, 2)
	active = step and stx.step(ENUM, "Count", step, type) or active
	local Active, Output = gui.InputInt("##Count", ENUM.Count or 16, 0, 0, 1)
	if Active or step then active, ENUM.Count = Output >= 1, math.max(1, Output) end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Points]]
	
	gui.PullItemWidth()
	if active then
		local data = calcExponential(ENUM)
		local lace = menu["Create"].Interlace
		if lace.Bool then
			Interlace(data, lace.Ratio, Behavior.string == "Speed Up" and 1)
			if Type.string:has("Average") then
				table.normalize(data, ENUM.Average)
		end end
		return data
	end
end
local function CreateStandardHermite(ENUM, WIDTH, active)
	gui.PushItemWidth(-1)
	
	local swap = gui_button("swap0", "S", {WIDTH*size.sml, 0}); gui.Sameline()
	local nega = gui_button("nega0", "N", {WIDTH*size.sml, 0}); gui.Sameline()
	active = swap and stx.swap(ENUM, {"Start", "End"}) or active
	active = nega and stx.nega(ENUM, {"Start", "End"}) or active
	local Active, Output = gui.InputFloat2("##Start / End", {ENUM.Start, ENUM.End}, "%.2fx", 1)
	if Active then active, ENUM.Start, ENUM.End = true, Output[1], Output[2] end
	gui.TableNextColumn()
	gui.TextFormatless[[Start / End]]

	gui.TableNextRow()
	gui.TableNextColumn()
	local nega = gui_button("nega0", "Neg.", {WIDTH*size.lrg, 0}); gui.Sameline()
	active = nega and stx.nega(ENUM, "Average") or active
	gui.Dummy({0, 0}); gui.Sameline()--gui.Sameline(0, ImStyle.ItemPad[1]*2)
	local Active, Output = gui.InputFloat("##Average", ENUM.Average, 0, 0, "%.2f", 1)
	if Active then active, ENUM.Average = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Average]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local rest = gui_button("rest1", "R##1", {WIDTH*size.sml, 0}); gui.Sameline()
	local nega = gui_button("nega1", "N##1", {WIDTH*size.sml, 0}); gui.Sameline()
	active = rest and stx.rest(ENUM, {"Shift", Shift = 0}) or active
	active = nega and stx.nega(ENUM, "Shift") or active
	local Active, Output = gui.InputFloat("##Shift", ENUM.Shift, 0, 0, "%.2fx", 1)
	if Active then active, ENUM.Shift = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Shift]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local step, type = vui.steps({WIDTH*size.sml, 0}, -1, 1, 0.5, 2)
	active = step and stx.step(ENUM, "Count", step, type) or active
	local Active, Output = gui.InputInt("##Count", ENUM.Count or 16, 0, 0, 1)
	if Active or step then active, ENUM.Count = Output >= 1, math.max(1, Output) end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Points]]
	
	gui.PullItemWidth()
	if active then
		local data = calcHermite(ENUM)
		local lace = menu["Create"].Interlace
		if lace.Bool then Interlace(data, lace.Ratio) end
		return data
	end
end
local function CreateStandardLinear(ENUM, WIDTH, active)
	local Type = ENUM.Type
	gui.PushItemWidth(-1)

	if global.advanced then
		active = gui_ComboList("##Type", Type) or active
		-- gui.TableNextColumn()
		-- gui.TextFormatless[[Type]]
		
		gui.TableNextRow()
		gui.TableNextColumn()
		active = Type[Type.string](ENUM, WIDTH) or active
	else
		active = Type["Start / End"](ENUM, WIDTH) or active
	end
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local step, type = vui.steps({WIDTH*size.sml, 0}, -1, 1, 0.5, 2)
	active = step and stx.step(ENUM, "Count", step, type) or active
	local Active, Output = gui.InputInt("##Count", ENUM.Count or 16, 0, 0, 1)
	if Active or step then active, ENUM.Count = Output > 0, math.max(1, Output) end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Points]]
	
	gui.PullItemWidth()
	if active and ENUM.Count > 0 then
		local data = calcLinear(ENUM)
		local lace = menu["Create"].Interlace
		if lace.Bool then
			Interlace(data, lace.Ratio)
			if Type.string:has("Average") then
				table.normalize(data, ENUM.Average)
		end end
		return data
	end
end
local function CreateStandardSinusoidal(ENUM, WIDTH, active)
	gui.PushItemWidth(-1)

	local swap = gui.Button("S", {WIDTH*size.sml, 0}); gui.Sameline()
	local nega = gui.Button("N##S/E", {WIDTH*size.sml, 0}); gui.Sameline()
	active = swap and stx.swap(ENUM, {"Start", "End"}) or active
	active = nega and stx.nega(ENUM, {"Start", "End"}) or active
	gui.InputFloat2("##Start / End", {ENUM.Start, ENUM.End}, "%.2fx", 1)-- needs an input
	gui.TableNextColumn()
	gui.TextFormatless[[Start / End]]

	gui.TableNextRow()
	gui.TableNextColumn()
	local rest = gui.Button("Reset", {WIDTH*(size.sml*2) + ImStyle.ItemPad[1], 0}); gui.Sameline()
	active = rest and stx.rest(ENUM, {"Sharpness", Sharpness = 50}) or active
	local Output = gui.SliderScale("##Sharpness", ENUM.Sharpness, 5, 0, 100, 0)
	if Output then ENUM.Sharpness = Output end
	gui.TableNextColumn()
	gui.TextFormatless[[% Sharpness]]

	gui.TableNextRow()
	gui.TableNextColumn()
	local rest = gui.Button("R", {WIDTH*size.sml, 0}); gui.Sameline()
	local nega = gui.Button("N##Shift", {WIDTH*size.sml, 0}); gui.Sameline()
	active = rest and stx.rest(ENUM, {"Shift", Shift = 1}) or active
	active = nega and stx.nega(ENUM, "Shift") or active
	local Active, Output gui.InputFloat("##Shift", ENUM.Shift, 0, 0, "%.2fx", 1)
	if Active then active, ENUM.Shift = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Shift]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local Active, Output = gui.InputFloat("##Cycles", ENUM.Cycles, 0.25, 0.05, "%.2f", 1)
	if Active then active, ENUM.Cycles = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[Phase Cycle]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local Active, Output = gui.InputFloat("##PhaseOffset", ENUM.PhaseOffset, 0.25, 0.05, "%.2f", 1)
	if Active then active, ENUM.PhaseOffset = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[Phase Shift]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local step, type = vui.steps({WIDTH*size.sml, 0}, -1, 1, 0.5, 2)
	active = step and stx.step(ENUM, "Count", step, type) or active
	local Active, Output = gui.InputInt("##Count", ENUM.Count or 16, 0, 0, 1)
	if Active or step then active, ENUM.Count = Output >= 1, math.max(1, Output) end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Points]]
	
	gui.PullItemWidth()
end
local function CreateStandardRandom(ENUM, WIDTH, active)
	local Type = ENUM.Type
	gui.PushItemWidth(-1)
	
	active = gui_ComboList("##Type", Type) or active
	-- gui.TableNextColumn()
	-- gui.TextFormatless[[Type]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local Active, Output = gui.InputFloat("##Scale", ENUM.Scale, 1, 0.25, "%.2f", 1)
	if Active then active, ENUM.Scale = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[Scale]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local step, type = vui.steps({WIDTH*size.sml, 0}, -1, 1, 0.5, 2); gui.Sameline()
	active = step and stx.step(ENUM, "Count", step, type) or active
	local Active, Output = gui.InputInt("##Count", ENUM.Count or 16, 0, 0, 1)
	if Active then active, ENUM.Count = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Points]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	gui.Button([[Create New Random]], {-1, 0})-- needs an actived
	
	gui.TableNextRow()
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local nega = gui.Button("Neg.", {WIDTH*size.lrg, 0}); gui.Sameline()
	active = nega and stx.nega(ENUM, "Average") or active
	local Active, Output = gui.InputFloat("##Average", ENUM.Average, 0, 0, "%.2f", 1)
	if Active then active, ENUM.Average = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Average]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local rest = gui.Button("R", {WIDTH*size.sml, 0}); gui.Sameline()
	local nega = gui.Button("N", {WIDTH*size.sml, 0}); gui.Sameline()
	active = rest and stx.rest(ENUM, {"Shift", Shift = 0}) or active
	active = nega and stx.nega(ENUM, "Shift") or active
	local Active, Output = gui.InputFloat("##Shift", ENUM.Shift, 0, 0, "%.2fx", 1)
	if Active then active, ENUM.Shift = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Shift]]
	
	gui.PullItemWidth()
	
	gui.TableNextRow()
	gui.TableNextColumn()
	gui.Checkbox("Normalize SV Average", ENUM.Normalize)
end
local function CreateStandardManual(ENUM, WIDTH, active)
end
local behavior = listable({}, "Slow Down")
behavior["Slow Down"] = nil
behavior["Speed Up"] = nil
behavior:kill()

listable(menu["Create"]["Standard"], "Linear")
--[=[menu["Create"]["Standard"]["Bezier"] = table.meta:call({
	-- Average = 1,
	-- Count = 16,
	-- Shift = 0,
}, CreateStandardBezier)]=]
--[=[menu["Create"]["Standard"]["Chinchilla"] = table.meta:call({
	Behavior = table.copy(behavior),
	Type = listable({}, "Exponential"),
	Average = 1,
	Count = 16,
	Intensity = 0.5,
	Shift = 0,
}, CreateStandardChinchilla)]=]
menu["Create"]["Standard"]["Circular"] = table.meta:call({
	Behavior = table.copy(behavior),
	Type = listable({}, "Average / Shift"),
	ArcPercent = 50,
	Average = 1,
	Count = 16,
	End = 0.5,
	Shift = 0,
	Start = 1.5,
}, CreateStandardCircular)
--menu["Create"]["Standard"]["Combo"] = table.meta:call({}, || "Combo")
menu["Create"]["Standard"]["Exponential"] = table.meta:call({
	Behavior = table.copy(behavior),
	Type = listable({}, "Average / Shift"),
	Average = 1,
	Count = 16,
	Distance = 100,
	End = 0.5,
	Intensity = 20,
	Shift = 0,
	Start = 1.5,
}, CreateStandardExponential)
menu["Create"]["Standard"]["Hermite"] = table.meta:call({
	Average = 1,
	Count = 16,
	End = 0,
	Shift = 0,
	Start = 0,
}, CreateStandardHermite)
menu["Create"]["Standard"]["Linear"] = table.meta:call({
	Type = listable({}, "Start / End"),
	Average = 0,
	Count = 16,
	End = 0.5,
	Start = 1.5,
}, CreateStandardLinear)
--[=[menu["Create"]["Standard"]["Sinusoidal"] = table.meta:call({
	Count = 8,
	Cycles = 1,
	End = 2,
	Shift = 1,
	PhaseOffset = 0.25,
	Sharpness = 50,
	Start = 2,
}, CreateStandardSinusoidal) ]=]
--[=[menu["Create"]["Standard"]["Random"] = table.meta:call({
	Type = listable({}, "Normal"),
	Average = 1,
	Count = 16,
	Normalize = true,
	Shift = 0,
	Scale = 2,
}, CreateStandardRandom)]=]
--[=[menu["Create"]["Standard"]["Manual"] = table.meta:call({
	Code = [[]],
	Count = 64,
}, CreateStandardManual)]=]
menu["Create"]["Standard"]:kill()

--[[local chinchilla = menu["Create"]["Standard"]["Chinchilla"]
chinchilla.Type["Arc Sine Power"] = nil
chinchilla.Type["Circular"] = nil
chinchilla.Type["Exponential"] = nil
chinchilla.Type["Inverse Power"] = nil
chinchilla.Type["Peter Stock"] = nil
chinchilla.Type["Polynormial"] = nil
chinchilla.Type["Sine Power"] = nil
chinchilla.Type:kill()
]]

local circular = menu["Create"]["Standard"]["Circular"]
circular.Type["Average / Shift"] = function(ENUM, WIDTH)
	local active = false
	
	local nega = gui_button("nega0", "Neg.", {WIDTH*size.lrg, 0}); gui.Sameline()
	active = nega and stx.nega(ENUM, "Average") or active
	gui.Dummy({0, 0}); gui.Sameline()--gui.Sameline(0, ImStyle.ItemPad[1]*2)
	local Active, Output = gui.InputFloat("##Average", ENUM.Average, 0, 0, "%.2f", 1)
	if Active then active, ENUM.Average = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Average]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local rest = gui_button("rest1", "R", {WIDTH*size.sml, 0}); gui.Sameline()
	local nega = gui_button("nega1", "N", {WIDTH*size.sml, 0}); gui.Sameline()
	active = rest and stx.rest(ENUM, {"Shift", Shift = 0}) or active
	active = nega and stx.nega(ENUM, "Shift") or active
	local Active, Output = gui.InputFloat("##Shift", ENUM.Shift, 0, 0, "%.2fx", 1)
	if Active then active, ENUM.Shift = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Shift]]

	if active then return true end
end
circular.Type["Start / End"] = function(ENUM, WIDTH)
	local active
	
	local swap = gui_button("swap0", "S", {WIDTH*size.sml, 0}); gui.Sameline()
	local nega = gui_button("nega0", "N", {WIDTH*size.sml, 0}); gui.Sameline()
	active = swap and stx.swap(ENUM, {"Start", "End"}) or active
	active = nega and stx.nega(ENUM, {"Start", "End"}) or active
	local Active, Output = gui.InputFloat2("##Start / End", {ENUM.Start, ENUM.End}, "%.2fx", 1)
	if Active then active, ENUM.Start, ENUM.End = true, Output[1], Output[2] end
	gui.TableNextColumn()
	gui.TextFormatless[[Start / End]]

	if active then return true end
end

--[[local combo = menu["Create"]["Standard"]["Combo"]
awaken(function()
	combo.Standard = table.clone(menu["Create"]["Standard"])
end)
--]]

local exponential = menu["Create"]["Standard"]["Exponential"]
exponential.Type["Average / Shift"] = circular.Type["Average / Shift"]
exponential.Type["Start / End"] = circular.Type["Start / End"]
exponential.Type:kill()

local linear = menu["Create"]["Standard"]["Linear"]
linear.Type["Start / End"] = circular.Type["Start / End"]
linear.Type["Start / Average"] = function(ENUM, WIDTH)
	local active = false

	local nega = gui_button("nega0", "Neg.##Start", {WIDTH*size.lrg, 0}); gui.Sameline()
	active = nega and stx.nega(ENUM, "Start") or active
	local Active, Output = gui.InputFloat("##Start", ENUM.Start, 0, 0, "%.2fx", 1)
	if Active then active, ENUM.Start = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[Start]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local nega = gui_button("nega0", "Neg.##Average", {WIDTH*size.lrg, 0}); gui.Sameline()
	active = nega and stx.nega(ENUM, "Average") or active
	local Active, Output = gui.InputFloat("##Average", ENUM.Average, 0, 0, "%.2fx", 1)
	if Active then active, ENUM.Average = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Average]]
	
	if active then return true end
end
linear.Type["End / Average"] = function(ENUM, WIDTH)
	local active = false
	
	local nega = gui_button("nega0", "Neg.##End", {WIDTH*size.lrg, 0}); gui.Sameline()
	active = nega and stx.nega(ENUM, "End") or active
	local Active, Output = gui.InputFloat("##Start", ENUM.End, 0, 0, "%.2fx", 1)
	if Active then active, ENUM.End = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[End]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local nega = gui_button("nega0", "Neg.##Average", {WIDTH*size.lrg, 0}); gui.Sameline()
	active = nega and stx.nega(ENUM, "Average") or active
	local Active, Output = gui.InputFloat("##Average", ENUM.Average, 0, 0, "%.2fx", 1)
	if Active then active, ENUM.Average = true, Output end
	gui.TableNextColumn()
	gui.TextFormatless[[SV Average]]
	
	if active then return true end
end
linear.Type:kill()

local Sinusoidal
--[[
local random = menu["Create"]["Standard"]["Random"]
random.Type["Normal"] = nil
random.Type["Uniform"] = nil
random.Type:kill()
]]


local function CreateSpecialTeleport(ENUM, WIDTH)
	gui.PushItemWidth(-1)
	local halfwidth = {WIDTH/2 - ImStyle.ItemPad[1]/2, 0}
	
	local nega = gui_button("nega0", "Neg.", {WIDTH*size.lrg, 0}); gui.Sameline()
	_ = nega and stx.nega(ENUM, "Distance")
	_, ENUM.Distance = gui.InputFloat("##Distance", ENUM.Distance, 1, 0, "%gx", "CharsNoBlank")
	gui.TableNextColumn()
	gui.TextFormatless[[Distance]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local disable = not(chart.SelectedObjects[1])
	_ = disable and gui.BeginDisabled()
	local place = gui_button("exec0", [[Place]], halfwidth); gui.Sameline()
	if disable then
		gui.CloseDisabled()
		gui.SetItemToolTip[[Select 1 or more Notes!]]
	end
	_, ENUM.After = gui.CheckBox("Place After", ENUM.After)
	if place and not(disable) then
		global.lagControl = false -- skip next frame lagControl
		local select = chart.SelectedObjects[1].StartTime
		local speed = ENUM.Distance
		local mini = ENUM.After and 0 or 0.1
		local maxi = ENUM.After and 0.1 or 0
		local Mini = utils.ToFloat(select - mini)
		local Maxi = utils.ToFloat(select + maxi)
		local scrolls = quaver.scrolls()
		local torem, i, j = util.getbetween(scrolls, Mini, Maxi)
		if j == 0 then
			i = 0
		elseif i > j then
			i, j = j, i
		end
		local sped = scrolls[i] and scrolls[i].Multiplier or 1
		local s1, s2
		
		local ea = {}
		local speed = ENUM.Distance
		if ENUM.After then
			speed = ENUM.Distance
			-- s1 = editor.CreateScroll(Mini, speed)
		elseif scrolls[i] then
			speed = ENUM.Distance
			-- if torem[1].Multiplier%ENUM.Distance == 0 then
				-- speed = torem[1].Multiplier + ENUM.Distance
			-- else
				-- speed = ENUM.Distance
			-- end
			
		end
		if torem[1] and torem[1].Multiplier%speed == 0 then
			speed = torem[1].Multiplier + speed
		else
			speed = speed
		end
		s1 = editor.CreateScroll(Mini, speed)
		print("removing", torem)
		if torem[#torem] and torem[#torem].StartTime == Maxi then
			print("remoed last", torem[#torem].Multiplier)
			torem[#torem] = nil
		else
			s2 = editor.CreateScroll(Maxi, sped)
		end
		_ = table.insert(ea, editor.CreateAction("AddScrollVelocityBatch", {s1, s2}))
		_ = torem[1] and table.insert(ea, editor.CreateAction("RemoveScrollVelocityBatch", torem))
		actions.PerformBatch(ea)
	end
	gui.PullItemWidth()
end
listable(menu["Create"]["Special"], "Teleport")
-- menu["Create"]["Special"]["Flicker"] = table.meta:call({}, || nil)
-- menu["Create"]["Special"]["Stutter"] = table.meta:call({}, || nil)
-- menu["Create"]["Special"]["Teleport Stutter"] = table.meta:call({}, || nil)
menu["Create"]["Special"]["Teleport"] = table.meta:call({
	Distance = 9600,
	After = false,
}, CreateSpecialTeleport)
--[[
listable(menu["Create"]["Vibrato"], "Linear", false, "enum")
menu["Create"]["Vibrato"]["Exponential"] = table.meta:call({}, || nil)
menu["Create"]["Vibrato"]["Linear"] = table.meta:call({}, || nil)
menu["Create"]["Vibrato"]["Polynomial"] = table.meta:call({}, || nil)
menu["Create"]["Vibrato"]["Sigmoidal"] = table.meta:call({}, || nil)
menu["Create"]["Vibrato"]["Sinusoidal"] = table.meta:call({}, || nil)
menu["Create"]["Vibrato"]["Manual"] = table.meta:call({}, || nil)
menu["Create"].Active = true
]]
local template = [[
return function(DATA, ENCODER)
	return function(lower, upper)
		local tbl = {}
		local I = toolbox.SearchLower(DATA, lower, "StartTime")
		local J = toolbox.SearchLower(DATA, upper, "StartTime")
		for i2 = I, J do
			local v = DATA[i2]
			tbl[i2 - I + 1] = {@Data}
		end
		if tbl[#tbl].StartTime == upper - lower then
			tbl[#tbl] = nil
		end
		return ENCODER(tbl)
	end
end
]]
local function create0(DATA, ENCODER, KEYS)
	if not(DATA[1]) then return end
	for i = 1, #KEYS do
		if KEYS[i]:has("Time") then
			KEYS[i] = KEYS[i].."=v."..KEYS[i].."- lower"
		else
			KEYS[i] = KEYS[i].."=v."..KEYS[i]
		end
	end
	local func = eval(template:gsub("@(%w+)", {
		Data = table.concat(KEYS, ","),
	}))
	return func(DATA, ENCODER)
end
--[[ Menu Editor ]]
local function editorScaleDispMenu(ENUM, WIDTH)
	local Behavior = ENUM.Behavior
	local Type = ENUM.Type
	gui.PushItemWidth(-1)
	local halfwidth = {WIDTH/2 - ImStyle.ItemPad[1]/2, 0}
	
	local swap = gui_button("swap0", "Swap", {WIDTH*size.lrg, 0}); gui.Sameline()
	if swap then; active = true
		Behavior.number = Behavior.number == 1 and 2 or 1
		Behavior.string = Behavior[Behavior.number]
	end
	gui_ComboList("##Behavior", Behavior)
	gui.TableNextColumn()
	gui.TextFormatless[[Displace From]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	
	local nega = gui_button("nega0", "Neg.", {WIDTH*size.lrg, 0}); gui.Sameline()
	_ = nega and stx.nega(ENUM, "Average")
	_, ENUM.Average = gui.InputFloat("##SV Average", ENUM.Average, 0, 0, "%.2f", 1)
	gui.TableNextColumn()
	gui.TextFormatless[[SV Average]]
	
	gui.TableNextRow()
	gui.TableNextColumn()
	local disable = not(chart.SelectedObjects[2])
	if disable then
		gui.BeginGroup()
		gui.BeginDisabled()
	end
	local displace = gui_button("exec0", "displace", halfwidth)
	gui.Sameline()
	gui.ButtonDisabled("", halfwidth)
	if disable then
		gui.CloseDisabled()
		gui.CloseGroup()
		gui.SetItemToolTip[[Select 2 or more Notes!]]
	end
	
	if displace and not(disable) then
		local addite = {}
		local qscrolls = quaver.scrolls()
		local select = chart.SelectedObjects
		local unique = table.unique(table.gather(select, "StartTime"))
		local Start, Close = util.GetOffsets(select, "StartTime")
		local len = 1/50
		for i = 1, #unique - 1 do
			local Start = unique[i]
			local Close = unique[i + 1]
			local scrolls, idx = util.GetBetween(qscrolls, Start, Close)
			if scrolls[1].StartTime > Start then
				table.insert(scrolls, 1, qscrolls[idx - 1] or {StartTime = Start, Multiplier = 1})
				idx = idx - 1
			end
			if scrolls[#scrolls].StartTime >= Close then
				-- scrolls[#scrolls] = nil
			end
			local mul = table.gather(scrolls, "Multiplier")
			local tim = table.gather(scrolls, "StartTime")
			local Target = Close - Start
			local currDist = calcDisplacement(mul, tim)
			local targDist = ENUM.Average*(Close - Start)
			local scalDist = targDist - currDist
			if Behavior.string == "Start" then
				local val = calcDisplacementSV(Start, scalDist, len)
				table.insert(addite, val)
			else
				local val = calcDisplacementSV(Close - len, scalDist, len)
				table.insert(addite, val)
			end
		end
		local Rem, Add
		if Behavior.string == "Start" then
			local i, j
			Rem, i, j = util.GetBetween(qscrolls, Start, Start)
			local val = qscrolls[j] or qscrolls[j - 1]
			val = val and val.Multiplier or 1
			Add = {
				editor.CreateScroll(Start, addite[1]),
				editor.CreateScroll(Start + len, (qscrolls[j] or {Multiplier = 1}).Multiplier),
			}
		elseif Behavior.string == "End" then
			local i, j
			Rem, i, j = util.GetBetween(qscrolls, Close, Close)
			local val = qscrolls[j] or qscrolls[j - 1]
			val = val and val.Multiplier or 1
 			Add = {
				editor.CreateScroll(Close - len, addite[1]),
				editor.CreateScroll(Close, val),
			}
		else
			error[[unknown {1}]]
		end
		if Add[1] or Rem[1] then
			actions.PerformBatch{
				editor.CreateAction("AddScrollVelocityBatch", Add),
				editor.CreateAction("RemoveScrollVelocityBatch", Rem),
			}
		end
	end
	
	gui.PullItemWidth(1)
end
local function editorCopyMenu(ENUM, WIDTH)
	local Types = ENUM.Types
	local halfwidth = {WIDTH/2 - ImStyle.ItemPad[1]/2, 0}
	
	local disable = not(chart.SelectedObjects[1])
	if disable then
		gui.BeginDisabled()
		gui.BeginGroup()
	end
	local Copy = gui.button("Copy", halfwidth); gui.Sameline()
	local CopyAll = gui_button(nil, "Copy All", halfwidth)
	if disable then
		gui.CloseGroup()
		gui.CloseDisabled()
		gui.SetItemToolTip[[Select Some Notes!]]
	end
	local Paste = gui.button("Paste", halfwidth)
	if Copy and not(disable) then
		local select = table.unique(table.gather(chart.SelectedObjects, "StartTime"))
		local tbl = {}
		local Scroll = Types.Scrolls and create0(quaver.scrolls(), editor.EncodeScrolls, {"StartTime", "Multiplier"})
		local Factor = Types.Factors and create0(quaver.factors(), editor.EncodeFactors, {"StartTime", "Multiplier"})
		local Object = Types.Objects and create0(editor.objects, editor.EncodeObjects, {"StartTime", "Lane", "Type", "EndTime", "TimingGroup"})
		
		for i = 1, #select - 1 do
			local lower = select[i]
			local upper = select[i + 1]
			local Tbl = {}
			_ = Scroll and table.insert(Tbl, Scroll(lower, upper))
			_ = Factor and table.insert(Tbl, Factor(lower, upper))
			_ = Object and table.insert(Tbl, Object(lower, upper))
			if Tbl[1] then
				tbl[#tbl + 1] = "time: 0,"..(upper - lower).."\n"..table.concat(Tbl, "\n")
			end
		end
		print(table.concat(tbl, "\n"))
		imgui.SetClipboardText(table.concat(tbl, "\n"))
	end
	if Paste then
		local formats = {
			captas = [[(-?[%d%.]+),([^|]*)]],
			factors = [[(-?[%d%.]+),(-?[%d%.]+)]],
			objects = [[(-?[%d%.]+),(-?[%d%.]+),(-?[%d%.]+),?(-?[%d%.]*),?(-?[%d%.]*)]],
			scrolls = [[(-?[%d%.]+),(-?[%d%.]+)]],
			tempos = [[(-?[%d%.]+),(-?[%d%.]+),?(%d?)]],
		}
		local Data = gui.GetClipboardText()
		local tbl = {}
		for name, data in Data:gmatch("(%w+):([^\n]*)") do
			if name == "time" then
				local lower, upper = data:match("(-?[%d%.]+),(-?[%d%.]+)")
				table.insert(tbl, {lower = lower + 0, upper = upper + 0})
			else
				data = editor.decode(data, formats[name])
				data.type = name
				table.insert(tbl[#tbl], data)
			end
		end
		-- print()
		local select = table.unique(table.gather(chart.SelectedObjects, "StartTime"))
		local Actions = {}
		for i = 1, #select - 1 do
			local v = tbl[i]
			if not(v) then break end
			local lower = select[i]
			local upper = select[i + 1]
			
			local diff = upper - lower
			local scale = (upper - lower)/tbl[i].upper
			for _, data in ipairs(tbl[i]) do
				if data.type == "objects" then
					for i, v in ipairs(data) do
						local EndTime = tonumber(v[4]) or 0
						v[4] = EndTime == 0 and 0 or EndTime*scale + lower -- EndTime
						v[3] = tonumber(v[3]) < 0 and 1 or 0 -- Type
						v[2] = tonumber(v[2]) -- Lane
						v[1] = tonumber(v[1])*scale + lower -- StartTime
					end
					editor.CreateObjects(data) -- creates inside table
				elseif data.type == "scrolls" then
					for i, v in ipairs(data) do
						v[2] = tonumber(v[2]) -- Multiplier
						v[1] = tonumber(v[1])*scale + lower -- StartTime
						data[i] = editor.CreateScroll(v[1], v[2]) -- creates inside table
					end
				end
			end
		end
		actions.Perform(editor.CreateAction("AddScrollVelocityBatch", tbl[1][1]))
			print(tbl[1][1])
		
	end
	gui.TableNextColumn()
	for i = 1, #Types do
		local name = Types[i]
		_, Types[name] = gui.CheckBox(name, Types[name])
	end
end
local function editorDeleteMenu(ENUM, WIDTH)
	local Types = ENUM.Types
	local halfwidth = {WIDTH/2 - ImStyle.ItemPad[1]/2, 0}

	local disable = not(chart.SelectedObjects[1])
	if disable then
		gui.BeginDisabled()
		gui.BeginGroup()
	end
	local delete = gui_button("exec0", "Delete", halfwidth); gui.Sameline()
	local deleteall = gui_button("exec1", "Delete All", halfwidth)
	if disable then
		gui.CloseGroup()
		gui.CloseDisabled()
		gui.SetItemToolTip[[Select Some Notes!]]
	end
	
	gui.Spacing()
	local deleteeverything = gui.Button("##X", {WIDTH*size.sml, 0});gui.Sameline()
	gui.BeginDisabled(not(gui.IsItemHovered()))
	gui.TextFormatless[[Delete Everything!]]
	gui.CloseDisabled()

	local Scrolls, Factors, Objects, Tempos, Captas
	local Groups, Layers
	local DoDelete = false
	
	if (delete or deleteall) and not(disable) then
		DoDelete = true
		global.lagControl = false -- skip next frame lagControl
		local select = chart.SelectedObjects
		local start, final = select[1].StartTime, select[#select].StartTime
		Scrolls = (deleteall or Types.Scrolls) and util.getbetween(quaver.scrolls(), start, final)
		Factors = (deleteall or Types.Factors) and util.getbetween(quaver.factors(), start, final)
		Objects = (deleteall or Types.Objects) and util.getbetween(quaver.objects(), start, final)
		Tempos = (Types.Tempos or deleteall) and util.getbetween(quaver.tempos(), start, final)
		Captas = (Types.Captas or deleteall) and util.getbetween(quaver.captas(), start, final)
	end
	if deleteeverything then
		DoDelete = true
		global.lagControl = false -- skip next frame lagControl
		Scrolls = {}
		Factors = {}
		for idx, tag in inext, chart.groups, 1 - 1 do
			Scrolls = table.combine(Scrolls, tag.Tag.ScrollVelocities)
			Factors = table.combine(Factors, tag.Tag.ScrollSpeedFactors)
		end
		
		Objects = quaver.objects()
		Tempos = table.copy(quaver.tempos())
		Captas = table.copy(quaver.captas())
		Groups = quaver.groups()
		Layers = quaver.layers()
	end
	if DoDelete then
		local data = {}
		local toprint = "Deleted:"
		if Scrolls and Scrolls[1] then
			table.insert(data, editor.CreateAction("RemoveScrollVelocityBatch", Scrolls))
			toprint = toprint.."\nScrolls - "..#Scrolls
		end
		if Factors and Factors[1] then
			table.insert(data, editor.CreateAction("RemoveScrollSpeedFactorBatch", Factors))
			toprint = toprint.."\nFactors - "..#Factors
		end
		if Objects and Objects[1] then
			table.insert(data, editor.CreateAction("RemoveHitObjectBatch", Objects))
			toprint = toprint.."\nObjects - "..#Objects
		end
		if Tempos and Tempos[1] then
			table.insert(data, editor.CreateAction("RemoveTimingPointBatch", Tempos))
			toprint = toprint.."\nTempos - "..#Tempos
		end
		if Captas and Captas[1] then
			table.insert(data, editor.CreateAction("RemoveBookmarkBatch", Captas))
			toprint = toprint.."\nCapTas - "..#Captas
		end
		
		if Groups and Groups[1] then
			table.insert(data, editor.CreateAction("RemoveTimingGroupBatch", Groups))
			toprint = toprint.."\nGroups - "..#Groups
		end
		if Layers and Layers[1] then
			for i = 1, #Layers do
				table.insert(data, editor.CreateAction("RemoveLayer", Layers[i]))
			end
			toprint = toprint.."\nLayers - "..#Layers
		end

		if data[1] then
			actions.PerformBatch(data)
			print("i!", toprint)
		else
			print[[nothing to delete!]]
		end
	end
	gui.TableNextColumn()
	for i = 1, #Types do
		local name = Types[i]
		_, Types[name] = gui.CheckBox(name, Types[name])
	end
end
local function editorMapCopyMenu(ENUM, WIDTH)
	local Types = ENUM.Types
	local halfwidth = {WIDTH/2 - ImStyle.ItemPad[1]/2, 0}
	local copy = gui_button("exec0", "Create", halfwidth); gui.Sameline()
	local past = gui_button("exec1", "Paste", halfwidth)
	gui.PushItemWidth(WIDTH/2 + ImStyle.ItemPad[1]/2)
	_, ENUM.Offset = gui.InputFloat("Paste Offset", ENUM.Offset, 1, 10, "%gms", 1)

	if copy then
		local data = {}
		global.lagControl = false -- skip next frame lagControl
		local Scrolls = Types.Scrolls and editor.encodeScrolls()
		local Factors = Types.Factors and editor.encodeFactors()
		local Objects = Types.Objects and editor.encodeObjects()
		local Tempos = Types.Tempos and editor.encodeTempos()
		local Captas = Types.Captas and editor.encodeCaptas()
		
		local toprint = "Copied: (To Clipboard)"
		if Scrolls and Scrolls ~= "scrolls:" then
			table.insert(data, Scrolls)
			toprint = toprint.."\nScrolls - "..#quaver.scrolls()
		end
		if Factors and Factors ~= "factors:" then
			table.insert(data, Factors)
			toprint = toprint.."\nFactors - "..#quaver.factors()
		end
		if Objects and Objects ~= "objects:" then
			table.insert(data, Objects)
			toprint = toprint.."\nObjects - "..#quaver.objects()
		end
		if Tempos and Tempos ~= "tempos:" then
			table.insert(data, Tempos)
			toprint = toprint.."\nTempos - "..#quaver.tempos()
		end
		if Captas and Captas ~= "captas:" then
			table.insert(data, Captas)
			toprint = toprint.."\nCapTas - "..#quaver.captas()
		end
		if data[1] then
			gui.SetClipboardText(table.concat(data, "\n"))
			print("i!", toprint)
		else
			print[[nothing to copy!]]
		end
	end
	if past then
		local data = gui.GetClipboardText()
		global.lagControl = false -- skip next frame lagControl
		local Scrolls = Types.Scrolls and editor.decode(data:match("scrolls:([^\n]*)"), [[(-?[%d%.]+),(-?[%d%.]+)]])
		local Factors = Types.Factors and editor.decode(data:match("factors:([^\n]*)"), [[(-?[%d%.]+),(-?[%d%.]+)]])
		local Objects = Types.Objects and editor.decode(data:match("objects:([^\n]*)"), [[(-?[%d%.]+),(-?[%d%.]+),(-?[%d%.]+),?(-?[%d%.]*),?(-?[%d%.]*)]])
		local Tempos = Types.Tempos and editor.decode(data:match("tempos:([^\n]*)"), [[(-?[%d%.]+),(-?[%d%.]+),?(%d?)]])
		local Captas = Types.Captas and editor.decode(data:match("captas:([^\n]*)"), [[(-?[%d%.]+),([^|]*)]])
		local Actions = {}
		if Scrolls and Scrolls[1] then
			for i, v in ipairs(Scrolls) do
				local Time = tonumber(v[1]) + ENUM.Offset
				local Speed = tonumber(v[2])
				Scrolls[i] = editor.CreateScroll(Time, Speed)
			end
			table.insert(Actions, editor.CreateAction("AddScrollVelocityBatch", Scrolls))
		end
		if Factors and Factors[1] then
			for i, v in ipairs(Factors) do
				local Time = tonumber(v[1]) + ENUM.Offset
				local Speed = tonumber(v[2])
				Factors[i] = editor.CreateFactor(Time, Speed)
			end
			table.insert(Actions, editor.CreateAction("AddScrollSpeedFactorBatch", Factors))
		end
		if Objects and Objects[1] then
			for i, v in ipairs(Objects) do
				local Time = tonumber(v[1]) + ENUM.Offset
				local Lane = tonumber(v[2])
				local Type = tonumber(v[3]) < 0 and 1 or 0
				local Held = v[4] and tonumber(v[4]) or 0
				Objects[i] = editor.CreateObject(Time, Lane, Held, nil, nil, Type, chart.CurrentGroupId)
			end
			table.insert(Actions, editor.CreateAction("PlaceHitObjectBatch", Objects))
		end
		if Tempos and Tempos[1] then
			for i, v in ipairs(Tempos) do
				local Time = tonumber(v[1]) + ENUM.Offset
				local Beat = tonumber(v[2])
				local Sign = tonumber(v[3])
				Tempos[i] = editor.CreateTempo(Time, Beat, Sign)
			end
			table.insert(Actions, editor.CreateAction("AddTimingPointBatch", Tempos))
		end
		if CapTas and CapTas[1] then
			for i, v in ipairs(CapTas) do
				local Time = tonumber(v[1]) + ENUM.Offset
				local Text = v[2]
				Text = Text:gsub([[\n𓁹]], "\n")
				Text = Text:gsub([[𓁹 𓁹]], "|")
				Text = Text:gsub([[𓁹𓁹]], "𓁹")
				CapTas[i] = editor.CreateCapta(Time, Beat, Sign)
			end
			table.insert(Actions, editor.CreateAction("AddTimingPointBatch", CapTas))
		end
		if Actions[1] then actions.PerformBatch(Actions) end
	end
	gui.TableNextColumn()
	for i = 1, #Types do
		local name = Types[i]
		_, Types[name] = gui.CheckBox(name, Types[name])
	end
end
local function editorOffsetMenu(ENUM, WIDTH)
	local Types = ENUM.Types
	
	local halfwidth = {WIDTH/2 - ImStyle.ItemPad[1]/2, 0}
	local disable = not(chart.SelectedObjects[1])
	if disable then
		gui.BeginDisabled()
		gui.BeginGroup()
	end
	local offset = gui_button("exec0", "Offset", halfwidth); gui.Sameline()
	local offsetall = gui_button("exec1", "Offset All", halfwidth)
	if disable then
		gui.CloseGroup()
		gui.CloseDisabled()
		gui.SetItemToolTip[[Select Some Notes!]]
	end
	
	gui.NextItemWidth(WIDTH/2 + ImStyle.ItemPad[1]/2)
	_, ENUM.Offset = gui.InputFloat("Offset##enum", ENUM.Offset, 1, 10, "%gms", 1)
	
	gui.Spacing()
	local offseteverything = gui.Button("##X", {WIDTH*size.sml, 0});gui.Sameline()
	gui.BeginDisabled(not(gui.IsItemHovered()))
	gui.TextFormatless[[Offset Everything!]]
	gui.CloseDisabled()
	
	local Scrolls, Factors, Objects, Tempos, Captas
	local DoOffset = false
	
	if (offset or offsetall) and not(disable) then
		DoOffset = true
		global.lagControl = false -- skip next frame lagControl
		local select = chart.SelectedObjects
		local start, final = select[1].StartTime, select[#select].StartTime
		Scrolls = (offsetall or Types.Scrolls) and util.getbetween(quaver.scrolls(), start, final)
		Factors = (offsetall or Types.Factors) and util.getbetween(quaver.factors(), start, final)
		Objects = (offsetall or Types.Objects) and util.getbetween(quaver.objects(), start, final)
		Tempos = (Types.Tempos or offsetall) and util.getbetween(quaver.tempos(), start, final)
		Captas = (Types.Captas or offsetall) and util.getbetween(quaver.captas(), start, final)
	end
	if offseteverything then
		DoOffset = false
		global.lagControl = false -- skip next frame lagControl
		Scrolls = 0
		Factors = 0
		Objects = #editor.objects
		Tempos = #editor.tempos
		Captas = #editor.captas
		for idx, tag in inext, chart.groups, 1 - 1 do
			Scrolls = Scrolls + #tag.Tag.ScrollVelocities
			Factors = Factors + #tag.Tag.ScrollSpeedFactors
		end
		local toprint = "Offset:"
		if Scrolls > 0 then toprint = toprint.."\nScrolls - "..Scrolls end
		if Factors > 0 then toprint = toprint.."\nFactors - "..Factors end
		if Objects > 0 then toprint = toprint.."\nObjects - "..Objects end
		if Tempos > 0 then toprint = toprint.."\nTempos - "..Tempos end
		if Captas > 0 then toprint = toprint.."\nCapTas - "..Captas end
		if toprint ~= "Offset:" then
			actions.Perform(editor.CreateAction("ApplyOffset", -ENUM.Offset))
			print("i!", toprint)
		else
			print[[nothing to offset!]]
		end
	end
	
	if DoOffset then
		local data = {}
		local toprint = "Offset:"
		if Scrolls and Scrolls[1] then
			table.insert(data, editor.CreateAction("ChangeScrollVelocityOffsetBatch", Scrolls, ENUM.Offset))
			toprint = toprint.."\nScrolls - "..#Scrolls
		end
		if Factors and Factors[1] then
			table.insert(data, editor.CreateAction("ChangeScrollSpeedFactorOffsetBatch", Factors, ENUM.Offset))
			toprint = toprint.."\nFactors - "..#Factors
		end
		if Objects and Objects[1] then
			table.insert(data, editor.CreateAction("MoveHitObjects", Objects, 0, ENUM.Offset))
			toprint = toprint.."\nObjects - "..#Objects
		end
		if Tempos and Tempos[1] then
			table.insert(data, editor.CreateAction("ChangeTimingPointOffsetBatch", Tempos, ENUM.Offset))
			toprint = toprint.."\nTempos - "..#Tempos
		end
		if Captas and Captas[1] then
			table.insert(data, editor.CreateAction("ChangeBookmarkOffsetBatch", Captas, ENUM.Offset))
			toprint = toprint.."\nCapTas - "..#Captas
		end

		if data[1] then
			actions.PerformBatch(data)
			print("i!", toprint)
		else
			print[[nothing to offset!]]
		end
	end
	gui.TableNextColumn()
	for i = 1, #Types do
		local name = Types[i]
		_, Types[name] = gui.CheckBox(name, Types[name])
	end
end
local function editorResnapMenu(ENUM, WIDTH)
	local halfwidth = {WIDTH/2 - ImStyle.ItemPad[1]/2, 0}
	local Find = gui_button("exec0", "Find", halfwidth); gui.Sameline()
	gui.ButtonDisabled(ENUM.lenData or [[]], halfwidth)
	
	gui.PushItemWidth(WIDTH/2 + ImStyle.ItemPad[1]/2)
	_, ENUM.Offset = gui.InputFloat("Buffer", ENUM.Offset, 0.1, 0.01, "%gms", 1)
	-- local context = gui.GetCurrentContext()
	-- print(context[1])
	_ = DrawHoverHelp() and ToolTip(
		[[Buffer range for search.]].."\n"..
		[[- Lower: may mistake snapped notes.]].."\n"..
		[[- Higher: may miss unsnapped notes.]].."\n"..
		[[Choose the best middle for your map.]]
	)
	if Find then
		if not(editor.objects[1]) then print("w", "No notes to check!") return end
		local tbl = action.GetNotesUnsnapped(ENUM.Offset, ENUM.Snaps)
		ENUM.Data = tbl[1] and tbl
		if not(tbl[1]) then
			ENUM.lenData = nil
			print("\nNo Unsnapped Detected!")
		else
			ENUM.lenData = #tbl
		end
	end
	if ENUM.Data then
		gui.BeginTable("Menu", 3, 1920)
		gui.TableSetupColumn(1, 16, WIDTH*(1/3))
		gui.TableSetupColumn(2, 16, WIDTH*(1/3))
		gui.TableSetupColumn(3, 16, WIDTH*(1/3))
		gui.TableNextColumn(); gui.TableHeader[[Start Time]]
		gui.TableNextColumn(); gui.TableHeader[[End Time]]
		gui.TableNextColumn(); gui.TableHeader[[Lane]]
		local posiy = gui.GetCursorPosY()
		local size = {-1, 0}
		for i, v in inext, ENUM.Data, ENUM.StartIdx - 1 do
			gui.PushID(i)
			if v.time then
				gui.TableNextRow()
				gui.TableNextColumn()
				local GoTo = gui.Button(v.time, size)
				if GoTo then
					actions.GoToObjects(v.time)
					actions.SetHitObjectSelection{editor.objects[v.i]}
				end
				gui.TableNextColumn()
				if v.hold then
					local GoTo = gui.Button(v.hold, size)
					if GoTo then
						actions.GoToObjects(v.hold)
						actions.SetHitObjectSelection{editor.objects[v.i]}
					end
				end
			elseif v.hold then
				gui.TableNextRow()
				gui.TableNextColumn()
				gui.TableNextColumn()
				local GoTo = gui.Button(v.hold, size)
				if GoTo then
					actions.GoToObjects(v.hold)
					actions.SetHitObjectSelection{editor.objects[v.i]}
				end
			end
			gui.TableNextColumn()
			gui.BeginDisabled()
			gui.Button(v.lane, size)
			gui.CloseDisabled()
			gui.PullID()
			if i >= (ENUM.StartIdx + ENUM.CloseIdx) then break end
		end
		gui.CloseTable()
		if #ENUM.Data > ENUM.CloseIdx then
			gui.TableNextColumn()
			gui.SetCursorPosY(posiy)
			gui.PushButtonRepeat()
			--
			local disabled = ENUM.StartIdx == 1
			_ = disabled and gui.BeginDisabled()
			local up = gui.ArrowButton("##AB1", "Up")
			_ = disabled and gui.CloseDisabled()
			
			local disabled = ENUM.StartIdx == #ENUM.Data - ENUM.CloseIdx
			_ = disabled and gui.BeginDisabled()
			local dw = gui.ArrowButton("##AB2", "Down")
			_ = disabled and gui.CloseDisabled()
			--
			gui.PullButtonRepeat()
			if up or dw then
				ENUM.StartIdx = math.clamp(ENUM.StartIdx + (up and -1 or dw and 1), 1, #ENUM.Data - ENUM.CloseIdx)
				-- ENUM.CloseIdx = math.clamp(ENUM.CloseIdx + (up and 1 or dw and -1), 1, #ENUM.Data - 1)
			end
		end
	end
end

menu["Editor"].Types = listable({})
menu["Editor"].Types.Scrolls = true
menu["Editor"].Types.Factors = true
menu["Editor"].Types.Objects = false
menu["Editor"].Types.Tempos = false
menu["Editor"].Types.Captas = false
menu["Editor"].Types:kill()

listable(menu["Editor"], "Delete")
--[[ menu["Editor"]["Copy"] = table.meta:call({
	Types = menu["Editor"].Types,
}, editorCopyMenu) ]]
menu["Editor"]["Create Map Copy"] = table.meta:call({
	Types = menu["Editor"].Types,
	Offset = 0,
}, editorMapCopyMenu)
menu["Editor"]["Delete"] = table.meta:call({
	Types = menu["Editor"].Types,
}, editorDeleteMenu)
menu["Editor"]["Detect Unsnapped"] = table.meta:call({
	Data = false,
	Count = 2,
	Snaps = {12, 16},
	Offset = 0.5,
	StartIdx = 1,
	CloseIdx = 14,
}, editorResnapMenu)
menu["Editor"]["Offset"] = table.meta:call({
	Types = menu["Editor"].Types,
	Offset = 0,
}, editorOffsetMenu)
--[[ menu["Editor"]["SV Displace"] = table.meta:call({
	Behavior = listable({}, "Start"),
	Type = listable({}, "Average"),
	Average = 1,
}, editorScaleDispMenu) ]]
menu["Editor"]:kill()

menu["Editor"].Types = listable({})
menu["Editor"].Types.Scrolls = true
menu["Editor"].Types.Factors = true
menu["Editor"].Types.Objects = false
menu["Editor"].Types.Tempos = false
menu["Editor"].Types.Captas = false
menu["Editor"].Types:kill()

-- local ScaleDisp = menu["Editor"]["SV Displace"]
-- ScaleDisp.Behavior["Start"] = nil
-- ScaleDisp.Behavior["End"] = nil
-- ScaleDisp.Behavior:kill()

menu["Create"].Active = true
def_menu = table.copy(menu)
function update()
	board.event()
	editor.time = state.SongTime
	chart.SelectedObjects = state.SelectedHitObjects
	local NewSG = state.SelectedScrollGroupId
	local NewEL = state.CurrentLayer
	if NewSG ~= OldSG then
		chart.CurrentGroupId = NewSG
		chart.CurrentGroup = chart.groups[NewSG]
		OldSG = NewSG
	end
	if NewEL ~= OldEL then
		chart.CurrentLayerId = NewEL.Name
		chart.CurrentLayer = chart.layers[NewEL.Name] or chart.layers[1]
		OldEL = NewEL
	end
end

function render(NAME, FUNC)
	if not(FUNC) or plugin.render[NAME] then
		plugin.render[NAME] = nil
	else
		plugin.render[NAME] = FUNC
	end
end
function renderOnPlugin(NAME, FUNC)
	if not(FUNC) or plugin.renderOnPlugin[NAME] then
		plugin.renderOnPlugin[NAME] = nil
	else
		plugin.renderOnPlugin[NAME] = FUNC
	end
end

local blealpha = false
local clock = os.clock
local function main()
	local bench = clock()
	update()
	for _, window in pairs(plugin.render) do
		window()
	end
	if blealpha then
		gui.PushStyleVar("Alpha", .33)
	end
	-- gui.SetNextWindowPos{200, 200}
	-- print()
	gui.NextWindowSizeClamp(plugin.mini, plugin.maxi)
	local acti, open = gui.Begin(plugin.name, true, plugin.flag)
	if not(acti) then
		return
	elseif not(open) then
		blealpha = not(blealpha)
	end
	gui.BeginDisabled(blealpha)
	local width = gui.GetWindowRegionAvailWidth()
	for _, item in pairs(plugin.renderOnPlugin) do
		item(width)
	end
	gui.BeginTabBar("SV Tab Bars")
	for i = 1, #menu do
		local str = menu[i]
		gui.NextItemWidth(width*(1/4))
		if gui.BeginTabItem(str) then
			menu[str](width)
			gui.CloseTabItem()
		end
	end
	gui.CloseTabBar()
	gui.CloseDisabled()
	-- gui.SetItemTooltip[[ffff]]
	gui.Close()
	
	if global.lagControl then
		if clock() - bench > 0.1 then
			if global.collapseOnLag then gui.SetWindowCollapsed(plugin.name, true) end
			error("\nLAG! please reset the editor if this repeats!")
			-- draw = isolate
		end
	else
		global.lagControl = true
	end
end
function isolate()
	if (1000/state.DeltaTime) > 500 then
		draw = main
	else
	end
end
local openingtext = {string = "regular"; rarity = 0/0}

function awake()
	local read = read()
	if read then
		for i, v in pairs(global) do
			read[i] = expr(read[i])
			if read[i] ~= nil then
				global[i] = read[i]
			end
		end
		if global.noteinfo then
			render("NoteInfoWidget", addon.NoteInfoWidget)
		end
	end
	plugin.menutext = [[Welcome to ADDtHER!Al]]
	for _, func in ipairs(awaken) do
		func()
	end
	
	-- listen(function(EVENT)
		-- local typ = tostring(EVENT.Type):lower()
		-- local read = read()
		-- read["Last Action"] = typ
		-- write(read)
		-- print(typ)
	-- end)
	gui.SetNextWindowCollapsed(false)
	draw = main
end
