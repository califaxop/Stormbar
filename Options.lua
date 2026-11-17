-- Stormbar: settings window (/stormbar or /stb, or Esc > Options > AddOns > Stormbar)
-- and start-up.
local _, ns = ...

local function ApplyAll()
  ns.CastSwing.Apply(); ns.ApplyLock()
end
ns.ApplyAll = ApplyAll

local function Label(parent, text, template)
  local fs = parent:CreateFontString(nil, "ARTWORK", template or "GameFontNormal")
  fs:SetText(text)
  return fs
end
local function Header(parent, text, anchor, x, y)
  local h = Label(parent, text)
  if anchor then h:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y or -16) else h:SetPoint("TOPLEFT", x, y) end
  return h
end

-- get/set by path, e.g. "castSwing.height"
local function Parts(path)
  local parts = {}
  for part in path:gmatch("[^.]+") do parts[#parts + 1] = tonumber(part) or part end
  return parts
end
local function Get(path)
  local t = ns.db
  for _, part in ipairs(Parts(path)) do t = t[part] end
  return t
end
local function Set(path, v)
  local t, last = ns.db, nil
  local parts = Parts(path)
  for i = 1, #parts - 1 do t = t[parts[i]] end
  last = parts[#parts]
  t[last] = v
end

-- factor: how the typed number relates to the saved value (100 for percentages)
local function Slider(parent, label, minV, maxV, step, path, fmt, anchor, factor)
  factor = factor or 1
  local text = Label(parent, "", "GameFontHighlight")
  text:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
  local s = CreateFrame("Slider", nil, parent, "BackdropTemplate")
  s:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -6)
  s:SetSize(170, 16)
  s:SetOrientation("HORIZONTAL")
  s:SetMinMaxValues(minV, maxV); s:SetValueStep(step); s:SetObeyStepOnDrag(true)
  s:SetBackdrop({ bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border", tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 } })
  s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  s:EnableMouseWheel(true)
  s:SetScript("OnMouseWheel", function(self, d) self:SetValue(self:GetValue() + d * step) end)
  local refreshing = false
  s:SetScript("OnValueChanged", function(_, v)
    v = math.floor(v / step + 0.5) * step
    text:SetText(label .. ": " .. fmt(v))
    if refreshing or Get(path) == v then return end
    Set(path, v); ApplyAll()
  end)
  -- type an exact value: Enter applies it (kept within the slider's range), Esc cancels
  local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  box:SetSize(46, 20)
  box:SetPoint("LEFT", s, "RIGHT", 12, 0)
  box:SetAutoFocus(false)
  box:SetJustifyH("CENTER")
  local function ShowValue()
    local v = Get(path) * factor
    box:SetText(tostring(math.floor(v + 0.5)))
  end
  box:SetScript("OnEnterPressed", function(self)
    local n = tonumber(self:GetText())
    if n then
      local v = math.max(minV, math.min(maxV, n / factor))
      v = math.floor(v / step + 0.5) * step
      Set(path, v); ApplyAll()
      refreshing = true; s:SetValue(v); text:SetText(label .. ": " .. fmt(v)); refreshing = false
    end
    ShowValue(); self:ClearFocus()
  end)
  box:SetScript("OnEscapePressed", function(self) ShowValue(); self:ClearFocus() end)
  box:SetScript("OnEditFocusLost", ShowValue)
  s:HookScript("OnValueChanged", function() if not box:HasFocus() then ShowValue() end end)

  s.Refresh = function()
    refreshing = true; s:SetValue(Get(path)); text:SetText(label .. ": " .. fmt(Get(path))); refreshing = false
    ShowValue()
  end
  return s
end

-- A choice between a few options: click to go to the next one, right-click for the previous.
local function Choice(parent, label, path, options, anchor)
  local l = Label(parent, label, "GameFontHighlight")
  l:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(230, 22)
  b:SetPoint("TOPLEFT", l, "BOTTOMLEFT", 0, -4)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  local function index()
    for i, o in ipairs(options) do if o[1] == Get(path) then return i end end
    return 1
  end
  b:SetScript("OnClick", function(_, mouse)
    local i = index() + (mouse == "RightButton" and -1 or 1)
    if i < 1 then i = #options elseif i > #options then i = 1 end
    Set(path, options[i][1]); b.Refresh(); ApplyAll()
  end)
  b.Refresh = function() b:SetText(options[index()][2]) end
  return b
end

local function Check(parent, label, path, anchor, invert)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb:SetSize(24, 24)
  cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
  local l = Label(parent, label, "GameFontHighlight")
  l:SetPoint("LEFT", cb, "RIGHT", 2, 0)
  cb:SetScript("OnClick", function(self)
    local v = self:GetChecked() and true or false
    if invert then v = not v end
    Set(path, v); ApplyAll()
  end)
  cb.Refresh = function()
    local v = Get(path) and true or false
    if invert then v = not v end
    cb:SetChecked(v)
  end
  return cb
end

local function Button(parent, text, width, onClick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, 22); b:SetText(text); b:SetScript("OnClick", onClick)
  return b
end

---------------------------------------------------------------------------
-- The options (shared by the settings window and the Edit Mode dialog)
---------------------------------------------------------------------------
local px = function(v) return v .. " px" end
local pctf = function(v) return math.floor(v * 100 + 0.5) .. "%" end

local BAR_ITEMS = {
  { "choice", "Weapon", "swingWeapon", {
    { "main", _G.SWING_TIMER_MAIN_HAND or "Main Hand" },
    { "off", _G.SWING_TIMER_OFF_HAND or "Off Hand" },
    { "ranged", (_G.SWING_TIMER_RANGED or "Ranged") .. " (wand / gun / bow)" } } },
  { "slider", "Scale", 0.5, 2, 0.01, "scale", pctf, 100 },   -- 1% steps; type the % in the box
  { "slider", "Width", 100, 600, 1, "castSwing.width", px },
  { "slider", "Height", 8, 32, 1, "castSwing.height", px },
  { "check", "Icon (weapon while swinging, spell while casting)", "castSwing.showIcon" },
  { "check", "Time remaining", "castSwing.showTime" },
  { "check", "Hide when not swinging or casting", "castSwing.hideIdle" },
}

-- Builds `items` top to bottom under `anchor`; returns the widgets and the last one.
local function BuildItems(parent, items, anchor)
  local w, prev, height = {}, anchor, 0
  for _, it in ipairs(items) do
    local widget
    if it[1] == "choice" then
      widget = Choice(parent, it[2], it[3], it[4], prev)
      height = height + 48
    elseif it[1] == "slider" then
      widget = Slider(parent, it[2], it[3], it[4], it[5], it[6], it[7], prev, it[8])
      height = height + 46
    else
      widget = Check(parent, it[2], it[3], prev)
      if prev.SetOrientation then widget:ClearAllPoints(); widget:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -10); height = height + 8 end
      height = height + 26
    end
    w[#w + 1] = widget
    prev = widget
  end
  return w, prev, height
end

---------------------------------------------------------------------------
-- Settings window (/stormbar)
---------------------------------------------------------------------------
local function BuildPanel(panel)
  local title = Label(panel, "Stormbar", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  local sub = Label(panel, "Main-hand swing timer and cast bar in one.", "GameFontDisableSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)

  local hG = Header(panel, "General", sub, nil, -14)
  local w1, last1 = BuildItems(panel, {
    { "check", "Unlock (drag to move)", "locked", invert = true },
    { "check", "Move in Edit Mode", "editMode" },
    { "check", "Snap to Edit Mode grid (when its Snap is on)", "snapGrid" },
    { "check", "FlareUI style (needs FlareUI)", "flareStyle" },
    { "check", "Hide Blizzard's cast bar", "hideBlizzCast" },
    { "check", "Hide FlareUI's Player Cast Bar", "hideFlareCast" },
    { "check", "Hide FlareUI's swing bar for the same weapon", "hideFlareSwing" },
  }, hG)
  -- "Unlock" is the inverse of the saved "locked"
  w1[1]:SetScript("OnClick", function(self) ns.db.locked = not self:GetChecked(); ApplyAll() end)
  w1[1].Refresh = function() w1[1]:SetChecked(not ns.db.locked) end

  local hB = Header(panel, "Bar", last1, nil, -16)
  local w2, last2 = BuildItems(panel, BAR_ITEMS, hB)

  local rp = Button(panel, "Reset position", 130, function() ns.ResetPosition("castSwing") end)
  rp:SetPoint("TOPLEFT", last2, "BOTTOMLEFT", 0, -18)
  local ra = Button(panel, "Reset everything", 130, function()
    ns.ResetDB(); ns.ResetPosition("castSwing"); panel.RefreshAll(); ApplyAll()
  end)
  ra:SetPoint("LEFT", rp, "RIGHT", 8, 0)

  panel.RefreshAll = function()
    for _, x in ipairs(w1) do x.Refresh() end
    for _, x in ipairs(w2) do x.Refresh() end
  end
  panel:HookScript("OnShow", panel.RefreshAll)
  return panel
end

local settingsPanel, window
local function CreateOptions()
  settingsPanel = CreateFrame("Frame")
  settingsPanel.name = "Stormbar"
  local ok, e = pcall(BuildPanel, settingsPanel)
  if not ok then ns.Print("settings panel failed: " .. tostring(e)); return end
  pcall(function()
    if Settings and Settings.RegisterCanvasLayoutCategory then
      local category = Settings.RegisterCanvasLayoutCategory(settingsPanel, settingsPanel.name)
      Settings.RegisterAddOnCategory(category)
    end
  end)
end

function ns.OpenOptions()
  if not window then
    window = CreateFrame("Frame", "StormbarOptionsWindow", UIParent, "BackdropTemplate")
    window:SetSize(400, 690)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 } })
    window:SetMovable(true); window:EnableMouse(true); window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:SetClampedToScreen(true)
    tinsert(UISpecialFrames, "StormbarOptionsWindow")
    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)
    local inner = CreateFrame("Frame", nil, window)
    inner:SetPoint("TOPLEFT", 8, -8); inner:SetPoint("BOTTOMRIGHT", -8, 8)
    local ok, e = pcall(BuildPanel, inner)
    if not ok then window:Hide(); window = nil; ns.Print("settings failed: " .. tostring(e)); return end
    window:Hide()
  end
  window:SetShown(not window:IsShown())
end

---------------------------------------------------------------------------
-- Edit Mode dialog: click the bar in Edit Mode (or while unlocked) for its options.
---------------------------------------------------------------------------
local dialog
local function BuildDialog()
  dialog = CreateFrame("Frame", "StormbarPieceDialog", UIParent, "BackdropTemplate")
  dialog:SetWidth(290)
  dialog:SetFrameStrata("DIALOG")
  dialog:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 } })
  dialog:SetMovable(true); dialog:EnableMouse(true); dialog:RegisterForDrag("LeftButton")
  dialog:SetScript("OnDragStart", dialog.StartMoving)
  dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
  dialog:SetClampedToScreen(true)
  local close = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -6, -6)
  close:SetScript("OnClick", function() ns.ClosePieceDialog() end)
  local title = Label(dialog, "Swing / Cast", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -18)
  local top = CreateFrame("Frame", nil, dialog)
  top:SetPoint("TOPLEFT", 22, -40); top:SetSize(1, 1)
  local w, last, h = BuildItems(dialog, BAR_ITEMS, top)
  local reset = Button(dialog, "Reset position", 130, function() ns.ResetPosition("castSwing") end)
  reset:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -14)
  dialog:SetHeight(h + 40 + 14 + 22 + 30)
  dialog.Refresh = function() for _, x in ipairs(w) do x.Refresh() end end
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
  elseif cmd == "reset" then
    ns.ResetPosition("castSwing"); ns.Print("position reset.")
  else
    local ok, e = pcall(ns.OpenOptions)
    if not ok then ns.Print("settings error: " .. tostring(e)) end
  end
end
