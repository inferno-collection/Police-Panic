-- Inferno Collection Police Panic Version 1.22 Beta
--
-- Copyright (c) 2019 - 2020, Christopher M, Inferno Collection. All rights reserved.
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
Config.Cooldown = 15
-- Time in secs blip flashes and map route appears on tuned
-- clients screens before disappearing
Config.BlipTime = 30
-- Whether or not to disable all on-screen messages
Config.DisableAllMessages = false
-- Whether or not to enable chat suggestions
Config.ChatSuggestions = true
-- Whether or not to enable a reminder for whitelisted people to tune into the
-- panic channel after they join the server, if they have not done so already
Config.Reminder = false
-- Whether or not to enable auto-tuning based off of whitelist entries
-- A.K.A, if a client is whitelisted and has 'autotune' set to true,
-- whether or not to allow this client to be auto-tuned
Config.WhitelistAutoTune = true
-- Whether or not to enable auto-tuning based off of what vehicle a client is in
-- DO NOT have 'WhitelistAutoTune' enabled at the same time as this, use one or the other
Config.VehicleAutoTune = false
-- The model name of the vehicles that will auto-tune a player if
-- 'VehicleAutoTune' is enabled
Config.AutoTuneVehicles = {
	"police",
	"police1",
	"police2",
	"police3",
	"police4"
}
-- Whether or not to enable command whitelist.
-- "ace" to use Ace permissions, "json" to use whitelist.json file, or false to disable.
Config.WhitelistEnabled = false
-- Default message sender with panic activation
Config.Sender = "Dispatch"
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
Whitelist.Command.autotune = false
Whitelist.Command.panictune = false
Whitelist.Command.panicwhitelist = false

-- Placed here so if the resource is restarted, whitelisting does not break
AddEventHandler("onClientResourceStart", function (ResourceName)
	if(GetCurrentResourceName() == ResourceName) then
		if Whitelist.Enabled then
			TriggerServerEvent("Police-Panic:WhitelistCheck", Whitelist)
		else
			for i in pairs(Whitelist.Command) do Whitelist.Command[i] = true end

			Whitelist.Command.autotune = false
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
		TriggerEvent("chat:addSuggestion", "/panicunwhitelist", "Remove players from the command whitelist.", {
			{ name = "{player hex/server id}", help = "Type out the player's steam hex, or put the player's server ID from the player list." }
		})
	end
end)

-- Return from whitelist check
RegisterNetEvent("Police-Panic:Return:WhitelistCheck")
AddEventHandler("Police-Panic:Return:WhitelistCheck", function(NewWhitelist)
	Whitelist = NewWhitelist

	if Whitelist.Command.autotune and Config.WhitelistAutoTune then
		Citizen.Wait(5000)
		PanicTune(true)
	elseif Config.Reminder and Whitelist.Command.panictune then
		Citizen.CreateThread(function()
			-- Wait two minutes after they join the server
			Citizen.Wait(120000)
			if not Panic.Tuned then NewNoti("~y~Don't forget to tune into the Panic Channel with /panictune!", true) end
		end)
	end
end)

-- Forces a whitelist reload on the client
RegisterNetEvent("Police-Panic:WhitelistRecheck")
AddEventHandler("Police-Panic:WhitelistRecheck", function() TriggerServerEvent("Police-Panic:WhitelistCheck", Whitelist) end)

-- Message return when removing clients from the whitelist
RegisterNetEvent("Police-Panic:Return:WhitelistRemove")
AddEventHandler("Police-Panic:Return:WhitelistRemove", function(Removed)
	if Removed then
		NewNoti("~g~Entry removed from whitelist.", true)
	else
		NewNoti("~r~No entry with provided ID found. Unable to remove.", true)
	end
end)

-- /panic command
RegisterCommand("panic", function()
	if Whitelist.Command.panic then
		if Panic.Cooling == 0 then
			local Officer = {}
			Officer.Ped = PlayerPedId()
			Officer.Name = GetPlayerName(PlayerId())
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
		if Officer.Ped == PlayerPedId() then
			SendNUIMessage({
				PayloadType	= {"Panic", "LocalPanic"},
				Payload	= source
			})
		else
			SendNUIMessage({
				PayloadType	= {"Panic", "ExternalPanic"},
				Payload	= source
			})
		end

		-- Only people tuned to the panic channel can see the message
		TriggerEvent("chat:addMessage", {
			color = {255, 0, 0},
			multiline = true,
			args = {Config.Sender, Config.Message .. " - " .. Officer.Name .. " (" .. source .. ") - " .. Officer.Location}
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

			SetBlipAlpha(Blip, 60)
			SetBlipColour(Blip, 1)
			SetBlipFlashes(Blip, true)
			SetBlipFlashInterval(Blip, 200)

			Citizen.Wait(Config.BlipTime * 1000)

			RemoveBlip(Blip)
			Blip = nil
		end)
	end
end)

-- /panictune command
RegisterCommand("panictune", function()
	if Whitelist.Command.panictune then
		PanicTune()
	else
		NewNoti("~r~You are not whitelisted for this command.", true)
	end
end)

-- /panicwhitelist command
RegisterCommand("panicwhitelist", function(_, Args)
	if Whitelist.Command.panicwhitelist then
		if Args[1] and Args[1]:lower() == "reload" then
			NewNoti("~g~Whitelist reload complete.", true)
			TriggerServerEvent("Police-Panic:WhitelistReload")
		elseif Args[1] then
			local ID
			local Entry = {}
			Entry.panic = "pending"
			Entry.panictune = "pending"
			Entry.panicwhitelist = "pending"
			Entry.autotune = "pending"

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
				-- If the argument is a valid command allow the player access to the command
				if Entry[Args[i]:lower()] then Entry[Args[i]] = true end
			end

			-- Loop though all commands
			for i in pairs(Entry) do
				-- If the command is still pending disallow the player access to the command
				if Entry[i] == "pending" then Entry[i] = false end
			end

			TriggerServerEvent("Police-Panic:WhitelistAdd", ID, Entry)
			NewNoti("~g~Whitelist reload complete.", true)
			NewNoti("~g~" .. ID .. " Added to whitelist successfully.", true)
		else
			NewNoti("~r~Error, not enough arguments.", true)
		end
	else
		NewNoti("~r~You are not whitelisted for this command.", true)
	end
end)

-- /panicwhitelist command
RegisterCommand("panicunwhitelist", function(_, Args)
	if Whitelist.Command.panicwhitelist then
		if Args[1] then
			local ID

			-- If is a number or the first part of the string contains "steam:"
			if tonumber(Args[1]) or (string.sub(Args[1]:lower(), 1, string.len("steam:")) == "steam:") then
				ID = Args[1]
			else
				-- Set the steam hex to the string, adding "steam:" to the front
				ID = "steam:" .. Args[1]
			end

			TriggerServerEvent("Police-Panic:WhitelistRemove", ID)
			NewNoti("~g~Whitelist reload complete.", true)
		else
			NewNoti("~r~Error, not enough arguments.", true)
		end
	else
		NewNoti("~r~You are not whitelisted for this command.", true)
	end
end)

-- Tunes a player to the panic channel
function PanicTune(AutoTune)
	AutoTune = AutoTune or false

	if Panic.Tuned then
		Panic.Tuned = false

		if AutoTune then
			NewNoti("~y~Auto-tuning you OUT of the Panic Channel. Use /panictune to retune.", true)
		else
			NewNoti("~r~No longer tuned to panic channel.", false)
		end
	else
		if AutoTune then
			Panic.Tuned = "autotune"
			NewNoti("~y~Auto-tuning you INTO the Panic Channel. Use /panictune to detune.", true)
		else
			Panic.Tuned = "command"
			NewNoti("~g~Tuned to Panic Channel.", false)
		end
	end
end

-- Draws notification on client's screen
function NewNoti(Text, Flash)
	if not Config.DisableAllMessages then
		SetNotificationTextEntry("STRING")
		AddTextComponentString(Text)
		DrawNotification(Flash, true)
	end
end

-- Cooldown loop
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if Panic.Cooling ~= 0 then
			Citizen.Wait(1000)
			Panic.Cooling = Panic.Cooling - 1
		end
	end
end)

-- If vehicle auto-tune is enabled
if Config.VehicleAutoTune then
	local Vehicle = false

	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(0)

			local PlayerVehicle = GetVehiclePedIsIn(PlayerPedId(), false)

			if PlayerVehicle ~= 0 then
				if not Vehicle then
					for _, Veh in ipairs(Config.AutoTuneVehicles) do
						-- If the current player's vehicle is in the list of auto-tune vehicles
						if GetEntityModel(PlayerVehicle) == GetHashKey(Veh) then
							Vehicle = PlayerVehicle

							if not Panic.Tuned then PanicTune(true) end
							break
						end

						-- Player is not in an auto-tune vehicle, but this variable still
						-- needs to be set to something
						Vehicle = "No Vehicle"
					end
				elseif Vehicle ~= PlayerVehicle and Vehicle ~= "No Vehicle" then
					Vehicle = false
				end
			else
				Vehicle = false

				if Panic.Tuned == "autotune" then PanicTune(true) end
			end
		end
	end)
end
