--[[-------------------------------------------------------------------------
This file handles networking and checking
when a user tries to unbox.
---------------------------------------------------------------------------]]

util.AddNetworkString("BU3:TriggerUnboxAnimation")
util.AddNetworkString("BU3:AttemptUnbox")
util.AddNetworkString("BU3:UnboxAnounce")

--This will attempt to unbox an item for the user, add it to there inventory then do the animation
function BU3.UnboxCase(ply, caseID)
	if ply.isUnboxing then return end --Don't let them unbox yet

	--First check case ID is valid
	local case = BU3.Items.Items[caseID]

	--Check case is valid
	if case == nil or case.type ~= "case" then
		return false
	end

	--Check the user has the case
	if not ply:UB3HasItem(caseID) then return end

	--Find the keys that opens this case
	local keyIDs = {}
	for k, v in pairs(BU3.Items.Items) do
		if v.type == "key" then
			for a, b in pairs(v.items) do
				if b == case.itemID then
					table.insert(keyIDs, v.itemID)
				end
			end
		end
	end

	--Failed to find key
	if table.Count(keyIDs) < 1 then 
		ply:SendLua([[notification.AddLegacy("No key can open this crate.", NOTIFY_ERROR, 5)]])
		return 
	end

	--Check if user has key
	local hasAKey = false
	local usedKey = -1
	for k, v in pairs(keyIDs) do
		if ply:UB3HasItem(v) then
			usedKey = v
			break
		end
	end


	if not ply:UB3HasItem(usedKey) then 
		ply:SendLua([[notification.AddLegacy("You don't have the key required.", NOTIFY_ERROR, 5)]])
		return 
	end

	--Generate the item to give them
	local wonItem = BU3.Chances.GenerateSingle(case.itemID)

	--Check item is valid
	if wonItem == nil or wonItem == false then return end

	--Take the key
	if not ply:UB3RemoveItem(usedKey, 1) then return end
	if not ply:UB3RemoveItem(caseID, 1) then return end

	--Now tell the client what they are getting and to spin to it.
	net.Start("BU3:TriggerUnboxAnimation")
	net.WriteInt(wonItem, 32)
	net.Send(ply)

	ply.isUnboxing = true

	timer.Simple(8, function()
		ply.isUnboxing = false

		if BU3.Config.ChatNotifications == true or BU3.Config.ChatNotifications == nil then
			net.Start("BU3:UnboxAnounce")
			net.WriteInt(wonItem, 32)
			net.WriteEntity(ply)
			net.Broadcast()
		end

		net.Start("BU3:AddEventHistory")
		net.WriteString("'"..ply:Name().."' unboxed a '"..BU3.Items.Items[wonItem].name.."'")
		net.Broadcast()
		--Give the user the item
		ply:UB3AddItem(wonItem, 1)
		ply:BU3AddStat("case", 1)
	end)
end

net.Receive("BU3:AttemptUnbox", function(len, ply)
	local caseID = net.ReadInt(32)

	if BU3.Items.Items[caseID] ~= nil and BU3.Items.Items[caseID].type == "case" then
		BU3.UnboxCase(ply, caseID)
	end
end)