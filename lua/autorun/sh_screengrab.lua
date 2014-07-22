SCRG = {}
-- I was told I was allowed to upload! If somehow this isn't allowed, PLEASE TELL ME I'LL REMOVE IT RIGHT-AWAY. Public addon aswell!
MsgN("Initialising screengrab by Pablo")

if SERVER then
	AddCSLuaFile("cl_screengrab.lua")
	include("sv_screengrab.lua" )
else
	include( "cl_screengrab.lua" )
end