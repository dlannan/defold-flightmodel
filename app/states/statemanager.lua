----------------------------------------------------------------
-- Simple State Manager.
----------------------------------------------------------------

local utils = require "app.utils"

----------------------------------------------------------------

State = 
{
	-- By default, states will run (Call Exit to leave a state and possibly stop execution)
	run 	= true,
	
	Begin = function()
	end,
	 
	Finish = function ()
	end,
	 
	Update = function(px, py, buttons)
	end,
	 
	Render = function()
    end,
} 

----------------------------------------------------------------

function NewState()
	return utils.deepcopy(State)
end

----------------------------------------------------------------

local StateManager =
{
	-- Index into the states and statenames being used.
	current		= "",
	start   	= nil,

	-- Are the states being executed at the moment, jumped?
	jumped   	= 0, 

    -- Some ways to integrate with Defold easily - bit hacky
    self        = nil,
    dt          = nil,
}

----------------------------------------------------------------

function StateManager:GetCurrent()

    if self.current == "" or self.current == nil then return nil end 
    return self.states[self.current]
end

----------------------------------------------------------------

function StateManager:GetState( state )

    if state == "" or state == nil then return nil end 
    return self.states[state]
end

----------------------------------------------------------------

function StateManager:Run()

	if self.current == "" then return true end 
	local state = self.states[self.current]
	return state.run
end

----------------------------------------------------------------
	
-- Create the statemanager
function StateManager:Init()

	self.states = {}
    self.stack 	= {}
end
	
----------------------------------------------------------------
-- On update manage the current states
function StateManager:Update(px, py, buttons)
	if self.current == "" then return end 
	local state = self.states[self.current]
    if state ~= nil then
        state.self  = StateManager.self
        state.dt    = StateManager.dt
        state:Update(px, py, buttons)
    end
end
	
----------------------------------------------------------------
-- On update manage the current states
function StateManager:Render()
	if self.current == "" then return end
	local state = self.states[self.current]
    if state ~= nil then
        state.self  = StateManager.self
        state.dt    = StateManager.dt
        state:Render()
    end
end

----------------------------------------------------------------
-- On message send to the current state
function StateManager:Message( owner, message_id, message, sender )
    if self.current == "" then return end
    local state = self.states[self.current]
    if state ~= nil and state.Message then
        state:Message( owner, message_id, message, sender )
    end
end

----------------------------------------------------------------
-- On input send to the current state
function StateManager:Input( owner, action_id, action )
    if self.current == "" then return end
    local state = self.states[self.current]
    if state ~= nil and state.Input then
        state:Input( owner, action_id, action )
    end
end


----------------------------------------------------------------
-- Create a new state then return the state object
function StateManager:CreateState(name, newstate)

    newstate.name     = name 
	self.states[name] = newstate
end

----------------------------------------------------------------
-- A ChangeState invokes an End on the current state, And 
-- a Begin on the Next state.

function StateManager:ChangeState(name)

	print("Changing State to... "..name)
	local state = self.states[name]
	if state == nil then 
		print("Error: Invalid State Name: "..name)
		return 
	end
	
    if self.start == nil then 
        self.current = name
		self.start = self.states[self.current]
    else
        self.states[self.current].self  = StateManager.self
        self.states[self.current]:Finish()
    end
    
    if state ~= nil then
        self.current = name
        self.states[self.current].self  = StateManager.self
        self.states[self.current].once  = nil
        self.states[self.current]:Begin()
    end
end 

----------------------------------------------------------------
-- A Transition is used to control Update and Render
--   Another state will transition between two states

function StateManager:Transition(name)

    print("Transitioning State to... "..name)
    local state = self.states[name]
    if state == nil then 
        print("Error: Invalid State Name: "..name)
        return 
    end

    if self.start == nil then 
        self.current = name
        self.start = self.states[self.current]
    else
        self.states[self.current].self  = StateManager.self
    end

    if state ~= nil then
        self.current = name
        self.states[self.current].self  = StateManager.self
    end
end 

----------------------------------------------------------------
--  SetVariable
-- Allows the setting of state variables - like sound, level etc.
-- Some special var names set profile information

function StateManager:SetVariable(name, val)


end

----------------------------------------------------------------
-- JumpToState moves To another state While maintaining, the
--  previous one. Once complete, a jumped state will Return To
--  the original owner of the child state.

-- End is Not called on the current state, Begin And End
-- are called on the child state.

function StateManager:JumpToState(name)

	print("Jumping State to... "..name)
	local state = self.states[name]
	if state == nil then 
		print("Error: Invalid State Name: "..name)
		return 
	end
    
    -- Entering jump state - could be multiple depth, cannot Exit
    -- Until stack is correctly depleted (Or stack out of balance)
    if self.jumped == 0 then 
        self.jumped = 1
        self.stack = {} 
    else 
        self.jumped = self.jumped + 1
    end
    -- Alreay in jump state, Then keep going...
    -- Put current onto stack
    self.stack[self.jumped] = self.current
    
    -- Enter New state  
    if state ~= nil then
        self.current = name
        self.states[self.current].self  = StateManager.self
        self.states[self.current].once  = nil
        self.states[self.current]:Begin()
    end
end 

----------------------------------------------------------------
-- Exit out of the current Jumped state

function StateManager:ExitState()

	-- If exiting a normal state, then set run to false, call Finish and 
	-- exit state manager (likely)
    if self.jumped == 0 then
        self.states[self.current].run = false
        self.states[self.current].self  = StateManager.self
        self.states[self.current]:Finish()
        print("Exiting state..."..self.current)
        return
    end

    -- Examine stack To see If there is a valid jumpstate on it
    -- If there is only one left, this is the normal parent, so Return
    -- sensibly To it, otherwise pop the stack And change
    if self.jumped > 0 then
        self.states[self.current].self  = StateManager.self
        self.states[self.current]:Finish()
        
        print("Exiting state..."..self.current)
        local name = self.stack[self.jumped]
		state = self.states[name]

        if state ~= nil then
            self.current = name
        end
        
        self.jumped = self.jumped - 1
    end
end
----------------------------------------------------------------
-- Call a function just once (until next begin)
function StateManager:OneShot( state, callback )

    if(state.once == nil) then 
        state.once  = 1
        if callback then callback() end
    end
end
    
----------------------------------------------------------------


return StateManager

----------------------------------------------------------------


