-- TODO: Make tooltip show up, make the OnClick handler work with map icons

local TL = CreateFrame("Frame","TownLocator",UIParent)
TL:SetScript("OnEvent", function(self,event,...) TL[event](self,...) end)
TL:RegisterEvent"ADDON_LOADED"
TL:RegisterEvent"WORLD_MAP_UPDATE"
TL.L = TL_GetLocalization()
TL.Data = TL_GetData()
local dd = CreateFrame('Frame', 'TownLocator_Menu', UIParent, 'UIDropDownMenuTemplate')
local Astrolabe = DongleStub"Astrolabe-0.4"
local miniPool = {}
local mapPool = {}

local tinsert = tinsert


-- Icons depending on the type
TL.Types = {
	["Bank"] = "Interface\\Minimap\\Tracking\\Banker",
	["Barber"] = "Interface\\BarberShop\\UI-Barbershop-Banner",
	["Flight Master"] = "Interface\\Minimap\\Tracking\\Flightmaster",
	["Mailbox"] = "Interface\\Minimap\\Tracking\\Mailbox",
	["Portals"] = "Interface\\AddOns\\TownLocator\\Portals",
	["Inn"] = "Interface\\Minimap\\Tracking\\Innkeeper",
	["Battlemasters"] = "Interface\\WorldStateFrame\\CombatSwords",
	["Higher Learning Books"] = "Interface\\Minimap\\Tracking\\Profession",
	-- Every profession
	["Alchemy Trainer"] = "Interface\\Minimap\\Tracking\\Profession",
	["Blacksmithing Trainer"] = "Interface\\Minimap\\Tracking\\Profession",
	["Cooking Trainer"] = "Interface\\Minimap\\Tracking\\Profession",
	["Enchanting Trainer"] = "Interface\\Minimap\\Tracking\\Profession",
	["First Aid Trainer"] = "Interface\\Minimap\\Tracking\\Profession",
	["Fishing Trainer"] = "Interface\\Minimap\\Tracking\\Profession",
	["Herbalism Trainer"] = "Interface\\Minimap\\Tracking\\Profession",
	["Inscription Trainer"] = "Interface\\Minimap\\Tracking\\Profession",
	["Leatherworking Trainer"] = "Interface\\Minimap\\Tracking\\Profession",
	["Mining Trainer"] = "Interface\\Minimap\\Tracking\\Profession",
	["Skinning Trainer"] = "Interface\\Minimap\\Tracking\\Profession",
	["Tailoring Trainer"] = "Interface\\Minimap\\Tracking\\Profession",
	["Jewelcrafting Trainer"] = "Interface\\Minimap\\Tracking\\Profession",
	-- Every class
	["Mage Trainer"] = "Interface\\Minimap\\Tracking\\Class",
	["Warrior Trainer"] = "Interface\\Minimap\\Tracking\\Class",
	["Warlock Trainer"] = "Interface\\Minimap\\Tracking\\Class",
	["Rogue Trainer"] = "Interface\\Minimap\\Tracking\\Class",
	["Priest Trainer"] = "Interface\\Minimap\\Tracking\\Class",
	["Paladin Trainer"] = "Interface\\Minimap\\Tracking\\Class",
	["Hunter Trainer"] = "Interface\\Minimap\\Tracking\\Class",
	["Death Knight Trainer"] = "Interface\\Minimap\\Tracking\\Class",
	["Shaman Trainer"] = "Interface\\Minimap\\Tracking\\Class",
	["Druid Trainer"] = "Interface\\Minimap\\Tracking\\Class",
}

-- Some utils functions
	local conts = {
		northrend = true,
		kalimdor = true,
		azeroth= true,
		expansion01 = true,
		crystalsongforest = true,
		[""] = true
	}
	-- All this is stolen from Tuhljin's Astronomer

    local ZoneIcons = {};
    local continentNames = { GetMapContinents() };
    for key, val in pairs(continentNames) do
      local zoneNames = { GetMapZones(key) };
      ZoneIcons[key] = {};
      ZoneIcons[key][0] = {};
      ZoneIcons[key][0].name = val;
      for k, v in pairs(zoneNames) do
        ZoneIcons[key][k] = {};
        ZoneIcons[key][k].name = v;
      end
    end
    -- Next, add entries for the "continents" whose ID numbers are 0 and -1:
    ZoneIcons[0] = {};
    ZoneIcons[0][0] = {}
    ZoneIcons[0][0].name = "Azeroth";
    ZoneIcons[-1] = {};
    ZoneIcons[-1][0] = {}
    ZoneIcons[-1][0].name = "Cosmic";
 local function getzoneIDfromname(C, zoneName)
    for k, v in ipairs(ZoneIcons[C]) do
      if (ZoneIcons[C][k].name == zoneName) then
        return k;
      end
    end
    return nil;
  end
function TL:ZoneCZ(zoneName, continent)
    local zone
    if (type(continent) == "number") then
      zone = getzoneIDfromname(continent, zoneName);
      if (zone) then
        return continent, zone;
      else
        return nil;
      end
    end
    for k, v in pairs(ZoneIcons) do
      zone = getzoneIDfromname(k, zoneName);
      if (zone) then
        return k, zone;
      end
    end
    return nil;
  end

  
-- Hide minimap icons
local function HideMinimap()
	for _,icon in ipairs(miniPool) do
		Astrolabe:RemoveIconFromMinimap(icon)
	end
end
-- Hide map icons
local function HideMap()
	for _,frame in ipairs(mapPool) do
		frame:Hide()
	end
end
-- Hide every icon
local function HideAll()
	HideMap()
	HideMinimap()
end


-- TomTom integration
local function ColorGradient(perc, ...)
	if perc >= 1 then
		local r, g, b = select(select('#', ...) - 2, ...)
		return r, g, b
	elseif perc <= 0 then
		local r, g, b = ...
		return r, g, b
	end
	
	local num = select('#', ...) / 3

	local segment, relperc = math.modf(perc*(num-1))
	local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)

	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

function TL:GetArrowColor(angle)
	local perc = math.abs((math.pi - math.abs(angle)) / math.pi)
	local r,g,b = ColorGradient(perc, 1, 0, 0, 1, 1, 0, 0, 1, 0)
	return r, g, b
end

function TL:GoTo(icon)
	if (not TomTom:CrazyArrowIsHijacked()) then
		TomTom:HijackCrazyArrow(function(self, elapsed)
			-- Angle to waypoint
			local direction = Astrolabe:GetDirectionToIcon(icon)
			local direction = direction - GetPlayerFacing()
			TomTom:SetCrazyArrowDirection(direction)
			-- CrayArrowColor
			local r,g,b = TL:GetArrowColor(direction)
			TomTom:SetCrazyArrowColor(r,g,b)
			-- Distance to waypoint
			local distance, _,_ = Astrolabe:GetDistanceToIcon(icon)
			-- CrazyArrow title
			local title = format("[TL]: %s (%d yards)", icon.name, distance)
			TomTom:SetCrazyArrowTitle(title)
			if distance < 5 then TomTom:ReleaseCrazyArrow() end
		end)
	end
end


-- Returns the icon
 function TL:GetTextureByType(type)
	return TL.Types[type]
end

-- Callback
local function OnEdge()
	for _,icon in ipairs(miniPool) do
		if(Astrolabe:IsIconOnEdge(icon)) then
			icon:Hide()
		else
			icon:Show()
		end
	end
end
Astrolabe:Register_OnEdgeChanged_Callback(OnEdge, true)

-- Scripts handlers
local function OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
	GameTooltip:SetText(self.type)
	GameTooltip:Show()
end
local function OnLeave(self)
	GameTooltip:Hide()
end

local function OnClick(self,button)
	if(button ~= "RightButton") then
		return
	else
		local w
		if self.kind == "MapIcon" then
			w = self.micon
		else
			w = self
		end		
		local tbl = {}
		local title = {text= self.type.."\n", isTitle = true}
		tinsert(tbl, title)
		if(IsAddOnLoaded"TomTom") then
			local tomtom = {text = "Go to this waypoint with TomTom", func = function() TL:GoTo(self) end}
			tinsert(tbl,tomtom)
		end
		local hide = {text = "Hide this POI", func = function() self:Hide() end}
		tinsert(tbl,hide)
		local hidemap = {text = "Hide all map POI", func = HideMap}
		tinsert(tbl, hidemap)
		local hidemini = {text = "Hide all minimap POI", func = HideMinimap}
		tinsert(tbl, hidemini)
		local hideall = {text = "Hide all POI (map and minimap)", func = HideAll}
		tinsert(tbl, hideall)
		local cancel = {text = "Cancel", func = CloseDropDownMenus}
		tinsert(tbl, cancel)
		
		EasyMenu(tbl,dd,self,0,0)
	end
end
	
	
-- Creates the minimap and map icon
function TL:CreateIcons(type,zone)
	
	-- Minimap button
	local minimap = CreateFrame("Button",nil,Minimap)
	minimap:SetWidth((type == "Barber" and 60) or 20)
	minimap:SetHeight((type == "Barber" and 30) or 20)
	minimap:RegisterForClicks("RightButtonUp")
	minimap.type = type
	minimap.kind = "MinimapIcon"
	
	minimap.icon = minimap:CreateTexture(nil,"OVERLAY")
	minimap.icon:SetTexture(self:GetTextureByType(type) or "Interface\\Minimap\\Tracking\\Flightmaster")
	minimap.icon:SetPoint("CENTER",0,0)
	minimap.icon:SetWidth((type == "Barber" and 60) or 20)
	minimap.icon:SetHeight((type == "Barber" and 30) or 20)
		
	minimap:SetScript("OnEnter", OnEnter)
	minimap:SetScript("OnLeave", OnLeave)
	minimap:SetScript("OnClick", OnClick)
	minimap:SetScript("OnUpdate", OnUpdate)
	
	-- Map button
	local map = CreateFrame("Button",nil,WorldMapDetailFrame)
	map:SetWidth((type == "Barber" and 60) or 20)
	map:SetHeight((type == "Barber" and 30) or 20)
	map:RegisterForClicks("RightButtonUp")
	map:SetFrameStrata("HIGH")
	map.type = type
	map.micon = minimap
	map.kind = "MapIcon"
	
	map.icon = map:CreateTexture(nil,"OVERLAY")
	map.icon:SetTexture(self:GetTextureByType(type) or "Interface\\Minimap\\Tracking\\Flightmaster")
	map.icon:SetPoint("CENTER",0,0)
	map.icon:SetWidth((type == "Barber" and 60) or 20)
	map.icon:SetHeight((type == "Barber" and 30) or 20)
	
	map:SetScript("OnEnter", OnEnter)
	map:SetScript("OnLeave", OnLeave)
	map:SetScript("OnClick", OnClick)
	
	
	tinsert(miniPool, minimap)
	tinsert(mapPool, map)
	
	return minimap, map
end


-- Creates the POI using Astrolabe
function TL:SetPOI(zoneName, x, y, type)	
	continent, zone = self:ZoneCZ(zoneName)	
	--Flightmaster icon by default (shouldn't happen anymore)
	local tex = self:GetTextureByType(type) or "Interface\\Minimap\\Tracking\\Flightmaster"
	-- Because barbers rules 
	local width = (type == "Barber" and 60) or 20
	local height = (type == "Barber" and 30) or nil

	-- Let's try without Astronomer
	local minimap, map = self:CreateIcons(type,zone)
	-- Some data 
	minimap.name = zoneName.." - "..type
	map.name = zoneName.." - "..type
	coords = {continent, zone, x, y}
	minimap.coords = coords
	map.coords = coords
	-- True placement
	Astrolabe:PlaceIconOnMinimap(minimap,continent,zone,x,y)
	Astrolabe:PlaceIconOnWorldMap(WorldMapDetailFrame,map,continent,zone,x,y)
		
	if(type == "Higher Learning Books") then
		-- Little hack to see where are those damned books
		minimap.icon:SetVertexColor(0,1,1)
		map.icon:SetVertexColor(0,1,1)
	end
end


-- Iterate over the data 
function TL:IterateData()
	for k, value in pairs(TL.Data) do
		local z = k
		for type, point in pairs(value) do
			for _, tbl in ipairs(point) do
				TL:SetPOI(z, tbl.xOff, tbl.yOff,type)
			end
		end
	end
end

function TL:ADDON_LOADED(addon) 
	if addon ~= "TownLocator" then return end
	TL:IterateData()
end


function TL:WORLD_MAP_UPDATE()
	local mapFileName = strlower(GetMapInfo() or "")
	local hide = false
	--[[
	for _,cont in ipairs(conts) do
		if mapFileName == cont then
			hide = true
		end
	end--]]
	if conts[mapFileName] then hide = true end
	for _, icon in ipairs(mapPool) do 
		Astrolabe:PlaceIconOnWorldMap(WorldMapDetailFrame, icon, unpack(icon.coords))	
		if(hide == true) then
			icon:SetAlpha(0)
		else
			icon:SetAlpha(1)
		end
	end
end
