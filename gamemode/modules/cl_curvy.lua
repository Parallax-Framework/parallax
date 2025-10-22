--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.Name = "Curvy"
MODULE.Description = "Adds a curvy visual style to HUD elements."
MODULE.Author = "Riggs"

ax.option:Add("curvyEnabled", ax.type.bool, true, { category = "visual", subCategory = "curvy", description = "Enable or disable the curvy visual effect entirely." })
ax.option:Add("curvyCurveAmount", ax.type.number, 64, { category = "visual", subCategory = "curvy", min = 0, max = 256, decimals = 0, description = "Controls how curved the screen appears. Higher values = more curve." })
ax.option:Add("curvySegments", ax.type.number, 256, { category = "visual", subCategory = "curvy", min = 16, max = 512, decimals = 0, description = "Number of segments used to create the curve. Higher = smoother but slower." })
ax.option:Add("curvyDynamicLOD", ax.type.bool, true, { category = "visual", subCategory = "curvy", description = "Automatically reduce curve segments when FPS is low." })
ax.option:Add("curvyHUDOnly", ax.type.bool, false, { category = "visual", subCategory = "curvy", description = "Only apply curve effect to HUD elements, not post-render effects." })
ax.option:Add("curvyIntensityScale", ax.type.number, 1.0, { category = "visual", subCategory = "curvy", min = 0.1, max = 2.0, decimals = 1, description = "Global intensity multiplier for all curve effects." })
ax.option:Add("curvyFrameSkipThreshold", ax.type.number, 30, { category = "visual", subCategory = "curvy", min = 15, max = 60, decimals = 0, description = "FPS threshold below which frame skipping begins." })
ax.option:Add("curvyMaxFrameSkip", ax.type.number, 2, { category = "visual", subCategory = "curvy", min = 1, max = 5, decimals = 0, description = "Maximum number of frames to skip in a row when FPS is low." })

ax.curvy = ax.curvy or {}

local renderTargets = {}
local materials = {}
local meshCache = {}
local meshObjects = {} -- Pre-built mesh objects
local renderCache = {} -- Frame-based render caching

-- Cached option values - updated only when changed
local cachedOptions = {
    enabled = true,
    segments = 256,
    curveAmount = 64,
    dynamicLOD = true,
    hudOnly = false,
    intensityScale = 1.0,
    frameSkipThreshold = 30,
    maxFrameSkip = 2,
    lastUpdate = 0
}

-- Performance tracking
local perfStats = {
    fpsAvg = 60,
    lastFPSUpdate = 0,
    frameSkip = 0
}

-- Micro-optimizations: localize frequently-used globals
local math_sin = math.sin
local math_pi = math.pi
local math_max = math.max
local math_min = math.min
local math_floor = math.floor
local Vector_local = Vector
local FrameTime_local = FrameTime
local CurTime_local = CurTime
local ScrW_local = ScrW
local ScrH_local = ScrH

-- Update cached options only when necessary
function ax.curvy:UpdateOptions()
    local now = CurTime_local()
    if ( now - cachedOptions.lastUpdate < 0.1 ) then return end -- Update max 10x per second

    cachedOptions.enabled = ax.option:Get("curvyEnabled")
    cachedOptions.segments = ax.option:Get("curvySegments")
    cachedOptions.curveAmount = ax.option:Get("curvyCurveAmount")
    cachedOptions.dynamicLOD = ax.option:Get("curvyDynamicLOD")
    cachedOptions.hudOnly = ax.option:Get("curvyHUDOnly")
    cachedOptions.intensityScale = ax.option:Get("curvyIntensityScale")
    cachedOptions.frameSkipThreshold = ax.option:Get("curvyFrameSkipThreshold")
    cachedOptions.maxFrameSkip = ax.option:Get("curvyMaxFrameSkip")
    cachedOptions.lastUpdate = now
end

-- Optimized FPS tracking with configurable thresholds
function ax.curvy:UpdatePerformanceStats()
    local now = CurTime_local()
    if ( now - perfStats.lastFPSUpdate < 0.2 ) then return end -- Update 5x per second

    local ft = FrameTime_local() or 0.016
    local fps = 1 / math_max(0.0001, ft)
    perfStats.fpsAvg = perfStats.fpsAvg * 0.85 + fps * 0.15
    perfStats.lastFPSUpdate = now
end

-- Get optimal segment count based on performance and viewport
function ax.curvy:GetOptimalSegments(width, height)
    self:UpdateOptions()
    self:UpdatePerformanceStats()

    local baseSegments = cachedOptions.segments

    if ( !cachedOptions.dynamicLOD ) then return baseSegments end

    -- Viewport-based LOD: reduce segments for larger viewports
    local pixelCount = width * height
    local basePixels = 1920 * 1080
    local viewportScale = math_min(1.0, basePixels / math_max(1, pixelCount))

    -- FPS-based LOD with configurable threshold
    local fpsScale = 1.0
    local threshold = cachedOptions.frameSkipThreshold
    if ( perfStats.fpsAvg < threshold ) then
        fpsScale = math_max(0.25, perfStats.fpsAvg / threshold)
    end

    local finalScale = math_min(viewportScale, fpsScale)
    return math_max(16, math_floor(baseSegments * finalScale))
end

function ax.curvy:LoadMaterial(path, filter)
    if ( !path or path == "" ) then return nil end

    local cacheKey = path .. (filter or "")
    if ( materials[cacheKey] ) then return materials[cacheKey] end

    local mat = Material(path, filter or "smooth")
    if ( mat:IsError() ) then return nil end

    materials[cacheKey] = mat

    return mat
end

function ax.curvy:DrawIcon(mat, x, y, size, col, alignX, alignY)
    if ( !mat or mat:IsError() ) then return end

    surface.SetMaterial(mat)
    surface.SetDrawColor(col or color_white)

    local width, height = size, size
    local ox, oy = 0, 0

    if ( alignX == TEXT_ALIGN_CENTER ) then
        ox = -width / 2
    elseif ( alignX == TEXT_ALIGN_RIGHT ) then
        ox = -width
    end

    if ( alignY == TEXT_ALIGN_CENTER ) then
        oy = -height / 2
    elseif ( alignY == TEXT_ALIGN_BOTTOM ) then
        oy = -height
    end

    surface.DrawTexturedRect(x + ox, y + oy, width, height)
end

function ax.curvy:EnsureRenderTarget(name, width, height)
    local rtName = ("ax_curvy_%s_%dx%d"):format(name, width, height)

    if ( renderTargets[rtName] and renderTargets[rtName].width == width and renderTargets[rtName].height == height ) then
        return renderTargets[rtName].texture
    end

    local texture = GetRenderTargetEx(
        rtName, width, height,
        RT_SIZE_OFFSCREEN,
        MATERIAL_RT_DEPTH_SHARED,
        0, 0,
        IMAGE_FORMAT_RGBA8888
    )

    renderTargets[rtName] = {
        texture = texture,
        width = width,
        height = height,
        name = rtName
    }

    return texture
end

function ax.curvy:CreateRenderTargetMaterial( name, texture )
    local matName = "ax_curvy_mat_" .. name

    if ( materials[matName] and !materials[matName]:IsError() ) then
        materials[matName]:SetTexture( "$basetexture", texture )
        return materials[matName]
    end

    local mat = CreateMaterial( matName, "UnlitGeneric", {
        ["$translucent"] = "1",
        ["$vertexalpha"] = "1",
        ["$vertexcolor"] = "1",
        ["$basetexture"] = texture:GetName(),
        ["$basetexturefiltermode"] = "0",
        ["$ignorez"] = "1",
        ["$nocull"] = "1"
    })

    materials[matName] = mat
    return mat
end

function ax.curvy:GetCurveMesh(segments, curveAmount, width, height)
    local cacheKey = ("%d_%d_%d_%d"):format(segments, curveAmount, width, height)

    -- Return pre-built mesh object if available
    if ( meshObjects[cacheKey] ) then
        return meshObjects[cacheKey]
    end

    -- Check for cached mesh data
    if ( meshCache[cacheKey] ) then
        -- Build mesh object from cached data
        local meshObj = Mesh()
        mesh.Begin(meshObj, MATERIAL_TRIANGLES, #meshCache[cacheKey])
            for i = 1, #meshCache[cacheKey] do
                local vertex = meshCache[cacheKey][i]
                mesh.Position(vertex.pos)
                mesh.TexCoord(0, vertex.u, vertex.v)
                mesh.Color(255, 255, 255, 255)
                mesh.AdvanceVertex()
            end
        mesh.End()

        meshObjects[cacheKey] = meshObj
        meshCache[cacheKey] = nil -- Free the vertex data
        return meshObj
    end

    -- Generate new mesh data (optimized version)
    local meshData = {}
    local vertexCount = 0

    -- Pre-calculate values outside the loop
    local segFloat = segments
    local widthStep = width / segFloat
    local piDivSeg = math_pi / segFloat

    for i = 0, segments - 1 do
        local u1 = i / segFloat
        local u2 = (i + 1) / segFloat
        local x1 = i * widthStep
        local x2 = (i + 1) * widthStep

        -- Use optimized sine calculation
        local off1 = math_sin(i * piDivSeg) * curveAmount
        local off2 = math_sin((i + 1) * piDivSeg) * curveAmount

        local yT1, yT2 = off1, off2
        local yB1, yB2 = height - off1, height - off2

        -- Pre-create vectors (reduced allocations)
        local v1 = Vector_local(x1, yT1, 0)
        local v2 = Vector_local(x2, yT2, 0)
        local v3 = Vector_local(x2, yB2, 0)
        local v4 = Vector_local(x1, yB1, 0)

        -- Triangle 1
        vertexCount = vertexCount + 1
        meshData[vertexCount] = { pos = v1, u = u1, v = 0 }
        vertexCount = vertexCount + 1
        meshData[vertexCount] = { pos = v2, u = u2, v = 0 }
        vertexCount = vertexCount + 1
        meshData[vertexCount] = { pos = v3, u = u2, v = 1 }

        -- Triangle 2
        vertexCount = vertexCount + 1
        meshData[vertexCount] = { pos = v1, u = u1, v = 0 }
        vertexCount = vertexCount + 1
        meshData[vertexCount] = { pos = v3, u = u2, v = 1 }
        vertexCount = vertexCount + 1
        meshData[vertexCount] = { pos = v4, u = u1, v = 1 }
    end

    -- Build mesh object immediately
    local meshObj = Mesh()
    mesh.Begin(meshObj, MATERIAL_TRIANGLES, vertexCount)
        for i = 1, vertexCount do
            local vertex = meshData[i]
            mesh.Position(vertex.pos)
            mesh.TexCoord(0, vertex.u, vertex.v)
            mesh.Color(255, 255, 255, 255)
            mesh.AdvanceVertex()
        end
    mesh.End()

    meshObjects[cacheKey] = meshObj
    return meshObj
end

function ax.curvy:RenderCurvedMesh(mat, width, height)
    if ( !mat or mat:IsError() ) then return end

    self:UpdateOptions()
    local segments = self:GetOptimalSegments(width, height)
    local curveAmount = cachedOptions.curveAmount * cachedOptions.intensityScale

    local meshObj = self:GetCurveMesh(segments, curveAmount, width, height)
    if ( !meshObj ) then return end

    cam.IgnoreZ(true)
    render.CullMode(MATERIAL_CULLMODE_CW)
    render.SetMaterial(mat)

    -- Draw the pre-built mesh object (much faster)
    meshObj:Draw()

    render.CullMode(MATERIAL_CULLMODE_CCW)
    cam.IgnoreZ(false)
end

function ax.curvy:RenderToTarget(rtName, width, height, drawFunc, ...)
    local frameCount = engine.TickCount()
    local cacheKey = rtName .. "_" .. width .. "_" .. height

    -- Skip if we already rendered this target this frame
    if ( renderCache[cacheKey] == frameCount ) then
        return self:EnsureRenderTarget(rtName, width, height)
    end

    local texture = self:EnsureRenderTarget(rtName, width, height)

    render.PushRenderTarget(texture)
        render.Clear(0, 0, 0, 0, true, true)
        cam.Start2D()
            if ( drawFunc ) then
                drawFunc(...)
            end
        cam.End2D()
    render.PopRenderTarget()

    renderCache[cacheKey] = frameCount
    return texture
end

-- Optimized HUD rendering with smart frame skipping
function ax.curvy:HUDPaint(drawFunc, rtName)
    local client = LocalPlayer()
    if ( hook.Run("HUDShouldDraw") == false ) then return end

    self:UpdateOptions()

    -- Early exit if curvy is disabled
    if ( !cachedOptions.enabled ) then
        if ( drawFunc ) then
            drawFunc(ScrW_local(), ScrH_local(), client)
        end

        hook.Run("HUDPaintCurvy", ScrW_local(), ScrH_local(), client, false)

        return
    end

    local width, height = ScrW_local(), ScrH_local()
    rtName = rtName or "main"

    -- Performance-based frame skipping with configurable threshold
    self:UpdatePerformanceStats()
    local threshold = cachedOptions.frameSkipThreshold
    local maxSkip = cachedOptions.maxFrameSkip

    if ( perfStats.fpsAvg < threshold ) then
        perfStats.frameSkip = (perfStats.frameSkip or 0) + 1
        if ( perfStats.frameSkip % maxSkip == 0 ) then return end -- Skip frames based on setting
    else
        perfStats.frameSkip = 0
    end

    -- Render to target and draw with curve
    local texture = self:RenderToTarget(rtName, width, height, function()
        if ( drawFunc ) then
            drawFunc(width, height, client)
        end

        hook.Run("HUDPaintCurvy", width, height, client, true)
    end)

    local material = self:CreateRenderTargetMaterial(rtName, texture)
    self:RenderCurvedMesh(material, width, height)
end

function ax.curvy:PostRender()
    local client = LocalPlayer()
    if ( hook.Run("HUDShouldDraw") == false ) then return end

    self:UpdateOptions()

    -- Early exit if curvy is disabled or HUD-only mode is enabled
    if ( !cachedOptions.enabled or cachedOptions.hudOnly ) then
        hook.Run("PostRenderCurvy", ScrW_local(), ScrH_local(), client, false)
        return
    end

    local width, height = ScrW_local(), ScrH_local()
    local rt = "post"

    -- Performance-based frame skipping with configurable settings
    local threshold = cachedOptions.frameSkipThreshold
    local maxSkip = cachedOptions.maxFrameSkip

    if ( perfStats.frameSkip and perfStats.frameSkip % maxSkip == 0 and perfStats.fpsAvg < threshold ) then
        return
    end

    -- Render to target and draw with curve
    local texture = self:RenderToTarget(rt, width, height, function()
        hook.Run("PostRenderCurvy", width, height, client, true)
    end)

    local material = self:CreateRenderTargetMaterial(rt, texture)
    self:RenderCurvedMesh(material, width, height)
end

-- Clean up old render cache entries
function ax.curvy:CleanupRenderCache()
    local frameCount = engine.TickCount()
    local cutoff = frameCount - 10 -- Keep last 10 frames

    for key, frame in pairs(renderCache) do
        if ( frame < cutoff ) then
            renderCache[key] = nil
        end
    end
end

-- Optimize material creation with better caching
function ax.curvy:CreateRenderTargetMaterial(name, texture)
    local matName = "ax_curvy_mat_" .. name

    if ( materials[matName] and !materials[matName]:IsError() ) then
        local mat = materials[matName]
        -- Only update texture if it's actually different
        if ( mat:GetTexture("$basetexture") != texture ) then
            mat:SetTexture("$basetexture", texture)
        end

        return mat
    end

    local mat = CreateMaterial(matName, "UnlitGeneric", {
        ["$translucent"] = "1",
        ["$vertexalpha"] = "1",
        ["$vertexcolor"] = "1",
        ["$basetexture"] = texture:GetName(),
        ["$basetexturefiltermode"] = "0",
        ["$ignorez"] = "1",
        ["$nocull"] = "1"
    })

    materials[matName] = mat
    return mat
end

-- Module hooks - automatically called by the framework's hook system

function MODULE:HUDPaint()
    ax.curvy:HUDPaint()
end

function MODULE:PostRenderVGUI()
    ax.curvy:PostRender()
end

-- Clean up render cache periodically
local lastCleanup = 0
function MODULE:Think()
    if ( CurTime() - lastCleanup > 10 ) then -- Every 10 seconds
        ax.curvy:CleanupRenderCache()
        lastCleanup = CurTime()
    end
end

function MODULE:OnScreenSizeChanged()
    renderTargets = {}
    meshCache = {}
    meshObjects = {}
    renderCache = {}
    perfStats.fpsAvg = 60 -- Reset performance tracking
end

function MODULE:OnReloaded()
    -- Destroy mesh objects properly from previous load
    for _, meshObj in pairs(meshObjects) do
        if ( meshObj and meshObj.Destroy ) then
            meshObj:Destroy()
        end
    end

    -- Clear all caches
    renderTargets = {}
    materials = {}
    meshCache = {}
    meshObjects = {}
    renderCache = {}

    -- Reset cached values
    cachedOptions.enabled = true
    cachedOptions.segments = 256
    cachedOptions.curveAmount = 64
    cachedOptions.dynamicLOD = true
    cachedOptions.hudOnly = false
    cachedOptions.intensityScale = 1.0
    cachedOptions.frameSkipThreshold = 30
    cachedOptions.maxFrameSkip = 2
    cachedOptions.lastUpdate = 0
    perfStats.fpsAvg = 60
    perfStats.lastFPSUpdate = 0
    perfStats.frameSkip = 0
end
