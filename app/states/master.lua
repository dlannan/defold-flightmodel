------------------------------------------------------------------------------------------------------------
-- State - Master contol state 
--
-- Decription: 	Control the movement to other states 
------------------------------------------------------------------------------------------------------------

local tinsert 	= table.insert
local tremove 	= table.remove

-- ---------------------------------------------------------------------------

local utils 	= require("app.utils")

-- local mdata 	    = require("app.menusData")
-- local mngame 	= require("app.menusNewgame")

-- local gplayer 	= require("app.gamePlayer")

------------------------------------------------------------------------------------------------------------

local Smaster	= NewState()

------------------------------------------------------------------------------------------------------------
-- Set state config here  Smaster.name = "MASTER"
-- ---------------------------------------------------------------------------

local PERSON_LIMIT 		= 4
local TRAIT_LIMIT 		= 4 

local enums 	        = require "app.gameEnums"
local GAME	 	        = enums.GAME

local flags = imgui.WINDOWFLAGS_NOTITLEBAR
--	flags = bit.bor(flags, imgui.WINDOWFLAGS_NOBACKGROUND)
flags = bit.bor(flags, imgui.WINDOWFLAGS_NORESIZE)
flags = bit.bor(flags, imgui.WINDOWFLAGS_NOMOVE)
flags = bit.bor(flags, imgui.WINDOWFLAGS_NOSCROLLBAR)

-- ---------------------------------------------------------------------------

local buttonwidth 		= 400
local buttonheight 		= 80
local buttontextsize 	= 0.65

local generaltextsize 	= 0.65
local smalltextsize 	= 0.55
local mediumtextsize	= 0.75
local largetextsize		= 1.0

local fontsizebase 		= 60.0
local spacing 			= 2.0 

-- ---------------------------------------------------------------------------
local function set_style()
	imgui.set_style_window_rounding(0)
	imgui.set_style_frame_rounding(0)
	imgui.set_style_scrollbar_rounding(0)
	imgui.set_style_color(imgui.ImGuiCol_Text, 1.0, 1.0, 1.0, 0.90)
	imgui.set_style_color(imgui.ImGuiCol_TextDisabled, 0.60, 0.60, 0.60, 1.00)
	imgui.set_style_color(imgui.ImGuiCol_WindowBg, 0.0, 0.0, 0.0, 1.00)
	imgui.set_style_color(imgui.ImGuiCol_PopupBg, 0.9, 0.9, 0.9, 0.85)
	imgui.set_style_color(imgui.ImGuiCol_Border, 0.0, 0.0, 0.0, 1.0)
	imgui.set_style_color(imgui.ImGuiCol_BorderShadow, 0.00, 0.00, 0.00, 0.00)
	imgui.set_style_color(imgui.ImGuiCol_FrameBg, 0.0, 0.0, 0.0, 1.00)
	imgui.set_style_color(imgui.ImGuiCol_FrameBgHovered, 0.9, 0.9, 0.9, 0.40)
	imgui.set_style_color(imgui.ImGuiCol_FrameBgActive, 0.90, 0.65, 0.65, 0.45)
	imgui.set_style_color(imgui.ImGuiCol_TitleBg, 0.00, 0.00, 0.00, 0.83)
	imgui.set_style_color(imgui.ImGuiCol_TitleBgCollapsed, 0.40, 0.40, 0.80, 0.20)
	imgui.set_style_color(imgui.ImGuiCol_TitleBgActive, 0.00, 0.00, 0.00, 0.87)
	imgui.set_style_color(imgui.ImGuiCol_MenuBarBg, 0.01, 0.01, 0.02, 0.80)
	imgui.set_style_color(imgui.ImGuiCol_ScrollbarBg, 0.93, 0.89, 0.79, 1.00)
	imgui.set_style_color(imgui.ImGuiCol_ScrollbarGrab, 0.55, 0.53, 0.55, 0.51)
	imgui.set_style_color(imgui.ImGuiCol_ScrollbarGrabHovered, 0.56, 0.56, 0.56, 1.00)
	imgui.set_style_color(imgui.ImGuiCol_ScrollbarGrabActive, 0.56, 0.56, 0.56, 0.91)
	imgui.set_style_color(imgui.ImGuiCol_CheckMark, 0.90, 0.90, 0.90, 0.83)
	imgui.set_style_color(imgui.ImGuiCol_SliderGrab, 0.70, 0.70, 0.70, 0.62)
	imgui.set_style_color(imgui.ImGuiCol_SliderGrabActive, 0.30, 0.30, 0.30, 0.84)
	imgui.set_style_color(imgui.ImGuiCol_Button, 0.48, 0.72, 0.89, 0.0)
	imgui.set_style_color(imgui.ImGuiCol_ButtonHovered, 0.50, 0.69, 0.99, 0.0)
	imgui.set_style_color(imgui.ImGuiCol_ButtonActive, 0.80, 0.50, 0.50, 0.0)
	imgui.set_style_color(imgui.ImGuiCol_Header, 0.30, 0.69, 1.00, 0.53)
	imgui.set_style_color(imgui.ImGuiCol_HeaderHovered, 0.44, 0.61, 0.86, 1.00)
	imgui.set_style_color(imgui.ImGuiCol_HeaderActive, 0.38, 0.62, 0.83, 1.00)
	imgui.set_style_color(imgui.ImGuiCol_ResizeGrip, 1.00, 1.00, 1.00, 0.85)
	imgui.set_style_color(imgui.ImGuiCol_ResizeGripHovered, 1.00, 1.00, 1.00, 0.60)
	imgui.set_style_color(imgui.ImGuiCol_ResizeGripActive, 1.00, 1.00, 1.00, 0.90)
	imgui.set_style_color(imgui.ImGuiCol_PlotLines, 1.00, 1.00, 1.00, 1.00)
	imgui.set_style_color(imgui.ImGuiCol_PlotLinesHovered, 0.90, 0.70, 0.00, 1.00)
	imgui.set_style_color(imgui.ImGuiCol_PlotHistogram, 0.90, 0.70, 0.00, 1.00)
	imgui.set_style_color(imgui.ImGuiCol_PlotHistogramHovered, 1.00, 0.60, 0.00, 1.00)
	imgui.set_style_color(imgui.ImGuiCol_TextSelectedBg, 0.00, 0.00, 1.00, 0.35)

	
end

-- ---------------------------------------------------------------------------

local function font_config(self)
	
	local fontsize 		= 1
	self.fonts 	= {}
	local regular_data, error = sys.load_resource("/app/fonts/bitwise.ttf")
	self.fonts["Regular"] = imgui.font_add_ttf_data(regular_data, #regular_data, fontsize, fontsizebase)
	-- local bold_data, error = sys.load_resource("/app/fonts/Overpass-ExtraBold.ttf")
	-- self.fonts["Bold"] = imgui.font_add_ttf_data(bold_data, #bold_data, fontsize, fontsizebase)
	-- local italic_data, error = sys.load_resource("/app/fonts/Overpass-SemiBoldItalic.ttf")
	-- self.fonts["Italic"] = imgui.font_add_ttf_data(italic_data, #italic_data, fontsize, fontsizebase)
	-- local bolditalic_data, error = sys.load_resource("/app/fonts/Overpass-ExtraBoldItalic.ttf")
	-- self.fonts["BoldItalic"] = imgui.font_add_ttf_data(bolditalic_data, #bolditalic_data, fontsize, fontsizebase)

	-- Resource based Image 
	-- local img_logo, error =  sys.load_resource("/assets/images/f18-title.png") 
	-- self.img_logo = imgui.image_load_data( "logo", img_logo, #img_logo )
end


------------------------------------------------------------------------------------------------------------

local function windowHeader( self, state )

	-- Each state can have seprate window positions
	state = state or gSmgr:GetCurrent()
	local x = state.windowx or 0
	local y = state.windowy or 0

	imgui.set_next_window_pos(x, y)
	imgui.set_next_window_size(self.width, self.height)
	
	imgui.begin_window("f18"..state.name, false, flags)
	imgui.set_window_font_scale(1.0)

	imgui.font_scale(self.fonts["Regular"], utils.generaltextsize)
	imgui.font_push(self.fonts["Regular"])

	if self.platform_info.system_name == "HTML5" then
		if(imgui.is_mouse_clicked(0) ==true) then 
			self.clicked = nil 
			html5.run("clearFocus()")
		end 
	end
end 

------------------------------------------------------------------------------------------------------------

local function windowFooter( self )
	imgui.font_pop()

	utils.drawerrors(self, Smaster.dt)
	imgui.end_window()
end

------------------------------------------------------------------------------------------------------------

function Smaster:Begin()

    self = Smaster.self
    self.flags = flags
    
    self.windowHeader = windowHeader 
    self.windowFooter = windowFooter
	
	self.login_attemps = 0
	self.counter = 0
	self.error_timer  = 0
	self.host_game = nil
		
	imgui.set_display_size(self.width, self.height)
	self.values_line = {}
	self.values_hist = {}

	font_config(self)
	
	self.gamestates = {}
	self.gamestate = GAME.SETUP

	-- All the timers used in the main game sections 
	self.timers 	= {}
	
	local left = self.width * 0.5 - 170 * self.scale	
	self.playercard_move = { pos = left }
end

------------------------------------------------------------------------------------------------------------
function Smaster:Update(mxi, myi, buttons)
	-- print("TICK")
end

------------------------------------------------------------------------------------------------------------

function Smaster:Render()

    self = Smaster.self
	windowHeader(self)

    -- TODO: This can probably all go in a nice connection state
	if(self.gamestate == GAME.SETUP) then 
		self.gamestate = GAME.MENU
	elseif(self.gamestate == GAME.MENU) then 
		gSmgr:ChangeState("GameFreePlay")
		
	elseif(self.gamestate == GAME.GAME_FINISH) then 

	end

    windowFooter(self)
end

------------------------------------------------------------------------------------------------------------

function Smaster:Finish()

    self = Smaster.self
end
	
------------------------------------------------------------------------------------------------------------

Smaster.set_style 		= set_style
Smaster.font_config 	= font_config

return Smaster

------------------------------------------------------------------------------------------------------------
	