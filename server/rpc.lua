local ServerCallbacks = {}

-- Register a server callback that client resources can query
function Bridge.RegisterServerCallback(name, cb)
    ServerCallbacks[name] = cb
    if Config.Debug then
        print(("[void_bridge] Registered Server Callback: ^3%s^7"):format(name))
    end
end

-- Network event listener for incoming client queries
RegisterNetEvent('void_bridge:server:triggerCallback', function(name, requestId, ...)
    local src = source
    if ServerCallbacks[name] then
        -- Execute the callback, passing a response function and client arguments
        ServerCallbacks[name](src, function(...)
            TriggerClientEvent('void_bridge:client:callback', src, requestId, ...)
        end, ...)
    else
        if Config.Debug then
            print(("[void_bridge] [Warning] Server callback '^1%s^7' was triggered by ID %d but is not registered."):format(name, src))
        end
        TriggerClientEvent('void_bridge:client:callback', src, requestId)
    end
end)
