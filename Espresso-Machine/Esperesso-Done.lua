--[[
%% properties
299 value
252 valueSensor
%% events
%% globals
--]]

-- Dont forget to change the numbers before "value" (Espresso Machine ID) and "valuesensor" (ID to blink) above to the same number as ID below!!
local id = 299; -- Thing Wall plug ID (Espresso Machine).
local masterid = 298; -- Thing Wall plug Master ID to be able to pull watt usage often.
local timer = 10; -- How often to check watt usage in seconds when machine is on (300 = 5 minutes, default: 10).
local thing = "Espresso Machine"; -- The thing we are monitoring (for the debugging text output).
local grinder = "Grinder"; -- The grinders name (for the debugging text output).
local triggerlimit = 100; -- Less then this watt value trigger the notification to be sent (Default: 100)
local enableblink = 1; -- Set to one if you want to blink the Wall plug ID below when the machine is ready.
local blinkid = 252; -- The Wall plug ID to blink when the machine is ready.
local numofblinks = 3; -- If blinking is enabled. This is how many times it blinks.
local leaveon = 2; -- When ID has blinked, set to 1 if you want the ID to stay on, set to 0 if you want the ID to stay off or set to 2 if you want ID to return to previous state (before blinking).
local notifytype = "push"; -- How the message should be delivered. Either "email" or "push" (default push).
local messagenr = "269"; -- Message number from notification list to deliver.
local touser = fibaro:getGlobalValue("msguser01"); -- The user to send the done-message to (I make global variable called "msguser01" for this).
local grinderon = 1; -- If set to 1, when espressomachine is hot, turn on the grinder.
local grinderoff = 1; -- If set to 1, when espressomachine is turned off, turn off the grinder as well.
local grinderid = 277; -- The ID of the grinder wall plug.
local sonossay = 1; -- Set to 1 if you want a message read on the Sonos player (using a Virtual Device for this action).
local sonosvirDevID = 294;  -- Sonos Virtual Action Device ID.
local sonosactionid = 1; -- The "button-ID" on the Sonos Virtual Action Device to be triggered (basically the defined action sound to play in the VDevice).
local latest = tonumber(fibaro:getGlobalValue("timelatest")); -- Set a global variable called "timelatest" with the latest hour (24h time) a sound is allowed to be played.
local earliest = tonumber(fibaro:getGlobalValue("timeearliest")); -- Set a global variable called "timeearliest" to the earliest hour (24h time) a sound is allowed to be played.
local debug = tonumber(fibaro:getGlobalValue("globaldebug")); -- Set the global variable called "globaldebug" to one to activate debugging (show all messages).
--local debug = 1; -- Set to one to activate debugging (show all messages). Enable this line to override the global debug variable.

-- Don't change anything below this line!!

local tocheck = 0;
local didSendNotification = 0;
local blinkstatus = 0; 

-- Checking the start type.
local trigger = fibaro:getSourceTrigger();
if (trigger['type'] == 'property') then
  if debug > 0 then fibaro:debug('Scene triggered by = ' .. trigger['deviceID']); end
elseif (trigger['type'] == 'global') then
  if debug > 0 then fibaro:debug('Scene triggered by source global variable = ' .. trigger['name']); end
elseif (trigger['type'] == 'other') then
  if debug > 0 then fibaro:debug('Scene triggered by other source'); end
end

-- Check power consumption if plug is on.
function checkwatts(wattcheck, wattmasterid)
  if (tonumber(fibaro:getValue(wattcheck, "value")) == 1) then
    fibaro:call(wattmasterid, "poll");
    wallplugwatt = tonumber(fibaro:getValue(wattcheck, "power"));
    return wallplugwatt;
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

-- Espresso Machine warm up loop.
function warmloop()
  if (status > 0 and didSendNotification == 0) then
    if debug > 0 then fibaro:debug ("Monitoring: " ..thing.. ".\nState is: " ..status.. " and watt is: " ..watts); end
    if (watts < triggerlimit and watts > 0) then
      -- Sends the notification.
      if (notifytype == "email") then
        fibaro:call(touser, "sendDefinedEmailNotification", messagenr);
      elseif (notifytype == "push") then
        fibaro:call(touser, "sendDefinedPushNotification", messagenr);
      else          
        if debug > 0 then fibaro:debug (thing.. " is done! This debug message sent (either email nor push was selected).\nState is: " ..status.. " and watt is: " ..watts); end
      end
      -- Sets the sent notification variable to 1.
      if debug > 0 then fibaro:debug(thing.. " is warm!\nMessages nr: " ..messagenr.. " sent to user nr: " ..touser.. ".\nState is: " ..status.. " and watt is: " ..watts); end
      didSendNotification = 1;
      -- Plays the message on SONOS if enabled.
      if (sonossay > 0) then
        local currenthour = os.date("%H");
        if ((tonumber(currenthour) <= latest ) and ( tonumber(currenthour) >= earliest )) then
          fibaro:call(sonosvirDevID, "pressButton", sonosactionid);
        end
      end
      -- Blinks the "Blink ID" if enabled.
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
      -- Turns on the grinder if enabled.
      if (grinderon > 0) then
        if debug > 0 then fibaro:debug("Turning on the " ..grinder.. "."); end
        fibaro:call(grinderid, "turnOn");
      end
    else
      -- Not yet warm, wanting.
      if debug > 0 then fibaro:debug("Not yet warm, waiting..."); end
      fibaro:sleep(timer*1000);
      watts = checkwatts(id, masterid);
      status = checkstatus(id);
      if (status == 0) then
        return 1;
      end
      warmloop();
    end
  end
end

-- Starts the check to see if it's on.
if (tonumber(fibaro:getValue(id, "value")) > 0) then
  if debug > 0 then fibaro:debug(thing.. " is on!"); end
  fibaro:sleep(15000); -- Wait a bit extra to get power consumption up.
  watts = checkwatts(id, masterid);
  status = checkstatus(id);
  didSendNotification = 0;
  blinkstatus = 0; 
  warmloop();
else
  if debug > 0 then fibaro:debug(thing.. " is off."); end
  if (grinderoff > 0) then
    if debug > 0 then fibaro:debug("Turning off the " ..grinder.. "."); end
    fibaro:call(grinderid, "turnOff");
  end
end
