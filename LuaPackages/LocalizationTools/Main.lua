local LocalizationService = game:GetService("LocalizationService")
local AnalyticsService = game:GetService("AnalyticsService")
local IsEdit = require(script.Parent.IsEdit)

local LocalizationTools = require(script.Parent.Components.LocalizationTools)
local MakeShowDialog = require(script.Parent.ShowDialog)
local MakeGameTableMain = require(script.Parent.GameTable.GameTableMain)
local RbxEntriesToWebEntries = require(script.Parent.GameTable.RbxEntriesToWebEntries)
local Roact = require(game:GetService("CorePackages").Roact)

local FFlagStudioLocalizationPluginButtonAnalytics = settings():GetFFlag("StudioLocalizationPluginButtonAnalytics")
local FFlagStudioLocalizationToolsAnalytics = settings():GetFFlag("StudioLocalizationToolsAnalytics")

local function getTextScraperButtonIconAsset()
	return LocalizationService.IsTextScraperRunning
		and "rbxasset://textures/localizationUIScrapingOn.png"
		or "rbxasset://textures/localizationUIScrapingOff.png"
end


local function reportButtonPress(plugin, btnName, status)
	local target = "studio"
	local context = "localizationPlugin"
	local eventName = "buttonPressed"
	local args = {
		uid = plugin:GetStudioUserId(),
		gameId = game.GameId,
		placeId = game.PlaceId,

		btnName = btnName,
		status = status,
	}

	AnalyticsService:SendEventDeferred(target, context, eventName, args)
end


local function createTextScraperPluginButtons(toolbar)
	local captureButton = toolbar:CreateButton(
		"Text Capture",
		"Enable untranslated text capture",
		getTextScraperButtonIconAsset()
	)

	local exportButton = toolbar:CreateButton(
		"Export",
		"Export LocalizationTables under LocalizationService to CSV files",
		"rbxasset://textures/localizationExport.png"
	)

	local importButton = toolbar:CreateButton(
		"Import",
		"Import CSV files to LocalizationTables under LocalizationService",
		"rbxasset://textures/localizationImport.png"
	)

	return {
		captureButton = captureButton,
		exportButton = exportButton,
		importButton = importButton,
	}
end


local function createTextScraperControlsEnabled(toolbar, plugin)
	local buttons = createTextScraperPluginButtons(toolbar)

	buttons.captureButton.Enabled = true
	buttons.captureButton.Click:Connect(function()
		if not LocalizationService.IsTextScraperRunning then
			LocalizationService:StartTextScraper()
			if FFlagStudioLocalizationPluginButtonAnalytics then
				reportButtonPress(plugin, "textCapture", "start")
			end
		else
			LocalizationService:StopTextScraper()
			if FFlagStudioLocalizationPluginButtonAnalytics then
				reportButtonPress(plugin, "textCapture", "stop")
			end
		end
		buttons.captureButton.Icon = getTextScraperButtonIconAsset()
	end)

	buttons.exportButton.Enabled = true
	buttons.exportButton.Click:Connect(function()
		if FFlagStudioLocalizationPluginButtonAnalytics then
			local success, message = pcall(
				function()
					return LocalizationService:PromptExportToCSVs()
				end
			)
			if success then
				reportButtonPress(plugin, "export", "success")
			else
				if message == "No file selected" then
					reportButtonPress(plugin, "export", "canceled")
				else
					reportButtonPress(plugin, "export", "error")
				end
			end
		else
			LocalizationService:PromptExportToCSVs()
		end
	end)

	buttons.importButton.Enabled = true
	buttons.importButton.Click:Connect(function()
		if FFlagStudioLocalizationPluginButtonAnalytics then
			local success, message = pcall(
				function()
					return LocalizationService:PromptImportFromCSVs()
				end
			)
			if success then
				reportButtonPress(plugin, "import", "success")
			else
				if message == "No file selected" then
					reportButtonPress(plugin, "import", "canceled")
				else
					reportButtonPress(plugin, "import", "error")
				end
			end
		else
			LocalizationService:PromptImportFromCSVs()
		end
	end)
end


local function createTextScraperControlsDisabled(toolbar)
	local buttons = createTextScraperPluginButtons(toolbar)

	buttons.captureButton.Enabled = false
	buttons.exportButton.Enabled = false
	buttons.importButton.Enabled = false
end


local function createLocalizationToolsPluginButton(toolbar)
	return toolbar:CreateButton(
		"Tools",
		"Hide/show the Localization Testing view",
		"rbxasset://textures/localizationTestingIcon.png")
end

local function reportToolOpened(plugin, openMethod)
	local target = "studio"
	local context = "localizationPlugin"
	local eventName = "toolOpened"
	local args = {
		method = openMethod,
		uid = plugin:GetStudioUserId(),
		gameId = game.GameId,
		placeId = game.PlaceId,
	}

	AnalyticsService:SendEventDeferred(target, context, eventName, args)
end

local function reportUploadPatch(plugin, patchInfo, btnName)
	local target = "studio"
	local context = "localizationPlugin"
	local eventName = "logLocalizationPerfStats"
	local args = {
		uid = plugin:GetStudioUserId(),
		gameId = game.GameId,
		placeId = game.PlaceId,
		btnName = btnName,

		totalRows = patchInfo.totalRows,
		totalTranslations = patchInfo.totalTranslations,
		supportedLocales = patchInfo.supportedLocales,
		unsupportedLocales = patchInfo.unsupportedLocales,
		numChangedTranslations = patchInfo.numChangedTranslations,
		numRemovedTranslations = patchInfo.numRemovedTranslations,
		numAddedTranslations = patchInfo.numAddedTranslations,
	}

	AnalyticsService:SendEventDeferred(target, context, eventName, args)
end

local function reportDownloadTable(plugin, table, btnName)
	local target = "studio"
	local context = "localizationPlugin"
	local eventName = "logLocalizationPerfStats"

	local info = RbxEntriesToWebEntries(table:GetEntries())

	local args = {
		uid = plugin:GetStudioUserId(),
		gameId = game.GameId,
		placeId = game.PlaceId,
		btnName = btnName,

		totalRows = info.totalRows,
		totalTranslations = info.totalTranslations,
		supportedLocales = info.supportedLocales,
		unsupportedLocales = info.unsupportedLocales,
	}

	AnalyticsService:SendEventDeferred(target, context, eventName, args)
end

local function createLocalizationToolsEnabled(toolbar, plugin, studioSettings)
	local ShowDialog = MakeShowDialog(plugin, studioSettings)
	local GameTableMain = MakeGameTableMain(plugin:GetStudioUserId())
	local Window = plugin:CreateDockWidgetPluginGui("Localization",
		DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Left))
	Window.Title = "Localization Tools"
	Window.Name = "Localization"

	local localizationToolsHandle = Roact.mount(Roact.createElement(LocalizationTools, {
		Window = Window,
		ShowDialog = ShowDialog,
		OpenCSV = GameTableMain.OpenCSV,
		SaveCSV = GameTableMain.SaveCSV,
		ComputeReplacePatch = GameTableMain.ComputeReplacePatch,
		ComputeUpdatePatch = GameTableMain.ComputeUpdatePatch,
		UploadPatch = GameTableMain.UploadPatch,
		DownloadGameTable = GameTableMain.DownloadGameTable,
		UpdateGameTableInfo = GameTableMain.UpdateGameTableInfo,
		CheckTableAvailability = GameTableMain.CheckTableAvailability,
		GameIdChangedSignal = GameTableMain.GameIdChangedSignal,
		StudioSettings = studioSettings,
		HandleUploadAnalytics = function(patchInfo, btnName)
			if FFlagStudioLocalizationToolsAnalytics then
				reportUploadPatch(plugin, patchInfo, btnName)
			end
		end,
		HandleDownloadAnalytics = function(table, btnName)
			if FFlagStudioLocalizationToolsAnalytics then
				reportDownloadTable(plugin, table, btnName)
			end
		end,
	}), Window)

	local button = createLocalizationToolsPluginButton(toolbar)

	Window.AncestryChanged:Connect(function(child, parent)
		if child == Window and parent == nil then
			Roact.unmount(localizationToolsHandle)
		end
	end)

	Window:GetPropertyChangedSignal("Enabled"):connect(function()
		button:SetActive(Window.Enabled)
	end)

	button.Enabled = true
	button.Click:Connect(
		function()
			Window.Enabled = not Window.Enabled
			button:SetActive(Window.Enabled)

			if (Window.Enabled) then
				reportToolOpened(plugin, 1)
			end

			if FFlagStudioLocalizationPluginButtonAnalytics then
				if Window.Enabled then
					reportButtonPress(plugin, "tools", "open")
				else
					reportButtonPress(plugin, "tools", "closed")
				end
			end
		end)
end


local function createLocalizationToolsDisabled(toolbar)
	createLocalizationToolsPluginButton(toolbar).Enabled = false
end


return function(plugin, studioSettings)
	local toolbar = plugin:CreateToolbar("Localization")
	if IsEdit() then
		createTextScraperControlsEnabled(toolbar, plugin)
		createLocalizationToolsEnabled(toolbar, plugin, studioSettings)
	else
		createTextScraperControlsDisabled(toolbar)
		createLocalizationToolsDisabled(toolbar)
	end
end

