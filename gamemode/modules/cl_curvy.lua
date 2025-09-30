local MODULE = MODULE

MODULE.Name = "Curvy"
MODULE.Description = "Adds a curvy visual style to HUD elements."
MODULE.Author = "Riggs"

ax.option:Add("curvyCurveAmount", ax.type.number, 64, { category = "curvy", min = 16, max = 256, decimals = 0 })
ax.option:Add("curvySegments", ax.type.number, 256, { category = "curvy", min = 16, max = 256, decimals = 0 })
ax.option:Add("curvyDynamicLOD", ax.type.bool, true, { category = "curvy", description = "Automatically reduce curve segments when FPS is low.", noNetworking = true })

ax.curvy = ax.curvy or {}

local renderTargets = {}
local materials = {}
local meshCache = {}

-- Micro-optimizations: localize frequently-used globals
local math_sin = math.sin
local math_pi = math.pi
local Vector_local = Vector

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
    if ( meshCache[cacheKey] ) then
        return meshCache[cacheKey]
    end

    local meshData = {}
    -- Use locals for perf
    local seg = segments
    local ca = curveAmount
    local w = width
    local h = height
    for i = 0, seg - 1 do
        local u1 = i / seg
        local u2 = (i + 1) / seg
        local x1 = u1 * w
        local x2 = u2 * w

        local off1 = math_sin(u1 * math_pi) * ca
        local off2 = math_sin(u2 * math_pi) * ca

        local yT1 = off1
        local yT2 = off2
        local yB1 = h - off1
        local yB2 = h - off2

        -- Triangle 1
        meshData[#meshData + 1] = { pos = Vector_local(x1, yT1, 0), u = u1, v = 0 }
        meshData[#meshData + 1] = { pos = Vector_local(x2, yT2, 0), u = u2, v = 0 }
        meshData[#meshData + 1] = { pos = Vector_local(x2, yB2, 0), u = u2, v = 1 }

        -- Triangle 2
        meshData[#meshData + 1] = { pos = Vector_local(x1, yT1, 0), u = u1, v = 0 }
        meshData[#meshData + 1] = { pos = Vector_local(x2, yB2, 0), u = u2, v = 1 }
        meshData[#meshData + 1] = { pos = Vector_local(x1, yB1, 0), u = u1, v = 1 }
    end

    meshCache[cacheKey] = meshData
    return meshData
end

function ax.curvy:RenderCurvedMesh(mat, width, height)
    if ( !mat or mat:IsError() ) then return end

    -- Cache option lookups locally for this render call
    local baseSegments = ax.option:Get("curvySegments")
    local curveAmount = ax.option:Get("curvyCurveAmount")

    -- Dynamic LOD: scale segments down when FPS is low using a smoothed FPS estimate
    local segments = baseSegments
    if ( ax.option:Get("curvyDynamicLOD") ) then
        local ft = FrameTime() or 0.016
        local fps = 1 / math.max(0.0001, ft)
        self._fpsAvg = (self._fpsAvg or fps) * 0.92 + fps * 0.08

        -- If average FPS under 30, scale segments linearly down to minimum (16)
        if ( self._fpsAvg < 30 ) then
            local scale = math.max(0.1, self._fpsAvg / 30)
            segments = math.max(16, math.floor(baseSegments * scale))
        end
    end

    local meshData = self:GetCurveMesh(segments, curveAmount, width, height)

    cam.IgnoreZ(true)
    render.CullMode(MATERIAL_CULLMODE_CW)
    render.SetMaterial(mat)

    mesh.Begin(MATERIAL_TRIANGLES, #meshData)
        for i = 1, #meshData do
            local vertex = meshData[i]
            mesh.Position(vertex.pos)
            mesh.TexCoord(0, vertex.u, vertex.v)
            mesh.Color(255, 255, 255, 255)
            mesh.AdvanceVertex()
        end
    mesh.End()

    render.CullMode(MATERIAL_CULLMODE_CCW)
    cam.IgnoreZ(false)
end

function ax.curvy:RenderToTarget(rtName, width, height, drawFunc, ...)
    local texture = self:EnsureRenderTarget(rtName, width, height)

    render.PushRenderTarget(texture)
        render.Clear(0, 0, 0, 0, true, true)
        cam.Start2D()
            if ( drawFunc ) then
                drawFunc(...)
            end
        cam.End2D()
    render.PopRenderTarget()

    return texture
end

function ax.curvy:HUDPaintCurvy(drawFunc, rtName)
    local client = LocalPlayer()
    if ( hook.Run("HUDShouldDraw") == false ) then return end

    local width, height = ScrW(), ScrH()
    rtName = rtName or "main"

    -- Cheap mode: draw directly without curve
    if ( ax.option:Get("curvyCheap") ) then
        if ( drawFunc ) then
            drawFunc(width, height, client)
        end

        hook.Run("HUDPaintCurvy", width, height, client, false)
        return
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

    local width, height = ScrW(), ScrH()
    local rt = "post"

    -- Cheap mode: just run the hook and return
    if ( ax.option:Get("curvyCheap") ) then
        hook.Run("PostRenderCurvy", width, height, client, false)
        return
    end

    -- Render to target and draw with curve
    local texture = self:RenderToTarget(rt, width, height, function()
        hook.Run("PostRenderCurvy", width, height, client, true)
    end)

    local material = self:CreateRenderTargetMaterial(rt, texture)
    self:RenderCurvedMesh(material, width, height)
end

hook.Add("HUDPaint", "ax.curvy.HUDPaint", function()
    ax.curvy:HUDPaintCurvy()
end)

hook.Add("PostRenderVGUI", "ax.curvy.PostRender", function()
    ax.curvy:PostRender()
end)

hook.Add("OnScreenSizeChanged", "ax.curvy.ScreenResize", function()
    renderTargets = {}
    meshCache = {}
end)

hook.Add("OnReloaded", "ax.curvy.Cleanup", function()
    renderTargets = {}
    materials = {}
    meshCache = {}
end)