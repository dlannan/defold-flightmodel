

------------------------------------------------------------------------------------------------------------
-- State - Master contol state 
--
-- Decription: 	Control the movement to other states 
------------------------------------------------------------------------------------------------------------
local tinsert 		  = table.insert
local tremove 		  = table.remove
local tcount 		  = table.getn

local Vec3            = require("opensteer.os-vec")

local tf              = require("utils.transforms")


-- // ----------------------------------------------------------------------------
-- The entity manager is a proximity database that handles all 'active' entities in 
--  a scene. Entities can be static, or moving. Collision entities can be added,
--  pathing, and ai agent behaviours for entities can be used. 
--
--  See opensteer examples for this.
-- // ----------------------------------------------------------------------------



local utils 	= require "app.utils"

local enums 	= require "app.gameEnums"
local GAME	 	= enums.GAME

------------------------------------------------------------------------------------------------------------

local SentityMgr	= NewState()

------------------------------------------------------------------------------------------------------------
-- Set state config here  SentityMgr.name = "MASTER"


------------------------------------------------------------------------------------------------------------

function SentityMgr:Begin()

	self = SentityMgr.self

end

------------------------------------------------------------------------------------------------------------
function SentityMgr:Update(mxi, myi, buttons)
end

------------------------------------------------------------------------------------------------------------

function SentityMgr:Render()

	self = SentityMgr.self

end


------------------------------------------------------------------------------------------------------------

function SentityMgr:Input( owner, action_id, action  ) 

	self = SentityMgr.self
	local dt = self.lastdt

end

------------------------------------------------------------------------------------------------------------

function SentityMgr:Finish()
end

------------------------------------------------------------------------------------------------------------

return SentityMgr

------------------------------------------------------------------------------------------------------------
