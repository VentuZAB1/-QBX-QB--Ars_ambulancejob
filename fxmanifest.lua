--#--
--Fx info--
--#--
fx_version 'cerulean'
use_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'
version '1.0.3'
author 'Arius Scripts'
description 'Advanced ambulance job with intergrated death system'


--#--
--Manifest--
--#--

shared_scripts {
	'@ox_lib/init.lua',
	'config.lua',
}

client_scripts {
	"client/bridge/*.lua",
	"client/modules/utils.lua",
	"client/modules/weapons.lua",
	"client/modules/death_ui.lua",
	"client/modules/coords_debug.lua",
	"client/death.lua",
	"client/injuries.lua",
	"client/paramedic.lua",
	"client/stretcher.lua",
	"client/job/*.lua",
	"client/main.lua",
}

server_scripts {
	"@oxmysql/lib/MySQL.lua",
	"server/bridge/esx.lua",
	"server/bridge/qb.lua",
	"server/main.lua",
	"server/commands.lua",
	"server/txadmin.lua",
}

files {
	'locales/*.json',
	'html/index.html',
	'html/style.css',
	'html/script.js',
}

ui_page 'html/index.html'
