local PAGE = {}

--This is called when the page is called to load
function PAGE:Load(contentFrame)

	self.mirrorPanel = vgui.Create("DPanel", contentFrame)
	self.mirrorPanel:SetSize(contentFrame:GetWide(), contentFrame:GetTall())
	self.mirrorPanel.Paint = function() end --Clear background

	local textPanel = vgui.Create("DPanel", self.mirrorPanel)
	textPanel:SetSize(400, 75)
	textPanel:SetPos(self.mirrorPanel:GetWide()/2 - 200,9)
	textPanel.Paint = function(s , w , h)
		draw.SimpleText("UNBOXING 3", BU3.UI.Fonts["large_bold"], w/2, h/2, Color(255,255,255,20),1 ,1)
	end

	--Now do all the text info
	local invValue = BU3.UI.Elements.CreateInfoPanel(BU3.Inventory.ItemCount(), "Number Of Items", self.mirrorPanel)
	invValue:SetPos(25, 85)
	invValue:SetSize(380, 130)

	local stats = BU3.Stats

	--Now do all the text info
	local val = "?"
	if stats["gift"] ~= nil then
		val = stats["gift"]
	end
	local otherVal = BU3.UI.Elements.CreateInfoPanel(val, "Numbers Of Items Traded", self.mirrorPanel)
	otherVal:SetPos(422, 85)
	otherVal:SetSize(380, 130)

	--Now do all the text info
	local val = "?"
	if stats["case"] ~= nil then
		val = stats["case"]
	end
	local numOfItems = BU3.UI.Elements.CreateInfoPanel(val, "Opened Cases", self.mirrorPanel)
	numOfItems:SetPos(25, 85 + 155)
	numOfItems:SetSize(380, 130)

	--Now do all the text info
		local val = "?"
	if stats["purchase"] ~= nil then
		val = stats["purchase"]
	end
	local itemsSold = BU3.UI.Elements.CreateInfoPanel(val, "Items Purchased", self.mirrorPanel)
	itemsSold:SetPos(422, 85 + 155)
	itemsSold:SetSize(380, 130)

	local textPanel = vgui.Create("DPanel", self.mirrorPanel)
	textPanel:SetSize(400, 75)
	textPanel:SetPos(25, 85 + 155  +120)
	textPanel.Paint = function(s , w , h)
		draw.SimpleText("Activity", BU3.UI.Fonts["med_bold"], 2, h/2, Color(255,255,255,50),0 ,1)
	end

	local panel = vgui.Create("DPanel", self.mirrorPanel)
	panel:SetPos(25, 85 + 155  +160 + 20)
	panel:SetSize(contentFrame:GetWide() - 50, 305)
	panel.Paint = function(s , w, h)
		draw.RoundedBoxEx(16,0,0,w,h,Color(40,40,45),false, true, true, true)

		for i = 1 , 13 do
			local text = BU3.UI.EventHistory[i]

			if text ~= nil then
				draw.SimpleText(text, BU3.UI.Fonts["small_reg"],10, 5 + ((i-1) * 22),Color(255,255,255,100))
			end
		end
	end

end

--This is called when the page should unload
function PAGE:Unload(contentFrame, direction)
	self.mirrorPanel:Remove() --Remove all the UI we added to the content frame
end
--385 130
--This can be called by anything to pass a message to the page
function PAGE:Message(message, data)

end

--Register the page
BU3.UI.RegisterPage("home", PAGE)