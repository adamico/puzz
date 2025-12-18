--[[pod_format="raw",created="2025-12-18 13:10:40",modified="2025-12-18 13:14:13",revision=3]]
include("src/constants.lua")
include("lib/require.lua")
include("lib/debugui.lua")
include("lib/eggs.p8/eggs.lua")

add_module_path("lib/")
add_module_path("src/")
add_module_path("src/entities/")
add_module_path("src/scenes/")
add_module_path("src/systems/")

Class = require("middleclass")
Stateful = require("stateful")

Log = require("log")
Log.init("trace")
Log.trace("Log.init: current_level = "..Log.current_level)

local Sound
-- local SoundManager = require("sound_manager")
local sound_enabled = false

local SceneManager = require("scene_manager")
local Title = require("title")
local Play = require("play")
local GameOver = require("game_over")

local starting_scene = "Play"
local Scene = SceneManager:new()

function _init()
   -- Sound = SoundManager:new(sound_enabled)
   Scene:gotoState(starting_scene)
end

function _update()
   Scene:update()
end

function _draw()
   Scene:draw()
   debugui.run()
end

include("lib/error_explorer.lua")
