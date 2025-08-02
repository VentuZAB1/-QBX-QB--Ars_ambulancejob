-- Global variables for death timer and UI state
startTime = 0
local uiThreadRunning = false

-- Function to create direct distress call without menu
local function createDirectDistressCall()
    if Config.DebugDistressCalls then
        print("^3[DISTRESS]^7 createDirectDistressCall called")
    end

    if player.distressCallTime then
        local currentTime = GetGameTimer()
        if currentTime - player.distressCallTime < 60000 * Config.WaitTimeForNewCall then
            utils.showNotification("Wait before sending another call")
            if Config.DebugDistressCalls then
                print("^3[DISTRESS]^7 Call blocked - too soon since last call")
            end
            return
        end
    end

    -- Auto message for death distress call
    local msg = Config.DeathUI.AutoDistressMessage
    if Config.DebugDistressCalls then
        print("^3[DISTRESS]^7 Sending emergency message:", msg)
    end

    if not Config.UseInterDistressSystem then
        if Config.DebugDistressCalls then
            print("^3[DISTRESS]^7 Using external distress system")
        end
        Config.SendDistressCall(msg)
    else
        if Config.DebugDistressCalls then
            print("^3[DISTRESS]^7 Using internal distress system")
        end
        local data = {}
        local playerCoords = cache.coords or GetEntityCoords(cache.ped)

        local current, crossing = GetStreetNameAtCoord(playerCoords.x, playerCoords.y, playerCoords.z)

        data.msg = msg
        data.gps = playerCoords
        data.location = GetStreetNameFromHashKey(current)

        if Config.DebugDistressCalls then
            print("^3[DISTRESS]^7 Distress data:", json.encode(data))
        end
        TriggerServerEvent("ars_ambulancejob:createDistressCall", data)
    end

    player.distressCallTime = GetGameTimer()
    utils.showNotification("Emergency call sent to EMS!")
    if Config.DebugDistressCalls then
        print("^3[DISTRESS]^7 Distress call completed")
    end
end

function openDeathUI()
    if Config.Debug then
        print("^2[DEBUG]^7 Opening death UI")
    end

    -- Send NUI message to show death screen
    SendNUIMessage({
        type = 'showDeathScreen',
        show = true,
        config = {
            circleScale = Config.DeathUI.CircleScale,
            medicCallText = Config.DeathUI.MedicCallText,
            showMedicCallButton = Config.DeathUI.ShowMedicCallButton,
            position = Config.DeathUI.Position
        }
    })
    SetNuiFocus(false, false) -- No cursor needed, keyboard only

    -- Add a lighter overlay to reduce the darkness of DeathFailOut effect (if enabled)
    if Config.DeathUI.LighteningOverlay > 0 then
        CreateThread(function()
            while player.isDead do
                -- Draw a semi-transparent white overlay to lighten the death effect
                DrawRect(0.5, 0.5, 1.0, 1.0, 255, 255, 255, Config.DeathUI.LighteningOverlay)
                Wait(0)
            end
        end)
    end
end

function closeDeathUI()
    if Config.Debug then
        print("^2[DEBUG]^7 Closing death UI")
    end

    -- Send NUI message to hide death screen
    SendNUIMessage({
        type = 'showDeathScreen',
        show = false
    })

    -- Reset UI state variables
    startTime = 0
    uiThreadRunning = false
end

local function updateTimer(minutes, seconds, progress)
    -- Send timer update to NUI
    SendNUIMessage({
        type = 'updateTimer',
        minutes = minutes,
        seconds = seconds,
        progress = progress
    })
end

function DrawDeathUI()
    if Config.Debug then
        print("^2[DEBUG]^7 Starting DrawDeathUI function")
    end

    -- Prevent multiple UI threads from running
    if uiThreadRunning then
        if Config.Debug then
            print("^2[DEBUG]^7 UI thread already running, skipping new UI initialization")
        end
        return
    end

    -- Reset the start time when UI is initialized
    startTime = GetGameTimer()
    local totalTime = Config.DeathUI.Timer * 60 * 1000 -- Timer from config in milliseconds
    local respawnAvailable = false
    local isHoldingRespawn = false
    local respawnHoldStart = 0
    local respawnHoldTime = Config.DeathUI.RespawnHoldTime * 1000 -- Convert to milliseconds

    -- Hide respawn option at start of new death
    SendNUIMessage({
        type = 'showRespawnOption',
        show = false
    })

    -- Show the death UI
    openDeathUI()

    uiThreadRunning = true
    CreateThread(function()
        while player.isDead and not player.respawning do
            local currentTime = GetGameTimer()
            local elapsedTime = currentTime - startTime
            local remainingTime = totalTime - elapsedTime

            if remainingTime <= 0 then
                remainingTime = 0

                -- Show respawn option when timer runs out
                if not respawnAvailable then
                    respawnAvailable = true
                    SendNUIMessage({
                        type = 'showRespawnOption',
                        show = true,
                        respawnText = Config.DeathUI.RespawnText
                    })
                end
            end

            local minutes = math.floor(remainingTime / 60000)
            local seconds = math.floor((remainingTime % 60000) / 1000)

            -- Calculate progress (1.0 = full time, 0.0 = no time)
            local progress = remainingTime / totalTime

            -- Update the NUI with current timer and progress
            updateTimer(minutes, seconds, progress)

            -- Handle G key press for calling medics (if enabled in config)
            if Config.DeathUI.ShowMedicCallButton and IsControlJustPressed(0, 47) then -- G key
                if Config.DebugDistressCalls then
                    print("G key pressed - calling medics")
                end
                createDirectDistressCall()
            end

            -- Handle E key hold for respawn (only when available)
            if respawnAvailable then
                if IsControlPressed(0, 38) then -- E key being held
                    if not isHoldingRespawn then
                        isHoldingRespawn = true
                        respawnHoldStart = currentTime
                    end

                    local holdElapsed = currentTime - respawnHoldStart
                    local holdProgress = math.min(holdElapsed / respawnHoldTime, 1.0)
                    local timeLeft = math.max((respawnHoldTime - holdElapsed) / 1000, 0)

                    -- Update progress bar
                    SendNUIMessage({
                        type = 'updateRespawnProgress',
                        progress = holdProgress,
                        timeLeft = timeLeft
                    })

                    -- Check if hold is complete
                    if holdElapsed >= respawnHoldTime then
                        if Config.DebugDistressCalls then
                            print("Respawn hold complete - triggering respawn")
                        end
                        -- Hide UI immediately when respawn starts
                        closeDeathUI()
                        startTime = 0
                        TriggerEvent('ars_ambulancejob:requestRespawn')
                        break
                    end
                else
                    -- E key released, reset hold progress
                    if isHoldingRespawn then
                        isHoldingRespawn = false
                        SendNUIMessage({
                            type = 'updateRespawnProgress',
                            progress = 0,
                            timeLeft = Config.DeathUI.RespawnHoldTime
                        })
                    end
                end
            end

            Wait(0) -- Check every frame for responsive key input
        end

        -- Hide UI and reset timer when player is no longer dead
        closeDeathUI()
        startTime = 0
        uiThreadRunning = false

        if Config.Debug then
            print("^2[DEBUG]^7 Death UI thread ended")
        end
    end)
end

-- Note: UI initialization is now handled directly by death system calls
-- No automatic thread needed to prevent conflicts

-- Handle NUI callback for calling medics
RegisterNUICallback('callMedics', function(data, cb)
    if Config.DebugDistressCalls then
        print("NUI Callback received: callMedics")
    end
    -- Use the direct distress call function instead of the one that requires input
    createDirectDistressCall()
    cb('ok')
end)

-- Export the function so it can be called from other files
exports('DrawDeathUI', DrawDeathUI)
