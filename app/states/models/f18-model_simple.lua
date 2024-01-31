
local atmos 			= require("assets.env.atmosphere")
local timers 			= require("utils.timer")
local tf 				= require("utils.transforms")

-- -------------------------------------------------------------------------
--- Important physics time step - must be called FixedUpate at this rate
fixedDeltaTime 			= 0.010  -- 10 ms

-- -------------------------------------------------------------------------
-- Source Data:
-- https://en.wikipedia.org/wiki/McDonnell_Douglas_F/A-18_Hornet

local gravity 			= 9.81  		-- m/s^2
-- TODO: Terrain lookup
local groundLevel 		= 1.9

local planedata = {
	wingX				= 6.15, 		-- m
	wingZ 				= 1.0,
	tailSize 			= 3.5,     		-- m
	tailX 				= 0.0, 			-- m

	bodyMass			= 10000,
	engineMass			= 1500,  		-- kg	The engine mass is off center
	engineZ				= 2.0,			-- m
	wingMass 			= 1035,  		-- kg
	tailMass 			= 500,  		-- kg
	wingArea 			= 38, 			-- m^2

	maxMilitary 		= 49000 * 2, 	-- N Each engine non after burner
	maxAfterburn		= 79000 * 2, 	-- N Each engine with after burner
	maxThrust 			= 49000 * 2,	-- N
	maxVelocity 		= 531.936, 		-- m/s or 1,034 knots
	maxFuel				= 4930,			-- kg
	maxFuelUseMil		= 23, 			-- g/(kN⋅s)
	maxFuelUseAB		= 49, 			-- g/(kN⋅s)

	stallSpeed			= 69.45,		-- m/s

	initialVelocity		= vmath.vector3( 0.0, 0.0, -400.0),
	initialHeading 		= math.rad(180),

	maxAOA 				= math.rad( 5 ),  -- radian
}

planedata.wingLiftSlope 		= planedata.wingArea * 2
planedata.wingLimit 			= math.pi / 2

planedata.horStabLiftSlope 		= planedata.wingArea	
planedata.verStabLiftSlope 		= planedata.wingArea	

-- Early stall warning light.
planedata.stallWarning			= planedata.stallSpeed * 1.2 


planedata.relAirfoilPositions = {
	vmath.vector3(-planedata.wingX, 0.0, planedata.wingZ),
	vmath.vector3(planedata.wingX, 0.0, planedata.wingZ),
	vmath.vector3(-planedata.tailX, 0.0, planedata.tailSize),
	vmath.vector3(planedata.tailX, 0.0, planedata.tailSize),
	vmath.vector3(-planedata.tailX, 0.0, planedata.tailSize),
	vmath.vector3(planedata.tailX, 0.0, planedata.tailSize)
}

planedata.axes = {
	vmath.vector3(1.0, 0.0, 0.0),
	vmath.vector3(1.0, 0.0, 0.0),
	vmath.vector3(1.0, 0.0, 0.0),
	vmath.vector3(1.0, 0.0, 0.0),
	vmath.vector3(0.0, 1.0, 0.0),
	vmath.vector3(0.0, 1.0, 0.0),
}

planedata.liftSlopes = {
	planedata.wingLiftSlope,
	planedata.wingLiftSlope,
	planedata.horStabLiftSlope,
	planedata.horStabLiftSlope,
	planedata.verStabLiftSlope,
	planedata.verStabLiftSlope,
}

-- -------------------------------------------------------------------------

table.keys = function(self)
	local keys = {}
	for k, v in pairs(self) do
		table.insert(keys, k)
	end
	return keys
end 

math.sign = function(n)
	return n==0 and 0 or math.abs(n)/n
end

local function perp( a, b )
	return a.x * b.y - a.y * b.x;
end 

-- -------------------------------------------------------------------------
local colors = {
	white	= vmath.vector4(1, 1, 1, 1),
	blue 	= vmath.vector4(0, 0, 1, 1),
	green 	= vmath.vector4(0, 1, 0, 1),
	red 	= vmath.vector4(1, 0, 0, 1),
	yellow 	= vmath.vector4(1, 1, 0, 1),
}

-- -------------------------------------------------------------------------

local function drawLine( spos, epos, col )

	if(type(col) == "string") then col = colors[col] end
	msg.post("@render:", "draw_line", { start_point = spos, end_point = epos, color = col } )
end 

-- -------------------------------------------------------------------------
-- Interpolate over 0.5 sec to 0.0 - rather than harsh snap
local count = 1
local function HoldRoll(self)

	self.rollTimer = timers.new( function()

		count = 1 
		while(count < 50) do 
			self.leftWingInclination = vmath.lerp(0.1, self.leftWingInclination, 0.0)	
			self.rightWingInclination = vmath.lerp(0.1, self.rightWingInclination, 0.0)
			self.angularV.z = vmath.lerp(0.1, self.angularV.z, 0.0)
			wait(0.010)
			count = count + 1
		end
		self.leftWingInclination = 0.0
		self.rightWingInclination = 0.0
		self.angularV.z = 0.0
	end)
end 

-- -------------------------------------------------------------------------
-- Interpolate over 0.5 sec to 0.0 - rather than harsh snap
local pcount = 1
local function SmoothPitch(self)

	self.pitchTimer = timers.new( function()

		pcount = 1 
		while(pcount < 33 ) do 
			self.horStabInclinationL = vmath.lerp(0.01, self.horStabInclinationL, 0.0)	
			self.horStabInclinationR = vmath.lerp(0.01, self.horStabInclinationR, 0.0)
			self.angularV.x = vmath.lerp(0.05, self.angularV.x, 0.0)
			wait(0.01)
			pcount = pcount + 1
		end
		-- self.horStabInclinationL = 0.0
		-- self.horStabInclinationR = 0.0
	end)
end 

-- -------------------------------------------------------------------------
-- Blend back to 0.0
local pcount = 1
local function SmoothRudder(self)

	self.rudderTimer = timers.new( function()
		pcount = 1 
		while(pcount < 333) do 
			self.verStabInclination = vmath.lerp(0.01, self.verStabInclination, 0.0)	
			wait(0.01)
			pcount = pcount + 1
		end
		self.verStabInclination = 0.0
	end)
end 

-- -------------------------------------------------------------------------

local f18model = {
	
	leftwing 			= vmath.matrix4(),
	rightwing 			= vmath.matrix4(),
	verticalStab 		= vmath.matrix4(),
	horizontalStab 		= vmath.matrix4(),

	-- This is position and rotation of the f18
	transform 			= {

		position 	= vmath.vector3(),
		rotation 	= vmath.vector3(),

		TransformVector 	= tf.TransformVector,
		InvTransformVector 	= tf.InvTransformVector,
	},

--	[Range(-Mathf.PI/2, Mathf.PI / 2)]
	leftWingInclination		= 0.0,
--	[Range(-Mathf.PI / 2, Mathf.PI / 2)]
	rightWingInclination 	= 0.0, 
--	[Range(-Mathf.PI / 2, Mathf.PI / 2)]
	horStabInclinationL		= 0.0,
	horStabInclinationR		= 0.0,

--	[Range(-Mathf.PI / 2, Mathf.PI / 2)]
	verStabInclination		= 0.0,
--	[Range(0, 2000)]
	thrust					= 0.0,
	mass					= 0.0, 

	roll 					= 0.0,

	getRotation = function(self)
		return self.transform.rotation
	end,
	
	ThrottleUp = function(self) 
		self.thrust = self.thrust + planedata.maxThrust * 0.1
		if(self.thrust > planedata.maxThrust) then self.thrust = planedata.maxThrust end
	end,

	ThrottleDown = function(self) 
		self.thrust = self.thrust - planedata.maxThrust * 0.1
		if(self.thrust < 0.0) then self.thrust = 0.0 end
	end,

	ApplyWingLimits = function( self )
		if(self.leftWingInclination < -planedata.wingLimit) then self.leftWingInclination = -planedata.wingLimit end
		if(self.leftWingInclination > planedata.wingLimit) then self.leftWingInclination = planedata.wingLimit end
		if(self.rightWingInclination < -planedata.wingLimit) then self.rightWingInclination = -planedata.wingLimit end
		if(self.rightWingInclination > planedata.wingLimit) then self.rightWingInclination = planedata.wingLimit end
	end,
	
	PitchDown = function(self, amount) 

		if(amount == 0) then SmoothPitch(self); return	end
		self.pitchTimer = nil
		self.horStabInclinationL = self.horStabInclinationL - amount
		self.horStabInclinationR = self.horStabInclinationR - amount
		
		self.angularV.x = self.angularV.x + amount * 5.0
	-- 	self.leftWingInclination = self.leftWingInclination + amount		
	-- 	self.rightWingInclination = self.rightWingInclination + amount
	-- 	self:ApplyWingLimits()
	end,
	
	PitchUp = function(self, amount) 

		if(amount == 0) then SmoothPitch(self); return	end
		self.pitchTimer = nil
		self.horStabInclinationL = self.horStabInclinationL + amount
		self.horStabInclinationR = self.horStabInclinationR + amount

		self.angularV.x = self.angularV.x - amount * 5.0
		
		-- self.leftWingInclination = self.leftWingInclination - amount		
		-- self.rightWingInclination = self.rightWingInclination - amount
		-- self:ApplyWingLimits()
	end,

	RollLeft = function( self, amount)

		if(amount == 0) then HoldRoll(self); return	end
		self.angularV.z = self.angularV.z + amount * 10.0
		-- self.horStabInclinationL = self.horStabInclinationL - amount
		-- self.horStabInclinationR = self.horStabInclinationR + amount
		self.leftWingInclination = self.leftWingInclination-amount		
		self.rightWingInclination = self.rightWingInclination + amount
		self:ApplyWingLimits()
	end,

	RollRight = function( self, amount)

		if(amount == 0) then HoldRoll(self); return  end
		self.angularV.z = self.angularV.z - amount * 10.0
		-- self.horStabInclinationL = self.horStabInclinationL + amount
		-- self.horStabInclinationR = self.horStabInclinationR - amount
		self.leftWingInclination = self.leftWingInclination + amount
		self.rightWingInclination = self.rightWingInclination - amount
		self:ApplyWingLimits()
	end,

	RudderLeft = function( self, amount)

		if(amount == 0) then SmoothRudder(self); return	end
		self.rudderTimer = nil
		self.verStabInclination = self.verStabInclination + amount
	end,
	
	RudderRight = function( self, amount)

		if(amount == 0) then SmoothRudder(self); return	end
		self.rudderTimer = nil
		self.verStabInclination = self.verStabInclination - amount
	end,
	
	velocity 		= vmath.vector3(),
	angularAcc 		= vmath.vector3(),
	angularV 		=  vmath.vector3(),

	totalForce 		= vmath.vector3(),
	totalTorque 	= vmath.vector3(),

	inertiaTensor 	= vmath.vector3(),

	Awake = function(self)

		local relAirfoilPositions = {
			vmath.vector3(-planedata.wingX, 0.0, planedata.wingZ),
			vmath.vector3(planedata.wingX, 0.0, planedata.wingZ),
			vmath.vector3(-planedata.tailX, 0.0, planedata.tailSize),
			vmath.vector3(planedata.tailX, 0.0, planedata.tailSize),
			-- vmath.vector3(-planedata.tailX, 0.0, planedata.tailSize),
			-- vmath.vector3(planedata.tailX, 0.0, planedata.tailSize),
		}
		
		local masses = {
			planedata.wingMass,
			planedata.wingMass,
			planedata.tailMass,
			planedata.tailMass,
			-- planedata.tailMass,
			-- planedata.tailMass,
		}

		local Ixx = 0
		local Iyy = 0
		local Izz = 0

		for i = 1, #relAirfoilPositions do

			Ixx = Ixx + masses[i] * (math.pow(relAirfoilPositions[i].y, 2) + math.pow(relAirfoilPositions[i].z, 2))
			Iyy = Iyy + masses[i] * (math.pow(relAirfoilPositions[i].z, 2) + math.pow(relAirfoilPositions[i].x, 2))
			Izz = Izz + masses[i] * (math.pow(relAirfoilPositions[i].x, 2) + math.pow(relAirfoilPositions[i].y, 2))
		end

		self.inertiaTensor = vmath.vector3(Ixx, Iyy, Izz)
		self:getMass()
	end, 
--

	getMass = function(self)

		local mass = 0
		mass = mass + planedata.wingMass * 2
		mass = mass + planedata.tailMass * 2
		mass = mass + planedata.engineMass * 2
		mass = mass + planedata.bodyMass
		self.mass = mass
		return mass
	end,

	-- Use this for initialization
	Start = function(self, goHeading, initialVelocity) 

		self.transform.rotation = goHeading or vmath.quat_rotation_y(planedata.initialHeading)
		initialVelocity = initialVelocity or planedata.initialVelocity 
		self.velocity = self.transform.TransformVector(self.transform.rotation, initialVelocity) 
		
		self.colorkeys 		= table.keys(colors)
		self.currPos 		= self.transform.position 
		self.currRot 		= self:getRotation()
		self.acceleration 	= vmath.vector3()
		self.rudderForce 	= vmath.vector3()
		self.flap 			= 0.0
		self.storedThrust 	= vmath.vector3(0.0, 0.0, -self.thrust)

		self.carrierCount = 0		
	end,

	-- Update is called once per frame
	Update = function(self, dt) 

		self.speed = vmath.length(flightModel.velocity) 
		self.throttle = math.floor((self.thrust / planedata.maxThrust) * 100)
		if(self.speed < planedata.stallWarning) then self.stallWarning = true else self.stallWarning = false end 

		-- Calc heading from rotation quat\
		if(vmath.length(self.velocity) > 0) then
			local veldir = vmath.vector3(self.velocity.x, 0.0, self.velocity.z)
			if(vmath.length(veldir) > 0) then 
				local hdir = vmath.normalize(veldir)
				self.heading = math.deg(math.acos( vmath.dot(hdir, vmath.vector3(0.0, 0.0, -1.0) )))
				if(hdir.x < 0) then self.heading = 360-self.heading end 
			end 
		end 
		
		if(self.rollTimer) then self.rollTimer:update(dt) end
		if(self.pitchTimer) then self.pitchTimer:update(dt) end
		if(self.rudderTimer) then self.rudderTimer:update(dt) end 
		
		-- print(self.rightWingInclination.."   "..self.leftWingInclination)
		
	-- TODO: SHould oneshot this.

		local pos = self.currPos
		drawLine(pos + vmath.vector3(0.0, -1.0, 0.0), pos + vmath.vector3(0.0, 1.0, 0.0), "white")
		drawLine(pos + vmath.vector3(-1.0, 0.0, 0.0), pos + vmath.vector3(1.0, 0.0, 0.0), "white")

		drawLine( pos, pos + self.velocity * 0.01, "green" )
		drawLine( pos, pos + self.acceleration * 0.5, "blue" )
		drawLine( pos, pos + self.transform.TransformVector(self.currRot, self.rudderForce) * 0.0001, "white" )
		drawLine(pos, pos + self.transform.TransformVector(self.currRot, self.storedThrust) * 0.0001, "yellow")
		drawLine(pos, pos + self.transform.TransformVector(self.currRot, self.totalForce) * 0.0001, "red")
				
		self.currPos = self.transform.position 
		self.currRot = self:getRotation()
		
	end,

	-- fixed Update for physics
	FixedUpdate = function(self, dt)

		local h = dt --fixedDeltaTime
		if(self.paused) then h = 0.0 end

		local localVelocity = self.transform.InvTransformVector(self.transform.rotation, self.velocity)
		local air = atmos.ISA( self.transform.position.y )
		local dynPressure = 0.5 * air.density * self.speed * self.speed
		local dragMag = math.abs(math.min(dynPressure * 0.3, 100000000)) 
		drag = localVelocity * dragMag * 0.1
		
		-- get force as a global vector - forward * N thrust
		self.totalForceL = vmath.vector3(0.0, 0.0, -1.0) * self.thrust + vmath.vector3(0.0, 0.0, -gravity) * self.mass  - drag

		local thrustdir = self.transform.TransformVector(self.transform.rotation, vmath.vector3(0.0, 0.0, -1.0) * self.speed)
		self.totalForce = self.transform.TransformVector(self.transform.rotation, self.totalForceL)
		
		local accel = (self.totalForce / self.mass) 
		-- setPosition
		self.prevpos = self.transform.position
		self.transform.position = self.prevpos + self.velocity * h + self.acceleration * 0.5 * h * h
		-- setVelocity
		-- self.velocity = self.velocity + accel * h
		
		self.velocity = thrustdir + accel * h 
		self.acceleration = accel

		local angRot = self.angularV * h
		-- Stop accumulative angles
		angRot.x = angRot.x % (2 * math.pi)
		angRot.y = angRot.y % (2 * math.pi)
		angRot.z = angRot.z % (2 * math.pi)
		self.transform.rotation = self.transform.rotation * tf.rotateEuler(angRot)
		
		if(self.transform.position.y < groundLevel) then 

			self.transform.position.y = groundLevel
			self.transform.rotation = vmath.slerp(0.3, self.transform.rotation, vmath.quat_rotation_y(math.rad(self.heading)))
		end 
		-- pprint(self.transform.position)
		-- pprint(self.thrust.."  "..self.leftWingInclination.."  "..self.rightWingInclination.."  "..self.totalTorque.x)
		-- pprint(self.velocity)
	end, 
}

-- -------------------------------------------------------------------------

return f18model

-- -------------------------------------------------------------------------
