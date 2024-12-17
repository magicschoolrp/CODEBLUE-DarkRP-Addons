timer.Create("bu3_item_drops", BU3.Config.DropTime * 60, 0, function()
	for k, v in pairs(player.GetAll()) do
		--Calculate chance
		local r = math.random(0, 100)
		print("working out chance")
		if r <= BU3.Config.DropChance then
			local item = table.Random(BU3.Config.DropItems)
			
			if BU3.Items.Items[item] == nil then return end

			print("user won")
			v:UB3AddItem(item, 1)
			v:ChatPrint("[UNBOXING] You received a random drop '"..BU3.Items.Items[item].name.."'")

		end 
	end
end)