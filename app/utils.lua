local tinsert 	= table.insert
local tremove 	= table.remove
local tcount 	= table.getn

-- ---------------------------------------------------------------------------

local wdgt 		= require("app.widgets.widgets")
local tween 	= require("app.tween")

-- ---------------------------------------------------------------------------

local function genname()
	m,c = math.random,("").char 
	name = ((" "):rep(9):gsub(".",function()return c(("aeiouy"):byte(m(1,6)))end):gsub(".-",function()return c(m(97,122))end))
	return(string.sub(name, 1, math.random(4) + 5))
end

-- ---------------------------------------------------------------------------

local function tcount(tbl)
	local cnt = 0
	if(tbl == nil) then return cnt end
	for k,v in pairs(tbl) do 
		cnt = cnt + 1
	end 
	return cnt
end 

-- ---------------------------------------------------------------------------

function tmerge(t1, t2)
	if(t1 == nil) then t1 = {} end 
	if(t2 == nil) then return t1 end 
	
	for k, v in pairs(t2) do
		if (type(v) == "table") and (type(t1[k] or false) == "table") then
			tmerge(t1[k], t2[k])
		else
			t1[k] = v
		end
	end
	return t1
end

-- ---------------------------------------------------------------------------

local function tablejson( list )

	local p = "{"
	local i = 1
	for k,v in pairs(list) do 
		if(i ~= 1) then p = p.."," end

		if(type(v) == "table") then 
			p = p.."\""..k.."\":\""..tablejson(v)
		elseif(type(v) == "number") then 
			p = p.."\""..k.."\":"..v
		else
			p = p.."\""..k.."\":\""..v.."\""
		end
		i = i + 1
	end
	p = p.." }"

	return p
end

-- ---------------------------------------------------------------------------
-- Deep Copy
-- This is good for instantiating tables/objects without too much effort :)

function deepcopy(t)
	if type(t) ~= 'table' then return t end
	local mt = getmetatable(t)
	local res = {}
	for k,v in pairs(t) do
		if type(v) == 'table' then
		v = deepcopy(v)
		end
		res[k] = v
	end
	setmetatable(res,mt)
	return res
end

-- ---------------------------------------------------------------------------

local function saveconfig(self, reset)

	if(self.debugClient == 1) then reset = true end 
	
	self.save_settings = sys.get_save_file("soulsurvivor", "config")
	self.config_data.host_id = self.game_name
	self.config_data.client_id = self.client_id
	self.config_data.user_id = self.user_id
	self.config_data.device_id = self.device_id
	self.config_data.player_name = self.player_name

	if(reset) then self.config_data = {} end
	if not sys.save(self.save_settings, self.config_data) then
		print("Failed to save.")
	end
end

-- ---------------------------------------------------------------------------

local function loadconfig(self)

	self.save_settings = sys.get_save_file("soulsurvivor", "config")
	self.config_data = sys.load(self.save_settings) or {}

	if(tcount(self.config_data) > 0) then loaded = true end 
	if(self.debugClient == 1) then loaded = nil end
	
	if(loaded) then
		self.config_id =  self.config_data.client_id
		self.user_id = self.config_data.user_id or genname()
		self.device_id = self.config_data.device_id
		self.game_name = self.config_data.host_id
		self.player_name = self.config_data.player_name
	else 
		self.config_id =  nil
		self.user_id = genname()
		self.device_id = nil
		self.game_name = nil
		self.player_name = nil
	end
	-- pprint( self.config_data )
end

-- ---------------------------------------------------------------------------

local function isjudge(self) 

	if(self.game == nil or self.round == nil) then return false end
	if(self.game.people[self.round.judge] == nil) then return false end
	return (self.game.people[self.round.judge].uid == self.device_id)
end 

-- ---------------------------------------------------------------------------

local function getpeopletext(self)
	if(self.game == nil) then return "0 PEOPLE" end 
	return tcount(self.game.people).." PEOPLE"
end

-- ---------------------------------------------------------------------------

local function getpeoplecount(self)
	if(self.game == nil) then return 0 end 
	return tcount(self.game.people)
end

-- ---------------------------------------------------------------------------

local function getscenariotext(self)

	if(self.round == nil) then return "" end
	return self.scenarios[self.round.scenario].desc:upper()
end 

-- ---------------------------------------------------------------------------

local function gettimetext(self)

	if(self.round == nil) then return "0s" end
	return string.format("%ds", self.round.timeout or 0)
end 

-- ---------------------------------------------------------------------------

local function getjudgetext(self) 
	if(self.game == nil or self.round == nil) then return "" end 
	return self.game.people[self.round.judge].username
end

-- ---------------------------------------------------------------------------

local function tickround(self, dt, callback)

	if(self.round == nil) then return end 
	
	self.round.timeout = self.round.timeout - dt
	-- Selection done
	if(self.round.timeout < 0.0) then 
		self.round.timeout = 0.0
		callback()
	end
end 

-- ---------------------------------------------------------------------------
return {
	init			= wdgt.init, 
	
	checklimits 	= wdgt.checklimits,
	genname 		= genname,
	tcount 			= tcount,
	tmerge			= tmerge,
	tablejson		= tablejson,

	deepcopy		= deepcopy,

	isjudge			= isjudge,
	getpeoplecount	= getpeoplecount,
	getpeopletext	= getpeopletext,
	getscenariotext = getscenariotext,
	gettimetext		= gettimetext,
	getjudgetext	= getjudgetext,

	tickround		= tickround,
	
	saveconfig 		= saveconfig,
	loadconfig 		= loadconfig,

	adderror 		= wdgt.adderror,
	drawerrors 		= wdgt.drawerrors,

	draw_button 	= wdgt.draw_button,
	draw_checkbox	= wdgt.draw_checkbox,
	draw_text		= wdgt.draw_text,
	draw_textbutton = wdgt.draw_textbutton,
	draw_input		= wdgt.draw_input,
	draw_aligned_text = wdgt.draw_aligned_text,
	draw_theme_icons= wdgt.draw_theme_icons,
	scrollcards		= wdgt.scrollcards,

	buttonwidth 	= wdgt.buttonwidth,
	buttonheight	= wdgt.buttonheight,
	buttontextsize 	= wdgt.buttontextsize,

	generaltextsize = wdgt.generaltextsize,
	smalltextsize 	= wdgt.smalltextsize,
	mediumtextsize 	= wdgt.mediumtextsize,
	largetextsize	= wdgt.largetextsize,
	exttextsize 	= wdgt.exttextsize,

	fontsizebase 	= wdgt.fontsizebase,
}
-- ---------------------------------------------------------------------------
