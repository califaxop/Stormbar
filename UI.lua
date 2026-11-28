-- Stormbar's look: the bar follows EllesmereUI (its skinning API) or FlareUI when installed. The
-- settings windows are always the game's own Settings design (Settings.lua).
local _, ns = ...
local UI = {}
ns.UI = UI

-- EllesmereUI style: EllesmereUI's own skinning API (EllesmereUI.RegisterSkin, see its SKINNING_API.md)
-- hands us S once, at login, unless the player turned skinning off for us; the bar takes its look.
function UI.HasEllesmere() return type(EllesmereUI) == "table" and EllesmereUI.RegisterSkin ~= nil end
if UI.HasEllesmere() then
  EllesmereUI.RegisterSkin("Stormbar", function(S)
    UI.euiSkin = S
    -- (ns.OnLooksChanged: the bar restyles when the player's EllesmereUI look changes)
    local function again() if ns.OnLooksChanged then pcall(ns.OnLooksChanged) end end
    if S.OnLooksChanged then S.OnLooksChanged(again) end
    again()
  end)
end
function UI.EUI()
  local S = UI.euiSkin
  -- (no setting: the bar follows EllesmereUI whenever it's installed and skinning us)
  if S and (not S.IsEnabled or S.IsEnabled()) then return S end
end
