--[[-------------------------------------------------------------------------
This file handles the players inventory, loading, saving, networking etc
---------------------------------------------------------------------------]]


local PLAYER = FindMetaTable("Player")

--All functions in here that are part of the player meta
--Must be prefixed with UB3

--Attempts to load, if it fails then it create the empty inventory
-- Initialize the unboxing inventory with a delay to avoid conflicts during player spawn
function PLAYER:UB3InitializeInventory()
    -- Wait until the player is fully initialized (after spawning)
    timer.Simple(2, function()
        if not IsValid(self) then return end
        self._ub3inv = {} --Inventory
        self:UB3LoadInventory()
        print("[UNBOXING 3] Set up inventory for player '"..self:Name().."'")
    end)
end


--Adds items to a players inventory
function PLAYER:UB3AddItem(itemID, amount)
	if self._ub3inv[itemID] == nil then
		self._ub3inv[itemID] = amount
	else
		self._ub3inv[itemID] = self._ub3inv[itemID] + amount
	end

	print("added item", itemID, amount, self)

	self:UB3UpdateClient()
	self:UB3SaveInventory()

	return true
end

--Tried to remove an item, if it fails to remove that ammount it will return false
function PLAYER:UB3RemoveItem(itemID, amount)
	if self._ub3inv[itemID] == nil then
		return false
	else
		if self._ub3inv[itemID] >= amount then
			self._ub3inv[itemID] = self._ub3inv[itemID] - amount
			if self._ub3inv[itemID] == 0 then
				self._ub3inv[itemID] = nil --Remove it from the inventory if there are none left
			end

			self:UB3UpdateClient()
			self:UB3SaveInventory()

			return true
		end
	end
end

--Tries to gift a player an item
function PLAYER:BU3GiftItem(itemID, target)
	local item = BU3.Items.Items[itemID]
	local hasOne, amount = self:UB3HasItem(itemID)

	if hasOne and item.gift then
		if self:UB3RemoveItem(itemID, 1) then
			--Add it to the other persons inventory
			target:UB3AddItem(itemID, 1)

			net.Start("BU3:AddEventHistory")
			net.WriteString("'"..self:Name().."' gifted '"..target:Name().."' a '"..BU3.Items.Items[itemID].name.."'")
			net.Broadcast()

			self:BU3AddStat("gift", 1)
		end
	end
end

--Returns true if yes, false if not (also returns a number of how many they have)
function PLAYER:UB3HasItem(itemID)
	if self._ub3inv[itemID] == nil then 
		return false
	end

	if self._ub3inv[itemID] > 0 then
		return true, self._ub3inv[itemID]
	end
end

--Saves the players inventory
function PLAYER:UB3SaveInventory()
	--TODO
	BU3.SQL.SaveInventory(self:SteamID64(), self._ub3inv)
end


--Returns true if the inventory loaded, false it if failed
function PLAYER:UB3LoadInventory()
	--TODO
	BU3.SQL.LoadInventory(self:SteamID64(), function(inv)
		if inv == false then
			self._ub3inv = {}
		else
			self._ub3inv = inv
		end
	end)

	--Load there stats too
	self:BU3LoadStats()

	return false
end

--This function network an update of the inventory to the client
function PLAYER:UB3UpdateClient()

	--First lets make sure we have all the items that exist
	for k, v in pairs(self._ub3inv) do
		if BU3.Items.Items[k] == nil then
			self._ub3inv[k] = nil
		end
	end

	local data = util.TableToJSON(self._ub3inv)
	data = util.Compress(data)

	local dataLen = string.len(data)

	net.Start("BU3:UpdateInventory")
	net.WriteDouble(dataLen)
	net.WriteData(data, dataLen)
	net.Send(self)

	--Also send them an update of there stats
	self:BU3UpdateClientStats()
end

--[[-------------------------------------------------------------------------
These are logic functions for attual items, such as equip, use
---------------------------------------------------------------------------]]

--Attempts to use an item
function PLAYER:BU3UseItem(itemID)
	local item = BU3.Items.Items[itemID]

	if item == nil then return end --Item is not valid

	--Check they have the rank required to use the item if its rank restricted
	if item.rankRestricted == true then
		if not table.HasValue(item.ranks, self:GetUserGroup()) then
			self:SendLua([[notification.AddLegacy("You don't have the rank required to use this item!", NOTIFY_ERROR, 5)]])
			return
		end
	end

	--Check if they have the item
	if not self:UB3HasItem(itemID) then return end

	--Remove the item if its not permanent
	if item.perm ~= true then
		self:UB3RemoveItem(itemID, 1)
	end

	--Perform the action for the item
	if item.type == "weapon" then
		--Give them the weapon
		self:Give(item.className)
		return
	end

	--Spawn the entity
	if item.type == "entity" then
		local trace = self:GetEyeTrace()
		local posToSpawn = Vector(0,0,0)

		if trace.HitPos:Distance(self:GetPos()) > 200 then
			posToSpawn = (self:GetPos() + Vector(0,0,50)) + (self:GetAimVector() * 100 )
		else
			posToSpawn = trace.HitPos
		end

		local temp = ents.Create(item.className)
		temp:SetPos(posToSpawn)
		temp:Spawn()

		if temp.Setowning_ent ~= nil then
			temp:Setowning_ent(self)
		end

		self:SendLua([[notification.AddLegacy("[UNBOX] Entity Spawned!", NOTIFY_HINT, 5)]])

		return
	end

	if item.type == "points1" then
		self:PS_GivePoints(tonumber(item.pointsAmount))
		self:SendLua([[notification.AddLegacy("[UNBOX] Added Points!", NOTIFY_HINT, 5)]])
	end

	if item.type == "points2" then
		if not item.premium then
			self:PS2_AddStandardPoints(tonumber(item.pointsAmount), "Added from Unboxing 3")
			self:SendLua([[notification.AddLegacy("[UNBOX] Added Points!", NOTIFY_HINT, 5)]])
		else
			self:PS2_AddPremiumPoints(tonumber(item.pointsAmount))
			self:SendLua([[notification.AddLegacy("[UNBOX] Added Premium Points!", NOTIFY_HINT, 5)]])
		end
	end	

	if item.type == "points1item" then
		print("Giving item class name ", item.className )
		self:PS_GiveItem(item.className)
		self:SendLua([[notification.AddLegacy("[UNBOX] Added Pointshop Item!", NOTIFY_HINT, 5)]])
	end	

	if item.type == "points2item" then        
		local itemClass = Pointshop2.GetItemClassByPrintName( item.className )
        if not itemClass then
            error( "Invalid item " .. tostring( item.className ) )
        end

		self:PS2_EasyAddItem( itemClass.className )
		self:SendLua([[notification.AddLegacy("[UNBOX] Added Pointshop Item!", NOTIFY_HINT, 5)]])
	end	

	if item.type == "money" then
		self:addMoney(tonumber(item.moneyAmount))
		self:SendLua([[notification.AddLegacy("[UNBOX] Added Money!", NOTIFY_HINT, 5)]])
	end	

	if item.type == "lua" then
		--Lua to execute
		local bootstrap = [[
			local PLY = Player(]]..self:UserID()..[[)
		]]
		local func = CompileString(bootstrap..item.lua, "BU3:ItemExecution"..math.random(10000,10000000), true)
		func()
	end	

	--If its a custom Lua entity perfom the actions
	--TODO
end


--[[-------------------------------------------------------------------------
Hooks
---------------------------------------------------------------------------]]
hook.Add("PlayerInitialSpawn", "UB3:SETUPINVENTORY", function(ply)
	ply:UB3InitializeInventory()
end)

--[[-------------------------------------------------------------------------
Networking stuff
---------------------------------------------------------------------------]]
util.AddNetworkString("BU3:UpdateInventory")
util.AddNetworkString("BU3:UseItem")
util.AddNetworkString("BU3:DeleteItem")
util.AddNetworkString("BU3:GiftItem")
util.AddNetworkString("BU3:AddEventHistory")
util.AddNetworkString("BU3:AdminOpenInventory")
util.AddNetworkString("UB3:AdminDeleteItem")

net.Receive("BU3:UseItem", function(len, ply)
	local itemID = net.ReadInt(32)
	ply:BU3UseItem(itemID or -1)
end)


net.Receive("BU3:GiftItem", function(len, ply)
	local itemID = net.ReadInt(32)
	local target = net.ReadEntity()

	if IsValid(target) and target:IsPlayer() and target ~= ply then
		if BU3.Items.Items[itemID] ~= nil then
			ply:BU3GiftItem(itemID, target)
		end
	end
end)

net.Receive("BU3:DeleteItem", function(len, ply)
	local itemID = net.ReadInt(32)
	ply:UB3RemoveItem(itemID or -1, 1)
end)

net.Receive("UB3:AdminDeleteItem", function(len, ply)
	if table.HasValue(BU3.Config.AdminRanks, ply:GetUserGroup()) then
		local target = net.ReadEntity()
		local itemID = net.ReadInt(32)

		if target ~= nil and IsValid(target) then

			--Attempt to delete that item 
			target:UB3RemoveItem(itemID or -1, 1)

			--Compress the targets inventory
			local inv = util.TableToJSON(target._ub3inv)
			inv = util.Compress(inv)
			local size = string.len(inv)

			net.Start("BU3:AdminOpenInventory")
			net.WriteDouble(size)
			net.WriteData(inv, size)
			net.WriteEntity(target)
			net.Send(ply)

		end
	end
end)

net.Receive("BU3:AdminOpenInventory", function(len, ply)
	if table.HasValue(BU3.Config.AdminRanks, ply:GetUserGroup()) then
		local target = net.ReadEntity()
		if target ~= nil and IsValid(target) then
			--Compress the targets inventory
			local inv = util.TableToJSON(target._ub3inv)
			inv = util.Compress(inv)
			local size = string.len(inv)

			net.Start("BU3:AdminOpenInventory")
			net.WriteDouble(size)
			net.WriteData(inv, size)
			net.WriteEntity(target)
			net.Send(ply)

		end
	end
end)