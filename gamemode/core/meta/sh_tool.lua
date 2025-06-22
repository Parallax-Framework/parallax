--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local TOOL = ax.tool or {}

function TOOL:Create()
    local tool = {}

    setmetatable(tool, self)
    self.__index = self

    tool.Mode           = nil
    tool.SWEP           = nil
    tool.Owner          = nil
    tool.ClientConVar   = {}
    tool.ServerConVar   = {}
    tool.Objects        = {}
    tool.Stage          = 0
    tool.Message        = "start"
    tool.LastMessage    = 0
    tool.AllowedCVar    = 0

    return tool
end

function TOOL:CreateConVars()
    local mode = self:GetMode()

    self.AllowedCVar   = CreateConVar("toolmode_allow_" .. mode, "1", { FCVAR_NOTIFY, FCVAR_REPLICATED }, "Set to 0 to disallow players being able to use the \"" .. mode .. "\" tool.")
    self.ClientConVars = {}
    self.ServerConVars = {}

    if ( CLIENT ) then
        for cvar, default in pairs(self.ClientConVar) do
            self.ClientConVars[cvar] = CreateClientConVar(mode .. "_" .. cvar, default, true, true, "Tool specific client setting (" .. mode .. ")")
        end
    else
        for cvar, default in pairs(self.ServerConVar) do
            self.ServerConVars[cvar] = CreateConVar(mode .. "_" .. cvar, default, FCVAR_ARCHIVE, "Tool specific server setting (" .. mode .. ")")
        end
    end
end

function TOOL:GetServerInfo(property)
    if ( self.ServerConVars[property] and SERVER ) then
        return self.ServerConVars[property]:GetString()
    end

    return GetConVarString(self:GetMode() .. "_" .. property)
end

function TOOL:GetClientInfo(property)
    if ( self.ClientConVars[property] and CLIENT ) then
        return self.ClientConVars[property]:GetString()
    end

    return self:GetOwner():GetInfo(self:GetMode() .. "_" .. property)
end

function TOOL:GetClientNumber(property, default)
    if ( self.ClientConVars[property] and CLIENT ) then
        return self.ClientConVars[property]:GetFloat()
    end

    return self:GetOwner():GetInfoNum(self:GetMode() .. "_" .. property, tonumber(default) or 0)
end

function TOOL:GetClientBool(property, default)
    if ( self.ClientConVars[property] and CLIENT ) then
        return self.ClientConVars[property]:GetBool()
    end

    return math.floor(self:GetOwner():GetInfoNum(self:GetMode() .. "_" .. property, tonumber(default) or 0)) != 0
end

function TOOL:BuildConVarList()
    local mode = self:GetMode()
    local convars = {}

    for k, v in pairs(self.ClientConVar) do
        convars[mode .. "_" .. k] = v
    end

    return convars
end

function TOOL:Allowed()
    return self.AllowedCVar:GetBool()
end

function TOOL:Init() end
function TOOL:GetMode()       return self.Mode end
function TOOL:GetWeapon()     return weapons.GetStored("gmod_tool") end
function TOOL:GetOwner()      return self:GetWeapon():GetOwner() or self.Owner end
function TOOL:GetSWEP()       return self:GetWeapon() end
function TOOL:LeftClick()     return false end
function TOOL:RightClick()    return false end
function TOOL:Reload()        self:ClearObjects() end
function TOOL:Deploy()        self:ReleaseGhostEntity() return end
function TOOL:Holster()       self:ReleaseGhostEntity() return end
function TOOL:Think()         self:ReleaseGhostEntity() end

function TOOL:CheckObjects()
    for _, v in pairs(self.Objects) do
        if ( !v.Ent:IsWorld() and !v.Ent:IsValid() ) then
            self:ClearObjects()
        end
    end
end

ax.tool = TOOL