Config, Locales = {}, {}

-- Language used by the resource locale files.
Config.Locale = 'en'

-- Enables extra console output for troubleshooting.
Config.Debug = false

-- Automatically detects qb-core or es_extended when set to auto.
Config.Framework = 'auto'

-- Prefix used for this resource events and callbacks.
Config.EventPrefix = 'rs-bossmenu'

-- Creates required SQL tables automatically on resource start.
Config.AutoAddDatabaseTables = true

-- Creates fallback society rows automatically when needed.
Config.AutoCreateSociety = true

-- Society system to use.
-- auto / renewed-banking / qb-management / qb-banking / esx_addonaccount / fallback
Config.SocietySystem = 'renewed-banking'

-- Inventory system to use.
-- auto / ox_inventory / qb-inventory
Config.InventorySystem = 'auto'

-- Target system to use.
-- ox-target / qb-target
Config.TargetSystem = 'ox-target'

-- Clothing system to use.
-- auto / illenium-appearance / qb-clothing
Config.ClothingSystem = 'auto'

-- Command used to open the boss menu.
Config.OpenBossMenuCommand = 'bossmenu'

-- Default keybind used to open the boss menu.
Config.OpenBossMenuKey = 'F6'

-- Enables command access for the boss menu.
Config.UseCommand = true

-- Enables target zones for boss menu locations.
Config.UseTarget = true

-- Enables marker interaction instead of target-only access.
Config.UseMarkers = false

-- Currency symbol shown in the UI.
Config.Currency = '$'

-- Cash given to an online employee after being fired.
Config.DefaultPaymentAfterFire = 50

-- Maximum distance allowed when hiring a nearby player.
Config.HireDistance = 3.0

-- Distance at which boss markers become visible.
Config.MarkerDistance = 10.0

-- Marker type used for boss marker interaction.
Config.MarkerId = 21

-- Marker scale used for boss marker interaction.
Config.MarkerScale = vec3(0.25, 0.25, 0.25)

-- Marker color used for boss marker interaction.
Config.MarkerColor = { r = 66, g = 133, b = 244, a = 170 }

-- Uses framework boss flags before falling back to configured grade names.
Config.UseFrameworkBoss = true

-- Grade names allowed to access the boss menu when framework boss flags are not available.
Config.BossGradeNames = { 'boss', 'chief', 'owner', 'manager' }

-- Grade levels allowed to access the boss menu when needed.
Config.BossGradeLevels = {}

-- Quick finance action amounts shown in the UI.
Config.QuickAmounts = { 500, 1000, 2500, 5000 }

-- Inventory configuration.
Config.Inventory = {
    stashes = {
        enabled = true,
        ox = 'ox_inventory',
        qb = 'qb-inventory',
        defaultSlots = 100,
        defaultMaxWeight = 400000,
        defaultLabel = 'Society Stash',
        prefix = 'bossstash_'
    }
}

-- Wardrobe integration configuration.
Config.Wardrobe = {
    enabled = true,
    illeniumEvent = 'illenium-appearance:client:openOutfitMenu',
    qbClothingEvent = 'qb-clothing:client:openOutfitMenu'
}

-- Job locations and per-job stash settings.
Config.JobLocations = {
    police = {
        label = 'Police Department',
        bossCoords = { vector3(0,0,0) },
        dutyCoords = { vector3(463.7565, -953.9496, 30.2611) },
        stash = {
            label = 'Police Society Stash',
            slots = 150,
            maxWeight = 600000
        }
    },
    underground = {
        label = 'Underground Mechanic',
        bossCoords = { vector3(0,0,0) },
        dutyCoords = { vector3(-941.19964599609, -769.28167724609, 14.627556800842) },
        stash = {
            label = 'Underground Backroom',
            slots = 90,
            maxWeight = 300000
        }
    },
    mechanic = {
        label = 'Sun Rise Mechanic',
        bossCoords = { vector3(0,0,0) },
        dutyCoords = { vector3(-349.94802856445, -145.84269714355, 39.003910064697) },
        stash = {
            label = 'Sun Rise Backroom',
            slots = 90,
            maxWeight = 300000
        }
    },
    mosleys = {
        label = 'Mosleys Mechanic',
        bossCoords = { vector3(0,0,0) },
        dutyCoords = { vector3(-34.543643951416, -1670.1405029297, 29.308471679688) },
        stash = {
            label = 'Mosleys Mechanic',
            slots = 90,
            maxWeight = 300000
        }
    },
    eastcustoms = {
        label = 'East Customs Mechanic',
        bossCoords = { vector3(0,0,0) },
        dutyCoords = { vector3(874.96856689453, -2100.9064941406, 30.48561668396) },
        stash = {
            label = 'East Customs Mechanic',
            slots = 90,
            maxWeight = 300000
        }
    },
    paleto = {
        label = 'Paleto Mechanic',
        bossCoords = { vector3(0,0,0) },
        dutyCoords = { vector3(95.83659362793, 6528.662109375, 30.852798461914) },
        stash = {
            label = 'Paleto Mechanic',
            slots = 90,
            maxWeight = 300000
        }
    },
    sadot = {
        label = 'SADOT',
        bossCoords = { vector3(0,0,0) },
        dutyCoords = { vector3(953.94427490234, -1466.5134277344, 31.440958023071) },
        stash = {
            label = 'SADOT',
            slots = 90,
            maxWeight = 300000
        }
    },
}
