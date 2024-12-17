BU3.Items = {}

--A table of all the items, indexed via ID
BU3.Items.Items = {}
BU3.Items.RarityToColor = {
	[1] = Color(169,169,169, 255),--Gray
	[2] = Color(0,191,255, 255), --Light blue
	[3] = Color(128,0,128, 255), --Purple
	[4] = Color(255,0,255, 255),--Pink
	[5] = Color(255,0,0, 255),--Red
	[6] = Color(255,215,0, 255)--Gold!
}
BU3.Items.StringToRarity = {
	Gray = 1,
	Blue = 2,
	Purple = 3,
	Pink = 4,
	Red = 5,
	Gold = 6
}

BU3.Items.RarityToString = {
	[1] = "Gray",
	[2] = "Blue",
	[3] = "Purple",
	[4] = "Pink",
	[5] = "Red",
	[6] = "Gold"
}

--All the types of items there can be
BU3.Items.Types = {
	customLua = 1, --The item runs custom lua
	weapon = 2, --The item is a weapon
	money = 3, --The item is money
	points1 = 4, --The item is points (pointshop1)
	points2 = 5, --The item is points (pointshop2)
	points2pre = 6, --The item is points (pointshop2 premium)
	points1item = 7, --The item is an item for pointshop1
	points2item = 8, --The item is a pointshop2 item
	entity = 9 --The item is a basic entity
}

local ITEM = {}
ITEMMetaAccessor = {__index = ITEM}

--[[-------------------------------------------------------------------------
Accessor functions, some are not listed such as getmoney, get points etc as 
you can direct access the tables for them
---------------------------------------------------------------------------]]
function ITEM:GetName()
	return self.name
end

function ITEM:GetDescription()
	return self.description
end

function ITEM:GetID()
	return self.id
end

function ITEM:GetSuggestedValue()
	return self.suggestedValue
end

function ITEM:GetMarketHistory()
	return self.marketHistory
end

function ITEM:GetItemType()
	return self.itemType
end

function ITEM:GetAveragePrice()
	return self.averagePrice
end

function ITEM:GetOnPress()
	return self.onPress
end

function ITEM:GetOnUnbox()
	return self.onUnbox
end

function ITEM:GetMarketListings()
	return self.market
end

function ITEM:GetPerma()
	return self.perma
end

--Registers an item in the item table
function BU3.Items.RegisterItem(itemID, itemData)
	local item = setmetatable(itemData, ITEMMetaAccessor)
	BU3.Items.Items[itemID] = item
end

--Tries to find an item based on its ID, if it fails it returns false
function BU3.Items.GetItemByID(itemID)
	if BU3.Items.Items[itemID] ~= nil then
		return BU3.Items.Items[itemID]
	else
		return false
	end
end

--Returns all items that can be bought
function BU3.Items.GetBuyableItems()
	local buyableItems = {}
	for k, v in pairs(BU3.Items.Items) do
		if v.canBeBought then
			table.insert(buyableItems, v)
		end
	end

	return buyableItems
end

--[[-------------------------------------------------------------------------
Networking stuff
---------------------------------------------------------------------------]]

net.Receive("BU3:NetworkItem", function()
	local item = net.ReadTable()
	BU3.Items.RegisterItem(item.itemID, item)
end)

net.Receive("BU3:CLDeleteItem", function()
	local itemID = net.ReadInt(32)
	BU3.Items.Items[itemID] = nil
end)

net.Receive("BU3:NetworkItemTable", function()
	local dataLen = net.ReadDouble()
	local rawData = net.ReadData(dataLen)
	local uncompressedData = util.Decompress(rawData)
	local rawTables = util.JSONToTable(uncompressedData)

	for k, v in pairs(rawTables) do
		v.color = Color(v.color.r, v.color.g, v.color.b, v.color.a)
		BU3.Items.RegisterItem(v.itemID, v)
	end
end)