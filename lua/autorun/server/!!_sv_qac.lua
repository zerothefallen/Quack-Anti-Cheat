--[[ 

Hi, This is Zero The Fallen
This is QAC (aka Quack Anti Cheat)
The Config is below, edit it to your likings, as I'll attempt to describe anything that seems confusing.
If you dont understand something, please post on the CH thread!
Thanks

Whats new:
=========
3/4/2014 

Hi, QAC 
--]]


util.AddNetworkString("Ping1")
util.AddNetworkString("Ping2")
util.AddNetworkString("checksum")
util.AddNetworkString("gcontrolled_vars")
util.AddNetworkString("controlled_vars")
util.AddNetworkString("quack")
resource.AddFile("sound/qac/quack.wav")

print("QAC: Serverside Starting")
QAC = true

-----------------------------  Config ----------------------------------\

local BanWhenDetected 	 = true 	-- Ban when detected?
local whitelist			 = true 	-- Will use whitelist -- TESTING ONLY PURPOSES...
local time 				 = 0 		-- Ban time
local MaxPings 			 = 10 		-- Max pings they can not return
local KickForPings		 = false		-- If they exceed MaxPings

local alertAdmins		 = false    -- Alerts admins when detected
local AlertTimerDelay    = 30       -- Message repeat delay
local AlertTimer 		 = false    -- Repeat banned users msg?

-------------------------------------------------------
-- Ban Systems ----------------------------------------
-- Do not set more than 1 to true. Only 1 at a time. --
-------------------------------------------------------

local UseSourceBans = false -- sm_ban
local UseAltSB 		= false -- ulx sban
local serverguard   = false -- If you use serverguard
local alt_ban
if (UseAltSB) or (serverguard) or (UseSourceBans) then
	alt_ban = true
end
	
----------
-- Misc --
----------

local RepeatBan     = true 	-- Will ban them every time they're detected. (AKA if you unban them, it will re-ban if cheats activated again)
local PlaySound 	= true 	-- You know whats up.
---------------
-- WhiteList --
---------------

local banned = {} -- Dont touch this
if (whitelist) then
	banned = {
		["STEAM_0:1:1"] = true
	}
end


------------------------------ End of Config --------------------------/




--------------------------------------------------------------------------------
--- DON'T TOUCH ANYTHING BELOW THIS POINT UNLESS YOU KNOW WHAT YOU'RE DOING-----
--------------------------------------------------------------------------------


local function LogBan(p, r)
		local qacrnb = "Detected " .. p:Name() .. " for " .. r .. "(" .. p:SteamID() .. ") \n"
		print(qacrnb)
		file.Append("QAC Log.txt", qacrnb)	
end
	
local function BanSystem(p, r)

	if GetConVarString("sv_allowcslua") != "0" then return end
	
	if (ulx) && !(alt_ban) then
		RunConsoleCommand("ulx", "ban", p:Name() , time, r)
	elseif (ulx) && (UseAltSB) then
		RunConsoleCommand("sm_ban", p:Name() , time, r)
	elseif (ulx) && (UseSourceBans) then
		RunConsoleCommand("ulx","sban", p:Name() , time, r)
	elseif (evolve) then
		RunConsoleCommand("ev", "ban", p:Name() , time, r)
	elseif (serverguard) then
		RunConsoleCommand("serverguard_ban", p:Name() , 7000, r)
	else
		ply:Ban(time, r)
		ply:Kick(r)
	end
end

local function PlaySounds()
	if (PlaySound) then
		net.Start("quack")
		net.Broadcast()
	end
end

-------------------
--- Ban function --
-------------------

local function Ban(p, r)
	hook.Call("QACBan", GAMEMODE, p, r)
	
	LogBan(p, r)
	if (banned[p:SteamID()]) then
		return
	end
	if !(RepeatBan) then
		banned[p:SteamID()] = true
	end
	
	PlaySounds()
	BanSystem(p, r)
end



------------------------------
-- Foreign Source Detection --
------------------------------

local scans = {}

net.Receive(
	"checksum",
	function(l, p)
		local s = net.ReadString()
		local crc = net.ReadString()
		
		local sr = scans[s]
		local br = "Detected foreign source file " .. s .. "."
		
		
		// Testing of CRC. Oddly, doesnt work. Maybe im dumb
		// local l_crc = util.CRC(file.Read(s, "game") or nil)
		// if (l_crc != crc) then
		//	file.Append("qac_crc_debug.txt", "client file " .. s .." crc ".. crc .. " does not seem to match server " .. s .. " s crc: " .. l_crc .. "\n")
		// end
		
		if (sr != nil) then
			if (sr) then
				return
			else
				Ban(p, br)
			end
		end
		
		if (file.Exists(s, "game")) then
			scans[s] = true
		else
			scans[s] = false
			Ban(p, br)
		end	
	end
)

----------------------
-- ConVar Detection --
----------------------

local function CC(name, value)
	CreateConVar(name, value, 0, ";c" )
end

--[[
CC("sp00f_bs_sv_allowcslua", "0")
CC("sp00f_bs_sv_cheats", "0")
CC("sp00f_bs_host_timescale", "0")
CC("tmcb_allowcslua", "0")
]]-- Currently useless


local ctd = {
	"sv_cheats",
	"sv_allowcslua",
	"mat_fullbright",
	"mat_proxy",
	"mat_wireframe",
	"host_timescale",
}

for i, c in pairs(ctd) do
	ctd[i] = GetConVar(c)
end

local function sendvars(p)
	for _, c in pairs(ctd) do
		net.Start("gcontrolled_vars")
			net.WriteTable({c = c:GetName(), v = c:GetString()})
		net.Send(p)
	end
end

net.Receive(
	"gcontrolled_vars",
	function(l, p)
		sendvars(p)
	end
)

local function validatevar(p, c, v)
	if (GetConVar(c):GetString() != (v || "")) then
		Ban(p, "Recieved UNSYNCED cvar (" .. c .." = " .. v .. ")") -- Fuck you, zero, it made me twitch.
	end
end

net.Receive(
	"controlled_vars",
	function(l, p)
		local t = net.ReadTable()
		validatevar(p, t.c, t.v)
	end
)


-----------------
-- Ping system V2 --
-----------------
	
local players = {}
	
hook.Add("PlayerInitialSpawn", "AddPlayer", function(ply)
	table.insert(players, ply)
end)
	
hook.Add("PlayerDisconnected", "RemovePlayer", function(ply)
	table.RemoveByValue(players, ply)
end)

local CoNum = 2 
timer.Create("STC",10,0, function()
	for k, v in pairs(players) do
		net.Start("Ping2")
		net.WriteInt(CoNum, 10)
		net.Send(v)
		
		if (!v.Pings) then 
			v.Pings = 0
		end
		
		if (KickForPings) then
			if (v.Pings > MaxPings && !v:IsBot()) then
				//v:Kick("Did not return ping")
				file.Append("QAC Log.txt", "Kicked " .. v:Name() .. " for not returning our pings. \n")
				v.Pings = 0
			end
		end
		v.Pings = v.Pings + 1
	end
end)
		
net.Receive("Ping1", function(len, ply)
	local HNum = net.ReadInt(16)
	if (HNum) && HNum == CoNum  then
		ply.Pings = ply.Pings - 1
	end
end)



--[[
Possible fetch

http.fetch(blahlbalhl)

local numberversion = whatever

file.read(data/QACV.txt, GAME) etc etc

if number = data number then

print success

else  

print ur late

Maybe autoupdate system? Dunno if I can write to lua

RunString() autoupdate checkversion.

]]--

print("QAC: Serverside finished loading")

// Credits:

// Zook -- About 75% of version 1 and the method. Without him I would literally know nothing.
// Zero the fallen -- Continuation of QAC, and myself. Most of the updates/fixes.
