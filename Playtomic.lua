--[[ Some Lua helper functions ]]--
local json = require "json"
local crypto = require "crypto"
local mime = require "mime"
local math = math
local string = string
local print = print
local tostring = tostring
local setmetatable = setmetatable

local newInvocations = {}
local invocations = {}

local function escape (s)
      if s == nil then return "" end
      return string.gsub(tostring(s), [[([% %!%#%$%%%^%&%(%)%=%:%;%"%'%\%?%<%>%~%[%]%{%}%`%,])]], function (c) return string.format("%%%02X", string.byte(c)) end)
end

local function join( object, string )
	return table.concat( object, string )
end

local function push( object, string )
	table.insert( object, string )
end

local Encode = {		
	Base64 = mime.b64,
	MD5 = function(str) return crypto.digest(crypto.md5, str ) end,	
}

local invoke = function( func, time, repeating )
	time = time or 1000
	repeating = repeating or false
	newInvocations[#newInvocations+1] = {func=func, time=time, elapsed=0, repeating=repeating}
	return newInvocations[#newInvocations].id
end
local tPrevious = system.getTimer()
local function onEnterFrame( event )
	local tDelta = event.time - tPrevious
	tPrevious = event.time

	if #newInvocations > 0 then
		for i = #newInvocations,1,-1 do
			invocations[#invocations+1] = newInvocations[i]
			newInvocations[i] = nil
		end
		newInvocations = {}
	end
	
	remainingInvocations = {}
	for i = 1,#invocations do
		if invocations[i] ~= nil then
			invocations[i].elapsed = invocations[i].elapsed + tDelta
			if invocations[i].elapsed >= invocations[i].time then
				invocations[i].func()
				if invocations[i].repeating then
					invocations[i].elapsed = 0
					remainingInvocations[#remainingInvocations+1] = invocations[i];
				end 
			else
				remainingInvocations[#remainingInvocations+1] = invocations[i];
			end
		end
	end
	invocations = remainingInvocations
	remainingInvocations = nil
end

Runtime:addEventListener( "enterFrame", onEnterFrame )

local function setTimeout(func, time)
	invoke( func, time, false )
end

local function setInterval(func, time)
	invoke( func, time, true )
end

local function Load( pathname )
	local data = nil
	local path = system.pathForFile( pathname, system.DocumentsDirectory  )
	local fileHandle = io.open( path, "r" )
	if fileHandle then 
		data = json.decode( fileHandle:read( "*a" ) ) 
		io.close( fileHandle )
	end 
	return data
end

local function Save( data, pathname ) 
	local success = false 
	local path = system.pathForFile( pathname, system.DocumentsDirectory  ) 
	local fileHandle = io.open( path, "w" ) 
	if fileHandle then 	
		fileHandle:write( json.encode( data ) )
		io.close( fileHandle )
		success = true
	end
	return success 
end

local function makeAsyncCall( url, listener )
	network.request(url, "GET", listener )
end

--crypto.digest(crypto.md5, str )

local Playtomic = {};
local display = display
local setmetatable = setmetatable
Playtomic.__index = Playtomic
setfenv(1, Playtomic)
	local Temp = {};
	local SWFID = 0;
	local GUID = "";
	local Enabled = true;
	local SourceUrl = "";
	local BaseUrl = "";
	local APIUrl = "";
	local APIKey = "";
	local Pings = 0;
	local FailCount = 0;
	local ScriptHolder = nil;
	local Beacon = {}; --new Image();
	local URLStub = "";
	local URLTail = "";
	local SECTIONS = {};
	local ACTIONS = {};
	local Cookies = {};
	local DEBUG = false;
	local function debug (...) if DEBUG then print("Playtomic: ",...) end end

--	do   --begin logging scope		
		local Request = false
		local Plays = 0
		local Pings = 0
		local FirstPing = true
		local Frozen = false
		local FrozenQueue = {}
		local Customs = {}
		local LevelCounters = {}
		local LevelAverages = {}
		local LevelRangeds = {}

		local function LogRequest()
			local this = {}
			this.Data = {};
			this.Ready = false;
	
			this.Queue = function(data)
			
				push(this.Data, data);

				if(#this.Data > 8) then
					this.Ready = true;
				end
			end

			this.Send = function()
				local url = URLStub .. "tracker/q.aspx?swfid=" .. SWFID .. "&q=" ..  join(this.Data, "~") .. "&url=" .. SourceUrl .. "&" .. math.random() .. "z"
				makeAsyncCall( url )
				debug( "Send:",  url )
			end
		
			this.MassQueue = function(frozenqueue)
			
				if(#frozenqueue == 0)then
					Log.Request = this;
					return;
				end
				
				for i=frozenqueue.length-1,0,-1 do
					this.Queue(frozenqueue[i]);
					frozenqueue.splice(i, 1);
					
					if(this.Ready)then
						this.Send();
						local request = LogRequest();
						request.MassQueue(frozenqueue);
						return;
					end
				end
			end
			return this
		end

		
		--[[
		 * Adds an event and if ready or a view or not queuing, sends it
		 * @param	s	The event as an ev/xx string
		 * @param	view	If it's a view or not
		 ]]	
		local function Send(data, forcesend)		
			if Frozen then
				FrozenQueue.push(data);
				return false
			end
			
			if not Request then
				Request = LogRequest();
			end

			Request.Queue(data);
			
			if Request.Ready or forcesend then
				Request.Send();
				Request = LogRequest();
			end
		end
		
		--[[
		 * Increases the play time and triggers events being sent
		 ]]
		local Ping
		Ping = function ()
			if not Enabled then
				return false
			end
				
			Pings = Pings + 1;

			if FirstPing then
				Send("t/y/" .. Pings, true);
			else
				Send("t/n/" .. Pings, true);
			end
				
			if FirstPing then
				setInterval(Ping, 30000);
				FirstPing = false;
			end
		end

		--[[
		 * Cleans a piece of text of reserved characters
		 * @param	s	The string to be cleaned
		 ]]
		function Clean(s)
			if s == nil then return ""; end
			s = string.gsub(tostring(s), [[([%/%~])]], function (c)
				if c == "~" then c = "-"
				elseif c == "/" then c = "\\" end
				return c
			end)

			return escape(s);		
		end		
	--[[
		function Unescape(s)
			--FLAG fix this too
			return decodeURI(s).replace(/\+/g, " ");
		end
	]]
		
		--[[
		 * Saves a cookie value
		 * @param	key		The key (views, plays)
		 * @param	value	The value
		 ]]
		function SetCookie(key, value)
			--escape(value)
			Cookies[ key ] = value
			Save( Cookies, "playtomic.cookies" );
		end

		function LoadCookies()
			Cookies = Load( "playtomic.cookies" );
			if not Cookies then 
				Cookies = {}
			end
		end

		--[[
		 * Gets a cookie value
		 * @param	key		The key (views, plays)
		 ]]
		function GetCookie(key)
			return Cookies[ key ]
		end
				
		Log = { }
				
			--[[
			 * Logs a view and initializes the API.  You must do this first before anything else!
			 * @param	swfid		Your game id from the Playtomic dashboard
			 * @param	guid		Your game guid from the Playtomic dashboard
			 * @param	apikey		Your secret API key from the Playtomic dashboard
			 * @param	defaulturl	Should be root.loaderInfo.loaderURL or some other default url value to be used if we can't detect the page
			 ]]
		function Log.View(swfid, guid, apikey, defaulturl, debugMode)
				-- game credentials
				if SWFID > 0 then
					return
				end
	
				SWFID = swfid;
				GUID = guid;
				Enabled = true;
	
				if SWFID == 0 or not SWFID or not GUID then
					debug( "Error: SWFID or GUID missing." )
					Enabled = false;
					local Nothing = function () end
					local blockAccess = {}
					blockAccess.__index = function () return Nothing end
					blockAccess.__newindex = function ()  end
					setmetatable( Log, blockAccess )
					return
				end

				DEBUG = ( debugMode == true )
				debug("View:",swfid, guid, apikey, defaulturl, debugMode);
						
				-- game & api urls
				SourceUrl = "ansca.corona.playtomic"
				BaseUrl = "ansca.corona.playtomic"

				URLStub = "http://g" .. GUID .. ".api.playtomic.com/";
				URLTail = "swfid=" .. SWFID .. "&js=y";	
				
				-- section & actions
				SECTIONS = {
					["gamevars"] = Encode.MD5("gamevars-" .. apikey),
					["geoip"] = Encode.MD5("geoip-" .. apikey),
					["leaderboards"] = Encode.MD5("leaderboards-" .. apikey),
					["playerlevels"] = Encode.MD5("playerlevels-" .. apikey),
					["data"] = Encode.MD5("data-" .. apikey),
					["parse"] = Encode.MD5("parse-" .. apikey),					
				}
				
				ACTIONS = {
					["gamevars-load"] = Encode.MD5("gamevars-load-" .. apikey),
					["geoip-lookup"] = Encode.MD5("geoip-lookup-" .. apikey),
					["leaderboards-list"] = Encode.MD5("leaderboards-list-" .. apikey),
					["leaderboards-listfb"] = Encode.MD5("leaderboards-listfb-" .. apikey),
					["leaderboards-save"] = Encode.MD5("leaderboards-save-" .. apikey),
					["leaderboards-savefb"] = Encode.MD5("leaderboards-savefb-" .. apikey),
					["leaderboards-saveandlist"] = Encode.MD5("leaderboards-saveandlist-" .. apikey),
					["leaderboards-saveandlistfb"] = Encode.MD5("leaderboards-saveandlistfb-" .. apikey),
					["leaderboards-createprivateleaderboard"] = Encode.MD5("leaderboards-createprivateleaderboard-" .. apikey),
					["leaderboards-loadprivateleaderboard"] = Encode.MD5("leaderboards-loadprivateleaderboard-" .. apikey),
					["playerlevels-save"] = Encode.MD5("playerlevels-save-" .. apikey),
					["playerlevels-load"] = Encode.MD5("playerlevels-load-" .. apikey),
					["playerlevels-list"] = Encode.MD5("playerlevels-list-" .. apikey),
					["playerlevels-rate"] = Encode.MD5("playerlevels-rate-" .. apikey),
					["data-views"] = Encode.MD5("data-views-" .. apikey),
					["data-plays"] = Encode.MD5("data-plays-" .. apikey),
					["data-playtime"] = Encode.MD5("data-playtime-" .. apikey),
					["data-custommetric"] = Encode.MD5("data-custommetric-" .. apikey),
					["data-levelcountermetric"] = Encode.MD5("data-levelcountermetric-" .. apikey),
					["data-levelrangedmetric"] = Encode.MD5("data-levelrangedmetric-" .. apikey),
					["data-levelaveragemetric"] = Encode.MD5("data-levelaveragemetric-" .. apikey),
					["parse-save"] = Encode.MD5("parse-save-" .. apikey),
					["parse-delete"] = Encode.MD5("parse-delete-" .. apikey),
					["parse-load"] = Encode.MD5("parse-load-" .. apikey),
					["parse-find"] = Encode.MD5("parse-find-" .. apikey),	
				}
				
				--[[ Create our script holder
				ScriptHolder = document.createElement("div");
				ScriptHolder.style.position = "absolute";
				document.getElementsByTagName("body")[0].appendChild(ScriptHolder);
				]]
	
				-- Log the view (first or repeat visitor)
				LoadCookies();
				local views = GetCookie("views") or 0;
				views = views + 1;
				SetCookie("views", views);
				Send("v/" .. views, true);
	
				-- Start the play timer
				setTimeout(Ping, 60000);
			
		end		
			--[[
			 * Logs a play.  Call this when the user begins an actual game (eg clicks play button)
			 ]]
		function Log.Play()
			debug("Play");	
			LevelCounters = {};
			LevelAverages = {};
			LevelRangeds = {};
			Plays = Plays + 1;
			Send("p/" .. Plays);
		end
				
			--[[
			 * Logs the link results, internal use only.  The correct use is Link.Open(...)
			 * @param	levelid		The player level id
			 ]]
		function Log.Link(name, group, url, unique, total, fail)
			debug("Link:",name, group, url, unique, total, fail)
			if not Enabled then
				return;
			end
				
			Send("l/" .. Clean(name) .. "/" .. Clean(group) .. "/" .. Clean(url) .. "/" .. unique .. "/" .. total .. "/" .. fail);
		end
			
			--[[
			 * Logs a custom metric which can be used to track how many times something happens in your game.
			 * @param	name		The metric name
			 * @param	group		Optional group used in reports
			 * @param	unique		Only count a metric one single time per view
			 ]]		
			function Log.CustomMetric(name, group, unique)
				debug("LevelCounterMetric:",name, group, unique)
				if not Enabled then
					return;
				end
	
				if(group == nil or group == undefined)then
					group = "";
	
				if unique then
					if(Customs.indexOf(name) > -1)then
						return;
					end
	
					Customs.push(name);
				end
					
				Send("c/" .. Clean(name) .. "/" .. Clean(group));
			end
				
			--[[
			 * Logs a level counter metric which can be used to track how many times something occurs in levels in your game.
			 * @param	name		The metric name
			 * @param	level		The level number as an integer or name as a string
			 * @param	unique		Only count a metric one single time per play
			 ]]
			function Log.LevelCounterMetric(name, level, unique)
				debug("LevelCounterMetric:", name, level, unique)	
				if unique then		
					local key = name .. "." .. tostring(level);
					if LevelCounter[key] then return end
					LevelCounters[key] = 1;
				end
				Send("lc/" .. Clean(name) .. "/" .. Clean(level));
			end
	
			--[[
			 * Logs a level ranged metric which can be used to track how many times a certain value is achieved in levels in your game.
			 * @param	name		The metric name
			 * @param	level		The level number as an integer or name as a string
			 * @param	value		The value being tracked
			 * @param	unique		Only count a metric one single time per play
			 ]]
			function Log.LevelRangedMetric(name, level, value, unique)
				debug("LevelRangedMetric:",name, level, value, unique)
				if unique then
					local key = name .. "." .. tostring(level);
					if LevelRanged[key] then return end
					LevelRangeds[key] = 1;
				end
				Send("lr/" .. Clean(name) .. "/" .. Clean(level) .. "/" .. value);
			end
			
			--[[
			 * Logs a level average metric which can be used to track the min, max, average and total values for an event.
			 * @param	name		The metric name
			 * @param	level		The level number as an integer or name as a string
			 * @param	value		The value being added
			 * @param	unique		Only count a metric one single time per play
			 ]]
			function Log.LevelAverageMetric(name, level, value, unique)
				debug("LevelAverageMetric:",name, level, value, unique)	
				if unique then
					local key = name .. "." .. tostring(level);
					if Log.LevelAverages[key] then return end
					LevelAverages[key] = 1;
				end
				
				Send("la/" .. Clean(name) .. "/" .. Clean(level) .. "/" .. value);
			end
				
			--[[
			 * Logs a heatmap which allows you to visualize where some event occurs.
			 * @param	metric		The metric you are tracking (eg clicks)
			 * @param	heatmap		The heatmap (it has the screen attached in Playtomic dashboard)
			 * @param	x			The x coordinate
			 * @param	y			The y coordinate
			 ]]
			function Log.Heatmap(metric, heatmap, x, y)
				debug("Heatmap:",metric, heatmap, x, y)
				Send("h/" .. Clean(metric) .. "/" .. Clean(heatmap) .. "/" .. x .. "/" .. y);
			end
			
			--[[
			 * Not yet implemented :(
			 ]]
			function Log.Funnel(name, step, stepnum)
				Send("f/" .. Clean(name) .. "/" .. Clean(step) .. "/" .. num);
			end
			
			--[[
			 * Logs a start of a player level, internal use only.  The correct use is PlayerLevels.LogStart(...);
			 * @param	levelid		The player level id
			 ]]			
			function Log.PlayerLevelStart(levelid)	
				Send("pls/" .. levelid);
			end
			
			--[[
			 * Logs a win on a player level, internal use only.  The correct use is PlayerLevels.LogWin(...);
			 * @param	levelid		The player level id
			 ]]
			function Log.PlayerLevelWin(levelid)
				Send("plw/" .. levelid);
			end
	
			--[[
			 * Logs a quit on a player level, internal use only.  The correct use is PlayerLevels.LogQuit(...);
			 * @param	levelid		The player level id
			 ]]
			function Log.PlayerLevelQuit(levelid)
				Send("plq/" .. levelid);
			end
	
			--[[
			 * Logs a retry on a player level, internal use only.  The correct use is PlayerLevels.LogRetry(...);
			 * @param	levelid		The player level id
			 ]]
			function Log.PlayerLevelRetry(levelid)
				Send("plr/" .. levelid);
			end
			
			--[[
			 * Logs a flag on a player level, internal use only.  The correct use is PlayerLevels.Flag(...);
			 * @param	levelid		The player level id
			 ]]
			function Log.PlayerLevelFlag(levelid)
				Send("plf/" .. levelid);
			end
			
			--[[
			 * Forces the API to send any unsent data now
			 ]]
			function Log.ForceSend()				
				if(Request == nil)then
					Request = LogRequest();
				end
				Request.Send();
				Request = LogRequest();
			end
			
			--[[
			 * Freezes the API so analytics events are queued but not sent
			 ]]		
			function Log.Freeze()
				Frozen = true;
			end
			
			--[[ Unfreezes the API and sends any queued events ]]		
			function Log.UnFreeze()
				Frozen = false;
				if(FrozenQueue.length > 0)then
					Request.MassQueue();
				end
			end
			
			function Log.isFrozen()
				return Frozen
			end
		--};
		
	end 
--end

return Playtomic

