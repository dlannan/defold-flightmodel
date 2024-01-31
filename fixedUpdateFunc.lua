-- // ----------------------------------------------------------------------------

local gravity 			= 9.81  		-- m/s^2
-- TODO: Terrain lookup
local groundLevel 		= 1.9

-- // ----------------------------------------------------------------------------

local tf = require("utils.transforms")

-- // ----------------------------------------------------------------------------

local planedata = {
	wingX				= 4.15, 		-- m
	wingZ 				= 0.0,			-- m
	tailArea 			= 10,     		-- m^2
	tailX 				= 2.6, 			-- m
	tailZ 				= 3.5,			-- m

	bodyMass			= 5000,
	bodyArea			= 6,
	bodyZ 				= -1.0,
	
	engineMass			= 1035,  		-- kg	The engine mass is off center
	engineZ				= 2.2,			-- m
	wingMass 			= 700,  		-- kg
	tailMass 			= 300,  		-- kg
	wingArea 			= 17, 			-- m^2
	
	maxMilitary 		= 49000 * 2, 	-- N Each engine non after burner
	maxAfterburn		= 79000 * 2, 	-- N Each engine with after burner

	maxVelocity 		= 531.936, 		-- m/s or 1,034 knots

	maxFuel				= 4930,			-- kg
	maxFuelUseMil		= 23, 			-- g/(kN⋅s)
	maxFuelUseAB		= 49, 			-- g/(kN⋅s)

	stallSpeed			= 69.45,		-- m/s

	-- Launch speed for f18 on carrier - 165 knots - 85 m/s
	initialVelocity		= vmath.vector3( 0.0, 0.0, -285.0),
	initialHeading 		= math.rad(180),

	maxAOA 				= math.rad( 20 ),  -- radian

	pitchMinimum 		= 0.0, -- -0.042,		  -- radian (minimum pitch for air surface).
	
	debug 				= false,
}

-- // ----------------------------------------------------------------------------

local function FixedUpdate(self, dt)

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
	
	local h = dt
	if(self.paused) then h = 0.0 end
	if(self.collision) then return end 

	-- get force as a global vector
	self.totalForceL = self:getTotalForce()
	self.totalForce = self.transform.TransformVector(self.transform.rotation, self.totalForceL)
	-- set torque
	self.totalTorque = self:getTotalTorque()
	-- Work out kN-s for fuel usage 
	local kgsFuel = self.thrust * 0.001 * h * planedata.maxFuelUseMil
	self.fuel = math.max(0, self.fuel - kgsFuel * 0.001)
	self.fuelPercent = ( self.fuel / planedata.maxFuel )
	
	local accelV = self.totalForce / self.mass
	local osaccel = Vec3Set(accelV.x, accelV.y, accelV.z) 

-- -- // damp out abrupt changes and oscillations in steering acceleration
-- -- // (rate is proportional to time step, then clipped into useful range)
	if (h > 0.0) then 
		local smoothRate = clip(9.0 * h, 0.15, 0.4)
    self._smoothedAcceleration = blendIntoAccumulatorV(smoothRate, osaccel, self._smoothedAcceleration)
	end
-- -- // Euler integrate (per frame) acceleration into velocity
	osaccel = self._smoothedAcceleration.mult(h)
	local accel = vmath.vector3(osaccel.x, osaccel.y, osaccel.z)
	-- setVelocity
	local newvelocity = self.velocity + accel

	-- setPosition
	self.prevpos = self.transform.position
	self.transform.position = self.prevpos + newvelocity * h -- + self.acceleration * 0.5 * h * h
	self.velocity = newvelocity

	if( vmath.length(self.velocity) > planedata.maxVelocity ) then 
		local velocityDir = vmath.normalize(self.velocity)
		self.velocity = planedata.maxVelocity * velocityDir
	end 
	
	self.acceleration = accel
	
	-- angularAcc
	-- calculate angularAcc
	self.angularAcc = vmath.vector3(self.inertiaMatrixInv.x * self.totalTorque.x, self.inertiaMatrixInv.y * self.totalTorque.y, self.inertiaMatrixInv.z * self.totalTorque.z)
	-- angularV
	self.angularV = self.angularV + self.angularAcc * h
	--self.angularV = self.angularV * math.max(1 - (0.5 * h), 0) -- I dont think this is needed anymore

	local angRot = self.angularV * h
	-- Stop accumulative angles
	angRot.x = angRot.x % (2.0 * math.pi)
	angRot.y = angRot.y % (2.0 * math.pi)
	angRot.z = angRot.z % (2.0 * math.pi)
	self.transform.rotation = self.transform.rotation * tf.RotateEuler(angRot)

	self.angles = tf.ToEulerAngles(self.transform.rotation)
	-- self.angles.y = vmath.normalize( self.transform.TransformVector(self.currRot, vmath.vector3(0,0,-1)) ).y
--		self.angles.z = tf.ToEulerAngles(self.transform.rotation).z

	if(self.transform.position.y < groundLevel) then 

		self.collision = true
		self.transform.position.y = groundLevel
	end 
	-- pprint(self.transform.position)
	-- pprint(self.thrust.."  "..self.leftWingInclination.."  "..self.rightWingInclination.."  "..self.totalTorque.x)
	-- pprint(self.velocity)
end

-- // ----------------------------------------------------------------------------

return FixedUpdate, planedata

-- // ----------------------------------------------------------------------------