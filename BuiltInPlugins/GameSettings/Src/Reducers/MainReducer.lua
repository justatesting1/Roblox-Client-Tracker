--[[
	Reducer that combines the Settings and Status reducers.
]]

local Plugin = script.Parent.Parent.Parent
local Rodux = require(Plugin.Rodux)

local Settings = require(Plugin.Src.Reducers.Settings)
local Status = require(Plugin.Src.Reducers.Status)

local fastFlags = require(Plugin.Src.Util.FastFlags)

local ReducerMorpher = require(Plugin.MorpherEditor.Code.Reducers.ReducerRootExternal)

return Rodux.combineReducers({
	Settings = Settings,
	Status = Status,
    StateMorpher = ReducerMorpher
})