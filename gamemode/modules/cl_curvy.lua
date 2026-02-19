--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

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
    ["option.curvy.edge_fade"] = "Edge Fade"
})

ax.localization:Register("ru", {
    ["category.visual"] = "Визуал",
    ["subcategory.curvy"] = "Изогнутость",
    ["option.curvy"] = "Изогнутый HUD",
    ["option.curvy.intensity"] = "Кривизна",
    ["option.curvy.edge_fade"] = "Исчезновение Краев"
})

ax.localization:Register("es", {
    ["category.visual"] = "Visual",
    ["subcategory.curvy"] = "Curvo",
    ["option.curvy"] = "HUD Curvo",
    ["option.curvy.intensity"] = "Curvatura",
    ["option.curvy.edge_fade"] = "Desvanecimiento de Bordes"
})

ax.curvy = ax.curvy or {}
ax.curvy.hud = ax.curvy.hud or nil
ax.curvy.mat = ax.curvy.mat or nil

local function RecreateMaterial()
    local scrW, scrH = ScrW(), ScrH()
    local name = "ax_curvy_rt_hud_" .. scrW .. "x" .. scrH

    ax.curvy.hud = GetRenderTargetEx(
        name,
        scrW,
        scrH,
        RT_SIZE_OFFSCREEN,
        MATERIAL_RT_DEPTH_SHARED,
        0, 0,
        IMAGE_FORMAT_RGBA8888
    )

    ax.curvy.mat = CreateMaterial(name, "screenspace_general", {
        ["$basetexture"] = name,

        ["$pixshader"] = "curvy_inverted_ps30",

        ["$ignorez"] = "1",
        ["$vertexcolor"] = "1",
        ["$vertextransform"] = "1",

        ["$copyalpha"] = "0",
        ["$alpha_blend_color_overlay"] = "0",
        ["$alpha_blend"] = "1",

        ["$linearwrite"] = "1",
        ["$linearread_basetexture"] = "1",
        ["$linearread_texture1"] = "1",
        ["$linearread_texture2"] = "1",
        ["$linearread_texture3"] = "1",
    })
end

function MODULE:OnSchemaLoaded()
    RecreateMaterial()
end

function MODULE:OnScreenSizeChanged()
    RecreateMaterial()
end

local function RenderCurvy(hookName)
    if ( !ax.option:Get("curvy") or ax.option:Get("curvy.intensity") <= 0 ) then
        hook.Run(hookName)
        return
    end

    if ( !ax.curvy.hud or !ax.curvy.mat ) then
        print("Curvy material or render target missing.")
        return
    end

    render.PushRenderTarget(ax.curvy.hud)
        render.Clear(0, 0, 0, 0, true, true)

        cam.Start2D()
            hook.Run(hookName)
        cam.End2D()
    render.PopRenderTarget()

    local w, h = ScrW(), ScrH()
    local aspect = w / h
    local intensity = ax.option:Get("curvy.intensity") / 10
    local edgeFade = ax.option:Get("curvy.edge_fade") / 10

    ax.curvy.mat:SetFloat("$c0_x", intensity)
    ax.curvy.mat:SetFloat("$c0_y", aspect)
    ax.curvy.mat:SetFloat("$c0_z", edgeFade)

    ax.curvy.mat:SetFloat("$c1_x", 1.0)
    ax.curvy.mat:SetFloat("$c1_y", 1.0)
    ax.curvy.mat:SetFloat("$c1_z", 1.0)
    ax.curvy.mat:SetFloat("$c1_w", 1.0)

    render.SetMaterial(ax.curvy.mat)
    render.DrawScreenQuad()
end

function MODULE:HUDPaint()
    RenderCurvy("HUDPaintCurvy")
end

function MODULE:PostRenderVGUI()
    RenderCurvy("PostRenderCurvy")
end
