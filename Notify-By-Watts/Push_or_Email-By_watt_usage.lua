--[[
%% autostart
%% properties 
156 valueSensor
%% globals 
--]] 

-- Dont forget to change the number before "valueSensor" above to the same number as ID below!!
local id = 156 -- Thing Wallplugg ID. 
local donevalue = 5 -- When the appliance uses less watt then this then it's done.
local timer = 300 -- How often to check watt usage in seconds (300 = 5 minutes).
local counter = 4 -- Counter used for counting wait timer loops before sending done message, to make sure the dishwasher is really done (timer * counter = time to wait).
local touser = fibaro:getGlobalValue("msguser01"); -- The user to receive the done-message (I make global variable for this).
local thing = "Dishwasher" -- The thing we are monitoring (for the debugging text output).
local messagenr = "122" -- Message number from notification list.
local notifytype = "push" -- Can be set to either "email" or "push".
local debug = tonumber(fibaro:getGlobalValue("globaldebug")); -- Set to one to activate debugging (show all messages).
--local debug = 1 -- Set to one to activate debugging (show all messages).

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
      if (count > counter) then
		if (notifytype == "email") then
          fibaro:call(touser, "sendEmail", messagenr);
        elseif (notifytype == "push") then
          fibaro:call(touser, "sendDefinedPushNotification", messagenr);
        else
          if debug > 0 then fibaro:debug (thing.. " is done! This debug message sent (nor email or push was selected).\nState is: " ..status.. " and watt is: " ..watts); end
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
  if debug > 0 then fibaro:debug ("Wating for " ..thing.. " to start.\nState is: " ..status.. " and watt is: " ..watts); end
  if (messsent == 1 and watts > donevalue) then
    messsent = 0
  end
  fibaro:sleep(timer*1000)
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
