--[[
%% properties
277 value
%% events
%% globals
--]]

-- Dont forget to change the number before "value" (Grinder ID) above to the same number as ID below!!
local id = 277 -- Thing Wall plug ID (Grinder).
local masterid = 278 -- Thing Wall plug Master ID (This is the parent ID to the Grinder plug ID). It's used to be able to pull for watt usage often.
local timer = 3 -- How often to "pull" watt usage in seconds when machine is grinding (default 3).
local thing = "Grinder" -- The thing we are monitoring (for the debugging text output).
local triggerlimit = 10 -- More then this watt value trigger the grinder is grinding. (Default: 10)
local DBvirDevID = 296  -- Database Virtual Action Device ID.
local DBactionid = 1 -- The "button-ID" on the Database Virtual Action Device to be triggered (basically the defined action button on the VDevice).
local debug = tonumber(fibaro:getGlobalValue("globaldebug")); -- Set the global variable called "globaldebug" to one to activate debugging (show all messages).
--local debug = 1 -- Set to one to activate debugging (show all messages). Enable this line to override the global debug variable.

-- Don't change anything below this line!!

local tocheck = 0;
local grinddone = 0;

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

-- Checking the grinding status.
function grindloop()
  status = checkstatus(id);
  watts = checkwatts(id, masterid);
  if (status > 0 and grinddone == 0) then
    if debug > 0 then fibaro:debug ("Monitoring " ..thing.. ".\nState is: " ..status.. " and watt is: " ..watts); end
    if (watts > 0) then
      repeat
        fibaro:sleep(timer*1000);
        status = checkstatus(id);
        if (status == 0) then
          return 1;
        end
        watts = checkwatts(id, masterid);
        if debug > 0 then fibaro:debug(thing.. " is grinding.\nState is: " ..status.. " and it's using: " ..watts.. " watts."); end
        grinddone = 1;
      until (watts < triggerlimit)
      if (grinddone > 0) then 
        if debug > 0 then fibaro:debug("Grinding done!\nSending update to Database."); end
        -- Adding the grind to the database using the VDevice.
        fibaro:call(DBvirDevID, "pressButton", DBactionid);
        grinddone = 0;
      end
    else
      fibaro:sleep(timer*1000);
      status = checkstatus(id);
      if (status == 0) then
        return 1;
      end
      watts = checkwatts(id, masterid);
    end
    grindloop();
  end
  return 1;
end

-- Starts the check to see if it's on.
if (tonumber(fibaro:getValue(id, "value")) > 0) then
  if debug > 0 then fibaro:debug(thing.. " is on!"); end
  fibaro:sleep(2000); -- Wait a bit extra to get power consumption up.
  grinddone = 0;
  grindloop();
  if debug > 0 then fibaro:debug(thing.. " is now turned off."); end
else
  if debug > 0 then fibaro:debug(thing.. " is off."); end
end