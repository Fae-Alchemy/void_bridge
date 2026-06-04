fx_version 'cerulean'
game 'gta5'

author 'Fae_Alchemy'
description 'A lightweight, framework-agnostic bridge for custom scripts'
version '1.0.1'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/rpc.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/player.lua',
    'server/rpc.lua'
}

dependencies {
    'ox_lib'
}

exports {
    'GetBridge',
    'OkokNotify',
    'OkokBanking_GetAccount',
    'OkokBanking_AddMoney',
    'OkokBanking_RemoveMoney',
    'OkokBanking_AddTransaction',
    'OkokBilling_CreateCustomInvoice',
    'OkokBilling_CreateNewInvoice',
    'OkokBilling_ToggleMyInvoices',
    'OkokBilling_ToggleCreateInvoice',
    'OkokRequests_RequestMenu',
    'OkokGarage_GiveKeys',
    'OkokGarage_SetVehicleStolen',
    'OkokGarage_LockVehicle',
    'OkokChat_Message',
    'AlertPolice'
}


