fx_version 'cerulean'
game 'gta5'

author 'Fae_Alchemy'
description 'A lightweight, framework-agnostic bridge for custom scripts'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/rpc.lua'
}

server_scripts {
    'server/main.lua',
    'server/player.lua',
    'server/rpc.lua'
}

dependencies {
    'ox_lib'
}

exports {
    'GetBridge'
}
