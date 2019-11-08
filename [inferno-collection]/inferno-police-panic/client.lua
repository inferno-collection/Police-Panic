-- Inferno Collection Police Panic Version 1.2 Beta
--
-- Copyright (c) 2019, Christopher M, Inferno Collection. All rights reserved.
--
-- This project is licensed under the following:
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to use, copy, modify, and merge the software, under the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. THE SOFTWARE MAY NOT BE SOLD.
--

--
-- Resource Configuration
-- PLEASE RESTART SERVER AFTER MAKING CHANGES TO THIS CONFIGURATION
--
local Config = {} -- Do not edit this line
-- Time in secs between Panic Button activates PER client
-- Set to 0 to impose no cooldown
Config.Cooldown = 5
-- Whether or not to disable all on-screen messages
Config.DisableAllMessages = false
-- Whether or not to enable chat suggestions
Config.ChatSuggestions = true
-- Whether or not to enable a reminder for whitelisted people to tune into the
-- panic channel after they join the server, if they have not done so already
Config.Reminder = true
-- Whether or not to enable command whitelist.
-- "ace" to use Ace permissions, "json" to use whitelist.json file, or false to disable.
Config.WhitelistEnabled = false
-- Default message displayed with panic activation
Config.Message = "Attention all units, Officer in distress!"

--
--		Nothing past this point needs to be edited, all the settings for the resource are found ABOVE this line.
--		Do not make changes below this line unless you know what you are doing!
--

-- Local Panic Variables
local Panic = {}
-- Time left on cool down
Panic.Cooling = 0
-- Is the client tuned to the panic channel
Panic.Tuned = false

-- Local whitelist variable
local Whitelist = {}
-- Boolean for whether the whitelist is enabled
Whitelist.Enabled = Config.WhitelistEnabled
-- Whitelist variable for commands
Whitelist.Command = {}
Whitelist.Command.panic = false
Whitelist.Command.panictune = false
Whitelist.Command.panicwhitelist = false

-- Placed here so if the resource is restarted, whitelisting does not break
AddEventHandler("onClientResourceStart", function (ResourceName)
	if(GetCurrentResourceName() == ResourceName) then
		if Whitelist.Enabled then
			TriggerServerEvent("Police-Panic:WhitelistCheck", Whitelist)
		else
			-- Loop through all commands
			for i in pairs(Whitelist.Command) do
				-- Grant players all permissions
				Whitelist.Command[i] = true
			end
			-- Override whitelist permission
			Whitelist.Command.panicwhitelist = false
		end
	end
end)

-- On client join server
AddEventHandler("onClientMapStart", function()
	if Config.ChatSuggestions then

		TriggerEvent("chat:addSuggestion", "/panic", "Activate your Panic Button!")
		TriggerEvent("chat:addSuggestion", "/panictune", "Tune into the Panic Button channel.")
		TriggerEvent("chat:addSuggestion", "/panicwhitelist", "Add to, and/or reload the command whitelist.", {
			{ name = "{reload} or {player hex/server id}", help = "Type 'reload' to reload the current whitelist, or if you are adding to the whitelist, type out the player's steam hex, or put the player's server ID from the player list." },
			{ name = "commands", help = "List all the commands you want this person to have access to."}
		})
	end

	if Whitelist.Enabled then
		TriggerServerEvent("Police-Panic:WhitelistCheck", Whitelist)
	else
		-- Loop through all commands
		for i in pairs(Whitelist.Command) do
			-- Grant players all permissions
			Whitelist.Command[i] = true
		end
		-- Override whitelist permission
		Whitelist.Command.panicwhitelist = false
	end

	-- Adds panic command chat template, including radio icon
	TriggerEvent("chat:addTemplate", "Panic", "<img src='data:image/png;base64,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' height='16'> <b>{0}</b>: {1}")
end)

-- Return from whitelist check
RegisterNetEvent("Police-Panic:Return:WhitelistCheck")
AddEventHandler("Police-Panic:Return:WhitelistCheck", function(NewWhitelist)
	Whitelist = NewWhitelist

	if Config.Reminder and Whitelist.Command.panictune then
		Citizen.CreateThread(function()
			-- Wait two minutes after they join the server
			Citizen.Wait(120000)
			if not Panic.Tuned then
				NewNoti("~y~Don't forget to tune into the Panic Channel with /panictune!", true)
			end
		end)
	end
end)

-- Forces a whitelist reload on the client
RegisterNetEvent("Police-Panic:WhitelistRecheck")
AddEventHandler("Police-Panic:WhitelistRecheck", function()
	TriggerServerEvent("Police-Panic:WhitelistCheck", Whitelist)
end)

-- /panic command
RegisterCommand("panic", function()
	if Whitelist.Command.panic then
		if Panic.Cooling == 0 then
			local Officer = {}
			Officer.Player = PlayerId()
			Officer.Ped = PlayerPedId()
			Officer.Name = GetPlayerName(Officer.Player)
			Officer.Coords = GetEntityCoords(Officer.Ped)
			Officer.Location = {}
			Officer.Location.Street, Officer.Location.CrossStreet = GetStreetNameAtCoord(Officer.Coords.x, Officer.Coords.y, Officer.Coords.z)
			Officer.Location.Street = GetStreetNameFromHashKey(Officer.Location.Street)
			if Officer.Location.CrossStreet ~= 0 then
				Officer.Location.CrossStreet = GetStreetNameFromHashKey(Officer.Location.CrossStreet)
				Officer.Location = Officer.Location.Street .. " X " .. Officer.Location.CrossStreet
			else
				Officer.Location = Officer.Location.Street
			end

			TriggerServerEvent("Police-Panic:NewPanic", Officer)

			Panic.Cooling = Config.Cooldown
		else
			NewNoti("~r~Panic Button still cooling down.", true)
		end
	else
		NewNoti("~r~You are not whitelisted for this command.", true)
	end
end)

-- Plays panic on client
RegisterNetEvent("Pass-Alarm:Return:NewPanic")
AddEventHandler("Pass-Alarm:Return:NewPanic", function(source, Officer)
	if Panic.Tuned then
		SendNUIMessage({
			PayloadType	= "Panic",
			Payload		= source
		})

		-- Only people tuned to the panic channel can see the message
		TriggerEvent("chat:addMessage", {
			templateId = "Panic",
			color = {255, 0, 0},
			multiline = true,
			args = {"Dispatch", Config.Message .. " - " .. Officer.Name .. " (" .. source .. ") - " .. Officer.Location}
		})

		Citizen.CreateThread(function()
			local Blip = AddBlipForRadius(Officer.Coords.x, Officer.Coords.y, Officer.Coords.z, 100.0)
			SetBlipRoute(Blip, true)
			Citizen.CreateThread(function()
				while Blip do
					SetBlipRouteColour(Blip, 1)
					Citizen.Wait(150)
					SetBlipRouteColour(Blip, 6)
					Citizen.Wait(150)
					SetBlipRouteColour(Blip, 35)
					Citizen.Wait(150)
					SetBlipRouteColour(Blip, 6)
				end
			end)
			SetBlipColour(Blip, 1)
			SetBlipAlpha(Blip, 60)
			SetBlipFlashes(Blip, true)
			SetBlipFlashInterval(Blip, 200)
			Citizen.Wait(30000)
			RemoveBlip(Blip)
			Blip = nil
		end)
	end
end)

-- /panictune command
RegisterCommand("panictune", function()
	if Whitelist.Command.panictune then
		if Panic.Tuned then
			Panic.Tuned = false
			NewNoti("~y~No longer tuned to Panic channel.", false)
		else
			Panic.Tuned = true
			NewNoti("~y~Now tuned to Panic channel.", false)
		end
	else
		NewNoti("~r~You are not whitelisted for this command.", true)
	end
end)

-- /panicwhitelist command
RegisterCommand("panicwhitelist", function(Source, Args)
	if Whitelist.Command.panicwhitelist then
		if Args[1] and Args[1]:lower() == "reload" then
			TriggerServerEvent("Police-Panic:WhitelistReload")
			NewNoti("~g~Whitelist reload complete.", true)
		elseif Args[1] then
			local ID
			local Entry = {}
			Entry.panic = "pending"
			Entry.panictune = "pending"
			Entry.panicwhitelist = "pending"

			if tonumber(Args[1]) then
				ID = Args[1]
			-- If the first part of the string contains "steam:"
			elseif string.sub(Args[1]:lower(), 1, string.len("steam:")) == "steam:" then
				-- Set the steam hex to the string
				ID = Args[1]
			-- In all other cases
			else
				-- Set the steam hex to the string, adding "steam:" to the front
				ID = "steam:" .. Args[1]
			end

			-- Loop though all command arguments
			for i in pairs(Args) do
				-- If the argument is a valid command
				if Entry[Args[i]:lower()] then
					-- Allow the player access to the command
					Entry[Args[i]] = true
				end
			end

			-- Loop though all commands
			for i in pairs(Entry) do
				-- If the command is still pending
				if Entry[i] == "pending" then
					-- Disallow the player access to the command
					Entry[i] = false
				end
			end

			TriggerServerEvent("Police-Panic:WhitelistAdd", ID, Entry)
			NewNoti("~g~" .. ID .. " Added to whitelist successfully.", true)
		else
			NewNoti("~r~Error, not enough arguments.", true)
		end
	else
		NewNoti("~r~You are not whitelisted for this command.", true)
	end
end)

-- Draws notification on client's screen
function NewNoti(Text, Flash)
	if not Config.DisableAllMessages then
		-- Tell GTA that a string will be passed
		SetNotificationTextEntry("STRING")
		-- Pass temporary variable to notification
		AddTextComponentString(Text)
		-- Draw new notification on client's screen
		DrawNotification(Flash, true)
	end
end

-- Cooldown loop
Citizen.CreateThread(function()
	-- Forever
	while true do
		Citizen.Wait(0)

		if Panic.Cooling ~= 0 then
			Panic.Cooling = Panic.Cooling - 1
			Citizen.Wait(1000)
		end
	end
end)