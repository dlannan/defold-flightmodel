------------------------------------------------------------------------------------------------------------
-- State - Master contol state 
--
-- Decription: 	Control the movement to other states 
------------------------------------------------------------------------------------------------------------
local tinsert 	= table.insert
local tremove 	= table.remove
local tcount 	= table.getn

local utils 	= require "app.utils"
local dgo       = require("utils.defold-gameobjects")

local enums 	= require "app.gameEnums"
local GAME	 	= enums.GAME
local ENTITY_TYPE 	= enums.ENTITY_TYPE

------------------------------------------------------------------------------------------------------------

local Sgamefreeplay	= NewState()

------------------------------------------------------------------------------------------------------------
-- Set state config here  Sgamefreeplay.name = "MASTER"


local tf 			= require("utils.transforms")
local timers 		= require("utils.timer")
local gen 			= require("utils.general")

local player 		= require("utils.camera-player")
local orbit 		= require("utils.camera-orbitGO")
local follow 		= require("utils.camera-follow")

local f18Entity 	= require("app.states.entities.f18")

local slogger 		= require("app.states.Glogger")

local gop 			= nil

--------------------------------------------------------------------------------
-- A simple handler, can be easily replaced
local function orbitspin( self, delta )

	self.spin = self.spin + 0.01
	if (self.spin > math.pi) then self.spin = -math.pi end 

	local pitch		= -self.xangle
	local yaw		= self.spin

	if (yaw > math.pi) then yaw = -math.pi; self.yangle = -math.pi end 
	if (yaw < -math.pi) then yaw = math.pi; self.yangle = math.pi end 
	if (pitch > math.pi * 0.5) then pitch = math.pi * 0.5; self.xangle = math.pi * 0.5 end 
	if (pitch < -math.pi * 0.5) then pitch = -math.pi * 0.5; self.xangle = -math.pi * 0.5 end 

	local camrot = vmath.quat_rotation_y( yaw )
	camrot = camrot * vmath.quat_rotation_x( pitch )

	local camrotinv = vmath.quat_rotation_y( yaw)
	camrotinv = camrotinv * vmath.quat_rotation_x( pitch)

	local campos 	 = vmath.matrix4_from_quat(camrot) * vmath.vector4(0, 0, self.distance, 0)
	local ospos 	 = self.target.mover.position()
	local tpos 		 = vmath.vector3(ospos.x, ospos.y,ospos.z)

	self.pos = tpos + vmath.vector3(campos.x, campos.y, campos.z)
	self.rot = camrotinv

	go.set_rotation( self.rot, self.cameraobj )		
	go.set_position( self.pos, self.cameraobj )
end

------------------------------------------------------------------------------------------------------------

local function cameraSet( self )

	local cam_name = self.cam_names[self.cam_select]
	self.cam = self.cams[cam_name]
	if(cam_name == "player") then 
		--msg.post("/gui", "disable")
		--msg.post(dgo.gid("/gui-cockpit"), "enable")
		--msg.post(msg.url(nil, self.f18.data.go, "mesh"), "disable")
		--msg.post(msg.url(nil, self.f18.data.go, "pilotseat"), "enable")
	else 
		--msg.post("/gui", "enable")
		--msg.post(dgo.gid("/gui-cockpit"), "disable")
		--msg.post(msg.url(nil, self.f18.data.go, "mesh"), "enable")
		--msg.post(msg.url(nil, self.f18.data.go, "pilotseat"), "disable")
	end
end

------------------------------------------------------------------------------------------------------------

local function init_gameenv(self)
	
	--msg.post("/gui", "init")

	self.f18 			= f18Entity.init(self)
	
	self.cams = { 
		player 	= player.init("/camera", self.f18, -2.5 ),
		orbit 	= orbit.init("/camera", self.f18, 30.0 ),
		follow	= follow.init("/camera", self.f18, 30.0 ),
	}

	self.cam_names =  { "player", "orbit", "follow" }

	self.camorbitspin = orbit.init("/camera", self.f18, 30.0, orbitspin)
	self.camorbitspin.spin = 0.0
	self.cam_select = 1
	cameraSet(self)

	if(self.crash_smoke) then 
		particlefx.stop(self.crash_smoke)
		self.crash_smoke = nil 
	end	
end

------------------------------------------------------------------------------------------------------------

function Sgamefreeplay:Begin()

	print("Starting Game...")
	msg.post(".", "acquire_input_focus")
	msg.post("@render:", "set_block", { block = self.block })
	msg.post("@render:", "use_camera_projection")
	msg.post("/camera#camera", "acquire_camera_focus")
	-- msg.post("/camera#camera", "set_camera", {aspect_ratio = 1, fov = 0.7854, near_z = 0.7, far_z = 50000})
	
	self = Sgamefreeplay.self
    self.gamestate 		= GAME.NEW_GAME

	self.block			= 4 
	self.mission 		= ""
	self.paused 		= true
	
	self.debug			= false
	self.profiler		= false
	
	self.lastdt 		= 0.016
	self.cumulTime 		= 0.0
	self.gear 			= true
	self.lastk			= nil

	self.game_ids 		= GAME_IDS 
	self.map_ids 		= MAP_IDS
	self.elapsedTime 	= 0.0
	self.currTime		= 0.0
	
	init_gameenv(self)
	slogger:Begin()

	print("===========>")
	self.line 			= drawtools.newline(0xffffffff, 3.0)
	print("===========>", self.line)
	drawtools.addpoint( self.line, 0.0, 0.0, 0.0 )
	drawtools.addpoint( self.line, 0.0, 0.0, 0.0 )
end

------------------------------------------------------------------------------------------------------------
function Sgamefreeplay:Update(mxi, myi, buttons)

	self = Sgamefreeplay.self
	local dt = Sgamefreeplay.dt 
	
	self.f18.data.paused = self.paused
	if(self.paused == true and self.step == nil) then 
		dt = 0 
	end 
	if(self.step) then self.step = nil; print("STEPPED") end

	self.elapsedTime  = dt
	self.currTime 	= self.currTime + dt
		
	local ospos = vmath.vector3()
	local f18pos = vmath.vector3(ospos.x, ospos.y, ospos.z)
	drawtools.setpoint( 0, 0, ospos.x, ospos.y, ospos.z )
	drawtools.setpoint( 0, 1, ospos.x, ospos.y + 10.0, ospos.z )
		
	if(self.f18.data.collision) then
		if(self.cam ~= self.camorbitspin) then
			self.cam_select = 2 
			cameraSet(self)
			self.cam = self.camorbitspin
			
			self.crash_smoke = factory.create(dgo.gid("/explosions", "smoke"), f18pos, vmath.quat_rotation_y(0))
			go.set_scale(0.1, self.crash_smoke)
			particlefx.play(self.crash_smoke)

			--msg.post("/gui", "collision")
		end

		if(self.crash_smoke) then 
			go.set_position( f18pos, self.crash_smoke )
			go.set_rotation( vmath.quat_rotation_y( self.camorbitspin.spin ), self.crash_smoke )
		end 
	end 

	self.cam.update(self, Sgamefreeplay.dt )
	if(dt == 0 and self.paused == true ) then dt = Sgamefreeplay.dt  end 
	
	slogger:Update( self.osentities )
	self.lastdt = dt
end


------------------------------------------------------------------------------------------------------------

function Sgamefreeplay:Render()

	self = Sgamefreeplay.self
	local dt = Sgamefreeplay.dt
	
	slogger:Render(dt)
end

------------------------------------------------------------------------------------------------------------

function Sgamefreeplay:Message(owner, message_id, message, sender)

	self = Sgamefreeplay.self
	local dt = self.lastdt
	
	-- f18Entity.message(self, message_id, message, sender)
end

------------------------------------------------------------------------------------------------------------

function Sgamefreeplay:Input( owner, action_id, action  ) 

	self = Sgamefreeplay.self
	local dt = self.lastdt

	if(self.f18) then f18Entity.input(self, action_id, action, dt) end

	if(action_id == hash("key_v") and action.released) then
		local k, obj = next(self.osentities, self.lastk)
		if(k == nil) then k, obj = next(self.osentities, nil) end 
		self.lastk = k
		self.cam.target = obj 
		self.cam.use_target = true
	end

	if(action_id == hash("key_b") and action.released) then 
		local mig = nil
		for k,v in pairs(self.osentities) do
			if(v.data.name == "Mig29") then mig = v; break end 
		end 
		mig.m_target = self.f18.mover
		mig.mover.setMaxSpeed(450)
		mig.m_pursue = true 
		mig.m_patrol = nil
	end

	if(self.f18.data.collision == nil) then
	
		if(action_id == hash("key_c") and action.released) then 
			self.cam_select = (self.cam_select % #self.cam_names) + 1
			self.cam.target = self.f18
			self.cam.use_target = nil
			cameraSet(self)
		end

		if(action_id == hash("key_n") and action.released) then 
			if(self.cam_select == 2) then 
				self.cam.distance = self.cam.distance + 20
				if(self.cam.distance > 240.0) then self.cam.distance = 30 end 
			end
		end 
		
		if(action_id == hash("key_up")) then 
			self.cam.xangle = self.cam.xangle + dt * 0.5
		end 
		if(action_id == hash("key_down")) then 
			self.cam.xangle = self.cam.xangle - dt * 0.5
		end 

		if(action_id == hash("key_left")) then 
			self.cam.yangle = self.cam.yangle + dt * 0.5
		end 
		if(action_id == hash("key_right")) then 
			self.cam.yangle = self.cam.yangle - dt * 0.5
		end 

	else 
		if(action_id == hash("key_enter") and action.released) then 
			self.f18.data.collision = nil
			gSmgr:ChangeState("MenuMain")
		end
	end

	if(action_id == hash('key_o') and action.released) then 
		self.step = true
	end 
	
	if(action_id == hash('key_p') and action.released) then 
		self.paused = not self.paused
	end 

	if(action_id == hash("key_f1") and action.released) then 
		self.block = self.block - 1
		if(self.block < 1) then self.block = 1 end  
		model.set_constant("/screen#screen", "res", vmath.vector4(960,480,self.block,1))
		--msg.post("@render:", "set_block", { block = self.block })
	end
	if(action_id == hash("key_f2") and action.released) then 
		self.block = self.block + 1
		if(self.block > 8) then self.block = 8 end  
		model.set_constant("/screen#screen", "res", vmath.vector4(960,480,self.block,1))
		--msg.post("@render:", "set_block", { block = self.block })
	end

	

	if(action_id == hash("key_backspace") and action.released) then
		self.debug = not self.debug 
		f18Entity.toggleDebug()
	end 

	if(action_id == hash("key_0") and action.released and self.debug == true) then
		self.profiler = not self.profiler
		profiler.enable_ui(self.profiler)
	end
	
	-- move directional light based on input
	-- self.light.x = 2 * ((action.x - 480) / 480)
	-- self.light.y = 2 * ((action.y - 320) / 320)
	-- model.set_constant("/f18#f18", "light", self.light)
end 

------------------------------------------------------------------------------------------------------------

function Sgamefreeplay:Finish()

	self = Sgamefreeplay.self
	
	self.osentities		= nil 

	dgo.cleanupGids()
	dgo.cleanupMids()
	
	self.f18.close()
	self.f18 			= nil
	
	print("Scene unloaded..")
	msg.post("/camera#camera", "release_camera_focus")

	slogger:Finish()
end
	
------------------------------------------------------------------------------------------------------------

return Sgamefreeplay

------------------------------------------------------------------------------------------------------------
	