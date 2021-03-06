--[[
	Component to avoid repetition of props used in text used in
	DeveloperSubscriptionListItems

	Props:
		UDim2 Size = how big the TextLabel is
		string Text = the text to show
		int LayoutOrder = the order in which this text shows
		TextXAlignment Alignment = the horizontal alignment of the text
			(vertical alignment is never used)
]]

local Plugin = script.Parent.Parent.Parent.Parent
local Roact = require(Plugin.Roact)
local withTheme = require(Plugin.Src.Consumers.withTheme)

return function(props)
	local size = props.Size
	local text = props.Text
	local layoutOrder = props.LayoutOrder
	local alignment = props.Alignment
	local textColor3 = props.TextColor3

	return withTheme(function(theme)
		return Roact.createElement("TextLabel", {
			Size = size,
			Text = text,
			LayoutOrder = layoutOrder,

			TextColor3 = textColor3 or theme.titledFrame.text,
			Font = Enum.Font.SourceSans,
			TextSize = 22,
			TextXAlignment = alignment,

			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		})
	end)
end