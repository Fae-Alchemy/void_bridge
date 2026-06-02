Bridge = {}
Bridge.Target = {}

local Framework = "standalone"
local QBCore = nil
local ESX = nil

local TargetSystem = "none"
local NotifySystemName = "standalone"
local LibSystemName = "none"

local LocalPlayerData = {}

-- Dynamic Environment Auto-Detection
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

    -- 2. Detect Target System
    if Config.Target ~= "auto" then
        TargetSystem = Config.Target
    else
        if GetResourceState('ox_target') == 'started' then
            TargetSystem = "ox_target"
        elseif GetResourceState('qb-target') == 'started' then
            TargetSystem = "qb-target"
        elseif GetResourceState('qtarget') == 'started' then
            TargetSystem = "qtarget"
        else
            TargetSystem = "none"
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

    -- 4. Detect Utility Library
    if Config.Lib ~= "auto" then
        LibSystemName = Config.Lib
    else
        if GetResourceState('ox_lib') == 'started' then
            LibSystemName = "ox_lib"
        else
            LibSystemName = "none"
        end
    end

    if Config.Debug then
        print("^4================= VOID_BRIDGE ENVIRONMENT (CLIENT) =================^7")
        print(("^4[void_bridge]^7 Framework: ^2%s^7"):format(Framework))
        print(("^4[void_bridge]^7 Target: ^2%s^7"):format(TargetSystem))
        print(("^4[void_bridge]^7 Notification: ^2%s^7"):format(NotifySystemName))
        print(("^4[void_bridge]^7 Library: ^2%s^7"):format(LibSystemName))
        print("^4====================================================================^7")
    end
end

-- Initialize detection on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
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
                canInteract = opt.canInteract
            })
        end
        exports.ox_target:addBoxZone({
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
                canInteract = opt.canInteract
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
                end
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

-- Export implementation to retrieve the bridge object
exports('GetBridge', function()
    return Bridge
end)
