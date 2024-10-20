local isScoreboardOpen = false
local requestedData

CreateThread(function()
    if Config.OldESX then 
        while ESX == nil do
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            Wait(0)
        end

        while ESX.GetPlayerData().job == nil do
            Wait(10)
        end

        ESX.PlayerData = ESX.GetPlayerData()
    end
end)

local PlayerPedPreview
function createPedScreen(playerID)
    CreateThread(function()
        ActivateFrontendMenu(GetHashKey("FE_MENU_VERSION_JOINING_SCREEN"), true, -1)
        Wait(100)
        SetMouseCursorVisibleInMenus(false)
        PlayerPedPreview = ClonePed(playerID, GetEntityHeading(playerID), true, false)
        local x,y,z = table.unpack(GetEntityCoords(PlayerPedPreview))
        SetEntityCoords(PlayerPedPreview, x,y,z-10)
        FreezeEntityPosition(PlayerPedPreview, true)
        SetEntityVisible(PlayerPedPreview, false, false)
        NetworkSetEntityInvisibleToNetwork(PlayerPedPreview, false)
        Wait(200)
        SetPedAsNoLongerNeeded(PlayerPedPreview)
        GivePedToPauseMenu(PlayerPedPreview, 2)
        SetPauseMenuPedLighting(true)
        SetPauseMenuPedSleepState(true)
    end)
end

RegisterCommand('togglescoreboard', function()
    if not isScoreboardOpen then
        isScoreboardOpen = true
        ESX.TriggerServerCallback("scoreboard:Open", function()
            TriggerServerEvent('scoreboard:requestUserData')
            if Config.showPlayerPed then
                SetFrontendActive(true)
                createPedScreen(ESX.PlayerData.ped or PlayerPedId())
            end
            SendNUIMessage({
                action = "show",
                keyBindValue = tostring(GetControlInstructionalButton(0, 0x3635f532 | 0x80000000, 1)),
            })
            SetNuiFocus(true,true)
            if Config.screenBlur then
                TriggerScreenblurFadeIn(Config.screenBlurAnimationDuration)
            end
        end)
    else
        ESX.TriggerServerCallback("scoreboard:Close", function()
            if Config.showPlayerPed then
                DeleteEntity(PlayerPedPreview)
                SetFrontendActive(false)
            end
            SendNUIMessage({
                action = "hide",
                keyBindValue = tostring(GetControlInstructionalButton(0, 0x3635f532 | 0x80000000, 1)),
            })
            SetNuiFocus(false,false)
            isScoreboardOpen = false
            if Config.screenBlur then
                TriggerScreenblurFadeOut(Config.screenBlurAnimationDuration)
            end
        end)
    end
end, false)

RegisterKeyMapping('togglescoreboard', 'Show/Hide Scoreboard', 'keyboard', 'F5')

RegisterNUICallback('closeScoreboard', function()
    ExecuteCommand('togglescoreboard')
end)

RegisterNetEvent("scoreboard:addUserToScoreboard")
AddEventHandler(
    "scoreboard:addUserToScoreboard",
    function(playerID, playerName, playerJob, playerGroup)
        SendNUIMessage(
            {
                action="addUserToScoreboard",
                playerID = playerID,
                playerName = playerName,
                playerJob = playerJob,
                playerGroup = playerGroup,
            }
        )
    end
)

RegisterNetEvent("scoreboard:sendConfigToNUI")
AddEventHandler("scoreboard:sendConfigToNUI",
    function()
        SendNUIMessage({
            action = "getConfig",
            config = json.encode(Config),
        })
    end
)

RegisterNetEvent("scoreboard:sendIllegalActivity")
AddEventHandler("scoreboard:sendIllegalActivity",
    function(data)
        SendNUIMessage({
            action = "addActivity",
            activity = data,
        })
    end
)

RegisterNetEvent("scoreboard:setValues")
AddEventHandler(
    "scoreboard:setValues",
    function(onlinePlayers, onlineStaff, onlinePolice, onlineEMS, onlineTaxi, onlineMechanics, onlinepemerintah, onlinepedagang)
        SendNUIMessage(
            {
                action="updateScoreboard",
                onlinePlayers = onlinePlayers,
                onlineStaff = onlineStaff,
                onlinePolice = onlinePolice,
                onlineEMS = onlineEMS,
                onlineTaxi = onlineTaxi,
                onlineMechanics = onlineMechanics,
                onlinepemerintah = onlinepemerintah,
                onlinepedagang = onlinepedagang,
            }
        )
    end
)

RegisterNetEvent("scoreboard:refrehScoreboard")
AddEventHandler(
    "scoreboard:refrehScoreboard",
    function()
        SendNUIMessage(
            {
                action="refreshScoreboard",
            }
        )
    end
)

RegisterNUICallback('showPlayerPed', function(data)
    TriggerServerEvent('scoreboard:requestUserData', tonumber(data.playerID))
    if Config.showPlayerPed then
        local playerID = data.playerID
        DeleteEntity(PlayerPedPreview)
        local playerTargetID = GetPlayerPed(GetPlayerFromServerId(playerID))
        PlayerPedPreview = ClonePed(playerTargetID, GetEntityHeading(playerTargetID), true, false)
        local x,y,z = table.unpack(GetEntityCoords(PlayerPedPreview))
        SetEntityCoords(PlayerPedPreview, x,y,z-10)
        FreezeEntityPosition(PlayerPedPreview, true)
        SetEntityVisible(PlayerPedPreview, false, false)
        NetworkSetEntityInvisibleToNetwork(PlayerPedPreview, false)
        SetPedAsNoLongerNeeded(PlayerPedPreview)
        GivePedToPauseMenu(PlayerPedPreview, 2)
        SetPauseMenuPedLighting(true)
        SetPauseMenuPedSleepState(true)
    end
end)

RegisterNetEvent("scoreboard:receiveRequestedData")
AddEventHandler(
    "scoreboard:receiveRequestedData",
    function(from, data)
        requestedData = data
        local tooFar = false
        SendNUIMessage(
        {
            action="playerInfoUpdate",
            playerName = requestedData.playerName,
            playerID = requestedData.playerID,
            timePlayed = requestedData.timePlayed,
            roleplayName = requestedData.roleplayName,
            job = ESX.PlayerData.job.label..' - '..ESX.PlayerData.job.grade_label,
            tooFar = tooFar,
        })
    end
)

RegisterNetEvent("scoreboard:retrieveUserData")
AddEventHandler(
    "scoreboard:retrieveUserData",
    function(from, to)
        local data = {}
        data.playerName = GetPlayerName(PlayerId())
        data.playerID = to
        data.playerCoords = GetEntityCoords(ESX.PlayerData.ped or PlayerPedId())
        local retVal, timePlayed = StatGetInt('mp0_total_playing_time')
        data.timePlayed = timePlayed
        TriggerServerEvent('scoreboard:sendRequestedData', from, data)
    end
)
