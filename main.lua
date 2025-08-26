local api = require("api")
local ui = require("obey/util/ui_helper")

local obey = {
	name = "Obey",
	author = "Emi",
	version = "1.0",
	desc = "Configurable phrases for 'forced' emotes"
}
local path = "obey/save.txt"

local phrases = {}
local phrase_map = {} -- Map for O(1) lookup
local whitelist = {}
local blacklist = {}
local settings_wnd = nil
local txt_edit = nil
local whtlist_edit = nil
local blklist_edit = nil

local function LoadSave()
	local save = api.File:Read(path)

	if save == nil or save.phrases == nil then
		save = { phrases = { { phrase = "Hello", emote = "/waving" }, { phrase = "This is the structure", emote = "/clap" } },
		whitelist = {}, blacklist = {},}
		api.File:Write(path, save)
	end

	phrases = save.phrases
	whitelist = save.whitelist
	blacklist = save.blacklist
end

local function SaveToFile()
	local out = {
		phrases = phrases,
		whitelist = whitelist,
		blacklist = blacklist,
	}
	api.File:Write(path, out)
end

local function BuildPhraseMap()
	phrase_map = {} -- Clear prev
	for _, v in ipairs(phrases) do
		phrase_map[string.lower(v.phrase)] = v.emote
	end
end

local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function ParsePhrases(input)
	local new_list = {}
	for chunk in string.gmatch(input, "([^,]+)") do
		local piece = trim(chunk)
		if piece ~= "" then
			local lhs, rhs = piece:match("^(.-)=(.*)$")
			local phrase = lhs and trim(lhs) or trim(piece)
			local emote = lhs and trim(rhs) or nil
			if phrase ~= "" then
				table.insert(new_list, {phrase = phrase, emote = emote})
			end
		end
	end

	local old_map = {}
	for _, item in ipairs(phrases) do
		old_map[item.phrase] = item
	end

	local result = {}
	for _, entry in ipairs(new_list) do
		local old = old_map[entry.phrase]
		if old then
			local emote = (entry.emote ~= nil and entry.emote ~= "" and entry.emote) or old.emote
			table.insert(result, { phrase = entry.phrase, emote = emote })
			old_map[entry.phrase] = nil
		else
			table.insert(result, { phrase = entry.phrase, emote = (entry.emote ~= nil and entry.emote ~= "" and entry.emote) or "/happy" })
		end

	end
				
	phrases = result
	BuildPhraseMap()
end

local function ParseList(input, isWhiteList)
	local new_list = {}

	for i in string.gmatch(input, "([^,]+)") do
		local item = trim(i)
		if item ~= "" then
			table.insert(new_list, item)
		end
	end

	if isWhiteList then
		whitelist = new_list
	else
		blacklist = new_list
	end
end

local function JoinPhraseData(tbl)
	local out = {}
	for i, entry in ipairs(tbl) do
		out[i] = entry.phrase .. " = " .. entry.emote
	end
    return table.concat(out, ",\n")
end

local function JoinListData(tbl)
	return table.concat(tbl, ", ")
end

local function SaveEdits()
	ParsePhrases(txt_edit:GetText())
	ParseList(whtlist_edit:GetText(), true)
	ParseList(blklist_edit:GetText(), false)
	SaveToFile()
end

local function OnSettingToggle()
	if settings_wnd == nil then
		settings_wnd = api.Interface:CreateWindow("obeySettingsWnd", "Obey Settings")
		settings_wnd:SetExtent(800, 580)

		
		local phraseinfolbl = ui.CreateChildLabel("obeyphraseinfolbl", settings_wnd, "Phrases", ALIGN.CENTER, FONT_SIZE.LARGE, 0.400, 0.251, 0.043, 1)
		phraseinfolbl:AddAnchor("TOPLEFT", settings_wnd, 170, 80)

		local phraseinfo2lbl = ui.CreateChildLabel("obeyphraseinfo2lbl", settings_wnd, "Add 'phrase = /emote' seperated by comma", ALIGN.CENTER, FONT_SIZE.MEDIUM, 0.400, 0.251, 0.043, 1)
		phraseinfo2lbl:AddAnchor("TOPLEFT", settings_wnd, 170, 100)
		
		txt_edit = ui.CreateMultiLineEdit("obeyEdit", settings_wnd, JoinPhraseData(phrases), 300, 380, 3000)
		txt_edit:AddAnchor("TOPLEFT", settings_wnd, 20, 120)

		local whtlistinfolbl = ui.CreateChildLabel("obeywhtlistinfolbl", settings_wnd, "Whitelist", ALIGN.CENTER, FONT_SIZE.LARGE, 0.400, 0.251, 0.043, 1)
		whtlistinfolbl:AddAnchor("TOPLEFT", settings_wnd, 565, 80)

		local whtlistinfo2lbl = ui.CreateChildLabel("obeywhtlistinfo2lbl", settings_wnd, "Add player names seperated by comma", ALIGN.CENTER, FONT_SIZE.MEDIUM, 0.400, 0.251, 0.043, 1)
		whtlistinfo2lbl:AddAnchor("TOPLEFT", settings_wnd, 565, 100)

		whtlist_edit = ui.CreateMultiLineEdit("obeywhtlistedit", settings_wnd, JoinListData(whitelist), 420, 150, 3000)
		whtlist_edit:AddAnchor("TOPLEFT", settings_wnd, 350, 120)

		blklist_edit = ui.CreateMultiLineEdit("obeyblklistedit", settings_wnd, JoinListData(blacklist), 420, 150, 3000)
		blklist_edit:AddAnchor("TOPLEFT", settings_wnd, 350, 350)

		local blklistinfolbl = ui.CreateChildLabel("obeyblklistinfolbl", settings_wnd, "Blacklist", ALIGN.CENTER, FONT_SIZE.LARGE, 0.400, 0.251, 0.043, 1)
		blklistinfolbl:AddAnchor("TOPLEFT", settings_wnd, 565, 310)

		local blklistinfo2lbl = ui.CreateChildLabel("obeyblklistinfo2lbl", settings_wnd, "Add player names seperated by comma", ALIGN.CENTER, FONT_SIZE.LARGE, 0.400, 0.251, 0.043, 1)
		blklistinfo2lbl:AddAnchor("TOPLEFT", settings_wnd, 565, 330)

		local saveEditsBtn = ui.CreateChildButton("obeysaveeditsbtn", settings_wnd, "Save Changes", 90, 26, BUTTON_BASIC.DEFAULT)
		saveEditsBtn:AddAnchor("BOTTOM", settings_wnd, 0, -20)
		saveEditsBtn:SetHandler("OnClick", SaveEdits)

	end
	settings_wnd:Show(true)
end

local function InList(list, value)
	for i = 1, #list do
		if string.lower(list[i]) == value then
			return true
		end
	end
	return false
end

local function OnChat(channelId, speakerId, _, speakerName, message)
	if channelId == 0 or channelId == 9 or channelId == -4 -- TODO: Make recognized channels configurable
	or channelId == 4 or channelId == 5 then
		-- Check for whitelist
		if #whitelist ~= 0 then
			if not InList(whitelist, string.lower(speakerName)) then
				return
			end
		end

		-- Check blacklist
		if #blacklist ~= 0 then
			if InList(blacklist, string.lower(speakerName)) then
				return
			end
		end

		-- TODO: Allow setting for finding phrase within message not exact message?

		-- Try find mapped phrase
		local emote = phrase_map[string.lower(message)]
		if emote then
			X2Chat:ExpressEmotion(emote)
		end
	end
end

local function OnLoad()
	LoadSave()
	BuildPhraseMap()
	api.On("CHAT_MESSAGE", OnChat)
end

local function OnUnload()
	api.On("CHAT_MESSAGE", nil)
	phrases = nil
	if settings_wnd ~= nil then
		txt_edit = nil
		settings_wnd:Show(false)
		settings_wnd = nil
	end
end

obey.OnLoad = OnLoad
obey.OnUnload = OnUnload
obey.OnSettingToggle = OnSettingToggle

return obey