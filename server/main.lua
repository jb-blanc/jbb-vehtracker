local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.AddItems(Config.Items)

local registered = {}
local tracked = {}

for i=Config.Settings.minChan, Config.Settings.maxChan, 1 do
    registered[tostring(i)] = {}
    tracked[tostring(i)] = {}
end

local function sendTrackingInfo(player)
    local infoStr = ""
    for chan,vehicles in pairs(tracked) do
        for _,v in ipairs(vehicles) do
            if v.player == player.PlayerData.citizenid then 
                infoStr = infoStr..("[%s] %s (%s)\n"):format(chan, v.name, v.plate)
            end
        end
    end

    if string.len(infoStr) <= 1 then
        infoStr = "No vehicle tracked"
        return false
    end
    
    QBCore.Functions.Notify(src,  infoStr, 'success')
end

local function isVehicleTracked(vNetId)
    for chan,vehicles in pairs(tracked) do
        for _,v in pairs(vehicles) do
            if v.vehicle == vNetId then 
                return true
            end
        end
    end
    return false
end

local function hasReceiver(Player)
    return Player.Functions.GetItemByName(Config.Items["veh_tracker_receiver"].name)
end

local function getVehiclesPositionsInChannel(channel)
    local vehicles = {}
    local trackedVehicles = tracked[channel]
    if trackedVehicles then
        for _,v in ipairs(trackedVehicles) do
            local vEntity = NetworkGetEntityFromNetworkId(v.vehicle)
            if vEntity then
                local coords = GetEntityCoords(vEntity)
                table.insert(vehicles, {plate=v.plate, coords=coords, name=v.name});
            end
        end
    end
    return vehicles
end

local function findChannelForPlayer(player)
    for chan,players in pairs(registered) do
        for pIdx,p in ipairs(players) do
            if p == player.PlayerData.citizenid then
                return {idx = pIdx, chan = tostring(chan)}
            end
        end
    end
    return nil
end

local function registerOnChannel(player, newChan)
    local oldChannel = findChannelForPlayer(player)
    local citizenid = player.PlayerData.citizenid
    local newChannel = tostring(newChan)

    if oldChannel ~= nil then
        registered[oldChannel.chan][oldChannel.idx] = nil
    end

    table.insert(registered[newChannel], citizenid)
end

-- Callbacks

-- Events

RegisterNetEvent('QBCore:Server:UpdateObject', function()
	if source ~= '' then return false end
	QBCore = exports['qb-core']:GetCoreObject()
end)

RegisterNetEvent('jbb:vehtrack:server:add-tracked-vehicle', function(vNetId, chanId, vName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local vEntity = NetworkGetEntityFromNetworkId(vNetId)
    if DoesEntityExist(vEntity) then
        local plate = GetVehicleNumberPlateText(vEntity)
        local cId = tostring(chanId)

        if not tracked[cId] then
            tracked[cId] = {}
        end

        table.insert(tracked[cId], {player=Player.PlayerData.citizenid, vehicle=vNetId, plate=plate, name=vName});
        
        Player.Functions.RemoveItem(Config.Items["veh_tracker_emitter"].name, 1)
        QBCore.Functions.Notify(src, ('Tracker installed on %s (%s)'):format(vName, plate), 'success')
    else
        QBCore.Functions.Notify(src, 'Vehicle can\'t be tracked', 'error')
    end
end)

QBCore.Functions.CreateCallback('jbb:vehtrack:server:scan-vehicle', function(source, cb, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local vNetId = args[1]
    if not Player then return end

    local vEntity = NetworkGetEntityFromNetworkId(vNetId)
    if DoesEntityExist(vEntity) and isVehicleTracked(vNetId) then
        cb(true)
    else
        cb(false)
    end
end)

RegisterNetEvent('jbb:vehtrack:server:remove-tracker', function(vNetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local vEntity = NetworkGetEntityFromNetworkId(vNetId)
    if DoesEntityExist(vEntity) then
        for channel,vehicles in pairs(tracked) do
            for idx,vehicle in ipairs(vehicles) do
                if vehicle.vehicle == vNetId then
                    QBCore.Functions.Notify(src, ('Tracker removed from %s (%s)'):format(vehicle.name, vehicle.plate), 'success')
                    table.remove(tracked[channel], idx);
                    return
                end
            end
        end
    else
        QBCore.Functions.Notify(src, 'Nothing found', 'error')
    end
end)

RegisterNetEvent("jbb:vehtrack:server:set-channel", function(chanId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not hasReceiver(Player) then 
        QBCore.Functions.Notify(src, 'You must have a receiver to set a channel', 'error')
        return 
    end

    local cId = tonumber(chanId)
    if cId then 
        if cId >= Config.Settings.minChan and cId<= Config.Settings.maxChan then
            registerOnChannel(Player, cId)
            QBCore.Functions.Notify(src, ('Registered on channel %d'):format(cId), 'success')
        end
    else
        QBCore.Functions.Notify(src, ('Insert a number between %d and %d (both included)'):format(Config.Settings.minChan,Config.Settings.maxChan), 'error')
    end
end)

-- Commands
QBCore.Commands.Add('vtinfo', "Get your tracked vehicles infos", {}, false, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not hasReceiver(Player) then 
        QBCore.Functions.Notify(src, 'You must have a receiver to get infos', 'error')
        return 
    end

    sendTrackingInfo(Player)
end)


--Usable Items

    --Emitter
QBCore.Functions.CreateUseableItem(Config.Items["veh_tracker_emitter"].name, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if not Player.Functions.GetItemByName(item.name) then return end
    TriggerClientEvent('jbb:vehtrack:client:putemitter', source)
end)

    --Receiver
QBCore.Functions.CreateUseableItem(Config.Items["veh_tracker_receiver"].name, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if not Player.Functions.GetItemByName(item.name) then return end
    TriggerClientEvent('jbb:vehtrack:client:setchannel', source)
end)

    --Scanner
QBCore.Functions.CreateUseableItem(Config.Items["veh_tracker_scanner"].name, function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if not Player.Functions.GetItemByName(item.name) then return end
    TriggerClientEvent('jbb:vehtrack:client:scanning', source)
end)


--Loops
CreateThread(function ()
    while true do
        --clearing entities that no longer exists
        for chan,trackedVehicles in pairs(tracked) do
            for i = #trackedVehicles, 1, -1 do
                if not DoesEntityExist(NetworkGetEntityFromNetworkId(trackedVehicles[i].vehicle)) then
                    local player = QBCore.Functions.GetPlayerByCitizenId(trackedVehicles[i].player)
                    TriggerClientEvent('jbb:vehtrack:client:vehicledel', player.PlayerData.source, trackedVehicles[i])
                    tracked[chan][i] = nil
                end
            end
        end

        Wait(0)

        for chan,players in pairs(registered) do
            if #players > 0 then 
                local vehicles = getVehiclesPositionsInChannel(chan)

                --Send new positions for each players
                if #vehicles > 0 then
                    for idx,citizenid in ipairs(players) do
                        local player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
                        if player and player.Functions.GetItemByName(Config.Items["veh_tracker_receiver"].name) then
                            TriggerClientEvent('jbb:vehtrack:client:updatepos', player.PlayerData.source, vehicles)
                        end
                    end
                end
            end
        end

        Wait(Config.Settings.refreshTime)
    end
end)