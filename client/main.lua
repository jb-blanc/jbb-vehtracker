local QBCore = exports['qb-core']:GetCoreObject()

local vehicleBlips = {}


function GetUserInput(windowTitle, defaultText, maxInputLength)
    -- Create the window title string.
    local resourceName = string.upper(GetCurrentResourceName())
    local textEntry = resourceName .. "_WINDOW_TITLE"
    if windowTitle == nil then
      windowTitle = "Enter:"
    end
    AddTextEntry(textEntry, windowTitle)
  
    -- Display the input box.
    DisplayOnscreenKeyboard(1, textEntry, "", defaultText or "", "", "", "", maxInputLength or 30)
    Wait(0)
    -- Wait for a result.
    while true do
      local keyboardStatus = UpdateOnscreenKeyboard();
      if keyboardStatus == 3 then -- not displaying input field anymore somehow
        return nil
      elseif keyboardStatus == 2 then -- cancelled
        return nil
      elseif keyboardStatus == 1 then -- finished editing
        return GetOnscreenKeyboardResult()
      else
        Wait(0)
      end
    end
end

local function CreateBlips(coords, blipNumber, blipColor, blipName)
    local Blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(Blip, blipNumber)
    SetBlipDisplay(Blip, 4)
    SetBlipScale(Blip, 0.60)
    SetBlipAsShortRange(Blip, true)
    SetBlipColour(Blip, blipColor)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(blipName)
    EndTextCommandSetBlipName(Blip)
    return Blip
end

function GetVehicleName(vehicle)
    if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
        local vehicleModel = GetEntityModel(vehicle)
        local displayName = GetDisplayNameFromVehicleModel(vehicleModel)
        return displayName
    end
    return "NoName"
end

local function doAction(action, cb)
    QBCore.Functions.Progressbar(action.name, action.description, action.duration, false, true, {
        disableMovement = true,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = false,
    }, {
        animDict = action.animation.anim_dict,
        anim = action.animation.anim_name,
    }, {
        model = action.animation.prop_model,
        bone = action.animation.attached_bone,
        coords = action.animation.prop_coord,
        rotation = action.animation.prop_rotaton,
    }, {}, cb)
end

local function getNearbyVehicle()
    local vehicle, distance = QBCore.Functions.GetClosestVehicle()
    if distance > 8 then
        QBCore.Functions.Notify("Vehicle is too far", "error")
        return
    end
    return vehicle
end

local function hasItem(item)
    return QBCore.Functions.HasItem(item)
end

local function removeTracker(vNetId)
    doAction(Config.Actions["remove_tracker"], function()
        TriggerServerEvent("jbb:vehtrack:server:remove-tracker",vNetId)
    end);
end

local function askChannelId(message)
    local cId = GetUserInput(message..(" (between %d and %d both included)"):format(Config.Settings.minChan,Config.Settings.maxChan), "", string.len(tostring(Config.Settings.maxChan)))
    if cId~=nil then
        local chan = tonumber(cId)
        if not chan then
            return askChannelId(("Enter a correct value (between %d and %d both included)"):format(Config.Settings.minChan,Config.Settings.maxChan))
        end

        if chan>=Config.Settings.minChan and chan<=Config.Settings.maxChan then
            return chan
        else
            return askChannelId(("Enter a correct value (between %d and %d both included)"):format(Config.Settings.minChan,Config.Settings.maxChan)) 
        end
    end
    return nil
end

local function resetBlips()
    for plate, blip in pairs(vehicleBlips) do
        RemoveBlip(blip)
    end
    vehicleBlips = {}
end

-- Events
RegisterNetEvent('QBCore:Client:UpdateObject', function()
    QBCore = exports['qb-core']:GetCoreObject()
end)

RegisterNetEvent('jbb:vehtrack:client:setchannel', function()
    if hasItem(Config.Items["veh_tracker_receiver"].name) then
        local cId = askChannelId(("Set your receiver channel (between %d and %d both included)"):format(Config.Settings.minChan,Config.Settings.maxChan))
        if cId ~= nil then
            resetBlips()
            TriggerServerEvent("jbb:vehtrack:server:set-channel", cId)
        end
    end
end)

RegisterNetEvent('jbb:vehtrack:client:putemitter', function()
    local veh = getNearbyVehicle()
    if veh then
        if hasItem(Config.Items["veh_tracker_emitter"].name) then
            local cId = askChannelId(("Select then channel for this tracker (between %d and %d both included)"):format(Config.Settings.minChan,Config.Settings.maxChan))
            if cId~=nil then
                doAction(Config.Actions["put_tracker"], function()
                    TriggerServerEvent("jbb:vehtrack:server:add-tracked-vehicle", VehToNet(veh), cId, GetVehicleName(veh))
                end);
            end
        end
    end
end)

RegisterNetEvent('jbb:vehtrack:client:scanning', function()
    local veh = getNearbyVehicle()
    if veh then
        local vNetId = VehToNet(veh)
        if hasItem(Config.Items["veh_tracker_scanner"].name) then
            doAction(Config.Actions["scan_tracker"], function()
                QBCore.Functions.TriggerCallback("jbb:vehtrack:server:scan-vehicle", function(data)
                    if data == true then
                        local result = GetUserInput("Do you want to remove tracker (y/n)?", "", 1)
                        if result == 'y' or result == 'Y' then
                            removeTracker(vNetId)
                        end
                    else
                        QBCore.Functions.Notify("No sign of any tracker", "success", 5000)
                    end
                end, {vNetId})
            end);
        end
    end
end)

local function tableContainsPlate(plate, table)
    for k,v in ipairs(table) do
        if v.plate == plate then 
            return k
        end
    end
    return nil
end

RegisterNetEvent("jbb:vehtrack:client:vehicledel", function(vehicle)
    if vehicleBlips[vehicle.plate] then
        RemoveBlip(vehicleBlips[vehicle.plate])
        vehicleBlips[vehicle.plate] = nil
        QBCore.Functions.Notify(("Vehicle %s (%s) is no more tracked"):format(vehicle.plate, vehicle.name), "error", 5000)
    end
end)
                    
RegisterNetEvent("jbb:vehtrack:client:updatepos", function(vehicles)
    for i,v in ipairs(vehicles) do
        if vehicleBlips[v.plate] then 
            local b = vehicleBlips[v.plate]
            SetBlipCoords(b,v.coords.x, v.coords.y, v.coords.z)
        else
            local blip = CreateBlips(v.coords, 162, 59,("Tracker %s : %s"):format(v.plate,v.name))
            vehicleBlips[v.plate] = blip
        end
    end

    for plate, blip in pairs(vehicleBlips)  do
        local idx = tableContainsPlate(plate, vehicles)
        if idx<0 then
            RemoveBlip(blip)
            Wait(10)
            vehicleBlips[plate] = nil
        end
    end

end)

-- Threads
