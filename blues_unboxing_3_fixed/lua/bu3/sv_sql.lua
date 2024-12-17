--[[-------------------------------------------------------------------------
This file is used to easily interface with SQLite or MySQL to save and load items and inventories
---------------------------------------------------------------------------]]

include("bu3_sql_config.lua")

BU3.SQL = {}

--Load MYSQLOO if we are using it
if BU3.SQLConfig.UseMySQL then
	--Load up MySQLoo
	require("mysqloo")
	BU3.SQL.MySQL = mysqloo
	print("Found MySQLOO version "..mysqloo.VERSION)
end

--This function will load all the items from the database
function BU3.SQL.LoadItems()
	if not BU3.SQLConfig.UseMySQL then
		--Get all the items
		local itemData = sql.Query("SELECT * FROM bu3_items;")
		if itemData == nil then
			BU3.ItemsIndex = 0
			return
		else
			for k, v in pairs(itemData) do
				local rawTable = util.JSONToTable(v.itemData)

				--Before creating the item we need to fix some stuff about it
				rawTable.color = Color(rawTable.color.r, rawTable.color.g, rawTable.color.b, rawTable.color.a)

				--Register it
				BU3.Items.CreateItem(rawTable, true)
			end

			--Now that we have the items registered. We need to find the largest itemID in the list so that new items dont
			--override old ones
			local max = sql.Query("SELECT MAX(itemID) FROM bu3_items;")

			if max ~= nil and max[1] ~= nil and max[1]["MAX(itemID)"] ~= nil then
				local maxIndex = max[1]["MAX(itemID)"] + 1
				BU3.ItemsIndex = maxIndex
			end
		end
	else
		--MySQL implementation
		local query = BU3.SQL.MySQLInstance:query("SELECT * FROM bu3_items;")

		function query:onSuccess(data)
			local highestID = 0
			for k, v in pairs(data) do 	
				local rawTable = util.JSONToTable(v.itemData)

				if rawTable ~= nil and IsValid(rawTable) then
					--Before creating the item we need to fix some stuff about it
					rawTable.color = Color(rawTable.color.r, rawTable.color.g, rawTable.color.b, rawTable.color.a)
	 
					--Register it
					BU3.Items.CreateItem(rawTable, true)

					if v.itemID >= highestID then
						highestID = v.itemID + 1
					end
				else
					print("ERROR: Failed to loaded blue's unboxing item ID '"..k.."'...Skipping!")
				end
			end

			--Update highest index
			BU3.ItemsIndex = highestID
		end

		function query:onError(err)
			print("[UNBOXING] Failed to save inventory, open a support ticket with the following error. ERROR:"..err)
		end	

		query:start()
		query:wait()
	end
end

--This will try to save an item to the SQL database
function BU3.SQL.SaveItem(itemID)
	if not BU3.SQLConfig.UseMySQL then
		if BU3.Items.Items[itemID] ~= nil then
			local item = BU3.Items.Items[itemID]

			local originalItemDescription = item.desc or ""
			local originalItemLua = item.lua or ""

			local fixedDescription = string.gsub(originalItemDescription, "\n", "\\n")
			local fixedLua = string.gsub(originalItemLua, "\n", "\\n")

			item.desc = fixedDescription
			item.lua = fixedLua

			--JSON it, compress it, save it
			local json = util.TableToJSON(item)

			item.desc = originalItemDescription
			item.lua = originalItemLua

			local result = sql.Query([[INSERT OR REPLACE INTO bu3_items VALUES (]]..item.itemID..[[ , ]]..sql.SQLStr(json)..[[);]])
			if result then
				print("[UNBOXING 3] Failed to save item! Reason :", sql.LastError())
			end
		end
	else
		if BU3.Items.Items[itemID] ~= nil then
			local item = BU3.Items.Items[itemID]

			local originalItemDescription = item.desc or ""
			local originalItemLua = item.lua or ""

			local fixedDescription = string.gsub(originalItemDescription, "\n", "\\n")
			local fixedLua = string.gsub(originalItemLua, "\n", "\\n")

			item.desc = fixedDescription
			item.lua = fixedLua

			--JSON it, compress it, save it
			local json = util.TableToJSON(item)

			item.desc = originalItemDescription
			item.lua = originalItemLua

			local request = [[REPLACE INTO bu3_items (itemID, itemData) VALUES (]]..item.itemID..[[ , ]]..sql.SQLStr(json)..[[);]]
			
			--MySQL implementation
			local query = BU3.SQL.MySQLInstance:query(request)

			function query:onSuccess(data)
				print("[UNBOXING] Saved item!")
			end
 
			function query:onError(err)
				print("[UNBOXING] Failed to save item, open a support ticket with the following error. ERROR:"..err)
			end	

			query:start()
		end
	end
end

--Will delete an item from the database
function BU3.SQL.DeleteItem(itemID)
	if not BU3.SQLConfig.UseMySQL then
		local result = sql.Query([[DELETE FROM bu3_items WHERE itemID=']]..itemID..[[';]])
		if result then
			print("[UNBOXING 3] Failed to delete item! Reason :", sql.LastError())
		end
	else
		--MySQL implementation
		local query = BU3.SQL.MySQLInstance:query([[DELETE FROM bu3_items WHERE itemID=]]..itemID..[[;]])

		function query:onSuccess(data)
			print("[UNBOXING] Deleting MySQL item!")

		end

		function query:onError(err)
			print("[UNBOXING] Failed to delete item, open a support ticket with the following error. ERROR:"..err)
		end	

		query:start()
	end
end

--Attempts to load an inventory based on the steamID64
--It it failed the callback will be called with false
function BU3.SQL.LoadInventory(steamID64, callback)
	if not BU3.SQLConfig.UseMySQL then
		local result = sql.Query("SELECT * FROM bu3_inventories WHERE steamid = "..steamID64..";")
		if result ~= nil and result[1] ~= nil and result[1].inventoryData ~= nil then
			--Convert it to a table
			local inv = util.JSONToTable(result[1].inventoryData)
			callback(inv)
		else
			callback(false)
		end
	else
		--MySQL implementation
		local query = BU3.SQL.MySQLInstance:query("SELECT * FROM bu3_inventories WHERE steamid='"..steamID64.."';")

		function query:onSuccess(data)
			if data ~= nil and data[1] ~= nil and data[1].inventoryData ~= nil then
				--Convert it to a table
				local inv = util.JSONToTable(data[1].inventoryData)
				callback(inv)
			else
				callback(false)
			end
		end

		function query:onError(err)
			print("[UNBOXING] Failed to save inventory, open a support ticket with the following error. ERROR:"..err)
		end	

		query:start()
		query:wait()

	end
end

--Attempts to load an inventory based on the steamID64
--It it failed the callback will be called with false
function BU3.SQL.SaveInventory(steamID64, inventory)
	if not BU3.SQLConfig.UseMySQL then
		--Convert to JSON
		local jsonInv = util.TableToJSON(inventory)
		sql.Query("INSERT OR REPLACE INTO bu3_inventories VALUES ("..steamID64..", "..sql.SQLStr(jsonInv)..");")
		print(sql.LastError())
	else
		--MySQL implementation
		local jsonInv = util.TableToJSON(inventory)
		local request = "REPLACE INTO bu3_inventories (steamid, inventoryData) VALUES ("..steamID64..", "..sql.SQLStr(jsonInv)..");"

		--MySQL implementation
		local query = BU3.SQL.MySQLInstance:query(request)

		function query:onSuccess(data)
			print("[UNBOXING] Saved inventory!")
		end

		function query:onError(err)
			print("[UNBOXING] Failed to save inventory, open a support ticket with the following error. ERROR:"..err)
		end	

		query:start()
	end
end

--This function will try to connect to the SQL database, then load the items and register them
--If they are not already loaded that is.
function BU3.SQL.Intitialize()
	if not BU3.SQLConfig.UseMySQL then
		if not sql.TableExists("bu3_items") then
			local result = sql.Query([[
				CREATE TABLE bu3_items (
				    itemID INT,
				    itemData TEXT,
				    PRIMARY KEY (itemID)
				);
			]])
		else
			BU3.SQL.LoadItems() --Load the items instead
		end

		if not sql.TableExists("bu3_inventories") then
			local result = sql.Query([[
				CREATE TABLE bu3_inventories (
				    steamid INT,
				    inventoryData TEXT,
				    PRIMARY KEY (steamid)
				);
			]])		
		end
		if not sql.TableExists("bu3_market") then
			local result = sql.Query([[
				CREATE TABLE bu3_market (
				    itemID INT,
				    marketInfo TEXT,
				    PRIMARY KEY (itemID)
				);
			]])				
		end

	else
		--MySQL implementation
		--First start by connecting to the database
		BU3.SQL.MySQLInstance = mysqloo.connect(BU3.SQLConfig.Host, 
			BU3.SQLConfig.Username, 
			BU3.SQLConfig.Password, 
			BU3.SQLConfig.DatabaseName, 
			tonumber(BU3.SQLConfig.Port)
		)

		print("[UNBOXING] Attempting to connect to MySQL database...")

		--Worked
		function BU3.SQL.MySQLInstance:onConnected()
		    print("[UNBOXING] Connected to mysql database '"..BU3.SQLConfig.DatabaseName.."' @ '"..BU3.SQLConfig.Host..":"..BU3.SQLConfig.Port.."'")

		    --Now try to create the tables
		    
		end

		--Faled
		function BU3.SQL.MySQLInstance:onConnectionFailed( err )
		    print( "[UNBOXING] Connection to database failed! You should not use the addon while it is not connected to any datasource!", err)
		    error("UNBOXING 3 FAILED TO CONNECT TO MYSQL DATABASE ERROR SHOULD BE ABOVE")
		    return
		end

		--Connect
		BU3.SQL.MySQLInstance:setAutoReconnect(true)
		BU3.SQL.MySQLInstance:connect()
		BU3.SQL.MySQLInstance:wait()

		--Now that we are connected try to make the tables, if it fails then its becuase the tables already exist
		local query = BU3.SQL.MySQLInstance:query([[
			CREATE TABLE bu3_items (
			    itemID BIGINT,
			    itemData TEXT,
			    PRIMARY KEY (itemID)
			);	
		]])

		function query:onSuccess(data)
			print("[UNBOXING] Created table 'bu3_items'")
		end

		function query:onError(err)
			--print("Failed to create the sql tables, If the following error says that the table already exists then this is fine. Ignore it, otherwise open a suppor ticket. ERROR:"..err)
		end	

		query:start()
		query:wait()

		local query = BU3.SQL.MySQLInstance:query([[
			CREATE TABLE bu3_inventories (
			    steamid BIGINT,
			    inventoryData TEXT,
			    PRIMARY KEY (steamid)
			);
		]])

		function query:onSuccess(data)
			print("[UNBOXING] Created table 'bu3_inventories'")
		end

		function query:onError(err)
			--print("Failed to create the sql tables, If the following error says that the table already exists then this is fine. Ignore it, otherwise open a suppor ticket. ERROR:"..err)
		end	

		query:start()
		query:wait()

		local query = BU3.SQL.MySQLInstance:query([[
			CREATE TABLE bu3_market (
			    itemID BIGINT,
			    marketInfo TEXT,
			    PRIMARY KEY (itemID)
			);
		]])

		function query:onSuccess(data)
			print("[UNBOXING] Created table 'bu3_market'")
		end

		function query:onError(err)
			--print("Failed to create the sql tables, If the following error says that the table already exists then this is fine. Ignore it, otherwise open a suppor ticket. ERROR:"..err)
		end	

		query:start()
		query:wait()

		--Now load the items
		BU3.SQL.LoadItems()

		print("[UNBOXING] Finished setting up MySQL.")
	end
end

--Intialize it all
BU3.SQL.Intitialize()