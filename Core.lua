local TL = CreateFrame("Frame","TownLocator",UIParent)
TL:SetScript("OnEvent", function(self,event,...) TL[event](self,...) end)
TL:RegisterEvent"ADDON_LOADED"  --]]
--local TL = LibStub("AceAddon-3.0"):NewAddon("TownLocator")
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

function TL:SetPNJ(zoneName, x, y, texture, type) 
	x = x/100 
	y = y/100 	
	continent, zone = Astronomer.ZoneCZ(zoneName)	
	local icon, placed = Astronomer.NewZoneIcon(texture, 16, nil, continent, zone, x, y, true)

end

function TL:GetTextureByType(type)
	return TL.Types[type]
end

function TL:IterateData()
	for k, value in pairs(TL.Data) do
		local z = k
		for idx, pnj in ipairs(value) do
			local tex = TL:GetTextureByType(pnj.type)
			TL:SetPNJ(z, pnj.xOff, pnj.yOff, tex)
		end
	end
end

--function TL:OnInitialize()
function TL:ADDON_LOADED(addon) 
	if addon ~= "TownLocator" then return end
	TL:IterateData()
end
