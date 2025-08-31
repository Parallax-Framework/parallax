local MODULE = MODULE

MODULE.Name = "Curvy"
MODULE.Description = "Adds a curvy visual style to HUD elements."
MODULE.Author = "Riggs"

ax.option:Add("curvyCurveAmount", ax.type.number, 64, { category = "curvy", min = 16, max = 256, decimals = 0 })
ax.option:Add("curvySegments", ax.type.number, 256, { category = "curvy", min = 16, max = 256, decimals = 0 })

ax.curvy = ax.curvy or {}

local renderTargets = {}
local materials = {}
local meshCache = {}

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
    for i = 0, segments - 1 do
        local u1 = i / segments
        local u2 = (i + 1) / segments
        local x1, x2 = u1 * width, u2 * width

        local off1 = math.sin(u1 * math.pi) * curveAmount
        local off2 = math.sin(u2 * math.pi) * curveAmount

        local yT1, yT2 = 0 + off1, 0 + off2
        local yB1, yB2 = height - off1, height - off2

        -- Triangle 1
        table.insert(meshData, {
            pos = Vector(x1, yT1, 0),
            u = u1, v = 0
        })

        table.insert(meshData, {
            pos = Vector(x2, yT2, 0),
            u = u2, v = 0
        })

        table.insert(meshData, {
            pos = Vector(x2, yB2, 0),
            u = u2, v = 1
        })

        -- Triangle 2
        table.insert(meshData, {
            pos = Vector(x1, yT1, 0),
            u = u1, v = 0
        })

        table.insert(meshData, {
            pos = Vector(x2, yB2, 0),
            u = u2, v = 1
        })

        table.insert(meshData, {
            pos = Vector(x1, yB1, 0),
            u = u1, v = 1
        })
    end

    meshCache[cacheKey] = meshData
    return meshData
end

function ax.curvy:RenderCurvedMesh(mat, width, height)
    if ( !mat or mat:IsError() ) then return end

    local meshData = self:GetCurveMesh(ax.option:Get("curvySegments"), ax.option:Get("curvyCurveAmount"), width, height)

    cam.IgnoreZ(true)
    render.CullMode(MATERIAL_CULLMODE_CW)
    render.SetMaterial(mat)

    mesh.Begin(MATERIAL_TRIANGLES, #meshData)
        for _, vertex in ipairs(meshData) do
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

function ax.curvy:ShouldDrawCurvedHUD(client)
    if ( !IsValid(client) ) then return false end
    if ( client:GetViewEntity() != client ) then return false end
    if ( gui.IsGameUIVisible() ) then return false end

    local weapon = client:GetActiveWeapon()
    if ( IsValid(weapon) and weapon:GetClass() == "gmod_camera" ) then return false end

    return true
end

function ax.curvy:DrawCurvedHUD(drawFunc, rtName)
    local client = LocalPlayer()
    if ( !self:ShouldDrawCurvedHUD(client) ) then return end

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

hook.Add("HUDPaint", "ax.curvy.HUDPaint", function()
    ax.curvy:DrawCurvedHUD()
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