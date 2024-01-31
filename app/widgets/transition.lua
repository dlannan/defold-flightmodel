------------------------------------------------------------------------------------------------------------
-- State - Create popup with timer
--
-- Decription: 	Popup a dialog, blur background and change to new state 
------------------------------------------------------------------------------------------------------------

local utils 	= require("app.utils")
local tween 	= require("app.tween")

------------------------------------------------------------------------------------------------------------

local POPUP_TWEEN 	= 'inOutCubic'


------------------------------------------------------------------------------------------------------------

local Stransition	= NewState()

------------------------------------------------------------------------------------------------------------
-- Set state config here  Stransition.name = "POPUP"

-- Change this to set new timeout
Stransition.TIME_SETTING  		= 2.0
Stransition.BLUR_ENABLE 		= true
Stransition.TOP 				= 0.0

-- Default text
Stransition.text 	= "Continue."
Stransition.textsize = utils.generaltextsize

-- Default dimensions and positioning
Stransition.width 	= utils.buttonwidth * 0.8
Stransition.height 	= utils.buttonheight * 4.0

-- Next state to go to  (if nil, it returns to top state)
Stransition.next 	= nil 
Stransition.prev 	= nil

------------------------------------------------------------------------------------------------------------

function gTransition( left, right, timer, dir, text, width, height )

	local popup = gSmgr.states["Transition"]
	popup.right 	= right
	popup.left 		= left
		
	popup.dir 		= dir
	Stransition.TIME_SETTING  = timer or 2.0
	popup.text 		= text or popup.text
	popup.width 	= width or popup.width 
	popup.height	= height or popup.height

	gSmgr:ChangeState("Transition")
end 

------------------------------------------------------------------------------------------------------------

function Stransition:Begin()

	local self  = Stransition.self

	-- Choose to overlay background with a blur
	Stransition.bgblur 	= Stransition.BLUR_ENABLE

	-- Amount of time the popup appears for before moving to next state 
	Stransition.timeout 	= Stransition.TIME_SETTING

	-- Offset from the top of the box
	Stransition.top 		= Stransition.TOP
	
	-- Left and right window states
	Stransition.stateLeft 	= gSmgr:GetState(Stransition.left)
	Stransition.stateRight 	= gSmgr:GetState(Stransition.right)
	
	if(Stransition.dir == -1) then 
		Stransition.stateRight.self = self 
		Stransition.stateRight.once = nil
		Stransition.stateRight:Begin()
	else 
		Stransition.stateLeft.self = self 
		Stransition.stateLeft.once = nil
		Stransition.stateLeft:Begin()
	end
	
	-- Moving to top left 
	Stransition.pos = { x = 0, y = 0, }

	-- Starting top right
	posstart = { x = self.width, y = 0,	}

	if(Stransition.dir == 1) then 
		Stransition.pos.x = self.width 
		posstart.x = 0.0
	end

	Stransition.stateLeft.windowx = posstart.x - self.width
	Stransition.stateRight.windowx = posstart.x
	
	Stransition.tweenwin = nil
	Stransition.tweenwin = tween.new(Stransition.timeout, posstart, Stransition.pos, POPUP_TWEEN, function(tweenobj)
		Stransition.tweenwin = nil
		if(Stransition.dir == -1) then 
			gSmgr:Transition( Stransition.right )
		else 
			gSmgr:Transition( Stransition.left )
		end
	end)
end

------------------------------------------------------------------------------------------------------------
function Stransition:Update(mxi, myi, buttons)

	local self  = Stransition.self
	local dt    = Stransition.dt
	
end

------------------------------------------------------------------------------------------------------------

function Stransition:Render()
	
	local self  = Stransition.self
	local dt    = Stransition.dt

	local pos = Stransition.pos
	if(Stransition.tweenwin) then 
		pos = Stransition.tweenwin.subject
		Stransition.tweenwin:update(dt)
	end

	Stransition.stateLeft.windowx = pos.x - self.width
	Stransition.stateRight.windowx = pos.x

	Stransition.stateRight.self = self 
	Stransition.stateRight.dt   = 0.0

	Stransition.stateLeft.self = self 
	Stransition.stateLeft.dt   = 0.0
	
	Stransition.stateLeft:Render()
	Stransition.stateRight:Render()
end

------------------------------------------------------------------------------------------------------------

function Stransition:Finish()
	local self  = Stransition.self
	
	-- On exit, we finish previous state
	if(Stransition.dir == -1) then 
		Stransition.stateLeft:Finish()
	else
		Stransition.stateRight:Finish()
	end
end
	
------------------------------------------------------------------------------------------------------------

return Stransition

------------------------------------------------------------------------------------------------------------
	