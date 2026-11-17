-- Stormbar: settings window (/stormbar or /stb, or Esc > Options > AddOns > Stormbar), the Edit Mode
-- dialog, and start-up. Drawn in the same style as XP Planner and Spell Glow (see UI.lua).
local _, ns = ...
local UI = ns.UI

local function ApplyAll()
  ns.CastSwing.Apply(); ns.ApplyLock()
end
ns.ApplyAll = ApplyAll

-- a { get, set } pair for a setting by path, e.g. "castSwing.height"
local function Parts(path)
  local parts = {}
  for part in path:gmatch("[^.]+") do parts[#parts + 1] = tonumber(part) or part end
  return parts
end
local function S(path, invert)
  local parts = Parts(path)
  local function get()
    local t = ns.db
    for _, p in ipairs(parts) do t = t[p] end
    if invert then return not t end
    return t
  end
  local function set(v)
    local t = ns.db
    for i = 1, #parts - 1 do t = t[parts[i]] end
    if invert then v = not v end
    t[parts[#parts]] = v
  end
  return { get, set }
end

local px = function(v) return v .. " px" end
local pctf = function(v) return math.floor(v * 100 + 0.5) .. "%" end
local WEAPONS = {
  { "main", _G.SWING_TIMER_MAIN_HAND or "Main Hand" },
  { "off", _G.SWING_TIMER_OFF_HAND or "Off Hand" },
  { "ranged", (_G.SWING_TIMER_RANGED or "Ranged") .. " (wand / gun / bow)" },
}

-- The bar's options, shared by the settings window and the Edit Mode dialog.
-- Places them top to bottom at (x, y) in `parent`, `width` wide; returns the widgets and the y below.
local function BarOptions(parent, x, y, width)
  local w = {}
  local function add(widget, h) widget:SetPoint("TOPLEFT", x, y); w[#w + 1] = widget; y = y - h end
  local wl = UI.Text(parent, "line", "Weapon"); wl:SetPoint("TOPLEFT", x, y); y = y - 18
  add(UI.Toggle(parent, width, WEAPONS, S("swingWeapon"), ApplyAll, "Which swing to time. Click to switch."), 32)
  add(UI.Slider(parent, "Scale", width, 0.5, 2, 0.01, S("scale"), pctf, ApplyAll, 100), 42)
  add(UI.Slider(parent, "Width", width, 100, 600, 1, S("castSwing.width"), px, ApplyAll, 1), 42)
  add(UI.Slider(parent, "Height", width, 8, 32, 1, S("castSwing.height"), px, ApplyAll, 1), 46)
  add(UI.Check(parent, "Icon (weapon, or the spell while casting)", S("castSwing.showIcon"), width, ApplyAll), 24)
  add(UI.Check(parent, "Time remaining", S("castSwing.showTime"), width, ApplyAll), 24)
  add(UI.Check(parent, "Hide when not swinging or casting", S("castSwing.hideIdle"), width, ApplyAll), 24)
  return w, y
end

---------------------------------------------------------------------------
-- Settings window (/stormbar)
---------------------------------------------------------------------------
local window
local function BuildWindow()
  window = UI.Window("StormbarOptionsWindow", 580, 430)
  window:SetPoint("CENTER")
  local title = UI.Text(window, "title", "Stormbar")
  title:SetPoint("TOPLEFT", 26, -20)
  UI.Text(window, "note", "Swing timer and cast bar in one."):SetPoint("LEFT", title, "RIGHT", 10, -1)

  local L, R, CW = 26, 300, 254
  local sec = UI.Section(window, "Bar", CW); sec:SetPoint("TOPLEFT", L, -54)
  local w = BarOptions(window, L, -86, CW)

  local function check(label, path, yy, invert, onChange)
    local c = UI.Check(window, label, S(path, invert), CW, onChange or ApplyAll)
    c:SetPoint("TOPLEFT", R, yy); w[#w + 1] = c
    return c
  end
  sec = UI.Section(window, "Moving", CW); sec:SetPoint("TOPLEFT", R, -54)
  check("Unlocked (drag to move)", "locked", -86, true)
  check("Move in Edit Mode", "editMode", -110)
  check("Snap to Edit Mode's grid", "snapGrid", -134)
  local nn = UI.Text(window, "note", "In Edit Mode, click the bar for its options; arrow keys nudge it (Shift: 10 px).")
  nn:SetPoint("TOPLEFT", R, -160); nn:SetWidth(CW)
  sec = UI.Section(window, "Replace other bars", CW); sec:SetPoint("TOPLEFT", R, -196)
  check("Hide Blizzard's cast bar", "hideBlizzCast", -228)
  check("Hide FlareUI's Player Cast Bar", "hideFlareCast", -252)
  check("Hide FlareUI's swing bar (same weapon)", "hideFlareSwing", -276)
  sec = UI.Section(window, "Look", CW); sec:SetPoint("TOPLEFT", R, -312)
  check("FlareUI style (needs FlareUI)", "flareStyle", -344, false, function() ApplyAll(); UI.Restyle() end)

  local rp = UI.Button(window, "Reset position", 130, function() ns.ResetPosition("castSwing") end)
  rp:SetPoint("BOTTOMLEFT", L, 20)
  local ra = UI.Button(window, "Reset everything", 130, function()
    ns.ResetDB(); ns.ResetPosition("castSwing"); ApplyAll(); UI.Restyle()
    for _, x in ipairs(w) do x.Refresh() end
  end)
  ra:SetPoint("LEFT", rp, "RIGHT", 6, 0)

  window:SetScript("OnShow", function() for _, x in ipairs(w) do x.Refresh() end end)
  window:Hide()
end

function ns.OpenOptions()
  if not window then
    local ok, e = pcall(BuildWindow)
    if not ok then if window then window:Hide() end; window = nil; ns.Print("settings failed: " .. tostring(e)); return end
  end
  UI.Restyle()
  window:SetShown(not window:IsShown())
end

-- Esc > Options > AddOns: a short page with a button that opens the window
local function CreateOptions()
  local p = CreateFrame("Frame"); p.name = "Stormbar"
  pcall(function()
    local t = p:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    t:SetPoint("TOPLEFT", 16, -16); t:SetText("Stormbar")
    local b = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
    b:SetSize(200, 24); b:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -12); b:SetText("Open Stormbar settings")
    b:SetScript("OnClick", function()
      if SettingsPanel and SettingsPanel.Close then pcall(SettingsPanel.Close, SettingsPanel, true) end
      if not (window and window:IsShown()) then ns.OpenOptions() end
    end)
    if Settings and Settings.RegisterCanvasLayoutCategory then
      Settings.RegisterAddOnCategory(Settings.RegisterCanvasLayoutCategory(p, p.name))
    end
  end)
end

---------------------------------------------------------------------------
-- Edit Mode dialog: click the bar in Edit Mode (or while unlocked) for its options.
---------------------------------------------------------------------------
local dialog
local function BuildDialog()
  dialog = UI.Window("StormbarPieceDialog", 290, 100)
  local title = UI.Text(dialog, "title", "Swing / Cast")
  title:SetPoint("TOPLEFT", 20, -18)
  local w, y = BarOptions(dialog, 20, -48, 250)
  local reset = UI.Button(dialog, "Reset position", 130, function() ns.ResetPosition("castSwing") end)
  reset:SetPoint("TOPLEFT", 20, y - 6)
  dialog:SetHeight(-y + 6 + 22 + 20)
  dialog.Refresh = function() for _, x in ipairs(w) do x.Refresh() end end
  -- closing it (its ×, or Esc) ends the selection too
  dialog:HookScript("OnHide", function() if ns.selected then ns.selected = nil; ns.ApplyLock() end end)
  dialog:Hide()
end

function ns.OpenPieceDialog(key)
  if not dialog then BuildDialog() end
  UI.Restyle()
  dialog.Refresh()
  ns.selected = key
  ns.ApplyLock()
  local m = ns.movers[key]
  dialog:ClearAllPoints()
  local top = m.frame:GetTop() and m.frame:GetTop() * m.frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
  if top and top + dialog:GetHeight() + 20 < UIParent:GetHeight() then
    dialog:SetPoint("BOTTOM", m.frame, "TOP", 0, 14)
  else
    dialog:SetPoint("TOP", m.frame, "BOTTOM", 0, -14)
  end
  -- Pin it to the screen where it opened: if it stayed attached to the bar, changing the
  -- bar's width/height/scale would drag the dialog (and the slider under your mouse) along.
  local left, dtop = dialog:GetLeft(), dialog:GetTop()
  if left and dtop then
    dialog:ClearAllPoints()
    dialog:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, dtop)
  end
  dialog:Show()
end

function ns.ClosePieceDialog()
  if dialog then dialog:Hide() end
  if ns.selected then ns.selected = nil; ns.ApplyLock() end
end

---------------------------------------------------------------------------
-- Start-up and slash commands
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ns.name then
    ns.LoadDB()
  elseif event == "PLAYER_LOGIN" then
    local ok, e = pcall(ns.CastSwing.Init)
    if not ok then ns.Print("start-up error: " .. tostring(e)) end
    ns.HookEditMode()
    ns.ApplyLock()
    CreateOptions()
    ns.Print("loaded. |cffffff00/stormbar|r for settings, |cffffff00/stb debug|r if the bar doesn't show.")
  end
end)

SLASH_STORMBAR1 = "/stormbar"
SLASH_STORMBAR2 = "/stb"
SlashCmdList.STORMBAR = function(msg)
  local cmd = (msg or ""):lower():match("^(%S*)")
  if cmd == "unlock" or cmd == "lock" then
    ns.db.locked = (cmd == "lock"); ns.ApplyLock()
    ns.Print(ns.db.locked and "locked." or "unlocked: drag the bar to move it, click it for options.")
  elseif cmd == "debug" then
    ns.CastSwing.Debug()
  elseif cmd == "reset" then
    ns.ResetPosition("castSwing"); ns.Print("position reset.")
  else
    local ok, e = pcall(ns.OpenOptions)
    if not ok then ns.Print("settings error: " .. tostring(e)) end
  end
end
