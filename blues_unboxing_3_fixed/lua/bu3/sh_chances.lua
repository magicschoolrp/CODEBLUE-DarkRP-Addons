--[[-------------------------------------------------------------------------
This file is used to calculate chances and generate a list of random items
---------------------------------------------------------------------------]]

BU3.Chances = {}

--Flush random seed
math.randomseed(os.time())
math.random()
math.random()

function generateItem(itemID)

	local totalChance = 0

	for k , v in pairs(BUC2.ITEMS[itemID].items) do
		
			v = BUC2.ITEMS[v]

			totalChance = totalChance + v.chance

	end

	local itemList = {}
		

	return item
 
end

--Generates a random case
function BU3.Chances.GenerateSingle(caseID)
	--Get list of items from case
	if BU3.Items.Items[caseID] ~= nil and BU3.Items.Items[caseID].type == "case" then
		local case = BU3.Items.Items[caseID]

		--Loop over items and create the chances
		local totalChance = 0
		for k ,v in pairs(case.items) do
			totalChance = totalChance + v
		end

		local num = math.random(1 , totalChance)
		local prevCheck = 0
		local curCheck = 0
		local item = nil

		for k ,v in pairs(case.items) do
			if num >= prevCheck and num <= prevCheck + v then
				item = k
			end
			prevCheck = prevCheck + v
		end

		--return the result
		return item
	end 
end

--Generates a random list of item ID's and returns them
--as a table
function BU3.Chances.GenerateList(caseID, amount)
	local items = {}

	for i = 1 , amount do
		items[i] = BU3.Chances.GenerateSingle(caseID)
	end

	return items
end