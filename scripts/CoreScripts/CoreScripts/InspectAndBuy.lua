local CorePackages = game:GetService("CorePackages")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local CoreGuiService = game:GetService("CoreGui")
local RobloxGui = CoreGuiService:WaitForChild("RobloxGui")
local CoreGuiModules = RobloxGui:WaitForChild("Modules")
local InspectAndBuyModules = CoreGuiModules:WaitForChild("InspectAndBuy")
local Roact = require(CorePackages.Roact)
local InspectAndBuy = require(InspectAndBuyModules.Components.InspectAndBuy)
local InspectAndBuyInstanceHandle = nil

local function mount(humanoidDescription, playerName, userId)
	if InspectAndBuyInstanceHandle then
		Roact.unmount(InspectAndBuyInstanceHandle)
	end

	local localPlayerModel = game.Players:CreateHumanoidModelFromUserId(Players.LocalPlayer.UserId)

	local inspectAndBuy = Roact.createElement(InspectAndBuy, {
		humanoidDescription = humanoidDescription,
		playerName = playerName,
		playerId = userId,
		localPlayerModel = localPlayerModel,
	})
	InspectAndBuyInstanceHandle = Roact.mount(inspectAndBuy, RobloxGui, "InspectAndBuy")
end

local function unmountInspectAndBuy()
	if InspectAndBuyInstanceHandle then
		Roact.unmount(InspectAndBuyInstanceHandle)
		InspectAndBuyInstanceHandle = nil
	end
end

local function mountInspectAndBuyFromHumanoidDescription(humanoidDescription, playerName)
	mount(humanoidDescription, playerName)
end

local function mountInspectAndBuyFromUserId(userId)
	local name = Players:GetNameFromUserIdAsync(userId)
	local inspectingModel = Players:CreateHumanoidModelFromUserId(userId)
	local humanoidDescription = inspectingModel.Humanoid.HumanoidDescription
	mount(humanoidDescription, name, userId)
end

GuiService.InspectPlayerFromHumanoidDescriptionRequest:Connect(function(humanoidDescription, playerName)
	mountInspectAndBuyFromHumanoidDescription(humanoidDescription, playerName)
end)

GuiService.InspectPlayerFromUserIdRequest:Connect(function(userId)
	mountInspectAndBuyFromUserId(userId)
end)

GuiService.CloseInspectMenuRequest:Connect(function()
	if InspectAndBuyInstanceHandle then
		unmountInspectAndBuy()
	end
end)

GuiService.InspectMenuEnabledChangedSignal:Connect(function(enabled)
	if not enabled and InspectAndBuyInstanceHandle then
		unmountInspectAndBuy()
	end
end)
