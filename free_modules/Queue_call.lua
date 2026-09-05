local queue = {};
local addEvent = modules["_G"]["addEvent"];

isOnQueue = function(func)
	return table["find"](queue, func);
end

putOnQueue = function(func)
	if (isOnQueue(func)) then
		return;
	end
	
	table["insert"](queue, func);
end

macro(50, function() 
	local currentCall = queue[1];
	if (currentCall == nil) then return; end
	
	addEvent(currentCall, true);
	table["remove"](queue, 1);
end)["timeout"] = 1;