--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--[[
    Two constraints on this file, both load-bearing:

    1. It loads BEFORE cl_palette.lua (the interface directory is included alphabetically), so `ax.color` and `ax.ui` do not exist here. The layer is pure black by contract, so it never needs them -- do not "improve" the draw call into `ax.color.void`.

    2. It is rendered from `GM:PostRenderVGUI` in framework/hooks/cl_hooks.lua, deliberately not from the `PostRenderCurvy` hook. `PostRenderCurvy` silently never fires when the curvy module's render target or material is nil, curvy is a module that loads after this directory, the curvy shader edge-fades so a black routed through it is not opaque at the corners, and the player can switch curvy off entirely. A gamemode method runs after every `hook.Add` handler, which puts this above curvy's blit and above all VGUI, undistorted. The one accepted risk is that a third-party addon which hooks `PostRenderVGUI` AND returns a value would suppress the gamemode method.
]]

--- Seconds the black is held fully opaque before it lifts on character load.
AX_FADE_HOLD_TIME = 1

--- Seconds the black takes to lift on character load.
AX_FADE_REVEAL_TIME = 4

---@class ax.fade
--- Full-screen black layer painted straight to the screen rather than living in the VGUI tree, so nothing can land on top of it: there is no z-order to lose, no `MoveToFront` to run every frame, and no panel input to release. One layer is shared by everything that blacks the screen out -- the boot curtain, the menu's fade out, the character load handoff -- so a raise issued while a lift is running supersedes it outright instead of stacking a second sheet of black on the first.
---@field alpha number Current alpha of the black, 0-255.
---@field tween table|nil The tween in flight, or nil when the layer is idle.
ax.fade = ax.fade or {}
ax.fade.alpha = ax.fade.alpha or 0

--- Drops the tween in flight, leaving the black wherever it had reached; the dropped tween's callback never runs.
---@realm client
function ax.fade:Stop()
    self.tween = nil
end

--- Snaps the black to an alpha outright, dropping any tween in flight.
---@realm client
---@param alpha number Target alpha, 0-255.
function ax.fade:Set(alpha)
    self.tween = nil
    self.alpha = math.Clamp(alpha, 0, 255)
end

--- Tweens the black to an alpha, superseding whatever was in flight. Safe to call from inside another tween's callback: the layer owns a single tween slot and the finished tween is cleared before its callback runs, so chained steps never delete each other the way `Panel:AlphaTo` from inside `OnEnd` does.
---@realm client
---@param alpha number Target alpha, 0-255.
---@param duration number Seconds the tween takes.
---@param delay? number Seconds held at the current alpha before the tween starts.
---@param callback? function Called once the tween lands, or immediately when it is instant.
function ax.fade:To(alpha, duration, delay, callback)
    alpha = math.Clamp(alpha, 0, 255)
    duration = math.max(duration or 0, 0)
    delay = math.max(delay or 0, 0)

    if ( duration <= 0 and delay <= 0 ) then
        self:Set(alpha)

        if ( isfunction(callback) ) then
            callback()
        end

        return
    end

    self.tween = {
        from = self.alpha,
        to = alpha,
        startTime = RealTime() + delay,
        duration = duration,
        callback = callback,
    }
end

--- The alpha the black currently sits at.
---@realm client
---@return number alpha Current alpha, 0-255.
function ax.fade:GetAlpha()
    return self.alpha
end

--- The alpha the layer is heading for: the tween's target while one is in flight, otherwise where it already sits.
---@realm client
---@return number alpha Target alpha, 0-255.
function ax.fade:GetTarget()
    return self.tween and self.tween.to or self.alpha
end

--- True while a tween is in flight, including during its delay.
---@realm client
---@return boolean bTweening Whether a tween is in flight.
function ax.fade:IsTweening()
    return self.tween != nil
end

--- True when the black is up or on its way up, and false the moment something asks for it to lift; a lifting layer reads as no cover at all, because anything built behind one would be revealed mid-fade.
---@realm client
---@return boolean bCovering Whether the screen is covered or becoming covered.
function ax.fade:IsCovering()
    return self:GetTarget() > 0
end

--- Advances the tween in flight and fires its callback once it lands; driven from `Think` rather than from the render pass so callbacks that build interface are not running mid-frame.
---@realm client
function ax.fade:Update()
    local tween = self.tween
    if ( !tween ) then return end

    local now = RealTime()
    if ( now < tween.startTime ) then return end

    local fraction = tween.duration > 0 and math.Clamp((now - tween.startTime) / tween.duration, 0, 1) or 1
    self.alpha = Lerp(fraction, tween.from, tween.to)

    if ( fraction < 1 ) then return end

    -- Cleared before the callback runs so a callback that starts the next step owns the slot outright.
    self.alpha = tween.to
    self.tween = nil

    if ( isfunction(tween.callback) ) then
        tween.callback()
    end
end

--- Paints the black over the whole screen; called from `GM:PostRenderVGUI` so it covers Derma and everything the framework itself draws in that pass.
---@realm client
function ax.fade:Render()
    local alpha = math.Round(self.alpha)
    if ( alpha <= 0 ) then return end

    surface.SetDrawColor(0, 0, 0, math.min(alpha, 255))
    surface.DrawRect(0, 0, ScrW(), ScrH())
end

hook.Add("Think", "ax.fade.Think", function()
    ax.fade:Update()
end)
