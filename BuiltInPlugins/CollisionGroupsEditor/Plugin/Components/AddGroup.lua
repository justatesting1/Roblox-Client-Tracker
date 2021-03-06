local Roact = require(script.Parent.Parent.Parent.modules.roact)

local Constants = require(script.Parent.Parent.Constants)

local GroupLabelPadding = require(script.Parent.GroupLabelPadding)
local GroupLabelColumn = require(script.Parent.GroupLabelColumn)

return function(props)
	return Roact.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Constants.GroupRowHeight),
		Position = UDim2.new(0, 0, 1, 0),
		AnchorPoint = Vector2.new(0, 1),
		LayoutOrder = props.LayoutOrder,
	}, {
		Layout = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
		}),

		Spacer = Roact.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(3, 3, 1, 0),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			LayoutOrder = 1,
		}),

		AddGroup = Roact.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = Constants.GroupLabelSize,
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			LayoutOrder = 2,
		}, {
			Padding = Roact.createElement(GroupLabelPadding),

			TextBox = Roact.createElement("TextBox", {
				BackgroundTransparency = 1,
				Text = "",
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Right,

				PlaceholderText = "+ Add Group",
				PlaceholderColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.SubText),

				TextColor3 = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText),

				Size = UDim2.new(1, 0, 1, 0),

				[Roact.Event.FocusLost] = function(gui, submitted)
					if submitted then
						props.OnGroupAdded(gui.Text)
					end
					gui.Text = ""
				end,
			}),
		})
	})
end