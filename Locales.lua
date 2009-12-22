local L = {}
if GetLocale() == "frFR" then
	-- Alliance
	L.SW = "Hurlevent"
	L.IF = "Forgefer"
	L.Exodar = "L'Exodar"
	L.Darnassus = "Darnassus"
	-- Horde
	L.Orgrimmar = "Orgrimmar"
	L.TB = "Les Pitons du Tonnerre"
	L.UD = "Fossoyeuse"
	L.SM = "Lune-d'argent"
	-- Outland
	L.ST = "Shattrath"
	-- Northrend
	L.Dalaran = "Dalaran"
else 
	-- Alliance
	L.SW = "Stormwind City"
	L.IF = "Ironforge"
	L.Exodar = "The Exodar"
	L.Darnassus = "Darnassus"
	-- Horde
	L.Orgrimmar = "Orgrimmar"
	L.TB = "Thunder Bluff"
	L.UD = "Undercity"
	L.SM = "Silvermoon City"
	-- Outland
	L.ST = "Shattrath"
	-- Northrend
	L.Dalaran = "Dalaran"
end

function TL_GetLocalization()
	return L
end
