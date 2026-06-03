fx_version 'cerulean'
game 'gta5'

author 'Fae_Alchemy'
description 'Test resource to validate void_bridge features'
version '1.0.0'

dependencies {
    'void_bridge'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}
