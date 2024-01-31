
local tinsert         = table.insert

local tf              = require("utils.transforms")
local dgo             = require("utils.defold-gameobjects")

local flightModel     = require("app.states.models.f18-model")
local weapons         = require("app.states.models.f18-weapons")

-- // ----------------------------------------------------------------------------

local f18weapons = { "AM 1", "AM 2", "AM 3", "AM 4", "SW 1", "SW 2" }

local f18                 = {}
local gop                 = nil

f18.oldTime               = 0
f18.currentTime           = 0
f18.elapsedTime           = 0

f18.checkRadius           = 30.0
f18.minimumDistance       = 20.0

------------------------------------------------------------------------------------------------------------
-- Set state config here  Mmission.name = "MASTER"
------------------------------------------------------------------------------------------------------------

local PITCH_RATE 	= math.rad(8.0)
local ROLL_RATE 	= math.rad(3.0)

local enums 	    = require "app.gameEnums"
local GAME	 	    = enums.GAME
local RADAR_RANGE 	= enums.RADAR_RANGE 
local RADAR_RANGES  = enums.RADAR_RANGES
local ENTITY_TYPE 	= enums.ENTITY_TYPE
local WEAPONS       = enums.WEAPONS_TYPE

------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------

local MAP_IDS = nil
local function mid( str ) 

    local id = str
    if(type(str) == "string") then 
        id = MAP_IDS[hash(str)]
    end 
    if(comp) then 
        return msg.url(nil, id, comp)
    end
    return id
end 

------------------------------------------------------------------------------------------------------------
local GAME_IDS = nil
local function gid( str, comp ) 

    local id = str
    if(type(str) == "string") then 
        id = GAME_IDS[hash(str)]
    end 
    if(comp) then 
        return msg.url(nil, id, comp)
    end
    return id
end 

---------------------------------------------------------------------------------
-- Build poly paths for the tanks

local function MakePath( pts, radius )

    -- convert points to OSVec3 
    local points = {}
    local radius = radius or 1

    local ptcount = 0 
    for k,v in pairs(pts) do  
        points[ptcount] = Vec3Set(v.x, v.y, v.z)
        ptcount = ptcount + 1
    end

    local polypath = OSPathway()
    polypath.initialize( ptcount, points, radius, true )
    return polypath
end

------------------------------------------------------------------------------------------------------------

local function sendradardata(self)

    if(self.f18 == nil) then return end 
    Sradar:Update(Sgamefreeplay, self.f18)
    local tpos = {x=0.0, y=0.0, z=0.0}
    local rdata = { 
        pos 		= vmath.vector3(tpos.x, tpos.y, tpos.z),
    }
    --msg.post(gid("/gui-cockpit"), "f18-radar", rdata)
end

------------------------------------------------------------------------------------------------------------

local function SetDebug( val )

    flightModel:toggleDebug()
end
    
------------------------------------------------------------------------------------------------------------

local function setupFlightModel( self, startpos, startrot )

    flightModel.transform.position = startpos
    flightModel.transform.rotation = startrot
    flightModel.thrust =100000
    flightModel:Awake(self.mover)
    flightModel:Start( flightModel.transform.rotation )
end 

-- // ----------------------------------------------------------------------------

local function loadResource( self )
    
    -- Yuk
    return launch_pos
end

-- // ----------------------------------------------------------------------------

local function checkWarnings( self) 

    local msg = { warnings = {nil, nil, nil, nil, nil} }
    if(self.mover.speed() < self.planedata.stallSpeed) then msg.warnings[3] = true end 
    return msg
end
    
-- // ----------------------------------------------------------------------------

local function f18Updater( self, currentTime, elapsedTime, simself ) 

    self.oldTime = self.currentTime
    self.currentTime = currentTime  
    self.elapsedTime = elapsedTime
    self.frames = (self.frames or 0) + 1

    flightModel.paused     = self.data.paused
    self.weapon_select     = nil

    -- Check warnings 
    local message         = checkWarnings(self)
    if(self.m_target) then 
        message.targetpos = go.get_world_position(self.m_target)
    end
    --msg.post(gid("/gui-cockpit"), "f18", message)

    if(self.frames % 10 == 0) then 
        sendradardata(simself)
    end 
    
    flightModel:FixedUpdate(elapsedTime)
    flightModel:Update(elapsedTime)

    -- I dont really like this - need better event/state way
    gop.set("MISSION_F18MODEL", flightModel)

    self.data.collision = flightModel.collision

    local pos = flightModel.currPos
    local rot = flightModel.currRot

    if(self.mover and self.m_MyID) then 
        self.mover.setPosition( Vec3Set(pos.x, pos.y, pos.z ) )
        self.mover._quat = rot
        
        go.set_position(pos, self.m_MyID)
        go.set_rotation(rot, self.m_MyID)

        local vel = vmath.normalize(flightModel.velocity)
        self.mover.setForward(Vec3Set(vel.x, vel.y, vel.z) )
        self.mover.setSpeed( flightModel.speed )
    end
end

-- // ----------------------------------------------------------------------------

local Player = function( self, id, data, updater )

    local lplayer = {}
    -- // constructor
    lplayer.m_MyID = id

    if(data and data.path) then 
        lplayer.ospath = MakePath( data.path.data, 400 )
    end 
    
    -- // reset state
    lplayer.reset = function() 
        lplayer.dist = 0.0
        lplayer.data = data
        
        lplayer.m_home       = nil
        lplayer.m_target     = nil
        lplayer.m_targetKey  = nil 
        
        setupFlightModel(lplayer, data.pos, data.rot)

        print("---------> f18 added")
    end

    -- // per frame simulation update
    lplayer.update = function( currTime, elapsedTime ) 

        weapons:Update(currTime)
        updater(lplayer, currTime, elapsedTime, self)
        Sradar:Render(currTime)
    end

    lplayer.close = function()

        weapons:Finish()
        Sradar:Finish(Sgamefreeplay)
        if(self.radartimer) then timer.cancel(self.radartimer) end
        if(lplayer.data.go) then go.delete(lplayer.data.go, true) end
        lplayer.mover      = nil
        lplayer.m_MyID     = nil
    end

    lplayer.reset()
    return lplayer
end

-- // ----------------------------------------------------------------------------

local function f18Init(self, id, data) 

    local f18 			= nil --f18player.f18 
    local f18_mesh 		= nil --f18player.f18_mesh
    
    data = {
        go           = nil, --f18player.f18,
        mesh         = nil, --f18player.f18_mesh,
        pos          = launch_pos,
        rot          = rot,
        collision    = nil,
        paused       = true,
        debug        = nil,
        etype        = ENTITY_TYPE.FRIENDLY,
    }

    model.play_anim(f18_mesh, "f18-5", go.PLAYBACK_NONE)
    flightModel.paused = true
    
    -- Create f18 player (ai or real)
    local entity = Player( self, data.go, data, f18Updater )
    -- entities are updated using the proximity db

    weapons:Begin()

    entity.planedata = flightModel.getPlaneData()
    return entity
end

------------------------------------------------------------------------------------------------------------
-- Choose the next available target (this will enable the reticule if there is any)
local function nextTarget(self)

    local contacts = Sradar.contacts
    local k,v = next(contacts, self.f18.m_targetKey) 
    self.f18.m_targetKey  = k
    self.f18.m_target     = nil
    if(v) then self.f18.m_target = v.go end
end

------------------------------------------------------------------------------------------------------------

local function f18Input( self, action_id, action, dt  ) 


    if( action_id == hash("key_slash") and action.released) then 

        flightModel:LoadFixedUpdate("fixedUpdateFunc.lua")
    end 

    if(flightModel.collision == nil) then

        if(action_id == hash("key_t") and action.released) then 
            nextTarget(self)
        end
        
        -- Select weapons - cycle through weapon selections
        if(action_id == hash("key_tab") and action.released) then 
            weapons:CycleWeapons()
        end

        if(action_id == hash("key_space") and action.released) then 
            weapons:FireWeapon()
        end
        
        if(action_id == hash("key_r") and action.released) then 
            Sradar.range = (Sradar.range + 1) % #RADAR_RANGES
            sendradardata(self)
        end

        if(action_id == hash("key_g") and action.released) then
            self.gear = not self.gear
            if(self.gear == false) then 
                --msg.post(gid("/gui-cockpit"), "gear", { state = "down"} )
                go.animate(self.f18.data.mesh, "cursor", go.PLAYBACK_ONCE_FORWARD, 1, go.EASING_INOUTQUAD, 5)
                flightModel:setFlaps(nil)
            else 
                --msg.post(gid("/gui-cockpit"), "gear", { state = "up"} )
                go.animate(self.f18.data.mesh, "cursor", go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_INOUTQUAD, 5)
                flightModel:setFlaps(true)
            end
        end

        if(action_id == hash("key_1") and action.released) then 
            flightModel:ThrottleUp()
        end
        if(action_id == hash("key_2") and action.released) then 
            flightModel:ThrottleDown()
        end

        if(action_id == hash("key_w")) then 
            if(action.released) then
                flightModel:PitchUp(0)
            else 
                flightModel:PitchUp(PITCH_RATE * dt)
            end
        end
        if(action_id == hash("key_s")) then 
            if(action.released) then
                flightModel:PitchDown(0)
            else 
                flightModel:PitchDown(PITCH_RATE * dt)
            end
        end

        if(action_id == hash("key_a")) then 
            if(action.released) then 
                flightModel:RollLeft(0)
            else 
                flightModel:RollLeft(ROLL_RATE * dt)
            end
        end
        if(action_id == hash("key_d")) then 
            if(action.released) then 
                flightModel:RollRight(0)
            else 
                flightModel:RollRight(ROLL_RATE * dt)
            end
        end

        if(action_id == hash("key_period")) then 
            if(action.released) then 
                flightModel:RudderLeft(0)
            else 
                flightModel:RudderLeft(ROLL_RATE * dt)
            end
        end

        if(action_id == hash("key_comma")) then 
            if(action.released) then 
                flightModel:RudderRight(0)
            else 
                flightModel:RudderRight(ROLL_RATE * dt)
            end
        end

    end

    -- move directional light based on input
    -- self.light.x = 2 * ((action.x - 480) / 480)
    -- self.light.y = 2 * ((action.y - 320) / 320)
    -- model.set_constant("/f18#f18", "light", self.light)
end 

-- // ----------------------------------------------------------------------------

local function f18Message( owner, message_id, message, sender )
end

-- // ----------------------------------------------------------------------------

f18.init          = f18Init
f18.input         = f18Input
f18.message       = f18Message
f18.toggleDebug   = SetDebug

f18.loadResource  = loadResource

return f18

-- // ----------------------------------------------------------------------------
