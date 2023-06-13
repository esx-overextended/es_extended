Config                             = {}
Config.EnableDebug                 = false -- Use Debug options? (Keep in mind only set this to true when *not* running on production/live server as multiple accounts with similar rockstar license can join the server)

Config.Locale                      = GetConvar("esx:locale", "en")

Config.MapName                     = "Los Santos"
Config.GameType                    = "ESX Overextended"

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

Config.EnablePaycheck              = true      -- enable paycheck
Config.EnableSocietyPayouts        = false     -- pay from the society account that the player is employed at? Requirement: esx_society
Config.EnableHud                   = true      -- enable the default hud? Display current job and accounts (black, bank & cash)
Config.HudButton                   = "GRAVE"   -- button to show/hide hud. Only works if Config.EnableHud is true (https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard)
Config.MaxWeight                   = 30        -- the max inventory weight without backpack
Config.PaycheckInterval            = 7 * 60000 -- how often to recieve pay checks in milliseconds
Config.EnableDefaultInventory      = true      -- Display the default Inventory ( F2 )
Config.EnableWantedLevel           = false     -- Use Normal GTA wanted Level?
Config.EnablePVP                   = true      -- Allow Player to player combat

Config.Multichar                   = true      -- true when using multicharacter, false when not
Config.Identity                    = true      -- Select a characters identity data before they have loaded in (this happens by default with multichar)
Config.DistanceGive                = 4.0       -- Max distance when giving items, weapons etc.

Config.DisableHealthRegeneration   = false     -- Player will no longer regenerate health
Config.DisableVehicleRewards       = false     -- Disables Player Recieving weapons from vehicles
Config.DisableNPCDrops             = false     -- stops NPCs from dropping weapons on death
Config.DisableDispatchServices     = false     -- Disable Dispatch services
Config.DisableScenarios            = false     -- Disable Scenarios
Config.DisableWeaponWheel          = false     -- Disables default weapon wheel
Config.DisableAimAssist            = false     -- disables AIM assist (mainly on controllers)
Config.DisableVehicleSeatShuff     = false     -- Disables vehicle seat shuff
Config.RemoveHudCommonents         = {
    [1] = false,                               --WANTED_STARS,
    [2] = false,                               --WEAPON_ICON
    [3] = false,                               --CASH
    [4] = false,                               --MP_CASH
    [5] = false,                               --MP_MESSAGE
    [6] = false,                               --VEHICLE_NAME
    [7] = false,                               -- AREA_NAME
    [8] = false,                               -- VEHICLE_CLASS
    [9] = false,                               --STREET_NAME
    [10] = false,                              --HELP_TEXT
    [11] = false,                              --FLOATING_HELP_TEXT_1
    [12] = false,                              --FLOATING_HELP_TEXT_2
    [13] = false,                              --CASH_CHANGE
    [14] = false,                              --RETICLE
    [15] = false,                              --SUBTITLE_TEXT
    [16] = false,                              --RADIO_STATIONS
    [17] = false,                              --SAVING_GAME,
    [18] = false,                              --GAME_STREAM
    [19] = false,                              --WEAPON_WHEEL
    [20] = false,                              --WEAPON_WHEEL_STATS
    [21] = false,                              --HUD_COMPONENTS
    [22] = false,                              --HUD_WEAPONS
}

Config.SpawnVehMaxUpgrades         = true       -- admin vehicles spawn with max vehicle settings
Config.CustomAIPlates              = "ESX1OX1." -- Custom plates for AI vehicles
Config.PlatePattern                = "........" -- Plate pattern for manually spawned vehicles
-- Pattern string format
--1 will lead to a random number from 0-9.
--A will lead to a random letter from A-Z.
-- . will lead to a random letter or number, with 50% probability of being either.
--^1 will lead to a literal 1 being emitted.
--^A will lead to a literal A being emitted.
--Any other character will lead to said character being emitted.
-- A string shorter than 8 characters will be padded on the right.

Config.DefaultNotificationPosition = "center-right" -- "top" | "top-right" | "top-left" | "bottom" | "bottom-right" | "bottom-left" | "center-right" | "center-left"
Config.DefaultTextUIPosition       = "left-center"  -- "right-center" | "left-center" | "top-center"
Config.DefaultProgressBarType      = "bar"          -- "bar" or "circle"
Config.DefaultProgressBarPosition  = "bottom"       -- "middle" or "bottom"
