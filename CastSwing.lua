-- One bar: your main-hand swing timer (with your equipped weapon's icon), replaced by your
-- cast bar (with the spell's icon) while you cast or channel, then back to the swing timer.
-- Swings come from Forever's own PLAYER_SWING event (your swings only, no combat log needed).
local _, ns = ...
local C = {}
ns.CastSwing = C
local isSecret = ns.isSecret

local f = CreateFrame("Frame", "StormbarCastSwing", UIParent)
f:SetSize(260, 16)
-- above FlareUI's bars (its resource bars use MEDIUM levels 10-114, its cast bar 130)
f:SetFrameStrata("MEDIUM")
f:SetFrameLevel(140)
local bar = CreateFrame("StatusBar", nil, f)
bar:SetMinMaxValues(0, 1)
local bg = bar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(); bg:SetColorTexture(0, 0, 0, 0.55)
local icon = f:CreateTexture(nil, "ARTWORK")
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
local iconBorder = CreateFrame("Frame", nil, f) -- holds the icon's own border

-- Show `tex` beside the bar (nil hides the icon and its border).
local function SetIcon(tex)
  if tex and not isSecret(tex) and ns.db.castSwing.showIcon then
    icon:SetTexture(tex); icon:Show()
    if iconBorder.SB_Border then iconBorder.SB_Border:Show() end
  else
    icon:Hide()
    if iconBorder.SB_Border then iconBorder.SB_Border:Hide() end
  end
end
local spark = bar:CreateTexture(nil, "OVERLAY")
spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
spark:SetBlendMode("ADD"); spark:SetWidth(12)
local leftText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
leftText:SetPoint("LEFT", 6, 0); leftText:SetJustifyH("LEFT")
local rightText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
rightText:SetPoint("RIGHT", -6, 0)
leftText:SetPoint("RIGHT", rightText, "LEFT", -6, 0); leftText:SetWordWrap(false)

local COLORS = {
  cast    = { 1.00, 0.70, 0.00 },
  channel = { 0.30, 0.80, 0.30 },
  fail    = { 0.90, 0.20, 0.20 },
  swing   = { 0.80, 0.62, 0.36 },
}
-- The weapon whose swings are shown: its swing type (Forever's PLAYER_SWING), inventory slot,
-- label (the game's own text), FlareUI's matching swing bar and FlareUI's colour for it.
local SWING = Enum and Enum.PlayerSwingType or {}
local WEAPONS = {
  main   = { type = SWING.MainHand, slot = 16, text = _G.SWING_TIMER_MAIN_HAND or "Main Hand",
             flare = "FlareUI_Resource_swingMain",   color = { 0.86, 0.65, 0.39 } },
  off    = { type = SWING.OffHand,  slot = 17, text = _G.SWING_TIMER_OFF_HAND or "Off Hand",
             flare = "FlareUI_Resource_swingOff",    color = { 0.72, 0.54, 0.32 } },
  ranged = { type = SWING.Ranged,   slot = 18, text = _G.SWING_TIMER_RANGED or "Ranged",
             flare = "FlareUI_Resource_swingRanged", color = { 0.45, 0.68, 0.40 } },
}
C.WEAPONS = WEAPONS
local function Tracked() return WEAPONS[ns.db.swingWeapon] or WEAPONS.main end

-- state
local mode = "idle"       -- "idle" | "swing" | "cast" | "channel" | "fail"
local castStart, castEnd = 0, 0
local swingStart, swingDur = 0, 0
local failUntil = 0

local function SwingColor()
  return ns.UsingFlare() and Tracked().color or COLORS.swing
end

local function SetColor(c) bar:SetStatusBarColor(c[1], c[2], c[3]) end

-- The icon beside the bar while it's a swing timer: the main-hand weapon you have equipped.
local function ShowWeaponIcon()
  SetIcon(GetInventoryItemTexture("player", Tracked().slot))
end

local function ShowSwingIdle()
  mode = (GetTime() < swingStart + swingDur) and "swing" or "idle"
  SetColor(SwingColor())
  ShowWeaponIcon()
  leftText:SetText(Tracked().text)
  if mode == "idle" then
    bar:SetValue(0); spark:Hide(); rightText:SetText(ns.db.castSwing.showTime and "0.0" or "")
  end
  f:SetAlpha((mode == "idle" and ns.db.castSwing.hideIdle) and 0 or 1)
end

local function StartCast(channel)
  local name, _, tex, startMS, endMS
  if channel then name, _, tex, startMS, endMS = UnitChannelInfo("player")
  else name, _, tex, startMS, endMS = UnitCastingInfo("player") end
  if not name or isSecret(startMS) or isSecret(endMS) then return end
  mode = channel and "channel" or "cast"
  castStart, castEnd = startMS / 1000, endMS / 1000
  SetColor(channel and COLORS.channel or COLORS.cast)
  leftText:SetText(ns.Readable(name) and name or "")
  SetIcon(tex) -- the spell being cast
  f:SetAlpha(1)
end

local function EndCast(failed)
  if mode ~= "cast" and mode ~= "channel" then return end
  if failed then
    mode = "fail"; failUntil = GetTime() + 0.5
    SetColor(COLORS.fail); bar:SetValue(1); spark:Hide()
    leftText:SetText(failed); rightText:SetText("")
  else
    ShowSwingIdle()
  end
end

f:SetScript("OnUpdate", function()
  local now = GetTime()
  local showTime = ns.db.castSwing.showTime
  if mode == "cast" or mode == "channel" then
    local total = castEnd - castStart
    local p = total > 0 and (now - castStart) / total or 1
    if p >= 1 then ShowSwingIdle(); return end
    if mode == "channel" then p = 1 - p end
    bar:SetValue(p)
    spark:SetPoint("CENTER", bar, "LEFT", bar:GetWidth() * p, 0); spark:Show()
    rightText:SetText(showTime and format("%.1f", math.max(0, castEnd - now)) or "")
  elseif mode == "fail" then
    if now >= failUntil then ShowSwingIdle() end
  elseif mode == "swing" then
    local p = swingDur > 0 and (now - swingStart) / swingDur or 1
    if p >= 1 then ShowSwingIdle(); return end
    bar:SetValue(p)
    spark:SetPoint("CENTER", bar, "LEFT", bar:GetWidth() * p, 0); spark:Show()
    rightText:SetText(showTime and format("%.1f", math.max(0, swingStart + swingDur - now)) or "")
  end
end)

local ev = CreateFrame("Frame")
ev:SetScript("OnEvent", function(_, event, arg1, arg2)
  if event == "PLAYER_SWING" then
    local duration, swingType = arg1, arg2
    if isSecret(duration) or isSecret(swingType) then return end
    local want = Tracked().type
    if want ~= nil and swingType ~= want then return end -- a different weapon's swing
    swingStart, swingDur = GetTime(), duration or 0
    if mode == "idle" or mode == "swing" then
      mode = "swing"; SetColor(SwingColor()); ShowWeaponIcon(); leftText:SetText(Tracked().text); f:SetAlpha(1)
    end
  elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_DELAYED" then
    StartCast(false)
  elseif event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
    StartCast(true)
  elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
    EndCast(_G.INTERRUPTED or "Interrupted")
  elseif event == "UNIT_SPELLCAST_FAILED" then
    if mode == "cast" then EndCast(_G.FAILED or "Failed") end
  elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
    EndCast(nil)
  elseif event == "PLAYER_DEAD" then
    swingDur = 0; ShowSwingIdle()
  elseif event == "PLAYER_ENTERING_WORLD" then
    C.ApplyFlare()
    C_Timer.After(2, C.ApplyFlare) -- FlareUI builds its bars around now
  elseif event == "PLAYER_EQUIPMENT_CHANGED" then
    if mode == "idle" or mode == "swing" then ShowWeaponIcon() end -- swapped weapons
  end
end)

local lastWeapon
function C.Apply()
  if lastWeapon and lastWeapon ~= ns.db.swingWeapon then swingDur = 0 end -- switched weapons
  lastWeapon = ns.db.swingWeapon
  local db = ns.db.castSwing
  local h = db.height
  local w = db.width or 260
  f:SetScale(ns.db.scale)
  f:SetSize(w, h)
  icon:ClearAllPoints()
  icon:SetSize(h, h); icon:SetPoint("LEFT", f, "LEFT", 0, 0)
  iconBorder:SetAllPoints(icon)
  local _, out = ns.Border(iconBorder, icon, true)
  -- room for the icon's border and the bar's border side by side, plus a small gap
  local gap = 2 * (out or 1) + 2
  bar:ClearAllPoints()
  bar:SetPoint("TOPLEFT", f, "TOPLEFT", db.showIcon and (h + gap) or 0, 0)
  bar:SetPoint("BOTTOMRIGHT")
  bar:SetStatusBarTexture(ns.BarTexture())
  spark:SetHeight(h * 2.2)
  ns.Border(f, bar, true)
  f:Show()
  if mode == "idle" or mode == "swing" then ShowSwingIdle() end
  -- Blizzard's own cast bar is replaced by this one
  for _, name in ipairs({ "PlayerCastingBarFrame", "CastingBarFrame" }) do
    if _G[name] then ns.HideBlizzard(_G[name], ns.db.hideBlizzCast) end
  end
  C.ApplyFlare()
end

-- FlareUI's own cast bar and Main Hand swing bar (FlareUI makes them after login,
-- so this runs again a moment later).
function C.ApplyFlare()
  ns.FadeFrame("FlareUI_UF_PlayerCastBar", ns.db.hideFlareCast)
  -- only FlareUI's bar for the weapon Stormbar tracks; its other swing bars are left alone
  for key, w in pairs(WEAPONS) do
    ns.FadeFrame(w.flare, ns.db.hideFlareSwing and key == ns.db.swingWeapon)
  end
end

function C.Debug()
  local p, _, rp, x, y = f:GetPoint()
  ns.Print(format("bar: shown=%s visible=%s alpha=%.2f scale=%.2f size=%dx%d at %s/%s %.0f,%.0f strata=%s level=%d",
    tostring(f:IsShown()), tostring(f:IsVisible()), f:GetEffectiveAlpha(), f:GetEffectiveScale(),
    f:GetWidth(), f:GetHeight(), tostring(p), tostring(rp), x or 0, y or 0, f:GetFrameStrata(), f:GetFrameLevel()))
  ns.Print("mode: " .. mode .. ", swing event: " .. tostring(C.swingEventOK))
  ns.Print("tracking: " .. Tracked().text)
  for _, name in ipairs({ "PlayerCastingBarFrame", "FlareUI_UF_PlayerCastBar", Tracked().flare }) do
    local o = _G[name]
    ns.Print(name .. ": " .. (o and format("exists, visible=%s, alpha=%.2f", tostring(o:IsVisible()), o:GetEffectiveAlpha()) or "not found"))
  end
end

function C.Init()
  ns.RegisterMover("castSwing", f, "Swing / Cast", { "BOTTOM", "BOTTOM", 0, 200 })
  ns.PlaceMover("castSwing")
  C.swingEventOK = pcall(ev.RegisterEvent, ev, "PLAYER_SWING")
  if not C.swingEventOK then
    ns.Print("this client has no swing event; the swing timer is off (the cast bar still works).")
  end
  ev:RegisterEvent("PLAYER_DEAD")
  ev:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  for _, e in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_CHANNEL_START",
    "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_CHANNEL_STOP" }) do
    ev:RegisterUnitEvent(e, "player")
  end
  C.Apply()
end
