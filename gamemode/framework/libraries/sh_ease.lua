--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Easing functions for lerping values.
-- This module provides a set of easing functions to create smooth transitions between values.
-- It allows you to specify the type of easing function to use, such as "InQuad", "OutCubic", etc.
-- @module ax.ease

ax.ease = ax.ease or {}

local function AreAnimationsEnabled()
    if ( SERVER ) then
        return true
    end

    if ( !ax.option or !ax.option.Get ) then
        return true
    end

    return ax.option:Get("performance.animations", ax.option:Get("performanceAnimations", true)) == true
end

local function InterpolateValue(time, startValue, endValue)
    if ( isvector(startValue) and isvector(endValue) ) then
        return LerpVector(time, startValue, endValue)
    elseif ( isangle(startValue) and isangle(endValue) ) then
        return LerpAngle(time, startValue, endValue)
    elseif ( istable(startValue) and istable(endValue) ) then
        return {
            r = Lerp(time, startValue.r, endValue.r),
            g = Lerp(time, startValue.g, endValue.g),
            b = Lerp(time, startValue.b, endValue.b),
            a = Lerp(time, startValue.a or 255, endValue.a or 255)
        }
    else
        return Lerp(time, startValue, endValue)
    end
end

--- Internal mapping of available easing functions
ax.ease.list = {
    InBack = math.ease.InBack,
    InBounce = math.ease.InBounce,
    InCirc = math.ease.InCirc,
    InCubic = math.ease.InCubic,
    InElastic = math.ease.InElastic,
    InExpo = math.ease.InExpo,
    InOutBack = math.ease.InOutBack,
    InOutBounce = math.ease.InOutBounce,
    InOutCirc = math.ease.InOutCirc,
    InOutCubic = math.ease.InOutCubic,
    InOutElastic = math.ease.InOutElastic,
    InOutExpo = math.ease.InOutExpo,
    InOutQuad = math.ease.InOutQuad,
    InOutQuart = math.ease.InOutQuart,
    InOutQuint = math.ease.InOutQuint,
    InOutSine = math.ease.InOutSine,
    InQuad = math.ease.InQuad,
    InQuart = math.ease.InQuart,
    InQuint = math.ease.InQuint,
    InSine = math.ease.InSine,
    OutBack = math.ease.OutBack,
    OutBounce = math.ease.OutBounce,
    OutCirc = math.ease.OutCirc,
    OutCubic = math.ease.OutCubic,
    OutElastic = math.ease.OutElastic,
    OutExpo = math.ease.OutExpo,
    OutQuad = math.ease.OutQuad,
    OutQuart = math.ease.OutQuart,
    OutQuint = math.ease.OutQuint,
    OutSine = math.ease.OutSine
}

--- Lerp a value, color, vector, or angle using an easing function.
-- @realm shared
-- @param easeType The type of easing function to use (e.g., "InOutQuad")
-- @param time The time value (0 to 1) to interpolate between startValue and endValue.
-- @param startValue The starting value for the interpolation (number, color table, vector, or angle).
-- @param endValue The ending value for the interpolation (number, color table, vector, or angle).
-- @return The interpolated value based on the easing function.
function ax.ease:Lerp(easeType, time, startValue, endValue)
    if ( !isstring(easeType) ) then
        error("[easeLerp] easeType must be a string, got: " .. type(easeType))
    end

    if ( !isnumber(time) ) then
        error("[easeLerp] time must be a number, got: " .. type(time))
    end

    if ( startValue == nil or endValue == nil ) then
        error("[easeLerp] startValue and endValue must not be nil")
    end

    local animationsEnabled = AreAnimationsEnabled()
    if ( !animationsEnabled ) then
        time = 1
    end

    time = math.Clamp(time, 0, 1)

    if ( easeType == "Linear" or !animationsEnabled ) then
        return InterpolateValue(time, startValue, endValue)
    end

    local easeFunc = ax.ease.list[easeType]
    if ( !easeFunc ) then
        error("[easeLerp] Invalid easing type: " .. tostring(easeType))
    end

    local easedT = easeFunc(time)

    return InterpolateValue(easedT, startValue, endValue)
end
