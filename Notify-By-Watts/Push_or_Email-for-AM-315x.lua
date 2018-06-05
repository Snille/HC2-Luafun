--[[
%% autostart
%% properties 
199 valueSensor --(AM Wallplugg ID)
%% globals 
--]] 

local id = 199 -- AM Wallplugg ID.
local donevalue = 8 -- When device uses less watt then this then it's done.
local timer1 = 600 -- How often to check watt usage in seconds (600 = 10 minutes) when in the "wait loop".
local timer2 = 180 -- How often to check watt usage in seconds (180 = 3 minutes) when in the "rechargeing loop".
local counter = 3 -- Counter used for counting wait timer2 loops before sending done message, to make sure it's really done (timer2 * counter = time to wait).
local touser = 230 -- The user to receive the messages (230 = Usernumber).
local thing = "AM-315X" -- The Automowers name we are monitoring (for the debugging text output).
local messagenr1 = "261" -- Message number from notification list when rechargeing is finnished.
local messagenr2 = "259" -- Message number from notification list when rechargeing begins.
local notifytype = "push" -- Can be set to either "email" or "push".

-- Don't change below!!

local messsent = 1 -- Sets to 1/0 if a message is sent / reset.
local count = 0 -- Sets to same as counter when done wating for the message to be sent.
local sourceTrigger = fibaro:getSourceTrigger(); -- Check if autostart.

-- Check power consumtion if plug is on.
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
      if (count == 1) then
        if (notifytype == "email") then
          fibaro:call(touser, "sendEmail", messagenr2);
        elseif (notifytype == "push") then
          fibaro:call(touser, "sendDefinedPushNotification", messagenr2);
        else
          fibaro:debug (thing.. " at docking station and starts rechargeing! This debug message sent (nor email or push was selected).\nState is: " ..status.. " and watt is: " ..watts);
        end
      end
      if (count > counter) then
        if (notifytype == "email") then
          fibaro:call(touser, "sendEmail", messagenr1);
        elseif (notifytype == "push") then
          fibaro:call(touser, "sendDefinedPushNotification", messagenr1);
        else
          fibaro:debug (thing.. " is done rechargeing! This debug message sent (nor email or push was selected).\nState is: " ..status.. " and watt is: " ..watts);
        end
        fibaro:debug (thing.. " is done rechargeing! Messages sent.\nState is: " ..status.. " and watt is: " ..watts);
        count = 0
        messsent = 1
      else 
        fibaro:debug (thing.. " is probably done rechargeing. No messages sent yet, wait " ..count.. "/" ..counter.. " to be sure.\nState is: " ..status.. " and watt is: " ..watts);
        fibaro:sleep(timer2*1000)
        mainloop();
      end
    else
      fibaro:debug (thing.. " is still rechargeing!\nState is: " ..status.. " and watt is: " ..watts);
      messsent = 0
      count = 0
      fibaro:sleep(timer2*1000)
      mainloop();
    end
  end
  fibaro:debug ("Wating for " ..thing.. " to start rechargeing.\nState is: " ..status.. " and watt is: " ..watts);
  if (messsent == 1 and watts > donevalue) then
    messsent = 0
  end
  fibaro:sleep(timer1*1000)
  mainloop();
end

status = checkstatus();
watts = checkwatts();
fibaro:debug ("Start - " ..thing.. " plug is in state "..status.. " and consums " ..watts.. " watt.");

if (sourceTrigger["type"] == "autostart") then
  mainresult = mainloop();
else
  fibaro:debug ("No auto start...");
end