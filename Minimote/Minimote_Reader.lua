--[[
%% properties
162 sceneActivation
%% globals
--]]
 
--------- Your Device ID's Here ---------
 
local virtualDevID = 69  -- Minimote 01 Function
local minimoteID = 162   -- Minimote 01 Physical
 
------ Do not edit below this line ------

local buttonPressed = fibaro:getValue(minimoteID, "sceneActivation")
fibaro:debug(buttonPressed)
fibaro:call(virtualDevID, "pressButton", buttonPressed)
