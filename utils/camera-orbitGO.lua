
-- A camera controller so I can pan and move around the scene. 
-- Enable/Disable using keys
--------------------------------------------------------------------------------

-- Soft start and stop - all movements should be softened to make a nice movement
--   experience. Camera motion should also be dampened.

local tf = require("utils.transforms")

local move_dampen 	= 0.89
local look_dampen 	= 0.89

local cameraorbit = {}

--------------------------------------------------------------------------------

local function newcamera()
	
	local cameraorbit = {

		playerheight 	= 1.3, 
		cameraheight 	= 2.0,

		-- Where the look focus is in the distance
		lookdistance 	= 4.0,

		looklimityaw 	= math.pi * 0.5,
		looklimitpitch 	= math.pi * 0.5,
		
		lookvec 		= vmath.vector3(),
		pos				= vmath.vector3(),
		movevec 		= vmath.vector3(),
		
		xangle 			= 0.0,
		yangle			= 0.0,
	}
	return cameraorbit
end 

--------------------------------------------------------------------------------
-- A simple handler, can be easily replaced
local function defaulthandler( self, delta )

	local pitch		= -self.xangle
	local yaw		= self.yangle

	if (yaw > math.pi) then yaw = -math.pi; self.yangle = -math.pi end 
	if (yaw < -math.pi) then yaw = math.pi; self.yangle = math.pi end 
	if (pitch > math.pi * 0.5) then pitch = math.pi * 0.5; self.xangle = math.pi * 0.5 end 
	if (pitch < -math.pi * 0.5) then pitch = -math.pi * 0.5; self.xangle = -math.pi * 0.5 end 
		
	local camrot = vmath.quat_rotation_y( yaw )
	camrot = camrot * vmath.quat_rotation_x( pitch )

	local camrotinv = vmath.quat_rotation_y( yaw)
	camrotinv = camrotinv * vmath.quat_rotation_x( pitch)

	local campos 	 = vmath.matrix4_from_quat(camrot) * vmath.vector4(0, 0, self.distance, 0)

	self.prevtpos 	 = vmath.vector3(self.tpos)
	local ospos 	 = self.target.mover.position()
	self.tpos 		 = vmath.vector3(ospos.x, ospos.y, ospos.z)
	local osfwd      = self.target.mover.forward()
	self.trot 		 = tf.DirToQuat(vmath.vector3(osfwd.x, osfwd.y, osfwd.z))
	
	self.tspeed 	 = self.target.mover.speed()
	self.teuler		 = tf.ToEulerAngles(self.trot)
	self.tvelocity 	 = self.target.mover.velocity()

	self.throttle	 = math.floor(self.tspeed/self.target.mover.maxSpeed() * 10)
	
	if(self.use_target == nil and self.tPos) then self.tpos = self.tPos end
	self.pos = self.tpos + vmath.vector3(campos.x, campos.y, campos.z)
	self.rot = camrotinv
	
	go.set_rotation( self.rot, self.cameraobj )		
	go.set_position( self.pos, self.cameraobj )
	
	local objdata = {		
		speed		 = self.tspeed,
		climb 		 = self.tvelocity.y,
		heading		 = 180 - math.deg(self.teuler.y),
		altitude	 = self.tpos.y,
		throttle 	 = self.throttle,
		fuelpercent  = 0,
		weight 		 = 0, 
		angles		 = { x = self.teuler.x, y = self.teuler.y, z = self.teuler.z },
	}

	--msg.post("/gui", "object", objdata)
end

--------------------------------------------------------------------------------

cameraorbit.init = function( cameraobj, target, distance, handler )

	local newcam = newcamera()
	newcam.cameraobj 	= cameraobj 
	newcam.target 		= target
	newcam.handler 		= handler or defaulthandler

	newcam.distance 	= distance
	newcam.smooth 		= 0.98
	newcam.speed 		= 1.0
	newcam.flat 		= true 		-- define if the camera rolls

	tvec =vmath.vector3()
	newcam.tpos			= vmath.vector3(tvec.x, tvec.y, tvec.z)
		
	newcam.pos = go.get_position(cameraobj)
	newcam.rot = go.get_rotation(cameraobj)

	newcam.enabled = true 		-- enabled by default
	newcam.update = function( self, delta )

		if(newcam.enabled ~= true) then return end
		if(newcam.handler) then newcam.handler( newcam, delta ) end
	end
	
	return newcam
end 

--------------------------------------------------------------------------------

return cameraorbit

--------------------------------------------------------------------------------