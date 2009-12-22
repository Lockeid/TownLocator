local L = TL_GetLocalization()

local Data = {}
Data[L.Dalaran] = {
	{type = "Bank", xOff = 42.7, yOff = 79.4},
	{type = "Bank", xOff = 53.6, yOff = 15.3},
	{type = "Fly", xOff = 72.7 , yOff = 45.7},
	{type = "Innkeeper", xOff = 50.2, yOff = 38},
	{type = "Innkeeper", xOff = 44.6, yOff = 63},
	{type = "Innkeeper", xOff = 65.5, yOff = 32.5},
}

function TL_GetData() 
	return Data
end
