local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Thunk = require(script.Parent.Parent.Thunk)
local PromptState = require(script.Parent.Parent.PromptState)

local HidePrompt = require(script.Parent.Parent.Actions.HidePrompt)

local function signalFinishedAndHidePrompt()
	return Thunk.new(script.Name, {}, function(store, services)
		local state = store:getState()
		local productType = state.product.infoType
		local id = state.product.id
		local assetTypeId = state.productInfo.assetTypeId
		local didPurchase = (state.promptState == PromptState.PurchaseComplete)

		if id ~= nil then
			if productType == Enum.InfoType.Product then
				local playerId = Players.LocalPlayer.UserId

				MarketplaceService:SignalPromptProductPurchaseFinished(playerId, id, didPurchase)
			elseif productType == Enum.InfoType.GamePass then
				MarketplaceService:SignalPromptGamePassPurchaseFinished(Players.LocalPlayer, id, didPurchase)
				if didPurchase and assetTypeId then
					MarketplaceService:SignalAssetTypePurchased(Players.LocalPlayer, assetTypeId)
				end
			elseif productType == Enum.InfoType.Asset then
				MarketplaceService:SignalPromptPurchaseFinished(Players.LocalPlayer, id, didPurchase)
				if didPurchase and assetTypeId then
					MarketplaceService:SignalAssetTypePurchased(Players.LocalPlayer, assetTypeId)
				end
			end
		end

		store:dispatch(HidePrompt())
	end)
end

return signalFinishedAndHidePrompt