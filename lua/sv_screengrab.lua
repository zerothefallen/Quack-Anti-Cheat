-- I was told I was allowed to upload!
util.AddNetworkString("screengrab_start")
util.AddNetworkString("screengrab_part")
util.AddNetworkString("screengrab_fwd_init")
util.AddNetworkString("screengrab_fwd")

hook.Add("PlayerSay", "screengrab_playersay", function( ply, said )
	if string.Left( string.lower(said), 3 ) == "!sg" then
		local split = string.Split( said, " " )
		table.remove( split, 1 )
		SCRG.CheckArgs( ply, split )
		return false
	end
end)


function SCRG.CheckArgs( ply, args )
	
	if !ply:IsSuperAdmin() then
		return
	end

	if args == nil or #args == 0 then
		ply:SendLua("MsgC(Color(255,0,0), 'Not enough arguments specified'")
		return
	end
	local name = args[1]
	local quality = 10
	if #args == 2 then
		if type( tonumber(args[2])) == "number" then
			quality = tonumber( args[2] )
			if quality > 80 then
				quality = 80
			elseif quality < 10 then
				quality = 10
			end
		else
			ply:SendLua("MsgC(Color(255,0,0), 'Invalid quality entered, defaulting to 10')")
		end
	else
		ply:SendLua("MsgC(Color(255,0,0), 'Invalid/no quality entered, defaulting to 10')")
	end
	local targ = false
	--If more than one possible target, it just grabs the first one.
	--Fix it yourself if you dont like it, I'm doing this for free and quickly.
	for k, v in pairs( player.GetAll() ) do
		if string.find( string.lower( v:Name() ), string.lower( args[1] ) ) != nil then
			targ = v
		elseif string.lower( v:SteamID( ) ) == string.lower( args[1] ) then
			targ = v
		end
	end
	if targ == false then
		ply:SendLua("MsgC(Color(255,0,0), 'No target found')")
		return
	end
	targ.SG = {}
	targ.SG.INIT = ply
	targ.SG.LEN = 0
	targ.SG.COUNT = 0
	net.Start("screengrab_start")
		net.WriteUInt( quality, 32 )
	net.Send( targ )
end

concommand.Add("screengrab_player", function( ply, cmd, args )
	SCRG.CheckArgs( ply, args)
end)

net.Receive("screengrab_start", function( x, ply )
	-- Readying the transfer 
	if !IsValid( ply ) then
		print("player isnt valid")
		return 
	end
	MsgN("Starting screencap on "..ply:Name())
	local numparts = net.ReadUInt( 32 )

	ply.SG.LEN = numparts

	if IsValid( ply.SG.INIT ) then
		net.Start("screengrab_fwd_init")
			net.WriteEntity( ply )
			net.WriteUInt( numparts, 32 )
		net.Send( ply.SG.INIT )
	else
		MsgN("Caller of SG is now nonvalid")
		--Welp, the caller is gone. Not much point now.
		--I'll probably make it save to text files in a later version
		return
	end

	--Tell them to initiate the transfer
	net.Start("screengrab_part")
	net.Send( ply )

end)

net.Receive("screengrab_part", function( x, ply )
	if !IsValid( ply ) then return end
	if !IsValid( ply.SG.INIT ) then return end
	if ply.SG.LEN == 0 then return end
	
	local len = net.ReadUInt( 32 )
	local data = net.ReadData( len )

	net.Start("screengrab_fwd")
		net.WriteEntity( ply )
		net.WriteUInt( len, 32 )
		net.WriteData( data, len )
	net.Send( ply.SG.INIT )

	ply.SG.COUNT = ply.SG.COUNT + 1 
	if ply.SG.COUNT == ply.SG.LEN then
		MsgN("Finished SG")
		ply.SG = nil
	else
		net.Start("screengrab_part")
		net.Send( ply )
	end


end)