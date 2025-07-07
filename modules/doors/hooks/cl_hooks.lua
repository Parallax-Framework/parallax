local MODULE = MODULE

function MODULE:PlayerButtonDown(client, key)
    if ( key != KEY_F2 ) then return end

    local ent = client:GetEyeTrace().Entity
    if ( !IsValid(ent) or !ent:IsDoor() ) then return end

    local owner = ent:GetRelay("owner", 0)
    if ( !IsValid(Entity(owner)) ) then
        net.Start("ax.doors.buy")
            net.WriteEntity(ent)
        net.SendToServer()
    else
        local panel = vgui.Create("ax.door")
        panel:Populate(ent)
    end
end

function MODULE:ShouldDrawTargetInfo(target)
    if ( target:GetClass():lower():find("prop_door_rotating") ) then
        return true
    end
end

function MODULE:DrawTargetInfo(target, alpha)
    if ( !target:GetClass():lower():find("prop_door_rotating") ) then return end

    local client = ax.client

    local ownerIndex = target:GetRelay("owner", 0)
    local owner = Entity(ownerIndex)
    local price = target:GetRelay("price") or ax.config:Get("door.price", 5)
    local child = target:GetChildDoor()
    local master = target:GetMasterDoor()
    if ( IsValid(child) ) then
        price = price + (child:GetRelay("price") or ax.config:Get("door.price", 5))
    end

    if ( IsValid(master) ) then
        price = price + (master:GetRelay("price") or ax.config:Get("door.price", 5))
    end

    local locked = target:GetRelay("locked", false)
    local mode = target:GetRelay("mode", "player")

    local msg
    if ( !IsValid(owner) ) then
        msg = "Press F2 to buy for " .. ax.currency:Format(price, false, true)
    else
        msg = owner:Nick()
    end

    local pos = target:WorldSpaceCenter()
    local ang = target:GetAngles()
    cam.Start3D2D(pos + ang:Forward() * 2, ang + Angle(0, 90, 90), 0.04)
        draw.SimpleTextOutlined(msg, "ax.huge.bold", 0, 0, ColorAlpha(ax.config:Get("color.schema"), alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0, alpha))
    cam.End3D2D()

    cam.Start3D2D(pos - ang:Forward() * 2, ang + Angle(0, 270, 90), 0.04)
        draw.SimpleTextOutlined(msg, "ax.huge.bold", 0, 0, ColorAlpha(ax.config:Get("color.schema"), alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0, alpha))
    cam.End3D2D()
end
