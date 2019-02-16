--[[
%% properties
263 value
252 valueSensor
%% events
%% weather
%% globals
--]]

-- Edit the variables below.
-- Dont forget to change the numbers before "value" (Espresso Machine ID) and "valuesensor" (ID to blink) above to the same number as ID below!!
local id = 263 -- Thing Wall plug ID. (Default: 263)
local timer = 10 -- How often to check watt usage in seconds when machine is on (300 = 5 minutes).
local thing = "Espresso Machine" -- The things name we are monitoring (for the debugging text output).
local triggerlimit = 100 -- Less then this watt value trigger the notification to be sent (Default: 100)
local enableblink = 1 -- Set to one if you want to blink the Wall plug ID below when the machine is ready.
local blinkid = 252 -- The Wall plug ID to blink when the machine is ready.
local numofblinks = 3 -- If blinking is enabled. This is how many times it blinks.
local leaveon = 2 -- When ID has blinked, set to 1 if you want the ID on, set to 0 if you want ID to off or set to 2 if you want ID to previous state (before blinking).
local notifytype = "push" -- Can be set to either "email" or "push".
local messagenr = "269" -- Message number from notification list.
local touser = fibaro:getGlobalValue("msguser01"); -- The user to receive the done-message (I make global variable for this).

-- Don't change anything below this!!

local sourceTrigger = fibaro:getSourceTrigger(); -- Check if autostart.
local tocheck = 0; -- Init variable.

-- Check power consumtion if plug is on.
function checkwatts()
  if (tonumber(fibaro:getValue(id, "value")) == 1) then
    wallplugwatt = tonumber(fibaro:getValue(id, "power"));
    return wallplugwatt
  end
  return 0;
end

-- Check if plug is on
function checkstatus(tocheck)
  if (tonumber(fibaro:getValue(tocheck, "value")) == 1) then
    return 1;
  else 
    return 0;
  end
   return -1;
end

-- Starts the check.
if (tonumber(fibaro:getValue(id, "value")) > 0) then
  fibaro:debug(thing.. " is on!");
  fibaro:sleep(15000); -- wait for a while to get power consumption up
  local didSendNotification = 0;
  local blinkstatus = 0; 
  status = checkstatus(id);
  function mainloop()
    if (status > 0 and didSendNotification == 0) then
      watts = checkwatts();
      fibaro:debug ("Now monitoring: " ..thing.. ".\nState is: " ..status.. " and watt is: " ..watts);
      if (watts < triggerlimit and watts > 0) then
        if (notifytype == "email") then
          fibaro:call(touser, "sendEmail", messagenr);
        elseif (notifytype == "push") then
          fibaro:call(touser, "sendDefinedPushNotification", messagenr);
        else
          fibaro:debug (thing.. " is done! This debug message sent (either email nor push was selected).\nState is: " ..status.. " and watt is: " ..watts);
        end
        if (enableblink > 0) then
          blinkstatus = checkstatus(blinkid);
          for loop = 1, numofblinks do
    		fibaro:debug("Blinking " ..blinkid.. " " ..loop.. ".");
            fibaro:call(blinkid, "turnOn");
            fibaro:sleep(500);
            fibaro:call(blinkid, "turnOff");
            fibaro:sleep(500);
          end
          if (leaveon <= 0) then
            fibaro:debug("Keeping " ..blinkid.. " Off.");
            fibaro:call(blinkid, "turnOff");
          elseif (leaveon == 1) then
            fibaro:debug("Keeping " ..blinkid.. " On.");
            fibaro:call(blinkid, "turnOn");
          elseif (leaveon >= 2) then
            if (blinkstatus > 0) then
              fibaro:debug("Returning " ..blinkid.. " to On.");
              fibaro:call(blinkid, "turnOn");
            else
              fibaro:debug("Returning " ..blinkid.. " to Off.");
              fibaro:call(blinkid, "turnOff");
            end
          end
        end
        fibaro:debug (thing.. " is done! Messages nr: " ..messagenr.. " sent to user nr: " ..touser.. ".\nState is: " ..status.. " and watt is: " ..watts);
        didSendNotification = 1;
        fibaro:debug("Looks like it's done!");
        return 1;
      end
      fibaro:debug("Not yet, wating...");
      fibaro:sleep(timer*1000);
      status = checkstatus(id);
      mainloop(); 
    else
      fibaro:debug("Turned off again...");
      return 1;
    end
  end
  mainloop();
else
  fibaro:debug(thing.. " is off.");
end
