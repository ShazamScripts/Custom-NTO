local _G = modules["_G"];
local removeEvent = _G["removeEvent"];
local scheduleEvent = _G["scheduleEvent"];

_G["sayList"] = _G["sayList"] or {};

local sort = function(a, b)
	return a["priority"] > b["priority"];
end

if (_G["talk_function"] == nil) then
	_G["talk_function"] = g_game["talk"];
end

local sortSayList = function()
	table["sort"](_G["sayList"], sort);
end

local getSayList = function()
	local cache = {};
	return table["collect"](_G["sayList"], function(_, value)
		local trimmed_spell = value["spell"]:trim();
		local spell = trimmed_spell:lower();
		
		local cached_value = cache[spell];
		if (cached_value == nil) then
			cache[spell] = true;
			return trimmed_spell;
		end
	end)
end

call_event = function()
	sortSayList();
	local sayList = getSayList();
	
	for _, spell in ipairs(sayList) do
		_G["talk_function"](spell);
	end
	
	_G["talking_event"] = nil;
	table["clear"](_G["sayList"]);
end;

g_game["talk"] = function(spell, priority)
	if (spell == nil) then return; end

	spell = tostring(spell);
	
	if (priority == nil) then
		priority = 0;
		if (spell:lower():find("regen")) then
			priority = -1;
		end
	end

	local append_value = {spell=spell, priority=priority};

	if (_G["talking_event"] == nil) then
		_G["talking_event"] = scheduleEvent(call_event, 5);
	end

	
	table["insert"](_G["sayList"], append_value);
end

say = g_game["talk"];