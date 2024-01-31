------------------------------------------------------------------------------------------------------------
-- State - Data logger
--
-- Decription: 	Log data for replay and AAR
--
-- Only log specific data from a mover:
--   position, rotation, velocity, damage, weapons(available), targets
--   Most of these only record on change.
-- Only record a handful of specific event messages
--   Weapon fire, Weapon hit, Entity destroyed, Collision
------------------------------------------------------------------------------------------------------------

local tinsert 	= table.insert
local tremove 	= table.remove

-- ---------------------------------------------------------------------------

local utils 	= require("app.utils")
local tf 		= require("utils.transforms")
local gen 		= require("utils.general")
------------------------------------------------------------------------------------------------------------

local Slogger	= NewState()
Slogger.self 	= Slogger

------------------------------------------------------------------------------------------------------------

local enums 	= require "app.gameEnums"

------------------------------------------------------------------------------------------------------------

function Slogger:Begin(missions)
	
	self = Slogger.self

	-- Log format: 
	--   key - timestamp.
	--   assigned values { go = gameobject, property name =  property value }
	--   a gameobject id _must_ be included for every log entry.  
	--   Names must be valid strings, values must be lua only data (Number or String)
	-- example: 
	--   { go = "/instance0", positionX = 1.405, positionY = 999, positionZ = 234.32 }
	self.log 		= {}
	self.time		= 0.0

	self.enabled = true 
end

------------------------------------------------------------------------------------------------------------
-- Important log events should come in here
function Slogger:Message(owner, message_id, message, sender )

	self = Slogger.self
	local dt = Slogger.dt

end

------------------------------------------------------------------------------------------------------------
function Slogger:Update(objects)

	self = Slogger.self
	if(objects == nil) then return end
	for k,v in pairs(objects) do
		
		local pos = v.mover.position() or vmath.vector3()
		local rot = v._quat or vmath.quat()
		local vel = v.mover.velocity() or vmath.vector3()
		local damage = v.damage or 0.0
		tinsert(self.log, {
			timestamp = self.time,
			go = v.m_MyID,
			positionX = pos.x, positionY = pos.y, positionZ = pos.z,
			rotationX = rot.x, rotationY = rot.y, rotationZ = rot.z, rotationW = rot.w,
			velX = vel.x, velY = vel.y, velZ = vel.z,
			damage = damage
		})
	end
end

------------------------------------------------------------------------------------------------------------

function Slogger:Render(dt)

	self = Slogger.self
	self.time = self.time + dt
end

------------------------------------------------------------------------------------------------------------

function Slogger:Finish()

end
	
------------------------------------------------------------------------------------------------------------

return Slogger

------------------------------------------------------------------------------------------------------------
	