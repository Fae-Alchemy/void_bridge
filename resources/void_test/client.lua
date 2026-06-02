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
end)
