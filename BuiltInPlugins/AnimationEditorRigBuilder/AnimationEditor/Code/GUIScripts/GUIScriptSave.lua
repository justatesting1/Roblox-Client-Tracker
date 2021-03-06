-- singleton
local FastFlags = require(script.Parent.Parent.FastFlags)

local Save = {}

function Save:init(Paths)
	self.Paths = Paths
end

local function destroyGUI(self)
	if nil ~= self.Connections then
		self.Connections:terminate()
		self.Connections = nil		
	end
	
	if not FastFlags:useQWidgetsForPopupsOn() then
		if nil ~= self.KillScreenUtil then
			self.KillScreenUtil:terminate()
			self.KillScreenUtil = nil
		end
	end
	
	if nil ~= self.GUI then
		self.GUI.Parent = nil
		self.GUI:Destroy()
		self.GUI = nil

		self.CancelButton:terminate()
		self.SaveButton:terminate()
	end

	if not FastFlags:useQWidgetsForPopupsOn() then
		if nil ~= self.resize then
			self.resize:terminate()
			self.resize = nil
		end
	end

	if FastFlags:useQWidgetsForPopupsOn() then
		if self.QtWindow then
			self.QtWindow:terminate()
			self.QtWindow = nil
		end
	end
end

local function exitFunction(self, givenName)
	if givenName ~= nil then
		self.Paths.DataModelClip:saveCurrentAnimation(givenName)
	end
	
	destroyGUI(self)
end

function Save:show()
	local rig = nil
	if FastFlags:isEnableRigSwitchingOn() then
		rig = self.Paths.DataModelRig:getModel()
	else
		rig = self.Paths.DataModelRig:getItem().Item.Parent
	end
	local gui = self.Paths.GUIPopUpSave:clone()
	self.GUI = gui
	if not FastFlags:useQWidgetsForPopupsOn() then
		self.Paths.UtilityScriptTheme:setColorsToTheme(self.GUI)
		self.KillScreenUtil = self.Paths.WidgetKillScreen:new(self.Paths, gui.KillScreen, true)
	end
	self.Connections = self.Paths.UtilityScriptConnections:new(self.Paths)

	self.CancelButton = self.Paths.WidgetCustomImageButton:new(self.Paths, self.GUI.Cancel)
	self.SaveButton = self.Paths.WidgetCustomImageButton:new(self.Paths, self.GUI.Save)
	self.SaveButton:setEnabled(false)
	
	if rig:FindFirstChild("AnimSaves") ~= nil then
		local items = rig.AnimSaves:GetChildren()
		local sf = function(a, b) return a.Name < b.Name end
		table.sort(items, sf)
		local count = 0
		for i, v in pairs(items) do
			if v:IsA("KeyframeSequence") and v.Name ~= "Automatic Save" then
				local btn = gui.Template:clone()
				btn.Text = v.Name
				btn.Position = UDim2.new(0.5, 0, 0, 23 * (count))
				btn.Parent = gui.ScrollingFrame
				btn.Visible = true
				self.Connections:add(btn.MouseButton1Click:connect(function()
					gui.TextBox.Text = btn.Text
					if self.SelectedButton then
						self.SelectedButton.BackgroundColor3 = self.Paths.UtilityScriptTheme:GetBackgroundColor()
						self.SelectedButton.TextColor3 = self.Paths.UtilityScriptTheme:GetTextColor()
					end
					self.SelectedButton = btn
					self.SelectedButton.BackgroundColor3 = self.Paths.UtilityScriptTheme:GetJointSelectedColor()
					self.SelectedButton.TextColor3 = self.Paths.UtilityScriptTheme:GetHighlightedTextColor()
				end))

				self.Connections:add(btn.MouseEnter:connect(function(x, y)
					if btn ~= self.SelectedButton then
						btn.BackgroundColor3 = self.Paths.UtilityScriptTheme:GetHoverColor()
					end
				end))

				self.Connections:add(btn.MouseLeave:connect(function(x, y)
					if btn ~= self.SelectedButton then
						btn.BackgroundColor3 = self.Paths.UtilityScriptTheme:GetBackgroundColor()
					end
				end))
				count = count + 1
			end
		end
	end
	
	local cancelFunc = function()
		exitFunction(self, nil)
	end

	self.Connections:add(self.GUI.TextBox.Changed:connect(function(property)
		if property == "Text" then
			if self.GUI.TextBox.Text ~= "" then
				self.SaveButton:setEnabled(true)
				if FastFlags:isFixAnimationsWithLongNamesOn() then
					local textWidth = self.GUI.TextBox.TextBounds.X
					if textWidth > self.GUI.TextBox.AbsoluteSize.X then
						self.GUI.TextBox.TextXAlignment = Enum.TextXAlignment.Right
					else
						self.GUI.TextBox.TextXAlignment = Enum.TextXAlignment.Left
					end
				end
			else
				self.SaveButton:setEnabled(false)
			end
		end
	end))

	self.Connections:add(self.GUI.TextBox.Focused:connect(function()
		self.GUI.TextBox.BorderColor3 = self.Paths.UtilityScriptTheme:GetHighlightColor()
	end))

	self.Connections:add(self.GUI.TextBox.FocusLost:connect(function(enterPressed, cause)
		self.GUI.TextBox.BorderColor3 = self.Paths.UtilityScriptTheme:GetInputBorderColor()
	end))
	
	self.Connections:add(gui.Save.MouseButton1Click:connect(function()
		local txt = gui.TextBox.Text
		if self.SaveButton:getEnabled() then
			exitFunction(self, txt)
		end
	end))
	
	self.Connections:add(gui.Cancel.MouseButton1Click:connect(cancelFunc))

	if FastFlags:useQWidgetsForPopupsOn() then
		if FastFlags:isFixAnimationsWithLongNamesOn() then
			self.QtWindow = self.Paths.GUIScriptQtWindow:new(self.Paths, "Save", self.GUI, cancelFunc, Vector2.new(200, 300), true)
		else
			self.QtWindow = self.Paths.GUIScriptQtWindow:new(self.Paths, "Save", self.GUI, cancelFunc)
		end
		self.QtWindow:turnOn(true)
	else
		self.Connections:add(self.KillScreenUtil.OnKillEvent:connect(cancelFunc))		
		
		local numOverwrite = #gui.ScrollingFrame:GetChildren()
		gui.ScrollingFrame.CanvasSize = UDim2.new(0,0,0,23 * numOverwrite)
		
		gui.Parent = self.Paths.GUIPopUps

		local minHeight = 150
		self.resize = self.Paths.UtilityScriptResize:new(gui, minHeight, self.Paths.GUIScrollingJointTimeline)
	end
end

function Save:terminate()
	self.Paths = nil
end

return Save
