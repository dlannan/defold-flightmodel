-- 
------------------------------------------------------------------------------------------------------------
-- State - Weapon control
--
-- Decription: 	Manage the weapon system for the f18 - mig and ddg will have similar
------------------------------------------------------------------------------------------------------------

local tinsert 	= table.insert
local tremove 	= table.remove

-- ---------------------------------------------------------------------------

local utils 	= require("app.utils")
local tf 		= require("utils.transforms")
local dgo		= require("utils.defold-gameobjects")
local gen 		= require("utils.general")

------------------------------------------------------------------------------------------------------------

local enums 	    = require "app.gameEnums"
local GAME	 	    = enums.GAME
local ENTITY_TYPE 	= enums.ENTITY_TYPE
local WEAPONS       = enums.WEAPONS_TYPE

------------------------------------------------------------------------------------------------------------

if(Sweapons) then return Sweapons end
Sweapons		= NewState()
Sweapons.self 	= Sweapons

------------------------------------------------------------------------------------------------------------

local f18weapons 	= {
	"None", "GUN", "AM 1", "AM 2", "AM 3", "AM 4", "SW 1", "SW 2"
}

------------------------------------------------------------------------------------------------------------

function Sweapons:GetWeapons(isgui)

	self = Sweapons.self
	pprint("[SETTING WEAPONS] ", isgui )
	
	local weapons = {

		["None"] 	= nil,
		["GUN"]		= nil,
		["AM 1"] 	= { 
			fired = nil, wtype = WEAPONS["AM"],
			pos = vmath.vector3(2.276,-0.631,-0.7), rot = vmath.quat(),
		},
		["AM 2"] 	= { 
			fired = nil, wtype = WEAPONS["AM"],
			pos = vmath.vector3(-2.276,-0.631,-0.7), rot = vmath.quat(),
		},
		["AM 3"] 	= { 
			fired = nil, wtype = WEAPONS["AM"],
			pos = vmath.vector3(4.274,-0.631,-0.7), rot = vmath.quat(),
		},
		["AM 4"] 	= { 
			fired = nil, wtype = WEAPONS["AM"],
			pos = vmath.vector3(-4.274,-0.631,-0.7), rot = vmath.quat(),
		},

		["SW 1"] 	= { 
			fired = nil, wtype = WEAPONS["SW"],
			pos = vmath.vector3(6.828,-0.236,-0.321), rot = vmath.quat(),
		},
		["SW 2"] 	= { 
			fired = nil, wtype = WEAPONS["SW"],
			pos = vmath.vector3(-6.828,-0.236,-0.321), rot = vmath.quat(),
		 },
	}

	if(isgui) then 

		weapons["AM 1"].node = gui.get_node("m1")
		weapons["AM 2"].node = gui.get_node("m2")
		weapons["AM 3"].node = gui.get_node("m3")
		weapons["AM 4"].node = gui.get_node("m4")
		weapons["SW 1"].node = gui.get_node("sw1")
		weapons["SW 2"].node = gui.get_node("sw2")
	end 
	
	
	self.weapons = weapons
	return weapons
end

------------------------------------------------------------------------------------------------------------

function Sweapons:LoadWeapon( weapon, parent )

end

------------------------------------------------------------------------------------------------------------

function Sweapons:FireWeapon( )

	self = Sweapons.self
	if(self.currWeapon == "None" or self.currWeapon == "GUN") then return end

	--msg.post(dgo.gid("/gui-cockpit"), "weapon_launch", { current = self.currWeapon } )

	-- Assume f18 is launching for now - this will be used by Mig and DDG as well as multi=player
	local  f18player = gop.get("PLAYER_F18") 
	msg.post(f18player.f18, "weapon_launch", { current = self.currWeapon  } )

	-- Add a mover to the weapon fired, so it can be updated and moved (dont forget to enable particlefx!! :) 
	local weapon = self.weapons[self.currWeapon]
	weapon.fired = true
end

------------------------------------------------------------------------------------------------------------

local function NextWeapon(self, weapon)

	self.currSelect = self.currSelect + 1
	if(self.currSelect > #f18weapons) then self.currSelect = 1 end
	local weapon = f18weapons[self.currSelect]
	if(self.currSelect > 2 and self.weapons[weapon].fired) then NextWeapon(self, self.currSelect) end 
end

function Sweapons:CycleWeapons( weapon )
	
	self = Sweapons.self
	NextWeapon(self, weapon)
	self.currWeapon = f18weapons[self.currSelect]
	--msg.post(dgo.gid("/gui-cockpit"), "weapon_select", { current = self.currWeapon } )
end

------------------------------------------------------------------------------------------------------------

function Sweapons:Begin(missions)

	self = Sweapons.self
	
	-- List of game objects to track and log info (mainly position)
	self.objects 		= {}
	self.currSelect		= 1
	self.currWeapon 	= f18weapons[self.currSelect]
	f18weaponsfired 	= {}
	
	self.enabled = true 
end

------------------------------------------------------------------------------------------------------------
function Sweapons:Update(Sgame, flightModel)

	self = Sweapons.self

end

------------------------------------------------------------------------------------------------------------

function Sweapons:Render(dt)

	self = Sweapons.self

end

------------------------------------------------------------------------------------------------------------

function Sweapons:Message(owner, message_id, message, sender)

	self = Sweapons.self
	pprint(message_id)
end

------------------------------------------------------------------------------------------------------------

function Sweapons:Finish(Sgame)

end
	
------------------------------------------------------------------------------------------------------------

return Sweapons

------------------------------------------------------------------------------------------------------------
	