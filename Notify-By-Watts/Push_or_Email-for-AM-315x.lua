--[[
%% autostart
%% properties 
199 valueSensor
%% globals 
--]] 

-- Dont forget to change the number before "valueSensor" above to the same number as ID below!!
local id = 199 -- AM Wallplugg ID.
local donevalue = 10 -- When device uses less watt then this then it's done.
local timer1 = 300 -- How often to check watt usage in seconds (600 = 10 minutes) when in the "wait loop".
local timer2 = 60 -- How often to check watt usage in seconds (60 = 1 minute) when in the "rechargeing loop".
local counter = 5 -- Counter used for counting wait timer2 loops before sending done message, to make sure it's really done (timer2 * counter = time to wait).
local touser = fibaro:getGlobalValue("msguser01"); -- The user to receive the done-message (I make global variable for this).
local thing = "Rupert" -- The Automowers name we are monitoring (for the debugging text output).
local messagenr1 = "259" -- Message number from notification list when rechargeing is finnished.
local messagenr2 = "261" -- Message number from notification list when rechargeing begins.
local notifytype = "push" -- Can be set to either "email" or "push".
local debug = tonumber(fibaro:getGlobalValue("globaldebug")); -- Set to one to activate debugging (show all messages).
--local debug = 1 -- Set to one to activate debugging (show all messages).

-- Don't change below!!

local messsent = 1 -- Sets to 1/0 if a message is sent / reset.
local count = 0 -- Sets to same as counter when done wating for the message to be sent.
local start = 0 -- Sets to 1 when the loadcycle has started and first message has been sent.
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
      if (count > counter) then
        if (notifytype == "email") then
          fibaro:call(touser, "sendEmail", messagenr1);
        elseif (notifytype == "push") then
          fibaro:call(touser, "sendDefinedPushNotification", messagenr1);
        else
          if debug > 0 then fibaro:debug (thing.. " is done rechargeing! This debug message sent (nor email or push was selected).\nState is: " ..status.. " and watt is: " ..watts); end
        end
        if debug > 0 then fibaro:debug (thing.. " is done rechargeing! Messages sent.\nState is: " ..status.. " and watt is: " ..watts); end
        count = 0
        messsent = 1
        start = 0
      else 
        if debug > 0 then fibaro:debug (thing.. " is probably done rechargeing. No messages sent yet, wait " ..count.. "/" ..counter.. " to be sure.\nState is: " ..status.. " and watt is: " ..watts); end
        fibaro:sleep(timer2*1000)
        mainloop();
      end
    else
      if (start == 0) then
        if (notifytype == "email") then
          fibaro:call(touser, "sendEmail", messagenr2);
        elseif (notifytype == "push") then
          fibaro:call(touser, "sendDefinedPushNotification", messagenr2);
        else
          if debug > 0 then fibaro:debug (thing.. " at docking station and starts rechargeing! This debug message sent (nor email or push was selected).\nState is: " ..status.. " and watt is: " ..watts); end
        end
        if debug > 0 then fibaro:debug (thing.. " at docking station and starts rechargeing! \nState is: " ..status.. " and watt is: " ..watts); end
        start = 1
      end
      if debug > 0 then fibaro:debug (thing.. " is still rechargeing!\nState is: " ..status.. " and watt is: " ..watts); end
      messsent = 0
      count = 0
      fibaro:sleep(timer2*1000)
      mainloop();
    end
  end
  if debug > 0 then fibaro:debug ("Wating for " ..thing.. " to start rechargeing.\nState is: " ..status.. " and watt is: " ..watts); end
  if (messsent == 1 and watts > donevalue) then
    messsent = 0
  end
  fibaro:sleep(timer1*1000)
  mainloop();
end

status = checkstatus();
watts = checkwatts();
if debug > 0 then fibaro:debug ("Start - " ..thing.. " plug is in state "..status.. " and consums " ..watts.. " watt."); end

if (sourceTrigger["type"] == "autostart") then
  mainresult = mainloop();
else
  if debug > 0 then fibaro:debug ("No auto start..."); end
end
