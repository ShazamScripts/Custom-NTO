local _G = modules["_G"];
local millis = _G["g_clock"]["millis"];
local cycleEvent = _G["cycleEvent"];
local removeEvent = _G["removeEvent"];
local scheduleEvent = _G["scheduleEvent"];

local registered_functions = {};

local removeCycleEvent = function()
	if (_G["onExitBot"] ~= nil) then
		removeEvent(_G["onExitBot"]);
		_G["onExitBot"] = nil;
	end
end

local onExit = function()
	
	for index, callback in ipairs(registered_functions) do
		callback();
	end
end

onExitRegister = function(func)
	if (not table["find"](registered_functions, func)) then
		table["insert"](registered_functions, func);
	end
end



	
	
	
	
		
	


local _G = modules["_G"];
local GameBot = _G["GameBot"];
local game_bot = modules["game_bot"];
local enableButton = g_ui["getRootWidget"]():recursiveGetChildById("enableButton");

if (game_bot["save_function"] == nil) then
	
	game_bot["isMainFunction"] = true;
	game_bot["save_function"] = game_bot["save"];
end

if (game_bot["save_function"] == nil) then
	game_bot["isMainFunction"] = false;
	game_bot["save_function"] = GameBot and GameBot["refresh"] or game_bot["refresh"];
end

if (game_bot["isMainFunction"]) then
	game_bot["save"] = function()
		if (enableButton:getText() == "On") then
			pcall(onExit);
		end
		game_bot["save_function"]();
	end
	
	return;
end

if (game_bot["refresh"] ~= nil) then
	game_bot["refresh"] = function()
		if (enableButton:getText() == "On") then
			pcall(onExit);
		end
		game_bot["save_function"]();
	end
	return;
end

GameBot["refresh"] = function()
	if (enableButton:getText() == "On") then
		pcall(onExit);
	end
	game_bot["save_function"]();
end


	
		
	
	
