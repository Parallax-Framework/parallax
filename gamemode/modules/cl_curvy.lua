--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.name = "Curvy"
MODULE.description = "Adds a curvy visual style to HUD elements."
MODULE.author = "Riggs"

ax.option:Add("curvy", ax.type.bool, true, {
    category = "visual",
    subCategory = "curvy",
    description = "curvy.help"
})

ax.option:Add("curvy.intensity", ax.type.number, 64, {
    category = "visual",
    subCategory = "curvy",
    min = 0,
    max = 256,
    decimals = 0,
    description = "curvy.intensity.help"
})

ax.option:Add("curvy.segments", ax.type.number, 256, {
    category = "visual",
    subCategory = "curvy",
    min = 16,
    max = 512,
    decimals = 0,
    description = "curvy.segments.help"
})

ax.option:Add("curvy.dynamic.lod", ax.type.bool, true, {
    category = "visual",
    subCategory = "curvy",
    description = "curvy.dynamic.lod.help"
})

ax.option:Add("curvy.hud.only", ax.type.bool, false, {
    category = "visual",
    subCategory = "curvy",
    description = "curvy.hud.only.help"
})

ax.option:Add("curvy.intensity.scale", ax.type.number, 1.0, {
    category = "visual",
    subCategory = "curvy",
    min = 0.1,
    max = 2.0,
    decimals = 1,
    description = "curvy.intensity.scale.help"
})

ax.option:Add("curvy.frame.skip.threshold", ax.type.number, 30, {
    category = "visual",
    subCategory = "curvy",
    min = 15,
    max = 60,
    decimals = 0,
    description = "curvy.frame.skip.threshold.help"
})

ax.option:Add("curvy.frame.skip.enabled", ax.type.bool, true, {
    category = "visual",
    subCategory = "curvy",
    description = "curvy.frame.skip.enabled.help"
})

ax.option:Add("curvy.frame.skip.max", ax.type.number, 2, {
    category = "visual",
    subCategory = "curvy",
    min = 1,
    max = 5,
    decimals = 0,
    description = "curvy.frame.skip.max.help"
})

ax.option:Add("curvy.edges.deadzone", ax.type.number, 0.3, {
    category = "visual",
    subCategory = "curvy",
    min = 0.0,
    max = 0.5,
    decimals = 2,
    description = "curvy.edges.deadzone.help"
})

ax.localization:Register("en", {
    ["category.visual"] = "Visual",
    ["subcategory.curvy"] = "Curvy",
    ["option.curvy"] = "Enable Curvy Effect",
    ["option.curvy.help"] = "Enable or disable the curvy visual effect entirely.",
    ["option.curvy.intensity"] = "Curvy Intensity",
    ["option.curvy.intensity.help"] = "Controls how curved the screen appears. Higher values = more curve.",
    ["option.curvy.segments"] = "Curvy Segments",
    ["option.curvy.segments.help"] = "Number of segments used to create the curve. Higher = smoother but slower.",
    ["option.curvy.dynamic.lod"] = "Dynamic LOD",
    ["option.curvy.dynamic.lod.help"] = "Automatically reduce curve segments when FPS is low.",
    ["option.curvy.hud.only"] = "HUD Only Mode",
    ["option.curvy.hud.only.help"] = "Only apply curve effect to HUD elements, not post-render effects.",
    ["option.curvy.intensity.scale"] = "Curvy Intensity Scale",
    ["option.curvy.intensity.scale.help"] = "Global intensity multiplier for all curve effects.",
    ["option.curvy.frame.skip.threshold"] = "Frame Skip FPS Threshold",
    ["option.curvy.frame.skip.threshold.help"] = "FPS threshold below which frame skipping begins.",
    ["option.curvy.frame.skip.enabled"] = "Enable Frame Skipping",
    ["option.curvy.frame.skip.enabled.help"] = "Toggle whether the curvy module may skip frames to improve performance.",
    ["option.curvy.frame.skip.max"] = "Max Frame Skips",
    ["option.curvy.frame.skip.max.help"] = "Maximum number of frames to skip in a row when FPS is low.",
    ["option.curvy.edges.deadzone"] = "Edges Mode Deadzone",
    ["option.curvy.edges.deadzone.help"] = "Percentage of screen center that remains flat in 'edges' mode (0.0 = no flat area, 0.5 = half the screen is flat).",
})

ax.curvy = ax.curvy or {}

local renderTargets = {}
local materials = {}
local meshCache = {}
local meshObjects = {} -- Pre-built mesh objects
local meshLastUsed = {} -- Track mesh usage for cleanup
local MESH_CACHE_LIMIT = 48 -- Max distinct mesh variants kept
local MESH_CACHE_TTL = 1200 -- Frames before unused meshes are purged (approx ~20s at 60fps)
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
    edgesDeadzone = 0.3,
    lastUpdate = 0
}

-- Performance tracking
local perfStats = {
    fpsAvg = 60,
    lastFPSUpdate = 0,
    frameSkip = 0,
    frameSkipEnabled = true
}

-- Micro-optimizations: localize frequently-used globals
local CurTime_local = CurTime
local FrameTime_local = FrameTime
local ScrH_local = ScrH
local ScrW_local = ScrW
local Vector_local = Vector
local math_abs = math.abs
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local math_pi = math.pi
local math_pow = math.pow
local math_sin = math.sin

local function HasHookListeners(name)
    local hookTable = hook.GetTable()
    local listeners = hookTable and hookTable[name]

    if ( listeners and next(listeners) != nil ) then
        return true
    end

    local gm = GAMEMODE
    if ( !gm and gmod and gmod.GetGamemode ) then
        gm = gmod.GetGamemode()
    end

    if ( gm and gm[name] ) then
        return true
    end

    return false
end

local function QuantizeSegments(segments, baseSegments)
    -- Keep the mesh cache small by snapping segments to a fixed step
    -- This prevents dynamic LOD from generating hundreds of unique meshes over time
    local step = 16
    local quantized = math_floor((segments + step / 2) / step) * step

    quantized = math_max(16, quantized)

    if ( baseSegments ) then
        quantized = math_min(baseSegments, quantized)
    end

    return quantized
end

-- Update cached options only when necessary
function ax.curvy:UpdateOptions()
    local now = CurTime_local()
    if ( now - cachedOptions.lastUpdate < 0.1 ) then return end -- Update max 10x per second

    cachedOptions.enabled = ax.option:Get("curvy")
    cachedOptions.segments = ax.option:Get("curvy.segments")
    cachedOptions.curveAmount = ax.option:Get("curvy.intensity")
    cachedOptions.dynamicLOD = ax.option:Get("curvy.dynamic.lod")
    cachedOptions.hudOnly = ax.option:Get("curvy.hud.only")
    cachedOptions.intensityScale = ax.option:Get("curvy.intensity.scale")
    cachedOptions.frameSkipThreshold = ax.option:Get("curvy.frame.skip.threshold")
    cachedOptions.frameSkipEnabled = ax.option:Get("curvy.frame.skip.enabled")
    cachedOptions.maxFrameSkip = ax.option:Get("curvy.frame.skip.max")
    cachedOptions.edgesDeadzone = ax.option:Get("curvy.edges.deadzone")
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
    local scaledSegments = baseSegments * finalScale

    -- Snap to a small set of segment counts to avoid unbounded mesh variants
    return QuantizeSegments(scaledSegments, baseSegments)
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

--- Calculate curve offset based on mode
-- @param mode string Curve mode: "center", "edges", "inverted", "flat", "fisheye", "wave", "vignette", "astigmatism", "scanline", "thermal", "perspective"
local function CalculateCurveOffset(normalizedPos, curveAmount, mode, deadzone)
    if mode == "flat" then
        return 0
    elseif mode == "center" then
        -- Classic: bow outward in center (CRT bulge)
        return math_sin(normalizedPos * math_pi) * curveAmount
    elseif mode == "edges" then
        -- Old TV: flat center, curve at edges (barrel distortion)
        local edgeDist = math_abs(normalizedPos - 0.5) * 2 -- 0 at center, 1 at edges
        local dz = deadzone or 0.3
        local edgeFactor = math_max(0, (edgeDist - dz) / (1 - dz))
        -- Use quadratic for smoother falloff
        return math_pow(edgeFactor, 2) * curveAmount
    elseif mode == "inverted" then
        -- Inverted: bow inward in center (pincushion)
        return (1 - math_sin(normalizedPos * math_pi)) * curveAmount
    elseif mode == "fisheye" then
        -- Extreme barrel distortion (wide-angle lens effect)
        local centerDist = math_abs(normalizedPos - 0.5) * 2
        return math_pow(1 - centerDist, 2) * curveAmount * 2
    elseif mode == "wave" then
        -- Sinusoidal wave pattern (alternating bulge and pinch)
        return math_sin(normalizedPos * math_pi * 4) * curveAmount * 0.5
    elseif mode == "vignette" then
        -- Rounded corners effect (curves increase near edges)
        local edgeDist = math_abs(normalizedPos - 0.5) * 2
        return math_pow(edgeDist, 3) * curveAmount * 1.5
    elseif mode == "astigmatism" then
        -- Optical defect: asymmetric distortion (horizontal compression)
        local centerDist = math_abs(normalizedPos - 0.5)
        return math_sin(normalizedPos * math_pi) * curveAmount * (0.3 + centerDist * 0.7)
    elseif mode == "scanline" then
        -- CRT scanline warping: subtle horizontal bands with phase shift
        local phase = normalizedPos * math_pi * 2
        local scanlineEffect = math_sin(phase * 8) * 0.15
        return (math_sin(phase) + scanlineEffect) * curveAmount * 0.6
    elseif mode == "thermal" then
        -- Heat shimmer: subtle time-based wobble (uses CurTime for animation)
        local time = CurTime_local() * 0.5
        local wobble = math_sin(normalizedPos * math_pi * 3 + time) * 0.3
        wobble = wobble + math_sin(normalizedPos * math_pi * 7 - time * 1.3) * 0.15
        return wobble * curveAmount
    elseif mode == "perspective" then
        -- Trapezoidal distortion: viewing screen at an angle
        local trapezoid = math_pow(normalizedPos, 1.5) - math_pow(1 - normalizedPos, 1.5)
        return trapezoid * curveAmount * 0.8
    end

    return 0
end

function ax.curvy:GetCurveMesh(segments, curveAmount, width, height, mode)
    mode = mode or "center"
    local deadzone = cachedOptions.edgesDeadzone or 0.3

    local cacheKey = ("%d_%d_%d_%d_%s_%.2f"):format(segments, curveAmount, width, height, mode, deadzone)
    local frameCount = engine.TickCount()

    -- Return pre-built mesh object if available
    if ( meshObjects[cacheKey] ) then
        meshLastUsed[cacheKey] = frameCount
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
        meshLastUsed[cacheKey] = frameCount
        meshCache[cacheKey] = nil -- Free the vertex data
        self:CleanupMeshCache(frameCount)
        return meshObj
    end

    -- Generate new mesh data (optimized version)
    local meshData = {}
    local vertexCount = 0

    -- Pre-calculate values outside the loop
    local segFloat = segments
    local widthStep = width / segFloat

    for i = 0, segments - 1 do
        local u1 = i / segFloat
        local u2 = (i + 1) / segFloat
        local x1 = i * widthStep
        local x2 = (i + 1) * widthStep

        -- Calculate curve offset based on selected mode
        local off1 = CalculateCurveOffset(u1, curveAmount, mode, deadzone)
        local off2 = CalculateCurveOffset(u2, curveAmount, mode, deadzone)

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
    meshLastUsed[cacheKey] = frameCount
    self:CleanupMeshCache(frameCount)
    return meshObj
end

function ax.curvy:RenderCurvedMesh(mat, width, height, mode)
    if ( !mat or mat:IsError() ) then return end

    self:UpdateOptions()
    mode = mode or "center"
    local segments = self:GetOptimalSegments(width, height)
    local curveAmount = cachedOptions.curveAmount * cachedOptions.intensityScale

    local meshObj = self:GetCurveMesh(segments, curveAmount, width, height, mode)
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

-- Render mode configuration
local RENDER_MODES = {
    { mode = "center",   hookName = "HUDPaintCenter",   rtName = "center" },
    { mode = "edges",    hookName = "HUDPaintEdges",    rtName = "edges" },
    { mode = "inverted", hookName = "HUDPaintInverted", rtName = "inverted" },
    { mode = "fisheye",  hookName = "HUDPaintFisheye",  rtName = "fisheye" },
    { mode = "wave",     hookName = "HUDPaintWave",     rtName = "wave" },
    { mode = "vignette", hookName = "HUDPaintVignette", rtName = "vignette" },
    { mode = "astigmatism",  hookName = "HUDPaintAstigmatism",  rtName = "astigmatism" },
    { mode = "scanline",     hookName = "HUDPaintScanline",     rtName = "scanline" },
    { mode = "thermal",      hookName = "HUDPaintThermal",      rtName = "thermal" },
    { mode = "perspective",  hookName = "HUDPaintPerspective",  rtName = "perspective" },
}

local POST_RENDER_MODES = {
    { mode = "center",   hookName = "PostRenderCenter",   rtName = "post_center" },
    { mode = "edges",    hookName = "PostRenderEdges",    rtName = "post_edges" },
    { mode = "inverted", hookName = "PostRenderInverted", rtName = "post_inverted" },
    { mode = "fisheye",  hookName = "PostRenderFisheye",  rtName = "post_fisheye" },
    { mode = "wave",     hookName = "PostRenderWave",     rtName = "post_wave" },
    { mode = "vignette", hookName = "PostRenderVignette", rtName = "post_vignette" },
    { mode = "astigmatism",  hookName = "PostRenderAstigmatism",  rtName = "post_astigmatism" },
    { mode = "scanline",     hookName = "PostRenderScanline",     rtName = "post_scanline" },
    { mode = "thermal",      hookName = "PostRenderThermal",      rtName = "post_thermal" },
    { mode = "perspective",  hookName = "PostRenderPerspective",  rtName = "post_perspective" },
}

-- Internal render function for a specific mode
function ax.curvy:RenderMode(hookName, rtName, mode, width, height, client)
    -- Render to target
    local texture = self:RenderToTarget(rtName, width, height, function()
        hook.Run(hookName, width, height, client)
    end)

    -- Apply curve and draw
    local material = self:CreateRenderTargetMaterial(rtName, texture)
    self:RenderCurvedMesh(material, width, height, mode)
end

-- Optimized HUD rendering with smart frame skipping
function ax.curvy:HUDPaint()
    local client = LocalPlayer()
    if ( hook.Run("HUDShouldDraw") == false ) then return end

    self:UpdateOptions()

    local width, height = ScrW_local(), ScrH_local()

    -- Early exit if curvy is disabled
    if ( !cachedOptions.enabled ) then
        for _, modeData in ipairs(RENDER_MODES) do
            hook.Run(modeData.hookName, width, height, client)
        end

        return
    end

    -- Performance-based frame skipping with configurable threshold
    self:UpdatePerformanceStats()
    local threshold = cachedOptions.frameSkipThreshold
    local maxSkip = cachedOptions.maxFrameSkip

    if ( cachedOptions.frameSkipEnabled ) then
        if ( perfStats.fpsAvg < threshold ) then
            perfStats.frameSkip = (perfStats.frameSkip or 0) + 1
            if ( perfStats.frameSkip % maxSkip == 0 ) then return end -- Skip frames based on setting
        else
            perfStats.frameSkip = 0
        end
    end

    -- Render all modes
    for _, modeData in ipairs(RENDER_MODES) do
        self:RenderMode(modeData.hookName, modeData.rtName, modeData.mode, width, height, client)
    end
end

function ax.curvy:PostRender()
    local client = LocalPlayer()
    if ( hook.Run("HUDShouldDraw") == false ) then return end

    self:UpdateOptions()

    local width, height = ScrW_local(), ScrH_local()

    -- Early exit if curvy is disabled or HUD-only mode is enabled
    if ( !cachedOptions.enabled or cachedOptions.hudOnly ) then
        for _, modeData in ipairs(POST_RENDER_MODES) do
            hook.Run(modeData.hookName, width, height, client)
        end

        return
    end

    -- Performance-based frame skipping with configurable settings
    local threshold = cachedOptions.frameSkipThreshold
    local maxSkip = cachedOptions.maxFrameSkip

    if ( cachedOptions.frameSkipEnabled and perfStats.frameSkip and perfStats.frameSkip % maxSkip == 0 and perfStats.fpsAvg < threshold ) then
        return
    end

    -- Render all post-render modes
    for _, modeData in ipairs(POST_RENDER_MODES) do
        self:RenderMode(modeData.hookName, modeData.rtName, modeData.mode, width, height, client)
    end
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

-- Trim mesh cache to prevent unbounded memory growth during long sessions
function ax.curvy:CleanupMeshCache(frameCount)
    frameCount = frameCount or engine.TickCount()

    local cutoff = frameCount - MESH_CACHE_TTL
    local total = 0

    for _ in pairs(meshObjects) do
        total = total + 1
    end

    for key, lastUsed in pairs(meshLastUsed) do
        if ( lastUsed < cutoff or total > MESH_CACHE_LIMIT ) then
            local meshObj = meshObjects[key]

            if ( meshObj and meshObj.Destroy ) then
                meshObj:Destroy()
            end

            meshObjects[key] = nil
            meshLastUsed[key] = nil
            total = total - 1
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
        ax.curvy:CleanupMeshCache()
        lastCleanup = CurTime()
    end
end

function MODULE:OnScreenSizeChanged()
    renderTargets = {}
    meshCache = {}
    meshObjects = {}
    meshLastUsed = {}
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
    meshLastUsed = {}
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
    cachedOptions.edgesDeadzone = 0.3
    cachedOptions.lastUpdate = 0
    perfStats.fpsAvg = 60
    perfStats.lastFPSUpdate = 0
    perfStats.frameSkip = 0
end
