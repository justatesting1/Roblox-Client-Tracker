-- singleton
local FastFlags = require(script.Parent.Parent.FastFlags)

local Keyboard = {}

Keyboard.Connection = {}
Keyboard.KeysDown = {}
Keyboard.PluginGuiKeysDown = {}
Keyboard.KeyPressedEvent = nil
Keyboard.KeyReleasedEvent = nil
Keyboard.CtrlAndCmdKeys = {
	Enum.KeyCode.RightControl,
	Enum.KeyCode.LeftControl,
	Enum.KeyCode.RightSuper,
	Enum.KeyCode.LeftSuper
}

Keyboard.ShiftKeys = {
	Enum.KeyCode.LeftShift,
	Enum.KeyCode.RightShift,
}

Keyboard.BackSpaceAndDeleteKeys = {
	Enum.KeyCode.Backspace,
	Enum.KeyCode.Delete
}

function Keyboard:init(Paths)
	Keyboard.Paths = Paths

	local userInputService = game:GetService('UserInputService')

	Keyboard.KeyPressedEvent = Paths.UtilityScriptEvent:new(Paths)
	Keyboard.KeyReleasedEvent = Paths.UtilityScriptEvent:new(Paths)

	local function inputHandler(input, handled)
		if handled or (FastFlags:isIKModeFlagOn() and self.Paths.DataModelSession:inputLocked()) then
			return
		end

		if input.UserInputState == Enum.UserInputState.Begin then
			Keyboard.KeysDown[input.KeyCode] = true
			Keyboard.KeyPressedEvent:fire(input.KeyCode)
		elseif input.UserInputState == Enum.UserInputState.End then
			Keyboard.KeysDown[input.KeyCode] = nil
			Keyboard.KeyReleasedEvent:fire(input.KeyCode)
		end
	end

	local function pluginGuiInputHandler(input, handled)
		if not handled then
			if input.UserInputState == Enum.UserInputState.Begin then
				Keyboard.PluginGuiKeysDown[input.KeyCode] = true
			elseif input.UserInputState == Enum.UserInputState.End then
				Keyboard.PluginGuiKeysDown[input.KeyCode] = nil
			end
		end

		inputHandler(input, handled)
	end

	Keyboard.Connection = Paths.UtilityScriptConnections:new(Paths)

	-- attach input handler to the 3d viewport
	Keyboard.Connection:add(userInputService.InputBegan:connect(inputHandler))
	Keyboard.Connection:add(userInputService.InputChanged:connect(inputHandler))
	Keyboard.Connection:add(userInputService.InputEnded:connect(inputHandler))

	-- attach input handler to the lua widgets frame
	if FastFlags:isFlyCameraOn() then
		Keyboard.Connection:add(Paths.GUI.InputBegan:connect(pluginGuiInputHandler))
		Keyboard.Connection:add(Paths.GUI.InputChanged:connect(pluginGuiInputHandler))
		Keyboard.Connection:add(Paths.GUI.InputEnded:connect(pluginGuiInputHandler))
	else
		Keyboard.Connection:add(Paths.GUI.InputBegan:connect(inputHandler))
		Keyboard.Connection:add(Paths.GUI.InputChanged:connect(inputHandler))
		Keyboard.Connection:add(Paths.GUI.InputEnded:connect(inputHandler))
	end
end

function Keyboard:terminate()
	Keyboard.Connection:terminate()
	Keyboard.Connection = nil

	Keyboard.KeysDown = {}

	Keyboard.KeyReleasedEvent = nil
	Keyboard.KeyPressedEvent = nil
	Keyboard.Paths = nil
end

function Keyboard:isKeyDown(key)
	return nil ~= Keyboard.KeysDown[key]
end

function Keyboard:isKeyDownForPluginGui(key)
	return nil ~= Keyboard.PluginGuiKeysDown[key]
end

function Keyboard:isKeyShiftDown()
	return Keyboard.Paths.HelperFunctionsIteration:ifAny(Keyboard.ShiftKeys, function(_, shiftKey) return Keyboard.KeysDown[shiftKey] end)
end

function Keyboard:isKeyCtrlOrCmdDown()
	return Keyboard.Paths.HelperFunctionsIteration:ifAny(Keyboard.CtrlAndCmdKeys, function(_, ctrlOrCmdKey) return Keyboard.KeysDown[ctrlOrCmdKey] end)
end

function Keyboard:isKeyCtrlOrCmd(key)
	return Keyboard.Paths.HelperFunctionsIteration:ifAny(Keyboard.CtrlAndCmdKeys, function(_, ctrlOrCmdKey) return key == ctrlOrCmdKey end)
end

function Keyboard:isKeyBackSpaceOrDelete(key)
	return Keyboard.Paths.HelperFunctionsIteration:ifAny(Keyboard.BackSpaceAndDeleteKeys, function(_, backSpaceOrDeleteKey) return key == backSpaceOrDeleteKey end)
end

-- If several of these are created, a new file should be added to store the keyboard/behavior bindings.
-- This abstraction is also useful if we ever decide to provide user defined key bindings.
function Keyboard:isKeyPlayPause(key)
	if FastFlags:isPlayPauseSpaceHotkeyEnabled() then
		return Enum.KeyCode.P == key or Enum.KeyCode.Space == key
	else
		return Enum.KeyCode.P == key
	end
end

function Keyboard:getNavKeys()
	return self.Paths.InputNavKeys:new(Keyboard)
end

return Keyboard
