local TL = CreateFrame("Frame","TownLocator",UIParent)
TL:SetScript("OnEvent", function(self,event,...) TL[event](self,...) end)
TL:RegisterEvent"ADDON_LOADED"
TL.L = TL_GetLocalization()
TL.Data = TL_GetData()
local dd = CreateFrame('Frame', 'TownLocator_Menu', UIParent, 'UIDropDownMenuTemplate')
local Astrolabe = DongleStub"Astrolabe-0.4"
local theWorldMap = WorldMapDetailFrame
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
-- Hide map icons
function TL:HideMap()
	for _,icon in ipairs(mapPool) do
		Astrolabe:RemoveIconFromMinimap(icon)
	end
end
-- Hide minimap icons
function TL:HideMinimap()
	for _,frame in ipairs(miniPool) do
		frame:Hide()
	end
end
-- Hide every icon
function TL:HideAll()
	self:HideMap()
	self:HideMinimap()
end

-- TomTom integration
function TL:GoTo(icon)
	if (not TomTom:CrazyArrowIsHijacked()) then
		TomTom:HijackCrazyArrow(function(self, elapsed)
			-- Angle to waypoint
			local direction = Astrolable:GetDirectionToIcon(icon)
			TomTom:SetCrazyArrowDirection(direction)
			-- Distance to waypoint
			local dist, xDelta, yDelta = Astrolabe:GetDistanceToIcon(icon)
			TomTom:SetCrazyArrowColor(0,0,0)
			-- CrazyArrow title
			TomTom:SetCrazyArrowTitle("[TL]"..icon.name,dist.." yards")
		end)
	end
end
-- Returns the icon
 function TL:GetTextureByType(type)
	return TL.Types[type]
end

-- Scripts handlers
local function OnEnter(self)
	GameTooltip:AddLine(self.type)
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
			local tomtom = {text = "Go to this waypoint with TomTom", func = function() TL.GoTo(w) end}
			tinsert(tbl,tomtom)
		end
		local hide = {text = "Hide this POI", func = self.Hide}
		tinsert(tbl,hide)
		local hidemap = {text = "Hide all map POI", func = TL.HideMap}
		tinsert(tbl, hidemap)
		local hidemini = {text = "Hide all minimap POI", func = TL.HideMinimap}
		tinsert(tbl, hideminimap)
		local hideall = {text = "Hide all POI (map and minimap)", func = TL.HideAll}
		tinsert(tbl, hideall)
		local cancel = {text = "Cancel", func = CloseDropDownMenus}
		tinsert(tbl, cancel)
		
		EasyMenu(menu,dd,self,0,0)
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
	minimap.name = zone.." - "..type
	minimap.kind = "MinimapIcon"
	
	minimap.icon = minimap:CreateTexture"BACKGROUND"
	minimap.icon:SetTexture(self:GetTextureByType(type) or "Interface\\Minimap\\Tracking\\Flightmaster")
	minimap.icon:SetPoint("CENTER",0,0)
	minimap.icon:SetWidth((type == "Barber" and 60) or 20)
	minimap.icon:SetHeight((type == "Barber" and 30) or 20)
	
	minimap:SetScript("OnEnter", OnEnter)
	minimap:SetScript("OnLeave", OnLeave)
	minimap:SetScript("OnClick", OnClick)
	
	-- Map button
	local map = CreateFrame("Button",nil,theWorldMap)
	map:SetWidth((type == "Barber" and 60) or 20)
	map:SetHeight((type == "Barber" and 30) or 20)
	map:RegisterForClicks("RightButtonUp")
	map.type = type
	map.name = zone.." - "..type
	map.micon = minimap
	map.kind = "MapIcon"
	
	map.icon = map:CreateTexture"BACKGROUND"
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
	continent, zone = Astronomer.ZoneCZ(zoneName)	
	--Flightmaster icon by default (shouldn't happen anymore)
	local tex = self:GetTextureByType(type) or "Interface\\Minimap\\Tracking\\Flightmaster"
	-- Because barbers rules 
	local width = (type == "Barber" and 60) or 20
	local height = (type == "Barber" and 30) or nil
--~ 	local icon, placed = Astronomer.NewZoneIcon(tex, width, height, continent, zone, x, y)

	-- Let's try without Astronomer
	local minimap, map = CreateIcons(type,z)
	Astrolabe:PlaceIconOnMinimap(minimap,continent,zone,x,y)
	Astrolabe:PlaceIconOnWorldMap(theWorldFrame,map,continent,zone,x,y)
		
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
