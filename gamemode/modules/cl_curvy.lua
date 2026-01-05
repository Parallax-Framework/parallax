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
    description = "Enable or disable the curvy visual effect",
    category = "visual",
    subcategory = "curvy"
})

ax.option:Add("curvy.intensity", ax.type.number, 0.25, {
    description = "Controls the curvature strength",
    category = "visual",
    subcategory = "curvy",
    decimals = 2,
    min = 0.0,
    max = 1.0
})

ax.option:Add("curvy.edge_fade", ax.type.number, 0.25, {
    description = "Controls the edge fading effect",
    category = "visual",
    subcategory = "curvy",
    decimals = 2,
    min = 0.0,
    max = 1.0
})

ax.localization:Register("en", {
    ["category.visual"] = "Visual",
    ["subcategory.curvy"] = "Curvy",
    ["option.curvy"] = "Curvy HUD",
    ["option.curvy.intensity"] = "Curvature",
    ["option.curvy.edge_fade"] = "Edge Fade",
})

local rtName = "_rt_hudcurved"

local rtHud = GetRenderTargetEx(
    rtName,
    ScrW(),
    ScrH(),
    RT_SIZE_OFFSCREEN,
    MATERIAL_RT_DEPTH_SHARED,
    0, 0,
    IMAGE_FORMAT_RGBA8888
)

local curvyMaterial = CreateMaterial("ax_curvy", "screenspace_general", {
    ["$basetexture"] = rtName,
    ["$pixshader"] = "curvy_inverted_ps30",
    ["$ignorez"] = "1",
    ["$vertextransform"] = "1",
    ["$alphablend"] = "1",
    ["$cull"] = "0",
    ["$linearwrite"] = "1",
})

local function RenderCurvy(hookName)
    if ( !ax.option:Get("curvy") or ax.option:Get("curvy.intensity") <= 0 ) then
        hook.Run(hookName)
        return
    end

    render.PushRenderTarget(rtHud)
        render.Clear(0, 0, 0, 0, true, true)

        cam.Start2D()
            hook.Run(hookName)
        cam.End2D()
    render.PopRenderTarget()

    local w, h = ScrW(), ScrH()
    local aspect = w / h
    local intensity = ax.option:Get("curvy.intensity") / 10
    local edgeFade = ax.option:Get("curvy.edge_fade") / 10

    curvyMaterial:SetFloat("$c0_x", intensity)
    curvyMaterial:SetFloat("$c0_y", aspect)
    curvyMaterial:SetFloat("$c0_z", edgeFade)

    curvyMaterial:SetFloat("$c1_x", 1.0)
    curvyMaterial:SetFloat("$c1_y", 1.0)
    curvyMaterial:SetFloat("$c1_z", 1.0)
    curvyMaterial:SetFloat("$c1_w", 1.0)

    render.SetMaterial(curvyMaterial)
    render.DrawScreenQuad()
end

function MODULE:HUDPaint()
    RenderCurvy("HUDPaintCurvy")
end

function MODULE:PostRenderVGUI()
    RenderCurvy("PostRenderCurvy")
end
