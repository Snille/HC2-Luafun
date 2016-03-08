# WallC-S (4-buttons)
1. First and foremost, you will have the "device" when you added it to the HC2 (the physical one). Check the ID.

2. Now create a virtual device (with a name ie. "WallC S-01 Function") with 8 buttons that symbolizes the physical device (I chose only 8 because you get a "number" when pressed briefly, and another "number" when you press a long press on each button. There is also a "number" when the button is released after a long press. But I saw no use for it in this scenario. it is in this unit we will put what should happen at every "touch", here we can also press "virtually" all the buttons. Note: WallC-S has 4 buttons = 8 functions = 8 virtual buttons. :)

I have created a device that you can import if you like, but remember to change all "devices" on all the buttons that you want to control.

2. Now create a Scene (with a name ie. "WallC S-01 Reader") that reads the switch and sends "numbers" to the virtual drive. This is what my LUA code looks like. Since WallC-S does not send a "1", "2", "3" ... and so on for each button-press, we have to "convert" to it before the number is sent to the virtual device.

Remember to change XXX to your units' ID!

— Start LUA Kod —
–[[
%% properties
140 sceneActivation
%% globals
–]]

——— Your Device ID’s Here ———

local virtualDevID = XXX — WallC-S4 01 Function (XXX = ID of your virtual device)
local wallcsID = XXX — WallC-S4 01 Fysisk (XXX = ID of your physical devcie)

—— Do not edit below this line ——

local buttonPressed = 0;

if (tonumber(fibaro:getValue(wallcsID, “sceneActivation”)) == 11) then
buttonPressed = 1;
elseif (tonumber(fibaro:getValue(wallcsID, “sceneActivation”)) == 13) then
buttonPressed = 2;
elseif (tonumber(fibaro:getValue(wallcsID, “sceneActivation”)) == 21) then
buttonPressed = 3;
elseif (tonumber(fibaro:getValue(wallcsID, “sceneActivation”)) == 23) then
buttonPressed = 4;
elseif (tonumber(fibaro:getValue(wallcsID, “sceneActivation”)) == 12) then
buttonPressed = 5;
elseif (tonumber(fibaro:getValue(wallcsID, “sceneActivation”)) == 14) then
buttonPressed = 6;
elseif (tonumber(fibaro:getValue(wallcsID, “sceneActivation”)) == 22) then
buttonPressed = 7;
elseif (tonumber(fibaro:getValue(wallcsID, “sceneActivation”)) == 24) then
buttonPressed = 8;
end
fibaro:debug(buttonPressed)
fibaro:call(virtualDevID, “pressButton”, buttonPressed)
— Slut LUA Kod —

This should be everything.
You will now have 1 physical device: "WallC S-01 Physical", then you will have a read-device: "WallC-S 01 Reader" and last but not least, you have a virtual drive for example: "WallC-S 01" function that performs the actual "control" of your devices. :)
Good luck!