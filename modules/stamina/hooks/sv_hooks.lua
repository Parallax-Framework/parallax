--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

local nextStamina = 0
function MODULE:Think()
    if ( !ax.config:Get("stamina", true) ) then return end

    if ( CurTime() >= nextStamina ) then
        local regen = ax.config:Get("stamina.regen", 20) / 10
        local drain = ax.config:Get("stamina.drain", 10) / 10
        nextStamina = CurTime() + ax.config:Get("stamina.tick", 0.1)

        for _, client in player.Iterator() do
            if ( !IsValid(client) or !client:Alive() ) then continue end
            if ( client:Team() == 0 ) then continue end

            local st = client:GetRelay("stamina")
            if ( !istable(st) ) then
                ax.Stamina:Initialize(client)

                continue
            end

            local isSprinting = client:KeyDown(IN_SPEED) and client:KeyDown(IN_FORWARD) and client:OnGround()
            if ( isSprinting and client:GetVelocity():Length2DSqr() > 1 ) then
                if ( ax.Stamina:Consume(client, drain) ) then
                    st.depleted = false
                    st.regenBlockedUntil = CurTime() + 2
                else
                    if ( !st.depleted ) then
                        st.depleted = true
                        st.regenBlockedUntil = CurTime() + 10
                    end
                end
            else
                if ( st.regenBlockedUntil and CurTime() >= st.regenBlockedUntil ) then
                    ax.Stamina:Set(client, math.min(st.current + regen, st.max))
                end
            end
        end
    end
end

function MODULE:OnPlayerHitGround(client, inWater, onFloater, speed)
    if ( !ax.config:Get("stamina", true) ) then return end

    local st = client:GetRelay("stamina")
    if ( st and st.current > 0 ) then
        ax.Stamina:Consume(client, speed / 64)
    end
end

function MODULE:PlayerSpawn(client)
    if ( !ax.config:Get("stamina", true) ) then return end

    -- Initialize stamina when player spawns
    ax.Stamina:Initialize(client)
end