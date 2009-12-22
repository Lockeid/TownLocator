local TL = CreateFrame("Frame","TownLocator",UIParent)
TL:SetScript("OnEvent", function(self,event,...) TL[event](self,...) end)
TL:RegisterEvent"ADDON_LOADED"
TL.L = TL_GetLocalization()
TL.Data = TL_GetData()

TL.Types = {
	Bank = "Interface\\Minimap\\Tracking\\Banker",
	["Flight Master"] = "Interface\\Minimap\\Tracking\\Flightmaster",
	ClassTrainer = "Interface\\Minimap\\Tracking\\Class",
	Mailbox = "Interface\\Minimap\\Tracking\\Mailbox",
	Portals = "",
	Inn = "Interface\\Minimap\\Tracking\\Innkeeper",
	PVP_Rewards = "",
	Arena_Battlemasters = "",
	Arena_Rewards = "",
	["Higher Learning Books"] = "Interface\\Minimap\\Tracking\\Class",
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

function TL:SetPNJ(zoneName, x, y, type)	
	continent, zone = Astronomer.ZoneCZ(zoneName)	
--~ 	Flightmaster icon for the test
	local tex = self:GetTextureByType(type) or "Interface\\Minimap\\Tracking\\Flightmaster"
	local icon, placed = Astronomer.NewZoneIcon(tex, 16, nil, continent, zone, x, y, true)
end

function TL:GetTextureByType(type)
	return TL.Types[type]
end

function TL:IterateData()
	for k, value in pairs(TL.Data) do
		local z = k
		print(z)
		for type, point in pairs(value) do
			for _, tbl in ipairs(point) do
				TL:SetPNJ(z, tbl.xOff, tbl.yOff,type)
			end
		end
	end
end

function TL:ADDON_LOADED(addon) 
	if addon ~= "TownLocator" then return end
	TL:IterateData()
end
