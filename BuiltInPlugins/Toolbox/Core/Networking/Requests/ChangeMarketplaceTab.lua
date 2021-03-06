local Plugin = script.Parent.Parent.Parent.Parent
local Cryo = require(Plugin.Libs.Cryo)

local UpdatePageInfo = require(Plugin.Core.Actions.UpdatePageInfo)
local SetCategories = require(Plugin.Core.Actions.SetCategories)
local GetManageableGroupsRequest = require(Plugin.Core.Networking.Requests.GetManageableGroupsRequest)

local FFlagEnableMarketplaceChangeTabsAnalytics = settings():GetFFlag("EnableMarketplaceChangeTabsAnalytics")

local Category = require(Plugin.Core.Types.Category)

return function(networkInterface, tabName, newCategories,  settings)
	return function(store)
		if store:getState().assets.isLoading then
			return
		end

		store:dispatch(UpdatePageInfo({
			creator = Cryo.None,
		}, settings))

		if FFlagEnableMarketplaceChangeTabsAnalytics then
			store:dispatch(SetCategories(tabName, newCategories))
		else
			store:dispatch(SetCategories(tabName, Category.TABS[tabName]))
		end

		if tabName == Category.INVENTORY_KEY then
			store:dispatch(GetManageableGroupsRequest(networkInterface))
		end
	end
end