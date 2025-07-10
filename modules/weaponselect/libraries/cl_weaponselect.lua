--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

if ( CLIENT ) then
    -- Animation library for weapon selection
    MODULE.Animation = MODULE.Animation or {}

    -- Easing functions for smooth animations
    MODULE.Animation.Ease = {
        Linear = function(t) return t end,

        InQuad = function(t) return t * t end,
        OutQuad = function(t) return t * (2 - t) end,
        InOutQuad = function(t) return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t end,

        InCubic = function(t) return t * t * t end,
        OutCubic = function(t) return (t - 1) * (t - 1) * (t - 1) + 1 end,
        InOutCubic = function(t) return t < 0.5 and 4 * t * t * t or (t - 1) * (2 * t - 2) * (2 * t - 2) + 1 end,

        InQuart = function(t) return t * t * t * t end,
        OutQuart = function(t) return 1 - (t - 1) * (t - 1) * (t - 1) * (t - 1) end,
        InOutQuart = function(t) return t < 0.5 and 8 * t * t * t * t or 1 - 8 * (t - 1) * (t - 1) * (t - 1) * (t - 1) end,

        InBack = function(t) return t * t * (2.7 * t - 1.7) end,
        OutBack = function(t) return 1 + (t - 1) * (t - 1) * (2.7 * (t - 1) + 1.7) end,
        InOutBack = function(t)
            if t < 0.5 then
                return 0.5 * (2 * t) * (2 * t) * (2.7 * 2 * t - 1.7)
            else
                return 0.5 * (2 + (2 * t - 2) * (2 * t - 2) * (2.7 * (2 * t - 2) + 1.7))
            end
        end,

        InBounce = function(t) return 1 - MODULE.Animation.Ease.OutBounce(1 - t) end,
        OutBounce = function(t)
            if t < 1 / 2.75 then
                return 7.5625 * t * t
            elseif t < 2 / 2.75 then
                return 7.5625 * (t - 1.5 / 2.75) * (t - 1.5 / 2.75) + 0.75
            elseif t < 2.5 / 2.75 then
                return 7.5625 * (t - 2.25 / 2.75) * (t - 2.25 / 2.75) + 0.9375
            else
                return 7.5625 * (t - 2.625 / 2.75) * (t - 2.625 / 2.75) + 0.984375
            end
        end,
        InOutBounce = function(t)
            if t < 0.5 then
                return MODULE.Animation.Ease.InBounce(t * 2) * 0.5
            else
                return MODULE.Animation.Ease.OutBounce(t * 2 - 1) * 0.5 + 0.5
            end
        end
    }

    -- Animation state manager
    MODULE.Animation.States = {}

    -- Create a new animation state
    function MODULE.Animation:CreateState(name, startValue, endValue, duration, easingFunction)
        self.States[name] = {
            startValue = startValue,
            endValue = endValue,
            currentValue = startValue,
            duration = duration,
            startTime = CurTime(),
            easingFunction = easingFunction or self.Ease.Linear,
            isActive = true,
            isReversed = false
        }
        return self.States[name]
    end

    -- Update animation state
    function MODULE.Animation:UpdateState(name)
        local state = self.States[name]
        if ( !state or !state.isActive ) then return state and state.currentValue or 0 end

        local currentTime = CurTime()
        local elapsedTime = currentTime - state.startTime
        local progress = math.Clamp(elapsedTime / state.duration, 0, 1)

        if ( state.isReversed ) then
            progress = 1 - progress
        end

        local easedProgress = state.easingFunction(progress)
        state.currentValue = Lerp(easedProgress, state.startValue, state.endValue)

        -- Check if animation is complete
        if ( progress >= 1 ) then
            state.isActive = false
            state.currentValue = state.isReversed and state.startValue or state.endValue
        end

        return state.currentValue
    end

    -- Reverse animation
    function MODULE.Animation:ReverseState(name)
        local state = self.States[name]
        if ( !state ) then return end

        state.isReversed = !state.isReversed
        state.startTime = CurTime()
        state.isActive = true

        -- Swap start and end values
        local temp = state.startValue
        state.startValue = state.endValue
        state.endValue = temp
    end

    -- Stop animation
    function MODULE.Animation:StopState(name)
        local state = self.States[name]
        if ( state ) then
            state.isActive = false
        end
    end

    -- Get current animation value
    function MODULE.Animation:GetValue(name)
        local state = self.States[name]
        if ( !state ) then return 0 end
        return state.currentValue
    end

    -- Check if animation is active
    function MODULE.Animation:IsActive(name)
        local state = self.States[name]
        return state and state.isActive or false
    end

    -- Get current easing function from options
    function MODULE.Animation:GetCurrentEasing()
        local easingName = ax.option:Get("weaponselect.animations.easing", "OutQuad")
        return self.Ease[easingName] or self.Ease.OutQuad
    end

    -- Weapon icon helper functions
    MODULE.WeaponIcons = MODULE.WeaponIcons or {}

    -- Default icon map for common weapons
    -- This can be extended with more icons as needed
    local iconMap = {
        ["ax_hands"] = "materials/gui/hand_human_left.png",
        ["gmod_camera"] = "materials/entities/gmod_camera.png",
        ["gmod_tool"] = "materials/entities/gmod_tool.png",
        ["weapon_357"] = "materials/entities/weapon_357.png",
        ["weapon_ar2"] = "materials/entities/weapon_ar2.png",
        ["weapon_crossbow"] = "materials/entities/weapon_crossbow.png",
        ["weapon_crowbar"] = "materials/entities/weapon_crowbar.png",
        ["weapon_physcannon"] = "materials/entities/weapon_physcannon.png",
        ["weapon_physgun"] = "materials/entities/weapon_physgun.png",
        ["weapon_pistol"] = "materials/entities/weapon_pistol.png",
        ["weapon_rpg"] = "materials/entities/weapon_rpg.png",
        ["weapon_shotgun"] = "materials/entities/weapon_shotgun.png",
        ["weapon_smg1"] = "materials/entities/weapon_smg1.png",
        ["weapon_stunstick"] = "materials/entities/weapon_stunstick.png"
    }

    -- Get weapon icon (placeholder for now, can be extended with actual icons)
    function MODULE.WeaponIcons:GetIcon(weapon)
        if ( !IsValid(weapon) ) then return nil end

        local class = weapon:GetClass()
        if ( !class or class == "" ) then return nil end

        -- Check if the weapon has a custom icon defined
        local iconPath = hook.Run("GetWeaponIcon", class)
        if ( iconPath and iconPath != "" ) then
            return ax.util:GetMaterial(iconPath)
        end

        -- Check the default icon map
        iconPath = iconMap[class]
        if ( iconPath and file.Exists(iconPath, "GAME") ) then
            return ax.util:GetMaterial(iconPath)
        end

        -- If no icon found, return a default icon
        return ax.util:GetMaterial("materials/gui/noicon.png")
    end

    -- Sound effects for weapon selection
    MODULE.Sounds = MODULE.Sounds or {}

    -- Play weapon selection sound
    function MODULE.Sounds:PlaySelection()
        if ( !ax.option:Get("weaponselect.sounds.enabled", true) ) then return end

        local volume = ax.option:Get("weaponselect.sounds.volume", 0.5)
        ax.client:EmitSound("ui/buttonrollover.wav", 75, 100, volume)
    end

    -- Play weapon switch sound
    function MODULE.Sounds:PlaySwitch()
        if ( !ax.option:Get("weaponselect.sounds.enabled", true) ) then return end

        local volume = ax.option:Get("weaponselect.sounds.volume", 0.5)
        ax.client:EmitSound("ui/buttonclick.wav", 75, 100, volume)
    end

    -- Play weapon select sound
    function MODULE.Sounds:PlaySelect()
        if ( !ax.option:Get("weaponselect.sounds.enabled", true) ) then return end

        local volume = ax.option:Get("weaponselect.sounds.volume", 0.5)
        ax.client:EmitSound("ui/buttonclickrelease.wav", 75, 100, volume)
    end

    -- Play error sound
    function MODULE.Sounds:PlayError()
        if ( !ax.option:Get("weaponselect.sounds.enabled", true) ) then return end

        local volume = ax.option:Get("weaponselect.sounds.volume", 0.5)
        ax.client:EmitSound("buttons/button10.wav", 75, 100, volume)
    end

    -- Particle effects for weapon selection
    MODULE.Particles = MODULE.Particles or {}
    MODULE.Particles.effects = MODULE.Particles.effects or {}

    -- Create selection particle effect
    function MODULE.Particles:CreateSelectionEffect(x, y, color)
        if ( !ax.option:Get("weaponselect.particles.enabled", true) ) then return end

        local effect = {
            x = x,
            y = y,
            color = color,
            alpha = 255,
            size = 1,
            life = 1,
            maxLife = 1,
            vel = Vector(math.random(-50, 50), math.random(-50, 50)),
            type = "selection"
        }

        table.insert(self.effects, effect)
    end

    -- Update particle effects
    function MODULE.Particles:Update(frameTime)
        for i = #self.effects, 1, -1 do
            local effect = self.effects[i]
            effect.life = effect.life - frameTime
            effect.alpha = (effect.life / effect.maxLife) * 255
            effect.size = effect.size + frameTime * 2
            effect.x = effect.x + effect.vel.x * frameTime
            effect.y = effect.y + effect.vel.y * frameTime

            if ( effect.life <= 0 ) then
                table.remove(self.effects, i)
            end
        end
    end

    -- Draw particle effects
    function MODULE.Particles:Draw()
        if ( !ax.option:Get("weaponselect.particles.enabled", true) ) then return end

        for _, effect in ipairs(self.effects) do
            if ( effect.type == "selection" ) then
                local color = ColorAlpha(effect.color, effect.alpha)
                draw.RoundedBox(0, effect.x - effect.size * 0.5, effect.y - effect.size * 0.5, effect.size, effect.size, color)
            end
        end
    end

    -- Utility functions
    MODULE.Util = MODULE.Util or {}

    -- Get weapon category
    function MODULE.Util:GetWeaponCategory(weapon)
        if ( !IsValid(weapon) ) then return "Unknown" end

        local class = weapon:GetClass()

        -- Categorize weapons
        if ( string.find(class, "pistol") or string.find(class, "357") ) then
            return "Pistols"
        elseif ( string.find(class, "smg") or string.find(class, "mp5") ) then
            return "SMGs"
        elseif ( string.find(class, "ar2") or string.find(class, "rifle") ) then
            return "Rifles"
        elseif ( string.find(class, "shotgun") ) then
            return "Shotguns"
        elseif ( string.find(class, "rpg") or string.find(class, "rocket") ) then
            return "Explosives"
        elseif ( string.find(class, "crowbar") or string.find(class, "stunstick") or string.find(class, "knife") ) then
            return "Melee"
        elseif ( string.find(class, "gmod") or string.find(class, "phys") ) then
            return "Tools"
        else
            return "Other"
        end
    end

    -- Get weapon rarity/tier
    function MODULE.Util:GetWeaponRarity(weapon)
        if ( !IsValid(weapon) ) then return 1 end

        -- This could be extended with actual weapon data
        local class = weapon:GetClass()

        if ( string.find(class, "crowbar") or string.find(class, "stunstick") ) then
            return 1 -- Common
        elseif ( string.find(class, "pistol") or string.find(class, "smg") ) then
            return 2 -- Uncommon
        elseif ( string.find(class, "shotgun") or string.find(class, "ar2") ) then
            return 3 -- Rare
        elseif ( string.find(class, "357") or string.find(class, "crossbow") ) then
            return 4 -- Epic
        elseif ( string.find(class, "rpg") ) then
            return 5 -- Legendary
        else
            return 1 -- Default to common
        end
    end
end
