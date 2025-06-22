--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.currency = ax.currency or {}

function ax.currency:GetSingular()
    return ax.config:Get("currency.singular")
end

function ax.currency:GetPlural()
    return ax.config:Get("currency.plural")
end

function ax.currency:GetSymbol()
    return ax.config:Get("currency.symbol")
end

function ax.currency:Format(amount, bNoSymbol, bComma)
    if ( !isnumber(amount) ) then return amount end

    local symbol = bNoSymbol and "" or self:GetSymbol()
    local formatted = !bComma and amount or string.Comma(amount)

    return symbol .. formatted
end

if ( SERVER ) then
    function ax.currency:Spawn(amount, pos, ang)
        if ( !isvector(pos) ) then
            ax.Util:PrintError("ax.currency:Spawn - Invalid position provided!")
            return
        end

        local ent = ents.Create("ax_currency")
        if ( !IsValid(ent) ) then return end

        ent:SetPos(pos)
        ent:SetAngles(ang or angle_zero)
        ent:SetAmount(amount or 1)
        ent:Spawn()
        ent:Activate()

        return ent
    end
end

ax.currency = ax.currency