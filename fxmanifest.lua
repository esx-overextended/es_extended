fx_version "cerulean"
game "gta5"
lua54 "yes"

description "ESX Overextended"
version "0.1.0"

shared_scripts {
    "@ox_lib/init.lua",
    "locale.lua",
    "locales/*.lua",

    "config.lua",
    "config.weapons.lua",
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "config.logs.lua",
    "server/common.lua",
    "common/**/*.lua",
    "server/modules/*.lua",
    "server/classes/**/*.lua",
    "server/player_events.lua",
    "server/functions.lua",
    "server/onesync.lua",
    "server/paycheck.lua",
    "server/main.lua",
    "server/commands.lua"
}

client_scripts {
    "client/common.lua",
    "client/functions.lua",
    "common/**/*.lua",
    "client/modules/*.lua",
    "client/player_events.lua",
    "client/wrapper.lua",
    "client/main.lua"
}

ui_page {
    "html/ui.html"
}

files {
    "imports.lua",
    "locale.js",

    "files/*.*",

    "html/ui.html",
    "html/css/app.css",
    "html/js/mustache.min.js",
    "html/js/wrapper.js",
    "html/js/app.js",
    "html/fonts/pdown.ttf",
    "html/fonts/bankgothic.ttf",
    "html/img/accounts/bank.png",
    "html/img/accounts/black_money.png",
    "html/img/accounts/money.png"
}

dependencies {
    "/native:0x6AE51D4B",
    "oxmysql",
    "spawnmanager",
}
