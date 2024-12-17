local PAGE = {}

--When set to true it will start spinning the tape
PAGE.startSpinning = false
PAGE.open = false

--This is called when the page is called to load
function PAGE:Load(contentFrame, caseID)
	contentFrame.NavBar:SelectButton("unknown") --Deselects all the buttons

	self.previousSoundTime = CurTime()
	self.previousSoundPosition = 0

	local case = BU3.Items.Items[caseID]
	self.startSpinning  = false
	self.open = true

	self.mirrorPanel = vgui.Create("DPanel", contentFrame)
	self.mirrorPanel:SetSize(contentFrame:GetWide(), contentFrame:GetTall())
	self.mirrorPanel.Paint = function(s,w,h) 
		--Draw seperator
		draw.RoundedBox(0,0, 318 , w, 2, Color(40,40,45))
	end --Clear background

	if case == nil or case.type ~= "case" then
		local textPanel = vgui.Create("DPanel", self.mirrorPanel)
		textPanel:SetSize(400, 75)
		textPanel:SetPos(self.mirrorPanel:GetWide()/2 - 200,9)
		textPanel.Paint = function(s , w , h)
			draw.SimpleText("ERROR : CASE INVALID", BU3.UI.Fonts["large_bold"], w/2, h/2, Color(255,255,255,20),1 ,1)
		end

		return		
	end

	local textPanel = vgui.Create("DPanel", self.mirrorPanel)
	textPanel:SetSize(400, 75)
	textPanel:SetPos(self.mirrorPanel:GetWide()/2 - 200,9)
	textPanel.Paint = function(s , w , h)
		draw.SimpleText("Preview: "..case.name, BU3.UI.Fonts["large_bold"], w/2, h/2, Color(255,255,255,20),1 ,1)
	end

	local scrollWindowPanel = vgui.Create("DPanel", self.mirrorPanel)
	scrollWindowPanel:SetPos(38, 100 + 15)
	scrollWindowPanel:SetSize(740, 140)
	scrollWindowPanel.Paint = function() end

	--Magic number is 72

	local tapePanel = vgui.Create("DPanel", scrollWindowPanel)
	tapePanel:SetSize(145 * 80, 140)
	tapePanel.soundPlayed = false
	tapePanel.Paint = function() end
	local targetPos = -10000 - (5) + (math.random(-55, 55))
	local speed = 1
	local lerpedPos = 0
	tapePanel.Think = function(s)

	end

	--Display all the items
	local itemPanels = {}
	local randomItems = BU3.Chances.GenerateList(case.itemID, 80)
	for i = 1, 80 do
		local xpos = 20 + ((i-1) * 145)
		local xsize = 130

		local borderColorRGB = BU3.Items.RarityToColor[1]


		local p = vgui.Create("DPanel", tapePanel)
		p:SetPos(xpos, 0)
		p:SetSize(xsize, 140)
		p.Paint = function(s, w, h)
			draw.RoundedBox(4, 0, 0, w, h, borderColorRGB)
			draw.RoundedBox(4, 1, 1, w - 2, h - 2, Color(40,40,45, 255))

			--Draw the item name
			local name = "Preview"
			if string.len(name) >= 15 then
				name = string.sub(name,1,12).."..." 
			end

			draw.SimpleText(name, BU3.UI.Fonts["small_reg"], w/2, 17, Color(200,200,200,255),1 ,1)
		end

		itemPanels[i] = p

		--Create the item preview
		local iconPreview = nil

		iconPreview = BU3.UI.Elements.IconView("help", Color(255,255,255, 100), p, false)

		iconPreview:SetPos(12, 25 + 3)
		iconPreview:SetSize(130 - 24, 130 - 24)
		iconPreview.zoom = 0

		p.iconPreview = iconPreview
	end


	local gradientWindow = vgui.Create("DPanel", scrollWindowPanel)
	gradientWindow:SetPos(0, 0)
	gradientWindow:SetSize(740, 140)
	gradientWindow.Paint = function(s, w, h)
		--Draw left size gradient
		surface.SetDrawColor(Color(255,255,255,255))
		surface.SetMaterial(BU3.UI.Materials.gradient)
		surface.DrawTexturedRectRotated(w - 98, h/2, 200, h, 180)
		surface.DrawTexturedRect(0,0,200,h)
	end

	local marker1 = vgui.Create("DPanel",self.mirrorPanel)
	marker1:SetPos(self.mirrorPanel:GetWide() / 2 - (22/2), 70 + 15)
	marker1:SetSize(22, 20)
	marker1.Paint = function(s , w , h)
		surface.SetDrawColor(Color(39, 121, 189))
		surface.SetMaterial(BU3.UI.Materials.marker)
		surface.DrawTexturedRectRotated(w/2,h/2,h, w, -90)
	end

	local marker2 = vgui.Create("DPanel",self.mirrorPanel)
	marker2:SetPos(self.mirrorPanel:GetWide() / 2 - (22/2), 250 + 15)
	marker2:SetSize(22, 20)
	marker2.Paint = function(s , w , h)
		surface.SetDrawColor(Color(39, 121, 189))
		surface.SetMaterial(BU3.UI.Materials.marker)
		surface.DrawTexturedRectRotated(w/2,h/2,h, w, 90)
	end

	--Unbox button
	--350
	local unboxButton = BU3.UI.Elements.CreateStandardButton("*PREVIEW*", self.mirrorPanel, function()

	end)
	unboxButton:SetSize(160, 50)
	unboxButton:SetPos(self.mirrorPanel:GetWide()/2 - 80, 350)

	local textPanel2 = vgui.Create("DPanel", self.mirrorPanel)
	textPanel2:SetSize(600, 75)
	textPanel2:SetPos(self.mirrorPanel:GetWide()/2 - 300,420)
	textPanel2.Paint = function(s , w , h)
		draw.SimpleText("Items contained inside: "..case.name, BU3.UI.Fonts["med_bold"], w/2, h/2, Color(255,255,255,20),1 ,1)
	end

	local itemContainedPanel = vgui.Create("DScrollPanel", self.mirrorPanel)
	itemContainedPanel:SetPos(125, 490)
	itemContainedPanel:SetSize(600, 240)

	local sbar = itemContainedPanel:GetVBar()

	function sbar:Paint( w, h )
		--draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 100 ) )
	end
	function sbar.btnUp:Paint( w, h )
		--draw.RoundedBox( 0, 0, 0, w, h, Color( 200, 100, 0 ) )
	end
	function sbar.btnDown:Paint( w, h )
		--draw.RoundedBox( 0, 0, 0, w, h, Color( 200, 100, 0 ) )
	end
	sbar.btnGrip:NoClipping(true)
	function sbar.btnGrip:Paint( w, h )
		draw.RoundedBox( 8, 4, -10, w - 4, h + 20, Color(39, 121, 189, 255) )
	end

	--Create the list of items
	--for k, v in pairs(items) do
	local x, y = 0, 0

	local items = table.Copy(case.items)

	for k, v in SortedPairsByValue(case.items, true) do
		local item = BU3.Items.Items[k]
		local xpos = x * 145
		local xsize = 130

		local borderColor = item.itemColorCode or 1
		local borderColorRGB = BU3.Items.RarityToColor[borderColor]

		local p = vgui.Create("DPanel", itemContainedPanel)
		p:SetPos(xpos, y * 155)
		p:SetSize(xsize, 140)
		p.Paint = function(s, w, h)
			draw.RoundedBox(4, 0, 0, w, h, borderColorRGB)
			draw.RoundedBox(4, 1, 1, w - 2, h - 2, Color(40,40,45, 255))

			--Draw the item name
			local name = item.name
			if string.len(name) >= 15 then
				name = string.sub(name,1,12).."..." 
			end

			draw.SimpleText(name, BU3.UI.Fonts["small_reg"], w/2, 17, Color(200,200,200,255),1 ,1)
		end

		--Create the item preview
		local iconPreview = nil

		if item.iconIsModel then
			iconPreview = BU3.UI.Elements.ModelView(item.iconID, item.zoom, p)
		else
			iconPreview = BU3.UI.Elements.IconView(item.iconID, item.color, p, false)
		end
		
		iconPreview:SetPos(12, 25 + 3)
		iconPreview:SetSize(130 - 24, 130 - 24)
		iconPreview.zoom = item.zoom

		--Increment offet
		x = x + 1
		if x > 3 then
			y = y + 1
			x = 0
		end
	end

	local gradientWindow2 = vgui.Create("DPanel", self.mirrorPanel)
	gradientWindow2:SetPos(125, 490)
	gradientWindow2:SetSize(580, 240)
	gradientWindow2.Paint = function(s, w, h)
		--Draw left size gradient
		--draw.RoundedBox(0,0,0,w,h,Color(255,255,255))
		surface.SetDrawColor(Color(255,255,255,255))
		surface.SetMaterial(BU3.UI.Materials.gradient)
		--surface.DrawTexturedRectRotated(w/2, 5, 10, w, -90)
		surface.DrawTexturedRectRotated(w/2, h-20, 40, w, 90)
		--surface.DrawTexturedRect(0,0,200,h)
	end

	net.Receive("BU3:TriggerUnboxAnimation", function()
		local itemID = net.ReadInt(32)

		--Lets check if the page is still valid, if so set up the last item
		--and play the animation
		if self.open then
			local i = 72
			--Set up the item
			itemPanels[i]:Remove()

			local item = BU3.Items.Items[itemID]
			local xpos = 20 + ((i-1) * 145)
			local xsize = 130

			local borderColor = item.itemColorCode or 1
			local borderColorRGB = BU3.Items.RarityToColor[borderColor]


			local p = vgui.Create("DPanel", tapePanel)
			p:SetPos(xpos, 0)
			p:SetSize(xsize, 140)
			p.Paint = function(s, w, h)
				draw.RoundedBox(4, 0, 0, w, h, borderColorRGB)
				draw.RoundedBox(4, 1, 1, w - 2, h - 2, Color(40,40,45, 255))

				--Draw the item name
				local name = item.name
				if string.len(name) >= 15 then
					name = string.sub(name,1,12).."..." 
				end

				draw.SimpleText(name, BU3.UI.Fonts["small_reg"], w/2, 17, Color(200,200,200,255),1 ,1)
			end

			itemPanels[i] = p

			--Create the item preview
			local iconPreview = nil

			if item.iconIsModel then
				iconPreview = BU3.UI.Elements.ModelView(item.iconID, item.zoom, p)
			else
				iconPreview = BU3.UI.Elements.IconView(item.iconID, item.color, p, false)
			end

			iconPreview:SetPos(12, 25 + 3)
			iconPreview:SetSize(130 - 24, 130 - 24)
			iconPreview.zoom = item.zoom

			p.iconPreview = iconPreview	

			--Begin spinning
			self.startSpinning = true	
		end
	end)
end


--This is called when the page should unload
function PAGE:Unload(contentFrame, direction)
	self.mirrorPanel:Remove() --Remove all the UI we added to the content frame
	self.open = false
end

--This can be called by anything to pass a message to the page
function PAGE:Message(message, data)

end

--Register the page
BU3.UI.RegisterPage("preview", PAGE)