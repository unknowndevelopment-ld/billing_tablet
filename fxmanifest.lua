fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'billing_tablet'
description 'billing tablet'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}
client_script 'client/main.lua'
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'web/dist/index.html'
files {
    'web/dist/index.html',
    'web/dist/assets/*'
}

dependencies { 'es_extended', 'esx_addonaccount', 'oxmysql', 'ox_lib' }
