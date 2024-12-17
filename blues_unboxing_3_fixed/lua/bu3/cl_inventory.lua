--[[-------------------------------------------------------------------------
Handles networking and unpacking of the server stuff
---------------------------------------------------------------------------]]

BU3.Inventory = {}
BU3.Inventory.Inventory = {} --The acctual inventory

function BU3.Inventory.UpdateInventory(data)
	local data = util.Decompress(data)
	data = util.JSONToTable(data)

	BU3.Inventory.Inventory = data

	--Check if the menu is open?
	if BU3.UI._MENU_OPEN then
		--Check if the page is inventory
		if BU3.UI.ContentFrame.loadedPageName == "inventory" then
			BU3.UI.ContentFrame:LoadPage("inventory") --Reload it
		end
	end
end

function BU3.Inventory.ItemCount()
	local amount = 0

	for k, v in pairs(BU3.Inventory.Inventory) do
		amount = amount + v
	end

	return amount
end

net.Receive("BU3:UpdateInventory", function()
	local dataLen = net.ReadDouble()
	local data = net.ReadData(dataLen)

	BU3.Inventory.UpdateInventory(data)
end)