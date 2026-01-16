--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Check if gshaders addon is available before creating options
local gshaderLib = GetConVar("r_shaderlib")
if ( !gshaderLib ) then
    ax.util:PrintDebug("GShaders addon not detected, skipping shader options")
    return
end

-- Verify individual shader convars exist before creating options
local shaderConVars = {
    { name = "r_csm", option = "shaderCSM", desc = "Enable or disable cascaded shadow maps." },
    { name = "r_fxaa", option = "shaderFXAA", desc = "Enable or disable fast approximate anti-aliasing." },
    { name = "pp_pbb", option = "shaderPhysicallyBasedBloom", desc = "Enable or disable physically based bloom." },
    { name = "r_smaa", option = "shaderSMAA", desc = "Enable or disable subpixel morphological anti-aliasing." },
    { name = "pp_ssao_plus", option = "shaderSSAO", desc = "Enable or disable screen space ambient occlusion." },
    { name = "r_ssr", option = "shaderSSR", desc = "Enable or disable screen space local reflections." }
}

-- Only create options for convars that actually exist
for _, shader in ipairs(shaderConVars) do
    local convar = GetConVar(shader.name)
    if ( convar ) then
        ax.option:Add(shader.option, ax.type.bool, false, {
            category = "visual",
            subCategory = "shaders",
            description = shader.desc,
            bNoNetworking = true -- We don't need to network shader options
        })
        ax.util:PrintDebug("Created shader option: " .. shader.option .. " for convar: " .. shader.name)
    else
        ax.util:PrintWarning("Shader convar '" .. shader.name .. "' not found, skipping option '" .. shader.option .. "'")
    end
end
