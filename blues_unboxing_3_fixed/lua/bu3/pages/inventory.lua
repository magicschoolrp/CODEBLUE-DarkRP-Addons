local PAGE = {}

PAGE.toolTipPanel = nil

function  PAGE:ShowTooltip(parent, title, text, xPos, yPos)
	if self.toolTipPanel ~= nil then
		self.toolTipPanel:Remove()
	end

	self.toolTipPanel = vgui.Create("DPanel", parent)
	self.toolTipPanel:SetSize(145, 190)

	--if xPos + 140 + 10 > ScrW() then
	--	xPos = xPos - 145 - 10
	--else
	--	xPos = xPos + 140 + 10
	--end

	--if yPos + 190 >  ScrH() then
	--	yPos = yPos - 190
	--end

	--Size of panel p:SetSize(140, 190)

	self.toolTipPanel:SetPos(0, 0)
	--self.toolTipPanel:MakePopup()
	self.toolTipPanel:SetMouseInputEnabled(false)
	self.toolTipPanel.Paint = function()

	end

	local richtext = vgui.Create( "RichText", self.toolTipPanel)
	richtext:SetPos(0, 30)
	richtext:SetSize(145, 190 - 60)
	richtext:SetText(text)
	richtext:SetVerticalScrollbarEnabled(false)
end

function PAGE:HideTooltip()
	if self.toolTipPanel ~= nil then
		self.toolTipPanel:Remove()
	end
end

--This is called when the page is called to load
function PAGE:Load(contentFrame)

 	if self.toolTipPanel ~= nil then
		self.toolTipPanel:Remove()
	end

	self.mirrorPanel = vgui.Create("DPanel", contentFrame)
	self.mirrorPanel:SetSize(contentFrame:GetWide(), contentFrame:GetTall())
	self.mirrorPanel.Paint = function() end --Clear background

	local textPanel = vgui.Create("DPanel", self.mirrorPanel)
	textPanel:SetSize(400, 75)
	textPanel:SetPos(self.mirrorPanel:GetWide()/2 - 200,9)
	textPanel.Paint = function(s , w , h)
		draw.SimpleText("INVENTORY", BU3.UI.Fonts["large_bold"], w/2, h/2, Color(255,255,255,20),1 ,1)
	end

	--Displays all the items from a users inventory, takes a filter if needed
	local function DisplayItems(filter)
		local skipFilter = false
		if filter == nil or string.len(filter) < 1 then
			skipFilter = true
		end

		local items = BU3.Inventory.Inventory

		--Filter the items
		if not skipFilter then
			local filteredTable = {}
			for k ,v in pairs(items) do
				local item = BU3.Items.Items[k]
				if string.match(string.lower(item.name), string.lower(filter), 1) then
					filteredTable[k] = v
				end
			end
			items = filteredTable
		end

		--Create the scroll panel for the content
		if scrollPanel ~= nil then
			scrollPanel:Remove()
			scrollPanel = nil
		end

		scrollPanel = vgui.Create("DScrollPanel", self.mirrorPanel)
		scrollPanel:SetPos(30, 100)
		scrollPanel:SetSize(800 - 30, 630) 

		local sbar = scrollPanel:GetVBar()

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

		if table.Count(items) <= 0 then
			--No items found in filter, show no text
			local noItemsText = vgui.Create("DPanel", scrollPanel)
			noItemsText:SetSize(400, 75)
			noItemsText:SetPos(scrollPanel:GetWide()/2 - 200,9)
			noItemsText.Paint = function(s , w , h)
				draw.SimpleText("No items found.", BU3.UI.Fonts["large_bold"], w/2, h/2, Color(255,255,255,20),1 ,1)
			end		
		else
			local x = 0
			local y = 0

			for k, v in pairs(items) do
				for i = 1, v do
					local item = BU3.Items.Items[k]

					if item == nil then continue end

					local borderColor = item.itemColorCode or 1
					local borderColorRGB = BU3.Items.RarityToColor[borderColor]

					--Create the panel
					local p = vgui.Create("DPanel", scrollPanel)
					p:SetPos((152 * x), (203 * y))
					p:SetSize(140, 190)
					p.Paint = function(s, w, h)
						draw.RoundedBox(4, 0, 0, w, h, borderColorRGB)
						draw.RoundedBox(4, 1, 1, w - 2, h - 2, Color(40,40,45, 255))

						--Draw the item name
						local name = item.name
						if string.len(name) >= 15 then
							name = string.sub(name,1,12).."..." 
						end

						draw.SimpleText(name, BU3.UI.Fonts["small_reg"], w/2, 17, Color(200,200,200,255),1 ,1)
						draw.SimpleText("$"..string.Comma(item.price), BU3.UI.Fonts["small_bold"], w/2, h - 18, Color(200,200,200,255),1 ,1)
					end

					--Create the item preview
					local iconPreview = nil

					if item.iconIsModel then
						iconPreview = BU3.UI.Elements.ModelView(item.iconID, item.zoom, p)
					else
						iconPreview = BU3.UI.Elements.IconView(item.iconID, item.color, p, false)
					end
					
					iconPreview:SetPos(3, 25 + 3)
					iconPreview:SetSize(140 - 6, 140 - 6)
					iconPreview.zoom = item.zoom

					--Interaction button
					local button = vgui.Create("DButton", p)
					button:SetSize(140, 190)
					button:SetText("")
					button.LerpValue = 0
					button.Paint = function(s , w , h)
						if s:IsHovered() then
							s.LerpValue = Lerp(12 * FrameTime(), s.LerpValue, 255)
						else
							s.LerpValue = Lerp(12 * FrameTime(), s.LerpValue, 0)
						end

						draw.RoundedBox(4,0,0,w,h,Color(0,0,0,s.LerpValue / 1.5))
					end
					button.OnCursorEntered = function(s)
						local x, y = s:GetPos()
						local mX, mY = p:LocalToScreen(x, y)
						self:ShowTooltip(s, item.name, item.desc, mX, mY)
					end
					button.OnCursorExited = function()
						self:HideTooltip()
					end					
					button.DoClick = function()
						--Create list of options
						local Menu = DermaMenu()
						if item.type == "case" then
							Menu:AddOption("Open Crate", function()
								contentFrame:LoadPage("unbox", item.itemID)
							end)
						else
							if item.type == "points2" or item.type == "points1" then
								Menu:AddOption("Use Points", function()
									net.Start("BU3:UseItem")
									net.WriteInt(item.itemID, 32)
									net.SendToServer()
								end)
							end

							if item.type == "points2item" or item.type == "points1item" then
								Menu:AddOption("Use Pointshop Item", function()
									net.Start("BU3:UseItem")
									net.WriteInt(item.itemID, 32)
									net.SendToServer()
								end)
							end

							if item.type == "entity"  then
								Menu:AddOption("Spawn Entity", function()
									net.Start("BU3:UseItem")
									net.WriteInt(item.itemID, 32)
									net.SendToServer()
								end)
							end

							if item.type == "money" then
								Menu:AddOption("Add Money", function()
									net.Start("BU3:UseItem")
									net.WriteInt(item.itemID, 32)
									net.SendToServer()
								end)
							end

							if item.type == "weapon" then
								Menu:AddOption("Equip Weapon", function()
									net.Start("BU3:UseItem")
									net.WriteInt(item.itemID, 32)
									net.SendToServer()
								end)
							end

							if item.type == "lua" then
								Menu:AddOption("Use Item", function()
									net.Start("BU3:UseItem")
									net.WriteInt(item.itemID, 32)
									net.SendToServer()
								end)
							end
						end

						Menu:AddSpacer()

						local sub = Menu:AddSubMenu("Gift To Player...", function() end)

						for k , v in pairs(player.GetAll()) do
							if v ~= LocalPlayer() then
								local temp = sub:AddOption(v:Name() , function(s)
									net.Start("BU3:GiftItem")
										net.WriteInt(item.itemID, 32)
										net.WriteEntity(v)
									net.SendToServer()
								end)
							end
						end

						if item.canBeSold then
							--Menu:AddOption("Sell Item", function()

							--end)
						end

						Menu:AddSpacer()
						Menu:AddOption("Delete Item", function()
							net.Start("BU3:DeleteItem")
							net.WriteInt(item.itemID, 32)
							net.SendToServer()
						end)

						Menu:Open()

						--net message name = BU3:UseItem


						--contentFrame:LoadPage("unbox", item.itemID)
					end

					--Increment offet
					x = x + 1
					if x > 4 then
						y = y + 1
						x = 0
					end
				end
			end
		end
	end

	--Create the search box
	local searchBox = BU3.UI.Elements.CreateTextEntry("Search...", self.mirrorPanel, true, true)
	searchBox:SetPos(550, 24)
	searchBox:SetSize(280 - 20, 37)
	searchBox:SetUpdateOnType(true)
	searchBox.OnValueChange = function(s)
		DisplayItems(s:GetText())
	end

	DisplayItems()
end

--This is called when the page should unload
function PAGE:Unload(contentFrame, direction)
	self.mirrorPanel:Remove() --Remove all the UI we added to the content frame
end

--This can be called by anything to pass a message to the page
function PAGE:Message(message, data)

end

--Register the page
BU3.UI.RegisterPage("inventory", PAGE)