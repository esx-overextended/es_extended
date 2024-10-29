Config                             = {}
Config.EnableDebug                 = false -- Use Debug options? (Keep in mind only set this to true when *not* running on production/live server as multiple accounts with similar rockstar license can join the server)

Config.MapName                     = "Los Santos"
Config.GameType                    = "ESX Overextended"

Config.Locale                      = GetConvar("esx:locale", "en")
Config.Identifier                  = GetConvar("esx:identifier", "license")

Config.Accounts                    = {
    bank = {
        label = _U("account_bank"),
        round = true
    },
    money = {
        label = _U("account_money"),
        round = true
    },
    black_money = {
        label = _U("account_black_money"),
        round = true
    }
}

Config.AdminGroups                 = { -- The order is *IMPORTANT*. The top group will have the highest permissions, while the bottom one will have the lowest perms
    "superadmin",
    "admin"
}

Config.StartingAccountMoney        = { bank = 10000, money = 1000 }

Config.DefaultSpawn                = { x = -269.4, y = -955.3, z = 31.2, heading = 205.8 }

Config.CIDPattern                  = "A.1ESX1.A"                                         -- Patern for characters' unique id(cid) to be generated (refer to Pattern String Format found below)

Config.EnablePaycheck              = true                                                -- enable paycheck
Config.EnableSocietyPayouts        = false                                               -- pay from the society account that the player is employed at? Requirement: esx_society
Config.EnableHud                   = true                                                -- enable the default hud? Display current job and accounts (black, bank & cash)
Config.HudButton                   = "GRAVE"                                             -- button to show/hide hud. Only works if Config.EnableHud is true (https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard)
Config.MaxWeight                   = 30                                                  -- the max inventory weight without backpack
Config.PaycheckInterval            = 15 * 60000                                          -- how often to recieve pay checks in milliseconds (defaults to every 15 minutes)
Config.EnableDefaultInventory      = true                                                -- Display the default Inventory ( F2 )

Config.Multichar                   = GetResourceState("esx_multicharacter") ~= "missing" -- Automatically detects if multicharacter is available to use or not
Config.Identity                    = true                                                -- Select a characters identity data before they have loaded in (this happens by default with multichar)
Config.DistanceGive                = 4.0                                                 -- Max distance when giving items, weapons etc.

Config.SpawnVehMaxUpgrades         = true                                                -- admin vehicles spawn with max vehicle settings
Config.CustomAIPlates              = "ESX1OX1."                                          -- Custom plates for AI vehicles (maximum 8 characters)
Config.PlatePattern                = "........"                                          -- Plate pattern for manually spawned vehicles (maximum 8 characters) (refer to Pattern String Format found below)

Config.DefaultNotificationPosition = "center-right"                                      -- "top" | "top-right" | "top-left" | "bottom" | "bottom-right" | "bottom-left" | "center-right" | "center-left"
Config.DefaultTextUIPosition       = "left-center"                                       -- "right-center" | "left-center" | "top-center"
Config.DefaultProgressBarType      = "bar"                                               -- "bar" or "circle"
Config.DefaultProgressBarPosition  = "bottom"                                            -- "middle" or "bottom"

Config.VehicleParser               = {                                                   -- Refer to https://esx-overextended.github.io/es_extended/Commands/parseVehicles (You also need to run screenshot-basic, and adjust the Discord VehicleImage's webhook address inside config.logs.lua for vehicles image data to be generated)
    Position = vector4(-144.67, -593.51, 211.39, 124.72),
    Cam = {
        Name = "DEFAULT_SCRIPTED_CAMERA",
        Coords = vector3(-145.2, -598.16, 212.2),
        Rotation = vector3(0.0),
        FOV = 65.0,
        Active = false,
        RotationOrder = 0
    }
}

-- #Pattern String Format#
-- 1 will lead to a random number from 0-9.
-- A will lead to a random letter from A-Z.
-- . will lead to a random letter or number, with 50% probability of being either.
-- ^1 will lead to a literal 1 being emitted.
-- ^A will lead to a literal A being emitted.
-- Any other character will lead to said character being emitted.
