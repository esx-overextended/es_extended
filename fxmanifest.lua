fx_version 'adamant'

game 'gta5'

description 'ESX Overextended'

lua54 'yes'
version '1.9.4'

shared_scripts {
    '@ox_lib/init.lua',
    'locale.lua',
    'locales/*.lua',

    'config.lua',
    'config.weapons.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.logs.lua',
    'server/common.lua',
    'server/modules/*.lua',
    'server/classes/**/*.lua',
    'server/player_events.lua',
    'server/functions.lua',
    'server/onesync.lua',
    'server/paycheck.lua',
    'server/main.lua',
    'server/commands.lua',

    'common/**/*.lua',
}

client_scripts {
    'client/common.lua',
    'client/functions.lua',
    'client/modules/*.lua',
    'client/player_events.lua',
    'client/wrapper.lua',
    'client/main.lua',

    'common/**/*.lua',
}

ui_page {
    'html/ui.html'
}

files {
    'imports.lua',
    'locale.js',
    'html/ui.html',

    'html/css/app.css',

    'html/js/mustache.min.js',
    'html/js/wrapper.js',
    'html/js/app.js',

    'html/fonts/pdown.ttf',
    'html/fonts/bankgothic.ttf',
}

dependencies {
    '/native:0x6AE51D4B',
    'oxmysql',
    'spawnmanager',
}
