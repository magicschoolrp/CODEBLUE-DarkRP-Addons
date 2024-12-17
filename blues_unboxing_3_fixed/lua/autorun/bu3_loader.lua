--The global table that stores everything
BU3 = {}

if SERVER then
	AddCSLuaFile("bu3_config.lua")
end

include("bu3_config.lua")

--Load all of the files

print("-----------------------------------------------------")
print("               LOADING BLUE'S UNBOXING 3             ") 
print("-----------------------------------------------------")
local files, folders = file.Find("bu3/*", "LUA")
for _, v in pairs(files) do
	if string.sub(v, 1, 3) == "cl_" then
		if CLIENT then
			include("bu3/"..v)
			print("Loaded "..v)
		else 
			AddCSLuaFile("bu3/"..v)
		end
	elseif string.sub(v, 1, 3) == "sh_" then 
		if CLIENT then
			include("bu3/"..v)
			print("Loaded "..v) 
		else
			AddCSLuaFile("bu3/"..v)
			include("bu3/"..v)
			print("Loaded "..v) 
		end
	elseif string.sub(v, 1, 3) == "sv_" then
		include("bu3/"..v)
		print("Loaded "..v)
	end
end

--Add CSLua file to all the pages
local files, folders = file.Find("bu3/pages/*", "LUA")

for _, v in pairs(files) do
	if SERVER then
		AddCSLuaFile("bu3/pages/"..v)
		print("Added page '"..v.."'")
	end
end

print("-----------------------------------------------------")
print("         FINISHED LOADING BLUES UNBOXING 3           ")
print("-----------------------------------------------------")

if SERVER then
	util.AddNetworkString("BU3:OpenGUI")
	hook.Add("PlayerSay" , "BU3:OpenTextCommand" , function(ply , text)
		if string.lower(text) == "!unbox" or string.lower(text) == "/unbox" then
			ply:UB3UpdateClient()
			net.Start("BU3:OpenGUI")
			net.Send(ply)
		end
	end) 
end