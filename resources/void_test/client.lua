local Bridge = exports['void_bridge']:GetBridge()

CreateThread(function()
    Wait(1000) -- Wait for initialization
    print("^5[void_test]^7 Client Test Initializing...")

    -- Test notification
    Bridge.Notify("void_bridge initialized successfully!", "success", 5000)

    -- Test Callback
    Bridge.TriggerServerCallback('void_test:server:getSystemData', function(result)
        if result then
            print("^5[void_test]^7 Server callback result received:")
            print(("^5[void_test]^7 Time: %s"):format(result.time))
            print(("^5[void_test]^7 Framework: %s"):format(result.framework))
            print(("^5[void_test]^7 Inventory: %s"):format(result.inventory))
            print(("^5[void_test]^7 Banking: %s"):format(result.banking))
            print(("^5[void_test]^7 Received Arg: %s"):format(result.receivedArg))
        else
            print("^1[void_test] Failed to receive server callback result.^7")
        end
    end, "Hello Server!")
    
    -- Test Player Data Retrieval
    local playerData = Bridge.GetPlayerData()
    if playerData and playerData.name then
        print(("^5[void_test]^7 Client Player Name: %s"):format(playerData.name))
        print(("^5[void_test]^7 Client Job: %s (Grade %d)"):format(playerData.job.name, playerData.job.grade))
    else
        print("^5[void_test]^7 Waiting for standalone player data to sync...")
    end

    -- Diagnostic commands for client okokScripts exports
    RegisterCommand('testokoknotify_cl', function(source, args)
        print("^5[void_test]^7 Testing client OkokNotify...")
        exports['void_bridge']:OkokNotify("Notification Alert", "This is a client-side test message!", 5000, "info", true)
    end, false)

    RegisterCommand('testokokbilling_cl', function(source, args)
        print("^5[void_test]^7 Testing client OkokBilling exports...")
        local successInvoice = exports['void_bridge']:OkokBilling_CreateNewInvoice("mechanic")
        print(("^5[void_test]^7 okokBilling_CreateNewInvoice result: %s"):format(tostring(successInvoice)))

        exports['void_bridge']:OkokBilling_ToggleMyInvoices()
        exports['void_bridge']:OkokBilling_ToggleCreateInvoice()
    end, false)

    RegisterCommand('testokokrequests_cl', function(source, args)
        local localSource = GetPlayerServerId(PlayerId())
        print(("^5[void_test]^7 Testing client OkokRequests request menu (Target source ID: %d)..."):format(localSource))
        RegisterNetEvent('void_test:client:requestAccepted', function(param1)
            print(("^5[void_test]^7 Client request accepted event parameter: %s"):format(tostring(param1)))
        end)
        exports['void_bridge']:OkokRequests_RequestMenu(localSource, 12000, "Confirm Purchase", "Do you want to buy this vehicle for $50,000?", "void_test:client:requestAccepted", "client", "custom_plate_123", 1)
    end, false)

    RegisterCommand('testokokgarage_cl', function(source, args)
        print("^5[void_test]^7 Testing client OkokGarage exports...")
        local successKeys = exports['void_bridge']:OkokGarage_GiveKeys("PLATE123")
        print(("^5[void_test]^7 GiveKeys result: %s"):format(tostring(successKeys)))

        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle ~= 0 then
            local successLock = exports['void_bridge']:OkokGarage_LockVehicle(vehicle)
            print(("^5[void_test]^7 LockVehicle result: %s"):format(tostring(successLock)))
        else
            print("^5[void_test]^7 You must be in a vehicle to test LockVehicle.")
        end
    end, false)

    RegisterCommand('testokokchat_cl', function(source, args)
        print("^5[void_test]^7 Testing client OkokChat export...")
        exports['void_bridge']:OkokChat_Message("#d9534f", "#ffffff", "fas fa-skull-crossbones", "System Notice", "Global", "The server will restart in 5 minutes.")
    end, false)
end)

