-- Stormbar: shared namespace, settings, FlareUI style and moving (Edit Mode / unlock).
local ADDON, ns = ...
ns.name = ADDON

ns.isSecret = issecretvalue or function() return false end
function ns.Readable(v) return v ~= nil and not ns.isSecret(v) end
function ns.Print(...) print("|cff66bbffStormbar:|r", ...) end

ns.DEFAULTS = {
  locked        = true,
  editMode      = true,  -- movable while Blizzard's Edit Mode is open
  snapGrid      = true,  -- in Edit Mode, drop onto Blizzard's grid (when its Snap is on)
  flareStyle    = true,  -- FlareUI look when FlareUI is installed
  hideBlizzCast = true,  -- hide Blizzard's cast bar (Stormbar replaces it)
  hideFlareCast = true,  -- hide FlareUI's Player Cast Bar (it replaces Blizzard's when FlareUI is on)
  hideFlareSwing = true, -- hide FlareUI's swing bar for the weapon Stormbar tracks
  swingWeapon   = "main", -- "main" | "off" | "ranged" (wands, guns, bows, thrown)
  scale         = 1.0,
  castSwing     = { width = 260, height = 16, showIcon = true, showTime = true, hideIdle = false },
  pos           = {},
}

-- settings from the old, bigger Stormbar (action bars, weapons, totems) that no longer exist
local OBSOLETE = { "buttonSize", "spacing", "sideGap", "hideBlizzBars", "hideBlizzTotem", "sources",
  "showLeft", "showRight", "weapons", "totems", "pieceScale" }

local function Copy(v)
  if type(v) ~= "table" then return v end
  local t = {}
  for k, x in pairs(v) do t[k] = Copy(x) end
  return t
end
local function Merge(dst, src)
  for k, v in pairs(src) do
    if dst[k] == nil then dst[k] = Copy(v)
    elseif type(v) == "table" and type(dst[k]) == "table" and k ~= "pos" then Merge(dst[k], v) end
  end
end

function ns.LoadDB()
  StormbarDB = StormbarDB or {}
  for _, k in ipairs(OBSOLETE) do StormbarDB[k] = nil end
  if StormbarDB.pos then -- only the bar's own position is kept
    for k in pairs(StormbarDB.pos) do if k ~= "castSwing" then StormbarDB.pos[k] = nil end end
  end
  local cs = StormbarDB.castSwing
  if cs then
    cs.show = nil
    if cs.width == 0 then cs.width = 260 end -- "match the centre bar" no longer exists
  end
  Merge(StormbarDB, ns.DEFAULTS)
  ns.db = StormbarDB
end

function ns.ResetDB()
  wipe(StormbarDB)
  ns.LoadDB()
end

---------------------------------------------------------------------------
-- Combat-safe changes: secure frames can't be moved, shown or reconfigured in combat.
---------------------------------------------------------------------------
local queued = {}
function ns.OutOfCombat(key, fn)
  if InCombatLockdown() then queued[key] = fn; return false end
  fn(); return true
end
local cev = CreateFrame("Frame")
cev:RegisterEvent("PLAYER_REGEN_ENABLED")
cev:SetScript("OnEvent", function()
  local list = queued; queued = {}
  for _, fn in pairs(list) do pcall(fn) end
end)

---------------------------------------------------------------------------
-- FlareUI style (read from your installed FlareUI; nothing of FlareUI's is copied)
---------------------------------------------------------------------------
ns.FLARE_BRONZE = { 0.65, 0.49, 0.27 }       -- FlareUI's frame-border bronze (#A67D45)
ns.FLARE_SWING  = { 0.86, 0.65, 0.39 }       -- FlareUI's main-hand swing colour
local function LSM() return LibStub and LibStub("LibSharedMedia-3.0", true) end

function ns.FlareLoaded()
  return (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("FlareUI"))
    or (IsAddOnLoaded and IsAddOnLoaded("FlareUI")) or false
end
function ns.UsingFlare() return ns.db and ns.db.flareStyle and ns.FlareLoaded() end

function ns.FlareMedia(kind, name, fallback)
  local lsm = LSM()
  return (lsm and lsm:Fetch(kind, name, true)) or fallback
end

-- A border around `region` (an icon or a bar): FlareUI Frames in bronze, or a plain dark edge.
function ns.Border(owner, region, thin)
  local b = owner.SB_Border
  if not b then
    b = CreateFrame("Frame", nil, owner, "BackdropTemplate")
    owner.SB_Border = b
  end
  -- How far the border frame sits outside `region`. FlareUI draws its border line about 4 px in
  -- from the border frame's edge and keeps its bars 4 px inside (its INSET), so the fill and the
  -- dark background stop at the line instead of poking past it.
  local out
  b:SetFrameLevel(owner:GetFrameLevel() + 2)
  if ns.UsingFlare() then
    local file = ns.FlareMedia("border", thin and "FlareUI Thin" or "FlareUI Frames",
      "Interface/AddOns/FlareUI/Media/Borders/FlareUI-Frames.tga")
    local edge = (thin and file:find("Thin")) and 8 or 16
    b:SetBackdrop({ edgeFile = file, edgeSize = edge })
    local c = ns.FLARE_BRONZE
    b:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    out = edge == 8 and 4 or 3
  else
    b:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    b:SetBackdropBorderColor(0, 0, 0, 1)
    out = 1 -- a plain 1 px line just outside
  end
  b:ClearAllPoints()
  b:SetPoint("TOPLEFT", region, "TOPLEFT", -out, out)
  b:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT", out, -out)
  b:Show()
  return b, out
end

function ns.BarTexture()
  if ns.UsingFlare() then
    return ns.FlareMedia("statusbar", "FlareUI Forever", "Interface\\TargetingFrame\\UI-StatusBar")
  end
  return "Interface\\TargetingFrame\\UI-StatusBar"
end

---------------------------------------------------------------------------
-- Movers: every top-level piece can be dragged while unlocked; positions are saved.
---------------------------------------------------------------------------
ns.movers = {}

-- Snap `frame` onto Blizzard's Edit Mode grid: the grid's lines run from the screen centre every
-- `gridSpacing`. On each axis the frame's nearest edge (or its centre) moves onto the nearest line.
-- Only while Edit Mode is open with its grid shown and Snap enabled.
local function SnapToGrid(frame)
  local emf = _G.EditModeManagerFrame
  local grid = emf and emf.Grid
  if not (ns.inEditMode and ns.db.snapGrid and grid and grid:IsShown()) then return end
  if emf.IsSnapEnabled and not emf:IsSnapEnabled() then return end
  local spacing = grid.gridSpacing
  if not spacing or spacing <= 0 then return end

  -- work in screen pixels so different scales line up
  local gs, fs = grid:GetEffectiveScale(), frame:GetEffectiveScale()
  local gcx, gcy = grid:GetCenter()
  local l, r, t, b = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
  if not (gcx and l and r and t and b) then return end
  gcx, gcy, spacing = gcx * gs, gcy * gs, spacing * gs
  l, r, t, b = l * fs, r * fs, t * fs, b * fs

  local function shift(origin, ...)
    local best
    for i = 1, select("#", ...) do
      local v = select(i, ...)
      local d = (origin + math.floor((v - origin) / spacing + 0.5) * spacing) - v
      if not best or math.abs(d) < math.abs(best) then best = d end
    end
    return best
  end
  local dx = shift(gcx, l, (l + r) / 2, r)
  local dy = shift(gcy, t, (t + b) / 2, b)

  frame:ClearAllPoints()
  frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (l + dx) / fs, (t + dy) / fs)
end
ns.SnapToGrid = SnapToGrid

function ns.RegisterMover(key, frame, label, default)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  if frame.SetDontSavePosition then frame:SetDontSavePosition(true) end
  local o = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  o:SetAllPoints()
  o:SetFrameLevel(frame:GetFrameLevel() + 20)
  o:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
  o:SetBackdropColor(0.2, 0.5, 1, 0.25)
  o:SetBackdropBorderColor(0.4, 0.7, 1, 0.9)
  o.text = o:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  o.text:SetPoint("CENTER"); o.text:SetText(label)
  o:EnableMouse(true)
  o:RegisterForDrag("LeftButton")
  o:SetScript("OnDragStart", function()
    o.dragged = true
    if not InCombatLockdown() then frame:StartMoving() end
  end)
  o:SetScript("OnMouseDown", function() o.dragged = false end)
  -- a click (not a drag) selects the piece and opens its settings, like Blizzard's Edit Mode
  o:SetScript("OnMouseUp", function(_, mouse)
    if not o.dragged and mouse == "LeftButton" and ns.OpenPieceDialog then ns.OpenPieceDialog(key) end
  end)
  o:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    if frame.SetUserPlaced then pcall(frame.SetUserPlaced, frame, false) end
    SnapToGrid(frame)
    local p, _, rp, x, y = frame:GetPoint()
    ns.db.pos[key] = { p, rp, x, y }
    if ns.OpenPieceDialog then ns.OpenPieceDialog(key) end -- dragging also selects it
  end)
  o:Hide()
  ns.movers[key] = { frame = frame, overlay = o, default = default }
end

function ns.PlaceMover(key)
  local m = ns.movers[key]
  if not m then return end
  ns.OutOfCombat("place" .. key, function()
    local p = ns.db.pos[key] or m.default
    m.frame:ClearAllPoints()
    m.frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
  end)
end

-- Movable when unlocked, or while Blizzard's Edit Mode is open (if that option is on).
ns.inEditMode = false
function ns.ApplyLock()
  local editing = ns.db.editMode and ns.inEditMode
  local movable = not ns.db.locked or editing
  if not movable and ns.ClosePieceDialog then ns.ClosePieceDialog() end
  -- arrow-key nudging: only while a piece is selected
  if not InCombatLockdown() then ns.nudgeKeys:SetShown(movable and ns.selected ~= nil) end
  for key, m in pairs(ns.movers) do
    local o = m.overlay
    o:SetShown(movable)
    -- selected: Blizzard's Edit Mode yellow; otherwise its blue (lighter when just unlocked)
    if movable and ns.selected == key then
      o:SetBackdropColor(1, 0.82, 0, 0.25); o:SetBackdropBorderColor(1, 0.82, 0, 1)
    elseif editing then
      o:SetBackdropColor(0.1, 0.45, 1, 0.35); o:SetBackdropBorderColor(0.3, 0.75, 1, 1)
    else
      o:SetBackdropColor(0.2, 0.5, 1, 0.25); o:SetBackdropBorderColor(0.4, 0.7, 1, 0.9)
    end
  end
end

local function SetEditMode(on)
  ns.inEditMode = on
  if ns.db then ns.ApplyLock() end
end
function ns.HookEditMode()
  if EventRegistry and EventRegistry.RegisterCallback then
    EventRegistry:RegisterCallback("EditMode.Enter", function() SetEditMode(true) end, ns)
    EventRegistry:RegisterCallback("EditMode.Exit", function() SetEditMode(false) end, ns)
  end
  -- fallback: watch the Edit Mode window itself
  local emf = _G.EditModeManagerFrame
  if emf and emf.HookScript then
    emf:HookScript("OnShow", function() SetEditMode(true) end)
    emf:HookScript("OnHide", function() SetEditMode(false) end)
  end
end

-- Arrow keys nudge the selected piece (1 px, Shift: 10 px), like Blizzard's Edit Mode.
-- Only while a piece is selected; other keys pass through to the game as normal.
function ns.Nudge(key, dx, dy)
  local m = ns.movers[key]
  if not m or InCombatLockdown() then return end
  local p, _, rp, x, y = m.frame:GetPoint()
  if not p then return end
  m.frame:ClearAllPoints()
  m.frame:SetPoint(p, UIParent, rp, (x or 0) + dx, (y or 0) + dy)
  ns.db.pos[key] = { p, rp, (x or 0) + dx, (y or 0) + dy }
end

local NUDGE = { UP = { 0, 1 }, DOWN = { 0, -1 }, LEFT = { -1, 0 }, RIGHT = { 1, 0 } }
local keys = CreateFrame("Frame", "StormbarNudgeKeys", UIParent)
keys:Hide()
keys:EnableKeyboard(true)
keys:SetScript("OnKeyDown", function(self, key)
  local d = NUDGE[key]
  if d and ns.selected and not InCombatLockdown() then
    self:SetPropagateKeyboardInput(false) -- this arrow press moves the bar, not your character
    local step = IsShiftKeyDown() and 10 or 1
    ns.Nudge(ns.selected, d[1] * step, d[2] * step)
  elseif not InCombatLockdown() then
    self:SetPropagateKeyboardInput(true)  -- every other key works as normal
  end
end)
ns.nudgeKeys = keys

function ns.ResetPosition(key)
  ns.db.pos[key] = nil
  ns.PlaceMover(key)
end

function ns.ResetPositions()
  wipe(ns.db.pos)
  for key in pairs(ns.movers) do ns.PlaceMover(key) end
end

-- Hide a Blizzard frame by moving it into a hidden container (works even if Blizzard re-shows it).
local hider = CreateFrame("Frame", nil, UIParent)
hider:Hide()
ns.hider = hider
local origParent = {}
-- Another addon's frame (FlareUI's cast/swing bars): made invisible, never moved or changed
-- otherwise, so turning the option off simply shows it again. Re-applied if that addon
-- shows or fades it again.
local faded = {}
function ns.FadeFrame(name, hide)
  local frame = _G[name]
  if not frame then return false end
  -- never touch a frame we haven't hidden ourselves (FlareUI may be fading it on purpose)
  if not hide and not (faded[name] and faded[name].want) then return true end
  if not faded[name] then
    faded[name] = { want = false }
    local state = faded[name]
    local busy = false
    local function reapply(self)
      if state.want and not busy then busy = true; self:SetAlpha(0); busy = false end
    end
    frame:HookScript("OnShow", reapply)
    hooksecurefunc(frame, "SetAlpha", reapply)
  end
  local was = faded[name].want
  faded[name].want = hide
  if hide then frame:SetAlpha(0)
  elseif was then frame:SetAlpha(1) end -- un-hide once; after that it's FlareUI's again
  return true
end

function ns.HideBlizzard(frame, hide)
  if not frame then return end
  ns.OutOfCombat("hide" .. tostring(frame), function()
    if hide then
      if frame:GetParent() ~= hider then
        origParent[frame] = origParent[frame] or frame:GetParent() or UIParent
        pcall(frame.SetParent, frame, hider)
      end
    elseif origParent[frame] and frame:GetParent() == hider then
      pcall(frame.SetParent, frame, origParent[frame])
    end
  end)
end
