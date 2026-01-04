--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--[[
    Translates either a sequence name (string) or an ACT_* enum (number) into a
    concrete sequence index for the owner's view model. Returns -1 if it fails.
    Supports both data-driven sequence strings and numeric ACT constants used by HL2 weapons.
]]
function SWEP:TranslateAnimation(anim)
    local owner = self:GetOwner()
    if ( !IsValid(owner) ) then return -1 end

    local vm = owner:GetViewModel()
    if ( !IsValid(vm) ) then return -1 end

    if ( isnumber(anim) ) then
        local seq = vm:SelectWeightedSequence(anim)
        if ( seq and seq >= 0 ) then
            return seq
        end
    elseif ( isstring(anim) ) then
        local seq = vm:LookupSequence(anim)
        if ( seq and seq >= 0 ) then
            return seq
        end
    elseif ( istable(anim) ) then
        local choice = anim[math.random(#anim)]
        return self:TranslateAnimation(choice)
    end

    return -1
end

--[[
    Plays an animation on the view model. Accepts either ACT_* enum (number) or sequence name.
    Falls back to SendWeaponAnim for ACT enums if direct sequence lookup fails, avoiding noisy errors.
]]
function SWEP:PlayAnimation(anim, rate)
    local owner = self:GetOwner()
    if ( !IsValid(owner) ) then return end

    local vm = owner:GetViewModel()
    if ( !IsValid(vm) ) then return end

    local seq = self:TranslateAnimation(anim)
    if ( seq and seq >= 0 ) then
        vm:SetPlaybackRate(rate or 1)
        vm:SendViewModelMatchingSequence(seq)
        return
    end

    if ( isnumber(anim) ) then
        self:SendWeaponAnim(anim)

        timer.Simple(0, function()
            if ( IsValid(self) ) then
                local vm2 = self:GetOwner():GetViewModel()
                if ( IsValid(vm2) ) then
                    vm2:SetPlaybackRate(rate or 1)
                end
            end
        end)

        return
    end

    -- Failed to play animation
    ax.util:PrintWarning("Failed to play animation: " .. tostring(anim))
    return
end

function SWEP:GetActiveAnimation()
    local vm = self:GetOwner():GetViewModel()
    if ( IsValid(vm) ) then
        return vm:GetSequenceName(vm:GetSequence())
    end

    return ""
end

function SWEP:GetActiveAnimationDuration()
    local vm = self:GetOwner():GetViewModel()
    if ( IsValid(vm) ) then
        return vm:SequenceDuration(vm:GetSequence())
    end

    return 0
end
