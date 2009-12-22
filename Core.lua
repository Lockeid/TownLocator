local TL = CreateFrame("Frame","TownLocator",UIParent)
TL:SetScript("OnEvent", function(self,event,...) TL[event](self,...) end)
TL:RegisterEvent"ADDON_LOADED"
TL.L = TL_GetLocalization()
TL.Data = TL_GetData()

TL.Types = {
	Bank = "Interface\\Minimap\\Tracking\\Banker",
	Fly = "Interface\\Minimap\\Tracking\\Flightmaster",
	ClassTrainer = "Interface\\Minimap\\Tracking\\ClassTrainer",
	ProfessionTrainer = "Interface\\Minimap\\Tracking\\ProfessionTrainer",
	Mailbox = "",
	Portals = "",
	Innkeeper = "Interface\\Minimap\\Tracking\\Innkeeper",
	PVP_Rewards = "",
	Arena_Battlemasters = "",
	Arena_Rewards = ""
}

function TL:SetPNJ(zoneName, x, y, type) 
--~ 	x = x/100 
--~ 	y = y/100 	
	continent, zone = Astronomer.ZoneCZ(zoneName)	
--~ 	Flightmaster icon for the test
	local icon, placed = Astronomer.NewZoneIcon("Interface\\Minimap\\Tracking\\Flightmaster", 16, nil, continent, zone, x, y, true)
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
