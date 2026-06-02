Config = {}

-- Enable debug print logs in the console
Config.Debug = true

-- Main Server Framework Configuration
-- Toggles: "auto" (auto-detects started framework), "qbcore", "esx", "standalone"
Config.Framework = "auto"

-- Inventory Configuration
-- Toggles: "auto" (auto-detects started inventory), "ox_inventory", "qb-inventory", "qs-inventory", "standalone"
Config.Inventory = "auto"

-- Target Interaction System
-- Toggles: "auto", "ox_target", "qb-target", "qtarget", "none"
Config.Target = "auto"

-- Notification System
-- Toggles: "auto", "ox_lib", "qbcore", "esx", "okokNotify", "standalone"
Config.Notify = "auto"

-- Banking Resource
-- Toggles: "auto", "qb-banking", "pefcl", "okBanking", "esx", "qbcore", "standalone"
Config.Banking = "auto"

-- Garage System Configuration
-- Toggles: "auto", "jg-advancedgarage", "qs-advancedgarages", "qb-garage", "esx_garage", "standalone"
Config.Garage = "auto"

-- Utility Library (e.g. ox_lib for progress bars, dialogs, menus, etc.)
-- Toggles: "auto", "ox_lib", "none"
Config.Lib = "auto"

-- Default settings for notifications (used if fallback to standalone is active)
Config.DefaultNotificationDuration = 5000 -- ms
