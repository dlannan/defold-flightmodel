------------------------------------------------------------------------------------------------------------
-- State - Create popup with timer
--
-- Decription: 	Popup a dialog, blur background and change to new state 
------------------------------------------------------------------------------------------------------------

local utils 	= require("app.utils")
local tween 	= require("app.tween")

------------------------------------------------------------------------------------------------------------

local POPUPMODE = {

	INSTANT		= 0,
	INLEFT 		= 1,
	INRIGHT		= 2,
	INTOP		= 3,
	INBOTTOM	= 4,
}

local POPUP_TWEEN 	= 'inOutCirc'
local POPUP_TIMER 	= 0.5

------------------------------------------------------------------------------------------------------------

function gPopupWin( top, text, width, height )

	local popup = gSmgr.states["PopupWin"]
	popup.prev 	= gSmgr.current
	popup.TOP 	= top
	popup.text 	= text or popup.text
	popup.width = width or popup.width 
	popup.height = height or popup.height
	gSmgr:JumpToState("PopupWin")
end 

------------------------------------------------------------------------------------------------------------

local Spopup	= NewState()

------------------------------------------------------------------------------------------------------------
-- Set state config here  Spopup.name = "POPUP"

-- Change this to set new timeout
Spopup.TIME_SETTING  	= 2.0
Spopup.BLUR_ENABLE 		= true
Spopup.TOP 				= 0.0

-- Default text
Spopup.text 	= "Continue."
Spopup.textsize = utils.generaltextsize

-- Default dimensions and positioning
Spopup.width 	= utils.buttonwidth * 0.8
Spopup.height 	= utils.buttonheight * 4.0

-- Mode - these are the supported modes
Spopup.mode 	= POPUPMODE.INLEFT

-- Next state to go to  (if nil, it returns to top state)
Spopup.prev 	= nil

------------------------------------------------------------------------------------------------------------

function Spopup:Begin()

	local self  = Spopup.self
	
	-- Choose to overlay background with a blur
	Spopup.bgblur 	= Spopup.BLUR_ENABLE

	-- Amount of time the popup appears for before moving to next state 
	Spopup.timeout 	= Spopup.TIME_SETTING

	-- Offset from the top of the box
	Spopup.top 		= Spopup.TOP

	Spopup.pos = {
		x = self.width * 0.5 - Spopup.width * 0.5,
		y = self.height * 0.5 - Spopup.height * 0.5,
	}

	posstart = {
		x = -Spopup.width,
		y = self.height * 0.5 - Spopup.height * 0.5,
	}

	Spopup.tweenwin = nil
	if(Spopup.mode > POPUPMODE.INSTANT) then 
		Spopup.tweenwin = tween.new(POPUP_TIMER, posstart, Spopup.pos, POPUP_TWEEN, function(tweenobj)
			Spopup.tweenwin = nil
			timer.delay(Spopup.timeout - POPUP_TIMER * 2.0, false, function()
				posend = {
					x = self.width + Spopup.width,
					y = self.height * 0.5 - Spopup.height * 0.5,
				}
				
				Spopup.tweenwin = tween.new(POPUP_TIMER, Spopup.pos, posend, POPUP_TWEEN, function(tweenobj)
					Spopup.tweenwin = nil 
				end)
			end)
		end)
	end

	timer.delay(Spopup.timeout, false, function()
		gSmgr:ExitState()
	end)
end

------------------------------------------------------------------------------------------------------------
function Spopup:Update(mxi, myi, buttons)

end

------------------------------------------------------------------------------------------------------------

local flags = imgui.WINDOWFLAGS_NOTITLEBAR
--	flags = bit.bor(flags, imgui.WINDOWFLAGS_NOBACKGROUND)
flags = bit.bor(flags, imgui.WINDOWFLAGS_NORESIZE)
flags = bit.bor(flags, imgui.WINDOWFLAGS_NOMOVE)
flags = bit.bor(flags, imgui.WINDOWFLAGS_NOSCROLLBAR)

function Spopup:Render()
	
	local self  = Spopup.self
	local dt    = Spopup.dt

	local prevstate = gSmgr.states[Spopup.prev]
	if(prevstate) then prevstate:Render() end 

	local pos = Spopup.pos
	if(Spopup.tweenwin) then 
		pos = Spopup.tweenwin.subject
		Spopup.tweenwin:update(dt)
	end
	imgui.set_next_window_pos(pos.x, pos.y)
	imgui.set_next_window_size(Spopup.width, Spopup.height)

	imgui.begin_window("popup", false, flags)
	imgui.set_window_font_scale(1.0)

	imgui.set_cursor_pos(0, 0)
	-- imgui.image_add(self.img_list_flat, Spopup.width, Spopup.height)

	imgui.font_scale(self.fonts["Regular"], utils.generaltextsize)
	imgui.font_push(self.fonts["Regular"])

	local x = 20 * self.scale
	local y = 20 * self.scale + Spopup.top

	utils.draw_aligned_text(self, Spopup.text, x, y, Spopup.width - 40 * self.scale, Spopup.textsize)
	
	imgui.font_pop()
	imgui.end_window()	
end

------------------------------------------------------------------------------------------------------------

function Spopup:Finish()
end
	
------------------------------------------------------------------------------------------------------------

return Spopup

------------------------------------------------------------------------------------------------------------
	