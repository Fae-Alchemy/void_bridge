local CurrentRequests = {}
local RequestIdCounter = 0

-- Trigger a server callback and receive the result asynchronously
function Bridge.TriggerServerCallback(name, cb, ...)
    RequestIdCounter = RequestIdCounter + 1
    CurrentRequests[RequestIdCounter] = cb

    -- Send request to server with request ID and optional arguments
    TriggerServerEvent('void_bridge:server:triggerCallback', name, RequestIdCounter, ...)
end

-- Network event listener for server responses
RegisterNetEvent('void_bridge:client:callback', function(requestId, ...)
    local cb = CurrentRequests[requestId]
    if cb then
        cb(...)
        CurrentRequests[requestId] = nil
    end
end)
