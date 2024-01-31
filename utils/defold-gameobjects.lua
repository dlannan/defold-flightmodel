------------------------------------------------------------------------------------------------------------
-- Set state config here  Mmission.name = "MASTER"
------------------------------------------------------------------------------------------------------------

_M  = {}

_M.MAP_IDS = nil

_M.mid = function( str ) 

	local id = str
	if(type(str) == "string") then 
		id = _M.MAP_IDS[hash(str)]
	end 
	if(comp) then 
		return msg.url(nil, id, comp)
	end
	return id
end 

------------------------------------------------------------------------------------------------------------
_M.GAME_IDS = nil

_M.gid = function( str, comp ) 

	local id = str
	if(type(str) == "string") then 
		if(_M.GAME_IDS) then 
			id = _M.GAME_IDS[hash(str)]
		end
	end 
	if(comp) then 
		return msg.url(nil, id, comp)
	end
	return id
end 

------------------------------------------------------------------------------------------------------------

_M.setMids = function( mids )
    _M.MAP_IDS  = mids 
end

------------------------------------------------------------------------------------------------------------

_M.setGids = function( gids )
    _M.GAME_IDS  = gids 
end

------------------------------------------------------------------------------------------------------------

_M.cleanupGids = function()
	if(_M.GAME_IDS == nil) then return end 
	for k,v in pairs(_M.GAME_IDS) do
		if(v) then go.delete(v, true) end
	end
	_M.GANME_IDS = nil
end 

------------------------------------------------------------------------------------------------------------

_M.cleanupMids = function()
	if(_M.MAP_IDS == nil) then return end 
	for k,v in pairs(_M.MAP_IDS) do
		if(v) then go.delete(v, true) end
	end
	_M.MAP_IDS = nil
end 

------------------------------------------------------------------------------------------------------------

return _M