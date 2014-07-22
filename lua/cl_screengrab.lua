-- I was told I was allowed to upload! If somehow this isn't allowed, PLEASE TELL ME I'LL REMOVE IT RIGHT-AWAY. Public addon aswell!

SCRG.UPTO = 1
SCRG.DATA = {}

local cap = render.Capture

function SCRG.ShowSC( data, ply )
	local isDecentRes = (ScrW()>=1600 and ScrH()>=900)
	local frmSG = vgui.Create("DFrame")
	frmSG:SetTitle("[Screengrab]: "..ply:Name() .." - "..ply:SteamID() )
	if isDecentRes then
		frmSG:SetSize( 1600, 900 ) -- Sorry if you have a resolution smaller than this lmao
	else
		frmSG:SetSize( 1024, 576)
	end
	frmSG:MakePopup()
	frmSG:Center()
	frmSG.Paint = function()
		surface.SetDrawColor( Color(30,30,30,255) )
		surface.DrawRect( 0, 0, 1600, 900 )
	end
	
	local image = vgui.Create("HTML", frmSG )
	if isDecentRes then
		image:SetSize( 1488, 837 )
		image:SetPos( 56, 35 )
		image:SetHTML( [[ <img width="1440" height="810" src="data:image/jpeg;base64, ]]..data..[["/> ]] )
	else
		image:SetSize( 960, 540 )
		image:SetPos( 32, 30 )
		image:SetHTML( [[ <img width="1440" height="810" src="data:image/jpeg;base64, ]]..data..[["/> ]] )
	end
end

net.Receive("screengrab_fwd_init", function()
	local ply = net.ReadEntity()
	ply.SG = {}
	ply.SG.LEN = net.ReadUInt( 32 )
	ply.SG.PARTS = {}
	chat.AddText(Color(0, 200, 0), "[SG] Screengrab initialised on "..ply:Name().." ["..ply.SG.LEN.." parts]")
end)

net.Receive("screengrab_fwd", function()
	local ply = net.ReadEntity()
	local len = net.ReadUInt( 32 )
	local data = net.ReadData( len )

	if !ply:IsValid() then print("ply not val"); return end
	if ply.SG == nil then print("sg nil"); return end
	
	ply.SG.PARTS[ #ply.SG.PARTS + 1 ] = util.Decompress( data )
	if #ply.SG.PARTS == ply.SG.LEN then
		chat.AddText( Color(0,200,0), "[SG] Screengrab finished for "..ply:Name() )
		local finaldata = table.concat( ply.SG.PARTS )
		SCRG.ShowSC( finaldata, ply )
		ply.SG = nil
		SCRG.UPTO = 1
		SCRG.DATA = {}
	end

end)

net.Receive("screengrab_start", function()
	local qual = net.ReadInt( 32 )
	local info = {
		format = "jpeg",
		h = ScrH(),
		w = ScrW(),
		quality = qual,
		x = 0,
		y = 0
	}
	local splitamt = 20000
	local capdat = util.Base64Encode( cap( info ) )
	local len = string.len( capdat )
	local frags = math.ceil( len / splitamt )

	for i = 1, frags do
		local start = (i * splitamt) - splitamt + 1
		local stop = (i * splitamt)
		if stop > len then
			stop = len
		end
		SCRG.DATA[i] = string.sub( capdat, start, stop )
	end

	net.Start("screengrab_start")
		net.WriteUInt( frags, 32 )
	net.SendToServer()

end)

net.Receive( "screengrab_part", function()

	local nextsend = SCRG.DATA[ SCRG.UPTO ]

	local len = string.len( nextsend )
	nextsend = util.Compress( nextsend )
	
	net.Start( "screengrab_part")
		net.WriteUInt( len, 32 )
		net.WriteData( nextsend, len )
	net.SendToServer()
	if SCRG.UPTO == #SCRG.DATA then
		SCRG.UPTO = 1
		SCRG.DATA = {}
		return
	end
	SCRG.UPTO = SCRG.UPTO + 1

end)