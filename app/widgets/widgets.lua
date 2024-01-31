local tinsert 	= table.insert
local tremove 	= table.remove
local tcount 	= table.getn

-- ---------------------------------------------------------------------------

local buttonwidth 		= 400
local buttonheight 		= 80
local buttontextsize 	= 0.65

local generaltextsize 	= 0.65
local smalltextsize 	= 0.55
local mediumtextsize	= 0.75
local largetextsize		= 1.0
local exttextsize		= 1.2

local fontsizebase 		= 60.0
local spacing 			= 2.0 

-- A local lookup for words being used in multilined aligned text
local wordcache 		= {}

local tween 	= require("app.tween")

-- ---------------------------------------------------------------------------

SLIDE_TIMER		= 0.5
SLIDE_TWEEN		= 'inOutCirc'

THEME_SIZE 		= 55

-- ---------------------------------------------------------------------------
-- order MUST match enums in ImGuiKey_
local IMGUI_KEYS = {
	"key_tab",
	"key_left",
	"key_right",
	"key_up",
	"key_down",
	"key_pageup",
	"key_pagedown",
	"key_home",
	"key_end",
	"key_insert",
	"key_delete",
	"key_backspace",
	"key_space",
	"key_enter",
	"key_esc",
}

-- ---------------------------------------------------------------------------
-- map action_id (key) to ImGuiKey_ enums
local IMGUI_KEYMAP = {}
for i=1,#IMGUI_KEYS do
	local key = IMGUI_KEYS[i]
	IMGUI_KEYMAP[key] = i - 1
end

-- ---------------------------------------------------------------------------

local function checklimits( obj, minimum, maximum )
	if( obj > maximum) then obj = minimum end
	if( obj < minimum) then obj = maximum end
	return obj
end


-- ---------------------------------------------------------------------------

local function init(self)

	-- Reconfig based on scaling!
	buttonwidth = buttonwidth * self.scale
	buttonheight = buttonheight * self.scale 
	spacing = spacing * self.scale

	buttontextsize = buttontextsize  * self.scale

	generaltextsize = generaltextsize * self.scale
	smalltextsize = smalltextsize * self.scale
	mediumtextsize = mediumtextsize * self.scale
	largetextsize = largetextsize * self.scale

	fontsizebase 	= fontsizebase * self.scale
end

-- ---------------------------------------------------------------------------
local function draw_button( self, text, x, y, flat, width )

	-- If width is negative dont draw background box, and set width..
	local nobg = false 
	width = width or buttonwidth
	if(width < 0) then width = -width; nobg = true end 
	
	local btn = self.img_button
	local flat_off = 0
	if(flat) then btn = self.img_button_flat; flat_off = -80 * self.scale end
	if(nobg) then btn = self.img_button_none end 
	local tw, th = imgui.text_getsize(text, buttontextsize / self.scale, self.fonts["Regular"])
	tw = tw * fontsizebase + flat_off
	th = th * fontsizebase
	local bw = width or buttonwidth
	local bh = buttonheight

	imgui.set_cursor_pos(x, y)
	imgui.image_add(btn, bw, bh)
	local result = imgui.is_item_clicked(0)

	imgui.set_cursor_pos(x + bw * 0.5 - tw * 0.5, y + bh * 0.5 - th * 0.5 - 6 * self.scale)
	imgui.font_scale(self.fonts["Regular"], buttontextsize)
	imgui.font_push(self.fonts["Regular"])
	imgui.text(text)
	imgui.font_pop()
	return result
end

-- ---------------------------------------------------------------------------

local function draw_text(self, text)
	imgui.font_scale(self.fonts["Regular"], buttontextsize)
	imgui.font_push(self.fonts["Regular"])
	imgui.text(text)
	imgui.font_pop()
end

-- ---------------------------------------------------------------------------

local function draw_textbutton( self, text ) 
	imgui.font_scale(self.fonts["Regular"], buttontextsize)
	imgui.font_push(self.fonts["Regular"])
	local res = imgui.button(text)
	imgui.font_pop()
	return res
end

-- ---------------------------------------------------------------------------

local function press_key( key, type )

	imgui.set_key_down(key, true)
	timer.delay(0.2, false, function() 
		imgui.set_key_down(key, false)
	end)
end 

-- ---------------------------------------------------------------------------

local function draw_input(self, name, id, value, maxwidth )

	imgui.begin_child( id.."_input", buttonwidth, buttonheight * 1.1)

	imgui.image_add(self.img_button_flat, buttonwidth , buttonheight)	
	imgui.set_cursor_pos(12 * self.scale, 8 * self.scale)
	
	if(string.len(name) > 0) then 
		draw_text(self, name)
		imgui.same_line(0)
	end
		
	imgui.font_scale(self.fonts["Regular"], buttontextsize)
	imgui.font_push(self.fonts["Regular"])

	local changed, newvalue = false, value 

	if self.platform_info.system_name == "HTML5" then

		maxwidth = maxwidth or 380 * self.scale
		if(self.clicked == id) then 
			local inputdata = html5.run("getInputText('"..id.."')")
			-- imgui.add_input_character()
			value = inputdata
			changed = true
			imgui.image_add(self.img_input_edit, maxwidth, buttonheight * 0.6)
		else
			imgui.image_add(self.img_input_def, maxwidth, buttonheight * 0.6)
		end

		local result = imgui.is_item_clicked(0)
		if(result == true) then 
			self.clicked = id
			html5.run("clearInput('"..id.."','"..tostring(value).."')")
		end

		local inputwidth = buttonwidth - 25 * self.scale
		local left = inputwidth - maxwidth + 20 * self.scale
		
		imgui.same_line(left)
		draw_text(self, value)
		newvalue = value
	else 
		local pad = 0
		if(string.len(name) <= 0) then pad = 180 end 
		
		-- This is a nasty hack to scale the input so it stretches with no text
		imgui.begin_child( id.."_input", buttonwidth + pad * self.scale, buttonheight)
		changed, newvalue = imgui.input_text(id, value)
		imgui.end_child()
	end

	imgui.font_pop()
	imgui.end_child()
	return changed, newvalue
end 
-- ---------------------------------------------------------------------------

local function draw_checkbox( self, value, text, x, y, flat, width, white )

	local check = self.img_check
	local checkoff = self.img_checkoff
	if(white) then 
		check = self.img_check_w
		checkoff = self.img_checkoff_w
	end
	
	value = value or 0
	if draw_button(self, text, x, y, flat, width) then
		value = 1-value 
	end
	if(value == 1) then 
		imgui.set_cursor_pos( x + 10 * self.scale, y +7 * self.scale)
		imgui.image_add(check, 50 * self.scale, 50 * self.scale)
	else
		imgui.set_cursor_pos( x + 10 * self.scale, y + 7 * self.scale)
		imgui.image_add(checkoff, 50 * self.scale, 50 * self.scale)
	end 
	return value 
end 

-- ---------------------------------------------------------------------------
-- An Aligned/wrapped text rendering method. It breaks lines on words as 
--  best as possible and applies alignment based on the img_settings
-- Alignment: 0/nil = left, 1 = center, 2 = right
local function draw_aligned_text( self, text, x, y, maxwidth, textsize, alignment )

	if(text == nil or string.len(text) == 0) then return end
	alignment = alignment or 1

	imgui.font_scale(self.fonts["Regular"], textsize)
	imgui.font_push(self.fonts["Regular"])
	
	local words = {} -- inorder words separated by spaces

	-- Check text cache - this just makes things a little more efficient over time
	if(wordcache[text] and wordcache[text].maxsize == maxwidth) then 
		words = wordcache[text]
	else
		-- Size of a space
		local sw, sh = imgui.text_getsize( " ", textsize/self.scale, self.fonts["Regular"] )
		local line = 1
		local linetext = ""
		local linesize = 0

		local wc = 1

		--get size of each word and spaces, then work out positioning
		for word in text:gmatch("[%w%.,]+") do 
			local space = " "
			local spacesize = sw
			if(wc == 1) then space = ""; spacesize = 0 end
			local ww, wh = imgui.text_getsize( word, textsize/self.scale, self.fonts["Regular"] )
			if(linesize + ww * fontsizebase < maxwidth) then 
				linesize = linesize + ww * fontsizebase + spacesize * fontsizebase
				linetext = linetext..space..word
			else 
				tinsert( words, { maxsize = maxwidth, text = linetext, size = linesize, height = wh * fontsizebase } )
				line = line + 1
				linesize = ww * fontsizebase
				linetext = word
			end 
			wc = wc + 1
		end
		tinsert( words, { maxsize = maxwidth, text = linetext, size = linesize, height = wh or buttonheight } )

		wordcache[text] = words
	end

	-- draw the lines of text aligned to the x, y and maxwidth
	local xpos = 0
	local ypos = 0

	imgui.font_scale(self.fonts["Regular"], textsize)
	imgui.font_push(self.fonts["Regular"])
	for k, v in ipairs(words) do 
		if(alignment == 1) then 
			xpos = maxwidth * 0.5 - v.size * 0.5
		end 
		if(alignment == 2) then 
			xpos = maxwidth - v.size
		end
		imgui.set_cursor_pos(x + xpos, y + ypos)
		imgui.text(v.text)
		ypos = ypos + v.height + spacing 
	end
	imgui.font_pop()

	imgui.font_pop()
end

-- ---------------------------------------------------------------------------

local function draw_theme_icons( self, themesize, x, y )

	themesize = themesize or THEME_SIZE
	themesize = themesize * self.scale
	local select = self.scenario_theme

	-- TODO: If position is set, then this assumes the buttons will be specifically positioned
	--if(x and y) then 

	if(self.scenario_theme == "zombie") then 
		imgui.image_add(self.img_zombie, themesize, themesize)
	else 
		if(imgui.button_image(self.img_zombie_alpha, themesize, themesize)) then 
			select = "zombie"
		end
	end 

	imgui.same_line(0)

	if(self.scenario_theme == "alien") then 
		imgui.image_add(self.img_alien, themesize, themesize)
	else 
		if(imgui.button_image(self.img_alien_alpha, themesize, themesize)) then 
			select = "alien"
		end
	end 

	imgui.same_line(0)

	if(self.scenario_theme == "space") then 
		imgui.image_add(self.img_space, themesize, themesize)
	else 
		if(imgui.button_image(self.img_space_alpha, themesize, themesize)) then 
			select = "space"
		end
	end 

	imgui.same_line(0)
	if(self.scenario_theme == "pirates") then 
		imgui.image_add(self.img_pirates, themesize, themesize)
	else
		if(imgui.button_image(self.img_pirates_alpha, themesize, themesize)) then 
			select = "pirates"
		end
	end

	return select
end

-- ---------------------------------------------------------------------------

local function scrollcards(self, pos, collection, selected, scrolltweencb, noarrows, chosen)

	selected = selected or 1
	local left = pos.left
	local top = pos.top
	local maxwidth = pos.width
	local maxheight = pos.height

	if(tcount(collection) == 0) then return selected end 
	if(self.collection_move == nil) then self.collection_move = { pos = 0, select = selected } end
	local thispos = self.collection_move.pos - maxwidth

	local mode = "TEXT"
	if(collection[1].person) then mode = "CHARACTER" end 

	imgui.set_cursor_pos(left, top)
	imgui.begin_child("scrollcard_mask", maxwidth, maxheight)

	for i=1, -1, -1 do 

		local idx = checklimits(selected + i, 1, tcount(collection))
		local data = collection[idx] or {}

		local bgimage = self.img_list_flat
		if(idx == selected and chosen) then 
			imgui.set_style_color(imgui.ImGuiCol_WindowBg, 1.0, 0.29, 0.70, 0.90)
			imgui.set_style_color(imgui.ImGuiCol_Text, 1.0, 0.96, 0.86, 1.00)
			bgimage = self.img_list_flat_pink
		end
		
		if(mode == "TEXT") then 
			if(data.desc) then
				local ttext = (data.desc or ""):upper()
				imgui.set_cursor_pos(thispos, 0)
				imgui.begin_child("scrollcard"..i, maxwidth, maxheight)

				imgui.font_scale(self.fonts["Regular"], generaltextsize)
				imgui.font_push(self.fonts["Regular"])

				imgui.set_cursor_pos( 0, 0)
				imgui.image_add(bgimage, maxwidth, maxheight)
				draw_aligned_text(self, ttext, 10 * self.scale, 10 * self.scale, maxwidth - 20 * self.scale, generaltextsize, 1)
				imgui.font_pop()

				imgui.end_child()
				thispos = thispos + maxwidth
			end
		else 
			if(data.trait and data.person) then 
				local ttext = (data.trait.desc or ""):upper()
				local ptext = (data.person.desc or ""):upper()

				imgui.set_cursor_pos(thispos, 0)
				imgui.begin_child("scrollcard_char"..i, maxwidth, maxheight)

				imgui.font_scale(self.fonts["Regular"], generaltextsize)
				imgui.font_push(self.fonts["Regular"])

				imgui.set_cursor_pos( 0, 0)
				imgui.image_add(bgimage, maxwidth, maxheight)
				draw_aligned_text(self, ptext, 10 * self.scale, 10 * self.scale, maxwidth - 20 * self.scale, generaltextsize, 1)
				draw_aligned_text(self, ttext, 10 * self.scale, 90 * self.scale, maxwidth - 20 * self.scale, generaltextsize, 1)
				imgui.font_pop()

				imgui.end_child()
				thispos = thispos + maxwidth
			end
		end

		if(idx == selected and chosen) then 
			imgui.set_style_color(imgui.ImGuiCol_Text, 1.0, 0.29, 0.70, 0.90)
			imgui.set_style_color(imgui.ImGuiCol_WindowBg, 1.0, 0.96, 0.86, 1.00)
		end
	end

	imgui.end_child()

	if(tcount(collection) > 0) then
		imgui.set_cursor_pos(0, top)
		if(noarrows == nil) then 

			imgui.begin_child("scrollcard_span", self.width, maxheight)

			local btnheight = 40 * self.scale
			local btny = 50 * self.scale
			local btnwidth = 20 * self.scale

			imgui.set_cursor_pos(50 * self.scale, maxheight * 0.5 - btnheight * 0.5)
			local leftbtn = imgui.button_image(self.img_arrow_left, btnwidth, btnheight) 

			imgui.set_cursor_pos(self.width - 70 * self.scale,  maxheight * 0.5 - btnheight * 0.5)
			local rightbtn = imgui.button_image(self.img_arrow_right, btnwidth, btnheight)


			imgui.end_child()

			if(not self.tweenobj) then 
				if( self.swipe.right or rightbtn ) then 
					selected = checklimits(selected + 1, 1, tcount(collection))
					self.swipe.right = false

					local target = maxwidth
					local obj = { pos = target, select = selected }
					self.tweenobj = tween.new(SLIDE_TIMER, self.collection_move, obj, SLIDE_TWEEN, scrolltweencb)
				end
				if( self.swipe.left or leftbtn ) then 
					selected = checklimits(selected - 1, 1, tcount(collection))
					self.swipe.left = false

					local target = -maxwidth
					local obj = { pos = target, select = selected }
					self.tweenobj = tween.new(SLIDE_TIMER, self.collection_move, obj, SLIDE_TWEEN, scrolltweencb)
				end
			end 

		end 
	end 

	return selected
end 

-- ---------------------------------------------------------------------------
local function adderror(self, text) 
	self.error_curr = text
	self.error_timer = 3  -- ms
end 
-- ---------------------------------------------------------------------------
local function drawerrors(self, dt) 

	-- On completion reset things 
	if(self.error_timer - dt < 0 and self.error_curr) then 
		self.error_curr = nil
	end

	if(self.error_curr == nil) then return end

	if(self.error_timer > 0) then 
		imgui.set_style_color(imgui.ImGuiCol_Text, 1.0, 0.8, 0.00, 0.90)
		imgui.set_cursor_pos(self.width * 0.25, self.height - 50 * self.scale)
		draw_text(self, self.error_curr)
		imgui.set_style_color(imgui.ImGuiCol_Text, 1.0, 0.29, 0.70, 0.90)
		self.error_timer = self.error_timer - dt
	end
end 

-- ---------------------------------------------------------------------------

return {

	init 			= init,

	checklimits		= checklimits,

	adderror 		= adderror,
	drawerrors 		= drawerrors,

	draw_button 	= draw_button,
	draw_checkbox	= draw_checkbox,
	draw_text		= draw_text,
	draw_textbutton = draw_textbutton,
	draw_input		= draw_input,
	draw_aligned_text = draw_aligned_text,
	draw_theme_icons= draw_theme_icons,
	scrollcards		= scrollcards,

	buttonwidth 	= buttonwidth,
	buttonheight	= buttonheight,
	buttontextsize 	= buttontextsize,

	generaltextsize = generaltextsize,
	smalltextsize 	= smalltextsize,
	mediumtextsize 	= mediumtextsize,
	largetextsize	= largetextsize,
	exttextsize		= exttextsize, 

	fontsizebase 	= fontsizebase,
}

-- ---------------------------------------------------------------------------
