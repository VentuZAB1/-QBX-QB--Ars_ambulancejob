local GetPlayerServerId            = GetPlayerServerId
local NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local PlayerPedId                  = PlayerPedId
local GetEntityHeading             = GetEntityHeading
local GetEntityForwardVector       = GetEntityForwardVector
local GetGameTimer                 = GetGameTimer
local GetEntityCoords              = GetEntityCoords
local GetStreetNameAtCoord         = GetStreetNameAtCoord
local GetStreetNameFromHashKey     = GetStreetNameFromHashKey
local TriggerServerEvent           = TriggerServerEvent
local CreateThread                 = CreateThread
local CreateObject                 = CreateObject
local AttachEntityToEntity         = AttachEntityToEntity
local SetNewWaypoint               = SetNewWaypoint
local ClearPedTasks                = ClearPedTasks
local DeleteEntity                 = DeleteEntity
local TaskPlayAnim                 = TaskPlayAnim
local PlaySound                    = PlaySound
local SetEntityVisible             = SetEntityVisible
local SetEntityInvincible          = SetEntityInvincible
local TriggerEvent                 = TriggerEvent
local SetCurrentPedWeapon          = SetCurrentPedWeapon


local function checkPatient(target)
    local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(target))
    local data = lib.callback.await('ars_ambulancejob:getData', false, targetServerId)
    local isDead = data.status.isDead
    local status = isDead and locale("patient_not_conscious") or locale("patient_conscious")

    -- Get target player's health for healing check
    local targetHealth = GetEntityHealth(target)
    local targetMaxHealth = GetEntityMaxHealth(target)
    local isFullHealth = targetHealth >= targetMaxHealth

    utils.debug(data)

    lib.progressBar({
        duration = 3000,
        label = locale("checking_patient"),
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
        },
    })

    local options = {
        {
            title = locale("status_patient") .. ": " .. status,
            icon = 'heartbeat',
            iconColor = isDead and "#b5300b" or "#5b87b0",
            readOnly = true,
        },

        {
            title = locale("check_injuries"),
            description = locale("check_injuries_desc"),
            icon = 'user-injured',
            onSelect = function()
                local passData = {}
                passData.target = targetServerId
                passData.injuries = data.injuries

                checkInjuries(passData)
            end,
        }
    }

    if isDead then
        options[#options + 1] = {
            title = locale("revive_patient"),
            description = locale("revive_patient_desc"),
            icon = 'medkit',
            iconColor = "#5BC0DE",
            onSelect = function()
                local count = exports.ox_inventory:Search('count', "defibrillator")
                if count < 1 then return utils.showNotification(locale("not_enough_defibrillator")) end

                local itemDurability = utils.getItem("defibrillator")?.metadata?.durability

                if itemDurability then
                    if itemDurability < Config.ConsumeItemPerUse then return utils.showNotification(locale("no_durability")) end
                end

                local playerPed = cache.ped or PlayerPedId()
                local playerHeading = GetEntityHeading(playerPed)
                local playerLocation = GetEntityForwardVector(playerPed)
                local playerCoords = GetEntityCoords(playerPed)

                local dataToSend = {}
                dataToSend.targetServerId = targetServerId
                dataToSend.injury = false
                dataToSend.heading = playerHeading
                dataToSend.location = playerLocation
                dataToSend.coords = playerCoords
                TriggerServerEvent("ars_ambulancejob:healPlayer", dataToSend)
            end,
        }

        options[#options + 1] = {
            title = locale("death_cause") .. ": " .. (WEAPONS[data.killedBy] and WEAPONS[data.killedBy][1] or locale("not_found")),
            readOnly = true,
            icon = 'skull',
            iconColor = "#b5300b",
        }
        else
        -- Add health status for alive players
        local healthPercentage = math.floor((targetHealth / targetMaxHealth) * 100)
        options[#options + 1] = {
            title = locale("patient_health") .. ": " .. healthPercentage .. "%",
            icon = 'heart',
            iconColor = healthPercentage > 75 and "#28a745" or healthPercentage > 50 and "#ffc107" or "#dc3545",
            readOnly = true,
        }

        -- Add healing option for alive players (only if not full health)
        if not isFullHealth then
            options[#options + 1] = {
                title = locale("heal_patient"),
                description = locale("heal_patient_desc"),
                icon = 'medkit',
                iconColor = "#28a745",
                onSelect = function()
                    local count = exports.ox_inventory:Search('count', "bandage")
                    if count < 1 then return utils.showNotification(locale("not_enough_bandage")) end

                    local itemDurability = utils.getItem("bandage")?.metadata?.durability

                    if itemDurability then
                        if itemDurability < Config.ConsumeItemPerUse then return utils.showNotification(locale("no_durability")) end
                    end

                    -- Start healing with animations
                    local playerPed = cache.ped or PlayerPedId()
                    local targetPed = target

                    local dataToSend = {}
                    dataToSend.targetServerId = targetServerId
                    dataToSend.healWithBandage = true
                    TriggerServerEvent("ars_ambulancejob:healPlayer", dataToSend)
                end,
            }
        else
            -- Show that patient is at full health
            options[#options + 1] = {
                title = locale("patient_full_health"),
                description = locale("patient_full_health_desc"),
                icon = 'medkit',
                iconColor = "#6c757d",
                readOnly = true,
            }
        end
    end

    lib.registerContext({
        id = 'check_patient',
        title = locale("check_patient_menu_title"),
        options = options
    })
    lib.showContext('check_patient')
end


function createDistressCall()
    if player.distressCallTime then
        local currentTime = GetGameTimer()
        utils.debug(currentTime - player.distressCallTime, 60000 * Config.WaitTimeForNewCall)
        if currentTime - player.distressCallTime < 60000 * Config.WaitTimeForNewCall then
            return utils.showNotification(
                "Wait before sending another call")
        end
    end

    local input = lib.inputDialog('Arius Ambulance', {
        { type = 'input', label = 'Message', description = 'a message to send to medics online', required = true },
    })
    if not input then return end

    local msg = input[1]

    if not Config.UseInterDistressSystem then
        Config.SendDistressCall(msg)
    else
        local data = {}
        local playerCoords = cache.coords or GetEntityCoords(cache.ped)

        local current, crossing = GetStreetNameAtCoord(playerCoords.x, playerCoords.y, playerCoords.z)

        data.msg = msg
        data.gps = playerCoords
        data.location = GetStreetNameFromHashKey(current)

        TriggerServerEvent("ars_ambulancejob:createDistressCall", data)
    end


    player.distressCallTime = GetGameTimer()
end

exports("createDistressCall", createDistressCall)
RegisterCommand(Config.HelpCommand, createDistressCall)

function openDistressCalls()
    if not hasJob(Config.EmsJobs) then return end

    local playerPed = cache.ped or PlayerPedId()
    local playerCoords = cache.coords or GetEntityCoords(playerPed)

    local distressCalls = lib.callback.await('ars_ambulancejob:getDistressCalls', false)

    local calls = {}

    local dict = lib.requestAnimDict("amb@world_human_tourist_map@male@base")
    local model = lib.requestModel("prop_cs_tablet")

    TaskPlayAnim(playerPed, dict, "base", 2.0, 2.0, -1, 51, 0, false, false, false)

    local tablet = CreateObject(model, playerCoords.x, playerCoords.y, playerCoords.z + 0.2, true, true, true)
    AttachEntityToEntity(tablet, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, -0.03, 0.0, 20.0, -90.0, 0.0, true,
        true, false, true, 1, true)

    for i = 1, #distressCalls do
        local call = distressCalls[i]

        utils.debug(call)

        calls[#calls + 1] = {
            title       = call.name,
            description = call.msg,
            icon        = "fa-truck-medical",
            iconColor   = "#FEBD69",
            arrow       = true,
            onSelect    = function()
                lib.registerContext({
                    id      = 'openCall' .. call.name .. call.msg .. i,
                    title   = call.name,
                    menu    = "openDistressCalls",
                    options = {
                        {
                            title       = call.msg,
                            icon        = "fa-info-circle",
                            iconColor   = "#0077FF",
                            readOnly    = true,
                            description = "message sent from the patient"
                        },
                        {
                            title       = call.location,
                            icon        = "fa-map-marker",
                            iconColor   = "#00CC00",
                            readOnly    = true,
                            description = "Location of the patient"
                        },
                        {
                            title       = "Set Waypoint",
                            icon        = "fa-map-pin",
                            iconColor   = "#FFA500",
                            arrow       = true,
                            description = "Set the waypoint to the patient direction",

                            onSelect    = function()
                                SetNewWaypoint(call.gps.x, call.gps.y)
                                utils.showNotification("Waypoint set")
                                ClearPedTasks(playerPed)
                                DeleteEntity(tablet)
                            end
                        },
                        {
                            title       = "Risolved",
                            icon        = "fa-check",
                            iconColor   = "#32CD32",
                            arrow       = true,
                            description = "Complete the call if you risolved it",
                            onSelect    = function()
                                TriggerServerEvent("ars_ambulancejob:callCompleted", call)
                                utils.showNotification("Call closed")
                                ClearPedTasks(playerPed)
                                DeleteEntity(tablet)
                            end
                        },
                    }
                })
                lib.showContext('openCall' .. call.name .. call.msg .. i)
            end
        }
    end

    lib.registerContext({
        id      = 'openDistressCalls',
        title   = "Calls",
        onExit  = function()
            ClearPedTasks(playerPed)
            DeleteEntity(tablet)
        end,
        options = calls
    })
    lib.showContext('openDistressCalls')
end

exports("openDistressCalls", openDistressCalls)


addGlobalPlayer({
    {
        name = 'check_suspect',
        icon = 'fas fa-magnifying-glass',
        label = locale('check_patient'),
        groups = Config.EmsJobs,
        distance = 3,
        fn = function(data)
            checkPatient(type(data) == "number" and data or data.entity)
        end
    },
    {
        name = 'put_on_stretcher',
        icon = 'fas fa-magnifying-glass',
        label = locale('put_on_stretcher'),
        groups = Config.EmsJobs,
        distance = 3,
        cn = function(entity, distance, coords, name, bone)
            local _coords = GetEntityCoords(entity)
            local closestStretcher = GetClosestObjectOfType(_coords.x, _coords.y, _coords.z, 5.5, `prop_ld_binbag_01`, false)

            return closestStretcher ~= 0
        end,
        fn = function(data)
            putOnStretcher(true, type(data) == "number" and data or data.entity)
        end
    },
})


RegisterNetEvent("ars_ambulancejob:playHealAnim", function(data)
    local playerPed = cache.ped or PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    if data.anim == "healing" then
        -- Medic healing animation with bandages
        utils.showNotification(locale("healing_patient"))

        CreateThread(function()
            lib.progressBar({
                duration = 8000, -- 8 seconds for bandage healing
                label = locale("healing_patient"),
                useWhileDead = false,
                canCancel = false,
                disable = {
                    car = true,
                    move = true,
                },
                anim = {
                    scenario = "CODE_HUMAN_MEDIC_TEND_TO_DEAD"
                }
            })
        end)

        lib.requestAnimDict("amb@medic@standing@tendtodead@base")
        lib.requestAnimDict("amb@medic@standing@tendtodead@idle_a")

        -- Play medic healing animation
        TaskPlayAnim(playerPed, 'amb@medic@standing@tendtodead@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)

        Wait(3000)
        TaskPlayAnim(playerPed, 'amb@medic@standing@tendtodead@idle_a', 'idle_a', 8.0, 8.0, -1, 1, 0, false, false, false)

        Wait(5000)

        ClearPedTasks(playerPed)

        -- Consume bandage and give reward
        utils.useItem("bandage", Config.ConsumeItemPerUse)
        utils.addRemoveItem("add", "money", Config.BandageHealReward)

        utils.showNotification(locale("patient_healed"))

    elseif data.anim == "receiving_heal" then
        -- Patient receiving heal animation
        utils.showNotification("Getting healed by medic")

        lib.requestAnimDict("random@mugging4")
        lib.requestAnimDict("amb@world_human_bum_slumped@male@laying_on_left_side@base")

        -- Patient sits/lies down for healing
        TaskPlayAnim(playerPed, 'random@mugging4', 'agitated_loop_a', 8.0, 8.0, 8000, 1, 0, false, false, false)

        Wait(8000)

        ClearPedTasks(playerPed)

        -- Heal the player - add health
        local currentHealth = GetEntityHealth(playerPed)
        local maxHealth = GetEntityMaxHealth(playerPed)
        local healAmount = 25 -- 25% heal
        local newHealth = math.min(currentHealth + healAmount, Config.HealthArmorPersistence.MaxHealthCap)

        SetEntityHealth(playerPed, newHealth)

        utils.showNotification(locale("treated_by_paramedic"))

    elseif data.anim == "medic" then
        utils.showNotification("Reviving player")

        CreateThread(function()
            lib.progressBar({
                duration = 14900 + (900 * 15) + 1000,
                label = locale("reviving_patient"),
                useWhileDead = false,
                canCancel = false,
                disable = {
                    car = true,
                    move = true,
                },
            })
        end)

        lib.requestAnimDict("mini@cpr@char_a@cpr_def")
        lib.requestAnimDict("mini@cpr@char_a@cpr_str")

        TaskPlayAnim(playerPed, 'mini@cpr@char_a@cpr_def', 'cpr_intro', 8.0, 8.0, -1, 0, 0, false, false, false)

        Wait(14900)

        for i = 1, 15 do
            Wait(900)
            TaskPlayAnim(playerPed, 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest', 8.0, 8.0, -1, 0, 0, false, false, false)
        end

        Wait(1000)

        TaskPlayAnim(playerPed, Config.DeathAnimations["revive"].dict, Config.DeathAnimations["revive"].clip, 10.0, -10.0,
            -1, 0, 0, 0, 0, 0)

        utils.useItem("defibrillator", Config.ConsumeItemPerUse)
        utils.addRemoveItem("add", "money", Config.ReviveReward)
    elseif data.anim == "dead" then
        utils.showNotification("Getting revived")

        player.gettingRevived = true

        lib.requestAnimDict('mini@cpr@char_b@cpr_str')
        lib.requestAnimDict('mini@cpr@char_b@cpr_def')

        SetEntityVisible(playerPed, false)
        Wait(250)
        SetEntityVisible(playerPed, true)

        SetEntityInvincible(playerPed, false)
        TriggerEvent('playerSpawned', coords.x, coords.y, coords.z)
        SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true)

        local x, y, z = table.unpack(data.coords + data.location)

        SetEntityCoords(playerPed, x, y, z - 0.50)
        SetEntityHeading(playerPed, data.heading - 270.0)

        TaskPlayAnim(playerPed, 'mini@cpr@char_b@cpr_def', 'cpr_intro', 8.0, 8.0, -1, 0, 0, false, false, false)

        Wait(14900)

        TaskPlayAnim(playerPed, 'mini@cpr@char_b@cpr_str', 'cpr_pumpchest', 8.0, 8.0, -1, 0, 0, false, false, false)

        for i = 1, 15 do
            Wait(900)
            TaskPlayAnim(playerPed, 'mini@cpr@char_b@cpr_str', 'cpr_pumpchest', 8.0, 8.0, -1, 0, 0, false, false, false)
        end

        Wait(800)

        player.gettingRevived = false
        stopPlayerDeath()
    end
end)


RegisterNetEvent("ars_ambulancejob:createDistressCall", function(name)
    if not hasJob(Config.EmsJobs) then return end

    lib.notify({
        title = "New Distress Call",
        description = ("%s sent a distress call"):format(name),
        position = 'bottom-right',
        duration = 8000,
        style = {
            backgroundColor = '#1C1C1C',
            color = '#C1C2C5',
            borderRadius = '8px',
            ['.description'] = {
                fontSize = '16px',
                color = '#B0B3B8'
            },
        },
        icon = 'fas fa-truck-medical',
        iconColor = '#FEBD69'
    })
    PlaySound(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset")
end)

RegisterNetEvent("ars_ambulancejob:createDistressCallBlip", function(data)
    if not hasJob(Config.EmsJobs) or not Config.DistressBlip.Enable then return end

    -- Create emergency blip on the map
    local blip = AddBlipForCoord(data.gps.x, data.gps.y, data.gps.z)
    SetBlipSprite(blip, Config.DistressBlip.Sprite)
    SetBlipColour(blip, Config.DistressBlip.Color)
    SetBlipScale(blip, Config.DistressBlip.Scale)
    SetBlipAsShortRange(blip, false) -- Always visible
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(("Emergency: %s"):format(data.name))
    EndTextCommandSetBlipName(blip)

    -- Flash the blip to get attention if enabled
    if Config.DistressBlip.Flash then
        SetBlipFlashes(blip, true)
    end

    -- Auto-remove blip after configured time if set
    if Config.DistressBlip.AutoRemoveTime > 0 then
        CreateThread(function()
            Wait(Config.DistressBlip.AutoRemoveTime * 60000) -- Convert minutes to milliseconds
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
                if distressBlips then
                    local blipKey = data.playerId and tostring(data.playerId) or (data.name .. "_" .. data.gps.x .. "_" .. data.gps.y)
                    distressBlips[blipKey] = nil
                end
            end
        end)
    end

    -- Store blip reference for later removal
    if not distressBlips then distressBlips = {} end
    local blipKey = data.playerId and tostring(data.playerId) or (data.name .. "_" .. data.gps.x .. "_" .. data.gps.y)
    distressBlips[blipKey] = {
        blip = blip,
        data = data
    }

    -- Show notification that blip was created
    utils.showNotification(("Emergency marker placed for %s"):format(data.name), "success")
end)

RegisterNetEvent("ars_ambulancejob:removeDistressBlip", function(data)
    if not hasJob(Config.EmsJobs) then return end

    local blipKey = data.playerId and tostring(data.playerId) or (data.name .. "_" .. data.gps.x .. "_" .. data.gps.y)

    if distressBlips and distressBlips[blipKey] then
        if DoesBlipExist(distressBlips[blipKey].blip) then
            RemoveBlip(distressBlips[blipKey].blip)
        end
        distressBlips[blipKey] = nil

        -- Show notification that emergency was resolved
        utils.showNotification(("Emergency resolved for %s"):format(data.name), "success")
    end
end)

-- © 𝐴𝑟𝑖𝑢𝑠 𝐷𝑒𝑣𝑒𝑙𝑜𝑝𝑚𝑒𝑛𝑡
