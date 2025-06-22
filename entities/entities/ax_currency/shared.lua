--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ENT.Type = "anim"
ENT.PrintName = "Currency"
ENT.Category = "Parallax"
ENT.Author = "Riggs"
ENT.Spawnable = false
ENT.AdminOnly = false

function ENT:SetupDataTables()
    self:NetworkVar("Float", 0, "Amount")
end

properties.Add("ax.Property.currency.setamount", {
    MenuLabel = "Set Amount",
    Order = 999,
    MenuIcon = "icon16/money.png",
    Filter = function( self, ent, client )
        if ( !IsValid(ent) or ent:GetClass() != "ax_currency" ) then return false end
        if ( !gamemode.Call( "CanProperty", client, "ax.Property.currency.setamount", ent ) ) then return false end

        return client:IsSuperAdmin()
    end,
    Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
        Derma_StringRequest(
            "Set Amount",
            "Enter the amount of currency:",
            tostring(ent:GetAmount()),
            function(text)
                if ( !isstring(text) or text == "" ) then return end

                local amount = tonumber(text)
                if ( !isnumber(amount) or amount < 0 ) then return end

                self:MsgStart()
                    net.WriteEntity(ent)
                    net.WriteFloat(amount)
                self:MsgEnd()
            end
        )
    end,
    Receive = function( self, length, client ) -- The action to perform upon using the property ( Serverside )
        local ent = net.ReadEntity()

        if ( !properties.CanBeTargeted( ent, client ) ) then return end
        if ( !self:Filter( ent, client ) ) then return end

        local amount = net.ReadFloat()
        if ( !isnumber(amount) ) then return end

        if ( amount < 0 ) then
            ax.util:PrintWarning(Format("Admin %s (%s) tried to set the amount of currency to a negative value!", client:SteamName(), client:SteamID64()))
            return
        end

        ent:SetAmount(amount)
    end
})