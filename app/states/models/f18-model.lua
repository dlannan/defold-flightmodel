
local tinsert 			= table.insert 
local tremove 			= table.remove

-- -------------------------------------------------------------------------

local atmos 			= require("assets.env.atmosphere")
local timers 			= require("utils.timer")
local tf 				= require("utils.transforms")
local gen				= require("utils.general")

-- -------------------------------------------------------------------------
--- Important physics time step - must be called FixedUpate at this rate
fixedDeltaTime 			= 0.010  		-- 10 ms

-- -------------------------------------------------------------------------
-- Source Data:
-- https://en.wikipedia.org/wiki/McDonnell_Douglas_F/A-18_Hornet

local gravity 			= 9.81  		-- m/s^2
-- TODO: Terrain lookup
local groundLevel 		= 1.9

local planedata = {
	wingX				= 4.15, 		-- m
	wingZ 				= 0.0,			-- m
	tailArea 			= 20,     		-- m^2
	tailX 				= 2.6, 			-- m
	tailZ 				= 3.0,			-- m

	bodyMass			= 4000,
	bodyArea			= 10,
	bodyZ 				= 0.0,

	engineMass			= 1035,  		-- kg	The engine mass is off center
	engineZ				= 1.5,			-- m
	wingMass 			= 700,  		-- kg
	tailMass 			= 300,  		-- kg
	wingArea 			= 34, 			-- m^2

	maxMilitary 		= 49000 * 2, 	-- N Each engine non after burner
	maxAfterburn		= 79000 * 2, 	-- N Each engine with after burner

	maxVelocity 		= 531.936, 		-- m/s or 1,034 knots

	maxFuel				= 4930,			-- kg
	maxFuelUseMil		= 23, 			-- g/(kN⋅s)
	maxFuelUseAB		= 49, 			-- g/(kN⋅s)

	stallSpeed			= 69.45,		-- m/s

	-- Launch speed for f18 on carrier - 165 knots - 85 m/s
	initialVelocity		= vmath.vector3( 0.0, 0.0, -85.0),
	initialHeading 		= math.rad(180),

	maxAOA 				= math.rad( 20 ),   -- deg to radian
	flapAOA				= math.rad( 5  ), 	-- deg to radian

	pitchMinimum 		= 0.0, -- -0.042,		  -- radian (minimum pitch for air surface).
	maxGearSpeed		= 0.3 * 531.936,
	
	debug 				= false,
}

local minAOA 	= -planedata.maxAOA
local maxAOA 	= planedata.maxAOA
local baseCL 	= 0.0
local maxCL 	= 1.5 

local function velocityGraph(AOA)

	-- AOA = math.min(maxAOA, math.max(minAOA, AOA))
	return math.sin(AOA)
	-- return tf.lerp(math.sin(AOA), baseCL, maxCL)
end 

-- -------------------------------------------------------------------------

local function setupPlaneData(planedata)

	planedata.maxThrust 			= planedata.maxMilitary
	planedata.wingLiftSlope 		= planedata.wingArea
	planedata.wingLimit 			= math.rad(15)
	planedata.vertLimit				= math.rad(7)

	planedata.horStabLiftSlope 		= planedata.tailArea	
	planedata.verStabLiftSlope 		= planedata.tailArea 

	-- Early stall warning light.
	planedata.stallWarning			= planedata.stallSpeed * 1.2 

	planedata.relAirfoilPositions = {
		vmath.vector3(-planedata.wingX, 0.0, planedata.wingZ ),
		vmath.vector3(planedata.wingX, 0.0, planedata.wingZ ),
		vmath.vector3(-planedata.tailX, 0.0, planedata.tailZ + 2.0),	-- tail rudder
		vmath.vector3(planedata.tailX, 0.0, planedata.tailZ + 2.0),     -- tail rudder
		vmath.vector3(-planedata.tailX * 0.4, 0.5, planedata.tailZ),
		vmath.vector3(planedata.tailX * 0.4, 0.5, planedata.tailZ),
		-- The remaining positions here are for interntial masses only 

		vmath.vector3(0.0, 0.0, planedata.bodyZ),		-- body mass
		vmath.vector3(-planedata.tailX * 0.6, 0.0, planedata.engineZ),	-- left engine
		vmath.vector3(planedata.tailX * 0.6, 0.0, planedata.engineZ),		-- right engine
	}

	planedata.axes = {
		vmath.vector3(1.0, 0.0, 0.0),
		vmath.vector3(1.0, 0.0, 0.0),
		vmath.vector3(1.0, 0.0, 0.0),
		vmath.vector3(1.0, 0.0, 0.0),
		vmath.vector3(-0.342020143, 0.939692621, 0.0),
		vmath.vector3(0.342020143, 0.939692621, 0.0),

		vmath.vector3(1.0, 0.0, 0.0),
	}

	planedata.liftSlopes = {
		planedata.wingLiftSlope,
		planedata.wingLiftSlope,
		planedata.horStabLiftSlope,
		planedata.horStabLiftSlope,
		planedata.verStabLiftSlope,
		planedata.verStabLiftSlope,

		planedata.bodyArea,		-- The body is essentially a wing but not as effective
	}

	planedata.masses = {
		planedata.wingMass,
		planedata.wingMass,
		planedata.tailMass,
		planedata.tailMass,
		planedata.tailMass,
		planedata.tailMass,

		planedata.bodyMass,
		planedata.engineMass,
		planedata.engineMass,
	}
end
	
-- -------------------------------------------------------------------------
-- Interpolate over 0.5 sec to 0.0 - rather than harsh snap
-- local count = 1
local function HoldRoll(self, dt)

-- 	self.rollTimer = timers.new( function()
-- 
-- 		count = 1 
-- 		while(count < 50) do 
-- 			self.leftWingInclination = vmath.lerp(0.1, self.leftWingInclination, 0.0)	
-- 			self.rightWingInclination = vmath.lerp(0.1, self.rightWingInclination, 0.0)
-- 			wait(0.010)
		self.targetRoll = vmath.lerp(dt * 0.4, self.targetRoll, 0.0)
			-- count = count + 1
	-- 	end
	-- 	self.leftWingInclination = 0.0
	-- 	self.rightWingInclination = 0.0
	-- end)
end 

-- -------------------------------------------------------------------------
-- Interpolate over 0.5 sec to 0.0 - rather than harsh snap
-- local pcount = 1
local function SmoothPitch(self, dt)

--	self.pitchTimer = timers.new( function()

		--pcount = 1 
		--while(pcount < 333 ) do 
		self.targetPitch = vmath.lerp(dt * 0.4, self.targetPitch, planedata.pitchMinimum)	
			--wait(0.01)
			-- pcount = pcount + 1
		--end
		-- self.horStabInclinationL = 0.0
		-- self.horStabInclinationR = 0.0
--	end)
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

if(f18model) then return f18model end

f18model = {
	
	leftwing 			= vmath.matrix4(),
	rightwing 			= vmath.matrix4(),
	verticalStab 		= vmath.matrix4(),
	horizontalStab 		= vmath.matrix4(),

	-- This is position and rotation of the f18
	transform 			= {

		position 			= vmath.vector3(),
		rotation 			= vmath.vector3(),

		TransformVector 	= tf.TransformVector,
		InvTransformVector 	= tf.InvTransformVector,
	},

	targetPitch 			= 0.0,
	targetRoll				= 0.0, 
	
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
	
	fuel 					= planedata.maxFuel,
	fuelPercent 			= 100,
	mover 					= nil,
	throttle 				= 10,

	getPosition = function(self)
		return self.transform.position
	end,
		
	getRotation = function(self)
		return self.transform.rotation
	end,
	
	ThrottleUp = function(self) 
		if(self.throttle == 10) then self.throttle_ab = not self.throttle_ab end
		self.throttle = math.min(self.throttle + 1, 10)
		self.thrust = self.throttle * planedata.maxThrust * 0.1
		if(self.throttle_ab == true) then self.thrust = planedata.maxAfterburn end
	end,

	ThrottleDown = function(self) 
		if(self.throttle_ab == true) then self.throttle_ab = false end
		self.throttle = math.max(self.throttle - 1, 0)
		self.thrust = self.throttle * planedata.maxThrust * 0.1
	end,

	ApplyWingLimits = function( self )
		if(self.leftWingInclination < -planedata.wingLimit) then self.leftWingInclination = -planedata.wingLimit end
		if(self.leftWingInclination > planedata.wingLimit) then self.leftWingInclination = planedata.wingLimit end
		if(self.rightWingInclination < -planedata.wingLimit) then self.rightWingInclination = -planedata.wingLimit end
		if(self.rightWingInclination > planedata.wingLimit) then self.rightWingInclination = planedata.wingLimit end
	end,

	ApplyVertLimits = function( self )
		if(self.verStabInclination < -planedata.vertLimit) then self.verStabInclination = -planedata.vertLimit end
		if(self.verStabInclination > planedata.vertLimit) then self.verStabInclination = planedata.vertLimit end
	end,
	
	PitchDown = function(self, amount) 

		self.pitchTimer = nil
		self.targetPitch = self.targetPitch - amount
		-- self.horStabInclinationL = self.horStabInclinationL - amount
		-- self.horStabInclinationR = self.horStabInclinationR - amount

	-- 	self.leftWingInclination = self.leftWingInclination + amount		
	-- 	self.rightWingInclination = self.rightWingInclination + amount
	-- 	self:ApplyWingLimits()
	end,
	
	PitchUp = function(self, amount) 

		self.pitchTimer = nil
		self.targetPitch = self.targetPitch + amount
-- 		self.horStabInclinationL = self.horStabInclinationL + amount
-- 		self.horStabInclinationR = self.horStabInclinationR + amount

		-- self.leftWingInclination = self.leftWingInclination - amount		
		-- self.rightWingInclination = self.rightWingInclination - amount
		-- self:ApplyWingLimits()
	end,

	RollLeft = function( self, amount)

		--if(amount == 0) then HoldRoll(self); return	end
		self.targetRoll = self.targetRoll - amount
		
		-- self.horStabInclinationL = self.horStabInclinationL - amount
		-- self.horStabInclinationR = self.horStabInclinationR + amount
		-- self.leftWingInclination = self.leftWingInclination-amount		
		-- self.rightWingInclination = self.rightWingInclination + amount
		self:ApplyWingLimits()
	end,

	RollRight = function( self, amount)

		--if(amount == 0) then HoldRoll(self); return  end
		self.targetRoll = self.targetRoll + amount
		-- self.horStabInclinationL = self.horStabInclinationL + amount
		-- self.horStabInclinationR = self.horStabInclinationR - amount
		-- self.leftWingInclination = self.leftWingInclination + amount
		-- self.rightWingInclination = self.rightWingInclination - amount
		self:ApplyWingLimits()
	end,

	RudderLeft = function( self, amount)

		if(amount == 0) then SmoothRudder(self); return	end
		self.rudderTimer = nil
		self.verStabInclination = self.verStabInclination + amount
		--self:ApplyVertLimits()
	end,
	
	RudderRight = function( self, amount)

		if(amount == 0) then SmoothRudder(self); return	end
		self.rudderTimer = nil
		self.verStabInclination = self.verStabInclination - amount
		--self:ApplyVertLimits()
	end,
	
	velocity 		= vmath.vector3(),
	angularAcc 		= vmath.vector3(),
	angularV 		=  vmath.vector3(),

	totalForce 		= vmath.vector3(),
	totalTorque 	= vmath.vector3(),

	inertiaTensor 	= vmath.vector3(),

	-- Alows rapid testing of the model, and ability to reload model at runtime. 
	LoadFixedUpdate = function(self, updatefile)

		local f = assert(loadfile(updatefile))
		self.FixedUpdate, planedata = f()
		self:Awake()
	end,
	
	Awake = function(self, mover)

		if(mover) then self.mover = mover end 
		setupPlaneData(planedata)
		
		local Ixx = 0
		local Iyy = 0
		local Izz = 0

		for i = 1, #(planedata.relAirfoilPositions) do

			local xsqr  = planedata.relAirfoilPositions[i].x * planedata.relAirfoilPositions[i].x
			local ysqr  = planedata.relAirfoilPositions[i].y * planedata.relAirfoilPositions[i].y
			local zsqr  = planedata.relAirfoilPositions[i].z * planedata.relAirfoilPositions[i].z
			Ixx = Ixx + planedata.masses[i] * (ysqr + zsqr)
			Iyy = Iyy + planedata.masses[i] * (zsqr + xsqr)
			Izz = Izz + planedata.masses[i] * (xsqr + ysqr)
		end

		self.inertiaTensor = vmath.vector3(Ixx, Iyy, Izz)
		self.inertiaMatrixInv = vmath.vector3(1 / self.inertiaTensor.x, 1 / self.inertiaTensor.y, 1 / self.inertiaTensor.z)
		
		self:getMass()

		self.horStabInclinationL = 0.0
		self.horStabInclinationR = 0.0
		self.leftWingInclination = 0.0
		self.rightWingInclination = 0.0 
	end, 

	getMass = function(self)

		local mass = 0
		for k,v in pairs(planedata.masses) do
			mass = mass + v
		end
		self.mass = mass + planedata.maxFuel
		return mass
	end,

	toggleDebug = function(self)

		planedata.debug = not planedata.debug
	end,
	
	-- Use this for initialization
	Start = function(self, goHeading, initialVelocity) 

		self.transform.rotation = goHeading or vmath.quat_rotation_y(planedata.initialHeading)
		initialVelocity = initialVelocity or planedata.initialVelocity 
		self.velocity = self.transform.TransformVector(self.transform.rotation, initialVelocity) 
		
		self.currPos 		= self:getPosition()
		self.currRot 		= self:getRotation()
		self.acceleration 	= vmath.vector3()
		self.rudderForce 	= vmath.vector3()
		self.flap 			= true

		self.throttle 		= 10
		self.throttle_ab	= false
		self.thrust 		= self.throttle * planedata.maxThrust * 0.1
		self.storedThrust 	= vmath.vector3(0.0, 0.0, -self.thrust)

		self._smoothedAcceleration = vmath.vector3()
		self._smoothedTorque = vmath.vector3()
		self.liftForces		= {}
		self.targetPitch 	= 0.0

		self.carrierCount   = 0
		self.angles 		= vmath.vector3(0,0,0)
		self.collision  	= nil
		self.collisions		= {} 	-- list of collision with objects.

		planedata.leftWingInclination		= 0.0
		--	[Range(-Mathf.PI / 2, Mathf.PI / 2)]
		planedata.rightWingInclination 		= 0.0 
		--	[Range(-Mathf.PI / 2, Mathf.PI / 2)]
		planedata.horStabInclinationL		= 0.0
		planedata.horStabInclinationR		= 0.0
	end,

	-- Update is called once per frame
	Update = function(self, dt) 

		self.speed = vmath.length(self.velocity) 

		-- Calc heading from rotation quat
		local forward = tf.TransformVector(self.currRot, vmath.vector3(0,0, -1.0))
		if(vmath.length(forward) > 0.0) then 
			local hdir = vmath.normalize(vmath.vector3(forward.x, 0.0, forward.z))
			self.heading = math.deg(math.acos( vmath.dot(hdir, vmath.vector3(0.0, 0.0, -1.0) )))
			if(hdir.x < 0) then self.heading = 360-self.heading end 
		end 

		--if(self.rollTimer) then self.rollTimer:update(dt) end
		--if(self.pitchTimer) then self.pitchTimer:update(dt) end
		if(self.rudderTimer) then self.rudderTimer:update(dt) end 

		SmoothPitch(self, dt)
		HoldRoll(self, dt)
		
		self.horStabInclinationL = self.targetPitch
		self.horStabInclinationR = self.targetPitch

		self.leftWingInclination  = self.targetRoll
		self.rightWingInclination = -self.targetRoll
				
		-- print(self.rightWingInclination.."   "..self.leftWingInclination)
		self.currPos = self.transform.position 
		self.currRot = self:getRotation()		
	-- TODO: SHould oneshot this.
		
		local pos = self.currPos
		if(planedata.debug) then 
		gen.drawLine(pos + vmath.vector3(0.0, -1.0, 0.0), pos + vmath.vector3(0.0, 1.0, 0.0), "white")
		gen.drawLine(pos + vmath.vector3(-1.0, 0.0, 0.0), pos + vmath.vector3(1.0, 0.0, 0.0), "white")

		gen.drawLine( pos, pos + self.velocity * 0.03, "green" )
		gen.drawLine( pos, pos + self.acceleration * 1, "blue" )
		gen.drawLine( pos, pos + self.transform.TransformVector(self.currRot, self.rudderForce) * 0.001, "white" )
		gen.drawLine(pos, pos + self.transform.TransformVector(self.currRot, self.storedThrust) * 0.0001, "yellow")
		gen.drawLine(pos, pos + self.transform.TransformVector(self.currRot, self.totalForce) * 0.0001, "red")
		
		local pd = planedata
		-- Attack vectors
		for k,v in pairs(pd.axes) do 
			local relAf = self.transform.TransformVector(self.currRot, pd.relAirfoilPositions[k])
			local relv = self.transform.TransformVector(self.currRot, v)
			gen.drawLine( pos + relAf, pos + relv + relAf, "white" )
		end
		end

	end,

	HandleLimits = function(self, dt)

		self.angles = tf.ToEulerAngles(self.transform.rotation)
		self.angles.y = vmath.normalize( self.transform.TransformVector(self.currRot, vmath.vector3(0,0,-1)) ).y
		--		self.angles.z = tf.ToEulerAngles(self.transform.rotation).z
		
		local angRot = self.angularV * dt
		-- Stop accumulative angles
		angRot.x = angRot.x % (2.0 * math.pi)
		angRot.y = angRot.y % (2.0 * math.pi)
		angRot.z = angRot.z % (2.0 * math.pi)

		-- set Rotation
		self.newrotation = self.transform.rotation * tf.RotateEuler(angRot)
		
		local speed = vmath.length(self.velocity)
		if( speed > planedata.maxVelocity ) then 
			local velocityDir = vmath.normalize(self.velocity)
			self.velocity = planedata.maxVelocity * velocityDir
		end 

		-- Stall warning light
		if(speed < planedata.stallWarning) then 
			self.stallWarning = true 
		else 
			self.stallWarning = false 
		end 
	end,

	AddCollision = function(self, collisiondata)
		tinsert(self.collisions, collisiondata)
	end,
	
	HandleCollision = function(self, dt)

		-- Very specific nimitz collision - should work for airfields too. 
		if(#self.collisions > 0) then 
			for k,v in pairs(self.collisions) do
				self.transform.position.y = v.position.y + v.distance + 2.0
			end 
			self.collisions = {}
		else 
			self.transform.rotation = self.newrotation 
		end

		-- This is temp - once airfields are done, just need to test for water
		if(self.transform.position.y < groundLevel) then 

			self.collision = true
			self.transform.position.y = groundLevel
		end 
	end,
	
	-- fixed Update for physics
	FixedUpdate = function(self, delta)

		-- Attack vectors regenerated per frame based on changes in airfoils
		--     TODO: Remove this and put into events for airfoil movement
		self.attackVectors = {
			vmath.vector3(0.0, math.sin(self.leftWingInclination), -math.cos(self.leftWingInclination)),
			vmath.vector3(0.0, math.sin(self.rightWingInclination), -math.cos(self.rightWingInclination)),
			vmath.vector3(0.0, math.sin(self.horStabInclinationL), -math.cos(self.horStabInclinationL)),
			vmath.vector3(0.0, math.sin(self.horStabInclinationR), -math.cos(self.horStabInclinationR)),

			-- Tail needs to be a Biconvex - it is currently not. Im not sure how to implement this.
			vmath.vector3(math.sin(self.verStabInclination), 0.0 , -math.cos(self.verStabInclination)),
			vmath.vector3(math.sin(self.verStabInclination), 0.0 , -math.cos(self.verStabInclination)),

			vmath.vector3(0.0, math.sin(0), -math.cos(0)),		-- Body is technically a wing with some lift.
		}

		self.localVelocity = self.transform.InvTransformVector(self.transform.rotation, self.velocity)

		local dt = delta
		
		-- Need to handle this better.
		if(self.collision) then return end 

		--self.transform.rotation = self.collisionrot or self.transform.rotation
		-- If gear down (flaps on) then limit velocity.
		local tempspeed = vmath.length(self.velocity)
		if(tempspeed > planedata.maxGearSpeed and self.flap) then 
			self.thrust = planedata.maxThrust * 0.15
		end
		
		-- get force as a global vector
		self.totalForceL = self:getTotalForce()
		self.totalForce = self.transform.TransformVector(self.transform.rotation, self.totalForceL)		
		
		-- set torque
		self.totalTorque = self:getTotalTorque()
		
		-- Work out kN-s for fuel usage 
		local kgsFuel = self.thrust * 0.001 * dt * planedata.maxFuelUseMil
		self.mass = self.mass - kgsFuel * 0.001
		self.fuel = math.max(0, self.fuel - kgsFuel * 0.001)
		self.fuelPercent = ( self.fuel / planedata.maxFuel )
		
		-- pprint(self.totalForce, self.mass)
		local accelV = self.totalForce / self.mass
		-- setVelocity
		local newvelocity = self.velocity + accelV * dt

		-- angularAcc
		-- calculate angularAcc
		self.angularAcc = vmath.vector3(self.inertiaMatrixInv.x * self.totalTorque.x, self.inertiaMatrixInv.y * self.totalTorque.y, self.inertiaMatrixInv.z * self.totalTorque.z)
		-- angularV
		self.angularV = self.angularV + self.angularAcc * dt
		self.angularV = self.angularV * math.max(1 - (0.5 * dt), 0) -- I dont think this is needed anymore

		------------------------------- Set position, rotation velocity and acceleration -------------------------------------
		-- setPosition
		self.prevpos = self.transform.position
		self.transform.position = self.prevpos + newvelocity * dt --self.acceleration * 0.5 * dt * dt
		self.velocity = newvelocity
		self.acceleration = accelV

		--- Apply Limits and Collision - resolve constraints in HandleCollision
		self.HandleLimits(self, dt)
		self.HandleCollision(self, dt)
	end, 

	--/**
	-- * Get the total force on the drone in the drone axis.
	-- *
	-- * @return total force of the Drone in the drone axis.
	-- */
	getTotalForce = function(self)

		local force = vmath.vector3(0, 0, -self.thrust)
		self.storedThrust = force 
		force = force + self.transform.InvTransformVector(self.transform.rotation, vmath.vector3(0, self.mass * -gravity, 0))
		
		self.liftForces = {}
		for i = 1, #planedata.liftSlopes do
		
			local axis 			= planedata.axes[i]
			local attackVector 	= self.attackVectors[i]
			local resPos 		= planedata.relAirfoilPositions[i]
			local liftSlope 	= planedata.liftSlopes[i]
			if(i < 3 and self.flap) then attackVector = attackVector + vmath.vector3(0.0, math.sin(planedata.flapAOA), -math.cos(planedata.flapAOA)) end 

			local Lforce = self:lift(resPos, axis, attackVector, liftSlope)
			
			if(i>=5) then self.rudderForce = Lforce end 
			self.liftForces[i] = Lforce
			force = force + Lforce
		end

		return force
	end,

	-- /**
	-- * the total torque in the of the drone.
	-- *
	-- * @return the total torque of the drone.
	-- */
	getTotalTorque = function( self )

		local totalTorque = vmath.vector3(0, 0, 0)

		local mult = 0.5
		for i = 1, #self.liftForces do
			totalTorque = totalTorque + vmath.cross(planedata.relAirfoilPositions[i], self.liftForces[i]) * mult
		end
		return totalTorque
	end,

	lift = function(self, relPos, axis, attackVector, liftSlope)

		local normal = vmath.cross(axis, attackVector)
		local projectedAirSpeed = tf.orthogonalize(vmath.cross(self.angularV, relPos) + self.localVelocity , axis)
		local AOA = -1.0 * math.atan2(vmath.dot(projectedAirSpeed, normal), vmath.dot(projectedAirSpeed, attackVector))

		-- From NASA - https://www.grc.nasa.gov/www/k-12/WindTunnel/Activities/lift_formula.html
		-- L = (1/2) d v^2 s CL
		--  L - Lift 
		--  d - Atmospheric density 
		--  v - velocity of aircraft
		--  s - surface area of wing 
		--  CL - Coefficient of lift 

		local spd = vmath.length(projectedAirSpeed)
		local pos = self.transform.position
		local air = atmos.ISA( pos.y )

		local liftMag = 0.0
		local drag = vmath.vector3()
		
		local Cl = math.sin(AOA)
		local dynPressure = 0.5 * air.density * spd * spd
		liftMag = math.min(math.max(Cl * dynPressure * liftSlope, -1e10), 1e10) 

		local Cd = 0.1 * Cl
		local dragMag = math.abs(math.min(Cd * dynPressure * liftSlope, 1e10)) 
		drag = vmath.normalize(self.localVelocity) * dragMag

		-- lift vector
		return normal * liftMag - drag
	end,

	gravity 		= gravity,

	getPlaneData 	= function() return planedata end,

	setFlaps 		= function(self, state) 
		self.flap = state 
		if(state == nil) then self.throttle = self.throttle + 1; self:ThrottleDown() end
	end,
}

-- -------------------------------------------------------------------------

return f18model

-- -------------------------------------------------------------------------
