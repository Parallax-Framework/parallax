--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.name = "Ammo Counter"
MODULE.description = "Displays a sleek ammo counter on the HUD with dynamic effects."
MODULE.author = "Riggs"

local ammoAlpha = 0
local lastAmmo = 0
local lastClip = 0
local shakeOffset = {x = 0, y = 0}
local shakeIntensity = 0
local lastFireTime = 0
local function UpdateShake()
    if ( shakeIntensity > 0 ) then
        shakeOffset.x = math.random(-shakeIntensity, shakeIntensity)
        shakeOffset.y = math.random(-shakeIntensity, shakeIntensity)
        shakeIntensity = math.max(0, shakeIntensity - FrameTime() * 30)
    else
        shakeOffset.x = Lerp(FrameTime() * 10, shakeOffset.x, 0)
        shakeOffset.y = Lerp(FrameTime() * 10, shakeOffset.y, 0)
    end
end

function MODULE:HUDPaintCurvy()
    local client = ax.client
    if ( !IsValid(client) or !client:Alive() ) then return end

    local shouldDraw = hook.Run("ShouldDrawWeaponAmmoCounter", client)
    if ( shouldDraw == false ) then return end

    local weapon = client:GetActiveWeapon()
    if ( !IsValid(weapon) ) then
        ammoAlpha = Lerp(FrameTime() * 8, ammoAlpha, 0)
        return
    end

    local clip1 = weapon:Clip1()
    local clip2 = weapon:Clip2()
    local ammo1 = client:GetAmmoCount(weapon:GetPrimaryAmmoType())
    local ammo2 = client:GetAmmoCount(weapon:GetSecondaryAmmoType())

    -- Check if weapon has ammo display
    local hasAmmo = (clip1 > -1 or ammo1 > 0) or (clip2 > -1 or ammo2 > 0)
    if ( !hasAmmo ) then
        ammoAlpha = Lerp(FrameTime() * 8, ammoAlpha, 0)
        return
    end

    -- Fade in ammo counter
    ammoAlpha = Lerp(FrameTime() * 8, ammoAlpha, 200)

    -- Detect weapon firing for shake effect
    if ( ( clip1 < lastClip and lastClip > 0 ) or ( ammo1 < lastAmmo and lastAmmo > 0 ) ) then
        shakeIntensity = 3
        lastFireTime = CurTime()
    end

    lastClip = clip1
    lastAmmo = ammo1

    UpdateShake()

    local scrW, scrH = ScrW(), ScrH()
    local baseX = scrW - ScreenScale(16) + shakeOffset.x
    local baseY = scrH - ScreenScaleH(16) + shakeOffset.y
    local offsetX = 0

    -- Get weapon info
    local weaponName = language.GetPhrase(weapon:GetPrintName()) or weapon:GetClass()
    weaponName = string.upper(weaponName)

    -- Darker, muted colors
    local weaponColor = Color(120, 120, 120, ammoAlpha * 0.8)
    local clipColor = Color(180, 180, 180, ammoAlpha)
    local reserveColor = Color(100, 100, 100, ammoAlpha * 0.7)
    local warningColor = Color(200, 80, 80, ammoAlpha)
    local lowAmmoColor = Color(180, 140, 60, ammoAlpha)

    -- Weapon name (smaller, muted)
    draw.SimpleText(weaponName, "ax.regular.bold.italic", baseX, baseY, weaponColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
    baseY = baseY - draw.GetFontHeight("ax.regular.bold.italic")

    -- Primary ammo display
    if ( clip1 > -1 or ammo1 > 0 ) then
        local clipText = clip1 > -1 and tostring(clip1) or "∞"

        -- Determine clip color based on ammo level
        local currentClipColor = clipColor
        if ( clip1 > -1 and weapon:GetMaxClip1() > 0 ) then
            local clipPercent = clip1 / weapon:GetMaxClip1()
            if ( clipPercent <= 0.25 ) then
                currentClipColor = warningColor
            elseif ( clipPercent <= 0.5 ) then
                currentClipColor = lowAmmoColor
            end
        end

        if ( ammo1 > 0 ) then
            offsetX = ax.util:GetTextWidth("ax.large", "/" .. tostring(ammo1)) + 5
        end

        -- Large clip count
        draw.SimpleText(clipText, "ax.huge.bold", baseX - offsetX, baseY + 5, currentClipColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)

        -- Reserve ammo (smaller, to the side)
        if ( ammo1 > 0 ) then
            draw.SimpleText("/" .. tostring(ammo1), "ax.large", baseX, baseY, reserveColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        end
    end

    -- Secondary ammo (if available)
    if ( clip2 > -1 or ammo2 > 0 ) then
        local clip2Text = clip2 > -1 and tostring(clip2) or "∞"
        local ammo2Text = ammo2 > 0 and ("/" .. tostring(ammo2)) or ""

        draw.SimpleText(clip2Text .. ammo2Text, "ax.regular.bold", baseX + ScreenScale(2), baseY, Color(100, 100, 100, ammoAlpha * 0.6), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    end

    -- Subtle firing flash effect
    local timeSinceFire = CurTime() - lastFireTime
    if ( timeSinceFire < 0.15 ) then
        local flashIntensity = math.max(0, (0.15 - timeSinceFire) / 0.15)
        local flashColor = Color(255, 255, 255, flashIntensity * 30)
        local clipText = clip1 > -1 and tostring(clip1) or "∞"

        -- Subtle glow effect around the numbers
        for i = 1, 3 do
            local offset = i * 2
            draw.SimpleText(clipText, "ax.huge.bold", baseX - offsetX + offset, baseY + 5, flashColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
            draw.SimpleText(clipText, "ax.huge.bold", baseX - offsetX - offset, baseY + 5, flashColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
            draw.SimpleText(clipText, "ax.huge.bold", baseX - offsetX, baseY + 5 + offset, flashColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
            draw.SimpleText(clipText, "ax.huge.bold", baseX - offsetX, baseY + 5 - offset, flashColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        end
    end
end
