
local tinsert 	= table.insert
local tremove 	= table.remove
local tcount 	= table.getn

-- ---------------------------------------------------------------------------
-- Simple game state - global.. meh
local GAME = {

	EXIT 			= 2,

	SETUP 			= 10,

	LOGIN 			= 20,
	LOGGING_IN		= 21,
	LOGIN_OK 		= 30, 
	CONNECTING		= 31,

	LOGIN_FAIL		= 40,
	MENU 			= 50, 

	NEW_GAME		= 60, 
	HOST			= 70,
	CLIENT 			= 80, 

	GAME_JOINING	= 90,   -- Joining a game (host lobby)
	GAME_STARTING	= 91,   -- The host has started the game
	GAME_SCENARIO	= 93,   -- Scenario is being selected
	GAME_PLAY		= 94,	-- Players in game playing
	GAME_FINISH		= 99,   

	QUIT 			= 9999,
}

-- ---------------------------------------------------------------------------

local USER_EVENT = {

	NONE                = 0, 
	POLL                = 1,    -- This just keeps the connect alive
	ENDSTATE            = 2,    -- Use this to move to next state

	REQUEST_GAME        = 20,   -- Client needs game state
	REQUEST_ROUND       = 21,   -- Client needs round state
	REQUEST_SCENARIOS   = 22,   -- Fetch the list of scenarios

	REQUEST_START       = 30,   -- Owner wants to start
	REQUEST_READY       = 31,   -- Player changing ready state in lobby

	REQUEST_WAITING     = 40,   -- Player is waiting after a timeout or similar

	SENDING_SCENARIO    = 50,   -- MAster chooses scenario
}

-- ---------------------------------------------------------------------------

local MATCH_DATA = {

	NONE 			= 0,
	PLAYER_DATA 	= 1,	-- Send/Recv player name
	ROUND_DATA		= 3, 	-- Data shared during rounds
}

-- ---------------------------------------------------------------------------

local PERSON_LIMIT 		= 4

-- ---------------------------------------------------------------------------

local STATE_NAME 		= {
	[50]	= "MenuMain", 

	[60]	= "MenuNew", 
	[70] 	= "MenuLobby",
	[80]	= "NOT IN USE", 

	[90]	= "GameJoining",   
	[91]	= "GameStart",   
	[93]	= "GameScenario",   
	[94]	= "GameSelect",	
	[99] 	= "GameFinish",   
}

local function namelookup( state )

	return STATE_NAME[state]
end 

-- ---------------------------------------------------------------------------

local RADAR_STATE 	= {
	DISABLED 		= 0,
	PASSIVE 		= 1, 
	ACTIVE 			= 2, 
}

local RADAR_RANGE	= {
	[2] 			= "2 MILES",
	[10]			= "10 MILES", 
	[40] 			= "40 MILES",
	[100] 			= "100 MILES",
	[200] 			= "200 MILES",
}

local RADAR_RANGES 	= { 2, 10, 40 }

-- ---------------------------------------------------------------------------

local ENTITY_TYPE 	= {
	UNKNOWN 		= 0,	-- Not yet designated
	CIVILIAN 		= 1, 	-- Non combatants
	FRIENDLY 		= 2,	-- Friendly is on the same force
	ALLY 			= 3,	-- Ally is on the same team, but different force (usually another country)
	THREAT 			= 4,	-- Is an enemy force
	MISSILE			= 5,	-- A missile - not detectable on radar 
}

local THREAT_COLOR	= {
	[0] 			= vmath.vector3(0.7, 0.0, 0.75),	-- purple
	[1] 			= vmath.vector3(0.0, 0.7, 0.0),		-- green
	[2] 			= vmath.vector3(0.0, 0.0, 0.75),	-- blue
	[3] 			= vmath.vector3(0.3, 0.3, 0.75),	-- light blue
	[4] 			= vmath.vector3(0.7, 0.0, 0.0),		-- red
}

-- ---------------------------------------------------------------------------
-- mtype will be an interface type - initially just a country code

-- AIM 120 DATA here - base burnrate - http://www.zaretto.com/sites/zaretto.com/files/missile-aerodynamic-data/AIM120C5-Performance-Assessment-rev2.pdf
local burn_rate = 51.0 / 7.75   -- kgs per sec 

local WEAPONS_TYPE 	= {
	["AM"]		= { id = "aim120",  mass = 150, speed = 700, fuel = 51, br = burn_rate, explosive = "blast1", mtype = "USA" },
	["SW"] 		= { id = "sidewinder", mass = 150, speed = 800,  fuel = 51, br = burn_rate,  explosive = "blast2", mtype = "USA" },
	["R27"]		= { id = "r27", mass = 150, speed = 700,  fuel = 51, br = burn_rate,  explosive = "blast1", mtype = "USSR" },
	["R60"]		= { id = "r60", mass = 150, speed = 800,  fuel = 51, br = burn_rate,  explosive = "blast2", mtype = "USSR" },

	["CRUISE"]	= { id = "cruise", mass = 300, speed = 400,  fuel = 100, br = burn_rate, explosive = "blast3", mtype = "USSR" },
}

-- ---------------------------------------------------------------------------

return {
	namelookup 	= namelookup,
	
	USER_EVENT	= USER_EVENT,
	GAME 		= GAME,
	MATCH_DATA 	= MATCH_DATA,

	PERSON_LIMIT= PERSON_LIMIT,

	RADAR_STATE = RADAR_STATE,
	RADAR_RANGE = RADAR_RANGE,
	RADAR_RANGES= RADAR_RANGES,
	ENTITY_TYPE = ENTITY_TYPE,
	THREAT_COLOR= THREAT_COLOR,
	WEAPONS_TYPE= WEAPONS_TYPE,
}

-- ---------------------------------------------------------------------------
