----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 --- Made by a transgender queen
 -- Slay queen Riggs
 -- Stay Powerfull against the Patiarchy by a man (Alex Grist) stealing code
 -- #OverwatchFramework #CodeStealingMatters

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]


--[[--
Position and direction in 3D space.

`Vectors` are used to represent 3D positions, directions, and sizes. They are used in many places in the Source Engine, such as the `Entity` class, the `PhysObj` class, and the `CUserCmd` class.

Vectors are represented by three numbers, `x`, `y`, and `z`. They can be created using the `Vector` function, which takes three numbers as arguments, or by using the `Vector` class, which has several methods for creating and manipulating vectors.

See the [Garry's Mod Wiki](https://wiki.facepunch.com/gmod/Vector) for all other methods that the `Vector` class has.
]]
-- @classmod Vector

local meta = FindMetaTable("Vector")

--- Returns the center of two vectors
-- @realm shared
-- @treturn Vector The center of the two vectors
-- @usage -- Prints the center of two players
-- print(Entity(1):GetPos():Center(Entity(2):GetPos()))
function meta:Center(other)
    return ( self + other ) / 2
end

--- Rounds the vector to the nearest whole number
-- @realm shared
-- @treturn Vector The rounded vector
-- @usage -- Rounds the vector to the nearest whole number
-- local vec = Vector(1.5, 2.3, 3.7)
-- print(vec:Round())
-- > 2 2 4
function meta:Round(decimals)
    local x, y, z = self.x, self.y, self.z
    return Vector(math.Round(x, decimals), math.Round(y, decimals), math.Round(z, decimals))
end

--- Returns the distance between two vectors
-- @realm shared
-- @treturn number The distance between the two vectors
-- @usage -- Prints the distance between two players
-- print(Entity(1):GetPos():Distance(Entity(2):GetPos()))
function meta:Distance(other)
    local x, y, z = self.x, self.y, self.z
    local x2, y2, z2 = other.x, other.y, other.z

    return math.sqrt((x - x2) ^ 2 + (y - y2) ^ 2 + (z - z2) ^ 2)
end

local CrossProduct = meta.Cross
local right = Vector(0, -1, 0)

--- Returns the right vector of the vector
-- @realm shared
-- @tparam[opt=Vector(0, -1, 0)] Vector vUp The up vector
-- @treturn Vector The right vector
-- @usage -- Prints the right vector of the player
-- print(Entity(1):GetPos():Right())
function meta:Right(vUp)
    if (self[1] == 0 and self[2] == 0) then
        return right
    end

    if (vUp == nil) then
        vUp = vector_up
    end

    local vRet = CrossProduct(self, vUp)
    vRet:Normalize()

    return vRet
end

--- Returns the up vector of the vector
-- @realm shared
-- @tparam[opt=Vector(0, 0, 1)] Vector vUp The up vector
-- @treturn Vector The up vector
-- @usage -- Prints the up vector of the player
-- print(Entity(1):GetPos():Up())
function meta:Up(vUp)
    if (self[1] == 0 and self[2] == 0) then return Vector(-self[3], 0, 0) end

    if (vUp == nil) then
        vUp = vector_up
    end

    local vRet = CrossProduct(self, vUp)
    vRet = CrossProduct(vRet, self)
    vRet:Normalize()

    return vRet
end

local trace = {collisiongroup = COLLISION_GROUP_WORLD, output = {}}

--- Returns whether or not the vector is in the world.
-- @realm shared
-- @treturn bool Whether or not the vector is in the world
-- @usage -- Prints whether or not the vector is in the world
-- print(Entity(1):GetPos():InWorld())
function meta:InWorld()
    if ( SERVER ) then return util.IsInWorld(self) end

    trace.start = self
    trace.endpos = self

    return util.TraceLine(tr).HitWorld
end

--- Clamps the components of a vector to a specified range.
-- @realm shared
-- @vector vec The vector to clamp.
-- @number min The minimum value for each component.
-- @number max The maximum value for each component.
-- @treturn vector The clamped vector.
function meta:Clamp(vec, min, max)
    return Vector(
        math.Clamp(vec.x, min, max),
        math.Clamp(vec.y, min, max),
        math.Clamp(vec.z, min, max)
    )
end

--- Linearly interpolates between two vectors.
-- @realm shared
-- @tparam Vector to The target vector.
-- @tparam number fraction The fraction of interpolation (0-1).
-- @treturn Vector The interpolated vector.
function meta:LerpVector(to, fraction)
    return Vector(
        Lerp(fraction, self.x, to.x),
        Lerp(fraction, self.y, to.y),
        Lerp(fraction, self.z, to.z)
    )
end

--- Checks if the vector is a zero vector.
-- @realm shared
-- @treturn boolean True if the vector is (0, 0, 0), false otherwise.
function meta:IsZero()
    return self.x == 0 and self.y == 0 and self.z == 0
end

--- Reflects the vector across a given normal.
-- @realm shared
-- @tparam Vector normal The normal to reflect across.
-- @treturn Vector The reflected vector.
function meta:Reflect(normal)
    local dot = self:Dot(normal)
    return self - (2 * dot) * normal
end

--- Returns the angle between two vectors.
-- @realm shared
-- @tparam Vector other The other vector.
-- @treturn number The angle in degrees.
function meta:AngleBetween(other)
    local dot = self:Dot(other) / (self:Length() * other:Length())
    return math.deg(math.acos(math.Clamp(dot, -1, 1)))
end

--- Projects the vector onto another vector.
-- @realm shared
-- @tparam Vector other The vector to project onto.
-- @treturn Vector The projected vector.
function meta:ProjectOnto(other)
    local dot = self:Dot(other)
    local lengthSquared = other:LengthSqr()
    return other * (dot / lengthSquared)
end

--- Minimizes the components of the vector with another vector.
-- @realm shared
-- @tparam Vector other The vector to compare with.
-- @treturn Vector The minimized vector.
function meta:Minimize(other)
    return Vector(
        math.min(self.x, other.x),
        math.min(self.y, other.y),
        math.min(self.z, other.z)
    )
end

--- Maximizes the components of the vector with another vector.
-- @realm shared
-- @tparam Vector other The vector to compare with.
-- @treturn Vector The maximized vector.
function meta:Maximize(other)
    return Vector(
        math.max(self.x, other.x),
        math.max(self.y, other.y),
        math.max(self.z, other.z)
    )
end

--- Converts the vector into a table.
-- @realm shared
-- @treturn table A table representation of the vector.
function meta:ToTable()
    return {x = self.x, y = self.y, z = self.z}
end

--- Normalizes the vector to a specific length.
-- @realm shared
-- @tparam number length The length to normalize to.
-- @treturn Vector The normalized vector.
function meta:NormalizeToLength(length)
    return self:GetNormalized() * length
end

--- Rotates the vector around an axis.
-- @realm shared
-- @tparam Vector axis The axis to rotate around.
-- @tparam number degrees The angle in degrees to rotate.
-- @treturn Vector The rotated vector.
function meta:RotateAroundAxis(axis, degrees)
    local rad = math.rad(degrees)
    local cosTheta = math.cos(rad)
    local sinTheta = math.sin(rad)

    return Vector(
        cosTheta * self.x + sinTheta * (axis.y * self.z - axis.z * self.y),
        cosTheta * self.y + sinTheta * (axis.z * self.x - axis.x * self.z),
        cosTheta * self.z + sinTheta * (axis.x * self.y - axis.y * self.x)
    )
end