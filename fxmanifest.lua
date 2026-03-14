fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rs-bossmenu'
author 'NRG development'
description 'Premium boss menu with modern NUI, society banking, employee management, and job utilities'
version '1.0.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/app.js',
    'web/style.css'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/en.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'oxmysql'
}
