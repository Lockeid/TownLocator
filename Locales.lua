local L = {}
if GetLocale() == "frFR" then
	-- Alliance
	L.Stormwind = "Hurlevent"
	L.Ironforge = "Forgefer"
	L.Exodar = "L'Exodar"
	L.Darnassus = "Darnassus"
	-- Horde
	L.Orgrimmar = "Orgrimmar"
	L.ThunderBluff = "Les Pitons du Tonnerre"
	L.Undercity = "Fossoyeuse"
	L.SilverMoonCity = "Lune-d'argent"
	-- Outland
	L.Shattrath = "Shattrath"
	-- Northrend
	L.Dalaran = "Dalaran"
else 
	-- Alliance
	L.Stormwind = "Shattrathormwind City"
	L.Ironforge = "Ironforge"
	L.Exodar = "The Exodar"
	L.Darnassus = "Darnassus"
	-- Horde
	L.Orgrimmar = "Orgrimmar"
	L.ThunderBluff = "Thunder Bluff"
	L.Undercity = "Undercity"
	L.SilverMoonCity = "Silvermoon City"
	-- Outland
	L.Shattrath = "Shattrath"
	-- Northrend
	L.Dalaran = "Dalaran"
end

function TL_GetLocalization()
	return L
end
