--[[
%% autostart
%% properties 
156 valueSensor
%% weather
%% events
%% globals 
--]] 

-- Dont forget to change the number before "valueSensor" above to the same number as Wall plug ID below!!
local id = 156 -- Thing Wall plug ID. 
local donevalue = 5 -- When the appliance uses less watt then this then it's done.
local timer = 300 -- How often to check watt usage in seconds (300 = 5 minutes).
local counter = 4 -- Counter used for counting wait timer loops before sending done message, to make sure the appliance is really done (timer * counter = time to wait).
local touser = fibaro:getGlobalValue("msguser01"); -- The user to send the done-message to (I make global variable called "msguser01" for this).
local thing = "Dishwasher" -- The thing we are monitoring (for the debugging text output).
local messagenr = "122" -- Message number from notification list.
local notifytype = "push" -- How the message should be delivered. Either "email" or "push" (default push).
local sonossay = 1 -- Set to 1 if you want a message read on the Sonos player (using a Virtual Device for this action).
local sonosvirDevID = 294  -- Sonos Virtual Action Device ID.
local sonosactionid = 2 -- The "button-ID" on the Sonos Virtual Action Device to be triggered (basically the defined action sound to play in the VDevice).
local latest = tonumber(fibaro:getGlobalValue("timelatest")); -- Set a global variable called "timelatest" with the latest hour (24h time) a sound is allowed to be played.
local earliest = tonumber(fibaro:getGlobalValue("timeearliest")); -- Set a global variable called "timeearliest" to the earliest hour (24h time) a sound is allowed to be played.
local debug = tonumber(fibaro:getGlobalValue("globaldebug")); -- Set the global variable called "globaldebug" to one to activate debugging (show all messages).
--local debug = 1 -- Set to one to activate debugging (show all messages). Enable this line to override the global debug variable.

-- Don't change anything below this line!!

local messsent = 1 -- Sets to 1/0 if a message is sent / reset.
local count = 0 -- Sets to same as counter when done waiting for the message to be sent.

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
function checkwatts()
  if (tonumber(fibaro:getValue(id, "value")) == 1) then
    wallplugwatt = tonumber(fibaro:getValue(id, "power"));
    return wallplugwatt
  end
  return 0
end

-- Check if plug is on
function checkstatus()
  if (tonumber(fibaro:getValue(id, "value")) == 1) then
    return 1
  else 
    return 0
  end
   return -1
end

-- Main loop
function mainloop()
  status = checkstatus();
  watts = checkwatts();
  if (messsent == 0 and status == 1) then
    if (watts < donevalue) then
      count = count+1
      if (count > counter) then
        if (notifytype == "email") then
          fibaro:call(touser, "sendDefinedEmailNotification", messagenr);
        elseif (notifytype == "push") then
          fibaro:call(touser, "sendDefinedPushNotification", messagenr);
        else
          if debug > 0 then fibaro:debug (thing.. " is done! This debug message sent (nor email or push was selected).\nState is: " ..status.. " and watt is: " ..watts); end
        end
        if (sonossay > 0) then
          local currenthour = os.date("%H");
          if ((tonumber(currenthour) <= latest ) and ( tonumber(currenthour) >= earliest )) then
            fibaro:call(sonosvirDevID, "pressButton", sonosactionid);
          end
        end
        if debug > 0 then fibaro:debug (thing.. " is done! Messages sent.\nState is: " ..status.. " and watt is: " ..watts); end
        count = 0
        messsent = 1
      else 
        if debug > 0 then fibaro:debug (thing.. " is probably done. No messages sent yet, wait " ..count.. "/" ..counter.. " to be sure.\nState is: " ..status.. " and watt is: " ..watts); end
        fibaro:sleep(timer*1000)
        mainloop();
      end
    else
      if debug > 0 then fibaro:debug (thing.. " is running!\nState is: " ..status.. " and watt is: " ..watts); end
      messsent = 0
      count = 0
      fibaro:sleep(timer*1000)
      mainloop();
    end
  end
  if debug > 0 then fibaro:debug ("Waiting for " ..thing.. " to start.\nState is: " ..status.. " and watt is: " ..watts); end
  if (messsent == 1 and watts > donevalue) then
    messsent = 0
  end
  fibaro:sleep(timer*1000)
  mainloop();
end

status = checkstatus();
watts = checkwatts();
if debug > 0 then fibaro:debug ("Start - " ..thing.. " plug is in state "..status.. " and consumes " ..watts.. " watt."); end

-- Starting the main loop.
if (trigger["type"] == "autostart") then
  mainresult = mainloop();
else
  if debug > 0 then fibaro:debug ("No auto start..."); end
end