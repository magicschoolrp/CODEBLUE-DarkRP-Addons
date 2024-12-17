--[[-------------------------------------------------------------------------
This file will contain all the console commands for the addon
---------------------------------------------------------------------------]]

--Prints out all the items names and there id's
concommand.Add( "bu3_items", function( ply, cmd, args )
	print("----------------UNBOXING ITEM LIST-----------------")
	for k, v in pairs(BU3.Items.Items) do
		print(k, BU3.Items.Items[k].name)
	end
	print("---------------------------------------------------")
end)


if SERVER then
	concommand.Add( "bu3_give", function(_, __, args)
		--Check its a valid item
		if _:IsValid() then return end
		local sid = args[1]
		local itemIDToGive = tonumber(args[2])
		local amount = tonumber(args[3]) or 1

		local item = BU3.Items.Items[itemIDToGive]
		PrintTable(BU3.Items.Items)
		print(itemIDToGive)
		print(item)
		if item == nil then
			print("[UNBOXING 3] Invalid item ID. Do bu3_items in console to get a list of items and their id's")
			return
		end

		if sid == nil or sid == "" then
			print("Invalid SteamID64")
			print("The command works like this : bu3_give <STEAMID64> <ID> <AMOUNT>")

			return  
		end

		local ply = player.GetBySteamID64(sid)

		if ply == nil or not IsValid(ply) then
			print("[UNBOXING 3] Failed to add item, either the player is not in the server or the steamid64 is wrong!")
			print("The command works like this : bu3_give <STEAMID64> <ID> <AMOUNT>")
			return
		end

		--Okay all checks passed, lets give them there item
		ply:UB3AddItem(itemIDToGive, amount)

		print("[UNBOXING 3] Give '"..ply:Name().."' item '"..itemIDToGive.."'")

	end )

	--Gives an item to every player on the server
	concommand.Add( "bu3_give_all", function(_, __, args)
		if _:IsValid() then return end

		--Check its a valid item
		local itemIDToGive = tonumber(args[1])
		local amount = tonumber(args[2]) or 1

		local item = BU3.Items.Items[itemIDToGive]
		PrintTable(BU3.Items.Items)
		print(itemIDToGive)
		print(item)
		if item == nil then
			print("[UNBOXING 3] Invalid item ID. Do bu3_items in console to get a list of items and their id's")
			return
		end

		for k, v in pairs(player.GetAll()) do
			--Okay all checks passed, lets give them there item
			v:UB3AddItem(itemIDToGive, amount)
			print("[UNBOXING 3] Give '"..v:Name().."' item '"..itemIDToGive.."'")
		end
	end )

	--Deletes someone inventory
	concommand.Add( "bu3_wipe", function(_, __, args)
		if _:IsValid() then return end
		--Check its a valid item

		local sid = args[1]
		local itemIDToGive = tonumber(args[2])
		local amount = tonumber(args[3]) or 1

		if sid == nil or sid == "" then
			print("Invalid SteamID64")
			print("This command will wipe a players inventory: bu3_wipe <STEAMID64>")

			return  
		end

		local ply = player.GetBySteamID64(sid)

		--Now wipe the inventory
		if ply ~= nil then
			ply._ub3inv = {}
			ply:UB3SaveInventory()
			ply:UB3UpdateClient()

			print("[UNBOXING 3] Wiped players inventory!")
		else
			print("[UNBOXING 3] Failed to wipe players inventory!")
		end

	end )
end