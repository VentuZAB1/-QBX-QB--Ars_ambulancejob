local DoScreenFadeOut              = DoScreenFadeOut
local IsScreenFadedOut             = IsScreenFadedOut
local NetworkResurrectLocalPlayer  = NetworkResurrectLocalPlayer
local ShakeGameplayCam             = ShakeGameplayCam
local AnimpostfxPlay               = AnimpostfxPlay
local CreateThread                 = CreateThread
local Wait                         = Wait
local SetEntityCoords              = SetEntityCoords
local TaskPlayAnim                 = TaskPlayAnim
local FreezeEntityPosition         = FreezeEntityPosition
local ClearPedTasks                = ClearPedTasks
local SetEntityHealth              = SetEntityHealth
local SetEntityInvincible          = SetEntityInvincible
local SetEveryoneIgnorePlayer      = SetEveryoneIgnorePlayer
local GetGameTimer                 = GetGameTimer
local IsControlJustPressed         = IsControlJustPressed
local TriggerServerEvent           = TriggerServerEvent
local AddEventHandler              = AddEventHandler
local SetEntityHeading             = SetEntityHeading
local DoScreenFadeIn               = DoScreenFadeIn
local PlayerPedId                  = PlayerPedId
local NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local IsPedAPlayer                 = IsPedAPlayer
local IsPedDeadOrDying             = IsPedDeadOrDying
local IsPedFatallyInjured          = IsPedFatallyInjured

-- Simple fallback initialization - doesn't depend on framework events
CreateThread(function()
    Wait(5000) -- Wait for resources to load

    -- Set basic player state if framework events didn't fire
    if not player.loaded and not player.loadedTime then
        player.loadedTime = GetGameTimer()
        if Config.Debug then
            print("^2[DEBUG]^7 ⚠️ Framework event didn't fire - using fallback initialization")
        end

        -- Call onPlayerLoaded with fallback to ensure basic functionality
        CreateThread(function()
            Wait(2000)
            if not player.loaded then
                if Config.Debug then
                    print("^2[DEBUG]^7 Calling onPlayerLoaded fallback")
                end
                onPlayerLoaded()
            end
        end)
    end
end)

function stopPlayerDeath()
    if Config.Debug then
        print("^2[DEBUG]^7 ============ STOPPING DEATH STATE ============")
    end

    player.isDead = false
    -- player.injuries = {}

    -- Close death UI
    closeDeathUI()

    local playerPed = cache.ped or PlayerPedId()

    DoScreenFadeOut(800)

    while not IsScreenFadedOut() do
        Wait(50)
    end

    local coords = cache.coords or GetEntityCoords(playerPed)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, coords.w, false, false)

    local deathStatus = { isDead = false }
    TriggerServerEvent('ars_ambulancejob:updateDeathStatus', deathStatus)

    playerPed = PlayerPedId()

    if cache.vehicle then
        SetPedIntoVehicle(cache.ped, cache.vehicle, cache.seat)
    end

    ClearPedBloodDamage(playerPed)
    SetEntityInvincible(playerPed, false)
    SetEveryoneIgnorePlayer(cache.playerId, false)
    ClearPedTasks(playerPed)
    AnimpostfxStopAll()

    DoScreenFadeIn(700)
    TaskPlayAnim(playerPed, Config.DeathAnimations["revive"].dict, Config.DeathAnimations["revive"].clip, 8.0, -8.0, -1, 0, 0, 0, 0, 0)

    -- LocalPlayer.state:set("injuries", {}, true)
    LocalPlayer.state:set("dead", false, true)
    player.distressCallTime = nil

    playerSpawned()
    healPlayer()
end

-- Utility function to set health with cap
local function setHealthWithCap(ped, health)
    local cappedHealth = math.min(health, Config.HealthArmorPersistence.MaxHealthCap)
    SetEntityHealth(ped, cappedHealth)

    if Config.Debug then
        print("^2[DEBUG]^7 Health set: requested=" .. health .. ", capped=" .. cappedHealth)
    end
end

function healPlayer()
    local playerPed = cache.ped or PlayerPedId()
    local maxHealth = GetEntityMaxHealth(playerPed)

    setHealthWithCap(playerPed, maxHealth)
    healStatus()
end

RegisterNetEvent("ars_ambulancejob:healPlayer", function(data)
    if data.revive then
        stopPlayerDeath()
    elseif data.injury then
        treatInjury(data.bone)
    elseif data.heal then
        healPlayer()
    end
end)

-- Kill event handler for testing
RegisterNetEvent('ars_ambulancejob:killPlayer', function()
    if Config.Debug then
        print("^2[DEBUG]^7 /kill command received - forcing player death")
    end
    local playerPed = cache.ped or PlayerPedId()

    -- Force death by setting health to 0
    SetEntityHealth(playerPed, 0)

    -- Also trigger death event for consistency
    TriggerEvent('gameEventTriggered', 'CEventNetworkEntityDamage', {
        playerPed, -- victim
        playerPed, -- attacker
        0, -- weapon hash
        1, -- isDead
        0, -- unknown
        0, -- unknown
        0, -- weapon
    })

    if Config.Debug then
        print("^2[DEBUG]^7 /kill command executed - health set to 0")
    end
end)

local function respawnPlayer()
    local playerPed = cache.ped or PlayerPedId()

    if Config.RemoveItemsOnRespawn then
        TriggerServerEvent("ars_ambulancejob:removeInventory")
    end

    lib.requestAnimDict("anim@gangops@morgue@table@")
    lib.requestAnimDict("switch@franklin@bed")

    local hospital = utils.getClosestHospital()
    local bed = nil

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(1) end

    for i = 1, #hospital.respawn do
        local _bed = hospital.respawn[i]
        local isBedOccupied = utils.isBedOccupied(_bed.bedPoint)
        if not isBedOccupied then
            bed = _bed
            break
        end
    end

    if not bed then bed = hospital.respawn[1] end

    player.respawning = true

    SetEntityCoords(playerPed, bed.bedPoint)
    SetEntityHeading(playerPed, bed.bedPoint.w)
    TaskPlayAnim(playerPed, "anim@gangops@morgue@table@", "body_search", 2.0, 2.0, -1, 1, 0, false, false, false)
    FreezeEntityPosition(playerPed, true)


    DoScreenFadeIn(300)
    Wait(5000)
    SetEntityCoords(playerPed, vector3(bed.bedPoint.x, bed.bedPoint.y, bed.bedPoint.z) + vector3(0.0, 0.0, -1.0))
    FreezeEntityPosition(playerPed, false)
    SetEntityHeading(cache.ped, bed.bedPoint.w + 90.0)
    TaskPlayAnim(playerPed, "switch@franklin@bed", "sleep_getup_rubeyes", 1.0, 1.0, -1, 8, -1, 0, 0, 0)

    Wait(5000)

    stopPlayerDeath()
    ClearPedTasks(playerPed)
    SetEntityCoords(playerPed, bed.spawnPoint)
    player.respawning = false
end

local function initPlayerDeath(logged_dead)
    if player.isDead then
        if Config.Debug then
            print("^2[DEBUG]^7 initPlayerDeath called but player already dead - skipping")
        end
        return
    end

    if Config.Debug then
        print("^2[DEBUG]^7 ============ INITIALIZING DEATH STATE ============")
        print("^2[DEBUG]^7 Logged dead:", logged_dead)
    end

    player.isDead = true

    -- Ensure any previous UI state is cleaned up
    if not logged_dead then
        closeDeathUI()
    end
    startCommandTimer()

    for _, anim in pairs(Config.DeathAnimations) do
        if Config.Debug then
            print("^2[DEBUG]^7 Loading animation dict:", anim.dict)
        end
        lib.requestAnimDict(anim.dict)
    end

    if logged_dead then goto logged_dead end

    -- Clear any existing visual effects that might darken the screen
    AnimpostfxStopAll()

            if Config.ExtraEffects then
        if Config.Debug then
            print("^2[DEBUG]^7 Applying death effects")
        end
        ShakeGameplayCam('DEATH_FAIL_IN_EFFECT_SHAKE', 1.0)

        -- Use subtle visual effects without harsh darkness
        -- Apply a brief screen fade for impact, but no dark post-processing
        DoScreenFadeOut(300)
        Wait(500)
        DoScreenFadeIn(800)

        -- Apply a subtle desaturation effect instead of darkness
        AnimpostfxPlay('MP_Celeb_Win', 0, true)
        CreateThread(function()
            Wait(3000)
            if player.isDead then
                AnimpostfxStop('MP_Celeb_Win')
                if Config.Debug then
                    print("^2[DEBUG]^7 Stopped subtle death effect")
                end
            end
        end)
    end

    if not player.isDead then return end

    ::logged_dead::
    local playerPed = cache.ped or PlayerPedId()

    CreateThread(function()
        while player.isDead do
            DisableFirstPersonCamThisFrame()
            Wait(0) -- This needs to stay at Wait(0) as it's a per-frame disable
        end
    end)

    local coords = cache.coords or GetEntityCoords(playerPed)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(playerPed), false, false)
    playerPed = PlayerPedId()

    if cache.vehicle then
        SetPedIntoVehicle(cache.ped, cache.vehicle, cache.seat)
    end

    SetEntityInvincible(cache.ped, true)
    SetEntityHealth(cache.ped, 100)
    SetEveryoneIgnorePlayer(cache.playerId, true)

    local time = 60000 * Config.RespawnTime
    local deathTime = GetGameTimer()

    if Config.Debug then
        print("^2[DEBUG]^7 Starting death loop")
        print("^2[DEBUG]^7 Respawn time:", time/1000, "seconds")
    end

    CreateThread(function()
        local lastAnimCheck = 0
        local animCheckInterval = Config.Performance.AnimationCheckInterval or 1500 -- Use configurable interval

        while player.isDead do
            local currentTime = GetGameTimer()
            local sleep = 500 -- Minimum sleep time between iterations

            if not player.gettingRevived and not player.respawning then
                -- Throttle animation checks to reduce performance
                if currentTime - lastAnimCheck >= animCheckInterval then
                    lastAnimCheck = currentTime

                local anim = cache.vehicle and Config.DeathAnimations["car"] or Config.DeathAnimations["normal"]

                if not IsEntityPlayingAnim(playerPed, anim.dict, anim.clip, 3) then
                        if Config.Debug then
                            print("^2[DEBUG]^7 Playing death animation:", anim.dict, anim.clip)
                        end
                    TaskPlayAnim(playerPed, anim.dict, anim.clip, 50.0, 8.0, -1, 1, 1.0, false, false, false)
                    end
                end

                local elapsedSeconds = math.floor((GetGameTimer() - deathTime) / 1000)

                -- Commented out for later implementation
                --[[
                utils.drawTextFrame({
                    x = 0.5,
                    y = 0.9,
                    msg = "Press ~r~E~s~ to call medics"
                })

                if IsControlJustPressed(0, 38) then
                    if Config.Debug then
                        print("^2[DEBUG]^7 Calling medics")
                    end
                    createDistressCall()
                end
                --]]

                if GetGameTimer() - deathTime >= time then
                    EnableControlAction(0, 47, true)

                    -- Commented out for later implementation
                    --[[
                    utils.drawTextFrame({
                        x = 0.5,
                        y = 0.86,
                        msg = "Press ~r~G~s~ to respawn"
                    })

                    if IsControlJustPressed(0, 47) then
                        if Config.Debug then
                            print("^2[DEBUG]^7 Player attempting to respawn")
                        end
                        local confirmation = lib.alertDialog({
                            header = 'Respawn',
                            content = 'Are you sure you want to respawn?',
                            centered = true,
                            cancel = true
                        })

                        if confirmation == "confirm" then
                            if Config.Debug then
                                print("^2[DEBUG]^7 Respawn confirmed")
                            end
                            respawnPlayer()
                        end
                    end
                    --]]
                else
                    -- Commented out for later implementation
                    --[[
                    utils.drawTextFrame({
                        x = 0.5,
                        y = 0.86,
                        msg = ("Respawn available in ~b~ %s seconds~s~"):format(math.floor((time / 1000) - elapsedSeconds))
                    })
                    --]]
                end
            else
                sleep = 1000 -- Longer sleep when getting revived or respawning
            end

            Wait(sleep)
        end
    end)

    local deathData = {
        isDead = true
    }
    TriggerServerEvent('ars_ambulancejob:updateDeathStatus', deathData)
    LocalPlayer.state:set("dead", true, true)

    -- Initialize death UI
    if logged_dead then
        -- If player was logged dead, show UI immediately
        if Config.Debug then
            print("^2[DEBUG]^7 Calling DrawDeathUI immediately (logged dead)")
        end
        DrawDeathUI()
    else
        -- For new deaths, show UI after effects
        CreateThread(function()
            Wait(1000) -- Wait 1 second for death effects to complete
            if player.isDead then -- Make sure player is still dead
                DrawDeathUI()
            end
        end)
    end

    if Config.Debug then
        print("^2[DEBUG]^7 ============ DEATH STATE INITIALIZED ============")
    end
end

-- Register death event
RegisterNetEvent('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local attacker = args[2]
        local isDead = args[4] == 1
        local weapon = args[7]

        if not IsPedAPlayer(victim) then return end

        local victimServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(victim))
        if victimServerId ~= cache.serverId then return end

        if isDead and not player.isDead then
            if Config.Debug then
                print("^2[DEBUG]^7 Death detected via gameEventTriggered")
            end
            updateInjuries(victim, weapon)
            initPlayerDeath()
        end
    end
end)

-- Alternative direct death event handler (more reliable for natural deaths)
AddEventHandler('gameEventTriggered', function(name, data)
    if name == 'CEventNetworkEntityDamage' then
        local entity = data[1]
        local attacker = data[2]
        local weaponHash = data[7]
        local hasEntityDied = data[4]

        if entity == cache.ped and hasEntityDied == 1 and not player.isDead then
            if Config.Debug then
                print("^2[DEBUG]^7 Death detected via alternative gameEventTriggered handler")
            end
            updateInjuries(entity, weaponHash)
            initPlayerDeath()
        end
    end
end)

-- Consolidated and optimized death detection system
CreateThread(function()
    local wasAlive = true
    local lastHealth = 200
    local lastCheck = 0

    -- Initialize basic player state if not already set
    if not player.loadedTime then
        player.loadedTime = GetGameTimer()
        if Config.Debug then
            print("^2[DEBUG]^7 Initializing player.loadedTime for death detection")
        end
    end

    if Config.Debug then
        print("^2[DEBUG]^7 🔄 Death detection thread started")
    end

    while true do
        local currentTime = GetGameTimer()
        local shouldContinue = false

        -- Use configurable timing - check less frequently when not critical
        local checkInterval = player.isDead and 2000 or (Config.Performance.DeathCheckInterval or 500)

        if currentTime - lastCheck < checkInterval then
            Wait(100)
            shouldContinue = true
        end

        if not shouldContinue then
            lastCheck = currentTime

            -- SPAWN PROTECTION: Wait for player to be properly loaded
            -- Don't block death detection if player.loaded isn't set, but still provide spawn protection
            if not player.loaded and not player.loadedTime then
                -- If neither loaded flag nor loadedTime is set, set loadedTime to prevent infinite waiting
                player.loadedTime = GetGameTimer()
                if Config.Debug then
                    print("^2[DEBUG]^7 Setting loadedTime fallback for death detection")
                end
            end
        end

        if not shouldContinue then
            -- Additional spawn protection - wait a bit more after loading
            local timeSinceLoaded = currentTime - (player.loadedTime or 0)
            if timeSinceLoaded < 5000 then -- 5 second protection after loading
                Wait(2000)
                shouldContinue = true
            end
        end

        if not shouldContinue then
            -- Skip if already dead to reduce unnecessary checks
            if player.isDead then
                Wait(2000)
                shouldContinue = true
            end
        end

        if not shouldContinue then
            local playerPed = cache.ped or PlayerPedId()
            if playerPed and playerPed > 0 then
                local timeSinceLoaded = currentTime - (player.loadedTime or 0)
                local currentHealth = GetEntityHealth(playerPed)

                -- Combine multiple death detection methods into one check
                local isEntityDead = IsEntityDead(playerPed)
                local isPlayerWasted = IsPlayerDead(cache.playerId)
                local isPedDying = IsPedDeadOrDying(playerPed, true)
                local isPedFatallyInjured = IsPedFatallyInjured(playerPed)

                local isDead = currentHealth <= 0 or isEntityDead or isPlayerWasted or isPedDying or isPedFatallyInjured
                local healthDroppedToZero = lastHealth > 0 and currentHealth <= 0

                -- SPAWN PROTECTION: Don't trigger death if player just spawned with low health
                local isLikelySpawnIssue = currentHealth <= 0 and lastHealth <= 0 and timeSinceLoaded < 10000

                -- If player just died (was alive, now dead) and not already in death state
                if ((wasAlive and isDead) or healthDroppedToZero) and not player.isDead and not isLikelySpawnIssue then
                    if Config.Debug then
                        print("^2[DEBUG]^7 ⚠️ DEATH DETECTED ⚠️")
                        print("^2[DEBUG]^7 Health:", currentHealth, "LastHealth:", lastHealth)
                        print("^2[DEBUG]^7 WasAlive:", wasAlive, "IsDead:", isDead)
                        print("^2[DEBUG]^7 HealthDroppedToZero:", healthDroppedToZero)
                        print("^2[DEBUG]^7 Player.isDead:", player.isDead)
                        print("^2[DEBUG]^7 TimeSinceLoaded:", timeSinceLoaded, "IsLikelySpawnIssue:", isLikelySpawnIssue)
                    end

                    -- Update injuries and trigger death
                    updateInjuries(playerPed, -842959696)
                    initPlayerDeath()
                    -- Don't break - continue monitoring for future deaths
                end

                -- During spawn protection, heal player if needed
                if timeSinceLoaded < 5000 and currentHealth <= 0 and not player.isDead then
                    if Config.Debug then
                        print("^2[DEBUG]^7 SPAWN PROTECTION: Healing player with 0 health during spawn")
                    end
                    local maxHealth = GetEntityMaxHealth(playerPed)
                    setHealthWithCap(playerPed, maxHealth)
                    currentHealth = math.min(maxHealth, Config.HealthArmorPersistence.MaxHealthCap)
                end

                wasAlive = not isDead and not player.isDead and currentHealth > 0
                lastHealth = currentHealth
            end
        end

        Wait(100) -- Base wait time between checks
    end
end)

function onPlayerLoaded()
    exports.spawnmanager:setAutoSpawn(false) -- for qbcore

    -- Record when player was loaded for spawn protection
    player.loadedTime = GetGameTimer()

    -- Get player status including death state and health/armor
    local data = lib.callback.await('ars_ambulancejob:getPlayerStatus', false)

    if data?.isDead then
        initPlayerDeath(true)
        utils.showNotification("logged_dead")
    else
        -- Ensure player is alive and restore their saved health/armor (if enabled)
        CreateThread(function()
            Wait(2000) -- Wait 2 seconds for everything to load

            local playerPed = cache.ped or PlayerPedId()
            if playerPed and playerPed > 0 then
                local currentHealth = GetEntityHealth(playerPed)
                local maxHealth = GetEntityMaxHealth(playerPed)
                local currentArmor = GetPedArmour(playerPed)

                if Config.HealthArmorPersistence.Enable then
                    -- Get saved health and armor from server
                    local savedHealth = data.health or maxHealth
                    local savedArmor = data.armor or 0

                    if Config.Debug and Config.HealthArmorPersistence.Debug then
                        print("^2[DEBUG]^7 POST-SPAWN HEALTH/ARMOR RESTORATION")
                        print("^2[DEBUG]^7 Current health:", currentHealth, "Max health:", maxHealth)
                        print("^2[DEBUG]^7 Current armor:", currentArmor)
                        print("^2[DEBUG]^7 Saved health:", savedHealth, "Saved armor:", savedArmor)
                    end

                    -- Restore saved health and armor
                    if savedHealth ~= currentHealth then
                        if Config.Debug and Config.HealthArmorPersistence.Debug then
                            print("^2[DEBUG]^7 Restoring health from", currentHealth, "to", savedHealth)
                        end
                        setHealthWithCap(playerPed, savedHealth)
                    end

                    if savedArmor ~= currentArmor then
                        if Config.Debug and Config.HealthArmorPersistence.Debug then
                            print("^2[DEBUG]^7 Restoring armor from", currentArmor, "to", savedArmor)
                        end
                        SetPedArmour(playerPed, savedArmor)
                    end

                    -- If health is too low and they're not supposed to be dead, restore to minimum safe level
                    local minHealthPercent = Config.HealthArmorPersistence.MinHealthForAlive or 10
                    local minHealth = maxHealth * (minHealthPercent / 100)

                    if savedHealth < minHealth and not data.isDead then
                        if Config.Debug and Config.HealthArmorPersistence.Debug then
                            print("^2[DEBUG]^7 Health too low for alive player - setting to minimum safe level")
                        end
                        setHealthWithCap(playerPed, math.max(savedHealth, minHealth))
                    end
                else
                    -- If persistence is disabled, just do basic health check
                    if currentHealth < maxHealth * 0.5 then -- If less than 50% health
                        if Config.Debug then
                            print("^2[DEBUG]^7 Basic health restoration - current health too low")
                        end
                        setHealthWithCap(playerPed, maxHealth)
                    end
                end
            end
        end)
    end
end

-- Periodic health and armor saving (optimized)
CreateThread(function()
    local lastSaveTime = 0
    local lastHealthArmor = {health = 0, armor = 0}

    while true do
        local saveInterval = (Config.HealthArmorPersistence.SaveInterval or 60) * 1000
        local currentTime = GetGameTimer()

        -- Check if it's time to save and if persistence is enabled
        if Config.HealthArmorPersistence.Enable and player.loaded and not player.isDead and (currentTime - lastSaveTime >= saveInterval) then
            local playerPed = cache.ped or PlayerPedId()
            if playerPed and playerPed > 0 then
                local health = GetEntityHealth(playerPed)
                local armor = GetPedArmour(playerPed)

                -- Only save if values are reasonable AND different from last save
                if health > 0 and health <= 200 and armor >= 0 and armor <= 100 then
                    local healthThreshold = Config.Performance.HealthChangeThreshold or 5
                    -- Only save if health or armor changed significantly (prevents unnecessary server calls)
                    if math.abs(health - lastHealthArmor.health) > healthThreshold or math.abs(armor - lastHealthArmor.armor) > healthThreshold then
                        TriggerServerEvent("ars_ambulancejob:saveHealthArmor", health, armor)
                        lastSaveTime = currentTime
                        lastHealthArmor = {health = health, armor = armor}

                        if Config.Debug and Config.HealthArmorPersistence.Debug then
                            print("^2[DEBUG]^7 Periodic save - Health:", health, "Armor:", armor)
                        end
                    end
                end
            end
        end

        -- Smart sleep - sleep longer if persistence is disabled or player is dead
        local sleepTime = (Config.HealthArmorPersistence.Enable and not player.isDead) and 5000 or 15000
        Wait(sleepTime)
    end
end)

-- Event handler for respawn request from UI
RegisterNetEvent('ars_ambulancejob:requestRespawn', function()
    if not player.isDead then return end
    respawnPlayer()
end)

exports("isDead", function()
    return player.isDead
end)

-- © 𝐴𝑟𝑖𝑢𝑠 𝐷𝑒𝑣𝑒𝑙𝑜𝑝𝑚𝑒𝑛𝑡
