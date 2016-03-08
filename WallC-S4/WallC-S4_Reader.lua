--[[
%% properties
140 sceneActivation
%% globals
--]]
 
--------- Your Device ID's Here ---------

local virtualDevID = 152  -- WallC-S4 01 Function
local wallcsID = 140    -- WallC-S4 01 Physical
 
------ Do not edit below this line ------

local buttonPressed = 0;

if (tonumber(fibaro:getValue(wallcsID, "sceneActivation")) == 11) then
  buttonPressed = 1;
elseif (tonumber(fibaro:getValue(wallcsID, "sceneActivation")) == 13) then
  buttonPressed = 2;
elseif (tonumber(fibaro:getValue(wallcsID, "sceneActivation")) == 21) then
  buttonPressed = 3;
elseif (tonumber(fibaro:getValue(wallcsID, "sceneActivation")) == 23) then
  buttonPressed = 4;
elseif (tonumber(fibaro:getValue(wallcsID, "sceneActivation")) == 12) then
  buttonPressed = 5;
elseif (tonumber(fibaro:getValue(wallcsID, "sceneActivation")) == 14) then
  buttonPressed = 6;
elseif (tonumber(fibaro:getValue(wallcsID, "sceneActivation")) == 22) then
  buttonPressed = 7;
elseif (tonumber(fibaro:getValue(wallcsID, "sceneActivation")) == 24) then
  buttonPressed = 8;
end
fibaro:debug(buttonPressed)
fibaro:call(virtualDevID, "pressButton", buttonPressed)

