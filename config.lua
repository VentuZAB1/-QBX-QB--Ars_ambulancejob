lib.locale()

Config                         = {}

Config.Debug                   = false
Config.DebugDistressCalls      = false  -- Enable debug logging for distress call system

Config.ClothingScript          = 'false' -- 'illenium-appearance', 'fivem-appearance' ,'core' or false -- to disable
Config.EmsJobs                 = { "ambulance", "ems" }
Config.RespawnTime             = 0                     -- in minutes
Config.UseInterDistressSystem  = true
Config.WaitTimeForNewCall      = 5                     -- minutes

Config.ReviveCommand           = "revive"
Config.ReviveAreaCommand       = "revivearea"
Config.HealCommand             = "heal"
Config.HealAreaCommand         = "healarea"
Config.ReviveAllCommand        = "reviveall"

Config.AdminGroup              = "group.admin"

Config.MedicBagProp            = "xm_prop_x17_bag_med_01a"
Config.MedicBagItem            = "medicalbag"

Config.HelpCommand             = "112"
Config.RemoveItemsOnRespawn    = true

Config.ReviveReward            = 700 -- reward for reviving dead players with defibrillator
Config.BandageHealReward       = 100 -- reward for all bandage healing (injuries and health restoration)

Config.ParamedicTreatmentPrice = 4000
Config.AllowAlways             = true        -- false if you want it to work only when there are only medics online

Config.AmbulanceStretchers     = 2           -- how many stretchers should an ambunalce have
Config.ConsumeItemPerUse       = 10          -- every time you use an item it gets used by 10%

Config.TimeToWaitForCommand    = 2           -- when player dies he needs to wait 2 minutes to do the ambulance command
Config.NpcReviveCommand        = "ambulance" -- this will work only when there are no medics online

Config.UsePedToDepositVehicle  = false       -- if false the vehicle will instantly despawns
Config.ExtraEffects            = true        -- false >> disables the screen shake and the black and white screen

-- Health & Armor Persistence Configuration
Config.HealthArmorPersistence = {
    Enable = true,                          -- Enable health and armor saving/loading
    SaveInterval = 60,                      -- Save interval in seconds (60 = save every 60 seconds) - Increased for better performance
    MinHealthForAlive = 10,                 -- Minimum health percentage for alive players (10 = 10% of max health)
    Debug = false,                          -- Show debug messages for health/armor persistence
}

-- Performance Optimization Settings
Config.Performance = {
    DeathCheckInterval = 500,               -- Death detection check interval in ms (500 = check every 500ms)
    UIUpdateInterval = 1000,                -- Death UI update interval in ms (1000 = update every 1 second)
    AnimationCheckInterval = 1500,          -- Animation check interval in ms (1500 = check every 1.5 seconds)
    HealthChangeThreshold = 5,              -- Minimum health/armor change to trigger save (prevents spam)
}

-- Death UI Configuration
Config.DeathUI = {
    Timer = 1,                              -- Death timer in minutes (how long before respawn is available)
    LighteningOverlay = 30,                 -- White overlay opacity (0-255) to lighten the death effect (0 = no overlay, 255 = fully white)
    CircleScale = 1.2,                      -- Scale of the death circle (1.0 = normal size, 1.5 = 50% bigger)
    ShowMedicCallButton = true,             -- Show the G key to call medics
    MedicCallText = "НАТИСНЕТЕ [G] ЗА ДА УВЕДОМИТЕ МЕДИЦИТЕ", -- Text for medic call button
    Position = "bottom",                    -- Position of death UI: "bottom", "center", "top"
    RespawnText = "ЗАДРЪЖТЕ [E] ЗА ДА СЕ РЕСПАУНЕТЕ", -- Text for respawn button
    RespawnHoldTime = 5,                    -- Time in seconds to hold E key for respawn
    AutoDistressMessage = "Emergency! Player needs immediate medical assistance!", -- Automatic message sent to EMS
}

-- Distress Call Blip Configuration
Config.DistressBlip = {
    Enable = true,                          -- Enable automatic map blips for distress calls
    Sprite = 153,                           -- Blip sprite (153 = medical cross, 1 = person, 304 = ambulance)
    Color = 1,                              -- Blip color (1 = red, 2 = green, 3 = blue, etc.)
    Scale = 1.2,                            -- Blip size
    Flash = true,                           -- Make blip flash to get attention
    AutoRemoveTime = 10,                    -- Auto-remove blip after X minutes (0 = never auto-remove)
}

Config.EmsVehicles             = {           -- vehicles that have access to the props (cones and ecc..)
	'ambulance',
	'ambulance2',
}

Config.DeathAnimations         = {
    ["car"] = {
        dict = "veh@low@front_ps@idle_duck",
        clip = "sit"
    },
    ["normal"] = {
        dict = "dead",
        clip = "dead_a"
    },
    ["revive"] = {
        dict = "get_up@directional@movement@from_knees@action",
        clip = "getup_r_0"
    }
}

Config.AdminGroups = {
    'admin',
    'god',
    'mod'
}


Config.Hospitals = {
    ["phillbox"] = {
        paramedic = {
            model = "s_m_m_scientist_01",
            pos = vector4(-677.5258, 327.2603, 82.0831, 190.2770),
        },
        bossmenu = {
            pos = vector3(0,0,0),
            min_grade = 2
        },
        zone = {
            pos = vec3(-677.5258, 327.2603, 83.0831),
            size = vec3(200.0, 200.0, 200.0),
        },
        blip = {
            enable = true,
            name = 'Phillbox Hospital',
            type = 61,
            scale = 1.0,
            color = 2,
            pos = vector3(-677.5258, 327.2603, 83.0831),
        },
        respawn = {
            {
                bedPoint = vector4(-662.6974, 321.9169, 87.8046, 175.2151),
                spawnPoint = vector4(-661.7634, 321.2337, 88.0166, 189.6124),
            },
            -- {
            --     bedPoint = vector4(346.96, -590.64, 44.12, 338.0),
            --     spawnPoint = vector4(348.84, -583.36, 42.32, 68.24)
            -- },

		},
		stash = {
			-- ['ems_stash_1'] = {
			-- 	slots = 50,
			-- 	weight = 50, -- kg
			-- 	min_grade = 0,
			-- 	label = 'Ems stash',
			-- 	shared = true, -- false if you want to make everyone has a personal stash
			-- 	pos = vector3(0,0,0)
			-- }
		},
		pharmacy = {
			["ems_shop_1"] = {
				job = true,
				label = "Pharmacy",
				grade = 0, -- works only if job true
				pos = vector3(0,0,0),
				blip = {
					enable = false,
					name = 'Pharmacy',
					type = 61,
					scale = 0.7,
					color = 2,
					pos = vector3(0,0,0),
				},
				items = {
					{ name = 'bandage',       price = 10 },
					{ name = 'defibrillator', price = 10 },
				}
			},
			["ems_shop_2"] = {
				job = true,
				label = "Pharmacy",
				grade = 0, -- works only if job true
				pos = vector3(-665.6212, 320.0668, 83.0831),
				blip = {
					enable = false,
					name = 'Pharmacy',
					type = 61,
					scale = 0.3,
					color = 2,
					pos = vector3(0, 0, 0),
				},
				items = {
					{ name = 'bandage', price = 200 },
				    { name = 'defibrillator', price = 1000 }
				}
			},
		},
		garage = {
			['ems_garage_1'] = {
				pedPos = vector4(0,0,0,0),
				model = 'mp_m_weapexp_01',
				spawn = vector4(0,0,0,0),
				deposit = vector3(0,0,0),
				driverSpawnCoords = vector3(0,0,0),

				vehicles = {
					{
						label = 'Ambulance',
						spawn_code = 'ambulance',
						min_grade = 3,
						modifications = {} -- es. {color1 = {255, 12, 25}}
					},
				}
			}
		},
		clothes = {
			enable = false,
			pos = vector4(0,0,0,0),
			model = 'a_f_m_bevhills_01',
			male = {
				[1] = {
					['mask_1']    = 0,
					['mask_2']    = 0,
					['arms']      = 0,
					['tshirt_1']  = 15,
					['tshirt_2']  = 0,
					['torso_1']   = 86,
					['torso_2']   = 0,
					['bproof_1']  = 0,
					['bproof_2']  = 0,
					['decals_1']  = 0,
					['decals_2']  = 0,
					['chain_1']   = 0,
					['chain_2']   = 0,
					['pants_1']   = 10,
					['pants_2']   = 2,
					['shoes_1']   = 56,
					['shoes_2']   = 0,
					['helmet_1']  = 34,
					['helmet_2']  = 0,
					['glasses_1'] = 34,
					['glasses_2'] = 1,
				},
				[2] = {
					['mask_1']    = 0,
					['mask_2']    = 0,
					['arms']      = 0,
					['tshirt_1']  = 15,
					['tshirt_2']  = 0,
					['torso_1']   = 86,
					['torso_2']   = 0,
					['bproof_1']  = 0,
					['bproof_2']  = 0,
					['decals_1']  = 0,
					['decals_2']  = 0,
					['chain_1']   = 0,
					['chain_2']   = 0,
					['pants_1']   = 10,
					['pants_2']   = 2,
					['shoes_1']   = 56,
					['shoes_2']   = 0,
					['helmet_1']  = 34,
					['helmet_2']  = 0,
					['glasses_1'] = 34,
					['glasses_2'] = 1,
				},
			},
			female = {
				[1] = {
					['mask_1']    = 0,
					['mask_2']    = 0,
					['arms']      = 0,
					['tshirt_1']  = 15,
					['tshirt_2']  = 0,
					['torso_1']   = 86,
					['torso_2']   = 0,
					['bproof_1']  = 0,
					['bproof_2']  = 0,
					['decals_1']  = 0,
					['decals_2']  = 0,
					['chain_1']   = 0,
					['chain_2']   = 0,
					['pants_1']   = 10,
					['pants_2']   = 2,
					['shoes_1']   = 56,
					['shoes_2']   = 0,
					['helmet_1']  = 34,
					['helmet_2']  = 0,
					['glasses_1'] = 34,
					['glasses_2'] = 1,
				},
			},
		},
	},
}


Config.BodyParts = {

	-- ["0"] = { id = "hip", label = "Damaged Hipbone", levels = { ["default"] = "Damaged", ["10"] = "Damaged x2", ["20"] = "Damaged x3", ["30"] = "Damaged x3", ["40"] = "Damaged x3", ["50"] = "Damaged x3" } },
	["0"] = { id = "hip", label = "Damaged Hipbone", levels = { ["default"] = "Damaged", ["10"] = "Damaged x2", ["20"] = "Damaged x3", ["30"] = "Damaged x3", ["40"] = "Damaged x3" } }, -- hip bone,
	["10706"] = { id = "rclavicle", label = "Right Clavicle", levels = { ["default"] = "Damaged" } },                                                                                 --right clavicle
	["64729"] = { id = "lclavicle", label = "Left Clavicle", levels = { ["default"] = "Damaged" } },                                                                                  --right clavicle
	["14201"] = { id = "lfoot", label = "Left Foot", levels = { ["default"] = "Damaged" } },                                                                                          -- left foot
	["18905"] = { id = "lhand", label = "Left Hand", levels = { ["default"] = "Damaged" } },                                                                                          -- left hand
	["24816"] = { id = "lbdy", label = "Lower chest", levels = { ["default"] = "Damaged" } },                                                                                         -- lower chest
	["24817"] = { id = "ubdy", label = "Upper Chest", levels = { ["default"] = "Damaged" } },                                                                                         -- Upper chest
	["24818"] = { id = "shoulder", label = "Shoulder", levels = { ["default"] = "Damaged" } },                                                                                        -- shoulder
	["28252"] = { id = "rforearm", label = "Right Forearm", levels = { ["default"] = "Damaged" } },                                                                                   -- right forearm
	["36864"] = { id = "rleg", label = "Right leg", levels = { ["default"] = "Damaged" } },                                                                                           -- right lef
	["39317"] = { id = "neck", label = "Neck", levels = { ["default"] = "Damaged" } },                                                                                                -- neck
	["40269"] = { id = "ruparm", label = "Right Upper Arm", levels = { ["default"] = "Damaged" } },                                                                                   -- right upper arm
	["45509"] = { id = "luparm", label = "Left Upper Arm", levels = { ["default"] = "Damaged" } },                                                                                    -- left upper arm
	["51826"] = { id = "rthigh", label = "Right Thigh", levels = { ["default"] = "Damaged" } },                                                                                       -- right thigh
	["52301"] = { id = "rfoot", label = "Right Foot", levels = { ["default"] = "Damaged" } },                                                                                         -- right foot
	["57005"] = { id = "rhand", label = "Right Hand", levels = { ["default"] = "Damaged" } },                                                                                         -- right hand
	["57597"] = { id = "5lumbar", label = "5th Lumbar vertabra", levels = { ["default"] = "Damaged" } },                                                                              --waist
	["58271"] = { id = "lthigh", label = "Left Thigh", levels = { ["default"] = "Damaged" } },                                                                                        -- left thigh
	["61163"] = { id = "lforearm", label = "Left forearm", levels = { ["default"] = "Damaged" } },                                                                                    -- left forearm
	["63931"] = { id = "lleg", label = "Left Leg", levels = { ["default"] = "Damaged" } },                                                                                            -- left leg
	["31086"] = { id = "head", label = "Head", levels = { ["default"] = "Damaged" } },                                                                                                -- head
}

function Config.SendDistressCall(msg)
	--[--] -- Quasar

	-- TriggerServerEvent('qs-smartphone:server:sendJobAlert', {message = msg, location = GetEntityCoords(PlayerPedId())}, "ambulance")


	--[--] -- GKS
	-- local myPos = GetEntityCoords(PlayerPedId())
	-- local GPS = 'GPS: ' .. myPos.x .. ', ' .. myPos.y

	-- ESX.TriggerServerCallback('gksphone:namenumber', function(Races)
	--     local name = Races[2].firstname .. ' ' .. Races[2].lastname

	--     TriggerServerEvent('gksphone:jbmessage', name, Races[1].phone_number, msg, '', GPS, "ambulance")
	-- end)
end
