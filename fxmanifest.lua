fx_version 'cerulean'
game 'gta5'

description 'A vehicle tracker system made for QBCore'
version '1.0.0'


shared_scripts {
    'config.lua'
}

server_script {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'qb-core',
    'qb-inventory'
}

lua54 'yes'
use_fxv2_oal 'yes'
