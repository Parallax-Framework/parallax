--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

function SWEP:TranslateAnimation(anim)
    local vm = self:GetOwner():GetViewModel()
    if ( IsValid(vm) ) then
        local seq = vm:LookupSequence(anim)
        if ( seq >= 0 ) then
            return seq
        end
    end

    return -1
end

function SWEP:PlayAnimation(anim, rate)
    local vm = self:GetOwner():GetViewModel()
    if ( !IsValid(vm) ) then return end

    local seq = self:TranslateAnimation(anim)
    if ( seq and seq >= 0 ) then
        vm:SendViewModelMatchingSequence(seq)
        vm:SetPlaybackRate(rate or 1)
    else
        ax.util:PrintError("Invalid animation sequence: " .. tostring(anim))
    end
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