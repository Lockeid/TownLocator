
--
--  Astronomer
--    by Tuhljin
--
--  AstroMain.lua - Implements primary Astronomer functionality and automatic reactions to map changes for
--  world map icons.
--
--  See readme.txt for details.
--

local ASTRONOMER_THIS_VERSION = "0.33"
ASTRONOMER_LOADING = nil


-- Do nothing if a newer or identical version is loaded
if (not Astronomer or not Astronomer.Version or Astronomer.Version < tonumber(ASTRONOMER_THIS_VERSION)) then
  ASTRONOMER_LOADING = true

  local CONT_KALIMDOR, CONT_EK, CONT_OUTLAND, CONT_NORTHREND = 1, 2, 3, 4
  local MAP_AZEROTH, MAP_COSMIC = 0, -1

  -- Debug/testing variables.
  Astronomer_Debug = 0         -- Set to 1 to get some debug messages. Set to 2 or 3 for more debug messages.
  local TryCosmicTrans = false
    -- TryCosmicTrans should be false. Set it to true to have Astronomer discount some logic that is in place
    -- in part because Astrolabe (as of this writing) does not translate the position of icons onto or from the
    -- Cosmic map. Good for testing should a new version of Astrolabe be released. (Note the "in part." If such
    -- an update occurs, Astronomer shouldn't just start skipping that logic as it does when in this test mode.)


-- START INITIALIZATION
----------------------------------------------------------------------------------------------------------------

  if (not Astronomer) then
    Astronomer = {};
  end
  Astronomer.Version = tonumber(ASTRONOMER_THIS_VERSION);
  Astronomer.VersionStr = ASTRONOMER_THIS_VERSION;

  Astronomer.MapHandlingEnabled = true
  local MapHandlingEnabled_internal = true
  Astronomer.BlockNextUpdate = false

  -- Reference to the Astrolabe library
  local Astrolabe = DongleStub("Astrolabe-0.4")

  local theWorldMap = WorldMapDetailFrame      -- Also set this in AstroPing.lua.
  local currentMapC, currentMapZ

  local prevMapC, prevMapZ
  local numTwoMapSwitch = 0
  local prevHandleMapChange
  local MAX_numTwoMapSwitch = 4  -- # of times switching between two maps is allowed within a short time frame
  local timerActive = false
  local timePassed

  if (not Astronomer.ZoneIcons) then
    Astronomer.ZoneIcons = {};
    local continentNames = { GetMapContinents() };
    for key, val in pairs(continentNames) do
      local zoneNames = { GetMapZones(key) };
      Astronomer.ZoneIcons[key] = {};
      Astronomer.ZoneIcons[key][0] = {};
      Astronomer.ZoneIcons[key][0].name = val;
      for k, v in pairs(zoneNames) do
        Astronomer.ZoneIcons[key][k] = {};
        Astronomer.ZoneIcons[key][k].name = v;
      end
    end
    -- Next, add entries for the "continents" whose ID numbers are 0 and -1:
    Astronomer.ZoneIcons[0] = {};
    Astronomer.ZoneIcons[0][0] = {}
    Astronomer.ZoneIcons[0][0].name = "Azeroth";
    Astronomer.ZoneIcons[-1] = {};
    Astronomer.ZoneIcons[-1][0] = {}
    Astronomer.ZoneIcons[-1][0].name = "Cosmic";
  end


-- LOCAL FUNCTIONS
----------------------------------------------------------------------------------------------------------------

  local function debugprint(msg, lvlrequired, premsg)
    lvlrequired = lvlrequired or 1
    if (Astronomer_Debug >= lvlrequired) then
      premsg = premsg or "Astron.: "
      DEFAULT_CHAT_FRAME:AddMessage(premsg..msg, 0.8,0.9,1);
    end
  end

  local function errormsg(msg, ...)
    if (Astronomer_Debug > 0) then
      debugprint(msg,1,"|cffff0000Astronomer ERROR: ")
    end
    -- error(msg, ...)  -- Commented out in favor of calling error() where the line number is more telling.
  end

  -- Table Helpers (tcount) - by Mikk - from http://www.wowwiki.com/Table_Helpers
  -- tcount: count table members even if they're not indexed by numbers
  local function tcount(tab)
    local n=0;
    for _ in pairs(tab) do
      n=n+1;
    end
    return n;
  end

  local function getargtypes(got, numargs, count, arg1, ...)
    count = count + 1
    if (count > numargs) then
      return got;
    end
    if (got) then
      got = got..", "..type(arg1);
    else
      got = type(arg1);
    end
    return getargtypes(got, numargs, count, ...)
  end

  local function checkargs(expect, arg1, ...)
    if (type(expect) ~= "string") then
      errormsg("checkargs(): Invalid argument type given. Expected string; got "..type(expect)..".")
      return false;
    end
    expect = strtrim(expect)
    if (expect == "") then
      errormsg("checkargs(): Invalid argument given. String should not be empty.")
      return false;
    end
    expect = string.gsub(expect,", ",",");    -- Switch ", " to "," for strsplit.
    local numargs = #( { strsplit(",", expect) } );
    local got = getargtypes(nil, numargs, 0, arg1, ...)
    expect = string.gsub(expect,",",", ");    -- Switch "," back to ", " before comparing.

    if (expect == got) then
      return true, got, expect;
    else
      return false, got, expect;
    end
  end

  local function GetArgError(expect, arg1, ...)
    local res, resgot, resexpect = checkargs(expect, arg1, ...);
    if (res) then
      return nil;
    end
    if (resexpect and resgot) then
      return "Invalid argument type given. Expected "..resexpect.."; got "..resgot.."."
    else
      return "Invalid argument passed to GetArgError()."
    end
  end

  local function remiconfromzonelist(icon, C, Z)
    for k, v in pairs(Astronomer.ZoneIcons[C][Z]) do
      if (v == icon) then
        debugprint("Removing Astronomer.ZoneIcons["..C.."]["..Z.."]["..k.."]",2)
        tremove(Astronomer.ZoneIcons[C][Z], k)
        return true;
      end
    end
    debugprint("Couldn't find icon in Astronomer.ZoneIcons["..C.."]["..Z.."]",2)
    return false;
  end

  local function hidezoneiconsinCZ(C, Z)
    for k, icon in ipairs(Astronomer.ZoneIcons[C][Z]) do   -- Use ipairs to grab only icon tables (which use #s > 0).
      icon:Hide()
      if (type(icon.Astro.UpdateCall) == "function") then
        icon.Astro.UpdateCall(icon, "hide");
      end
      if (icon.Astro.WorldPingInform) then
        icon.Astro.WorldPingInform(icon, "hide");
      end
    end
  end

  local function hidezoneiconsinC(C)
    for Z, v in pairs(Astronomer.ZoneIcons[C]) do   -- pairs, not ipairs, to include 0
      hidezoneiconsinCZ(C, Z)
    end
  end

  local function hideallzoneicons()
    for C, v in pairs(Astronomer.ZoneIcons) do   -- pairs, not ipairs, to include 0 and -1
      hidezoneiconsinC(C);
    end
  end

  local function hideallzoneicons_except(arg1, arg2, arg3, arg4)
    for C, v in pairs(Astronomer.ZoneIcons) do   -- pairs, not ipairs, to include 0 and -1
      if (C ~= arg1 and C ~= arg2 and C ~= arg3 and C ~= arg4) then
        hidezoneiconsinC(C);
      end
    end
  end

  local function getzoneIDfromname(C, zoneName)
    for k, v in ipairs(Astronomer.ZoneIcons[C]) do
      if (Astronomer.ZoneIcons[C][k].name == zoneName) then
        return k;
      end
    end
    return nil;
  end

  local function catforiconis(icon, cont, zone)
    if (cont == icon.Astro.C and zone == icon.Astro.Z) then      -- Map icon was placed on
      return "here";
    elseif (cont == 0) then           -- Multiple continents
      return "multcon"
    elseif (cont == -1) then          -- Cosmic map
      return "cosmic"
    elseif (zone == 0) then           -- Continent
      return "cont"
    end                               -- Only remaining maps are at the zone level.
    return "zone";
  end

  local function iconalpha_cat(icon, cat)
    if (cat == "here") then
      return icon.Astro.alphahere
    elseif (cat == "multcon") then
      return icon.Astro.alphamultcon
    elseif (cat == "cosmic") then
    -- Cosmic level unsupported. Default to 1.
      return 1;
    elseif (cat == "cont") then
      return icon.Astro.alphacon
    end               -- Only remaining maps are at the zone level.
    return icon.Astro.alphazone
  end

  local function iconsize_cat(icon, cat)
    if (cat == "here") then
      return icon.Astro.width_here, icon.Astro.height_here
    elseif (cat == "multcon") then
      return icon.Astro.width_multcon, icon.Astro.height_multcon
    elseif (cat == "cosmic") then
    -- Cosmic level unsupported. Default to "here" values.
      return icon.Astro.width_here, icon.Astro.height_here
    elseif (cat == "cont") then
      return icon.Astro.width_con, icon.Astro.height_con
    end               -- Only remaining maps are at the zone level.
    return icon.Astro.width_zone, icon.Astro.height_zone
  end

  local function updateicon(icon)
    if (not icon.Astro.DoNotAutoUpdate) then
      if (Astronomer.BlockNextUpdate) then
        Astronomer.BlockNextUpdate = false
      elseif (MapHandlingEnabled_internal and Astronomer.MapHandlingEnabled) then
        Astronomer.ZoneIcons_Update(icon)
      end
    end
  end


-- GLOBAL FUNCTIONS
----------------------------------------------------------------------------------------------------------------

  function Astronomer.ZoneCZ(zoneName, continent)
    local zone
    if (type(continent) == "number") then
      zone = getzoneIDfromname(continent, zoneName);
      if (zone) then
        return continent, zone;
      else
        return nil;
      end
    end
    for k, v in pairs(Astronomer.ZoneIcons) do
      zone = getzoneIDfromname(k, zoneName);
      if (zone) then
        return k, zone;
      end
    end
    return nil;
  end
  
  function Astronomer.GetZoneName(C, Z)
    if (Astronomer.ZoneIcons[C] and Astronomer.ZoneIcons[C][Z]) then
      return Astronomer.ZoneIcons[C][Z].name;
    end
    return nil;
  end

  function Astronomer.ZoneID(zoneName, continent)
    local _, zone = Astronomer.ZoneCZ(zoneName, continent);
    return zone;
  end

  function Astronomer.OnEvent(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    if (event == "VARIABLES_LOADED") then
      Astronomer.MainFrame:RegisterEvent("WORLD_MAP_UPDATE")
      Astronomer.MainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
      Astronomer.MainFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
      debugprint("Astronomer v"..Astronomer.VersionStr.." loaded.",1,"")
    elseif (event == "WORLD_MAP_UPDATE" and theWorldMap:IsVisible() and
            MapHandlingEnabled_internal and Astronomer.MapHandlingEnabled) then
      local C, Z = GetCurrentMapContinent(), GetCurrentMapZone()
      -- Don't update if already on this map unless world map is just being opened:
      if (arg1 == "panel-show" or currentMapC ~= C or currentMapZ ~= Z) then
      -- (Can't rely on just it being a different zone because the player may look at the map in one zone, close it,
      -- then move to another where an addon that uses Astronomer may trigger an icon update that moves an icon. If
      -- the player doesn't look at the map while in the other zone and then returns to the previous zone and, once
      -- there, he opens the world map again, the icon will be in the wrong place. That is, unless we also check if
      -- arg1 is "panel-show" - so we do.

      -- Check to see if two maps are being switched between repeatedly in less than a second's time. This occurs
      -- sometimes when zoning or on a boat or flight path that goes outside normal zone boundaries. (It's not
      -- perfect, since one could happen at the end of a second and the next at the beginning, but it doesn't
      -- need to be perfect.) Without this being handled, HandleMapChange can sometimes be unnecessarily called
      -- several hundred times over just a few seconds!
        if ( (timerActive or prevHandleMapChange == time()) and prevMapC == C and prevMapZ == Z) then
          numTwoMapSwitch = numTwoMapSwitch + 1
          --debugprint("numTwoMapSwitch is "..numTwoMapSwitch)
          if (numTwoMapSwitch >= MAX_numTwoMapSwitch) then
            if (not timerActive) then      -- If timer not going
              --debugprint("|cfffff000Exceeded MAX_numTwoMapSwitch ("..MAX_numTwoMapSwitch..") with "..numTwoMapSwitch..".")
              --debugprint("|cfffff000Timer started. (time="..time()..")")
              timerActive = true
              timePassed = 0
              Astronomer.MainFrame:Show()    -- Start timer
            end
            return nil;
          end
        else
          numTwoMapSwitch = 0
        end
        Astronomer.HandleMapChange()
      end
    elseif (event == "PLAYER_ENTERING_WORLD") then
      debugprint("PLAYER_ENTERING_WORLD")
      MapHandlingEnabled_internal = true
      Astronomer.HandleMapChange()      -- While it's not needed most of the time, it is needed sometimes; e.g.
                                        -- updates have not occurred while arriving at a destination by ship.
    elseif (event == "PLAYER_LEAVING_WORLD") then
      debugprint("PLAYER_LEAVING_WORLD")
      MapHandlingEnabled_internal = false
    end
  end

  function Astronomer.HideZoneIcon(icon)
    icon.Astro.Visible = false
    updateicon(icon)
  end

  function Astronomer.ShowZoneIcon(icon)
    icon.Astro.Visible = true
    updateicon(icon)
  end

  function Astronomer.SetZoneIconVisByCat(icon, vishere, viszone, viscon, vismultcon)
    local err1, err2, err3, err4 = ", nil", ", nil", ", nil", ", nil"
    if (vishere ~= nil) then err1 = ", boolean" end
    if (viszone ~= nil) then err2 = ", boolean" end
    if (viscon ~= nil) then err3 = ", boolean" end
    if (vismultcon ~= nil) then err4 = ", boolean" end
    -- debugprint("table"..err1..err2..err3..err4)
    local errmsg = GetArgError("table"..err1..err2..err3..err4, icon, vishere, viszone, viscon, vismultcon)
    if (errmsg) then
      errormsg("SetZoneIconVisByCat(): "..errmsg)
      error("SetZoneIconVisByCat(): "..errmsg)
      return nil;
    elseif (not icon.Astro) then
      errormsg("SetZoneIconVisByCat(): Invalid icon.")
      error("SetZoneIconVisByCat(): Invalid icon.")
      return nil;
    end
    if (vishere ~= nil) then
      icon.Astro.vishere = vishere
    end
    if (viszone ~= nil) then
      icon.Astro.viszone = viszone
    end
    if (viscon ~= nil) then
      icon.Astro.viscon = viscon
    end
    if (vismultcon ~= nil) then
      icon.Astro.vismultcon = vismultcon
    end
    updateicon(icon)
  end

  function Astronomer.SetZoneIconAlphaByCat(icon, ahere, azone, acon, amultcon)
    local err1, err2, err3, err4 = ", nil", ", nil", ", nil", ", nil"
    if (ahere ~= nil) then err1 = ", number" end
    if (azone ~= nil) then err2 = ", number" end
    if (acon ~= nil) then err3 = ", number" end
    if (amultcon ~= nil) then err4 = ", number" end
    -- debugprint("table"..err1..err2..err3..err4)
    local errmsg = GetArgError("table"..err1..err2..err3..err4, icon, ahere, azone, acon, amultcon)
    if (errmsg) then
      errormsg("SetZoneIconAlphaByCat(): "..errmsg)
      error("SetZoneIconAlphaByCat(): "..errmsg)
      return nil;
    elseif (not icon.Astro) then
      errormsg("SetZoneIconAlphaByCat(): Invalid icon.")
      error("SetZoneIconAlphaByCat(): Invalid icon.")
      return nil;
    end
    if (ahere ~= nil) then
      icon.Astro.alphahere = ahere
    end
    if (azone ~= nil) then
      icon.Astro.alphazone = azone
    end
    if (acon ~= nil) then
      icon.Astro.alphacon = acon
    end
    if (amultcon ~= nil) then
      icon.Astro.alphamultcon = amultcon
    end
    updateicon(icon)
  end

  function Astronomer.SetZoneIconSizeByCat(icon, i_here, i_zone, i_con, i_multcon)
    local err1, err2, err3, err4 = ", nil", ", nil", ", nil", ", nil"
    if (i_here ~= nil) then err1 = ", number" end
    if (i_zone ~= nil) then err2 = ", number" end
    if (i_con ~= nil) then err3 = ", number" end
    if (i_multcon ~= nil) then err4 = ", number" end
    -- debugprint("table"..err1..err2..err3..err4)
    local errmsg = GetArgError("table"..err1..err2..err3..err4, icon, i_here, i_zone, i_con, i_multcon)
    if (errmsg) then
      errormsg("SetZoneIconSizeByCat(): "..errmsg)
      error("SetZoneIconSizeByCat(): "..errmsg)
      return nil;
    elseif (not icon.Astro) then
      errormsg("SetZoneIconSizeByCat(): Invalid icon.")
      error("SetZoneIconSizeByCat(): Invalid icon.")
      return nil;
    end
    if (i_here ~= nil) then
      icon.Astro.width_here = i_here
      icon.Astro.height_here = i_here
    end
    if (i_zone ~= nil) then
      icon.Astro.width_zone = i_zone
      icon.Astro.height_zone = i_zone
    end
    if (i_con ~= nil) then
      icon.Astro.width_con = i_con
      icon.Astro.height_con = i_con
    end
    if (i_multcon ~= nil) then
      icon.Astro.width_multcon = i_multcon
      icon.Astro.height_multcon = i_multcon
    end
    updateicon(icon)
  end

  function Astronomer.SetZoneIconWidthByCat(icon, i_here, i_zone, i_con, i_multcon)
    local err1, err2, err3, err4 = ", nil", ", nil", ", nil", ", nil"
    if (i_here ~= nil) then err1 = ", number" end
    if (i_zone ~= nil) then err2 = ", number" end
    if (i_con ~= nil) then err3 = ", number" end
    if (i_multcon ~= nil) then err4 = ", number" end
    -- debugprint("table"..err1..err2..err3..err4)
    local errmsg = GetArgError("table"..err1..err2..err3..err4, icon, i_here, i_zone, i_con, i_multcon)
    if (errmsg) then
      errormsg("SetZoneIconWidthByCat(): "..errmsg)
      error("SetZoneIconWidthByCat(): "..errmsg)
      return nil;
    elseif (not icon.Astro) then
      errormsg("SetZoneIconWidthByCat(): Invalid icon.")
      error("SetZoneIconWidthByCat(): Invalid icon.")
      return nil;
    end
    if (i_here ~= nil) then
      icon.Astro.width_here = i_here
    end
    if (i_zone ~= nil) then
      icon.Astro.width_zone = i_zone
    end
    if (i_con ~= nil) then
      icon.Astro.width_con = i_con
    end
    if (i_multcon ~= nil) then
      icon.Astro.width_multcon = i_multcon
    end
    updateicon(icon)
  end

  function Astronomer.SetZoneIconHeightByCat(icon, i_here, i_zone, i_con, i_multcon)
    local err1, err2, err3, err4 = ", nil", ", nil", ", nil", ", nil"
    if (i_here ~= nil) then err1 = ", number" end
    if (i_zone ~= nil) then err2 = ", number" end
    if (i_con ~= nil) then err3 = ", number" end
    if (i_multcon ~= nil) then err4 = ", number" end
    -- debugprint("table"..err1..err2..err3..err4)
    local errmsg = GetArgError("table"..err1..err2..err3..err4, icon, i_here, i_zone, i_con, i_multcon)
    if (errmsg) then
      errormsg("SetZoneIconHeightByCat(): "..errmsg)
      error("SetZoneIconHeightByCat(): "..errmsg)
      return nil;
    elseif (not icon.Astro) then
      errormsg("SetZoneIconHeightByCat(): Invalid icon.")
      error("SetZoneIconHeightByCat(): Invalid icon.")
      return nil;
    end
    if (i_here ~= nil) then
      icon.Astro.height_here = i_here
    end
    if (i_zone ~= nil) then
      icon.Astro.height_zone = i_zone
    end
    if (i_con ~= nil) then
      icon.Astro.height_con = i_con
    end
    if (i_multcon ~= nil) then
      icon.Astro.height_multcon = i_multcon
    end
    updateicon(icon)
  end

  -- For use with Models, only (such as AstroPing.lua's ping objects)
  function Astronomer.SetZoneIconScaleByCat(icon, s_here, s_zone, s_con, s_multcon)
    local err1, err2, err3, err4 = ", nil", ", nil", ", nil", ", nil"
    if (s_here ~= nil) then err1 = ", number" end
    if (s_zone ~= nil) then err2 = ", number" end
    if (s_con ~= nil) then err3 = ", number" end
    if (s_multcon ~= nil) then err4 = ", number" end
    -- debugprint("table"..err1..err2..err3..err4)
    local errmsg = GetArgError("table"..err1..err2..err3..err4, icon, s_here, s_zone, s_con, s_multcon)
    if (errmsg) then
      errormsg("SetZoneIconScaleByCat(): "..errmsg)
      error("SetZoneIconScaleByCat(): "..errmsg)
      return nil;
    elseif (not icon.Astro) then
      errormsg("SetZoneIconScaleByCat(): Invalid icon.")
      error("SetZoneIconScaleByCat(): Invalid icon.")
      return nil;
    end
    if (s_here ~= nil) then
      icon.Astro.scalehere = s_here
    end
    if (s_zone ~= nil) then
      icon.Astro.scalezone = s_zone
    end
    if (s_con ~= nil) then
      icon.Astro.scalecon = s_con
    end
    if (s_multcon ~= nil) then
      icon.Astro.scalemultcon = s_multcon
    end
    updateicon(icon)
  end

  function Astronomer.NewZoneIcon(texture, width, height, continent, zone, x, y, hereonly)
    if (not height or height == 0) then
      height = width
    end
    local expect = "string, number, number"
    if (continent or zone or x or y or hereonly) then
      if (hereonly) then
        expect = "string, number, number, number, number, number, number, boolean"
      else
        expect = "string, number, number, number, number, number, number"
      end
    end
    local errmsg = GetArgError(expect, texture, width, height, continent, zone, x, y, hereonly)
    if (errmsg) then
      errormsg("NewZoneIcon(): "..errmsg)
      error("NewZoneIcon(): "..errmsg)
      return nil;
    elseif (continent and not Astronomer.ZoneIcons[continent]) then
      errormsg("NewZoneIcon(): Invalid continent given. (continent="..continent..")")
      return false;
    elseif (zone and not Astronomer.ZoneIcons[continent][zone]) then
      errormsg("NewZoneIcon(): Invalid zone given. (zone="..zone..")")
      return false;
    end

    local iconWidget = CreateFrame("Button", nil, theWorldMap)
    iconWidget:SetWidth(width)
    iconWidget:SetHeight(height)
    iconWidget.icon = iconWidget:CreateTexture("ARTWORK")
    iconWidget.icon:SetAllPoints()
    iconWidget.icon:SetTexture(texture)
    if (continent and zone and x and y) then
      return iconWidget, Astronomer.AddZoneIcon(iconWidget, continent, zone, x, y, hereonly)
    end
    iconWidget:Hide()
    return iconWidget
  end

  function Astronomer.AddZoneIcon(icon, continent, zone, x, y, hereonly)
    if (hereonly) then
      hereonly = true
    else
      hereonly = false
    end
    local errmsg = GetArgError("table, number, number, number, number", icon, continent, zone, x, y)
    if (errmsg) then
      errormsg("AddZoneIcon(): "..errmsg)
      error("AddZoneIcon(): "..errmsg)
      return false;
    elseif (not Astronomer.ZoneIcons[continent]) then
      errormsg("AddZoneIcon(): Invalid continent given. (continent="..continent..")")
      return false;
    elseif (not Astronomer.ZoneIcons[continent][zone]) then
      errormsg("AddZoneIcon(): Invalid zone given. (zone="..zone..")")
      return false;
    elseif (Astronomer.IsIconPlaced(icon)) then
      debugprint("AddZoneIcon(): Icon is already placed on a map.")
      return false;
    end

    if (type(icon.Astro) ~= "table") then
      icon.Astro = {};
    end
    -- Position
    icon.Astro.C = continent
    icon.Astro.Z = zone
    icon.Astro.x = x
    icon.Astro.y = y
    icon.Astro.offsetX = nil
    icon.Astro.offsetY = nil
    -- Visibility
    icon.Astro.Visible = true
    icon.Astro.vishere = true
    if (hereonly) then
      icon.Astro.viszone = false
      icon.Astro.viscon = false
      icon.Astro.vismultcon = false
    else
      icon.Astro.viszone = true
      icon.Astro.viscon = true
      icon.Astro.vismultcon = true
    end
    -- Alpha
    icon.Astro.alphahere = nil
    icon.Astro.alphazone = nil
    icon.Astro.alphacon = nil
    icon.Astro.alphamultcon = nil
    -- Size
    icon.Astro.width_here = nil
    icon.Astro.height_here = nil
    icon.Astro.width_zone = nil
    icon.Astro.height_zone = nil
    icon.Astro.width_con = nil
    icon.Astro.height_con = nil
    icon.Astro.width_multcon = nil
    icon.Astro.height_multcon = nil
    -- Scale
    icon.Astro.scalehere = nil
    icon.Astro.scalezone = nil
    icon.Astro.scalecon = nil
    icon.Astro.scalemultcon = nil

    icon.Astro.DoNotAutoUpdate = nil

    -- Using #(), not tcount(), because we're excluding entries that aren't a number of 1 or higher.
    local num = #(Astronomer.ZoneIcons[continent][zone]) + 1
    Astronomer.ZoneIcons[continent][zone][num] = icon
    debugprint("# of icons on this map: "..num,2)

    updateicon(icon)
    return true;
  end

  function Astronomer.MoveZoneIcon(icon, continent, zone, x, y)
    if (not continent and type(icon) == "table" and type(icon.Astro) == "table") then
      continent = icon.Astro.C
      if (not zone) then
        zone = icon.Astro.Z
      end
    end
    local errmsg = GetArgError("table, number, number, number, number", icon, continent, zone, x, y)
    if (errmsg) then
      errormsg("MoveZoneIcon(): "..errmsg)
      error("MoveZoneIcon(): "..errmsg)
      return false;
    elseif (not Astronomer.ZoneIcons[continent]) then
      errormsg("MoveZoneIcon(): Invalid continent given. (continent="..continent..")")
      return false;
    elseif (not Astronomer.ZoneIcons[continent][zone]) then
      errormsg("MoveZoneIcon(): Invalid zone given. (zone="..zone..")")
      return false;
    elseif (not Astronomer.IsIconPlaced(icon)) then
      debugprint("MoveZoneIcon(): Given icon not placed on any maps.")
      return false;
    end

    if (icon.Astro.C ~= continent or icon.Astro.Z ~= zone) then
      remiconfromzonelist(icon, icon.Astro.C, icon.Astro.Z)
      local num = #(Astronomer.ZoneIcons[continent][zone]) + 1
      Astronomer.ZoneIcons[continent][zone][num] = icon
      debugprint("# of icons on this map: "..num,2)
      icon.Astro.C = continent
      icon.Astro.Z = zone
    end
    icon.Astro.x = x;
    icon.Astro.y = y;

    updateicon(icon)
    debugprint("Icon moved.")
    return true;
  end

  function Astronomer.IsIconPlaced(icon)
    local C, Z
    if (icon and icon.Astro) then
      C = icon.Astro.C
      Z = icon.Astro.Z
    end
    if (not C or not Z) then
      return false;
    end
    for k, v in pairs(Astronomer.ZoneIcons[C][Z]) do
      if (v == icon) then
        return true;
      end
    end
    return false;
  end

  function Astronomer.RemZoneIcon(icon)
    local errmsg = GetArgError("table", icon)
    if (errmsg) then
      errormsg("RemZoneIcon(): "..errmsg)
      error("RemZoneIcon(): "..errmsg)
      return false;
    elseif (not Astronomer.IsIconPlaced(icon)) then
      debugprint("RemZoneIcon(): Given icon not placed on any maps.")
      return false;
    end

    remiconfromzonelist(icon, icon.Astro.C, icon.Astro.Z)
    icon.Astro.C = nil;
    icon.Astro.Z = nil;
    icon.Astro.x = nil;
    icon.Astro.y = nil;
    icon:Hide()
    if (type(icon.Astro.UpdateCall) == "function") then
      icon.Astro.UpdateCall(icon, "rem");
      icon.Astro.UpdateCall = nil;
    end
    if (icon.Astro.WorldPingInform) then
      icon.Astro.WorldPingInform(icon, "rem");
      -- Setting the icon's WorldPingInform var to nil is handled in that function.
    end
    return true;
  end
  
  -- Check icon visibility based on given map category
  function Astronomer.iconvis_cat(icon, cat)
    if (cat == "here") then
      return icon.Astro.vishere
    elseif (cat == "multcon") then
      return icon.Astro.vismultcon
    elseif (cat == "cosmic") then
      if (TryCosmicTrans) then
        return true;
      end             -- Astrolabe won't translate positions from anywhere else to the Cosmic map, so don't
      return false;   -- bother; if icon was actually placed here, vishere variable handled it, above.
    elseif (cat == "cont") then
      return icon.Astro.viscon
    end               -- Only remaining maps are at the zone level.
    return icon.Astro.viszone
  end
  
  -- Check icon scale based on given map category
  function Astronomer.iconscale_cat(icon, cat)
    if (cat == "here") then
      return icon.Astro.scalehere
    elseif (cat == "multcon") then
      return icon.Astro.scalemultcon
    elseif (cat == "cosmic") then
    -- Cosmic level unsupported. Default to 1.
      return 1;
    elseif (cat == "cont") then
      return icon.Astro.scalecon
    end               -- Only remaining maps are at the zone level.
    return icon.Astro.scalezone
  end

  function Astronomer.ZoneIcons_Update(icon, icon2, ...)
    local continent, zone = GetCurrentMapContinent(), GetCurrentMapZone()
    local cat = catforiconis(icon, continent, zone)
    local reason = "update"
    if (icon.Astro.Visible and Astronomer.iconvis_cat(icon, cat)) then
      local alpha = iconalpha_cat(icon, cat)
      if (alpha) then
        icon:SetAlpha(alpha)
      end
      local width, height = iconsize_cat(icon, cat)
      if (width) then
        icon:SetWidth(width)
      end
      if (height) then
        icon:SetHeight(height)
      end
      Astrolabe:PlaceIconOnWorldMap(theWorldMap, icon, icon.Astro.C, icon.Astro.Z, icon.Astro.x, icon.Astro.y)

      -- Didn't work when before PlaceIconOnWorldMap, so do it after:
      local scale = Astronomer.iconscale_cat(icon, cat)
      if (scale) then
        icon:SetModelScale(scale)
      end
    else
      icon:Hide()
      reason = "hide"
    end

    if (type(icon.Astro.UpdateCall) == "function") then
      icon.Astro.UpdateCall(icon, reason, cat, continent, zone);
    end
    if (icon.Astro.WorldPingInform) then
      icon.Astro.WorldPingInform(icon, reason, cat);
      --icon.Astro.WorldPingInform(icon, reason, continent, zone);
    end

    if (icon2) then
      Astronomer.ZoneIcons_Update(icon2, ...)
    end
  end

  function Astronomer.ZoneIcons_UpdateZone(C,Z)
    for k, icon in ipairs(Astronomer.ZoneIcons[C][Z]) do   -- Use ipairs to grab only icon tables (which use #s > 0).
      if (not icon.Astro.DoNotAutoUpdate) then
        Astronomer.ZoneIcons_Update(icon)
      end
    end
  end

  function Astronomer.ZoneIcons_UpdateContinent(C)
    for Z, v in pairs(Astronomer.ZoneIcons[C]) do   -- pairs, not ipairs, to include 0
      Astronomer.ZoneIcons_UpdateZone(C,Z);
    end
  end

  function Astronomer.ZoneIcons_UpdateAll()
    for C, v in pairs(Astronomer.ZoneIcons) do   -- pairs, not ipairs, to include 0 and -1
      Astronomer.ZoneIcons_UpdateContinent(C);
    end
  end

  function Astronomer.HandleMapChange(timercalled)
    local C, Z = GetCurrentMapContinent(), GetCurrentMapZone()
    prevHandleMapChange = time()
    prevMapC, prevMapZ = currentMapC, currentMapZ
    currentMapC = C
    currentMapZ = Z

    if (Astronomer_Debug >= 2) then
      debugprint("HandleMapChange() called for "..Astronomer.ZoneIcons[C][Z].name.." ("..C..", "..Z..").",2)
    end

    -- Avoid unnecessary processing by grouping things together according to what regions' icons
    -- can be shown at the same time by Astrolabe:
    if (TryCosmicTrans) then
      Astronomer.ZoneIcons_UpdateAll()
    elseif (C == CONT_KALIMDOR or C == CONT_EK or C == CONT_NORTHREND) then
      hideallzoneicons_except(C, MAP_AZEROTH)
      Astronomer.ZoneIcons_UpdateContinent(MAP_AZEROTH)
      Astronomer.ZoneIcons_UpdateContinent(C)
    elseif (C == MAP_AZEROTH) then
      hideallzoneicons_except(MAP_AZEROTH, CONT_KALIMDOR, CONT_EK, CONT_NORTHREND)
      Astronomer.ZoneIcons_UpdateContinent(CONT_KALIMDOR)
      Astronomer.ZoneIcons_UpdateContinent(CONT_EK)
      Astronomer.ZoneIcons_UpdateContinent(CONT_NORTHREND)
      Astronomer.ZoneIcons_UpdateContinent(MAP_AZEROTH)
    elseif (C == CONT_OUTLAND or C == MAP_COSMIC) then
      hideallzoneicons_except(C)
      Astronomer.ZoneIcons_UpdateContinent(C)
    else  -- Failsafe
      Astronomer.ZoneIcons_UpdateAll()
    end
  end

  function Astronomer.SuspendMapHandling()
    Astronomer.MapHandlingEnabled = false
  end

  function Astronomer.ResumeMapHandling(arg1, icon2, ...)
    Astronomer.MapHandlingEnabled = true
    if (type(arg1) == "table") then
      Astronomer.ZoneIcons_Update(arg1, icon2, ...)
    elseif (arg1 == nil or arg1 == true) then
      Astronomer.HandleMapChange()
    end
  end

  function Astronomer.OnUpdate(frame, elapsed)
    timePassed = timePassed + elapsed
    if (timePassed >= 3) then   -- # is the delay in seconds.
      Astronomer.MainFrame:Hide()
      timerActive = false
      --debugprint("|cfffff000Timer ended. (time="..time()..")")
      Astronomer.HandleMapChange()     -- Delayed long enough: Handle map change now.
    end
  end


-- FINAL INITIALIZATION
----------------------------------------------------------------------------------------------------------------

  if (not Astronomer.MainFrame) then
    Astronomer.MainFrame = CreateFrame("Frame")
  end

  Astronomer.MainFrame:Hide()
  Astronomer.MainFrame:RegisterEvent("VARIABLES_LOADED")
  Astronomer.MainFrame:SetScript("OnEvent", Astronomer.OnEvent)
  Astronomer.MainFrame:SetScript("OnUpdate", Astronomer.OnUpdate)
end

