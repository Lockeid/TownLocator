
--
--  Astronomer
--    by Tuhljin
--
--  AstroPing.lua - Implements "world map ping" functionality.
--

-- Do nothing if this version of Astronomer isn't loading
if (ASTRONOMER_LOADING) then

-- LOCAL VARIABLES AND FUNCTIONS
----------------------------------------------------------------------------------------------------------------

  local theWorldMap = WorldMapDetailFrame  -- Also set this in AstroMain.lua.
  local defWorldPing = WorldMapPing        -- Blizzard's world map ping (used for marking player's position)

  local NumWorldPingObj = 0
  local MAX_NumWorldPingObj = 45           -- Maximum number of ping objects to allow. (Largely arbitrary.)

  local PING_TIME = MINIMAPPING_TIMER or 5
    -- MINIMAPPING_TIMER is a default Blizzard value used for minimap pings' time before fading.
    -- As of this writing, it defaults to 5. (Their world map ping time defaults to 1, but this isn't enough for us.)
  local FADE_TIME = MINIMAPPING_FADE_TIMER or 0.5
    -- MINIMAPPING_FADE_TIMER is a default Blizzard value used for minimap and world map ping fading.
  ASTRONOMER_PING_INDEFINITE = "inf"       -- Use ASTRONOMER_PING_INDEFINITE as your pingtimer argument to make
                                           -- it ping indefinitely, so it won't automatically time out and stop.
  local AllowTakeoverIndef = false         -- Set to true to allow taking over indefinitely-pinging objects
                                           -- if takeover arg is 2. Otherwise, sets takeover arg to 1 max.
  local DefFrameLevel = 3                  -- Default frame level for ping objects.

  local ActiveWorldPings = {};
  local UsedPingIDs = 0;

  local function debugprint(msg, lvlrequired, premsg)
    lvlrequired = lvlrequired or 1
    if (Astronomer_Debug >= lvlrequired) then
      premsg = premsg or "Astron.: "
      DEFAULT_CHAT_FRAME:AddMessage(premsg..msg, 0.8,0.9,1);
    end
  end

  local function errormsg(msg)
    if (Astronomer_Debug > 0) then
      debugprint(msg,1,"|cffff0000Astronomer ERROR: ")
    end
  end

  -- Create a new world ping object.
  local function NewWorldPingWidget()
    if (NumWorldPingObj + 1 > MAX_NumWorldPingObj) then
      --debugprint("MAX_NumWorldPingObj ("..MAX_NumWorldPingObj..") reached. Ping object not created.",3)
      return nil;
    end
    local w = CreateFrame("Model", "Astronomer_WorldMapPing"..(NumWorldPingObj + 1), theWorldMap, defWorldPing)
    w:Hide()
    w:SetModel("Interface\\MiniMap\\Ping\\MinimapPing.mdx")
    w:SetSequence(0);
    w:SetPosition(defWorldPing:GetPosition())

    NumWorldPingObj = NumWorldPingObj + 1
    debugprint("Created Astronomer_WorldMapPing"..NumWorldPingObj..".")
    return w;
  end

  local function remfromactivelist(pingobj)
    for k, v in ipairs(ActiveWorldPings) do
      if (v == pingobj) then
        debugprint("Removing ActiveWorldPings["..k.."].",2)
        tremove(ActiveWorldPings, k)
        return true;
      end
    end
    debugprint("|cffff0000Couldn't find pingobj in ActiveWorldPings.")
    return false;
  end

  -- Get a world ping widget that isn't currently being used, or create one if all existing ones are used.
  -- Failing that, take over the object that has been pinging the longest (unless passed arg is false).
  -- Avoid taking indefinitely-pinging objects unless there are no others to take over.
  -- The second argument returned is 0 if the widget is new, 2 if a takeover was performed, nil if no widget
  -- was returned, and 1 otherwise.
  -- takeover arg should be 0 for no takeovers allowed, 1 to allow normal takeovers (default), 2 to allow
  -- taking over indefinitely-pinging objects.
  local function FindAvailableWorldPingWidget(takeover)
    takeover = takeover or 1
    if (not AllowTakeoverIndef and takeover > 1) then
      takeover = 1
    end
    --debugprint(takeover,1,"takeover: ")
    local widget
    for i=1,NumWorldPingObj do
      widget = getglobal("Astronomer_WorldMapPing"..i)
      if (not widget.pinging) then
        return widget, 1;
      end
    end
    widget = NewWorldPingWidget();
    -- If creating a new widget failed and we are allowed to take control of an existing one...
    if ((not widget) and takeover > 0) then
      --debugprint("trying takeover")
      -- Find first widget in ActiveWorldPings (which means the longest-pinging) that isn't pinging
      -- indefinitely.
      local infpingobj1
      for k, v in ipairs(ActiveWorldPings) do
        if ( v.timer == ASTRONOMER_PING_INDEFINITE ) then
          if (takeover > 1 and not infpingobj1) then
            infpingobj1 = v    -- Remember the longest-indefinitely-pinging object, in case cannot find another
            --debugprint("remembering 1st indefinite: "..infpingobj1:GetName())
          end
        else
          --debugprint("found non-indefinite")
          return v, 2;
        end
      end
      --debugprint("no non-indefinites")
      return infpingobj1, 2;  -- Will be nil if ActiveWorldPings contained only indefinitely-pinging objects and
                              -- takeover is 1.
    end
    return widget, 0;
  end

  local function GetWorldPingObj(scale, level, takeover)
    local pingobj, res = FindAvailableWorldPingWidget(takeover)
    if (not pingobj) then
      return nil
    end
    if (pingobj.pinging) then  -- If taking over a previous ping, stop what it's currently doing first.
      Astronomer.StopWorldPing(pingobj)
    end
    --debugprint("GetWorldPingObj(): Using "..pingobj:GetName()..".")
    scale = scale or 0.4       -- 0.4 is the scale used by Blizzard for player-position world map pings
    level = level or DefFrameLevel
    pingobj:SetModelScale(scale)
    pingobj:SetWidth(50)       -- 50x50 is size used by Blizzard for this model
    pingobj:SetHeight(50)
    --pingobj:SetAllPoints()
    pingobj:SetFrameLevel(level)
    pingobj:SetAlpha(255)
    return pingobj, res;
  end

  local function IconAttachedPingUpdate(pingobj, icon, cat)
    pingobj.Astro.C = icon.Astro.C
    pingobj.Astro.Z = icon.Astro.Z
    pingobj.Astro.x = icon.Astro.x
    pingobj.Astro.y = icon.Astro.y

    -- If the icon the ping object is attached to is visible and the ping object's visibility-by-map-category
    -- checks out...
    cat = cat or "here"
    if (icon:IsShown() and Astronomer.iconvis_cat(pingobj, cat)) then
      local scale = Astronomer.iconscale_cat(pingobj, cat)
      if (scale) then
        pingobj:SetModelScale(scale)
      end

      local x = pingobj.Astro.offsetX or 0.5;  -- Offset by percentages (0 < x <= 1).
      local y = pingobj.Astro.offsetY or 0.5;  -- 0.5 and 0.5 is about center (50% and 50%).
                               -- Tip: If you want it on pixel #11 out of 32 pixels, 11/32 gets you the # to use.
      pingobj:ClearAllPoints();
      pingobj:SetPoint("CENTER", icon, "TOPLEFT", x * icon:GetWidth(), -y * icon:GetHeight());
      pingobj:Show();
    else
      pingobj:Hide();
    end
  end

  local function pingworldCZ(noupdate, C, Z, x, y, pingtime, fadetime, vishere, viszone, viscon, vismultcon,
                             scale, level, takeover)
    local pingobj, res = GetWorldPingObj(scale, level, takeover)
    if (not pingobj) then
      return nil;
    end
    tinsert(ActiveWorldPings, pingobj)
    UsedPingIDs = UsedPingIDs + 1
    pingobj.id = UsedPingIDs
    pingobj.pinging = true
    pingobj.timer = pingtime or PING_TIME
    pingobj.fadetime = fadetime or FADE_TIME
    pingobj.fadeOut = nil
    pingobj.fadeOutTimer = nil
    if (vishere ~= false) then        -- Done this way so if nil is given, it defaults to true.
      vishere = true
    end
    if (viszone ~= false) then
      viszone = true
    end
    if (viscon ~= false) then
      viscon = true
    end
    if (vismultcon ~= false) then
      vismultcon = true
    end

    -- Prevent an icon update from MoveZoneIcon or AddZoneIcon, letting it trigger from SetZoneIconVisByCat.
    Astronomer.BlockNextUpdate = true

    if (res > 0) then                    -- If pingobj is not a new widget.
      pingobj.Astro.Visible = true
      Astronomer.MoveZoneIcon(pingobj, C, Z, x, y)
    else
      Astronomer.AddZoneIcon(pingobj, C, Z, x, y)
    end
    if (noupdate) then
      Astronomer.BlockNextUpdate = true
    end
    Astronomer.SetZoneIconVisByCat(pingobj, vishere, viszone, viscon, vismultcon)
    if (pingobj.timer ~= ASTRONOMER_PING_INDEFINITE) then
      Astronomer.WorldPingTimerFrame:Show()                   -- Allow ping countdown
    end
    return pingobj;
  end

  -- Find out how many ping objects this icon is attached to.
  local function numAttached(icon)
    local pingobj;
    local num = 0;
    for i=1,NumWorldPingObj do
      pingobj = getglobal("Astronomer_WorldMapPing"..i)
      if (pingobj.Astro.AttachedIcon == icon) then
        num = num + 1;
      end
    end
    return num;
  end
  
  -- Find pingobj using pingID.
  local function getpingobj(pingID)
    local pingobj
    for i=1,NumWorldPingObj do
      pingobj = getglobal("Astronomer_WorldMapPing"..i)
      if (pingobj.id == pingID) then
        return pingobj;
      end
    end
    return nil;
  end


-- GLOBAL FUNCTIONS
----------------------------------------------------------------------------------------------------------------

  function Astronomer.StopWorldPing(pingobj)
    if (type(pingobj) == "number") then
      pingobj = getpingobj(pingobj)
      if (not pingobj) then  return;  end
    elseif (type(pingobj) ~= "table") then
      errormsg("StopWorldPing(): Invalid argument type given. Expected table; got "..type(pingobj)..".")
      error("StopWorldPing(): Invalid argument type given. Expected table; got "..type(pingobj)..".")
    end
    debugprint("StopWorldPing() called for "..pingobj:GetName()..".")
    local callfunc = pingobj.OnStopCall
    local callfunc_icon = pingobj.Astro.AttachedIcon
    local callfunc_arg = pingobj.OnStopCall_arg

    remfromactivelist(pingobj)
    pingobj.id = nil
    pingobj.pinging = nil
    pingobj.Astro.DoNotAutoUpdate = nil
    pingobj.Astro.offsetX = nil
    pingobj.Astro.offsetY = nil
    pingobj.Astro.scalehere = nil
    pingobj.Astro.scalezone = nil
    pingobj.Astro.scalecon = nil
    pingobj.Astro.scalemultcon = nil
    pingobj.OnStopCall = nil
    pingobj.OnStopCall_arg = nil
    Astronomer.HideZoneIcon(pingobj)

    -- Unattach icon
    if (pingobj.Astro.AttachedIcon) then
      if (numAttached(pingobj.Astro.AttachedIcon) <= 1) then    -- If this is the last ping obj attached to the
        pingobj.Astro.AttachedIcon.Astro.WorldPingInform = nil  -- icon, it should no longer trigger our function.
        debugprint("Icon no longer informing ping objects of updates.")
      end
      pingobj.Astro.AttachedIcon = nil
    end

    -- Call "on stop" function if present
    if (type(callfunc) == "function") then
      callfunc(pingobj, callfunc_icon, callfunc_arg);
    end
  end

  function Astronomer.AttachedIconUpdated(icon, reason, cat)
    -- Function call for every ping object attached to this icon:
    local pingobj
    for i=1,NumWorldPingObj do
      pingobj = getglobal("Astronomer_WorldMapPing"..i)
      if (pingobj.Astro.AttachedIcon == icon) then
        --debugprint("Handling for Astronomer_WorldMapPing"..i..".")
        if (reason == "rem") then
          Astronomer.StopWorldPing(pingobj)
        else
          IconAttachedPingUpdate(pingobj, icon, cat)
        end
      end
    end
  end

  function Astronomer.PingWorldAt(C, Z, x, y, pingtime, fadetime, vishere, viszone, viscon, vismultcon, scale, level, takeover)
    local pingobj
    pingobj = pingworldCZ(false, C, Z, x, y, pingtime, fadetime, vishere, viszone, viscon, vismultcon, scale, level, takeover);
    if (pingobj) then
      return pingobj.id, pingobj;
    end
    return nil;
  end

  function Astronomer.PingZoneIcon(icon, offsetX, offsetY, pingtime, fadetime, vishere, viszone, viscon, vismultcon, scale, level, takeover)
    if (type(icon) ~= "table") then
      errormsg("PingZoneIcon(): Invalid argument type given. Expected table; got "..type(icon)..".")
      error("PingZoneIcon(): Invalid argument type given. Expected table; got "..type(icon)..".")
      return nil;
    elseif (not Astronomer.IsIconPlaced(icon)) then
      errormsg("PingZoneIcon(): Given icon not placed on any maps.")
      error("PingZoneIcon(): Given icon not placed on any maps.")
      return nil;
    end
    local pingobj = pingworldCZ(true, icon.Astro.C, icon.Astro.Z, icon.Astro.x, icon.Astro.y, pingtime, fadetime,
                                vishere, viszone, viscon, vismultcon, scale, level, takeover)
    if (not pingobj) then
      return nil;
    end
    pingobj.Astro.DoNotAutoUpdate = true
    pingobj.Astro.AttachedIcon = icon
    icon.Astro.WorldPingInform = Astronomer.AttachedIconUpdated;
    pingobj.Astro.offsetX = offsetX
    pingobj.Astro.offsetY = offsetY
    -- Update attached icon which will ensure its visibility is properly set and trigger AttachedIconUpdated:
    Astronomer.ZoneIcons_Update(icon)
    return pingobj.id, pingobj;
  end

  function Astronomer.SetPingObjScaleByCat(pingobj, s_here, s_zone, s_con, s_multcon)
    if (type(pingobj) == "number") then
      pingobj = getpingobj(pingobj)
      if (not pingobj) then  return;  end
    end
    Astronomer.SetZoneIconScaleByCat(pingobj, s_here, s_zone, s_con, s_multcon)
    if (pingobj.Astro.AttachedIcon) then
      Astronomer.ZoneIcons_Update(pingobj.Astro.AttachedIcon)
    end
  end

  function Astronomer.SetWorldPingTime(pingobj, pingtime)
    if (type(pingobj) == "number") then
      pingobj = getpingobj(pingobj)
      if (not pingobj) then  return;  end
    end
    if (pingobj and pingobj.pinging) then
      pingobj.timer = pingtime or PING_TIME
      if (pingobj.timer ~= ASTRONOMER_PING_INDEFINITE) then
        if (pingobj.timer > 0) then
          pingobj.fadeOut = false;
          pingobj:SetAlpha(255)
        else
          pingobj.fadeOut = true;
        end
        Astronomer.WorldPingTimerFrame:Show()   -- Allow ping countdown
      end
      return true;
    end
    return false;
  end

  function Astronomer.GetRemainingPingTime(pingobj)
    if (type(pingobj) == "number") then
      pingobj = getpingobj(pingobj)
      if (not pingobj) then  return 0;  end
    end
    if (type(pingobj) ~= "table") then
      errormsg("GetRemainingPingTime(): Invalid argument type given (arg1). Expected table; got "..type(pingobj)..".")
      error("GetRemainingPingTime(): Invalid argument type given (arg1). Expected table; got "..type(pingobj)..".")
      return nil;
    end
    if (not pingobj.pinging) then  return 0;  end
    return pingobj.timer;
  end

  function Astronomer.OnPingStop(pingobj, callfunc, arg3)
    if (type(pingobj) == "number") then
      pingobj = getpingobj(pingobj)
      if (not pingobj) then  return;  end
    end
    if (type(pingobj) ~= "table") then
      errormsg("OnPingStop(): Invalid argument type given (arg1). Expected table; got "..type(pingobj)..".")
      error("OnPingStop(): Invalid argument type given (arg1). Expected table; got "..type(pingobj)..".")
      return nil;
    elseif (type(callfunc) ~= "function") then
      errormsg("OnPingStop(): Invalid argument type given (arg2). Expected function; got "..type(callfunc)..".")
      error("OnPingStop(): Invalid argument type given (arg2). Expected function; got "..type(callfunc)..".")
      return nil;
    end
    pingobj.OnStopCall = callfunc
    pingobj.OnStopCall_arg = arg3
  end

  function Astronomer.WorldPingTimer(frame, elapsed, continue)
    continue = continue or 1
    local numinf = 0
    for k, pingobj in ipairs(ActiveWorldPings) do
      if ( pingobj.timer == ASTRONOMER_PING_INDEFINITE ) then   -- Skip indefinitely-pinging objects
        numinf = numinf + 1
      elseif ( k >= continue ) then               -- Skip what was handled before a StopWorldPing (see below).
        -- If ping has a timer greater than 0 count it down, otherwise fade it out
        if ( pingobj.timer > 0 ) then
          pingobj.timer = pingobj.timer - elapsed;
          if ( pingobj.timer <= 0 ) then
            pingobj.fadeOut = true;
            pingobj.fadeOutTimer = pingobj.fadetime + pingobj.timer   -- Apply however far below 0 timer went to
          end                                                         -- the fadeout timer.
        elseif ( pingobj.fadeOut ) then
          pingobj.fadeOutTimer = pingobj.fadeOutTimer - elapsed;
        end
        if ( pingobj.fadeOut ) then
          if ( pingobj.fadeOutTimer > 0 ) then
            pingobj:SetAlpha(255 * (pingobj.fadeOutTimer/pingobj.fadetime))
          else
            Astronomer.StopWorldPing(pingobj);  -- Doing this alters ActiveWorldPings, which messes with this
                    -- for loop, so we'll break out of it now, continuing where we left off.
            return Astronomer.WorldPingTimer(frame, elapsed, k)
          end
        end
      end
    end

    if ( #(ActiveWorldPings) - numinf < 1 ) then
      --debugprint("No more pings to time.",2)
      Astronomer.WorldPingTimerFrame:Hide()     -- Stop ping countdown if no active pings are left
      --debugprint("# active: "..#(ActiveWorldPings)..". numinf="..numinf,3)
    end
  end


-- FINAL INITIALIZATION
----------------------------------------------------------------------------------------------------------------

  if (not Astronomer.WorldPingTimerFrame) then
    Astronomer.WorldPingTimerFrame = CreateFrame("Frame")
  end

  Astronomer.WorldPingTimerFrame:Hide()
  Astronomer.WorldPingTimerFrame:SetScript("OnUpdate", Astronomer.WorldPingTimer)


end
