--[[
Copyright (c) 2025 Srlion (https://github.com/Srlion)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

if SERVER then
	AddCSLuaFile()
	return
end

local bit_band = bit.band
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRectUV = surface.DrawTexturedRectUV
local surface_DrawTexturedRect = surface.DrawTexturedRect
local render_CopyRenderTargetToTexture = render.CopyRenderTargetToTexture
local math_min = math.min
local math_max = math.max
local DisableClipping = DisableClipping
local type = type

local SHADERS_VERSION = "1759837522"
local SHADERS_GMA = [========[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]========]
do
	local DECODED_SHADERS_GMA = util.Base64Decode(SHADERS_GMA)
	if not DECODED_SHADERS_GMA or #DECODED_SHADERS_GMA == 0 then
		print("Failed to load shaders!") -- this shouldn't happen
		return
	end

	file.Write("rndx_shaders_" .. SHADERS_VERSION .. ".gma", DECODED_SHADERS_GMA)
	game.MountGMA("data/rndx_shaders_" .. SHADERS_VERSION .. ".gma")
end

local function GET_SHADER(name)
	return SHADERS_VERSION:gsub("%.", "_") .. "_" .. name
end

local BLUR_RT = GetRenderTargetEx("RNDX" .. SHADERS_VERSION .. SysTime(),
	1024, 1024,
	RT_SIZE_LITERAL,
	MATERIAL_RT_DEPTH_SEPARATE,
	bit.bor(2, 256, 4, 8 --[[4, 8 is clamp_s + clamp-t]]),
	0,
	IMAGE_FORMAT_BGRA8888
)

local NEW_FLAG; do
	local flags_n = -1
	function NEW_FLAG()
		flags_n = flags_n + 1
		return 2 ^ flags_n
	end
end

local NO_TL, NO_TR, NO_BL, NO_BR           = NEW_FLAG(), NEW_FLAG(), NEW_FLAG(), NEW_FLAG()

-- Svetov/Jaffies's great idea!
local SHAPE_CIRCLE, SHAPE_FIGMA, SHAPE_IOS = NEW_FLAG(), NEW_FLAG(), NEW_FLAG()

local BLUR                                 = NEW_FLAG()

local RNDX                                 = {}

local shader_mat                           = [==[
screenspace_general
{
	$pixshader ""
	$vertexshader ""

	$basetexture ""
	$texture1    ""
	$texture2    ""
	$texture3    ""

	// Mandatory, don't touch
	$ignorez            1
	$vertexcolor        1
	$vertextransform    1
	"<dx90"
	{
		$no_draw 1
	}

	$copyalpha                 0
	$alpha_blend_color_overlay 0
	$alpha_blend               1 // for AA
	$linearwrite               1 // to disable broken gamma correction for colors
	$linearread_basetexture    1 // to disable broken gamma correction for textures
	$linearread_texture1       1 // to disable broken gamma correction for textures
	$linearread_texture2       1 // to disable broken gamma correction for textures
	$linearread_texture3       1 // to disable broken gamma correction for textures
}
]==]

local MATRIXES                             = {}

local function create_shader_mat(name, opts)
	assert(name and isstring(name), "create_shader_mat: tex must be a string")

	local key_values = util.KeyValuesToTable(shader_mat, false, true)

	if opts then
		for k, v in pairs(opts) do
			key_values[k] = v
		end
	end

	local mat = CreateMaterial(
		"rndx_shaders1" .. name .. SysTime(),
		"screenspace_general",
		key_values
	)

	MATRIXES[mat] = Matrix()

	return mat
end

local ROUNDED_MAT = create_shader_mat("rounded", {
	["$pixshader"] = GET_SHADER("rndx_rounded_ps30"),
	["$vertexshader"] = GET_SHADER("rndx_vertex_vs30"),
})
local ROUNDED_TEXTURE_MAT = create_shader_mat("rounded_texture", {
	["$pixshader"] = GET_SHADER("rndx_rounded_ps30"),
	["$vertexshader"] = GET_SHADER("rndx_vertex_vs30"),
	["$basetexture"] = "loveyoumom", -- if there is no base texture, you can't change it later
})

local BLUR_VERTICAL = "$c0_x"
local ROUNDED_BLUR_MAT = create_shader_mat("blur_horizontal", {
	["$pixshader"] = GET_SHADER("rndx_rounded_blur_ps30"),
	["$vertexshader"] = GET_SHADER("rndx_vertex_vs30"),
	["$basetexture"] = BLUR_RT:GetName(),
	["$texture1"] = "_rt_FullFrameFB",
})

local SHADOWS_MAT = create_shader_mat("rounded_shadows", {
	["$pixshader"] = GET_SHADER("rndx_shadows_ps30"),
	["$vertexshader"] = GET_SHADER("rndx_vertex_vs30"),
})

local SHADOWS_BLUR_MAT = create_shader_mat("shadows_blur_horizontal", {
	["$pixshader"] = GET_SHADER("rndx_shadows_blur_ps30"),
	["$vertexshader"] = GET_SHADER("rndx_vertex_vs30"),
	["$basetexture"] = BLUR_RT:GetName(),
	["$texture1"] = "_rt_FullFrameFB",
})

local SHAPES = {
	[SHAPE_CIRCLE] = 2,
	[SHAPE_FIGMA] = 2.2,
	[SHAPE_IOS] = 4,
}
local DEFAULT_SHAPE = SHAPE_FIGMA

local MATERIAL_SetTexture = ROUNDED_MAT.SetTexture
local MATERIAL_SetMatrix = ROUNDED_MAT.SetMatrix
local MATERIAL_SetFloat = ROUNDED_MAT.SetFloat
local MATRIX_SetUnpacked = Matrix().SetUnpacked

local MAT
local X, Y, W, H
local TL, TR, BL, BR
local TEXTURE
local USING_BLUR, BLUR_INTENSITY
local COL_R, COL_G, COL_B, COL_A
local SHAPE, OUTLINE_THICKNESS
local START_ANGLE, END_ANGLE, ROTATION
local CLIP_PANEL
local SHADOW_ENABLED, SHADOW_SPREAD, SHADOW_INTENSITY
local function RESET_PARAMS()
	MAT = nil
	X, Y, W, H = 0, 0, 0, 0
	TL, TR, BL, BR = 0, 0, 0, 0
	TEXTURE = nil
	USING_BLUR, BLUR_INTENSITY = false, 1.0
	COL_R, COL_G, COL_B, COL_A = 255, 255, 255, 255
	SHAPE, OUTLINE_THICKNESS = SHAPES[DEFAULT_SHAPE], -1
	START_ANGLE, END_ANGLE, ROTATION = 0, 360, 0
	CLIP_PANEL = nil
	SHADOW_ENABLED, SHADOW_SPREAD, SHADOW_INTENSITY = false, 0, 0
end

local normalize_corner_radii; do
	local HUGE = math.huge

	local function nzr(x)
		if x ~= x or x < 0 then return 0 end
		local lim = math_min(W, H)
		if x == HUGE then return lim end
		return x
	end

	local function clamp0(x) return x < 0 and 0 or x end

	function normalize_corner_radii()
		local TL, TR, BL, BR = nzr(TL), nzr(TR), nzr(BL), nzr(BR)

		local k = math_max(
			1,
			(TL + TR) / W,
			(BL + BR) / W,
			(TL + BL) / H,
			(TR + BR) / H
		)

		if k > 1 then
			local inv = 1 / k
			TL, TR, BL, BR = TL * inv, TR * inv, BL * inv, BR * inv
		end

		return clamp0(TL), clamp0(TR), clamp0(BL), clamp0(BR)
	end
end

local function SetupDraw()
	local TL, TR, BL, BR = normalize_corner_radii()

	local matrix = MATRIXES[MAT]
	MATRIX_SetUnpacked(
		matrix,

		BL, W, OUTLINE_THICKNESS or -1, END_ANGLE,
		BR, H, SHADOW_INTENSITY, ROTATION,
		TR, SHAPE, BLUR_INTENSITY or 1.0, 0,
		TL, TEXTURE and 1 or 0, START_ANGLE, 0
	)
	MATERIAL_SetMatrix(MAT, "$viewprojmat", matrix)

	if COL_R then
		surface_SetDrawColor(COL_R, COL_G, COL_B, COL_A)
	end

	surface_SetMaterial(MAT)
end

local MANUAL_COLOR = NEW_FLAG()
local DEFAULT_DRAW_FLAGS = DEFAULT_SHAPE

local function draw_rounded(x, y, w, h, col, flags, tl, tr, bl, br, texture, thickness)
	if col and col.a == 0 then
		return
	end

	RESET_PARAMS()

	if not flags then
		flags = DEFAULT_DRAW_FLAGS
	end

	local using_blur = bit_band(flags, BLUR) ~= 0
	if using_blur then
		return RNDX.DrawBlur(x, y, w, h, flags, tl, tr, bl, br, thickness)
	end

	MAT = ROUNDED_MAT; if texture then
		MAT = ROUNDED_TEXTURE_MAT
		MATERIAL_SetTexture(MAT, "$basetexture", texture)
		TEXTURE = texture
	end

	W, H = w, h
	TL, TR, BL, BR = bit_band(flags, NO_TL) == 0 and tl or 0,
		bit_band(flags, NO_TR) == 0 and tr or 0,
		bit_band(flags, NO_BL) == 0 and bl or 0,
		bit_band(flags, NO_BR) == 0 and br or 0
	SHAPE = SHAPES[bit_band(flags, SHAPE_CIRCLE + SHAPE_FIGMA + SHAPE_IOS)] or SHAPES[DEFAULT_SHAPE]
	OUTLINE_THICKNESS = thickness

	if bit_band(flags, MANUAL_COLOR) ~= 0 then
		COL_R = nil
	elseif col then
		COL_R, COL_G, COL_B, COL_A = col.r, col.g, col.b, col.a
	else
		COL_R, COL_G, COL_B, COL_A = 255, 255, 255, 255
	end

	SetupDraw()

	-- https://github.com/Jaffies/rboxes/blob/main/rboxes.lua
	-- fixes setting $basetexture to ""(none) not working correctly
	return surface_DrawTexturedRectUV(x, y, w, h, -0.015625, -0.015625, 1.015625, 1.015625)
end

function RNDX.Draw(r, x, y, w, h, col, flags)
	return draw_rounded(x, y, w, h, col, flags, r, r, r, r)
end

function RNDX.DrawOutlined(r, x, y, w, h, col, thickness, flags)
	return draw_rounded(x, y, w, h, col, flags, r, r, r, r, nil, thickness or 1)
end

function RNDX.DrawTexture(r, x, y, w, h, col, texture, flags)
	return draw_rounded(x, y, w, h, col, flags, r, r, r, r, texture)
end

function RNDX.DrawMaterial(r, x, y, w, h, col, mat, flags)
	local tex = mat:GetTexture("$basetexture")
	if tex then
		return RNDX.DrawTexture(r, x, y, w, h, col, tex, flags)
	end
end

function RNDX.DrawCircle(x, y, r, col, flags)
	return RNDX.Draw(r / 2, x - r / 2, y - r / 2, r, r, col, (flags or 0) + SHAPE_CIRCLE)
end

function RNDX.DrawCircleOutlined(x, y, r, col, thickness, flags)
	return RNDX.DrawOutlined(r / 2, x - r / 2, y - r / 2, r, r, col, thickness, (flags or 0) + SHAPE_CIRCLE)
end

function RNDX.DrawCircleTexture(x, y, r, col, texture, flags)
	return RNDX.DrawTexture(r / 2, x - r / 2, y - r / 2, r, r, col, texture, (flags or 0) + SHAPE_CIRCLE)
end

function RNDX.DrawCircleMaterial(x, y, r, col, mat, flags)
	return RNDX.DrawMaterial(r / 2, x - r / 2, y - r / 2, r, r, col, mat, (flags or 0) + SHAPE_CIRCLE)
end

local USE_SHADOWS_BLUR = false

local function draw_blur()
	if USE_SHADOWS_BLUR then
		MAT = SHADOWS_BLUR_MAT
	else
		MAT = ROUNDED_BLUR_MAT
	end

	COL_R, COL_G, COL_B, COL_A = 255, 255, 255, 255
	SetupDraw()

	render_CopyRenderTargetToTexture(BLUR_RT)
	MATERIAL_SetFloat(MAT, BLUR_VERTICAL, 0)
	surface_DrawTexturedRect(X, Y, W, H)

	render_CopyRenderTargetToTexture(BLUR_RT)
	MATERIAL_SetFloat(MAT, BLUR_VERTICAL, 1)
	surface_DrawTexturedRect(X, Y, W, H)
end

function RNDX.DrawBlur(x, y, w, h, flags, tl, tr, bl, br, thickness)
	RESET_PARAMS()

	if not flags then
		flags = DEFAULT_DRAW_FLAGS
	end

	X, Y = x, y
	W, H = w, h
	TL, TR, BL, BR = bit_band(flags, NO_TL) == 0 and tl or 0,
		bit_band(flags, NO_TR) == 0 and tr or 0,
		bit_band(flags, NO_BL) == 0 and bl or 0,
		bit_band(flags, NO_BR) == 0 and br or 0
	SHAPE = SHAPES[bit_band(flags, SHAPE_CIRCLE + SHAPE_FIGMA + SHAPE_IOS)] or SHAPES[DEFAULT_SHAPE]
	OUTLINE_THICKNESS = thickness

	draw_blur()
end

local function setup_shadows()
	X = X - SHADOW_SPREAD
	Y = Y - SHADOW_SPREAD
	W = W + (SHADOW_SPREAD * 2)
	H = H + (SHADOW_SPREAD * 2)

	TL = TL + (SHADOW_SPREAD * 2)
	TR = TR + (SHADOW_SPREAD * 2)
	BL = BL + (SHADOW_SPREAD * 2)
	BR = BR + (SHADOW_SPREAD * 2)
end

local function draw_shadows(r, g, b, a)
	if USING_BLUR then
		USE_SHADOWS_BLUR = true
		draw_blur()
		USE_SHADOWS_BLUR = false
	end

	MAT = SHADOWS_MAT

	if r == false then
		COL_R = nil
	else
		COL_R, COL_G, COL_B, COL_A = r, g, b, a
	end

	SetupDraw()
	-- https://github.com/Jaffies/rboxes/blob/main/rboxes.lua
	-- fixes having no $basetexture causing uv to be broken
	surface_DrawTexturedRectUV(X, Y, W, H, -0.015625, -0.015625, 1.015625, 1.015625)
end

function RNDX.DrawShadowsEx(x, y, w, h, col, flags, tl, tr, bl, br, spread, intensity, thickness)
	if col and col.a == 0 then
		return
	end

	local OLD_CLIPPING_STATE = DisableClipping(true)

	RESET_PARAMS()

	if not flags then
		flags = DEFAULT_DRAW_FLAGS
	end

	X, Y = x, y
	W, H = w, h
	SHADOW_SPREAD = spread or 30
	SHADOW_INTENSITY = intensity or SHADOW_SPREAD * 1.2

	TL, TR, BL, BR = bit_band(flags, NO_TL) == 0 and tl or 0,
		bit_band(flags, NO_TR) == 0 and tr or 0,
		bit_band(flags, NO_BL) == 0 and bl or 0,
		bit_band(flags, NO_BR) == 0 and br or 0

	SHAPE = SHAPES[bit_band(flags, SHAPE_CIRCLE + SHAPE_FIGMA + SHAPE_IOS)] or SHAPES[DEFAULT_SHAPE]

	OUTLINE_THICKNESS = thickness

	setup_shadows()

	USING_BLUR = bit_band(flags, BLUR) ~= 0

	if bit_band(flags, MANUAL_COLOR) ~= 0 then
		draw_shadows(false, nil, nil, nil)
	elseif col then
		draw_shadows(col.r, col.g, col.b, col.a)
	else
		draw_shadows(0, 0, 0, 255)
	end

	DisableClipping(OLD_CLIPPING_STATE)
end

function RNDX.DrawShadows(r, x, y, w, h, col, spread, intensity, flags)
	return RNDX.DrawShadowsEx(x, y, w, h, col, flags, r, r, r, r, spread, intensity)
end

function RNDX.DrawShadowsOutlined(r, x, y, w, h, col, thickness, spread, intensity, flags)
	return RNDX.DrawShadowsEx(x, y, w, h, col, flags, r, r, r, r, spread, intensity, thickness or 1)
end

local BASE_FUNCS; BASE_FUNCS = {
	Rad = function(self, rad)
		TL, TR, BL, BR = rad, rad, rad, rad
		return self
	end,
	Radii = function(self, tl, tr, bl, br)
		TL, TR, BL, BR = tl or 0, tr or 0, bl or 0, br or 0
		return self
	end,
	Texture = function(self, texture)
		TEXTURE = texture
		return self
	end,
	Material = function(self, mat)
		local tex = mat:GetTexture("$basetexture")
		if tex then
			TEXTURE = tex
		end
		return self
	end,
	Outline = function(self, thickness)
		OUTLINE_THICKNESS = thickness
		return self
	end,
	Shape = function(self, shape)
		SHAPE = SHAPES[shape] or 2.2
		return self
	end,
	Color = function(self, col_or_r, g, b, a)
		if type(col_or_r) == "number" then
			COL_R, COL_G, COL_B, COL_A = col_or_r, g or 255, b or 255, a or 255
		else
			COL_R, COL_G, COL_B, COL_A = col_or_r.r, col_or_r.g, col_or_r.b, col_or_r.a
		end
		return self
	end,
	Blur = function(self, intensity)
		if not intensity then
			intensity = 1.0
		end
		intensity = math_max(intensity, 0)
		USING_BLUR, BLUR_INTENSITY = true, intensity
		return self
	end,
	Rotation = function(self, angle)
		ROTATION = math.rad(angle or 0)
		return self
	end,
	StartAngle = function(self, angle)
		START_ANGLE = angle or 0
		return self
	end,
	EndAngle = function(self, angle)
		END_ANGLE = angle or 360
		return self
	end,
	Shadow = function(self, spread, intensity)
		SHADOW_ENABLED, SHADOW_SPREAD, SHADOW_INTENSITY = true, spread or 30, intensity or (spread or 30) * 1.2
		return self
	end,
	Clip = function(self, pnl)
		CLIP_PANEL = pnl
		return self
	end,
	Flags = function(self, flags)
		flags = flags or 0

		-- Corner flags
		if bit_band(flags, NO_TL) ~= 0 then
			TL = 0
		end
		if bit_band(flags, NO_TR) ~= 0 then
			TR = 0
		end
		if bit_band(flags, NO_BL) ~= 0 then
			BL = 0
		end
		if bit_band(flags, NO_BR) ~= 0 then
			BR = 0
		end

		-- Shape flags
		local shape_flag = bit_band(flags, SHAPE_CIRCLE + SHAPE_FIGMA + SHAPE_IOS)
		if shape_flag ~= 0 then
			SHAPE = SHAPES[shape_flag] or SHAPES[DEFAULT_SHAPE]
		end

		-- Blur flag
		if bit_band(flags, BLUR) ~= 0 then
			BASE_FUNCS.Blur(self)
		end

		-- Manual color flag
		if bit_band(flags, MANUAL_COLOR) ~= 0 then
			COL_R = nil
		end

		return self
	end,

}

local RECT = {
	Rad         = BASE_FUNCS.Rad,
	Radii       = BASE_FUNCS.Radii,
	Texture     = BASE_FUNCS.Texture,
	Material    = BASE_FUNCS.Material,
	Outline     = BASE_FUNCS.Outline,
	Shape       = BASE_FUNCS.Shape,
	Color       = BASE_FUNCS.Color,
	Blur        = BASE_FUNCS.Blur,
	Rotation    = BASE_FUNCS.Rotation,
	StartAngle  = BASE_FUNCS.StartAngle,
	EndAngle    = BASE_FUNCS.EndAngle,
	Clip        = BASE_FUNCS.Clip,
	Shadow      = BASE_FUNCS.Shadow,
	Flags       = BASE_FUNCS.Flags,

	Draw        = function(self)
		if START_ANGLE == END_ANGLE then
			return -- nothing to draw
		end

		local OLD_CLIPPING_STATE
		if SHADOW_ENABLED or CLIP_PANEL then
			-- if we are inside a panel, we need to draw outside of it
			OLD_CLIPPING_STATE = DisableClipping(true)
		end

		if CLIP_PANEL then
			local sx, sy = CLIP_PANEL:LocalToScreen(0, 0)
			local sw, sh = CLIP_PANEL:GetSize()
			render.SetScissorRect(sx, sy, sx + sw, sy + sh, true)
		end

		if SHADOW_ENABLED then
			setup_shadows()
			draw_shadows(COL_R, COL_G, COL_B, COL_A)
		elseif USING_BLUR then
			draw_blur()
		else
			if TEXTURE then
				MAT = ROUNDED_TEXTURE_MAT
				MATERIAL_SetTexture(MAT, "$basetexture", TEXTURE)
			end

			SetupDraw()
			surface_DrawTexturedRectUV(X, Y, W, H, -0.015625, -0.015625, 1.015625, 1.015625)
		end

		if CLIP_PANEL then
			render.SetScissorRect(0, 0, 0, 0, false)
		end

		if SHADOW_ENABLED or CLIP_PANEL then
			DisableClipping(OLD_CLIPPING_STATE)
		end
	end,

	GetMaterial = function(self)
		if SHADOW_ENABLED or USING_BLUR then
			error("You can't get the material of a shadowed or blurred rectangle!")
		end

		if TEXTURE then
			MAT = ROUNDED_TEXTURE_MAT
			MATERIAL_SetTexture(MAT, "$basetexture", TEXTURE)
		end
		SetupDraw()

		return MAT
	end,
}

local CIRCLE = {
	Texture = BASE_FUNCS.Texture,
	Material = BASE_FUNCS.Material,
	Outline = BASE_FUNCS.Outline,
	Color = BASE_FUNCS.Color,
	Blur = BASE_FUNCS.Blur,
	Rotation = BASE_FUNCS.Rotation,
	StartAngle = BASE_FUNCS.StartAngle,
	EndAngle = BASE_FUNCS.EndAngle,
	Clip = BASE_FUNCS.Clip,
	Shadow = BASE_FUNCS.Shadow,
	Flags = BASE_FUNCS.Flags,

	Draw = RECT.Draw,
	GetMaterial = RECT.GetMaterial,
}

local TYPES = {
	Rect = function(x, y, w, h)
		RESET_PARAMS()
		MAT = ROUNDED_MAT
		X, Y, W, H = x, y, w, h
		return RECT
	end,
	Circle = function(x, y, r)
		RESET_PARAMS()
		MAT = ROUNDED_MAT
		SHAPE = SHAPES[SHAPE_CIRCLE]
		X, Y, W, H = x - r / 2, y - r / 2, r, r
		r = r / 2
		TL, TR, BL, BR = r, r, r, r
		return CIRCLE
	end
}

setmetatable(RNDX, {
	__call = function()
		return TYPES
	end
})

-- Flags
RNDX.NO_TL = NO_TL
RNDX.NO_TR = NO_TR
RNDX.NO_BL = NO_BL
RNDX.NO_BR = NO_BR

RNDX.SHAPE_CIRCLE = SHAPE_CIRCLE
RNDX.SHAPE_FIGMA = SHAPE_FIGMA
RNDX.SHAPE_IOS = SHAPE_IOS

RNDX.BLUR = BLUR
RNDX.MANUAL_COLOR = MANUAL_COLOR

function RNDX.SetFlag(flags, flag, bool)
	flag = RNDX[flag] or flag
	if tobool(bool) then
		return bit.bor(flags, flag)
	else
		return bit.band(flags, bit.bnot(flag))
	end
end

function RNDX.SetDefaultShape(shape)
	DEFAULT_SHAPE = shape or SHAPE_FIGMA
	DEFAULT_DRAW_FLAGS = DEFAULT_SHAPE
end
