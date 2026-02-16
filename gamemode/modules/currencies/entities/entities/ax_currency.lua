--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Currency"
ENT.Category = "Parallax"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "Amount")
    self:NetworkVar("String", 0, "CurrencyID")
end

if ( SERVER ) then
    function ENT:Initialize()
        self:SetModel("models/props_lab/box01a.mdl")
        self:SetSolid(SOLID_VPHYSICS)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        local physicsObject = self:GetPhysicsObject()
        if ( IsValid(physicsObject) ) then
            physicsObject:EnableMotion(true)
            physicsObject:Wake()
        end

        -- Despawn after 5 minutes to avoid clutter
        SafeRemoveEntityDelayed(self, 300)
    end

    function ENT:Use(activator)
        if ( !ax.util:IsValidPlayer(activator) ) then return end

        local character = activator:GetCharacter()
        if ( !character ) then
            activator:Notify("You need an active character to pick up currency, how did you even get this?")
            return
        end

        local amount = self:GetAmount()
        local currencyID = self:GetCurrencyID()

        if ( !ax.currencies:IsValid(currencyID) or amount <= 0 ) then
            self:Remove()
            return
        end

        -- Add currency to character and remove the entity
        character:AddCurrency(amount, currencyID)

        activator:Notify("You picked up " .. ax.currencies:Format(currencyID, amount))

        hook.Run("PlayerPickedUpCurrency", activator, character, amount, currencyID)

        self:Remove()
    end

    function ENT:UpdateTransmitState()
        return TRANSMIT_PVS
    end
end
