--[[
	A text entry that is only one line.
	Used in a RoundTextBox when Multiline is false.

	Props:
		string Text = The text to display
		bool Visible = Whether to display this component
		function SetText(text) = Callback to tell parent that text has changed
		function FocusChanged(focus) = Callback to tell parent that this component has focus
]]

local FFlagGameSettingsFixNameWhitespace = settings():GetFFlag("GameSettingsFixNameWhitespace")

local Library = script.Parent.Parent
local Roact = require(Library.Parent.Roact)

local TextEntry = Roact.PureComponent:extend("TextEntry")

function TextEntry:init()
	self.textBoxRef = Roact.createRef()
	self.onTextChanged = function(rbx)
		if rbx.TextFits then
			rbx.TextXAlignment = Enum.TextXAlignment.Left
		else
			rbx.TextXAlignment = Enum.TextXAlignment.Right
		end
		if rbx.Text ~= self.props.Text then
			if FFlagGameSettingsFixNameWhitespace then
				local processed = string.gsub(rbx.Text, "[\n\r]", " ")
				self.props.SetText(processed)
			else
				self.props.SetText(rbx.Text)
			end
		end
	end

	self.mouseEnter = function()
		self.props.HoverChanged(true)
	end
	self.mouseLeave = function()
		self.props.HoverChanged(false)
	end
end

function TextEntry:render()
	local textSize = self.props.TextSize
	local font = self.props.Font

	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, {
		Text = Roact.createElement("TextBox", {
			Visible = self.props.Visible,

			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			ClearTextOnFocus = false,
			Font = font,
			TextSize = textSize,
			TextColor3 = self.props.TextColor3,
			Text = self.props.Text,
			TextXAlignment = Enum.TextXAlignment.Left,

			[Roact.Ref] = self.textBoxRef,

			[Roact.Event.MouseEnter] = self.mouseEnter,
			[Roact.Event.MouseLeave] = self.mouseLeave,

			[Roact.Event.Focused] = function()
				self.props.FocusChanged(true)
			end,

			[Roact.Event.FocusLost] = function()
				local textBox = self.textBoxRef.current
				textBox.TextXAlignment = Enum.TextXAlignment.Left
				self.props.FocusChanged(false)
			end,

			[Roact.Change.Text] = self.onTextChanged,
		}),
	})
end

return TextEntry
