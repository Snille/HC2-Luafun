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
local debug = tonumber(fibaro:getGlobalValue("globaldebug")); -- Set to one to activate debugging (show all messages).
--local debug = 1 -- Set to one to activate debugging (show all messages).

-- Don't change anything below this!!

local sourceTrigger = fibaro:getSourceTrigger(); -- Check if autostart.
local tocheck = 0; -- Init variable.
local didSendNotification = 0;
local blinkstatus = 0; 

-- Check power consumption if plug is on.
function checkwatts(wattcheck)
  if (tonumber(fibaro:getValue(wattcheck, "value")) == 1) then
    wallplugwatt = tonumber(fibaro:getValue(wattcheck, "power"));
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
  if debug > 0 then fibaro:debug(thing.. " is on!"); end
  fibaro:sleep(15000); -- wait for a while to get power consumption up
  didSendNotification = 0;
  blinkstatus = 0; 
  status = checkstatus(id);
  function mainloop()
    if (status > 0 and didSendNotification == 0) then
      watts = checkwatts(id);
      if debug > 0 then fibaro:debug ("Now monitoring: " ..thing.. ".\nState is: " ..status.. " and watt is: " ..watts); end
      if (watts < triggerlimit and watts > 0) then
        if (notifytype == "email") then
          fibaro:call(touser, "sendEmail", messagenr);
        elseif (notifytype == "push") then
          fibaro:call(touser, "sendDefinedPushNotification", messagenr);
        else
          if debug > 0 then fibaro:debug (thing.. " is done! This debug message sent (either email nor push was selected).\nState is: " ..status.. " and watt is: " ..watts); end
        end
        if (enableblink > 0) then
          blinkstatus = checkstatus(blinkid);
          for loop = 1, numofblinks do
    		if debug > 0 then fibaro:debug("Blinking " ..blinkid.. " " ..loop.. "."); end
            fibaro:call(blinkid, "turnOn");
            fibaro:sleep(500);
            fibaro:call(blinkid, "turnOff");
            fibaro:sleep(500);
          end
          if (leaveon <= 0) then
            if debug > 0 then fibaro:debug("Keeping " ..blinkid.. " Off."); end
            fibaro:call(blinkid, "turnOff");
          elseif (leaveon == 1) then
            if debug > 0 then fibaro:debug("Keeping " ..blinkid.. " On."); end
            fibaro:call(blinkid, "turnOn");
          elseif (leaveon >= 2) then
            if (blinkstatus > 0) then
              if debug > 0 then fibaro:debug("Returning " ..blinkid.. " to On."); end
              fibaro:call(blinkid, "turnOn");
            else
              if debug > 0 then fibaro:debug("Returning " ..blinkid.. " to Off."); end
              fibaro:call(blinkid, "turnOff");
            end
          end
        end
        if debug > 0 then fibaro:debug(thing.. " is done! Messages nr: " ..messagenr.. " sent to user nr: " ..touser.. ".\nState is: " ..status.. " and watt is: " ..watts); end
        didSendNotification = 1;
        if debug > 0 then fibaro:debug("Looks like it's done!"); end
        return 1;
      end
      if debug > 0 then fibaro:debug("Not yet, wating..."); end
      fibaro:sleep(timer*1000);
      status = checkstatus(id);
      mainloop(); 
    else
	  didSendNotification = 0;
      if debug > 0 then fibaro:debug("Turned off again..."); end
      return 1;
    end
  end
  mainloop();
else
  if debug > 0 then fibaro:debug(thing.. " is off."); end
end