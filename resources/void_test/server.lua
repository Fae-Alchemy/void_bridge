local Bridge = exports['void_bridge']:GetBridge()

CreateThread(function()
    Wait(500) -- Wait for bridge initialization
    print("^5[void_test]^7 Initializing Server Test...")
    
    -- Verify framework type
    print(("^5[void_test]^7 Active Framework: %s"):format(Bridge.GetFramework()))

    -- Register a test callback
    Bridge.RegisterServerCallback('void_test:server:getSystemData', function(source, cb, arg1)
        print(("^5[void_test]^7 Server callback triggered by ID %d with argument: %s"):format(source, tostring(arg1)))
        cb({
            framework = Bridge.GetFramework(),
            inventory = Bridge.Inventory.GetSystem(),
            banking = Bridge.Banking.GetSystem(),
            time = os.time(),
            receivedArg = arg1
        })
    end)
    
    -- Register a command to test money additions (standalone testing helper)
    RegisterCommand('addmoneytest', function(source, args)
        local src = source
        if src == 0 then print("This command must be run by a player.") return end
        
        local amount = tonumber(args[1]) or 100
        local player = Bridge.GetPlayer(src)
        if player then
            local balanceBefore = player.GetMoney("cash")
            player.AddMoney("cash", amount, "Test Command")
            local balanceAfter = player.GetMoney("cash")
            print(("^5[void_test]^7 Cash adjusted for %s from $%d to $%d"):format(player.GetData().name, balanceBefore, balanceAfter))
        end
    end, false)
end)
