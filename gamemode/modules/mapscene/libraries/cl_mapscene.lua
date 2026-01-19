--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Client-side map scene behavior.
-- @module ax.mapscene

ax.mapscene = ax.mapscene or {}
ax.mapscene.scenes = ax.mapscene.scenes or {}

ax.mapscene.state = ax.mapscene.state or {
    startTime = 0,
    finishTime = 0,
    startOrigin = nil,
    startAngles = nil,
    targetOrigin = nil,
    targetAngles = nil,
    currentOrigin = nil,
    currentAngles = nil,
    orderedIndex = 0,
    activeIndex = nil,
    preview = nil,
    mouseX = 0,
    mouseY = 0,
    pvsOrigin = nil,
    pvsLastSend = 0
}

--- Determine if map scenes should render.
-- @param client Player
-- @return boolean
function ax.mapscene:ShouldRenderMapScene(client)
    if ( !IsValid(client) ) then return false end
    if ( !IsValid(ax.gui.main) ) then return false end
    if ( self:GetCount() < 1 ) then return false end

    local can = hook.Run("ShouldRenderMapScene", client)
    if ( can == false ) then return false end

    return true
end

--- Reset scene transition state.
function ax.mapscene:ResetState()
    self.state.startTime = 0
    self.state.finishTime = 0
    self.state.startOrigin = nil
    self.state.startAngles = nil
    self.state.targetOrigin = nil
    self.state.targetAngles = nil
    self.state.currentOrigin = nil
    self.state.currentAngles = nil
    self.state.orderedIndex = 0
    self.state.activeIndex = nil
    self.state.mouseX = 0
    self.state.mouseY = 0
    self.state.pvsOrigin = nil
    self.state.pvsLastSend = 0
end

--- Apply a preview override.
-- @param identifier number|string|nil
function ax.mapscene:SetPreview(identifier)
    self.state.preview = identifier
    self:ResetState()
end

--- Clear preview override.
function ax.mapscene:ClearPreview()
    self.state.preview = nil
    self:ResetState()
end

--- Choose the next scene based on config.
-- @return table|nil, number|nil
function ax.mapscene:PickNextScene()
    local scenes = self.scenes
    if ( !istable(scenes) or #scenes < 1 ) then return nil end

    local order = ax.config:Get("map.scene.order", "random")
    local randomize = ax.config:Get("map.scene.randomize", true)

    if ( order == "ordered" or !randomize ) then
        self.state.orderedIndex = (self.state.orderedIndex or 0) + 1
        if ( self.state.orderedIndex > #scenes ) then
            self.state.orderedIndex = 1
        end

        return scenes[self.state.orderedIndex], self.state.orderedIndex
    end

    if ( order == "weighted" ) then
        local total = 0
        for i = 1, #scenes do
            total = total + (tonumber(scenes[i].weight) or 1)
        end

        if ( total <= 0 ) then
            local index = math.random(1, #scenes)
            return scenes[index], index
        end

        local roll = math.Rand(0, total)
        local running = 0
        for i = 1, #scenes do
            running = running + (tonumber(scenes[i].weight) or 1)
            if ( roll <= running ) then
                return scenes[i], i
            end
        end
    end

    local index = math.random(1, #scenes)
    return scenes[index], index
end

--- Start transitioning to a scene.
-- @param scene table
-- @param index number
function ax.mapscene:BeginScene(scene, index)
    local now = CurTime()
    local duration = ax.config:Get("map.scene.time", 30)

    self.state.startTime = now
    self.state.finishTime = now + duration
    self.state.activeIndex = index

    if ( self:IsPair(scene) ) then
        self.state.startOrigin = scene.origin
        self.state.startAngles = scene.angles
        self.state.targetOrigin = scene.origin2
        self.state.targetAngles = scene.angles2
        self.state.currentOrigin = scene.origin
        self.state.currentAngles = scene.angles
    else
        self.state.startOrigin = self.state.currentOrigin or scene.origin
        self.state.startAngles = self.state.currentAngles or scene.angles
        self.state.targetOrigin = scene.origin
        self.state.targetAngles = scene.angles
    end
end

local view = {}

--- Update and return the map scene view override.
-- @param client Player
-- @param patch table
-- @return table|nil
function ax.mapscene:ApplyView(client, patch)
    if ( !self:ShouldRenderMapScene(client) ) then
        self:SendPVS(nil)
        self:ResetState()
        return nil
    end

    local scene, index
    if ( self.state.preview ) then
        scene, index = self:ResolveScene(self.state.preview)
    elseif ( self.state.activeIndex ) then
        scene, index = self:ResolveScene(self.state.activeIndex)
    else
        scene, index = self:PickNextScene()
    end

    if ( !scene and !self.state.preview ) then
        self.state.activeIndex = nil
        scene, index = self:PickNextScene()
    end

    if ( !scene ) then
        return nil
    end

    if ( !self.state.activeIndex or self.state.activeIndex != index ) then
        self:BeginScene(scene, index)
    end

    local fraction = 1
    if ( self.state.finishTime > self.state.startTime ) then
        fraction = math.TimeFraction(self.state.startTime, self.state.finishTime, CurTime())
        fraction = math.Clamp(fraction, 0, 1)
    end

    local opts = {
        smooth = ax.config:Get("map.scene.smooth", 100),
        linear = ax.config:Get("map.scene.linear", false),
        transition = ax.config:Get("map.scene.transition", "lerp")
    }

    local realOrigin = ax.util:ApproachVector(fraction, self.state.startOrigin, self.state.targetOrigin, opts)
    local realAngles = ax.util:ApproachAngle(fraction, self.state.startAngles, self.state.targetAngles, opts)

    self.state.currentOrigin = realOrigin
    self.state.currentAngles = realAngles

    if ( fraction >= 1 and !self.state.preview ) then
        self.state.startTime = CurTime()
        self.state.finishTime = CurTime() + ax.config:Get("map.scene.time", 30)
        self.state.activeIndex = nil
        self:SendPVS(nil)

        if ( ax.config:Get("map.scene.snap", false) ) then
            self.state.currentOrigin = nil
            self.state.currentAngles = nil
        end
    end

    local strength = ax.config:Get("map.scene.strength", 6)
    local x, y = gui.MousePos()
    local x2, y2 = ScrW() * 0.5, ScrH() * 0.5

    if ( !ax.config:Get("map.scene.input", true) ) then
        x = 0
        y = 0
    end

    local targetX = math.Clamp((x - x2) / x2, -1, 1) * strength
    local targetY = math.Clamp((y - y2) / y2, -1, 1) * -strength

    local ft = FrameTime() * 0.5
    self.state.mouseX = ax.util:ApproachNumber(ft, self.state.mouseX or 0, targetX, opts)
    self.state.mouseY = ax.util:ApproachNumber(ft, self.state.mouseY or 0, targetY, opts)

    view.origin = realOrigin + realAngles:Up() * self.state.mouseY + realAngles:Right() * self.state.mouseX

    local rollMax = ax.config:Get("map.scene.roll", 0)
    local roll = 0
    if ( rollMax > 0 and strength > 0 ) then
        roll = (self.state.mouseX / strength) * rollMax
    end

    view.angles = realAngles + Angle(self.state.mouseY * -0.5, self.state.mouseX * -0.5, roll)
    view.fov = ax.util:ClampRound(ax.config:Get("map.scene.fov", 90), 0, 180, 0)

    self:SendPVS(realOrigin)

    return view
end

--- Send PVS origin to the server (or clear it).
-- @param origin Vector|nil
function ax.mapscene:SendPVS(origin, bForce)
    local minInterval = 0.5
    local minDistSqr = 256

    if ( origin == nil ) then
        if ( isvector(self.state.pvsOrigin) ) then
            ax.net:Start("mapscene.pvs")
            self.state.pvsOrigin = false
            self.state.pvsLastSend = CurTime()
        end

        return
    end

    if ( !self:IsValidVector(origin) ) then return end

    local now = CurTime()
    local distOk = !self.state.pvsOrigin or self.state.pvsOrigin:DistToSqr(origin) > minDistSqr
    local timeOk = (now - (self.state.pvsLastSend or 0)) >= minInterval

    if ( bForce or (distOk and timeOk) ) then
        ax.net:Start("mapscene.pvs", origin)
        self.state.pvsOrigin = origin
        self.state.pvsLastSend = now
    end
end
