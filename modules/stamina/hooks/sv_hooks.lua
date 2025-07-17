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

            local stamina = client:GetRelay("stamina")
            if ( !istable(stamina) ) then
                ax.stamina:Initialize(client)
                continue
            end

            local isSprinting = client:KeyDown(IN_SPEED) and client:KeyDown(IN_FORWARD) and client:OnGround()
            if ( isSprinting and client:GetVelocity():Length2DSqr() > 1 ) then
                if ( ax.stamina:Consume(client, drain) ) then
                    stamina.depleted = false
                    stamina.regenBlockedUntil = CurTime() + 2
                else
                    if ( !stamina.depleted ) then
                        stamina.depleted = true
                        stamina.regenBlockedUntil = CurTime() + 10
                    end
                end
            else
                if ( stamina.regenBlockedUntil and CurTime() >= stamina.regenBlockedUntil ) then
                    local newRegen = regen
                    if ( client:Crouching() and client:OnGround() ) then
                        newRegen = newRegen * 1.5
                    end

                    newRegen = hook.Run("PlayerStaminaRegen", client, newRegen) or newRegen
                    if ( !newRegen or newRegen <= 0 ) then continue end
                    ax.stamina:Set(client, math.min(stamina.current + newRegen, stamina.max))
                end
            end
        end
    end
end

function MODULE:OnPlayerHitGround(client, inWater, onFloater, speed)
    if ( !ax.config:Get("stamina", true) ) then return end

    local stamina = client:GetRelay("stamina")
    if ( stamina and stamina.current > 0 ) then
        ax.stamina:Consume(client, speed / 64)
    end
end

function MODULE:PlayerLoadout(client)
    if ( !ax.config:Get("stamina", true) ) then return end

    -- Initialize stamina when player spawns
    ax.stamina:Initialize(client)
end