--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Motion and animation utilities for the interface.
-- @module ax.motion

ax.motion = ax.motion or {}

-- Animation easing functions
ax.motion.easingFunctions = {
    linear = function(t) return t end,
    inQuad = function(t) return t * t end,
    outQuad = function(t) return t * (2 - t) end,
    inOutQuad = function(t)
        t = t * 2
        if t < 1 then return 0.5 * t * t end
        t = t - 1
        return -0.5 * (t * (t - 2) - 1)
    end,
    inCubic = function(t) return t * t * t end,
    outCubic = function(t)
        t = t - 1
        return t * t * t + 1
    end,
    inOutCubic = function(t)
        t = t * 2
        if t < 1 then return 0.5 * t * t * t end
        t = t - 2
        return 0.5 * (t * t * t + 2)
    end
}

--- Animates a property of a panel over time.
-- @realm client
-- @param panel The panel to animate
-- @param property The property name to animate
-- @param start The starting value
-- @param finish The target value
-- @param duration Duration in seconds
-- @param easing Easing function name (default: "inOutQuad")
-- @param delay Optional delay before starting animation
-- @param callback Optional function to call when animation completes
function ax.motion:AnimateProperty(panel, property, start, finish, duration, easing, delay, callback)
    easing = easing or "inOutQuad"
    delay = delay or 0

    local startTime = SysTime() + delay
    local endTime = startTime + duration
    local easingFunc = self.easingFunctions[easing] or self.easingFunctions.inOutQuad

    local uniqueIdent = "ax.motion." .. panel:GetTable().__index .. "." .. property .. "." .. SysTime()

    hook.Add("Think", uniqueIdent, function()
        if ( !IsValid(panel) ) then
            hook.Remove("Think", uniqueIdent)
            return
        end

        local currentTime = SysTime()

        if ( currentTime < startTime ) then return end

        if ( currentTime >= endTime ) then
            panel[property] = finish
            hook.Remove("Think", uniqueIdent)
            if callback then callback() end
            return
        end

        local delta = (currentTime - startTime) / duration
        local easedDelta = easingFunc(delta)

        panel[property] = Lerp(easedDelta, start, finish)
    end)

    return uniqueIdent
end

--- Storage for particle systems
ax.motion.particles = {}

--- Creates a particle system for decorative effects.
-- @realm client
-- @param parent The parent panel to contain the particles
-- @param count Number of particles to create
-- @param minSize Minimum particle size
-- @param maxSize Maximum particle size
-- @return The container panel for the particle system
function ax.motion:CreateParticleSystem(parent, count, minSize, maxSize)
    local container = vgui.Create("DPanel", parent)
    container:SetSize(parent:GetSize())
    container:SetPos(0, 0)

    container.Paint = function(_, w, h)
        -- Draw nothing for the container itself
    end

    local particles = {}

    -- Create particles
    for i = 1, count do
        local particle = vgui.Create("DPanel", container)
        local size = math.random(minSize, maxSize)
        particle:SetSize(size, size)
        particle:SetPos(math.random(0, parent:GetWide()), math.random(0, parent:GetTall()))

        particle.alpha = math.random(5, 30)
        particle.speed = math.random(5, 20) / 10
        particle.direction = math.random(0, 360)

        particle.Paint = function(this, pw, ph)
            surface.SetDrawColor(255, 255, 255, this.alpha)
            surface.DrawRect(0, 0, pw, ph)
        end

        table.insert(particles, particle)
    end

    -- Store reference to particles
    local systemID = SysTime() .. "." .. math.random(1, 1000)
    self.particles[systemID] = particles

    -- Animation timer
    timer.Create("ax.motion.particles." .. systemID, 0.02, 0, function()
        if ( !IsValid(container) ) then
            timer.Remove("ax.motion.particles." .. systemID)
            self.particles[systemID] = nil
            return
        end

        local w, h = container:GetSize()

        for _, p in ipairs(particles) do
            if IsValid(p) then
                local x, y = p:GetPos()
                local rad = math.rad(p.direction)

                x = x + math.cos(rad) * p.speed
                y = y + math.sin(rad) * p.speed

                -- Bounce off edges
                if x <= 0 or x >= w then
                    p.direction = (180 - p.direction) % 360
                end

                if y <= 0 or y >= h then
                    p.direction = (360 - p.direction) % 360
                end

                -- Keep particles in bounds
                x = math.Clamp(x, 0, w)
                y = math.Clamp(y, 0, h)

                p:SetPos(x, y)
            end
        end
    end)

    return container, systemID
end

--- Destroys a particle system.
-- @realm client
-- @param systemID The ID of the system to destroy
function ax.motion:DestroyParticleSystem(systemID)
    if ( self.particles[systemID] ) then
        for _, p in ipairs(self.particles[systemID]) do
            if ( IsValid(p) ) then
                p:Remove()
            end
        end

        self.particles[systemID] = nil
        timer.Remove("ax.motion.particles." .. systemID)
    end
end