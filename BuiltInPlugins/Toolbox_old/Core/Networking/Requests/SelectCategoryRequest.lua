local Plugin = script.Parent.Parent.Parent.Parent

local Sort = require(Plugin.Core.Types.Sort)

local UpdatePageInfoAndSendRequest = require(Plugin.Core.Networking.Requests.UpdatePageInfoAndSendRequest)
local StopAllSounds = require(Plugin.Core.Actions.StopAllSounds)

return function(networkInterface, settings, categoryIndex)
	return function(store)
		if store:getState().assets.isLoading then
			return
		end

		store:dispatch(StopAllSounds())

		store:dispatch(UpdatePageInfoAndSendRequest(networkInterface, settings, {
			categoryIndex = categoryIndex,
			searchTerm = "",
			sortIndex = Sort.getDefaultSortForCategory(categoryIndex),
			page = 1,
		}))

	end
end
