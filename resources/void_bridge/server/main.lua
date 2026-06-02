Bridge = {}
Bridge.Inventory = {}
Bridge.Banking = {}
Bridge.NotifySystem = {}
Bridge.Garage = {}

local Framework = "standalone"
local QBCore = nil
local ESX = nil

local InventorySystem = "standalone"
local NotifySystemName = "standalone"
local BankingSystemName = "standalone"
local GarageSystemName = "standalone"

-- Dynamic Framework and Dependency Auto-Detection
local function DetectEnvironment()
    -- 1. Detect Core Framework
    if Config.Framework ~= "auto" then
        Framework = Config.Framework
    else
        if GetResourceState('qb-core') == 'started' then
            Framework = "qbcore"
        elseif GetResourceState('es_extended') == 'started' then
            Framework = "esx"
        else
            Framework = "standalone"
        end
    end

    if Framework == "qbcore" then
        QBCore = exports['qb-core']:GetCoreObject()
    elseif Framework == "esx" then
        pcall(function() ESX = exports['es_extended']:getSharedObject() end)
        if not ESX then
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        end
    end

    -- 2. Detect Inventory System
    if Config.Inventory ~= "auto" then
        InventorySystem = Config.Inventory
    else
        if GetResourceState('ox_inventory') == 'started' then
            InventorySystem = "ox_inventory"
        elseif GetResourceState('qb-inventory') == 'started' or GetResourceState('qb-core') == 'started' then
            InventorySystem = "qb-inventory"
        elseif GetResourceState('qs-inventory') == 'started' then
            InventorySystem = "qs-inventory"
        else
            InventorySystem = "standalone"
        end
    end

    -- 3. Detect Notification System
    if Config.Notify ~= "auto" then
        NotifySystemName = Config.Notify
    else
        if GetResourceState('ox_lib') == 'started' then
            NotifySystemName = "ox_lib"
        elseif GetResourceState('okokNotify') == 'started' then
            NotifySystemName = "okokNotify"
        elseif Framework == "qbcore" then
            NotifySystemName = "qbcore"
        elseif Framework == "esx" then
            NotifySystemName = "esx"
        else
            NotifySystemName = "standalone"
        end
    end

    -- 4. Detect Banking System
    if Config.Banking ~= "auto" then
        BankingSystemName = Config.Banking
    else
        if GetResourceState('pefcl') == 'started' then
            BankingSystemName = "pefcl"
        elseif GetResourceState('okBanking') == 'started' then
            BankingSystemName = "okBanking"
        elseif Framework == "qbcore" then
            BankingSystemName = "qbcore"
        elseif Framework == "esx" then
            BankingSystemName = "esx"
        else
            BankingSystemName = "standalone"
        end
    end

    -- 5. Detect Garage System
    if Config.Garage ~= "auto" then
        GarageSystemName = Config.Garage
    else
        if GetResourceState('jg-advancedgarage') == 'started' then
            GarageSystemName = "jg-advancedgarage"
        elseif GetResourceState('qs-advancedgarages') == 'started' then
            GarageSystemName = "qs-advancedgarages"
        elseif GetResourceState('qb-garage') == 'started' then
            GarageSystemName = "qb-garage"
        elseif GetResourceState('esx_garage') == 'started' then
            GarageSystemName = "esx_garage"
        else
            GarageSystemName = "standalone"
        end
    end

    if Config.Debug then
        print("^4================= VOID_BRIDGE ENVIRONMENT =================^7")
        print(("^4[void_bridge]^7 Framework: ^2%s^7"):format(Framework))
        print(("^4[void_bridge]^7 Inventory: ^2%s^7"):format(InventorySystem))
        print(("^4[void_bridge]^7 Notification: ^2%s^7"):format(NotifySystemName))
        print(("^4[void_bridge]^7 Banking: ^2%s^7"):format(BankingSystemName))
        print(("^4[void_bridge]^7 Garage: ^2%s^7"):format(GarageSystemName))
        print("^4===========================================================^7")
    end
end

-- Initialize detection on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    DetectEnvironment()
end)

-- Also run it immediately in case of script restarts
CreateThread(function()
    Wait(100)
    DetectEnvironment()
end)

-------------------------------------------------------------------------------
-- CORE BRIDGE API EXPORTS
-------------------------------------------------------------------------------

-- Retrieve Framework Type
function Bridge.GetFramework()
    return Framework
end

-- Get list of online player IDs
function Bridge.GetPlayers()
    if Framework == "qbcore" then
        return QBCore.Functions.GetPlayers()
    elseif Framework == "esx" then
        return ESX.GetPlayers()
    else
        return GetPlayers()
    end
end

-- Notification Wrapper
function Bridge.Notify(source, message, type, duration)
    type = type or "info"
    duration = duration or Config.DefaultNotificationDuration

    if NotifySystemName == "ox_lib" then
        TriggerClientEvent('ox_lib:notify', source, {
            description = message,
            type = type,
            duration = duration
        })
    elseif NotifySystemName == "okokNotify" then
        TriggerClientEvent('okokNotify:Alert', source, "System", message, duration, type)
    elseif NotifySystemName == "qbcore" and Framework == "qbcore" then
        TriggerClientEvent('QBCore:Notify', source, message, type, duration)
    elseif NotifySystemName == "esx" and Framework == "esx" then
        TriggerClientEvent('esx:showNotification', source, message, type, duration)
    else
        -- Fallback: standard chat message if standalone
        TriggerClientEvent('chat:addMessage', source, {
            args = { "[System]", message }
        })
    end
end

-- Permission check (ACE, ESX Groups, or QBCore Permissions)
function Bridge.HasPermission(source, permission)
    if Framework == "qbcore" then
        return QBCore.Functions.HasPermission(source, permission)
    elseif Framework == "esx" then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            local group = xPlayer.getGroup()
            if permission == "admin" and (group == "admin" or group == "superadmin") then
                return true
            elseif permission == "mod" and (group == "mod" or group == "admin" or group == "superadmin") then
                return true
            elseif group == permission then
                return true
            end
        end
    else
        -- Standalone ACE permissions fallback
        return IsPlayerAceAllowed(source, permission) or IsPlayerAceAllowed(source, "command." .. permission)
    end
    return false
end

-------------------------------------------------------------------------------
-- INVENTORY WRAPPER FUNCTIONS
-------------------------------------------------------------------------------

function Bridge.Inventory.GetSystem()
    return InventorySystem
end

function Bridge.Inventory.AddItem(source, item, count, metadata)
    count = tonumber(count) or 1
    if InventorySystem == "ox_inventory" then
        return exports.ox_inventory:AddItem(source, item, count, metadata)
    elseif InventorySystem == "qb-inventory" and Framework == "qbcore" then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.Functions.AddItem(item, count, false, metadata)
        end
    elseif InventorySystem == "qs-inventory" then
        return exports['qs-inventory']:AddItem(source, item, count, metadata)
    end
    return false
end

function Bridge.Inventory.RemoveItem(source, item, count, metadata)
    count = tonumber(count) or 1
    if InventorySystem == "ox_inventory" then
        return exports.ox_inventory:RemoveItem(source, item, count, metadata)
    elseif InventorySystem == "qb-inventory" and Framework == "qbcore" then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.Functions.RemoveItem(item, count, false)
        end
    elseif InventorySystem == "qs-inventory" then
        return exports['qs-inventory']:RemoveItem(source, item, count)
    end
    return false
end

function Bridge.Inventory.HasItem(source, item, count)
    count = tonumber(count) or 1
    if InventorySystem == "ox_inventory" then
        local itemCount = exports.ox_inventory:Search(source, 'count', item)
        return itemCount >= count
    elseif InventorySystem == "qb-inventory" and Framework == "qbcore" then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            local itemData = Player.Functions.GetItemByName(item)
            return itemData and itemData.amount >= count
        end
    elseif InventorySystem == "qs-inventory" then
        local quantity = exports['qs-inventory']:GetItemTotalAmount(source, item)
        return quantity >= count
    end
    return false
end

-------------------------------------------------------------------------------
-- BANKING WRAPPER FUNCTIONS
-------------------------------------------------------------------------------

function Bridge.Banking.GetSystem()
    return BankingSystemName
end

function Bridge.Banking.GetBalance(source, account)
    local player = Bridge.GetPlayer(source)
    if player then
        return player.GetMoney(account)
    end
    return 0
end

function Bridge.Banking.AddMoney(source, account, amount, reason)
    local player = Bridge.GetPlayer(source)
    if player then
        return player.AddMoney(account, amount, reason)
    end
    return false
end

function Bridge.Banking.RemoveMoney(source, account, amount, reason)
    local player = Bridge.GetPlayer(source)
    if player then
        return player.RemoveMoney(account, amount, reason)
    end
    return false
end

-------------------------------------------------------------------------------
-- GARAGE WRAPPER FUNCTIONS
-------------------------------------------------------------------------------

function Bridge.Garage.GetSystem()
    return GarageSystemName
end

-- GetPlayerVehicles returns a list of vehicles owned by player
function Bridge.Garage.GetPlayerVehicles(source)
    local player = Bridge.GetPlayer(source)
    if not player then return {} end
    local citizenid = player.GetData().citizenid
    local fw = Bridge.GetFramework()
    local promise = promise.new()

    -- Standard QB-Core vehicle query (compatible with qb-garage, jg-advancedgarage, qs-advancedgarages on QB)
    if fw == "qbcore" then
        MySQL.query('SELECT plate, vehicle, state, hash FROM player_vehicles WHERE citizenid = ?', {citizenid}, function(results)
            local list = {}
            if results then
                for _, row in ipairs(results) do
                    -- State mapping: 0 = out, 1 = stored, 2 = impounded
                    local stateStr = "out"
                    if row.state == 1 then
                        stateStr = "stored"
                    elseif row.state == 2 then
                        stateStr = "impounded"
                    end
                    table.insert(list, {
                        plate = row.plate,
                        model = row.vehicle,
                        state = stateStr,
                        hash = row.hash
                    })
                end
            end
            promise:resolve(list)
        end)
    -- Standard ESX vehicle query (compatible with esx_garage, jg-advancedgarage, qs-advancedgarages on ESX)
    elseif fw == "esx" then
        MySQL.query('SELECT plate, vehicle, stored FROM owned_vehicles WHERE owner = ?', {citizenid}, function(results)
            local list = {}
            if results then
                for _, row in ipairs(results) do
                    local vehicleData = {}
                    pcall(function() vehicleData = json.decode(row.vehicle) end)
                    local model = vehicleData and vehicleData.model or "unknown"
                    -- Stored: 1/true = stored, 0/false = out
                    local stateStr = "out"
                    if row.stored == 1 or row.stored == true then
                        stateStr = "stored"
                    end
                    table.insert(list, {
                        plate = row.plate,
                        model = model,
                        state = stateStr
                    })
                end
            end
            promise:resolve(list)
        end)
    else
        -- Standalone / Fallback
        promise:resolve({})
    end

    return Citizen.Await(promise)
end

-- IsVehicleOwner checks if player owns a specific plate
function Bridge.Garage.IsVehicleOwner(source, plate)
    local player = Bridge.GetPlayer(source)
    if not player then return false end
    local citizenid = player.GetData().citizenid
    local fw = Bridge.GetFramework()
    local plateNormalized = string.gsub(plate, "%s+", ""):upper()
    local promise = promise.new()

    if fw == "qbcore" then
        MySQL.single('SELECT citizenid FROM player_vehicles WHERE TRIM(plate) = ?', {plateNormalized}, function(result)
            if result then
                promise:resolve(result.citizenid == citizenid)
            else
                -- Try querying without trim just in case
                MySQL.single('SELECT citizenid FROM player_vehicles WHERE plate = ?', {plate}, function(result2)
                    promise:resolve(result2 and result2.citizenid == citizenid or false)
                end)
            end
        end)
    elseif fw == "esx" then
        MySQL.single('SELECT owner FROM owned_vehicles WHERE TRIM(plate) = ?', {plateNormalized}, function(result)
            if result then
                promise:resolve(result.owner == citizenid)
            else
                MySQL.single('SELECT owner FROM owned_vehicles WHERE plate = ?', {plate}, function(result2)
                    promise:resolve(result2 and result2.owner == citizenid or false)
                end)
            end
        end)
    else
        -- Standalone allows ownership
        promise:resolve(true)
    end

    return Citizen.Await(promise)
end

-------------------------------------------------------------------------------
-- STANDALONE SYNCHRONIZATION
-------------------------------------------------------------------------------

RegisterNetEvent('void_bridge:server:requestPlayerData', function()
    local src = source
    local player = Bridge.GetPlayer(src)
    if player then
        TriggerClientEvent('void_bridge:client:syncPlayerData', src, player.GetData())
    end
end)

-- Export implementation to retrieve the bridge object
exports('GetBridge', function()
    return Bridge
end)
