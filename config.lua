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
-- auto / renewed-banking / okokbanking / qb-management / qb-banking / esx_addonaccount / fallback
Config.SocietySystem = 'okokbanking'

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
Config.UseCommand = false

-- Enables a standalone time sheet command.
Config.UseTimeSheetCommand = false

-- Command used to open the time sheet page.
Config.TimeSheetCommand = 'timesheet'

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
    ['police'] = {
        bossCoords = {
            vector3(-1857.309570, -338.183960, 34.709202)
        },
        dutyCoords = {
            vector3(-1845.401001, -344.176849, 49.826473)
        }
    },

    ['bcso'] = {
        bossCoords = {
            vector3(-461.422821, 7116.516602, 22.383671)
        },
        dutyCoords = {
            vector3(-474.566284, 7103.724609, 22.383684)
        }
    },

    ['ambulance'] = {
        bossCoords = {
            vector3(336.997314, -1416.344238, 38.028152)
        },
        dutyCoords = {
            vector3(350.861633, -1412.150513, 32.510262)
        }
    },

    ['mechanic'] = {
        bossCoords = {
            vector3(-305.833008, -150.014038, 40.349735)
        },
        dutyCoords = {
            vector3(-311.839966, -161.571976, 40.349735)
        }
    },

    ['vape'] = {
        bossCoords = {
            vector3(-498.518311, 296.077209, 84.122322)
        },
        dutyCoords = {
            vector3(-499.692108, 294.196136, 83.315933)
        }
    },

    ['bakery'] = {
        bossCoords = {
            vector3(62.285927, -132.102692, 55.464058)
        },
        dutyCoords = {
            vector3(55.088005, -133.349045, 55.463421)
        }
    },

    ['hornys'] = {
        bossCoords = {
            vector3(1238.314331, -348.801147, 69.082161)
        },
        dutyCoords = {
            vector3(1244.019531, -354.610565, 69.082161)
        }
    },

    ['catcafe'] = {
        bossCoords = {
            vector3(-577.575012, -1067.577515, 26.614079)
        },
        dutyCoords = {
            vector3(-585.231445, -1055.875244, 22.344204)
        }
    },

    ['bahamamamas'] = {
        bossCoords = {
            vector3(-1376.663696, -621.882080, 35.896198)
        },
        dutyCoords = {
            vector3(-1388.221191, -591.509033, 30.214043)
        }
    },

    ['pizza'] = {
        bossCoords = {
            vector3(797.235291, -750.699768, 31.265902)
        },
        dutyCoords = {
            vector3(811.076843, -756.873474, 26.780849)
        }
    },

    ['burgershot'] = {
        bossCoords = {
            vector3(-1198.184326, -897.743103, 13.798368)
        },
        dutyCoords = {
            vector3(-1177.716187, -897.245300, 13.798384)
        }
    },

    ['beanmachine'] = {
        bossCoords = {
            vector3(-628.219788, 225.092041, 81.881996)
        },
        dutyCoords = {
            vector3(-634.558960, 228.060852, 81.882011)
        }
    },
}