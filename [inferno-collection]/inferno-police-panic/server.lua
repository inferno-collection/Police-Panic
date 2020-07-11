-- Inferno Collection Police Panic Version 1.22 Beta
--
-- Copyright (c) 2019 - 2020, Christopher M, Inferno Collection. All rights reserved.
--
-- This project is licensed under the following:
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to use, copy, modify, and merge the software, under the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. THE SOFTWARE MAY NOT BE SOLD.
--

-- Play tones on all clients
RegisterServerEvent("Police-Panic:NewPanic")
AddEventHandler("Police-Panic:NewPanic", function(Officer) TriggerClientEvent("Pass-Alarm:Return:NewPanic", -1, source, Officer) end)

-- Whitelist check on server join
RegisterServerEvent("Police-Panic:WhitelistCheck")
AddEventHandler("Police-Panic:WhitelistCheck", function(Whitelist)
	for i in pairs(Whitelist.Command) do Whitelist.Command[i] = "pending" end

	-- If using json file as whitelist
	if Whitelist.Enabled:lower() == "json" then
		-- Collect all the data from the whitelist.json file
		local Data = LoadResourceFile(GetCurrentResourceName(), "whitelist.json")
		-- If able to collect data
		if Data then
			-- Place the decoded whitelist into the array
			local Entries = json.decode(Data)

			-- Loop through the whitelist array
			for _, Entry in ipairs(Entries) do
				-- Check if the player exists in the array.
				if GetPlayerIdentifier(source):lower() == Entry.steamhex:lower() then
					-- Loop though all values in whitelist entry
					for i in pairs(Entry) do
						-- If the value is not the player's steam hex
						if i ~= "steamhex" then
							-- If whitelist value is true, aka they have access to a command
							if Entry[i] then
								-- If command is a valid command
								if Whitelist.Command[i] then
									-- Allow player to use that command
									Whitelist.Command[i] = true
								-- If command is not valid
								else
									-- Print error message to server console
									print("===================================================================")
									print("==============================WARNING==============================")
									print("/" .. i .. " is not a valid command, but is listed in ")
									print(Entry.steamhex:lower() .. "'s whitelist entry. Please correct this")
									print("issue, and reload the whitelist with /panicwhitelist reload.")
									print("Note: Entries are CaSe SeNsItIvE.")
									print("===================================================================")
								end
							end
						end
					end
					-- Break the loop once whitelist entry found
					break
				end
			end
		-- If unable to load json file
		else
			-- Print error message to server console
			print("===================================================================")
			print("==============================WARNING==============================")
			print("Unable to load whitelist file for Inferno-Police-Panic. The white")
			print("list has been disabled. This message will appear every time someone")
			print("joins the server until the issue is corrected.")
			print("===================================================================")
			-- Loop through all commands and grant players all permissions
			for i in pairs(Whitelist.Command) do Whitelist.Command[i] = true end
			-- Override auto-tune permission
			Whitelist.Command.autotune = false
			-- Override whitelist permission
			Whitelist.Command.panicwhitelist = false
		end

		-- Loop through all commands
		for i in pairs(Whitelist.Command) do
			-- If command is still pending deny access
			if Whitelist.Command[i] == "pending" then Whitelist.Command[i] = false end
		end
	-- If using Ace permissions
	elseif Whitelist.Enabled:lower() == "ace" then
		-- Loop through all commands and grant player permission to command based on Ace group
		for i in pairs(Whitelist.Command) do Whitelist.Command[i] = IsPlayerAceAllowed(source, "Police-Panic." .. i) end
	-- If using neither json, Ace, or disabled
	else
		-- Print error message to server console
		print("===================================================================")
		print("==============================WARNING==============================")
		print("'" .. tostring(Whitelist.Enabled) .. "' is not a valid Whitelist option.")
		print("The whitelist has been disabled.")
		print("===================================================================")
		-- Loop through all commands and grant players all permissions
		for i in pairs(Whitelist.Command) do Whitelist.Command[i] = true end
		-- Override auto-tune permission
		Whitelist.Command.autotune = false
		-- Override whitelist permission
		Whitelist.Command.panicwhitelist = false
	end
	-- Return whietlist object to client
	TriggerClientEvent("Police-Panic:Return:WhitelistCheck", source, Whitelist)
end)

-- Whitelist reload on all clients
RegisterServerEvent("Police-Panic:WhitelistReload")
AddEventHandler("Police-Panic:WhitelistReload", function() TriggerClientEvent("Police-Panic:WhitelistRecheck", -1) end)

-- Add entry to whitelist (json only)
RegisterServerEvent("Police-Panic:WhitelistAdd")
AddEventHandler("Police-Panic:WhitelistAdd", function(ID, Entry)
	-- Collect all the data from the whitelist.json file
	local Data = json.decode(LoadResourceFile(GetCurrentResourceName(), "whitelist.json"))

	-- If 'steam hex' provided was a number get steam hex based off of number
	if tonumber(ID) then ID = GetPlayerIdentifier(ID) end

	-- Add the steam hex to the whitelist entry
	Entry.steamhex = ID
	-- Add the entry to the existing whitelist
	table.insert(Data, Entry)
	-- Covert the entire object to a json format, then save it over the existing file
	SaveResourceFile(GetCurrentResourceName(), "whitelist.json", json.encode(Data), -1)
	-- Force all clients to reload their whitelists
	TriggerClientEvent("Police-Panic:WhitelistRecheck", -1)
end)

-- Remove entry from whitelist (json only)
RegisterServerEvent("Police-Panic:WhitelistRemove")
AddEventHandler("Police-Panic:WhitelistRemove", function(ID)
	-- Collect all the data from the whitelist.json file
	local Data = json.decode(LoadResourceFile(GetCurrentResourceName(), "whitelist.json"))
	local Removed = false

	-- If 'steam hex' provided was a number get steam hex based off of number
	if tonumber(ID) then ID = GetPlayerIdentifier(ID) end

	-- Loop through the whitelist array
	for EntryID, Entry in ipairs(Data) do
		-- Check if the player exists in the array.
		if ID:lower() == Entry.steamhex:lower() then Removed = EntryID end
	end

	-- Remove the entry from the existing whitelist
	table.remove(Data, Removed)
	-- Covert the entire object to a json format, then save it over the existing file
	SaveResourceFile(GetCurrentResourceName(), "whitelist.json", json.encode(Data), -1)
	-- Force all clients to reload their whitelists
	TriggerClientEvent("Police-Panic:WhitelistRecheck", -1)
	TriggerClientEvent("Police-Panic:Return:WhitelistRemove", source, Removed)
end)