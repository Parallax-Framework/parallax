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

ax.mapscene.music = ax.mapscene.music or {
    channel = nil,
    path = nil,
    resolvedPath = nil,
    duration = 0,
    startTime = 0,
    volume = 0,
    fadeIn = 0,
    fadeOut = 0,
    loopDelay = 0,
    fadingIn = false,
    fadingOut = false,
    fadeStart = 0,
    fadeDuration = 0,
    fadeFrom = 0,
    currentVolume = 0,
    nextPlayTime = 0,
    lastEndTime = 0,
    bWasInScene = false,
    resolveId = 0,
    pendingResolveId = 0,
    pendingResolvedPath = nil
}

--- Determine if map scenes should render.
-- @param client Player
-- @return boolean
function ax.mapscene:ShouldRenderMapScene(client)
    if ( !ax.util:IsValidPlayer(client) ) then return false end
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

--- Normalize a music path string.
-- @param path any
-- @return string|nil
function ax.mapscene:NormalizeMusicPath(path)
    if ( !isstring(path) ) then return nil end

    path = string.Trim(path)
    if ( path == "" ) then return nil end

    if ( string.StartWith(path, "sound/") ) then
        return path
    end

    return "sound/" .. path
end

--- Resolve the active music path (supports overrides).
-- @param defaultPath string
-- @return string, boolean, boolean
function ax.mapscene:ResolveMusicPath(defaultPath)
    local resolveId = (self.music.resolveId or 0) + 1
    self.music.resolveId = resolveId
    self.music.pendingResolveId = resolveId
    self.music.pendingResolvedPath = nil
    ax.util:PrintDebug("[MAPSCENE] ResolveMusicPath called with default: " .. tostring(defaultPath))
    local override = hook.Run("GetMapSceneMusicPath", ax.client, defaultPath, self.music.path)
    if ( override == false ) then
        ax.util:PrintDebug("[MAPSCENE] Music disabled by hook (id=" .. tostring(resolveId) .. ")")
        return "", false, true
    end

    local path = defaultPath
    local bForce = false
    local paths = nil

    if ( istable(override) ) then
        if ( istable(override.paths) ) then
            paths = override.paths
        end

        if ( isstring(override.path) ) then
            path = override.path
        end

        if ( override.force != nil ) then
            bForce = tobool(override.force)
        elseif ( override.bForce != nil ) then
            bForce = tobool(override.bForce)
        end
    elseif ( isstring(override) ) then
        path = override
    end

    if ( istable(paths) and #paths > 0 ) then
        local pool = {}
        for i = 1, #paths do
            local candidate = tostring(paths[i] or "")
            candidate = string.Trim(candidate)
            if ( candidate != "" ) then
                pool[#pool + 1] = candidate
            end
        end

        if ( #pool > 0 ) then
            path = pool[math.random(#pool)]
        end
    end

    self.music.pendingResolvedPath = path
    return path, bForce, false
end

--- Get music duration in seconds.
-- @param path any
-- @return number
function ax.mapscene:GetMusicDuration(path)
    if ( !isstring(path) ) then return 0 end

    path = string.Trim(path)
    if ( path == "" ) then return 0 end

    if ( string.StartWith(path, "sound/") ) then
        path = string.sub(path, 7)
    end

    local duration = SoundDuration(path)
    if ( !isnumber(duration) or duration <= 0 ) then
        return 0
    end

    return duration
end

--- Set music volume and cache it.
-- @param volume number
function ax.mapscene:SetMusicVolume(volume)
    local music = self.music
    music.currentVolume = volume or 0

    if ( IsValid(music.channel) ) then
        music.channel:SetVolume(music.currentVolume)
    end
end

--- Stop map scene music.
-- @param fadeOut number
-- @param bForce boolean
function ax.mapscene:StopMusic(fadeOut, bForce)
    local music = self.music
    ax.util:PrintDebug("[MAPSCENE] StopMusic called (fadeOut=" .. tostring(fadeOut) .. ", force=" .. tostring(bForce) .. ")")

    if ( !IsValid(music.channel) ) then
        ax.util:PrintDebug("[MAPSCENE] No active music channel")
        music.fadingOut = false
        music.fadingIn = false
        return
    end

    fadeOut = math.max(tonumber(fadeOut) or 0, 0)

    if ( fadeOut > 0 and !bForce ) then
        if ( music.fadingOut ) then return end

        music.fadingOut = true
        music.fadingIn = false
        music.fadeStart = CurTime()
        music.fadeDuration = fadeOut
        music.fadeFrom = music.currentVolume or music.volume or 0
        return
    end

    music.channel:Stop()
    music.channel = nil
    music.fadingOut = false
    music.fadingIn = false
    music.currentVolume = 0
    music.lastEndTime = 0
    music.nextPlayTime = 0
    music.duration = 0
    music.startTime = 0
    music.resolvedPath = nil
    music.bWasInScene = false
    music.pendingResolveId = 0
    music.pendingResolvedPath = nil
end

--- Reset music state and stop playback.
function ax.mapscene:ResetMusic()
    self:StopMusic(0, true)

    local music = self.music
    music.path = nil
    music.nextPlayTime = 0
    music.lastEndTime = 0
    music.duration = 0
    music.startTime = 0
    music.resolvedPath = nil
    music.bWasInScene = false
    music.pendingResolveId = 0
    music.pendingResolvedPath = nil
end

--- Start map scene music.
-- @param path string
function ax.mapscene:StartMusic(path)
    local music = self.music
    local resolveId = music.pendingResolveId or music.resolveId or 0
    local pendingPath = music.pendingResolvedPath
    ax.util:PrintDebug("[MAPSCENE] StartMusic called (id=" .. tostring(resolveId) .. ") with path: " .. tostring(path))
    local normalized = self:NormalizeMusicPath(path)
    if ( !normalized ) then
        ax.util:PrintDebug("[MAPSCENE] Failed to normalize path")
        return
    end

    if ( isstring(pendingPath) and pendingPath != "" and pendingPath != path ) then
        ax.util:PrintDebug("[MAPSCENE] StartMusic path differs from pending (id=" .. tostring(resolveId) .. "): " .. tostring(pendingPath) .. " -> " .. tostring(path))
    elseif ( isstring(pendingPath) and pendingPath != "" ) then
        ax.util:PrintDebug("[MAPSCENE] Confirmed pending track (id=" .. tostring(resolveId) .. "): " .. tostring(pendingPath))
    end

    if ( IsValid(music.channel) ) then
        music.channel:Stop()
        music.channel = nil
    end

    local fadeIn = math.max(tonumber(music.fadeIn) or 0, 0)
    local volume = math.Clamp(tonumber(music.volume) or 0, 0, 1)

    music.fadingOut = false
    music.fadingIn = false
    music.fadeStart = 0
    music.fadeDuration = 0
    music.fadeFrom = 0
    music.lastEndTime = 0
    music.nextPlayTime = 0

    sound.PlayFile(normalized, "noplay", function(channel, errId, errName)
        if ( !IsValid(channel) ) then
            ax.util:PrintWarning("[MAPSCENE] Music file load failed: " .. tostring(errName or errId))
            return
        end
        ax.util:PrintDebug("[MAPSCENE] Music file loaded successfully (id=" .. tostring(resolveId) .. ")")

        if ( !self:ShouldPlayMusic(path) ) then
            channel:Stop()
            return
        end

        music.channel = channel
        music.path = path
        music.duration = self:GetMusicDuration(path)
        music.startTime = CurTime()
        ax.util:PrintDebug("[MAPSCENE] Music started (id=" .. tostring(resolveId) .. "): " .. tostring(path) .. " (" .. tostring(normalized) .. ", duration=" .. tostring(music.duration) .. "s)")
        music.pendingResolvedPath = nil

        if ( fadeIn > 0 ) then
            self:SetMusicVolume(0)
            music.fadingIn = true
            music.fadeStart = CurTime()
            music.fadeDuration = fadeIn
            music.fadeFrom = 0
        else
            self:SetMusicVolume(volume)
        end

        channel:Play()
    end)
end

--- Determine if music should currently play.
-- @param pathOverride string|nil
-- @return boolean
function ax.mapscene:ShouldPlayMusic(pathOverride)
    if ( !self:ShouldRenderMapScene(ax.client) ) then return false end

    local path = pathOverride
    if ( !isstring(path) or string.Trim(path) == "" ) then
        path = ax.config:Get("map.scene.music.path", "")
    end

    if ( !isstring(path) or string.Trim(path) == "" ) then return false end

    local volume = math.Clamp(tonumber(ax.config:Get("map.scene.music.volume", 0.5)) or 0, 0, 1)
    if ( volume <= 0 ) then return false end

    return true
end

--- Update fade-in/out transitions.
function ax.mapscene:UpdateMusicFades()
    local music = self.music
    if ( !IsValid(music.channel) ) then return end

    if ( music.fadingIn ) then
        local duration = math.max(tonumber(music.fadeDuration) or 0, 0)
        if ( duration <= 0 ) then
            music.fadingIn = false
            self:SetMusicVolume(music.volume or 0)
            return
        end

        local fraction = math.TimeFraction(music.fadeStart, music.fadeStart + duration, CurTime())
        fraction = math.Clamp(fraction, 0, 1)
        self:SetMusicVolume(Lerp(fraction, 0, music.volume or 0))

        if ( fraction >= 1 ) then
            music.fadingIn = false
        end
    elseif ( music.fadingOut ) then
        local duration = math.max(tonumber(music.fadeDuration) or 0, 0)
        if ( duration <= 0 ) then
            self:StopMusic(0, true)
            return
        end

        local fraction = math.TimeFraction(music.fadeStart, music.fadeStart + duration, CurTime())
        fraction = math.Clamp(fraction, 0, 1)
        self:SetMusicVolume(Lerp(fraction, music.fadeFrom or 0, 0))

        if ( fraction >= 1 ) then
            self:StopMusic(0, true)
        end
    end
end

--- Update music playback state.
function ax.mapscene:UpdateMusic()
    if ( !ax.client ) then return end

    local music = self.music
    local rawPath = ax.config:Get("map.scene.music.path", "")
    local volume = math.Clamp(tonumber(ax.config:Get("map.scene.music.volume", 0.5)) or 0, 0, 1)
    local loopDelay = math.max(tonumber(ax.config:Get("map.scene.music.loopDelay", 0)) or 0, 0)
    local fadeIn = math.max(tonumber(ax.config:Get("map.scene.music.fadeIn", 0)) or 0, 0)
    local fadeOut = math.max(tonumber(ax.config:Get("map.scene.music.fadeOut", 0)) or 0, 0)

    music.volume = volume
    music.loopDelay = loopDelay
    music.fadeIn = fadeIn
    music.fadeOut = fadeOut

    local resolvedCached = music.resolvedPath or ""
    local bResolveNeeded = rawPath != (music.path or "") or !isstring(resolvedCached) or string.Trim(resolvedCached) == ""

    local resolvedPath = resolvedCached
    local bForce = false
    local bDisabled = false

    if ( bResolveNeeded ) then
        resolvedPath, bForce, bDisabled = self:ResolveMusicPath(rawPath)
        music.resolvedPath = resolvedPath
        music.path = rawPath
    else
        resolvedPath = music.resolvedPath or ""
    end

    local bIsInScene = self:ShouldRenderMapScene(ax.client)
    local shouldPlay = bIsInScene and !bDisabled and self:ShouldPlayMusic(resolvedPath) and volume > 0
    local bExitFading = false

    if ( bIsInScene ) then
        music.bWasInScene = true
    else
        if ( music.bWasInScene ) then
            ax.util:PrintDebug("[MAPSCENE] Leaving map scene, fading out music")
            music.bWasInScene = false
            if ( IsValid(music.channel) and !music.fadingOut ) then
                self:StopMusic(fadeOut)
            end
            bExitFading = true
        end
    end

    if ( !shouldPlay ) then
        if ( music.fadingOut or bExitFading ) then
            self:UpdateMusicFades()
            return
        end

        if ( IsValid(music.channel) or music.fadingIn ) then
            self:StopMusic(fadeOut)
        end
        return
    end

    if ( bForce and isstring(resolvedPath) and string.Trim(resolvedPath) != "" ) then
        if ( !IsValid(music.channel) or music.resolvedPath != resolvedPath ) then
            self:StopMusic(0, true)
            music.nextPlayTime = 0
            music.lastEndTime = 0
            self:StartMusic(resolvedPath)
        end

        return
    end

    if ( music.resolvedPath != resolvedPath and IsValid(music.channel) ) then
        self:StopMusic(fadeOut, true)
        music.nextPlayTime = 0
        music.lastEndTime = 0
    end

    music.resolvedPath = resolvedPath

    if ( !IsValid(music.channel) ) then
        if ( (music.nextPlayTime or 0) <= CurTime() ) then
            if ( !isstring(resolvedPath) or string.Trim(resolvedPath) == "" ) then
                ax.util:PrintDebug("[MAPSCENE] Skipping StartMusic due to empty path")
                return
            end
            self:StartMusic(resolvedPath)
        end

        return
    end

    self:UpdateMusicFades()

    if ( !music.fadingIn and !music.fadingOut and music.currentVolume != volume ) then
        self:SetMusicVolume(volume)
    end

    if ( !music.fadingOut and IsValid(music.channel) ) then
        local duration = tonumber(music.duration) or 0
        if ( duration > 0 and (music.startTime or 0) > 0 and CurTime() >= (music.startTime + duration) ) then
            if ( music.lastEndTime == 0 ) then
                ax.util:PrintDebug("[MAPSCENE] Track finished, duration was " .. tostring(duration) .. "s")
                music.lastEndTime = CurTime()
                music.nextPlayTime = music.lastEndTime + loopDelay
                music.resolvedPath = nil
                ax.util:PrintDebug("[MAPSCENE] Next track in " .. tostring(loopDelay) .. "s")
            end

            if ( CurTime() >= (music.nextPlayTime or 0) ) then
                ax.util:PrintDebug("[MAPSCENE] Loop delay expired, resolving next track")
                resolvedPath, bForce, bDisabled = self:ResolveMusicPath(rawPath)
                if ( bDisabled or !isstring(resolvedPath) or string.Trim(resolvedPath) == "" ) then
                    ax.util:PrintDebug("[MAPSCENE] Loop resolve disabled or empty, stopping music")
                    self:StopMusic(fadeOut)
                    return
                end
                music.resolvedPath = resolvedPath
                music.lastEndTime = 0
                music.nextPlayTime = 0
                self:StartMusic(resolvedPath)
            end
        end
    end
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
