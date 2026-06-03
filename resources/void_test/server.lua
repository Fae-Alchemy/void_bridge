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

    -- Auto-debug database structure on startup
    CreateThread(function()
        Wait(2000)
        print("^5[void_test]^7 Querying player_vehicles structure...")
        MySQL.query("DESCRIBE player_vehicles", {}, function(columns)
            if columns then
                print("^5[void_test]^7 Columns in player_vehicles:")
                for _, col in ipairs(columns) do
                    print(("- Column: %s, Type: %s"):format(col.Field, col.Type))
                end
            else
                print("^1[void_test]^7 Failed to describe player_vehicles table.^7")
            end
        end)
        
        MySQL.query("SELECT * FROM player_vehicles LIMIT 10", {}, function(rows)
            if rows then
                print(("^5[void_test]^7 Found %d rows in player_vehicles:"):format(#rows))
                for idx, row in ipairs(rows) do
                    print(("- Row %d: citizenid=%s, plate=%s, vehicle=%s, state=%s, garage=%s, stored=%s"):format(idx, tostring(row.citizenid), tostring(row.plate), tostring(row.vehicle), tostring(row.state), tostring(row.garage), tostring(row.stored)))
                end
            else
                print("^1[void_test]^7 Failed to query rows from player_vehicles table.^7")
            end
        end)
    end)

    -- Diagnostic commands for server okokScripts exports
    RegisterCommand('testokoknotify_sv', function(source, args)
        local src = source
        if src == 0 then src = 1 end
        print("^5[void_test]^7 Testing server OkokNotify...")
        exports['void_bridge']:OkokNotify(src, "Test Title", "Hello via OkokNotify Server Export!", 5000, "success", true)
    end, false)

    RegisterCommand('testokokbanking_sv', function(source, args)
        local src = source
        print("^5[void_test]^7 Testing server OkokBanking exports...")
        local acc = exports['void_bridge']:OkokBanking_GetAccount("police")
        print(("^5[void_test]^7 okokBanking_GetAccount result: %s"):format(tostring(acc)))
        
        local successAdd = exports['void_bridge']:OkokBanking_AddMoney("police", 500)
        print(("^5[void_test]^7 okokBanking_AddMoney result: %s"):format(tostring(successAdd)))

        local successRemove = exports['void_bridge']:OkokBanking_RemoveMoney("police", 200)
        print(("^5[void_test]^7 okokBanking_RemoveMoney result: %s"):format(tostring(successRemove)))
    end, false)

    RegisterCommand('testokokbilling_sv', function(source, args)
        local src = source
        if src == 0 then src = 1 end
        print("^5[void_test]^7 Testing server OkokBilling custom invoice...")
        local success = exports['void_bridge']:OkokBilling_CreateCustomInvoice(src, 1500, "Towing Service Charge", "Mechanic Shop", "mechanic", "Downtown Customs")
        print(("^5[void_test]^7 okokBilling_CreateCustomInvoice success state: %s"):format(tostring(success)))
    end, false)

    RegisterCommand('testokokrequests_sv', function(source, args)
        local src = source
        if src == 0 then src = 1 end
        print("^5[void_test]^7 Testing server OkokRequests request menu...")
        RegisterNetEvent('void_test:server:requestAccepted', function(param1, param2)
            print(("^5[void_test]^7 Request accepted event parameters: %s, %s"):format(tostring(param1), tostring(param2)))
        end)
        exports['void_bridge']:OkokRequests_RequestMenu(src, 10000, "Job Offer", "Would you like to join the mechanic shop?", "void_test:server:requestAccepted", "server", "mechanic,john_doe", 2)
    end, false)

    RegisterCommand('testokokgarage_sv', function(source, args)
        print("^5[void_test]^7 Testing server OkokGarage exports...")
        local okKeys = exports['void_bridge']:OkokGarage_GiveKeys(source, "TESTPLATE")
        local okStolen = exports['void_bridge']:OkokGarage_SetVehicleStolen("TESTPLATE")
        print(("^5[void_test]^7 GiveKeys result: %s | SetVehicleStolen result: %s"):format(tostring(okKeys), tostring(okStolen)))
    end, false)

    RegisterCommand('testokokchat_sv', function(source, args)
        local src = source
        if src == 0 then src = 1 end
        print("^5[void_test]^7 Testing server OkokChat export...")
        exports['void_bridge']:OkokChat_Message(src, "#1e1e24", "#ffffff", "fas fa-shield-alt", "Dispatch", "LSPD Control", "A robbery has been reported in Sandy Shores!")
    end, false)
end)

