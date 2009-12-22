
Astronomer v0.33
========================================

Author: Tuhljin

Astronomer is an addon library that builds upon the Astrolabe library by Esamynn. It provides methods for addon
authors to easily carry out certain tasks involving the world map. Highlights include:

- Functions that place icons on the world map which are automatically updated: adjusting their positions,
  visibility, and optionally their size and translucency intelligently.

- Fire-and-forget functions that ping world map locations, similar to how the minimap is pinged.

To embed Astronomer in your addon:
  - Put the Astronomer folder inside your Interface\Addons\<YourAddonName>\ folder.
  - Add Astronomer\Astronomer.xml to the list of files to load in your toc file or load it in your xml before
    your localization files.
  - Do not include Astronomer\Astrolabe\Load.xml in your TOC file. This is handled by Astronomer.xml.

All credit for the Astrolabe library goes to its author. See Astrolabe.lua for more information.


I. GENERAL USAGE AND WORLD MAP ICONS
----------------------------------------

FUNCTIONS SUGGESTED FOR USE IN ADDONS:

The icon argument passed to one of these functions can be any compatible widget, such as those returned by
the Astronomer.NewZoneIcon function. Compatible widgets are any that can be used with Astrolabe. Note that
Astronomer will add the variable <YourIconWidget>.Astro as a table, if it is not there, and might change some
of its values if it is. See the section "USEFUL VARIABLES ADDED TO THE ICON," below.

The continent and zone arguments and return values use the same numbering system that Blizzard functions such
as GetCurrentMapContinent() and GetCurrentMapZone() use. Continent numbers are the same for all localizations
of World of Warcraft, but the same is not true of zone numbers. Additionally, if a new zone is released in
a content patch, zone numbers may change, so hard-coded zone numbers are unreliable. Instead, get a zone's
number using a function like GetCurrentMapZone() or one of the functions described in the following section.


*** Getting a Zone's Number: ***

continent, zone = Astronomer.ZoneCZ(zoneName[, continent])
  Where zoneName is a string which is the name of the zone. The continent argument is optional; if used,
  only zones in that continent will be checked. Returns the zone's continent and zone numbers, or nil
  if the zoneName wasn't found.

zone = Astronomer.ZoneID(zoneName[, continent])
  As Astronomer.ZoneCZ, except that it returns only the zone number (or nil).


*** Creating, Placing, and Removing Icons: ***

iconWidget, boolean = Astronomer.NewZoneIcon(texture, width[, height[, continent, zone, x, y[, hereonly]]])
  Create a new icon for use with Astronomer and return it. If height is nil or zero, it will match the width
  value. Include continent, zone, x, and y to call AddZoneIcon (see below) using the new icon immediately
  after its creation. In this case, NewZoneIcon will also return whatever AddZoneIcon returns. The optional
  hereonly argument corresponds to AddZoneIcon's hereonly argument.

boolean = Astronomer.AddZoneIcon(icon, continent, zone, x, y[, hereonly])
  Add a specified icon to the world map and display it on the map specified by continent and zone at the
  coordinates (x, y). Returns true if successful, false otherwise. If the optional argument hereonly is true,
  the icon is set to display only on the given zone map. (See Astronomer.SetZoneIconVisByCat, below.)

boolean = Astronomer.RemZoneIcon(icon)
  Remove a previously-placed icon from the map. Returns true if any pointers to the icon were removed.

boolean = Astronomer.MoveZoneIcon(icon, continent, zone, x, y)
  Move the specified icon to the position specified by the other arguments. Returns true if successful. If
  continent is nil, the icon's current continent is used. If zone is nil, the icon's current zone is used,
  but only if continent was also nil.

booleanValue = Astronomer.IsIconPlaced(icon)
  Returns true if the given icon has been placed on a map by Astronomer.


*** Icon Visibility: ***

These functions have to do with whether an icon should be visible when the world map is open to an
appropriate continent and zone, not whether they are currently visible on the screen.

Astronomer.SetZoneIconVisByCat(icon, vishere, viszone, viscon, vismultcon)
  Use this function to set whether the icon should be displayed on certain maps. The arguments after the
  icon should be booleans; if true, the icon is displayed on the indicated map(s). If one of them is nil,
  its current value is not changed. Each corresponds to a different map category:
    vishere       The map on which the icon was placed. Takes priority should it conflict with other args.
    viszone       Zone-level maps.
    viscon        Continent-level maps.
    vismultcon    Multi-continent-level maps. (Currently, only the Azeroth map is in this category.)
  The default value (when an icon is first placed by Astronomer.AddZoneIcon) for all of these is true.

  Note that displaying icons on the Cosmic map is unsupported by Astrolabe, thus any icons placed on a lower
  level (from multi-continent-level to zone-level) will not display there. At this time, icons placed
  directly on the Cosmic map will also not display; support for this may be considered for inclusion in a
  future version of Astronomer.

Astronomer.HideZoneIcon(icon)  -- or --  Astronomer.ShowZoneIcon(icon)
  Hide or show the icon specified. Must be an icon previously added to the map via Astronomer.AddZoneIcon.
  A hidden icon will not display on any maps, regardless of other visibility settings (such as those set
  by Astronomer.SetZoneIconVisByCat).


*** Other Adjustments by Displayed Map's Category: ***

SetZoneIconVisByCat, detailed above, changes the icon's visibility based on the displayed map's "category."
Here are some other functions that operate in the same vein. Note that they correspond to some of the normal
widget functions (e.g. <WidgetName>:SetAlpha), so if your addon uses both one of those functions and the
corresponding one below, Astronomer may "override" their settings when the map changes. (If you only use one
or the other, this shouldn't be an issue.) If a category's argument is nil, its current setting isn't changed.

Astronomer.SetZoneIconAlphaByCat(icon, ahere, azone, acon, amultcon)
  Adjust the icon's alpha setting (transparency). Arguments #2-5 should be a number between 0 and 1: e.g.,
  0.75 means the icon will be translucent, but mostly visible.

Astronomer.SetZoneIconSizeByCat(icon, i_here, i_zone, i_con, i_multcon)  -- or --
Astronomer.SetZoneIconWidthByCat(icon, i_here, i_zone, i_con, i_multcon)  -- and --
Astronomer.SetZoneIconHeightByCat(icon, i_here, i_zone, i_con, i_multcon)
  Adjust the icon's width and/or height. (The first function applies given values to both width and height.)

Astronomer.SetZoneIconScaleByCat(icon, s_here, s_zone, s_con, s_multcon)
  For use with Models only: It won't work if the given icon doesn't support the icon:SetModelScale function.
  Note that icons created by Astronomer.NewZoneIcon are not Models.


*** Miscellaneous: ***

Astronomer.GetZoneName(continent, zone)
  Return the name (a string) of the indicated zone, or nil if it was not found.

Astronomer.SuspendMapHandling()  -- and --
Astronomer.ResumeMapHandling([bool])  -- or --  Astronomer.ResumeMapHandling(icon1[, ...])
  Suspend or resume automatic handling of icon display on the world map. It may be useful to suspend handling
  when your addon is about to make a large number of changes to icons and you don't want to make useless
  repeated updates to their display. ResumeMapHandling can take any number of arguments: zero, one, or more.
  If the first argument is a boolean and it is true, or if no argument is given, the map handler is called
  immediately to update icons displayed in the region. Alternatively, if the first argument is an icon, then
  it and any other given icons (arguments #2 and beyond) are updated when the function is called. This is far
  more efficient than calling the handler. (Note that it can actually be less efficient to suspend and then
  resume map handling if you aren't making very many changes than simply making changes without suspending it
  at all if you don't use the icons in question as arguments.)


USEFUL VARIABLES ADDED TO THE ICON:

As mentioned above, Astronomer adds the table <YourIconWidget>.Astro to your icon when it is first placed on
the map. Your addon can access any of the variables it contains, but it is recommended that you use the
functions provided instead of directly changing their values, as doing so could interfere with Astronomer's
operation. However, it is safe for your addon to check these variables in order to react to their values. To
check visibility, for instance, you could use "<YourIconWidget>.Astro.Visible" (without quotes). Some useful
variables are listed below.

  C             Integer. The continent where the icon is placed.
  Z             Integer. The zone where the icon is placed.
  x             Integer. The x coordinate of the location in the zone where the icon is placed.
  y             Integer. The y coordinate of the location in the zone where the icon is placed.
  Visible       Boolean. True if the icon should be visible when an appropriate map is displayed.
  vishere, viszone, viscon, vismultcon
                Boolean. See the Astronomer.SetZoneIconVisByCat description, above, for their purpose.
  alphahere, alphazone, alphacon, alphamultcon
                Number. See the Astronomer.SetZoneIconAlphaByCat description, above, for their purpose.
  width_here, height_here, width_zone, height_zone, width_con, height_con, width_multcon, height_multcon
                Number. See the description of Astronomer.SetZoneIconSizeByCat and related functions, above.

(It may be safe to alter some of these variables with your addon if you are certain of what you are doing, of
course, but changing things at the wrong time could mean your changes are temporarily displayed improperly and
it is more future-safe to use the provided functions since new versions of Astronomer will try to be backward-
compatible with function use but may not react the same way to direct variable changes.)

One exception to the "do not alter Astro table variables with your addon" rule is the variable DoNotAutoUpdate.
It defaults to nil and is not normally set to anything else by Astronomer. If you set it to true, however, this
prevents that icon from automatically being updated when one of its properties or the map changes. Updates
will only occur if you explicitly call for them using Astronomer.ZoneIcons_Update(icon) or pass the icon as an
argument to ResumeMapHandling.

Another exception to the rule is UpdateCall. This variable will be nil when an icon is added to the map and
will not otherwise be changed by Astronomer to anything else (except to nil when the icon is removed), but if
you set it to a function, that function will be called whenever Astronomer handles updates for the icon (which
occurs when the WORLD_MAP_UPDATE event occurs, if the current map isn't the same as the previous one, and also
whenever one of the above functions that changes a property of the icon is called). The first argument passed
to the function is the icon in question. The second argument passed is a string giving the reason this call was
made: "update" (only given if the icon is visible on this map), "hide" (given when the icon is hidden), or
"rem" (meaning the icon was removed from the map, not merely hidden). The remaining arguments are nil unless
the reason is "update" or, in some but not all cases, "hide"; they are, in order:

  cat           The map category applicable to the icon at the time ("here", "zone", "con", or "multcon").
  continent     The continent number of the current map. (Not necessarily the map the icon is placed on.)
  zone          The zone number of the current map.

IMPORTANT: Be sure not to create an infinite loop by putting anything in your function that will in turn
cause UpdateCall to be called again! This includes any Astronomer functions that change an icon's properties
as well as anything that might trigger another WORLD_MAP_UPDATE event using a different continent/zone as its
map. (Careful: That event occurs more frequently than one might at first think it does and with current map
values set to things one might not expect.) If you really need to use such functions, judicious use of
Astronomer.SuspendMapHandling() and Astronomer.ResumeMapHandling(false) can prevent an infinite loop.


II. WORLD MAP PINGING
----------------------------------------

Astronomer includes functions that allow addons to "ping" the world map in much the same way that the minimap
can be pinged. You indicate the place to be pinged using the same conventions that tell Astronomer where to
place a world map icon: Continent and zone numbers coupled with X and Y coordinates. Alternatively, you can
specify an existing world map icon to which Astronomer will "attach" the ping.

Two arguments used here could use some explanation. First, "pingID" refers to the "ping ID" of an individual
world-map-ping occurrence. Every time Astronomer.PingWorldAt or Astronomer.PingZoneIcon is called, a unique
ping ID is returned. Second, "pingobj" refers to a "ping object," which is a widget created by Astronomer and
also returned by the Astronomer.PingWorldAt and Astronomer.PingZoneIcon functions. Ping objects are
automatically reused by Astronomer: When one object stops pinging the map, it becomes available for use in
future ping requests. Thus, it is usually safer to use pingID instead of a pingobj when calling functions like
Astronomer.StopWorldPing to ensure your addon doesn't interfere with another's use of a ping object.

An argument listed as "pingID/pingobj" means the function can take either a ping object or a ping ID. If the
ping ID is no longer valid - that is, the object that was associated with it is either no longer visible or has
been given a new ID - then the function does nothing; no error is triggered.

pingID, pingobj = Astronomer.PingWorldAt(continent, zone, x, y[, pingtime, fadetime, vishere, viszone, viscon,
                                         vismultcon, scale, level, takeover])
  Pings the world map at the location indicated by continent, zone, x, and y. Other arguments are optional.
  (If you want to omit one but give another listed after it, pass the one you are skipping as nil.)
    pingtime      Number. How long, in seconds, the ping should last. It is valid to use non-integers, such as
                  0.5 for half a second. Defaults to the same time used by standard minimap pings. Instead
                  of a number, you can use the constant ASTRONOMER_PING_INDEFINITE to make the ping last
                  until something (other than simply time) causes it to stop.
    fadetime      Number. After pingtime has elapsed, the ping object fades over the time given before stopping
                  entirely.
    vishere, viszone, viscon, vismultcon
                  Boolean. Just as world map icons are visible depending on the current map's category, so
                  are ping objects' visibility dependant on the current map. See the description of the world
                  map function Astronomer.SetZoneIconVisByCat, above. All of these default to true.
    scale         Number. The scale to use for the ping. Defaults to that used by the minimap (0.4). This
                  essentially takes the place of setting the size for the ping object, as that doesn't work
                  as well for this type of widget. Note that going much beyond 0.7 can cause the ping to
                  display improperly.
    level         Integer. The frame level used for the ping object, used to put the ping in front of or behind
                  other objects. Defaults to 3 if omitted.
    takeover      Integer. For most addons' purposes, it's best to omit this argument. Defaults to 1, which
                  lets Astronomer take a currently-existing ping object that isn't set up to ping indefinitely
                  and use that instead of creating a new ping object when the maximum number of such objects
                  are already being used. Set to 0 to not take ping objects over.

pingID, pingobj = Astronomer.PingZoneIcon(icon[, offsetX, offsetY, pingtime, fadetime, vishere, viszone,
                                          viscon, vismultcon, scale, level, takeover])
  Pings the world map at a location attached to the given world map icon. If that icon moves, the ping location
  moves. If the icon is not visible, the ping will not be, regardless of its own settings (vishere, viszone,
  etc.), though it isn't necessarily true that whenever the icon is visible, the ping will also be. If the
  icon is removed, the ping will stop. This is otherwise identical to Astronomer.PingWorldAt, and its arguments
  are the same except for the addition of offsetX and offsetY:
    offsetX, offsetY
      Number. These arguments change where the ping is centered in relation to the icon. They default to 0.5
      and 0.5, which means 50% of the width and 50% of the height of the icon, putting the ping in its center.
      (Some icons' visible areas take up only a portion of their total size, meaning a ping at 0.5 and 0.5 may
      appear off-center.) Tip: If you want the ping to center on, e.g., pixel 11 out of the icon's total 32
      pixels in width, 11 divided by 32 (11/32) gives you the number you'd want to use for offsetX. (You could
      even simply use 11/32 as the actual argument; the math will be done for you and it will remind you
      exactly what the number there means.)

Astronomer.StopWorldPing(pingID/pingobj)
  Stop the given ping object's pinging.

Astronomer.SetWorldPingTime(pingID/pingobj[, pingtime])
  Dynamically change the pingtime of the given ping object. See Astronomer.PingWorldAt, above. Use a negative
  number to make the object begin fading out if it isn't already.

Astronomer.SetPingObjScaleByCat(pingID/pingobj, s_here, s_zone, s_con, s_multcon)
  The ping object equivalent of Astronomer.SetZoneIconSizeByCat, except that it sets scale instead of width
  and height. See the description of the scale argument in Astronomer.PingWorldAt, above.

Astronomer.OnPingStop(pingID/pingobj, callfunc[, arg3])
  Set a function (callfunc) to be called When the object stops pinging. The function is called with the
  relevant ping object as its first argument. If it was attached to an icon (through Astronomer.PingZoneIcon),
  the second argument will be that icon, or nil otherwise. The third argument will be whatever you set as arg3
  when you call Astronomer.OnPingStop.

Astronomer.GetRemainingPingTime(pingID/pingobj)
  Return the number of seconds remaining before the ping object stops pinging. Returns 0 if the object is not
  pinging or the pingID is no longer in use.


Change log
==========

v0.33
- New version of Astrolabe library included for WoW 3.2.

v0.32
- New version of Astrolabe library included for WoW 3.1.

v0.31
- New version of Astrolabe library included.

v0.30
- New version of Astrolabe library included for WoW 3.0.
- Now handles the continent of Northrend.

v0.21
- The default frame level for world map ping objects is now 3 (up from 1). This resolves a compatibility issue
  with the addon Cartographer.

v0.20
- Event handler updated to new standards used in WoW 3.0.

v0.19
- AddZoneIcon and NewZoneIcon's hereonly argument now properly affects multi-continent Visibility.

v0.18
- New icon visibility now defaults to visible in all categories.

v0.17
- Code cleanup.

v0.15.1
- Improved Astrolabe embedding method to prevent (harmless) error message.

v0.15
- First public release.
