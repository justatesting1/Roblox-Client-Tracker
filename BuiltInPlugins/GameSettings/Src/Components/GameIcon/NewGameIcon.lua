--[[
	Represents a widget for adding a new game icon to the game.
	It displays only when the game does not have a game icon,
	in which case GameIconWidget was passed a nil Icon prop.

	Props:
		bool Visible = Whether this widget is currently visible.
		function OnClick = A callback invoked when this widget is clicked.
			This will mean that the user wants to add a new icon.
]]

local Plugin = script.Parent.Parent.Parent.Parent
local Roact = require(Plugin.Roact)
local withTheme = require(Plugin.Src.Consumers.withTheme)
local getMouse = require(Plugin.Src.Consumers.getMouse)

local BORDER = "rbxasset://textures/GameSettings/DottedBorder_Square.png"
local PLUS = "rbxasset://textures/GameSettings/CenterPlus.png"

local NewGameIcon = Roact.PureComponent:extend("NewGameIcon")

function NewGameIcon:init()
	self.mouseEnter = function()
		self:mouseHoverChanged(true)
	end

	self.mouseLeave = function()
		self:mouseHoverChanged(false)
	end
end

function NewGameIcon:mouseHoverChanged(hovering)
	getMouse(self).setHoverIcon("PointingHand", hovering)
end

function NewGameIcon:render()
	local visible = self.props.Visible

	return withTheme(function(theme)
		return Roact.createElement("ImageButton", {
			Visible = visible,
			BorderSizePixel = 0,
			BackgroundColor3 = theme.newThumbnail.background,
			ImageColor3 = theme.newThumbnail.border,
			Image = BORDER,
			Size = UDim2.new(0, 150, 0, 150),

			[Roact.Event.MouseEnter] = self.mouseEnter,
			[Roact.Event.MouseLeave] = self.mouseLeave,

			[Roact.Event.Activated] = self.props.OnClick,
		}, {
			Plus = Roact.createElement("ImageLabel", {
				BackgroundTransparency = 1,
				ImageColor3 = theme.newThumbnail.plus,
				ImageTransparency = 0.4,
				Size = UDim2.new(0, 267, 0, 150),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = PLUS,
				ZIndex = 2,
			})
		})
	end)
end

return NewGameIcon