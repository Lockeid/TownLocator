local L = TL_GetLocalization()

local Data = {}
	Data[L.Dalaran] =
	{
		["Dalaran Silver Enclave"] = {
			{
				["yOff"] = 0.5576320886611939,
				["xOff"] = 0.4058589339256287,
			}, -- [1] -- [3]
		},
		["Dalaran Inn"] = {
			{
				["yOff"] = 0.394712507724762,
				["xOff"] = 0.500997006893158,
			}, -- [1]
		},
		["Dalaran Northern Bank"] = {
			{
				["yOff"] = 0.1804498583078384,
				["xOff"] = 0.5284157395362854,
			}, -- [1]
		},
		["Dalaran Flight Master"] = {
			{
				["yOff"] = 0.4566808342933655,
				["xOff"] = 0.7269784212112427,
			}, -- [1]
		},
		["Dalaran Horde Inn"] = {
			{
				["yOff"] = 0.3271946012973785,
				["xOff"] = 0.6394270062446594,
			}, -- [1]
		},
		["Dalaran Visitor Center"] = {
			{
				["yOff"] = 0.559872567653656,
				["xOff"] = 0.5201412439346314,
			}, -- [1]
		},
		["Dalaran Locksmith"] = {
			{
				["yOff"] = 0.2396720945835114,
				["xOff"] = 0.5745486617088318,
			}, -- [1]
		},
		["Dalaran Krasus' Landing"] = {
			{
				["yOff"] = 0.4249832332134247,
				["xOff"] = 0.6552809476852417,
			}, -- [1]
		},
		["Dalaran Sunreaver's Sanctuary"] = {
			{
				["yOff"] = 0.3784476220607758,
				["xOff"] = 0.5506996512413025,
			}, -- [1]
		},
		["Dalaran Well"] = {
			{
				["yOff"] = 0.3375322222709656,
				["xOff"] = 0.4815913140773773,
			}, -- [1]
		},
		["Dalaran Alliance Inn"] = {
			{
				["yOff"] = 0.6057940125465393,
				["xOff"] = 0.4509689807891846,
			}, -- [1]
		},
		["Dalaran Eastern Sewer Entrance"] = {
			{
				["yOff"] = 0.4769404530525208,
				["xOff"] = 0.6026757955551148,
			}, -- [1]
		},
		["Dalaran Western Sewer Entrance"] = {
			{
				["yOff"] = 0.4523075520992279,
				["xOff"] = 0.3523128926753998,
			}, -- [1]
		},
	}
	
function TL_GetData() 
	return Data
end
