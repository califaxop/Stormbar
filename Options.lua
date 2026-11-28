-- Stormbar: settings window (/stormbar or /stb, or Esc > Options > AddOns > Stormbar), the Edit Mode
-- dialog, and start-up. In the game's own Settings design (Settings.lua).
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

-- The bar's options, shared by the settings window and the Edit Mode dialog, as rows in R
local function BarOptions(R)
  R:Toggle("Weapon", 230, WEAPONS, S("swingWeapon"), ApplyAll, "Which swing to time.")
  R:Slider("Scale", 0.5, 2, 0.01, S("scale"), pctf, ApplyAll, "Type an exact % in the box.", 100, 200)
  R:Slider("Width", 100, 600, 1, S("castSwing.width"), px, ApplyAll, "Type an exact size in the box.", 1, 200)
  R:Slider("Height", 8, 32, 1, S("castSwing.height"), px, ApplyAll, "Type an exact size in the box.", 1, 200)
  R:Check("Icon", S("castSwing.showIcon"), ApplyAll, "The weapon, or the spell while casting.")
  R:Check("Time remaining", S("castSwing.showTime"), ApplyAll)
  R:Check("Hide when idle", S("castSwing.hideIdle"), ApplyAll, "Hidden when you're not swinging or casting.")
  R:Swatch("Cast done colour", function() return S("castSwing.doneColor")[1]() end, ApplyAll, "The bar's colour when a cast goes off.")
end

---------------------------------------------------------------------------
-- Report a bug (the title bar's button, /stb report): the line to paste and its counters
---------------------------------------------------------------------------
local function yes(v) return v and "yes" or "no" end
local function BugReport()
  local db, C = ns.db, ns.CastSwing
  local okB, build, number, _, toc = pcall(GetBuildInfo)
  local _, class = UnitClass("player")
  local L = { format("Stormbar; client %s (%s), interface %s; %s %d", okB and tostring(build) or "?",
    okB and tostring(number) or "?", okB and tostring(toc) or "?", tostring(class), UnitLevel("player")) }
  L[#L + 1] = format("settings: weapon %s, locked %s, Edit Mode %s, snap %s, hide Blizzard cast %s, hide FlareUI cast %s, hide FlareUI swing %s, scale %.2f, size %dx%d, icon %s, time %s, hide idle %s",
    tostring(db.swingWeapon), yes(db.locked), yes(db.editMode), yes(db.snapGrid), yes(db.hideBlizzCast), yes(db.hideFlareCast),
    yes(db.hideFlareSwing), db.scale or 1, db.castSwing.width or 0, db.castSwing.height or 0, yes(db.castSwing.showIcon),
    yes(db.castSwing.showTime), yes(db.castSwing.hideIdle))
  L[#L + 1] = format("FlareUI: %s; EllesmereUI: %s", yes(type(FlareUI) == "table"), yes(UI.HasEllesmere()))
  for _, l in ipairs(C.DebugLines()) do L[#L + 1] = l end
  local W = C.WEAPONS[db.swingWeapon] or C.WEAPONS.main
  return table.concat(L, " // "), {
    { "Interface\\Icons\\INV_Sword_04", "Swing timer", C.swingEventOK and "on" or "off (no swing event)" },
    { "Interface\\Icons\\Ability_DualWield", "Tracking", W.text },
    { "Interface\\Icons\\Spell_Nature_Lightning", "Doing now", C.Mode() },
    { "Interface\\Icons\\INV_Misc_PocketWatch_01", "Locked", yes(db.locked) },
    { "Interface\\Icons\\INV_Misc_Note_01", "Hides Blizzard's cast bar", yes(db.hideBlizzCast) },
    { "Interface\\Icons\\INV_Misc_Gem_Pearl_04", "FlareUI", type(FlareUI) == "table" and "installed" or "not installed" },
  }
end
local BUG = { name = "StormbarReportWindow", title = "Stormbar Bugs & Feedback", repo = "https://github.com/califaxop/stormbar/issues/new",
  included = "Included: Stormbar's version, the game client, your class and level, its settings, the bar's state and the cast bars it replaces. Never: your name, realm, guild or other players.",
  build = BugReport }
function ns.ShowBugReport(kind)
  local get = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
  BUG.version = get and get(ns.name, "Version") or nil
  return UI.ShowBugReport(BUG, kind)
end

---------------------------------------------------------------------------
-- Settings window (/stormbar)
---------------------------------------------------------------------------
local window
local function StatusPage(_, R)
  R:Section("Now")
  local rows = {}
  for i = 1, 6 do rows[i] = R:Row("") end
  local function update()
    local ok, _, stats = pcall(BugReport)
    for i, row in ipairs(rows) do
      local v = ok and stats[i]
      row.label:SetText(v and v[2] or "")
      if not row.value then
        row.value = UI.Font(row, "GameFontHighlight"); row.value:SetPoint("LEFT", R.ctrl, 0)
      end
      row.value:SetText(v and tostring(v[3]) or "")
    end
  end
  R:Track({ Refresh = update })
  R:Note("/stb debug: what the bar sees.  /stb report: the bug report.  /stb lock, /stb unlock, /stb reset.")
  R:Section("Reset")
  R:Button("Reset position", "Reset", 96, function() ns.ResetPosition("castSwing") end, "The bar back to its default place.")
  R:Button("Reset everything", "Defaults", 96, function()
    ns.ResetDB(); ns.ResetPosition("castSwing"); ApplyAll(); window.Refresh()
  end, "Every setting back to its default, and the bar to its default place.")
end

local function BuildWindow()
  window = UI.Settings({ name = "StormbarOptionsWindow", title = "Stormbar",
    bug = function() ns.ShowBugReport() end,
    pages = {
      { "Bar", "What the bar shows and its size.", function(_, R) R:Section("Bar"); BarOptions(R) end },
      { "Moving", "Unlocking the bar, Edit Mode and its grid.", function(_, R)
        R:Section("Moving")
        R:Check("Unlocked (drag to move)", S("locked", true), ApplyAll)
        R:Check("Move in Edit Mode", S("editMode"), ApplyAll)
        R:Check("Snap to Edit Mode's grid", S("snapGrid"), ApplyAll)
        R:Note("In Edit Mode, click the bar for its options; arrow keys nudge it (Shift: 10 px).")
      end },
      { "Other Cast Bars", "The cast and swing bars Stormbar takes the place of.", function(_, R)
        R:Section("Replace other bars")
        R:Check("Hide Blizzard's cast bar", S("hideBlizzCast"), ApplyAll)
        R:Check("Hide FlareUI's Player Cast Bar", S("hideFlareCast"), ApplyAll)
        R:Check("Hide FlareUI's swing bar", S("hideFlareSwing"), ApplyAll, "When it times the same weapon.")
      end },
      { "Status", "What the bar is doing, the commands, and starting afresh.", StatusPage },
    },
    categories = { { "Stormbar", { 1, 2, 3 } }, { "Help", { 4 } } } })
end

-- the settings window, built the first time it's asked for
local function GetWindow()
  if not window then
    local ok, e = pcall(BuildWindow)
    if not ok then if window then window:Hide() end; window = nil; ns.Print("settings failed: " .. tostring(e)); return end
  end
  return window
end
function ns.OpenOptions()
  local w = GetWindow()
  if w then UI.ToggleWindow(w) end
  return w
end
UI.JoinSuite("Stormbar", "Swing timer and cast bar in one.",
  "Interface\\AddOns\\Stormbar\\media\\Logo", 5, GetWindow)

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
  dialog = UI.Window("StormbarPieceDialog", 470, 100, "Swing / Cast")
  local R = UI.Rows(dialog, { width = 470, label = 22, control = 150, y = -34 })
  BarOptions(R)
  local reset = UI.Button(dialog, "Reset position", 130, function() ns.ResetPosition("castSwing") end)
  reset:SetPoint("TOPLEFT", 20, R.y - 8)
  dialog:SetHeight(-R.y + 8 + 22 + 18)
  dialog.Refresh = R.Refresh
  -- closing it (its close button, or Esc) ends the selection too
  dialog:HookScript("OnHide", function() if ns.selected then ns.selected = nil; ns.ApplyLock() end end)
  dialog:Hide()
end

function ns.OpenPieceDialog(key)
  if not dialog then BuildDialog() end
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
  elseif cmd == "report" then
    ns.ShowBugReport()
  elseif cmd == "reset" then
    ns.ResetPosition("castSwing"); ns.Print("position reset.")
  else
    local ok, e = pcall(ns.OpenOptions)
    if not ok then ns.Print("settings error: " .. tostring(e)) end
  end
end
