Bridge = {}
Bridge.Target = {}

local Framework = "standalone"
local QBCore = nil
local ESX = nil

local TargetSystem = "none"
local NotifySystemName = "standalone"
local LibSystemName = "none"

local LocalPlayerData = {}

local lastFramework = nil
local lastTargetSystem = nil
local lastNotifySystem = nil
local lastLibSystem = nil

local function IsResourceActive(name)
    local state = GetResourceState(name)
    return state == "started" or state == "starting"
end

-- Dynamic Environment Auto-Detection
local function DetectEnvironment()
    -- 1. Detect Core Framework
    if Config.Framework ~= "auto" then
        Framework = Config.Framework
    else
        if IsResourceActive('qbx_core') then
            Framework = "qbx"
        elseif IsResourceActive('qb-core') then
            Framework = "qbcore"
        elseif IsResourceActive('es_extended') then
            Framework = "esx"
        else
            Framework = "standalone"
        end
    end

    if Framework == "qbcore" then
        if not QBCore then
            pcall(function() QBCore = exports['qb-core']:GetCoreObject() end)
        end
    elseif Framework == "esx" then
        if not ESX then
            pcall(function() ESX = exports['es_extended']:getSharedObject() end)
            if not ESX then
                TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            end
        end
    end

    -- 2. Detect Target System
    if Config.Target ~= "auto" then
        TargetSystem = Config.Target
    else
        if IsResourceActive('ox_target') then
            TargetSystem = "ox_target"
        elseif IsResourceActive('qb-target') then
            TargetSystem = "qb-target"
        elseif IsResourceActive('qtarget') then
            TargetSystem = "qtarget"
        else
            TargetSystem = "none"
        end
    end

    -- 3. Detect Notification System
    if Config.Notify ~= "auto" then
        NotifySystemName = Config.Notify
    else
        if IsResourceActive('okokNotify') then
            NotifySystemName = "okokNotify"
        elseif IsResourceActive('ox_lib') then
            NotifySystemName = "ox_lib"
        elseif Framework == "qbcore" or Framework == "qbx" then
            NotifySystemName = "qbcore"
        elseif Framework == "esx" then
            NotifySystemName = "esx"
        else
            NotifySystemName = "standalone"
        end
    end

    -- 4. Detect Utility Library
    if Config.Lib ~= "auto" then
        LibSystemName = Config.Lib
    else
        if IsResourceActive('ox_lib') then
            LibSystemName = "ox_lib"
        else
            LibSystemName = "none"
        end
    end

    -- Log configuration banner only if state changes
    local changed = (Framework ~= lastFramework) or (TargetSystem ~= lastTargetSystem) or (NotifySystemName ~= lastNotifySystem) or (LibSystemName ~= lastLibSystem)
    if changed then
        lastFramework = Framework
        lastTargetSystem = TargetSystem
        lastNotifySystem = NotifySystemName
        lastLibSystem = LibSystemName

        if Config.Debug then
            print("^4================= VOID_BRIDGE ENVIRONMENT (CLIENT) =================^7")
            print(("^4[void_bridge]^7 Framework: ^2%s^7"):format(Framework))
            print(("^4[void_bridge]^7 Target: ^2%s^7"):format(TargetSystem))
            print(("^4[void_bridge]^7 Notification: ^2%s^7"):format(NotifySystemName))
            print(("^4[void_bridge]^7 Library: ^2%s^7"):format(LibSystemName))
            print("^4====================================================================^7")
        end
    end
end

-- Initialize detection on resource start / dynamically when any resource starts
AddEventHandler('onClientResourceStart', function(resourceName)
    DetectEnvironment()
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    DetectEnvironment()
end)

CreateThread(function()
    Wait(100)
    DetectEnvironment()
    -- Sync standalone player data on load
    if Framework == "standalone" then
        TriggerServerEvent('void_bridge:server:requestPlayerData')
    end
end)

-------------------------------------------------------------------------------
-- PLAYER DATA CLIENT API
-------------------------------------------------------------------------------

-- Get local player info uniformly
function Bridge.GetPlayerData()
    if Framework == "qbcore" then
        local pData = QBCore.Functions.GetPlayerData()
        return {
            citizenid = pData.citizenid,
            source = pData.source,
            name = pData.charinfo.firstname .. " " .. pData.charinfo.lastname,
            job = {
                name = pData.job.name,
                label = pData.job.label,
                grade = pData.job.grade.level,
                gradeLabel = pData.job.grade.name
            },
            gang = pData.gang and {
                name = pData.gang.name,
                label = pData.gang.label,
                grade = pData.gang.grade.level,
                gradeLabel = pData.gang.grade.name,
                isboss = pData.gang.isboss
            } or nil
        }
    elseif Framework == "qbx" then
        local pData = nil
        if QBX and QBX.PlayerData then
            pData = QBX.PlayerData
        elseif exports.qbx_core and exports.qbx_core.GetPlayerData then
            pData = exports.qbx_core:GetPlayerData()
        elseif QBCore and QBCore.Functions then
            pData = QBCore.Functions.GetPlayerData()
        end

        if not pData then return {} end
        return {
            citizenid = pData.citizenid,
            source = pData.source or GetPlayerServerId(PlayerId()),
            name = pData.charinfo and (pData.charinfo.firstname .. " " .. pData.charinfo.lastname) or "Player",
            job = {
                name = pData.job and pData.job.name or "unemployed",
                label = pData.job and pData.job.label or "Unemployed",
                grade = pData.job and pData.job.grade and pData.job.grade.level or 0,
                gradeLabel = pData.job and pData.job.grade and pData.job.grade.name or "Freelancer"
            },
            gang = pData.gang and {
                name = pData.gang.name,
                label = pData.gang.label,
                grade = pData.gang.grade and pData.gang.grade.level or 0,
                gradeLabel = pData.gang.grade and pData.gang.grade.name or "Recruit",
                isboss = pData.gang.isboss
            } or nil
        }
    elseif Framework == "esx" then
        local pData = ESX.GetPlayerData()
        local jobLabel = pData.job and pData.job.label or "Unemployed"
        local gradeLabel = pData.job and pData.job.grade_label or "Grade"
        return {
            citizenid = pData.identifier,
            source = GetPlayerServerId(PlayerId()),
            name = pData.firstName and (pData.firstName .. " " .. pData.lastName) or GetPlayerName(PlayerId()),
            job = {
                name = pData.job and pData.job.name or "unemployed",
                label = jobLabel,
                grade = pData.job and pData.job.grade or 0,
                gradeLabel = gradeLabel
            }
        }
    else
        return LocalPlayerData
    end
end

-- Sync standalone player data network event
RegisterNetEvent('void_bridge:client:syncPlayerData', function(pData)
    LocalPlayerData = pData
end)

-------------------------------------------------------------------------------
-- NOTIFICATION CLIENT API
-------------------------------------------------------------------------------

function Bridge.Notify(message, type, duration)
    type = type or "info"
    duration = duration or Config.DefaultNotificationDuration

    if NotifySystemName == "ox_lib" then
        lib.notify({
            description = message,
            type = type,
            duration = duration
        })
    elseif NotifySystemName == "okokNotify" then
        exports['okokNotify']:Alert("System", message, duration, type)
    elseif NotifySystemName == "qbcore" and Framework == "qbcore" then
        QBCore.Functions.Notify(message, type, duration)
    elseif NotifySystemName == "qbcore" and Framework == "qbx" then
        pcall(function()
            exports.qbx_core:Notify(message, type, duration)
        end)
    elseif NotifySystemName == "esx" and Framework == "esx" then
        ESX.ShowNotification(message, type, duration)
    else
        -- Native subtitle text fallback
        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    end
end

-------------------------------------------------------------------------------
-- TARGET INTERACTION CLIENT API
-------------------------------------------------------------------------------

function Bridge.Target.GetSystem()
    return TargetSystem
end

function Bridge.Target.AddBoxZone(id, coords, size, rotation, options)
    -- Unified targeting options mapping
    if TargetSystem == "ox_target" then
        local oxOptions = {}
        for _, opt in ipairs(options.options) do
            table.insert(oxOptions, {
                name = opt.name or id .. "_" .. opt.label,
                icon = opt.icon,
                label = opt.label,
                event = opt.event,
                onSelect = opt.action,
                canInteract = opt.canInteract,
                distance = opt.distance or options.distance
            })
        end
        return exports.ox_target:addBoxZone({
            coords = coords,
            size = size,
            rotation = rotation,
            debug = Config.Debug,
            options = oxOptions
        })
    elseif TargetSystem == "qb-target" or TargetSystem == "qtarget" then
        local targetName = TargetSystem == "qb-target" and "qb-target" or "qtarget"
        local qbOptions = {}
        for _, opt in ipairs(options.options) do
            table.insert(qbOptions, {
                type = "client",
                event = opt.event,
                icon = opt.icon,
                label = opt.label,
                action = opt.action,
                canInteract = opt.canInteract
            })
        end

        exports[targetName]:AddBoxZone(id, coords, size.x, size.y, {
            name = id,
            heading = rotation,
            debugPoly = Config.Debug,
            minZ = coords.z - size.z / 2,
            maxZ = coords.z + size.z / 2,
        }, {
            options = qbOptions,
            distance = options.distance or 2.5
        })
    end
end

function Bridge.Target.AddTargetModel(models, options)
    if TargetSystem == "ox_target" then
        local oxOptions = {}
        for _, opt in ipairs(options.options) do
            table.insert(oxOptions, {
                name = opt.name or opt.label,
                icon = opt.icon,
                label = opt.label,
                event = opt.event,
                onSelect = opt.action,
                canInteract = opt.canInteract,
                distance = opt.distance or options.distance
            })
        end
        exports.ox_target:addModel(models, oxOptions)
    elseif TargetSystem == "qb-target" or TargetSystem == "qtarget" then
        local targetName = TargetSystem == "qb-target" and "qb-target" or "qtarget"
        local qbOptions = {}
        for _, opt in ipairs(options.options) do
            table.insert(qbOptions, {
                type = "client",
                event = opt.event,
                icon = opt.icon,
                label = opt.label,
                action = opt.action,
                canInteract = opt.canInteract
            })
        end
        exports[targetName]:AddTargetModel(models, {
            options = qbOptions,
            distance = options.distance or 2.5
        })
    end
end

function Bridge.Target.AddTargetEntity(entity, options)
    local items = options.options or options
    local distance = options.distance or 2.5

    if TargetSystem == "ox_target" then
        local oxOptions = {}
        for _, opt in ipairs(items) do
            table.insert(oxOptions, {
                name = opt.name or opt.label,
                icon = opt.icon,
                label = opt.label,
                event = opt.event,
                onSelect = function(data)
                    if opt.action then
                        opt.action(data.entity)
                    end
                end,
                canInteract = function(ent, dist, coords, name, bone)
                    if opt.canInteract then
                        return opt.canInteract(ent)
                    end
                    return true
                end,
                distance = opt.distance or distance
            })
        end
        exports.ox_target:addLocalEntity(entity, oxOptions)
    elseif TargetSystem == "qb-target" or TargetSystem == "qtarget" then
        local targetName = TargetSystem == "qb-target" and "qb-target" or "qtarget"
        local qbOptions = {}
        for i, opt in ipairs(items) do
            table.insert(qbOptions, {
                num = i,
                type = "client",
                event = opt.event,
                icon = opt.icon,
                label = opt.label,
                action = opt.action,
                canInteract = opt.canInteract
            })
        end
        exports[targetName]:AddTargetEntity(entity, {
            options = qbOptions,
            distance = distance
        })
    end
end

function Bridge.Target.RemoveTargetEntity(entity)
    if TargetSystem == "ox_target" then
        exports.ox_target:removeLocalEntity(entity)
    elseif TargetSystem == "qb-target" or TargetSystem == "qtarget" then
        local targetName = TargetSystem == "qb-target" and "qb-target" or "qtarget"
        exports[targetName]:RemoveTargetEntity(entity)
    end
end

function Bridge.Target.RemoveZone(zone)
    if TargetSystem == "ox_target" then
        exports.ox_target:removeZone(zone)
    elseif TargetSystem == "qb-target" or TargetSystem == "qtarget" then
        local targetName = TargetSystem == "qb-target" and "qb-target" or "qtarget"
        exports[targetName]:RemoveZone(zone)
    end
end

-- Export implementation to retrieve the bridge object
exports('GetBridge', function()
    return Bridge
end)

-------------------------------------------------------------------------------
-- OKOKSCRIPTS WRAPPER FUNCTIONS (CLIENT)
-------------------------------------------------------------------------------
Bridge.Okok = {}

-- okokNotify Client Integration
function Bridge.OkokNotify(title, message, duration, type, playSound)
    type = type or "info"
    duration = duration or 5000
    if GetResourceState('okokNotify') == 'started' then
        exports['okokNotify']:Alert(title, message, duration, type, playSound)
    else
        -- Fallback to standard Bridge notification
        Bridge.Notify(message, type, duration)
    end
end

exports('OkokNotify', function(...)
    Bridge.OkokNotify(...)
end)

-- okokBilling Client Integration
Bridge.OkokBilling = {}

function Bridge.OkokBilling.CreateNewInvoice(jobName)
    if GetResourceState('okokBilling') == 'started' then
        exports['okokBilling']:CreateNewInvoice(jobName)
        return true
    else
        if Config.Debug then
            print("[void_bridge] okokBilling is not started. CreateNewInvoice aborted.")
        end
        return false
    end
end

function Bridge.OkokBilling.ToggleMyInvoices()
    if GetResourceState('okokBilling') == 'started' then
        TriggerEvent('okokBilling:ToggleMyInvoices')
        return true
    else
        if Config.Debug then
            print("[void_bridge] okokBilling is not started. ToggleMyInvoices aborted.")
        end
        return false
    end
end

function Bridge.OkokBilling.ToggleCreateInvoice()
    if GetResourceState('okokBilling') == 'started' then
        TriggerEvent('okokBilling:ToggleCreateInvoice')
        return true
    else
        if Config.Debug then
            print("[void_bridge] okokBilling is not started. ToggleCreateInvoice aborted.")
        end
        return false
    end
end

exports('OkokBilling_CreateNewInvoice', function(...)
    return Bridge.OkokBilling.CreateNewInvoice(...)
end)
exports('OkokBilling_ToggleMyInvoices', function(...)
    return Bridge.OkokBilling.ToggleMyInvoices(...)
end)
exports('OkokBilling_ToggleCreateInvoice', function(...)
    return Bridge.OkokBilling.ToggleCreateInvoice(...)
end)

-- okokRequests Client Integration
Bridge.OkokRequests = {}

function Bridge.OkokRequests.RequestMenu(target, time, title, message, trigger, side, parameters, parametersNum)
    if GetResourceState('okokRequests') == 'started' then
        exports['okokRequests']:requestMenu(target, time, title, message, trigger, side, parameters, parametersNum)
        return true
    else
        if Config.Debug then
            print("[void_bridge] okokRequests is not started on client. Fallback to server-side event trigger.")
        end
        -- Trigger event directly as fallback (if target matches local player or server side)
        local localSource = GetPlayerServerId(PlayerId())
        if tonumber(target) == localSource then
            local args = {}
            if parameters then
                for arg in string.gmatch(parameters, "([^,]+)") do
                    table.insert(args, arg)
                end
            end
            if side == "client" then
                TriggerEvent(trigger, table.unpack(args))
            elseif side == "server" then
                TriggerServerEvent(trigger, table.unpack(args))
            end
        end
        return true
    end
end

exports('OkokRequests_RequestMenu', function(...)
    return Bridge.OkokRequests.RequestMenu(...)
end)

-- okokGarage Client Integration
Bridge.OkokGarage = {}

function Bridge.OkokGarage.GiveKeys(plate)
    if GetResourceState('okokGarage') == 'started' then
        TriggerServerEvent('okokGarage:GiveKeys', plate)
        return true
    else
        if Config.Debug then
            print("[void_bridge] okokGarage is not started. GiveKeys client trigger ignored.")
        end
        return false
    end
end

function Bridge.OkokGarage.LockVehicle(vehicle)
    if GetResourceState('okokGarage') == 'started' then
        pcall(function()
            exports['okokGarage']:lockvehicle(vehicle)
        end)
        return true
    else
        if Config.Debug then
            print("[void_bridge] okokGarage is not started. LockVehicle fallback toggle.")
        end
        local lockStatus = GetVehicleDoorLockStatus(vehicle)
        if lockStatus == 1 or lockStatus == 0 then
            SetVehicleDoorsLocked(vehicle, 2)
            Bridge.Notify("Vehicle Locked", "success", 3000)
        else
            SetVehicleDoorsLocked(vehicle, 1)
            Bridge.Notify("Vehicle Unlocked", "success", 3000)
        end
        return true
    end
end

exports('OkokGarage_GiveKeys', function(...)
    return Bridge.OkokGarage.GiveKeys(...)
end)
exports('OkokGarage_LockVehicle', function(...)
    return Bridge.OkokGarage.LockVehicle(...)
end)

-- okokChat Client Integration
Bridge.OkokChat = {}

function Bridge.OkokChat.Message(background, color, icon, title, playername, message)
    if GetResourceState('okokChat') == 'started' or GetResourceState('okokChatV2') == 'started' then
        local chatRes = GetResourceState('okokChatV2') == 'started' and 'okokChatV2' or 'okokChat'
        exports[chatRes]:Message(background, color, icon, title, playername, message)
        return true
    else
        TriggerEvent('chat:addMessage', {
            args = { title or "System", message }
        })
        return false
    end
end

exports('OkokChat_Message', function(...)
    return Bridge.OkokChat.Message(...)
end)

-------------------------------------------------------------------------------
-- STANDALONE DISPATCH SYSTEM FALLBACK (CLIENT)
-------------------------------------------------------------------------------
local fallbackBlip = nil

RegisterNetEvent('void_bridge:client:dispatchAlert', function(data)
    local pData = Bridge.GetPlayerData()
    if not pData or not pData.job or not pData.job.name then return end

    -- Check if player's job is in target dispatch jobs
    local hasJob = false
    for _, job in ipairs(data.jobs) do
        if pData.job.name == job then
            hasJob = true
            break
        end
    end

    if not hasJob then return end

    -- Play warning sound
    PlaySoundFrontend(-1, "LEADER_BOARD", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)

    -- Display alert message
    Bridge.Notify(("[%s] %s - %s"):format(data.code, data.title, data.description), "warning", 8000)

    -- Add blip
    if fallbackBlip then RemoveBlip(fallbackBlip) end
    fallbackBlip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipSprite(fallbackBlip, data.sprite or 161)
    SetBlipScale(fallbackBlip, data.scale or 1.0)
    SetBlipColor(fallbackBlip, data.color or 1)
    SetBlipRoute(fallbackBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(data.title)
    EndTextCommandSetBlipName(fallbackBlip)

    -- Remove blip after 2 minutes
    CreateThread(function()
        Wait(120000)
        if fallbackBlip then
            RemoveBlip(fallbackBlip)
            fallbackBlip = nil
        end
    end)
end)

-------------------------------------------------------------------------------
-- VEHICLE PROPERTIES CLIENT API
-------------------------------------------------------------------------------

function Bridge.GetVehicleProperties(vehicle)
    if not DoesEntityExist(vehicle) then return {} end
    if LibSystemName == "ox_lib" then
        return lib.getVehicleProperties(vehicle)
    end
    
    -- QB-Core / Qbox compatibility fallback
    if Framework == "qbcore" or Framework == "qbx" then
        local QBCoreObj = nil
        if Framework == "qbcore" then
            QBCoreObj = QBCore
        else
            pcall(function() QBCoreObj = exports['qb-core']:GetCoreObject() end)
        end
        if QBCoreObj and QBCoreObj.Functions and QBCoreObj.Functions.GetVehicleProperties then
            return QBCoreObj.Functions.GetVehicleProperties(vehicle)
        end
    end

    -- ESX compatibility fallback
    if Framework == "esx" and ESX then
        return ESX.Game.GetVehicleProperties(vehicle)
    end

    -- Standalone native fallback
    local color1, color2 = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    local properties = {
        model = GetEntityModel(vehicle),
        plate = GetVehicleNumberPlateText(vehicle),
        color1 = color1,
        color2 = color2,
        pearlescentColor = pearlescentColor,
        wheelColor = wheelColor,
        wheels = GetVehicleWheelType(vehicle),
        windowTint = GetVehicleWindowTint(vehicle),
        bodyHealth = GetVehicleBodyHealth(vehicle),
        engineHealth = GetVehicleEngineHealth(vehicle),
        fuelLevel = GetVehicleFuelLevel(vehicle),
        mods = {}
    }
    SetVehicleModKit(vehicle, 0)
    for i = 0, 48 do
        properties.mods[tostring(i)] = GetVehicleMod(vehicle, i)
    end
    return properties
end

function Bridge.SetVehicleProperties(vehicle, props)
    if not DoesEntityExist(vehicle) or not props then return end
    if LibSystemName == "ox_lib" then
        lib.setVehicleProperties(vehicle, props)
        return
    end

    -- QB-Core / Qbox compatibility fallback
    if Framework == "qbcore" or Framework == "qbx" then
        local QBCoreObj = nil
        if Framework == "qbcore" then
            QBCoreObj = QBCore
        else
            pcall(function() QBCoreObj = exports['qb-core']:GetCoreObject() end)
        end
        if QBCoreObj and QBCoreObj.Functions and QBCoreObj.Functions.SetVehicleProperties then
            QBCoreObj.Functions.SetVehicleProperties(vehicle, props)
            return
        end
    end

    -- ESX compatibility fallback
    if Framework == "esx" and ESX then
        ESX.Game.SetVehicleProperties(vehicle, props)
        return
    end

    -- Standalone native fallback
    SetVehicleModKit(vehicle, 0)
    if props.color1 and props.color2 then SetVehicleColours(vehicle, props.color1, props.color2) end
    if props.pearlescentColor and props.wheelColor then SetVehicleExtraColours(vehicle, props.pearlescentColor, props.wheelColor) end
    if props.wheels then SetVehicleWheelType(vehicle, props.wheels) end
    if props.windowTint then SetVehicleWindowTint(vehicle, props.windowTint) end
    if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
    if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
    if props.fuelLevel then SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0) end
    if props.mods then
        for modId, modVal in pairs(props.mods) do
            local id = tonumber(modId)
            if id then
                if id == 18 then ToggleVehicleMod(vehicle, 18, modVal == 1 or modVal == true)
                elseif id == 22 then ToggleVehicleMod(vehicle, 22, modVal == 1 or modVal == true)
                else SetVehicleMod(vehicle, id, tonumber(modVal), false) end
            end
        end
    end
end

exports('GetVehicleProperties', function(vehicle)
    return Bridge.GetVehicleProperties(vehicle)
end)

exports('SetVehicleProperties', function(vehicle, props)
    Bridge.SetVehicleProperties(vehicle, props)
end)

-------------------------------------------------------------------------------
-- VEHICLE KEYS & LOCKS CLIENT API
-------------------------------------------------------------------------------

function Bridge.GiveVehicleKeys(vehicle, plate)
    if not plate then plate = GetVehicleNumberPlateText(vehicle) end
    if not plate then return false end
    
    if GetResourceState('void_keys') == 'started' then
        exports.void_keys:GiveKeys(plate)
        return true
    elseif GetResourceState('qb-vehiclekeys') == 'started' then
        TriggerEvent('vehiclekeys:client:SetOwner', plate)
        return true
    elseif GetResourceState('okokGarage') == 'started' then
        TriggerServerEvent('okokGarage:GiveKeys', plate)
        return true
    end
    return false
end

function Bridge.LockVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return end
    if GetResourceState('okokGarage') == 'started' then
        pcall(function() exports['okokGarage']:lockvehicle(vehicle) end)
        return true
    end

    -- Default fallback (toggle)
    local lockStatus = GetVehicleDoorLockStatus(vehicle)
    if lockStatus == 1 or lockStatus == 0 then
        SetVehicleDoorsLocked(vehicle, 2)
        Bridge.Notify("Vehicle Locked", "success", 3000)
    else
        SetVehicleDoorsLocked(vehicle, 1)
        Bridge.Notify("Vehicle Unlocked", "success", 3000)
    end
    return true
end

exports('GiveVehicleKeys', function(vehicle, plate)
    return Bridge.GiveVehicleKeys(vehicle, plate)
end)

exports('LockVehicle', function(vehicle)
    return Bridge.LockVehicle(vehicle)
end)



