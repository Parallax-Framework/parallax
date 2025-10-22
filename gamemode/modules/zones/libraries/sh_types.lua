--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- @module ax.zones

-- Box zone type
ax.zones:RegisterType("box", {
    --- Validate a box zone specification.
    -- @tparam table spec Zone spec with mins and maxs
    -- @treturn boolean success
    -- @treturn string|nil error
    Validate = function(spec)
        if ( !spec.mins or !isvector(spec.mins) ) then
            return false, "Box zone requires mins Vector"
        end

        if ( !spec.maxs or !isvector(spec.maxs) ) then
            return false, "Box zone requires maxs Vector"
        end

        if ( spec.mins.x > spec.maxs.x or spec.mins.y > spec.maxs.y or spec.mins.z > spec.maxs.z ) then
            return false, "Box mins must be <= maxs on all axes"
        end

        return true
    end,

    --- Get axis-aligned bounding box for a box zone.
    -- @tparam table spec Zone spec
    -- @treturn Vector mins
    -- @treturn Vector maxs
    AABB = function(spec)
        return spec.mins, spec.maxs
    end,

    --- Check if a position is inside a box zone.
    -- @tparam table spec Zone spec
    -- @tparam Vector pos Position to test
    -- @treturn boolean contained
    Contains = function(spec, pos)
        return pos.x >= spec.mins.x and pos.x <= spec.maxs.x
            and pos.y >= spec.mins.y and pos.y <= spec.maxs.y
            and pos.z >= spec.mins.z and pos.z <= spec.maxs.z
    end,
})

-- Sphere zone type
ax.zones:RegisterType("sphere", {
    --- Validate a sphere zone specification.
    -- @tparam table spec Zone spec with center and radius
    -- @treturn boolean success
    -- @treturn string|nil error
    Validate = function(spec)
        if ( !spec.center or !isvector(spec.center) ) then
            return false, "Sphere zone requires center Vector"
        end

        if ( !isnumber(spec.radius) or spec.radius <= 0 ) then
            return false, "Sphere zone requires radius > 0"
        end

        return true
    end,

    --- Get axis-aligned bounding box for a sphere zone.
    -- @tparam table spec Zone spec
    -- @treturn Vector mins
    -- @treturn Vector maxs
    AABB = function(spec)
        local r = spec.radius
        return spec.center - Vector(r, r, r), spec.center + Vector(r, r, r)
    end,

    --- Check if a position is inside a sphere zone.
    -- @tparam table spec Zone spec
    -- @tparam Vector pos Position to test
    -- @treturn boolean contained
    Contains = function(spec, pos)
        return spec.center:DistToSqr(pos) <= (spec.radius * spec.radius)
    end,
})

-- PVS (visibility) zone type
ax.zones:RegisterType("pvs", {
    --- Validate a PVS zone specification.
    -- @tparam table spec Zone spec with origin and optional radius
    -- @treturn boolean success
    -- @treturn string|nil error
    Validate = function(spec)
        if ( !spec.origin or !isvector(spec.origin) ) then
            return false, "PVS zone requires origin Vector"
        end

        if ( spec.radius != nil and (!isnumber(spec.radius) or spec.radius < 0) ) then
            return false, "PVS zone radius must be >= 0 if present"
        end

        return true
    end,

    --- Get axis-aligned bounding box for a PVS zone (returns origin point).
    -- @tparam table spec Zone spec
    -- @treturn Vector mins
    -- @treturn Vector maxs
    AABB = function(spec)
        return spec.origin, spec.origin
    end,

    --- PVS zones don't use physical containment.
    -- @tparam table spec Zone spec
    -- @tparam Vector pos Position to test
    -- @treturn boolean always false
    Contains = function(spec, pos)
        return false
    end,

    --- Calculate visibility weight for a PVS zone.
    -- @tparam table spec Zone spec
    -- @tparam Vector pos Entity position
    -- @tparam Entity ent The entity (used for PVS checks)
    -- @treturn number weight 0.0 to 1.0, higher is more relevant
    Weight = function(spec, pos, ent)
        -- If entity can't see the zone origin, weight is 0
        if ( !ent or !IsValid(ent) ) then return 0 end

        -- Check PVS visibility
        if ( SERVER ) then
            -- Use TestPVS for performance
            local pvs = ent:TestPVS(spec.origin)
            if ( !pvs ) then return 0 end
        else
            -- Client can use simpler check
            local visible = util.IsInWorld(spec.origin)
            if ( !visible ) then return 0 end
        end

        -- If no radius specified, full weight when visible
        if ( !spec.radius ) then return 1.0 end

        -- Apply distance falloff
        local dist = pos:Distance(spec.origin)
        if ( dist >= spec.radius ) then return 0 end

        return 1.0 - (dist / spec.radius)
    end,
})

-- Trace (line-of-sight) zone type
ax.zones:RegisterType("trace", {
    --- Validate a trace zone specification.
    -- @tparam table spec Zone spec with origin and optional radius
    -- @treturn boolean success
    -- @treturn string|nil error
    Validate = function(spec)
        if ( !spec.origin or !isvector(spec.origin) ) then
            return false, "Trace zone requires origin Vector"
        end

        if ( spec.radius != nil and (!isnumber(spec.radius) or spec.radius < 0) ) then
            return false, "Trace zone radius must be >= 0 if present"
        end

        return true
    end,

    --- Get axis-aligned bounding box for a trace zone (returns origin point).
    -- @tparam table spec Zone spec
    -- @treturn Vector mins
    -- @treturn Vector maxs
    AABB = function(spec)
        return spec.origin, spec.origin
    end,

    --- Trace zones don't use physical containment.
    -- @tparam table spec Zone spec
    -- @tparam Vector pos Position to test
    -- @treturn boolean always false
    Contains = function(spec, pos)
        return false
    end,

    --- Calculate trace weight for a trace zone.
    -- @tparam table spec Zone spec
    -- @tparam Vector pos Entity position
    -- @tparam Entity ent The entity (used for trace origin)
    -- @treturn number weight 0.0 to 1.0, higher is more relevant
    Weight = function(spec, pos, ent)
        if ( !ent or !IsValid(ent) ) then return 0 end

        -- Perform trace from entity position to zone origin
        local traceData = {
            start = pos,
            endpos = spec.origin,
            filter = ent,
            mask = MASK_VISIBLE_AND_NPCS,
        }

        local trace = util.TraceLine(traceData)

        -- If trace doesn't hit the origin point (blocked), weight is 0
        if ( trace.Hit and trace.HitPos:DistToSqr(spec.origin) > 25 ) then
            return 0
        end

        -- If no radius specified, full weight when trace succeeds
        if ( !spec.radius ) then return 1.0 end

        -- Apply distance falloff
        local dist = pos:Distance(spec.origin)
        if ( dist >= spec.radius ) then return 0 end

        return 1.0 - (dist / spec.radius)
    end,
})
