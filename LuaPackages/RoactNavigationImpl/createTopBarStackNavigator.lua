local CoreGui = game:GetService("CoreGui")
local Modules = CoreGui.RobloxGui.Modules
local Roact = require(Modules.Common.Roact)

local StubComponent = Roact.Component:extend("TopBarStackNavigator")

function StubComponent.render()
	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 1, 0)
	})
end

return function(--[[routeConfigs, navigatorConfig]])
	-- TODO: Implement me.
	return StubComponent
end
