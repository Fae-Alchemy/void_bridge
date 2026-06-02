local StandalonePlayers = {}

local function GetLicense(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.sub(id, 1, 8) == "license:" then
            return id
        end
    end
    return "license:unknown"
end

-- Helper to construct standalone player object in memory
local function CreateStandalonePlayer(source)
    local license = GetLicense(source)
    local pData = {
        source = source,
        citizenid = "SA-" .. string.sub(license, 9, 14),
        identifier = license,
        name = GetPlayerName(source) or "Standalone Player",
        job = {
            name = "unemployed",
            label = "Unemployed",
            grade = 0,
            gradeLabel = "Freelancer"
        },
        money = {
            cash = 5000,
            bank = 10000
        }
    }

    local self = {}
    self.PlayerData = pData

    function self.GetData()
        return self.PlayerData
    end

    function self.GetMoney(account)
        account = account == "cash" and "cash" or "bank"
        return self.PlayerData.money[account] or 0
    end

    function self.AddMoney(account, amount, reason)
        account = account == "cash" and "cash" or "bank"
        amount = tonumber(amount) or 0
        if amount <= 0 then return false end
        self.PlayerData.money[account] = self.PlayerData.money[account] + amount
        if Config.Debug then
            print(("[void_bridge] Standalone AddMoney: %s added $%d (%s)"):format(self.PlayerData.name, amount, reason or "None"))
        end
        TriggerClientEvent('chat:addMessage', source, {
            args = { "[Banking]", ("Received $%d on your %s account"):format(amount, account) }
        })
        TriggerClientEvent('void_bridge:client:syncPlayerData', source, self.PlayerData)
        return true
    end

    function self.RemoveMoney(account, amount, reason)
        account = account == "cash" and "cash" or "bank"
        amount = tonumber(amount) or 0
        if amount <= 0 then return false end
        if self.PlayerData.money[account] < amount then return false end
        self.PlayerData.money[account] = self.PlayerData.money[account] - amount
        if Config.Debug then
            print(("[void_bridge] Standalone RemoveMoney: %s spent $%d (%s)"):format(self.PlayerData.name, amount, reason or "None"))
        end
        TriggerClientEvent('chat:addMessage', source, {
            args = { "[Banking]", ("Charged $%d from your %s account"):format(amount, account) }
        })
        TriggerClientEvent('void_bridge:client:syncPlayerData', source, self.PlayerData)
        return true
    end

    function self.SetJob(jobName, grade)
        self.PlayerData.job.name = jobName or "unemployed"
        self.PlayerData.job.grade = tonumber(grade) or 0
        self.PlayerData.job.label = string.upper(string.sub(self.PlayerData.job.name, 1, 1)) .. string.sub(self.PlayerData.job.name, 2)
        self.PlayerData.job.gradeLabel = "Grade " .. self.PlayerData.job.grade
        TriggerClientEvent('void_bridge:client:syncPlayerData', source, self.PlayerData)
        return true
    end

    self.PlayerData.metadata = self.PlayerData.metadata or {}
    function self.GetMetaData(key)
        return self.PlayerData.metadata[key]
    end

    function self.SetMetaData(key, val)
        self.PlayerData.metadata[key] = val
        TriggerClientEvent('void_bridge:client:syncPlayerData', source, self.PlayerData)
    end

    StandalonePlayers[source] = self
    return self
end

-- Clear standalone player data when they disconnect
AddEventHandler('playerDropped', function()
    local source = source
    if StandalonePlayers[source] then
        StandalonePlayers[source] = nil
    end
end)

-------------------------------------------------------------------------------
-- UNIFIED PLAYER GETTER
-------------------------------------------------------------------------------

function Bridge.GetPlayer(source)
    local source = tonumber(source)
    if not source or source <= 0 then return nil end

    local fw = Bridge.GetFramework()

    if fw == "qbcore" then
        local QBCore = exports['qb-core']:GetCoreObject()
        local qbPlayer = QBCore.Functions.GetPlayer(source)
        if not qbPlayer then return nil end

        local self = {}
        
        function self.GetData()
            return {
                source = qbPlayer.PlayerData.source,
                citizenid = qbPlayer.PlayerData.citizenid,
                identifier = qbPlayer.PlayerData.license,
                name = qbPlayer.PlayerData.charinfo.firstname .. " " .. qbPlayer.PlayerData.charinfo.lastname,
                job = {
                    name = qbPlayer.PlayerData.job.name,
                    label = qbPlayer.PlayerData.job.label,
                    grade = qbPlayer.PlayerData.job.grade.level,
                    gradeLabel = qbPlayer.PlayerData.job.grade.name
                },
                gang = qbPlayer.PlayerData.gang and {
                    name = qbPlayer.PlayerData.gang.name,
                    label = qbPlayer.PlayerData.gang.label,
                    grade = qbPlayer.PlayerData.gang.grade.level,
                    gradeLabel = qbPlayer.PlayerData.gang.grade.name,
                    isboss = qbPlayer.PlayerData.gang.isboss
                } or nil
            }
        end

        function self.GetMoney(account)
            -- QBCore uses "cash", "bank", "crypto"
            account = account == "cash" and "cash" or "bank"
            return qbPlayer.Functions.GetMoney(account) or 0
        end

        function self.AddMoney(account, amount, reason)
            account = account == "cash" and "cash" or "bank"
            return qbPlayer.Functions.AddMoney(account, amount, reason)
        end

        function self.RemoveMoney(account, amount, reason)
            account = account == "cash" and "cash" or "bank"
            return qbPlayer.Functions.RemoveMoney(account, amount, reason)
        end

        function self.SetJob(jobName, grade)
            return qbPlayer.Functions.SetJob(jobName, grade)
        end

        function self.GetMetaData(key)
            return qbPlayer.Functions.GetMetaData(key)
        end

        function self.SetMetaData(key, val)
            qbPlayer.Functions.SetMetaData(key, val)
        end

        return self

    elseif fw == "esx" then
        local ESX = nil
        pcall(function() ESX = exports['es_extended']:getSharedObject() end)
        if not ESX then TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end) end
        if not ESX then return nil end

        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return nil end

        local self = {}

        function self.GetData()
            local jobLabel = xPlayer.job and xPlayer.job.label or "Unemployed"
            local gradeLabel = xPlayer.job and xPlayer.job.grade_label or "Grade"
            return {
                source = xPlayer.source,
                citizenid = xPlayer.identifier,
                identifier = xPlayer.identifier,
                name = xPlayer.getName() or "ESX Player",
                job = {
                    name = xPlayer.job and xPlayer.job.name or "unemployed",
                    label = jobLabel,
                    grade = xPlayer.job and xPlayer.job.grade or 0,
                    gradeLabel = gradeLabel
                }
            }
        end

        function self.GetMoney(account)
            if account == "cash" or account == "money" then
                return xPlayer.getMoney() or 0
            elseif account == "bank" then
                local bankAcc = xPlayer.getAccount('bank')
                return bankAcc and bankAcc.money or 0
            end
            return 0
        end

        function self.AddMoney(account, amount, reason)
            if account == "cash" or account == "money" then
                xPlayer.addMoney(amount)
                return true
            elseif account == "bank" then
                xPlayer.addAccountMoney('bank', amount)
                return true
            end
            return false
        end

        function self.RemoveMoney(account, amount, reason)
            if account == "cash" or account == "money" then
                if xPlayer.getMoney() >= amount then
                    xPlayer.removeMoney(amount)
                    return true
                end
            elseif account == "bank" then
                local bankAcc = xPlayer.getAccount('bank')
                if bankAcc and bankAcc.money >= amount then
                    xPlayer.removeAccountMoney('bank', amount)
                    return true
                end
            end
            return false
        end

        function self.SetJob(jobName, grade)
            pcall(function() xPlayer.setJob(jobName, grade) end)
            return true
        end

        function self.GetMetaData(key)
            return xPlayer.get(key)
        end

        function self.SetMetaData(key, val)
            xPlayer.set(key, val)
        end

        return self

    else
        -- Standalone mode
        if StandalonePlayers[source] then
            return StandalonePlayers[source]
        else
            return CreateStandalonePlayer(source)
        end
    end
end

function Bridge.GetPlayerByCitizenId(citizenid)
    local fw = Bridge.GetFramework()

    if fw == "qbcore" then
        local QBCore = exports['qb-core']:GetCoreObject()
        local qbPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
        if qbPlayer then
            return Bridge.GetPlayer(qbPlayer.PlayerData.source)
        end
    elseif fw == "esx" then
        local ESX = nil
        pcall(function() ESX = exports['es_extended']:getSharedObject() end)
        if not ESX then TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end) end
        if ESX then
            local xPlayer = ESX.GetPlayerFromIdentifier(citizenid)
            if xPlayer then
                return Bridge.GetPlayer(xPlayer.source)
            end
        end
    else
        -- Standalone mode check in-memory cache
        for src, player in pairs(StandalonePlayers) do
            if player.GetData().citizenid == citizenid then
                return player
            end
        end
    end
    return nil
end
