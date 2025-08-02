local ESX = GetResourceState('es_extended'):find('start') and exports['es_extended']:getSharedObject() or nil

if not ESX then return end

function removeAccountMoney(target, account, amount)
    local xPlayer = ESX.GetPlayerFromId(target)
    xPlayer.removeAccountMoney(account, amount)
end

function hasJob(target, jobs)
    local xPlayer = ESX.GetPlayerFromId(target)

    if type(jobs) == "table" then
        for index, jobName in pairs(jobs) do
            if xPlayer.job.name == jobName then return true end
        end
    else
        return xPlayer.job.name == jobs
    end

    return false
end

function playerJob(target)
    local xPlayer = ESX.GetPlayerFromId(target)

    return xPlayer.job.name
end

function updateStatus(data)
    local xPlayer = ESX.GetPlayerFromId(data.target)

    MySQL.update('UPDATE users SET is_dead = ? WHERE identifier = ?', { data.status, xPlayer.identifier })

    if not player[source] then
        player[source] = {}
    end

    player[source].isDead = data.status

    if data.status == true then
        player[source].killedBy = data.killedBy
    end
end

function getPlayerName(target)
    local xPlayer = ESX.GetPlayerFromId(target)

    return xPlayer.getName()
end

function getDeathStatus(target)
    local xPlayer = ESX.GetPlayerFromId(target)

    local isDead = MySQL.scalar.await('SELECT `is_dead` FROM `users` WHERE `identifier` = ? LIMIT 1', {
        xPlayer.identifier
    })

    local data = {
        isDead = isDead
    }

    return data
end

-- Save player health and armor to KVP
function savePlayerHealthArmor(target, health, armor)
    local xPlayer = ESX.GetPlayerFromId(target)
    if not xPlayer then return end

    local identifier = xPlayer.identifier

    -- Save to KVP using identifier as unique key
    SetResourceKvp("ars_ambulance_health_" .. identifier, tostring(health))
    SetResourceKvp("ars_ambulance_armor_" .. identifier, tostring(armor))

    if Config.Debug and Config.HealthArmorPersistence.Debug then
        print("^2[DEBUG]^7 ESX-KVP: Saved health/armor for", identifier, "Health:", health, "Armor:", armor)
    end
end

-- Get player health and armor from KVP
function getPlayerHealthArmor(target)
    local xPlayer = ESX.GetPlayerFromId(target)
    if not xPlayer then return { health = 200, armor = 0 } end

    local identifier = xPlayer.identifier

    -- Get from KVP
    local savedHealth = GetResourceKvpString("ars_ambulance_health_" .. identifier)
    local savedArmor = GetResourceKvpString("ars_ambulance_armor_" .. identifier)

    local health = tonumber(savedHealth) or 200
    local armor = tonumber(savedArmor) or 0

    -- Ensure valid ranges
    health = math.max(0, math.min(200, health))
    armor = math.max(0, math.min(100, armor))

    if Config.Debug and Config.HealthArmorPersistence.Debug then
        print("^2[DEBUG]^7 ESX-KVP: Retrieved health/armor for", identifier, "Health:", health, "Armor:", armor)
    end

    return { health = health, armor = armor }
end

ESX.RegisterUsableItem(Config.MedicBagItem, function(source)
    if not hasJob(source, Config.EmsJobs) then return end

    TriggerClientEvent("ars_ambulancejob:placeMedicalBag", source)
end)

CreateThread(function()
    for k, v in pairs(Config.EmsJobs) do
        TriggerEvent('esx_society:registerSociety', v, v, 'society_' .. v, 'society_' .. v, 'society_' .. v, { type = 'public' })
    end
end)
