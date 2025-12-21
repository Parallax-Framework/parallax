local MODULE = MODULE or {}

function MODULE:LoadFonts()
    ax.font:CreateFamily("small.admin", "Courier New", ax.util:ScreenScaleH(5))
    ax.font:CreateFamily("regular.admin", "Courier New", ax.util:ScreenScaleH(6))
    ax.font:CreateFamily("large.admin", "Courier New", ax.util:ScreenScaleH(12))
    ax.font:CreateFamily("huge.admin", "Courier New", ax.util:ScreenScaleH(24))
    ax.font:CreateFamily("massive.admin", "Courier New", ax.util:ScreenScaleH(32))
end

function MODULE:HUDPaint()
    local client = ax.client
    if ( !IsValid(client) or !client:IsAdmin() ) then return end

    if ( !ax.option:Get("admin.esp") ) then return end
    if ( client:InVehicle() ) then return end
    if ( client:GetMoveType() != MOVETYPE_NOCLIP ) then return end

    self:DrawItems()
    self:DrawPlayers()
    self:DrawEntities()

    hook.Run("HUDPaintAdminESP")
end

function MODULE:DrawItems()
    local THRESHOLD = ax.util:ScreenScale(12) + ax.util:ScreenScaleH(12) -- pixels; distance under which same-class items will stack visually

    local stacks_by_class = {}

    for _, item in ipairs(ents.FindByClass("ax_item")) do
        if ( !IsValid(item) ) then continue end

        local scr = item:GetPos():ToScreen()
        if ( !scr.visible ) then continue end

        local cls = item:GetRelay( "itemClass" ) or "unknown"
        stacks_by_class[cls] = stacks_by_class[cls] or {}

        local placed = false
        for _, stack in ipairs(stacks_by_class[cls]) do
            local dx = scr.x - stack.x
            local dy = scr.y - stack.y
            if ( math.sqrt(dx * dx + dy * dy) <= THRESHOLD ) then
                table.insert(stack.items, item)
                -- update stack anchor to running average so it follows visual cluster
                local n = #stack.items
                stack.x = (stack.x * (n - 1) + scr.x) / n
                stack.y = (stack.y * (n - 1) + scr.y) / n
                placed = true
                break
            end
        end

        if ( !placed ) then
            table.insert(stacks_by_class[cls], { x = scr.x, y = scr.y, items = { item } })
        end
    end

    -- Draw stacks: single label per visual cluster, add count if > 1
    for cls, stacks in pairs(stacks_by_class) do
        for _, stack in ipairs(stacks) do
            local x, y = stack.x, stack.y
            local count = #stack.items

            local stored = ax.item.stored[cls]
            if ( !stored ) then continue end

            local displayName = stored:GetName() or "Unknown Item"
            draw.SimpleTextOutlined(displayName, "ax.regular.admin", x, y + 4, Color(255, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0))

            if ( count > 1 ) then
                draw.SimpleTextOutlined("x" .. tostring(count), "ax.small.admin", x, y - 4, Color(255, 200, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
            end
        end
    end
end

function MODULE:DrawPlayers()
    local client = ax.client
    if ( !IsValid(client) or !client:IsAdmin() ) then return end

    for _, target in player.Iterator() do
        if ( target == client or !IsValid(target) ) then continue end

        local scr = target:GetPos():ToScreen()
        if ( !scr.visible ) then continue end

        local steamID64 = target:SteamID64()
        local name = target:SteamName()
        local teamName = team.GetName(target:Team()) or "Unknown"
        local character = target:GetCharacter()
        if ( character ) then
            name = character:GetName() .. " [" .. target:EntIndex() .. "][" .. name .. "]"

            local class = character:GetClass()
            if ( class ) then
                local classTable = ax.class.instances[class]
                if ( classTable ) then
                    teamName = teamName .. " (" .. (classTable.name or "Unknown") .. ")"
                end
            end
        end

        local health = target:Health() or 0
        local maxHealth = target:GetMaxHealth() or 100
        local armor = target:Armor() or 0
        local maxArmor = target:GetMaxArmor() or 100

        local yOffset = 0
        local ySpacing = draw.GetFontHeight("ax.regular.admin.bold") / 1.25

        draw.SimpleTextOutlined(steamID64, "ax.regular.admin", scr.x, scr.y + yOffset, Color(255, 0, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0))
        yOffset = yOffset + ySpacing

        draw.SimpleTextOutlined(name, "ax.regular.admin.bold", scr.x, scr.y + yOffset, Color(0, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0))
        yOffset = yOffset + ySpacing

        draw.SimpleTextOutlined(teamName, "ax.regular.admin", scr.x, scr.y + yOffset, team.GetColor(target:Team()) or Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0))
        yOffset = yOffset + ySpacing

        local healthText = "HP: " .. tostring(health) .. " / " .. tostring(maxHealth)
        draw.SimpleTextOutlined(healthText, "ax.regular.admin", scr.x, scr.y + yOffset, Color(0, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0))
        yOffset = yOffset + ySpacing

        if ( armor > 0 ) then
            local armorText = "AR: " .. tostring(armor) .. " / " .. tostring(maxArmor)
            draw.SimpleTextOutlined(armorText, "ax.regular.admin", scr.x, scr.y + yOffset, Color(0, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0))
            yOffset = yOffset + ySpacing
        end

        local weapon = target:GetActiveWeapon()
        if ( IsValid(weapon) ) then
            local wepName = weapon:GetPrintName() or "Unknown"
            draw.SimpleTextOutlined(wepName, "ax.regular.admin", scr.x, scr.y + yOffset, Color(255, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0))
            yOffset = yOffset + ySpacing
        end
    end
end

-- Search for Parallax Entities and draw their name
local blacklist = {
    ["ax_item"] = true,
}

function MODULE:DrawEntities()
    local client = ax.client
    if ( !IsValid(client) or !client:IsAdmin() ) then return end

    for _, ent in ipairs(ents.FindByClass("ax_*")) do
        if ( !IsValid(ent) or blacklist[ent:GetClass()] or ent:GetOwner() == client ) then continue end

        local scr = ent:GetPos():ToScreen()
        if ( !scr.visible ) then continue end

        local class = ent:GetClass() or "Unknown"
        local name = ent.PrintName or class

        draw.SimpleTextOutlined(name, "ax.regular.admin.bold", scr.x, scr.y + 4, Color(255, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0))
        draw.SimpleTextOutlined(class, "ax.small.admin", scr.x, scr.y - 4, Color(200, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
    end
end
