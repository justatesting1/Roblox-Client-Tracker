local CorePackages = game:GetService("CorePackages")
local Signal = require(CorePackages.AppTempCommon.Common.Signal)

local Library = script.Parent
local Roact = require(Library.Parent.Roact)
local Symbol = require(Library.Parent.Roact.Symbol)
local themeKey = Symbol.named("UILibraryTheme")

local ThemeProvider = Roact.PureComponent:extend("UILibraryThemeProvider")
function ThemeProvider:init()
	local theme = self.props.theme
	assert(theme ~= nil, "No theme was given to this ThemeProvider.")
	self.themeChanged = Signal.new()

	self._context[themeKey] = {
		initialValues = theme,
		themeChanged = self.themeChanged,
	}
end
function ThemeProvider:render()
	self.themeChanged:fire(self.props.theme)
	return Roact.oneChild(self.props[Roact.Children])
end

-- the consumer should complain if it doesn't have a theme
local ThemeConsumer = Roact.PureComponent:extend("UILibraryThemeConsumer")
function ThemeConsumer:init()
	assert(self._context[themeKey] ~= nil, "No ThemeProvider found.")
	local theme = self._context[themeKey]

	self.state = {
		themeValues = theme.initialValues,
	}

	self.themeConnection = theme.themeChanged:connect(function(newValues)
		self:setState({
			themeValues = newValues,
		})
	end)
end
function ThemeConsumer:render()
	local themeValues = self.state.themeValues
	return self.props.themedRender(themeValues)
end
function ThemeConsumer:willUnmount()
	if self.themeConnection then
		self.themeConnection:disconnect()
	end
end

-- withTheme should provide a simple way to style elements
-- callback : function<RoactElement>(theme)
local function withTheme(callback)
	return Roact.createElement(ThemeConsumer, {
		themedRender = callback
	})
end

return {
	Provider = ThemeProvider,
	Consumer = ThemeConsumer,
	withTheme = withTheme,
}