if Config.OldESX then
    ESX = nil
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
end

function Sanitize(str)
    local replacements = {
        ['&' ] = '&amp;',
        ['<' ] = '&lt;',
        ['>' ] = '&gt;',
        ['\n'] = '<br/>'
    }
    return str
        :gsub('[&<>\n]', replacements)
        :gsub(' +', function(s)
            return ' '..('&nbsp;'):rep(#s-1)
        end)
end

function RefreshScoreboard()
    local xPlayers = ESX.GetExtendedPlayers()
    TriggerClientEvent("scoreboard:refrehScoreboard", -1)
    getIllegalActivitesData()
    for _, xPlayer in pairs(xPlayers) do
        local playerID = xPlayer.source
        local playerName = Sanitize(xPlayer.getName())
        local playerJob = xPlayer.job.label
        local playerGroup = xPlayer.group
        TriggerClientEvent("scoreboard:addUserToScoreboard", -1, playerID, playerName, playerJob, playerGroup)
        TriggerClientEvent("scoreboard:sendConfigToNUI", -1)
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        Citizen.Wait(1000)
        RefreshScoreboard()
    end
    TriggerClientEvent("scoreboard:sendConfigToNUI", -1)
end)

RegisterCommand("refreshscoreboard", function()
    RefreshScoreboard()
end, true)

CreateThread(function()
    while true do
        local onlinePlayers = getOnlinePlayers()
        local onlineStaff = getOnlineStaff()
        local onlinePolice = #ESX.GetExtendedPlayers(Config.policeCounterType,Config.policeCounterIdentifier)
        local onlineEMS = #ESX.GetExtendedPlayers(Config.emsCounterType,Config.emsCounterIdentifier)
        local onlineTaxi = #ESX.GetExtendedPlayers(Config.taxiCounterType,Config.taxiCounterIdentifier)
        local onlineMechanics = #ESX.GetExtendedPlayers(Config.mechanicCounterType,Config.mechanicCounterIdentifier)
        local onlinepemerintah = #ESX.GetExtendedPlayers(Config.pemerintahCounterType,Config.pemerintahCounterIdentifier)
        local onlinepedagang = #ESX.GetExtendedPlayers(Config.pedagangCounterType,Config.pedagangCounterIdentifier)
        local illegalActivites = getIllegalActivitesData()
        TriggerClientEvent("scoreboard:setValues", -1, onlinePlayers, onlineStaff, onlinePolice, onlineEMS, onlineTaxi, onlineMechanics, onlinepemerintah, onlinepedagang, illegalActivites)
        Wait(Config.updateScoreboardInterval)
    end
end)

RegisterNetEvent('scoreboard:requestUserData',
    function(target)
        local target = target or source
        TriggerClientEvent("scoreboard:retrieveUserData", tonumber(target), source, tonumber(target))
    end)

RegisterNetEvent('scoreboard:sendRequestedData', 
    function(to, data)
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer ~= nil then
            data.roleplayName = xPlayer.getName()
            TriggerClientEvent("scoreboard:receiveRequestedData", to, source, data)
        end
    end)

AddEventHandler(
    'esx:playerLoaded',  
    function()
        Citizen.Wait(500)
        RefreshScoreboard()
    end
)

AddEventHandler(
    'playerDropped', 
    function()
        Citizen.Wait(500)
        RefreshScoreboard()
    end
)
  

function getOnlinePlayers()
    local xPlayers = ESX.GetExtendedPlayers()
    return #xPlayers
end

function getOnlineStaff()
    local xPlayersTotal = ESX.GetExtendedPlayers()
    local xPlayersUsers = ESX.GetExtendedPlayers('group','user')
    return (#xPlayersTotal - #xPlayersUsers)
end

function getIllegalActivitesData()
    local data = Config.illegalActivites
    for i = 1,#data do
        data[i]["onlinePlayers"] = getOnlinePlayers()
        data[i]["onlineGroup"] = #ESX.GetExtendedPlayers(data[i]["groupType"],data[i]["groupName"])
        TriggerClientEvent("scoreboard:sendIllegalActivity",-1,data[i])
    end
    return data
end

ESX.RegisterServerCallback('scoreboard:Close', function(src, cb)
   SetPlayerCullingRadius(src, 0.0)
   cb()
end)

ESX.RegisterServerCallback('scoreboard:Open', function(src, cb)
    SetPlayerCullingRadius(src, 50000.0)
    cb()
 end)
 