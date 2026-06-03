# 🌌 void_bridge

A lightweight, high-performance, and framework-agnostic bridge for **FiveM** servers. It automatically detects and abstracts standard server frameworks and common resource dependencies, providing a single, unified scripting API for your resources.

By routing all interactions through `void_bridge`, any custom script you write will work seamlessly across different server environments without editing a single line of core logic.

---

## ✨ Features

- ⚙️ **Dynamic Auto-Detection**: Automatically detects active framework (**QBCore**, **ESX**, or **Standalone**) and started dependencies (**ox_inventory**, **qb-inventory**, **ox_target**, **qb-target**, and more) at runtime.
- 👤 **Unified Player Object**: Simplifies character details, job data, permissions, and cash/bank balances under a single interface.
- 💳 **Society & Banking Wrapper**: Standardizes transactions and automatically routes society funds to started management scripts.
- 📦 **Dynamic Stash & Inventory Controls**: Standardizes item addition, removal, weight validations, and checks.
- 🎯 **Targeting Interface**: Translates targeting parameters automatically between `ox_target`, `qb-target`, and `qtarget`.
- 📯 **Built-in Callback System (RPC)**: Includes a lightweight, thread-safe Remote Procedure Call mechanism to query server data from the client asynchronously.
- 💾 **State Variable Synchronization**: Fully supports session metadata storage (`GetMetaData` / `SetMetaData`) across QBCore, ESX, and Standalone modes.

---

## ⚙️ Configuration (`config.lua`)

The bridge allows forcing specific resources or enabling dynamic runtime detection:

```lua
Config = {}
Config.Debug = true -- Print diagnostic logs on startup

Config.Framework = "auto" -- "auto" (QBCore/ESX/Standalone detection), "qbcore", "esx", "standalone"
Config.Inventory = "auto" -- "auto", "ox_inventory", "qb-inventory", "qs-inventory", "standalone"
Config.Target = "auto"    -- "auto", "ox_target", "qb-target", "qtarget", "none"
Config.Notify = "auto"    -- "auto", "ox_lib", "qbcore", "esx", "okokNotify", "standalone"
Config.Banking = "auto"   -- "auto", "qb-banking", "pefcl", "okBanking", "esx", "qbcore", "standalone"
Config.Lib = "auto"       -- "auto", "ox_lib", "none"
```

---

## 🚀 API Documentation

### Initializing the Bridge
Retrieve the bridge instance at the top of your scripts:
```lua
local Bridge = exports['void_bridge']:GetBridge()
```

### 👤 Player Methods (Server-Side)
```lua
local player = Bridge.GetPlayer(source)
if player then
    local pData = player.GetData()
    print(pData.name)        -- Unified display name
    print(pData.citizenid)   -- Unified citizen/character ID
    print(pData.job.name)    -- Unified job name
    print(pData.job.grade)   -- Unified job grade (integer)

    -- Financial manipulations
    player.AddMoney("cash", 1000, "Bonus reward")
    player.RemoveMoney("bank", 500, "Store purchase")
    local balance = player.GetMoney("bank")

    -- Session Metadata (Persisted dynamically)
    player.SetMetaData("jailtime", 60)
    local remaining = player.GetMetaData("jailtime")
end
```

### 🎯 Targeting (Client-Side)
Register zones or model interactions uniformly:
```lua
-- Box Zone Interaction
Bridge.Target.AddBoxZone("town_hall_desk", vector3(-540.0, -200.0, 38.0), vector3(1.5, 1.5, 2.0), 0.0, {
    options = {
        {
            icon = "fas fa-id-card",
            label = "Renew ID Card",
            action = function()
                print("Interacted desk!")
            end
        }
    },
    distance = 2.0
})

-- Model Interaction
Bridge.Target.AddTargetModel({ `s_m_y_barman_01` }, {
    options = {
        {
            icon = "fas fa-glass-martini",
            label = "Buy Drink",
            event = "bar:client:openMenu"
        }
    },
    distance = 2.5
})
```

### 📦 Inventory Interactions (Server-Side)
```lua
-- Check if player has item
if Bridge.Inventory.HasItem(source, "water_bottle", 1) then
    -- Remove item
    Bridge.Inventory.RemoveItem(source, "water_bottle", 1)
    
    -- Notify player
    Bridge.Notify(source, "You drank refreshing water.", "success")
else
    Bridge.Notify(source, "You don't have any water!", "error")
end
```

### 📯 Callback (RPC) System
Query server data from the client asynchronously:

**Server Registration:**
```lua
Bridge.RegisterServerCallback('my_resource:server:checkLicense', function(source, cb, licenseType)
    local player = Bridge.GetPlayer(source)
    -- Your logic to verify licenses
    local hasLicense = true 
    cb(hasLicense)
end)
```

**Client Trigger:**
```lua
Bridge.TriggerServerCallback('my_resource:server:checkLicense', function(hasLicense)
    if hasLicense then
        print("Player has the license!")
    end
end, "drivers_license")
```

---

## 📋 Installation

1. Clone or download `void_bridge` into your server's `resources/` directory.
2. In your `server.cfg`, start the resource **before** any scripts that rely on it:
   ```cfg
   ensure void_bridge
   ensure void_market
   ensure void_shops
   ensure void_prison
   ```
3. Start the server. The startup diagnostics will print your automatically resolved server parameters:
   ```
   ================= VOID_BRIDGE ENVIRONMENT =================
   [void_bridge] Framework: qbcore
   [void_bridge] Inventory: ox_inventory
   [void_bridge] Notification: ox_lib
   [void_bridge] Banking: qbcore
   ===========================================================
   ```
