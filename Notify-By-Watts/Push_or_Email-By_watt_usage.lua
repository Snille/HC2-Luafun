--[[
%% autostart
%% properties 
156 valueSensor --(Thing Wallplugg ID)
%% globals 
--]] 

local id = 156 -- Thing Wallplugg ID.
local donevalue = 1 -- When dishwasher uses less watt then this then it's done.
local timer = 300 -- How often to check watt usage in seconds (300 = 5 minutes).
local counter = 4 -- Counter used for counting wait timer loops before sending done message, to make sure the dishwasher is really done (timer * counter = time to wait).
local touser = 167 -- The user to receive the done-message (166 = NMA-User, 167 = Snilles Z2).
local thing = "Dishwasher" -- The thing we are monitoring (for the debugging text output).
local subject = "Diskmaskin klar." -- Email message header.
local message = "Dags att gå och plocka ur den!" -- Email and Push message body.
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
      if (count > counter) then
		if (notifytype == "email") then
          fibaro:call(touser, "sendEmail", subject, message)
        elseif (notifytype == "push") then
          fibaro:call(touser, "sendPush", subject.." "..message);
        else
          fibaro:debug (thing.. " is done! This debug message sent (nor email or push was selected).\nState is: " ..status.. " and watt is: " ..watts);
        end
        fibaro:debug (thing.. " is done! Messages sent.\nState is: " ..status.. " and watt is: " ..watts);
        count = 0
        messsent = 1
      else 
        fibaro:debug (thing.. " is probably done. No messages sent yet, wait " ..count.. "/" ..counter.. " to be sure.\nState is: " ..status.. " and watt is: " ..watts);
        fibaro:sleep(timer*1000)
		mainloop();
	  end
    else
      fibaro:debug (thing.. " is running!\nState is: " ..status.. " and watt is: " ..watts);
	  messsent = 0
	  count = 0
      fibaro:sleep(timer*1000)
      mainloop();
	end
  end
  fibaro:debug ("Wating for " ..thing.. " to start.\nState is: " ..status.. " and watt is: " ..watts);
  if (messsent == 1 and watts > donevalue) then
    messsent = 0
  end
  fibaro:sleep(timer*1000)
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