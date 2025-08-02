QBCore = GetResourceState('qb-core'):find('start') and exports['qb-core']:GetCoreObject() or nil

if not QBCore then return end

function removeAccountMoney(target, account, amount)
    local xPlayer = QBCore.Functions.GetPlayer(target)
    if not xPlayer then return end
    xPlayer.Functions.RemoveMoney(account, amount)
end

function hasJob(target, jobs)
    local xPlayer = QBCore.Functions.GetPlayer(target)
    if not xPlayer then return false end

    if type(jobs) == "table" then
        for index, jobName in pairs(jobs) do
            if xPlayer.PlayerData.job.name == jobName then return true end
        end
    else
        return xPlayer.PlayerData.job.name == jobs
    end

    return false
end

function playerJob(target)
    local xPlayer = QBCore.Functions.GetPlayer(target)
    if not xPlayer then return nil end

    return xPlayer.PlayerData.job.name
end

function updateStatus(data)
    local Player = QBCore.Functions.GetPlayer(data.target)

    if not Player then
        print("[ERROR] Could not find player with ID: " .. tostring(data.target))
        return
    end

    Player.Functions.SetMetaData("isdead", data.status)

    if not player[source] then
        player[source] = {}
    end

    player[source].isDead = data.status

    if data.status == true then
        player[source].killedBy = data.killedBy
    end
end

function getPlayerName(target)
    local xPlayer = QBCore.Functions.GetPlayer(target)
    if not xPlayer then return "Unknown Player" end

    return xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
end

function getDeathStatus(target)
    local Player = QBCore.Functions.GetPlayer(target)
    if not Player then return { isDead = false } end

    local data = {
        isDead = Player.PlayerData.metadata['isdead']
    }

    return data
end

-- Save player health and armor to KVP
function savePlayerHealthArmor(target, health, armor)
    local Player = QBCore.Functions.GetPlayer(target)
    if not Player then return end

    local identifier = Player.PlayerData.citizenid

    -- Save to KVP using citizenid as unique identifier
    SetResourceKvp("ars_ambulance_health_" .. identifier, tostring(health))
    SetResourceKvp("ars_ambulance_armor_" .. identifier, tostring(armor))

    if Config.Debug and Config.HealthArmorPersistence.Debug then
        print("^2[DEBUG]^7 QB-KVP: Saved health/armor for", identifier, "Health:", health, "Armor:", armor)
    end
end

-- Get player health and armor from KVP
function getPlayerHealthArmor(target)
    local Player = QBCore.Functions.GetPlayer(target)
    if not Player then return { health = 200, armor = 0 } end

    local identifier = Player.PlayerData.citizenid

    -- Get from KVP
    local savedHealth = GetResourceKvpString("ars_ambulance_health_" .. identifier)
    local savedArmor = GetResourceKvpString("ars_ambulance_armor_" .. identifier)

    local health = tonumber(savedHealth) or 200
    local armor = tonumber(savedArmor) or 0

    -- Ensure valid ranges
    health = math.max(0, math.min(200, health))
    armor = math.max(0, math.min(100, armor))

    if Config.Debug and Config.HealthArmorPersistence.Debug then
        print("^2[DEBUG]^7 QB-KVP: Retrieved health/armor for", identifier, "Health:", health, "Armor:", armor)
    end

    return { health = health, armor = armor }
end

QBCore.Functions.CreateUseableItem(Config.MedicBagItem, function(source, item)
    if not hasJob(source, Config.EmsJobs) then return end

    TriggerClientEvent("ars_ambulancejob:placeMedicalBag", source)
end)
