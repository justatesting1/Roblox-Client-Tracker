--	// FileName: PlayEmote.lua
--	// Written by: TheGamer101
--	// Description: Play an emote by name.

local Chat = game:GetService("Chat")
local Players = game:GetService("Players")

local CommandModules = script.Parent
local Util = require(CommandModules:WaitForChild("Util"))

local FFlagPlayEmoteChatCommandEnabled = false do
	local ok, value = pcall(function()
		return UserSettings():IsUserFeatureEnabled("UserPlayEmoteChatCommand")
	end)
	if ok then
		FFlagPlayEmoteChatCommandEnabled = value
	end
end

if not FFlagPlayEmoteChatCommandEnabled then
    return {
        [Util.KEY_COMMAND_PROCESSOR_TYPE] = Util.COMPLETED_MESSAGE_PROCESSOR,
        [Util.KEY_PROCESSOR_FUNCTION] = function() return false end,
    }
end

local ChatLocalization = nil
pcall(function() ChatLocalization = require(Chat.ClientChatModules.ChatLocalization) end)
if ChatLocalization == nil then ChatLocalization = { Get = function(self, key, fallback) return fallback end } end

local LocalPlayer = Players.LocalPlayer

local LegacyDefaultEmotes = {
	wave = true,
	point = true,
	dance = true,
	dance2 = true,
	dance3 = true,
	laugh = true,
	cheer = true,
}

local LocalizationKeys = {
    NotSupported = "InGame.Chat.Response.EmoteNotAvailable",
    R15Only = "InGame.Chat.Response.EmotesNotSupported",
    NoMatchingEmote = "InGame.Chat.Response.EmotesWrongAvatarType",
    TemporarilyUnavailable = "InGame.Chat.Response.EmotesTemporarilyUnavailable",
}

local FallbackStrings = {
	[LocalizationKeys.NotSupported] = "You can't use Emotes here.",
	[LocalizationKeys.R15Only] = "Only R15 avatars can use Emotes.",
	[LocalizationKeys.NoMatchingEmote] = "You can't use that Emote.",
	[LocalizationKeys.TemporarilyUnavailable] = "You can't use Emotes right now.",
}

local ErrorColor = Color3.fromRGB(245, 50, 50)

local function getEmoteName(message)
	if string.sub(message, 1, 3) == "/e " then
		return string.sub(message, 4)
	elseif string.sub(message, 1, 7) == "/emote " then
		return string.sub(message, 8)
	end

	return nil
end

local function sendErrorMessage(channelObj, errorMessageKey)
	local localizedString = ChatLocalization:Get(errorMessageKey, FallbackStrings[errorMessageKey])
	local extraData = {
		ChatColor = ErrorColor,
	}

	Util:SendSystemMessageToSelf(localizedString, channelObj, extraData)
end

local function ProcessMessage(message, ChatWindow, ChatSettings)
	local emoteName = getEmoteName(message)
	if not emoteName then
		return false
	end

	if LegacyDefaultEmotes[emoteName] then
		-- Just don't show these in the chat log. The animation script listens on these.
		return true
	end

	local channelObj = ChatWindow:GetCurrentChannel()
	if not channelObj then
		return true
	end

	local character = LocalPlayer.Character
	if not character then
		sendErrorMessage(channelObj, LocalizationKeys.TemporarilyUnavailable)
		return true
	end

	local animateScript = character:FindFirstChild("Animate")
	if not animateScript then
		sendErrorMessage(channelObj, LocalizationKeys.NotSupported)
		return true
	end

	local playEmoteBindable = animateScript:FindFirstChild("PlayEmote")
	if not playEmoteBindable then
		sendErrorMessage(channelObj, LocalizationKeys.NotSupported)
		return true
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		sendErrorMessage(channelObj, LocalizationKeys.TemporarilyUnavailable)
		return true
	end

	if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		sendErrorMessage(channelObj, LocalizationKeys.R15Only)
		return true
	end

	local humanoidDescription = character:FindFirstChildOfClass("HumanoidDescription")
	if not humanoidDescription then
		sendErrorMessage(channelObj, LocalizationKeys.TemporarilyUnavailable)
		return true
	end

	local lowerCaseEmoteNamesMap = {}

	local emotes = humanoidDescription:GetEmotes()
	for name, _ in pairs(emotes) do
		lowerCaseEmoteNamesMap[string.lower(name)] = name
	end

	local emoteNameLower = string.lower(emoteName)
	emoteName = lowerCaseEmoteNamesMap[emoteNameLower]

	if not emoteName then
		sendErrorMessage(channelObj, LocalizationKeys.NoMatchingEmote)
		return true
	end

	spawn(function()
		local ok, didPlay = pcall(function() return humanoid:PlayEmote(emoteName) end)

		if not ok then
			sendErrorMessage(channelObj, LocalizationKeys.NotSupported)
		elseif not didPlay then
			sendErrorMessage(channelObj, LocalizationKeys.TemporarilyUnavailable)
		end
	end)

	return true
end

return {
	[Util.KEY_COMMAND_PROCESSOR_TYPE] = Util.COMPLETED_MESSAGE_PROCESSOR,
	[Util.KEY_PROCESSOR_FUNCTION] = ProcessMessage
}
