--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Fallback used when a character's model is missing or fails to load, so the preview is never an error model.
local FALLBACK_MODEL = "models/player/kleiner.mdl"

---@class ax.model : DModelPanel
--- A character model preview framed on the head and upper body. The stock `DModelPanel` lighting and camera are both replaced: the default framing points at the model origin, which puts a player model's feet in the middle of the panel.
local PANEL = {}

--- Initialises the preview with neutral lighting and no stock background.
---@realm client
function PANEL:Init()
    self:SetPaintBackground(false)
    self:SetFOV(36)
    self:SetAnimated(false)

    self.rotation = 0
    self.bRotating = false

    self:SetDirectionalLight(BOX_RIGHT, ax.color.raised)
    self:SetDirectionalLight(BOX_LEFT, ax.color.panel)
    self:SetDirectionalLight(BOX_FRONT, ax.color.textFaint)
    self:SetAmbientLight(Vector(0.28, 0.26, 0.32))
    self:SetColor(color_white)
end

--- Points the camera at the model's head and upper body rather than its origin.
---@realm client
function PANEL:FrameModel()
    local entity = self:GetEntity()
    if ( !IsValid(entity) ) then return end

    local mins, maxs = entity:GetRenderBounds()
    local height = maxs.z - mins.z
    local center = Vector(0, 0, mins.z + height * 0.82)

    self:SetLookAt(center)
    self:SetCamPos(center + Vector(height * 0.62, 0, 0))
end

--- Sets the previewed model, skin and bodygroups, then reframes the camera.
---@realm client
---@param model string Model path.
---@param skin? number Skin index. Defaults to 0.
---@param bodygroups? table Optional map of bodygroup index to value.
function PANEL:SetCharacterModel(model, skin, bodygroups)
    if ( !isstring(model) or model == "" or !util.IsValidModel(model) ) then
        model = FALLBACK_MODEL
    end

    self:SetModel(model)

    local entity = self:GetEntity()
    if ( !IsValid(entity) ) then return end

    entity:SetSkin(tonumber(skin) or 0)

    if ( istable(bodygroups) ) then
        for index, value in pairs(bodygroups) do
            local resolved = ax.util:ResolveBodygroupIndex(entity, index)
            if ( resolved ) then
                entity:SetBodygroup(resolved, value)
            end
        end
    end

    -- Stand the model in its idle pose instead of the T-pose the panel starts in.
    local sequence = entity:LookupSequence("idle_all_01")
    if ( sequence and sequence > 0 ) then
        entity:ResetSequence(sequence)
    end

    self:FrameModel()
end

--- Enables a slow turntable rotation.
---@realm client
---@param bRotating boolean Whether the model should turn.
function PANEL:SetRotating(bRotating)
    self.bRotating = bRotating and true or false
end

--- Overrides the stock layout so the framing survives a resize.
---@realm client
function PANEL:PerformLayout()
    self:FrameModel()
end

--- Applies the turntable rotation.
---@realm client
---@param entity Entity The previewed entity.
function PANEL:LayoutEntity(entity)
    if ( !IsValid(entity) ) then return end

    if ( self.bRotating ) then
        self.rotation = RealTime() * 12 % 360
    end

    entity:SetAngles(Angle(0, self.rotation + 45, 0))
end

vgui.Register("ax.model", PANEL, "DModelPanel")
