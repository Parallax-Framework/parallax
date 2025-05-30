--- Cinematic
-- Clientside Bézier-based camera system using keyframes and timestamped playback.
-- @module ax.cinematic

ax.cinematic = ax.cinematic or {}
ax.cinematic.Active = nil
ax.cinematic.Path = {}
ax.cinematic.TotalDistance = 0
ax.cinematic.StartTime = 0
ax.cinematic.Duration = 0
ax.cinematic.Debug = true
ax.cinematic.RenderPaths = {}

--- Starts a new cinematic path.
-- @param duration Playback duration
-- @param path Table of {pos, ang, [fov], [ctrl]} entries
function ax.cinematic:Start(duration, path)
    self:Stop()

    self.Path = {}
    self.TotalDistance = 0
    self.Duration = duration
    self.StartTime = CurTime()

    local lastPos

    for i, node in ipairs(path) do
        local pos = node.pos
        local ctrl = node.ctrl or {}
        local ang = node.ang or Angle()
        local fov = node.fov or 90

        local segment = {
            pos = pos,
            ang = ang,
            fov = fov,
            ctrl = ctrl,
            distanceStart = self.TotalDistance
        }

        if ( lastPos ) then
            local distance = 0
            local points = table.Copy(ctrl)
            table.insert(points, 1, lastPos)
            table.insert(points, pos)
            segment.points = points

            for j = 1, 50 do
                local a = self:Bezier(points, (j - 1) / 50)
                local b = self:Bezier(points, j / 50)
                distance = distance + a:Distance(b)
            end

            segment.distanceFromLast = distance
            segment.distanceEnd = self.TotalDistance + distance
            segment.points = points
            self.TotalDistance = self.TotalDistance + distance
        else
            segment.distanceFromLast = 0
            segment.distanceEnd = 0
            segment.points = {}
        end

        table.insert(self.Path, segment)
        lastPos = pos
    end

    self.Active = true
    self.RenderPaths["Cinematic"] = path
end

--- Stops the current cinematic.
function ax.cinematic:Stop()
    self.Path = {}
    self.TotalDistance = 0
    self.StartTime = 0
    self.Duration = 0
    self.Active = nil
    self.RenderPaths["Cinematic"] = nil
end

--- Cubic Bézier curve calculator.
-- @param points Table of 4 control points
-- @param t Normalized progress
function ax.cinematic:Bezier(points, t)
    local u = 1 - t
    local tt = t * t
    local uu = u * u
    local uuu = uu * u
    local ttt = tt * t

    return uuu * points[1] +
        3 * uu * t * points[2] +
        3 * u * tt * points[3] +
        ttt * points[4]
end

function ax.cinematic:GetValue()
    local elapsed = CurTime() - self.StartTime
    if elapsed >= self.Duration then self:Stop() return end

    local t = elapsed / self.Duration
    t = math.Clamp(t, 0, 1)

    local curveDist = self.TotalDistance * t
    local path = self.Path

    for i = 2, #path do
        local node = path[i]
        local prev = path[i - 1]

        if node.distanceEnd >= curveDist then
            local localDist = curveDist - prev.distanceEnd
            local localT = localDist / node.distanceFromLast

            -- Compute smoothed shared control handles
            local handleOut = prev.ctrl and prev.ctrl[2] or prev.pos + (node.pos - prev.pos):GetNormalized() * 64
            local handleIn  = node.ctrl and node.ctrl[1] or node.pos - (node.pos - prev.pos):GetNormalized() * 64

            local p0 = prev.pos
            local p1 = handleOut
            local p2 = handleIn
            local p3 = node.pos

            local pos = self:Bezier({p0, p1, p2, p3}, localT)
            local ang = LerpAngle(localT, prev.ang, node.ang)
            local fov = Lerp(localT, prev.fov or 90, node.fov or 90)

            return pos, ang, fov
        end
    end
end

--- Example usage:
local path = {
    {
        pos = Vector(8623.775391, 4180.006836, 577.278015),
        ang = Angle(-0.527811, -117.383987, 0.000000),
        fov = 90,
        ctrl = {
            Vector(8594.339739, 4123.180832, 577.867577),
            Vector(8653.211042, 4236.832840, 576.688453)
        }
    },
    {
        pos = Vector(8500.307617, 1360.916138, 590.933044),
        ang = Angle(0.198189, -170.448120, 0.000000),
        fov = 90,
        ctrl = {
            Vector(8437.195313, 1350.296006, 590.711665),
            Vector(8563.419922, 1371.536269, 591.154423)
        }
    },
    {
        pos = Vector(6330.010254, 1113.116699, 595.425171),
        ang = Angle(-0.461811, -106.626457, 0.000000),
        fov = 90,
        ctrl = {
            Vector(6311.698475, 1051.794495, 595.941013),
            Vector(6348.322033, 1174.438904, 594.909329)
        }
    },
    {
        pos = Vector(5980.886719, -257.951813, 597.130249),
        ang = Angle(0.660189, -90.588570, 0.000000),
        fov = 90,
        ctrl = {
            Vector(5980.229341, -321.944180, 596.392827),
            Vector(5981.544096, -193.959446, 597.867671)
        }
    },
    {
        pos = Vector(6015.497559, -735.748840, 589.748230),
        ang = Angle(-0.857811, -140.682617, 0.000000),
        fov = 90,
        ctrl = {
            Vector(5965.989632, -776.295692, 590.706378),
            Vector(6065.005486, -695.201988, 588.790082)
        }
    },
    {
        pos = Vector(5436.376465, -1230.183105, 599.578186),
        ang = Angle(0.396189, -179.820572, 0.000000),
        fov = 90,
        ctrl = {
            Vector(5372.378315, -1230.383519, 599.135642),
            Vector(5500.374615, -1229.982692, 600.020730)
        }
    },
    {
        pos = Vector(3003.240723, -1199.234985, 636.318909),
        ang = Angle(32.472221, -89.202621, 0.000000),
        fov = 90,
        ctrl = {
            Vector(3003.992127, -1253.223461, 601.957905),
            Vector(3002.489318, -1145.246510, 670.679913)
        }
    },
    {
        pos = Vector(1933.230225, -1224.479980, 599.297913),
        ang = Angle(0.660206, -179.952499, 0.000000),
        fov = 90,
        ctrl = {
            Vector(1869.234497, -1224.533041, 598.560472),
            Vector(1997.225952, -1224.426920, 600.035353)
        }
    },
    {
        pos = Vector(651.227112, -1272.952637, 582.757935),
        ang = Angle(-2.573794, 119.789474, 0.000000),
        fov = 90,
        ctrl = {
            Vector(619.463055, -1217.465836, 585.631923),
            Vector(682.991169, -1328.439438, 579.883946)
        }
    },
}

concommand.Add("ax_cinematic_example", function()
    ax.cinematic:Start(#path * 4, path)
end)

-- Prints a point with the current eye pos, angle and fov, used for adding new points
concommand.Add("ax_cinematic_print", function(ply, cmd, arguments)
    local pos = ply:EyePos()
    local ang = ply:EyeAngles()
    local fov = 90

    local output = string.format("{\n\tpos = Vector(%f, %f, %f),\n\tang = Angle(%f, %f, %f),\n\tfov = %d,\n\tctrl = {\n\t\tVector(%f, %f, %f),\n\t\tVector(%f, %f, %f)\n\t}\n},",
        pos.x, pos.y, pos.z,
        ang.p, ang.y, ang.r,
        fov,
        pos.x + ply:GetForward().x * 64, pos.y + ply:GetForward().y * 64, pos.z + ply:GetForward().z * 64,
        pos.x - ply:GetForward().x * 64, pos.y - ply:GetForward().y * 64, pos.z - ply:GetForward().z * 64
    )

    ax.util:Print(output)
    SetClipboardText(output)
end)