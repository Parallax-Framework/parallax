--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Check if gshaders addon is available before loading module functionality
local gshaderLib = GetConVar("r_shaderlib")
if ( !gshaderLib ) then
    ax.util:PrintDebug("GShaders addon not detected, skipping shader hooks")
    return
end

local MODULE = MODULE

-- Safely get convars with existence checks
local function GetSafeConVar(name)
    local cvar = GetConVar(name)
    if ( !cvar ) then
        ax.util:PrintWarning("Shader convar '" .. name .. "' not found")
    end

    return cvar
end

-- Localise convars with safety checks
local r_shaderlib = gshaderLib -- We already know this exists
local pp_ssao = GetSafeConVar("pp_ssao")
local r_smaa = GetSafeConVar("r_smaa")
local r_fxaa = GetSafeConVar("r_fxaa")
local pp_pbb = GetSafeConVar("pp_pbb")
local r_csm = GetSafeConVar("r_csm")

-- Helper function to safely set convar value
local function SafeSetConVar(cvar, value)
    if ( cvar ) then
        cvar:SetInt(value)
    end
end

function MODULE:OnOptionChanged(key, oldValue, newValue)
    -- Only proceed if we have valid shader options
    local ssao = ax.option:Get("shaderSSAO")
    local smaa = ax.option:Get("shaderSMAA")
    local fxaa = ax.option:Get("shaderFXAA")
    local bloom = ax.option:Get("shaderPhysicallyBasedBloom")
    local csm = ax.option:Get("shaderCSM")

    -- If none of the shaders are on, disable gshaders library
    if ( !ssao and !smaa and !fxaa and !bloom and !csm ) then
        SafeSetConVar(r_shaderlib, 0)
    else
        SafeSetConVar(r_shaderlib, 1)
    end

    -- Apply individual shader settings with safety checks
    if ( key == "shaderSSAO" ) then
        SafeSetConVar(pp_ssao, ssao and 1 or 0)
    elseif ( key == "shaderSMAA" ) then
        SafeSetConVar(r_smaa, smaa and 1 or 0)
    elseif ( key == "shaderFXAA" ) then
        SafeSetConVar(r_fxaa, fxaa and 1 or 0)
    elseif ( key == "shaderPhysicallyBasedBloom" ) then
        SafeSetConVar(pp_pbb, bloom and 1 or 0)
    elseif ( key == "shaderCSM" ) then
        SafeSetConVar(r_csm, csm and 1 or 0)
    end
end

function MODULE:OnOptionsLoaded()
    -- Only proceed if shader options exist (they might not if convars weren't found)
    local ssao = ax.option:Get("shaderSSAO")
    local smaa = ax.option:Get("shaderSMAA")
    local fxaa = ax.option:Get("shaderFXAA")
    local bloom = ax.option:Get("shaderPhysicallyBasedBloom")
    local csm = ax.option:Get("shaderCSM")

    -- If none of the shaders are on, disable gshaders library
    if ( !ssao and !smaa and !fxaa and !bloom and !csm ) then
        SafeSetConVar(r_shaderlib, 0)
    else
        SafeSetConVar(r_shaderlib, 1)
    end

    -- Apply all shader settings with safety checks
    SafeSetConVar(pp_ssao, ssao and 1 or 0)
    SafeSetConVar(r_smaa, smaa and 1 or 0)
    SafeSetConVar(r_fxaa, fxaa and 1 or 0)
    SafeSetConVar(pp_pbb, bloom and 1 or 0)
    SafeSetConVar(r_csm, csm and 1 or 0)
end