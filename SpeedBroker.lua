-- Speed Broker: LDB feed for current movement speed
local ADDON = ...
local BASE = BASE_MOVEMENT_SPEED or 7 -- yards/sec at 100%
local THROTTLE = 0.1

local LDB = LibStub("LibDataBroker-1.1")
local obj = LDB:NewDataObject("Speed", {
    type  = "data source",
    label = "Speed",
    text  = "0%",
    icon  = "Interface\\Icons\\Ability_Rogue_Sprint",
})

local db
local mode = "Run"

local function pct(yds) return yds / BASE * 100 end

local function fmt(yds)
    if db and db.yards then
        return string.format("%.1f yd/s", yds)
    end
    return string.format("%d%%", math.floor(pct(yds) + 0.5))
end

local function GetSpeed()
    -- Skyriding: GetUnitSpeed doesn't report it, use gliding info
    if C_PlayerInfo and C_PlayerInfo.GetGlidingInfo then
        local isGliding, _, forwardSpeed = C_PlayerInfo.GetGlidingInfo()
        if isGliding and forwardSpeed then
            return forwardSpeed, "Skyriding"
        end
    end

    local current, run, flight, swim = GetUnitSpeed("player")

    if UnitOnTaxi("player") then return current, "Taxi" end

    if current > 0 then
        if IsSwimming() then return current, "Swim" end
        if IsFlying() then return current, "Fly" end
        if current < run * 0.4 then return current, "Walk" end
        return current, "Run"
    end

    -- Standing still: show what you'd move at
    if IsSwimming() then return swim, "Swim" end
    if IsFlying() then return flight, "Fly" end
    return run, "Run"
end

local elapsed = 0
local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed < THROTTLE then return end
    elapsed = 0
    local speed, m = GetSpeed()
    mode = m
    local text = (db and db.showMode ~= false) and (m .. ": " .. fmt(speed)) or fmt(speed)
    if obj.text ~= text then obj.text = text end
end)

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, _, name)
    if name ~= ADDON then return end
    SpeedBrokerDB = SpeedBrokerDB or { yards = false, showMode = true }
    db = SpeedBrokerDB
    frame:UnregisterEvent("ADDON_LOADED")
end)

obj.OnClick = function(_, button)
    if not db then return end
    if button == "RightButton" then
        db.showMode = not db.showMode
    else
        db.yards = not db.yards
    end
end

obj.OnTooltipShow = function(tt)
    local current, run, flight, swim = GetUnitSpeed("player")
    tt:AddLine("Speed")
    tt:AddDoubleLine("Mode", mode, 1, 1, 1, 1, 0.82, 0)
    tt:AddDoubleLine("Current", string.format("%d%%  (%.1f yd/s)", pct(current), current), 1, 1, 1, 1, 1, 1)
    tt:AddDoubleLine("Run", string.format("%d%%", pct(run)), 1, 1, 1, 1, 1, 1)
    tt:AddDoubleLine("Swim", string.format("%d%%", pct(swim)), 1, 1, 1, 1, 1, 1)
    tt:AddDoubleLine("Fly", string.format("%d%%", pct(flight)), 1, 1, 1, 1, 1, 1)
    tt:AddLine(" ")
    tt:AddLine("|cff00ff00Left-click|r: toggle % / yd/s", 0.8, 0.8, 0.8)
    tt:AddLine("|cff00ff00Right-click|r: toggle mode label", 0.8, 0.8, 0.8)
end
