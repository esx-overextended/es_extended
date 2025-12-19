fx_version "cerulean"
use_experimental_fxv2_oal "yes"
game "gta5"
lua54 "yes"

description "ESX Overextended"
version "0.5.3"

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
    "server/functions.lua",
    "modules/**/*shared*.lua",
    "modules/**/*server*.lua",
    "server/classes/**/*.lua",
    "server/events.lua",
    "server/paycheck.lua",
    "server/main.lua",
    "server/commands.lua"
}

client_scripts {
    "client/common.lua",
    "client/functions.lua",
    "modules/**/*shared*.lua",
    "modules/**/*client*.lua",
    "client/events.lua",
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
    "files/vehicle-images/*.*",

    "html/ui.html",
    "html/css/*.css",
    "html/js/*.js",
    "html/fonts/*.ttf",
    "html/img/**/*.png"
}

dependencies {
    "/server:23683",
    "/gameBuild:3717",
    "oxmysql"
}
