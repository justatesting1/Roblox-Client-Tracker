--[[
	A toggleable drawer which is used to set search options like creator and sort order.

	Props:
		table LiveSearchData = A table of live search data received from the live
			search request. Should contain a results table and searchTerm string.
		int SortIndex = The currently set sort type index in the current pageInfo.

		function updateSearch(string searchTerm) = A callback when the live search
			for Creator should be updated.
		function onClose(table options) = A callback for when the drawer is closed.
			If cancelled, options will be nil. Else, it will contain the new options
			that were set by the user.
]]

local FFlagStudioMarketplaceTabsEnabled = settings():GetFFlag("StudioMarketplaceTabsEnabled")

local Plugin = script.Parent.Parent.Parent.Parent

local Libs = Plugin.Libs
local Roact = require(Libs.Roact)

local ContextGetter = require(Plugin.Core.Util.ContextGetter)
local ContextHelper = require(Plugin.Core.Util.ContextHelper)
local getModal = ContextGetter.getModal
local withTheme = ContextHelper.withTheme
local withLocalization = ContextHelper.withLocalization
local withModal = ContextHelper.withModal

local createFitToContent = require(Plugin.Core.Components.createFitToContent)

local Constants = require(Plugin.Core.Util.Constants)

local LiveSearchBar = require(Plugin.Core.Components.SearchOptions.LiveSearchBar)
local RadioButtons = require(Plugin.Core.Components.SearchOptions.RadioButtons)
local SearchOptionsEntry = require(Plugin.Core.Components.SearchOptions.SearchOptionsEntry)
local SearchOptionsFooter = require(Plugin.Core.Components.SearchOptions.SearchOptionsFooter)

local SearchOptions = Roact.PureComponent:extend("SearchOptions")

local FitToContent = createFitToContent("ImageButton", "UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	Padding = UDim.new(0, 10),
	BorderSize = Constants.MAIN_VIEW_PADDING,
	SortOrder = Enum.SortOrder.LayoutOrder,
})

function SearchOptions:init(initialProps)
	self.layoutRef = Roact.createRef()
	self.containerRef = Roact.createRef()
	self.currentLayout = 0
	self.searchTerm = initialProps.LiveSearchData.searchTerm

	local modal = getModal(self)

	self.mouseEnter = function()
		modal.onSearchOptionsMouse(true)
	end

	self.mouseLeave = function()
		modal.onSearchOptionsMouse(false)
	end

	self.updateSearch = function(searchTerm)
		self.searchTerm = searchTerm
		if self.props.updateSearch then
			self.props.updateSearch(searchTerm)
		end
	end

	self.state = {
		SortIndex = nil,
	}

	self.selectSort = function(_, index)
		self:setState({
			SortIndex = index,
		})
	end

	self.apply = function(options)
		if self.props.onClose then
			self.props.onClose(options)
		end
	end

	self.cancel = function()
		if self.props.onClose then
			self.props.onClose()
		end
	end

	self.footerButtonClicked = function(button)
		local options = {
			SortIndex = self.state.SortIndex,
			Creator = self.searchTerm,
		}
		self:setState({
			SortIndex = Roact.None,
			Creator = Roact.None,
		})
		if button == "Cancel" then
			self.cancel()
		elseif button == "Apply" then
			self.apply(options)
		end
	end
end

function SearchOptions:createSeparator(color)
	return Roact.createElement("Frame", {
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		LayoutOrder = self:nextLayout(),
	})
end

function SearchOptions:resetLayout()
	self.currentLayout = 0
end

function SearchOptions:nextLayout()
	self.currentLayout = self.currentLayout + 1
	return self.currentLayout
end

function SearchOptions:render()
	return withTheme(function(theme)
		return withLocalization(function(_, localizedContent)
			return withModal(function(modalTarget)
				local optionsTheme = theme.searchOptions
				local liveSearchData = self.props.LiveSearchData

				local sorts = {
					{Key = "Relevance", Text = localizedContent.Sort.Relevance},
					{Key = "MostTaken", Text = localizedContent.Sort.MostTaken},
					{Key = "Favorites", Text = localizedContent.Sort.Favorites},
					{Key = "Updated", Text = localizedContent.Sort.Updated},
					{Key = "Ratings", Text = localizedContent.Sort.Ratings},
				}
				local sortIndex = self.state.SortIndex or self.props.SortIndex
				local selectedSort = sorts[sortIndex].Key

				local tabHeight = FFlagStudioMarketplaceTabsEnabled and Constants.TAB_WIDGET_HEIGHT or 0

				self:resetLayout()

				local searchOptions = {
					Main = Roact.createElement("Frame", {
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.new(1, 0, 0, tabHeight + Constants.HEADER_HEIGHT),
						Size = UDim2.new(0, Constants.TOOLBOX_MIN_WIDTH, 1, 0),
					}, {
						Container = Roact.createElement(FitToContent, {
							BackgroundColor3 = optionsTheme.background,
							BorderColor3 = optionsTheme.border,
							AutoButtonColor = false,

							[Roact.Event.MouseEnter] = self.mouseEnter,
							[Roact.Event.MouseLeave] = self.mouseLeave,
						}, {
							Creator = Roact.createElement(SearchOptionsEntry, {
								LayoutOrder = self:nextLayout(),
								Header = localizedContent.SearchOptions.Creator,
								ZIndex = 2,
							}, {
								SearchBar = Roact.createElement(LiveSearchBar, {
									defaultTextKey = "SearchBarCreatorText",
									searchTerm = liveSearchData.searchTerm,
									results = liveSearchData.results,
									updateSearch = self.updateSearch,
									width = Constants.SEARCH_BAR_WIDTH,
								}),
							}),

							Separator1 = self:createSeparator(optionsTheme.separator),

							SortBy = Roact.createElement(SearchOptionsEntry, {
								LayoutOrder = self:nextLayout(),
								Header = localizedContent.SearchOptions.Sort,
							}, {
								RadioButtons = Roact.createElement(RadioButtons, {
									Buttons = sorts,
									Selected = selectedSort,
									onButtonClicked = self.selectSort,
								}),
							}),

							Separator2 = self:createSeparator(optionsTheme.separator),

							Footer = Roact.createElement(SearchOptionsFooter, {
								LayoutOrder = self:nextLayout(),
								onButtonClicked = self.footerButtonClicked,
							}),
						})
					})
				}

				return Roact.createElement("Frame", {
					BackgroundTransparency = 1,
				}, {
					Portal = modalTarget and Roact.createElement(Roact.Portal, {
						target = modalTarget,
					}, {
						ClickEventDetectFrame = Roact.createElement("ImageButton", {
							ZIndex = 10,
							Position = UDim2.new(0, 0, 0, 0),
							Size = UDim2.new(1, 0, 1, 0),
							BackgroundTransparency = 1,
							AutoButtonColor = false,

							[Roact.Event.Activated] = self.cancel,
						}, searchOptions),
					}),
				})
			end)
		end)
	end)
end

return SearchOptions
