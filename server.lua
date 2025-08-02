player = {}
distressCalls = {}

-- Function to remove distress call by player ID
function removeDistressCallByPlayer(playerId)
    for i = #distressCalls, 1, -1 do
        if distressCalls[i].playerId == playerId then
            local callData = distressCalls[i]
            table.remove(distressCalls, i)

            -- Remove the blip from all EMS players
            local players = GetPlayers()
            for j = 1, #players do
                local id = tonumber(players[j])
                if hasJob(id, Config.EmsJobs) then
                    TriggerClientEvent("ars_ambulancejob:removeDistressBlip", id, callData)
                end
            end
            break
        end
    end
end

RegisterNetEvent("ars_ambulancejob:updateDeathStatus", function(death)
    local data = {}
    data.target = source
    data.status = death.isDead
    data.killedBy = death?.weapon or false

    updateStatus(data)

    -- Remove distress call and blip if player is no longer dead
    if not death.isDead then
        removeDistressCallByPlayer(source)
    end
end)

RegisterNetEvent("ars_ambulancejob:revivePlayer", function(data)
    if not hasJob(source, Config.EmsJobs) or not source or source < 1 then return end

    local sourcePed = GetPlayerPed(source)
    local targetPed = GetPlayerPed(data.targetServerId)

    if data.targetServerId < 1 or #(GetEntityCoords(sourcePed) - GetEntityCoords(targetPed)) > 4.0 then
        print(source .. ' probile modder')
    else
        local dataToSend = {}
        dataToSend.revive = true

        TriggerClientEvent('ars_ambulancejob:healPlayer', tonumber(data.targetServerId), dataToSend)
    end
end)

RegisterNetEvent("ars_ambulancejob:healPlayer", function(data)
    if not hasJob(source, Config.EmsJobs) or not source or source < 1 then return end

    local sourcePed = GetPlayerPed(source)
    local targetPed = GetPlayerPed(data.targetServerId)

    if data.targetServerId < 1 or #(GetEntityCoords(sourcePed) - GetEntityCoords(targetPed)) > 4.0 then
        return print(source .. ' probile modder')
    end

    if data.injury then
        -- Existing injury treatment
        TriggerClientEvent('ars_ambulancejob:healPlayer', tonumber(data.targetServerId), data)
    elseif data.healWithBandage then
        -- New bandage healing for alive players
        data.anim = "healing"
        TriggerClientEvent("ars_ambulancejob:playHealAnim", source, data)
        data.anim = "receiving_heal"
        TriggerClientEvent("ars_ambulancejob:playHealAnim", data.targetServerId, data)
    else
        -- Existing revive system
        data.anim = "medic"
        TriggerClientEvent("ars_ambulancejob:playHealAnim", source, data)
        data.anim = "dead"
        TriggerClientEvent("ars_ambulancejob:playHealAnim", data.targetServerId, data)
    end
end)

RegisterNetEvent("ars_ambulancejob:createDistressCall", function(data)
    if Config.DebugDistressCalls then
        print("^3[SERVER DISTRESS]^7 Received distress call from player:", source)
    end

    if not source or source < 1 then
        if Config.DebugDistressCalls then
            print("^1[ERROR]^7 Invalid source for distress call")
        end
        return
    end

    local callData = {
        msg = data.msg,
        gps = data.gps,
        location = data.location,
        name = getPlayerName(source),
        playerId = source  -- Add player ID to track who made the call
    }

    if Config.DebugDistressCalls then
        print("^3[SERVER DISTRESS]^7 Call data:", json.encode(callData))
    end
    distressCalls[#distressCalls + 1] = callData

    local players = GetPlayers()
    local emsCount = 0

    for i = 1, #players do
        local id = tonumber(players[i])

        if hasJob(id, Config.EmsJobs) then
            emsCount = emsCount + 1
            if Config.DebugDistressCalls then
                print("^3[SERVER DISTRESS]^7 Sending distress call to EMS player:", id)
            end
            TriggerClientEvent("ars_ambulancejob:createDistressCall", id, getPlayerName(source))
            -- Also create the map blip for EMS
            TriggerClientEvent("ars_ambulancejob:createDistressCallBlip", id, callData)
        end
    end

    if Config.DebugDistressCalls then
        print("^3[SERVER DISTRESS]^7 Distress call sent to", emsCount, "EMS players")
    end
end)

RegisterNetEvent("ars_ambulancejob:callCompleted", function(call)
    for i = #distressCalls, 1, -1 do
        if distressCalls[i].gps == call.gps and distressCalls[i].msg == call.msg then
            local callData = distressCalls[i]
            table.remove(distressCalls, i)

            -- Remove the blip from all EMS players
            local players = GetPlayers()
            for j = 1, #players do
                local id = tonumber(players[j])
                if hasJob(id, Config.EmsJobs) then
                    TriggerClientEvent("ars_ambulancejob:removeDistressBlip", id, callData)
                end
            end
            break
        end
    end
end)

RegisterNetEvent("ars_ambulancejob:removAddItem", function(data)
    if data.toggle then
        exports.ox_inventory:RemoveItem(source, data.item, data.quantity)
    else
        exports.ox_inventory:AddItem(source, data.item, data.quantity)
    end
end)

RegisterNetEvent("ars_ambulancejob:useItem", function(data)
    if not hasJob(source, Config.EmsJobs) then return end

    local item = exports.ox_inventory:GetSlotWithItem(source, data.item)
    local slot = item.slot

    exports.ox_inventory:SetDurability(source, slot, item.metadata?.durability and (item.metadata?.durability - data.value) or (100 - data.value))
end)

RegisterNetEvent("ars_ambulancejob:removeInventory", function()
    if player[source].isDead and Config.RemoveItemsOnRespawn then
        exports.ox_inventory:ClearInventory(source)
    end
end)

RegisterNetEvent("ars_ambulancejob:putOnStretcher", function(data)
    if not player[data.target].isDead then return end
    TriggerClientEvent("ars_ambulancejob:putOnStretcher", data.target, data.toggle)
end)

RegisterNetEvent("ars_ambulancejob:togglePatientFromVehicle", function(data)
    print(data.target)
    if not player[data.target].isDead then return end

    TriggerClientEvent("ars_ambulancejob:togglePatientFromVehicle", data.target, data.vehicle)
end)

lib.callback.register('ars_ambulancejob:getDeathStatus', function(source, target)
    return player[target] and player[target] or getDeathStatus(target or source)
end)

lib.callback.register('ars_ambulancejob:getData', function(source, target)
    local data = {}
    data.injuries = Player(target).state.injuries or false
    data.status = getDeathStatus(target or source) or Player(target).state.dead
    data.killedBy = player[target]?.killedBy or false

    return data
end)

lib.callback.register('ars_ambulancejob:getDistressCalls', function(source)
    return distressCalls
end)

lib.callback.register('ars_ambulancejob:openMedicalBag', function(source)
    exports.ox_inventory:RegisterStash("medicalBag_" .. source, "Medical Bag", 10, 50 * 1000)

    return "medicalBag_" .. source
end)
lib.callback.register('ars_ambulancejob:getItem', function(source, name)
    local item = exports.ox_inventory:GetSlotWithItem(source, name)

    return item
end)

lib.callback.register('ars_ambulancejob:getMedicsOniline', function(source)
    local count = 0
    local players = GetPlayers()

    for i = 1, #players do
        local id = tonumber(players[i])

        if hasJob(id, Config.EmsJobs) then
            count += 1
        end
    end
    return count
end)

exports.ox_inventory:registerHook('swapItems', function(payload)
    if string.find(payload.toInventory, "medicalBag_") then
        if payload.fromSlot.name == Config.MedicBagItem then return false end
    end
end, {})

-- Handle player disconnect - remove their distress calls
AddEventHandler('playerDropped', function(reason)
    local playerId = source

    -- Save player health and armor before they disconnect (if enabled)
    if Config.HealthArmorPersistence.Enable and GetPlayerPed(playerId) and GetPlayerPed(playerId) > 0 then
        local health = GetEntityHealth(GetPlayerPed(playerId))
        local armor = GetPedArmour(GetPlayerPed(playerId))

        -- Ensure valid ranges
        health = math.max(0, math.min(Config.HealthArmorPersistence.MaxHealthCap, health))
        armor = math.max(0, math.min(100, armor))

        savePlayerHealthArmor(playerId, health, armor)

        if Config.Debug and Config.HealthArmorPersistence.Debug then
            print("^2[DEBUG]^7 Player", playerId, "disconnected - saved health:", health, "armor:", armor)
        end
    end

    -- Remove any active distress calls from this player
    removeDistressCallByPlayer(playerId)

    -- Clean up player data
    if player[playerId] then
        player[playerId] = nil
    end
end)

-- Event to save health/armor on demand (for periodic saving)
RegisterNetEvent("ars_ambulancejob:saveHealthArmor", function(health, armor)
    local playerId = source
    if not playerId or playerId < 1 or not Config.HealthArmorPersistence.Enable then return end

    -- Ensure valid ranges
    health = math.max(0, math.min(Config.HealthArmorPersistence.MaxHealthCap, health or Config.HealthArmorPersistence.MaxHealthCap))
    armor = math.max(0, math.min(100, armor or 0))

    savePlayerHealthArmor(playerId, health, armor)

    if Config.Debug and Config.HealthArmorPersistence.Debug then
        print("^2[DEBUG]^7 Manual save - Player:", playerId, "Health:", health, "Armor:", armor)
    end
end)

-- Callback to get saved health and armor data
lib.callback.register('ars_ambulancejob:getHealthArmor', function(source, target)
    if not Config.HealthArmorPersistence.Enable then
        return { health = 200, armor = 0 }
    end

    local targetId = target or source
    return getPlayerHealthArmor(targetId)
end)

-- Enhanced death status callback that includes health/armor
lib.callback.register('ars_ambulancejob:getPlayerStatus', function(source, target)
    local targetId = target or source
    local deathData = getDeathStatus(targetId)

    local healthArmorData = { health = 200, armor = 0 }
    if Config.HealthArmorPersistence.Enable then
        healthArmorData = getPlayerHealthArmor(targetId)
    end

    return {
        isDead = deathData.isDead,
        health = healthArmorData.health,
        armor = healthArmorData.armor
    }
end)

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for index, hospital in pairs(Config.Hospitals) do
            local cfg = hospital

            for id, stash in pairs(cfg.stash) do
                exports.ox_inventory:RegisterStash(id, stash.label, stash.slots, stash.weight * 1000, cfg.stash.shared and true or nil)
            end

            for id, pharmacy in pairs(cfg.pharmacy) do
                exports.ox_inventory:RegisterShop(id, {
                    name = pharmacy.label,
                    inventory = pharmacy.items,
                })
            end
        end
    end
end)


lib.versionCheck('Arius-Development/ars_ambulancejob')
