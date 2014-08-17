---- CL_QAC
---- Public 6/23/14, original copy @ 9/13
---- current vers 7/5/2014
---- ZTF/zuk

local qac = table.Copy(_G) -- UH OH. UR FUKD KID
QAC = true
-- note to self, set meta table on debug table so no one can access it unless it's whitelisted
-- additional note, implying you'll ever do that you lazy fucker.

--Source Detection Things
qac.scans = {}

qac.scanf = {

	{hook, "Add"},

	--{hook, "Call"}, -- cl deathnotice is retarded?

	--{hook, "Run"}, -- cl deathnotice is retarded?

	{timer, "Create"},

	{timer, "Simple"},

	--{_G, "CreateClientConVar"}, -- ULX IS GAY
	
	{_G, "RunString"}, -- cl deathnotice is retarded?

	{_G, "RunStringEx"},
	
	{file, "Read"},
	
	{concommand, "Add"},

	{_G, "RunConsoleCommand"},
	
	{_G, "setfenv"},
	
	{_G, "CompileFile"},
	
	{_G, "CompileString"},
	
	{net, "SendToServer"}, -- People have retarded fucking backdoors. Maybe this can stop it? naw prolly not
	-- ^ keep in mind this will lag large servers, probably. CAREFUL
	{debug, "setfenv"},
	
	{debug, "getupvalue"}
}

function qac.validate_src(src, crc)
	qac.net.Start("checksum")
	qac.net.WriteString(src)
	qac.net.WriteString(crc)
	qac.net.SendToServer()
end

function qac.RFS()
	local CNum = qac.net.ReadInt(10)
	qac.net.Start("Ping1")
	qac.net.WriteInt(CNum, 16)
	qac.net.SendToServer()
end
qac.net.Receive("Ping2", qac.RFS)

qac.net.Receive("quack", function()
	LocalPlayer():EmitSound("qac/quack.wav") -- RIP.
end)

function qac.scan_func()
	local s = {}
	for i = 0, 1/0, 1 do
	local dbg = qac.debug.getinfo(i)
		if (dbg) then
			s[dbg.short_src] = true
		else
			break
		end
	end
	
	for src, _ in qac.pairs(s) do
		if (src == "RunString" || src == "LuaCmd" || src == "[C]") then
			return
		elseif (!(qac.scans[src])) then
			qac.scans[src] = true
			local crc = qac.util.CRC(qac.file.Read(src, "game") or "0") // Currently doesnt work. Send for debug
			qac.validate_src(src, crc)
		end
	end
end

---Scan Functions
function qac.SCAN_G()
	for _, ft in qac.pairs(qac.scanf) do
		local ofunc = ft[1][ft[2]]

		ft[1][ft[2]] = (
			function(...)
				local args = {...}
				qac.scan_func()
				ofunc(qac.unpack(args))
			end
		)
	end
end

qac.hook.Add(
	"OnGamemodeLoaded",
	"___scan_g_init",
	function()
	qac.SCAN_G()
	qac.hook.Remove("OnGamemodeLoaded", "___scan_g_init")
end)

--ConVar Detection

function qac.validate_cvar(c, v)
	qac.net.Start("controlled_vars")
	qac.net.WriteTable({c = c, v = v})
	qac.net.SendToServer()
end

function qac.cvcc(cv, pval, nval)
	qac.validate_cvar(cv, nval)
end

qac.ctd = {}

function qac.sned_req()
	qac.net.Start("gcontrolled_vars")
	qac.net.WriteBit()
	qac.net.SendToServer()
end

qac.timer.Simple(1, qac.sned_req)

qac.net.Receive(
	"gcontrolled_vars",
	function()
	local t = qac.net.ReadTable()
	local c = qac.GetConVar(t.c)
	local v = (c != nil && c:GetString() || "0")
	qac.ctd[c] = v
	qac.cvars.AddChangeCallback(t.c, qac.cvcc)
	if (v != t.v) then
		qac.validate_cvar(t.c, v)
	end
end)

---Timed Chec

qac.mintime = 010
qac.maxtime = 030

function qac.timecheck()
	for c, v in qac.pairs(qac.ctd) do
		local cv = c:GetString() || ""
		if (cv != v) then
			validate_cvar(c:GetName(), cv)
			qac.ctd[c] = cv
		end
	end
	qac.timer.Simple(qac.math.random(mintime, maxtime), qac.timecheck)
end
