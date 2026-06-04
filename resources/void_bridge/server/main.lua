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
local DispatchSystemName = "standalone"


-- Dynamic Framework and Dependency Auto-Detection
local function DetectEnvironment()
    -- 1. Detect Core Framework
    if Config.Framework ~= "auto" then
        Framework = Config.Framework
    else
        if GetResourceState('qb-core') == 'started' or GetResourceState('qbx_core') == 'started' then
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

    -- 6. Detect Dispatch System
    if Config.Dispatch ~= "auto" then
        DispatchSystemName = Config.Dispatch
    else
        if GetResourceState('ps-dispatch') == 'started' then
            DispatchSystemName = "ps-dispatch"
        elseif GetResourceState('qb-dispatch') == 'started' then
            DispatchSystemName = "qb-dispatch"
        elseif GetResourceState('cd_dispatch') == 'started' then
            DispatchSystemName = "cd_dispatch"
        else
            DispatchSystemName = "standalone"
        end
    end

    if Config.Debug then
        print("^4================= VOID_BRIDGE ENVIRONMENT =================^7")
        print(("^4[void_bridge]^7 Framework: ^2%s^7"):format(Framework))
        print(("^4[void_bridge]^7 Inventory: ^2%s^7"):format(InventorySystem))
        print(("^4[void_bridge]^7 Notification: ^2%s^7"):format(NotifySystemName))
        print(("^4[void_bridge]^7 Banking: ^2%s^7"):format(BankingSystemName))
        print(("^4[void_bridge]^7 Garage: ^2%s^7"):format(GarageSystemName))
        print(("^4[void_bridge]^7 Dispatch: ^2%s^7"):format(DispatchSystemName))
        print("^4===========================================================^7")
    end
end

-- Version Checker
local function CheckVersion()
    local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
    if not currentVersion then
        if Config.Debug then
            print("[void_bridge] Version metadata not found in fxmanifest.lua.")
        end
        return
    end

    PerformHttpRequest('https://raw.githubusercontent.com/Fae-Alchemy/void_bridge/master/fxmanifest.lua', function(statusCode, response, headers)
        if statusCode ~= 200 or not response then
            if Config.Debug then
                print("[void_bridge] Failed to fetch latest version from GitHub.")
            end
            return
        end

        -- Parse version from response
        local latestVersion = response:match("version%s+['\"]([%d%.]+)['\"]")
        if not latestVersion then
            if Config.Debug then
                print("[void_bridge] Could not parse version from GitHub response.")
            end
            return
        end

        if currentVersion ~= latestVersion then
            print("^4===========================================================^7")
            print(("^4[void_bridge]^7 Update Available! Local: ^1v%s^7 | Latest: ^2v%s^7"):format(currentVersion, latestVersion))
            print("^4[void_bridge]^7 Please download the latest version from:")
            print("^4[void_bridge]^7 https://github.com/Fae-Alchemy/void_bridge/releases")
            print("^4===========================================================^7")
        else
            if Config.Debug then
                print(("^4[void_bridge]^7 Version check: up to date (v" .. currentVersion .. ")"))
            end
        end
    end, 'GET')
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
    Wait(5000) -- Wait 5 seconds after startup to not clutter console
    CheckVersion()
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
    source = tonumber(source) or source
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
    source = tonumber(source) or source
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
    source = tonumber(source) or source
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

-------------------------------------------------------------------------------
-- OKOKSCRIPTS WRAPPER FUNCTIONS (SERVER)
-------------------------------------------------------------------------------
Bridge.Okok = {}

-- okokNotify Server Integration
function Bridge.OkokNotify(source, title, message, duration, type, playSound)
    type = type or "info"
    duration = duration or 5000
    if GetResourceState('okokNotify') == 'started' then
        TriggerClientEvent('okokNotify:Alert', source, title, message, duration, type, playSound)
    else
        -- Fallback to standard Bridge notification
        Bridge.Notify(source, message, type, duration)
    end
end

exports('OkokNotify', function(...)
    Bridge.OkokNotify(...)
end)

-- okokBanking Server Integration
Bridge.OkokBanking = {}

function Bridge.OkokBanking.GetAccount(society)
    if GetResourceState('okokBanking') == 'started' then
        return exports['okokBanking']:GetAccount(society)
    else
        if Config.Debug then
            print("[void_bridge] okokBanking is not started. GetAccount returning nil.")
        end
        return nil
    end
end

function Bridge.OkokBanking.AddMoney(society, value)
    if GetResourceState('okokBanking') == 'started' then
        return exports['okokBanking']:AddMoney(society, value)
    else
        if Config.Debug then
            print("[void_bridge] okokBanking is not started. AddMoney aborted.")
        end
        return false
    end
end

function Bridge.OkokBanking.RemoveMoney(society, value)
    if GetResourceState('okokBanking') == 'started' then
        return exports['okokBanking']:RemoveMoney(society, value)
    else
        if Config.Debug then
            print("[void_bridge] okokBanking is not started. RemoveMoney aborted.")
        end
        return false
    end
end

function Bridge.OkokBanking.AddTransaction(citizenid, transactionData, source)
    if GetResourceState('okokBanking') == 'started' then
        return exports['okokBanking']:AddTransaction(citizenid, transactionData, source)
    else
        if Config.Debug then
            print("[void_bridge] okokBanking is not started. AddTransaction aborted.")
        end
        return false
    end
end

exports('OkokBanking_GetAccount', function(...)
    return Bridge.OkokBanking.GetAccount(...)
end)
exports('OkokBanking_AddMoney', function(...)
    return Bridge.OkokBanking.AddMoney(...)
end)
exports('OkokBanking_RemoveMoney', function(...)
    return Bridge.OkokBanking.RemoveMoney(...)
end)
exports('OkokBanking_AddTransaction', function(...)
    return Bridge.OkokBanking.AddTransaction(...)
end)

-- okokBilling Server Integration
Bridge.OkokBilling = {}

function Bridge.OkokBilling.CreateCustomInvoice(target, price, reason, invoiceSource, society, societyName, authorIdentifier)
    if GetResourceState('okokBilling') == 'started' then
        TriggerEvent('okokBilling:CreateCustomInvoice', target, price, reason, invoiceSource, society, societyName, authorIdentifier)
        return true
    else
        if Config.Debug then
            print("[void_bridge] okokBilling is not started. Billing fallback to notifying the target.")
        end
        -- Fallback: Notify target they owe money
        local invoiceMsg = ("You received an invoice of $%d from %s for: %s"):format(price, invoiceSource or "System", reason or "Services")
        Bridge.Notify(target, invoiceMsg, "warning", 6000)
        return false
    end
end

exports('OkokBilling_CreateCustomInvoice', function(...)
    return Bridge.OkokBilling.CreateCustomInvoice(...)
end)

-- okokRequests Server Integration
Bridge.OkokRequests = {}

function Bridge.OkokRequests.RequestMenu(target, time, title, message, trigger, side, parameters, parametersNum)
    if GetResourceState('okokRequests') == 'started' then
        return exports['okokRequests']:requestMenu(target, time, title, message, trigger, side, parameters, parametersNum)
    else
        if Config.Debug then
            print("[void_bridge] okokRequests is not started. Executing trigger directly as fallback.")
        end
        -- Fallback: auto-accept the request instantly if side is server
        if side == "server" then
            local args = {}
            if parameters then
                for arg in string.gmatch(parameters, "([^,]+)") do
                    table.insert(args, arg)
                end
            end
            TriggerEvent(trigger, table.unpack(args))
        elseif side == "client" then
            local args = {}
            if parameters then
                for arg in string.gmatch(parameters, "([^,]+)") do
                    table.insert(args, arg)
                end
            end
            TriggerClientEvent(trigger, target, table.unpack(args))
        end
        return true
    end
end

exports('OkokRequests_RequestMenu', function(...)
    return Bridge.OkokRequests.RequestMenu(...)
end)

-- okokGarage Server Integration
Bridge.OkokGarage = {}

function Bridge.OkokGarage.GiveKeys(source, plate)
    if GetResourceState('okokGarage') == 'started' then
        TriggerEvent('okokGarage:GiveKeys', plate)
        return true
    else
        if Config.Debug then
            print("[void_bridge] okokGarage is not started. Cannot give keys server-side.")
        end
        return false
    end
end

function Bridge.OkokGarage.SetVehicleStolen(plate)
    if GetResourceState('okokGarage') == 'started' then
        TriggerEvent('okokGarage:setVehicleStolen', plate)
        return true
    else
        if Config.Debug then
            print("[void_bridge] okokGarage is not started. SetVehicleStolen aborted.")
        end
        return false
    end
end

exports('OkokGarage_GiveKeys', function(...)
    return Bridge.OkokGarage.GiveKeys(...)
end)
exports('OkokGarage_SetVehicleStolen', function(...)
    return Bridge.OkokGarage.SetVehicleStolen(...)
end)

-- okokChat Server Integration
Bridge.OkokChat = {}

function Bridge.OkokChat.Message(source, background, color, icon, title, playername, message)
    if GetResourceState('okokChat') == 'started' or GetResourceState('okokChatV2') == 'started' then
        local chatRes = GetResourceState('okokChatV2') == 'started' and 'okokChatV2' or 'okokChat'
        exports[chatRes]:Message(background, color, icon, title, playername, message)
        return true
    else
        -- Fallback to standard chat message
        TriggerClientEvent('chat:addMessage', source, {
            args = { title or "System", message }
        })
        return false
    end
end

exports('OkokChat_Message', function(...)
    return Bridge.OkokChat.Message(...)
end)

-------------------------------------------------------------------------------
-- DISPATCH WRAPPER FUNCTIONS (SERVER)
-------------------------------------------------------------------------------
Bridge.Dispatch = {}

function Bridge.Dispatch.GetSystem()
    return DispatchSystemName
end

function Bridge.Dispatch.Alert(source, data)
    if not data then return end
    local coords = data.coords or (source and GetEntityCoords(GetPlayerPed(source)) or vector3(0.0, 0.0, 0.0))
    local title = data.title or "Robbery in progress"
    local description = data.description or "Robbery alarm triggered"
    local code = data.code or "10-90"
    local sprite = data.sprite or 161
    local color = data.color or 1
    local scale = data.scale or 1.0
    local jobs = data.jobs or { "police" }

    if DispatchSystemName == "ps-dispatch" then
        exports['ps-dispatch']:CustomAlert({
            coords = coords,
            message = description,
            dispatchCode = code,
            description = description,
            priority = 2,
            playKeepAliveSound = true,
            alert = {
                title = title,
                coords = coords,
                sprite = sprite,
                color = color,
                scale = scale,
                flash = true
            },
            jobs = jobs
        })
    elseif DispatchSystemName == "qb-dispatch" then
        TriggerEvent('qb-dispatch:server:CreateDispatchCall', {
            code = code,
            description = description,
            radius = 0,
            sprite = sprite,
            color = color,
            scale = scale,
            coords = coords,
            job = jobs
        })
    elseif DispatchSystemName == "cd_dispatch" then
        TriggerEvent('cd_dispatch:AddNotification', {
            job_table = jobs,
            coords = coords,
            title = title,
            message = description,
            flash = 1,
            unique_id = tostring(math.random(10000, 99999)),
            blip = {
                sprite = sprite,
                color = color,
                scale = scale,
                text = title,
                time = 60,
                flash = true
            }
        })
    else
        -- Standalone / Fallback to all online players with target jobs
        TriggerClientEvent('void_bridge:client:dispatchAlert', -1, {
            coords = coords,
            title = title,
            description = description,
            code = code,
            sprite = sprite,
            color = color,
            scale = scale,
            jobs = jobs
        })
    end
end

exports('AlertPolice', function(source, data)
    return Bridge.Dispatch.Alert(source, data)
end)

-- Export implementation to retrieve the bridge object
exports('GetBridge', function()
    return Bridge
end)


