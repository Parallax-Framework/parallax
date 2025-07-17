--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

local nextUse = 0
function MODULE:PlayerButtonDown(client, key)
    if ( key != KEY_F2 ) then return end

    local ent = client:GetEyeTrace().Entity
    if ( !IsValid(ent) or !ent:IsDoor() ) then return end

    if ( nextUse > CurTime() ) then return end
    nextUse = CurTime() + 1

    local owner = ent:GetRelay("owner", 0)
    local isAdmin = CAMI.PlayerHasAccess(client, "Parallax - Manage Doors", nil)
    local isOwnable = !ent:GetRelay("unownable", false)

    -- Check default config for ownable status
    if ( ax.config:Get("door.defaultUnownable", false) and isOwnable ) then
        isOwnable = false
    end

    -- If admin and config allows admin menu access, always show menu
    if ( isAdmin and ax.config:Get("door.adminMenuAccess", true) ) then
        local panel = vgui.Create("ax.door")
        panel:Populate(ent, true) -- Pass true for admin mode
        return
    end

    -- Regular player logic
    if ( !isOwnable ) then
        client:Notify("This door cannot be owned!")
        return
    end

    if ( !IsValid(Entity(owner)) ) then
        net.Start("ax.doors.buy")
            net.WriteEntity(ent)
        net.SendToServer()
    else
        local panel = vgui.Create("ax.door")
        panel:Populate(ent, false) -- Pass false for regular mode
    end
end

function MODULE:ShouldDrawTargetInfo(target, is3D2D)
    if ( target:IsDoor() ) then
        return true
    end
end

function MODULE:DrawTargetInfo(target, alpha, is3D2D)
    if ( !target:IsDoor() ) then return end

    local ownerIndex = target:GetRelay("owner", 0)
    local owner = Entity(ownerIndex)
    local price = target:GetRelay("price") or ax.config:Get("door.price", 5)
    local isOwnable = !target:GetRelay("unownable", false)
    local isAdmin = CAMI.PlayerHasAccess(ax.client, "Parallax - Manage Doors", nil)

    -- Check default config for ownable status
    if ( ax.config:Get("door.defaultUnownable", false) and isOwnable ) then
        isOwnable = false
    end

    local child = target:GetChildDoor()
    local master = target:GetMasterDoor()
    if ( IsValid(child) ) then
        price = price + (child:GetRelay("price") or ax.config:Get("door.price", 5))
    end

    if ( IsValid(master) ) then
        price = price + (master:GetRelay("price") or ax.config:Get("door.price", 5))
    end

    local msg
    if ( !isOwnable ) then
        if ( isAdmin ) then
            msg = "Press F2 to manage this door"
        else
            msg = nil
        end
    elseif ( !IsValid(owner) ) then
        msg = "Press F2 to buy for " .. ax.currency:Format(price, false, true)
    else
        msg = owner:Nick()
        if ( owner == ax.client or isAdmin ) then
            msg = msg .. " (F2 to manage)"
        end
    end

    if ( !msg or msg == "" ) then
        return
    end

    local pos = target:WorldSpaceCenter()
    local ang = target:GetAngles()

    if ( target:GetClass():lower() == "prop_door_rotating" ) then
        cam.Start3D2D(pos + ang:Forward() * 2, ang + Angle(0, 90, 90), 0.04)
            draw.SimpleTextOutlined(msg, "ax.huge.bold", 0, 0, ColorAlpha(ax.config:Get("color.schema"), alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0, alpha))
        cam.End3D2D()

        cam.Start3D2D(pos - ang:Forward() * 2, ang + Angle(0, 270, 90), 0.04)
            draw.SimpleTextOutlined(msg, "ax.huge.bold", 0, 0, ColorAlpha(ax.config:Get("color.schema"), alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0, alpha))
        cam.End3D2D()
    else
        local screenPos = pos:ToScreen()
        draw.SimpleTextOutlined(msg, "ax.regular.bold", screenPos.x, screenPos.y, ColorAlpha(ax.config:Get("color.schema"), alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, alpha))
    end
end