--[[
%% autostart
%% properties 
199 valueSensor
%% globals 
--]] 

-- Dont forget to change the number before "valueSensor" above to the same number as Wall plug ID below!!
local id = 199 -- AM Wall plug ID.
local donevalue = 10 -- When the AM uses less watt then this then it's done.
local timer1 = 300 -- How often to check watt usage in seconds (600 = 10 minutes) when in the "wait loop".
local timer2 = 60 -- How often to check watt usage in seconds (60 = 1 minute) when in the "recharging loop".
local counter = 5 -- Counter used for counting wait timer2 loops before sending done message, to make sure it's really done (timer2 * counter = time to wait).
local touser = fibaro:getGlobalValue("msguser01"); -- The user to send the done-message to (I make global variable called "msguser01" for this).
local thing = "Rupert" -- The Automowers name we are monitoring (for the debugging text output).
local messagenr1 = "259" -- Message number from notification list when recharging is finished.
local messagenr2 = "261" -- Message number from notification list when recharging begins.
local notifytype = "push" -- How the message should be delivered. Either "email" or "push" (default push).
local debug = tonumber(fibaro:getGlobalValue("globaldebug")); -- Set the global variable called "globaldebug" to one to activate debugging (show all messages).
--local debug = 1 -- Set to one to activate debugging (show all messages). Enable this line to override the global debug variable.

-- Don't change anything below this line!!

local messsent = 1 -- Sets to 1/0 if a message is sent / reset.
local count = 0 -- Sets to same as counter when done waiting for the message to be sent.
local start = 0 -- Sets to 1 when the load cycle has started and first message has been sent.

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
          fibaro:call(touser, "sendDefinedEmailNotification", messagenr1);
        elseif (notifytype == "push") then
          fibaro:call(touser, "sendDefinedPushNotification", messagenr1);
        else
          if debug > 0 then fibaro:debug (thing.. " is done recharging! This debug message sent (nor email or push was selected).\nState is: " ..status.. " and watt is: " ..watts); end
        end
        if debug > 0 then fibaro:debug (thing.. " is done recharging! Messages sent.\nState is: " ..status.. " and watt is: " ..watts); end
        count = 0
        messsent = 1
        start = 0
      else 
        if debug > 0 then fibaro:debug (thing.. " is probably done recharging. No messages sent yet, wait " ..count.. "/" ..counter.. " to be sure.\nState is: " ..status.. " and watt is: " ..watts); end
        fibaro:sleep(timer2*1000)
        mainloop();
      end
    else
      if (start == 0) then
        if (notifytype == "email") then
          fibaro:call(touser, "sendDefinedEmailNotification", messagenr2);
        elseif (notifytype == "push") then
          fibaro:call(touser, "sendDefinedPushNotification", messagenr2);
        else
          if debug > 0 then fibaro:debug (thing.. " at docking station and starts recharging! This debug message sent (nor email or push was selected).\nState is: " ..status.. " and watt is: " ..watts); end
        end
        if debug > 0 then fibaro:debug (thing.. " at docking station and starts recharging! \nState is: " ..status.. " and watt is: " ..watts); end
        start = 1
      end
      if debug > 0 then fibaro:debug (thing.. " is still recharging!\nState is: " ..status.. " and watt is: " ..watts); end
      messsent = 0
      count = 0
      fibaro:sleep(timer2*1000)
      mainloop();
    end
  end
  if debug > 0 then fibaro:debug ("Waiting for " ..thing.. " to start recharging.\nState is: " ..status.. " and watt is: " ..watts); end
  if (messsent == 1 and watts > donevalue) then
    messsent = 0
  end
  fibaro:sleep(timer1*1000)
  mainloop();
end

status = checkstatus();
watts = checkwatts();
if debug > 0 then fibaro:debug ("Start - " ..thing.. " plug is in state "..status.. " and consumes " ..watts.. " watt."); end

if (trigger["type"] == "autostart") then
  mainresult = mainloop();
else
  if debug > 0 then fibaro:debug ("No auto start..."); end
end
