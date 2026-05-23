local MODULE = MODULE or {}

function MODULE:GetChatNameColor(client)
end

function MODULE:LoadFonts()
    ax.font:CreateFamily("small.admin", "Courier New", 11)
    ax.font:CreateFamily("regular.admin", "Courier New", 13)
    ax.font:CreateFamily("large.admin", "Courier New", 17)
    ax.font:CreateFamily("huge.admin", "Courier New", 21)
    ax.font:CreateFamily("massive.admin", "Courier New", 25)
end

function MODULE:HUDPaint()
    local client = ax.client
    if ( !ax.util:IsValidPlayer(client) or !client:IsAdmin() ) then return end

    if ( !ax.option:Get("admin.esp") ) then return end
    if ( client:InVehicle() or !client:InNoclip() ) then return end

    self:DrawItems()
    self:DrawPlayers()
    self:DrawEntities()

    hook.Run("HUDPaintAdminESP")
end

function MODULE:DrawItems()
    local THRESHOLD = ax.util:ScreenScale(12) + ax.util:ScreenScaleH(12) -- pixels; distance under which same-class items will stack visually

    local stacks_by_class = {}

    local items = ents.FindByClass("ax_item")
    for _ = 1, #items do
        local item = items[_]

        local scr = item:GetPos():ToScreen()
        if ( !scr.visible ) then continue end

        local cls = item:GetItemClass()
        stacks_by_class[cls] = stacks_by_class[cls] or {}

        local placed = false
        for _ = 1, #stacks_by_class[cls] do
            local stack = stacks_by_class[cls][_]
            local dx = scr.x - stack.x
            local dy = scr.y - stack.y
            if ( math.sqrt(dx * dx + dy * dy) <= THRESHOLD ) then
                stack.items[#stack.items + 1] = item
                -- update stack anchor to running average so it follows visual cluster
                local n = #stack.items
                stack.x = (stack.x * (n - 1) + scr.x) / n
                stack.y = (stack.y * (n - 1) + scr.y) / n
                placed = true
                break
            end
        end

        if ( !placed ) then
            stacks_by_class[cls][#stacks_by_class[cls] + 1] = { x = scr.x, y = scr.y, items = { item } }
        end
    end

    -- Draw stacks: single label per visual cluster, add count if > 1
    for cls, stacks in pairs(stacks_by_class) do
        for _ = 1, #stacks do
            local stack = stacks[_]
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

local OUTLINE = Color(0, 0, 0)
local CHARACTER_NAME_COLOR = Color(255, 255, 255)
local STEAM_NAME_COLOR = Color(170, 215, 255)
local STEAM_NAME_FALLBACK_COLOR = Color(255, 255, 255)
local HEALTH_COLOR = Color(120, 235, 120)
local ARMOR_COLOR = Color(120, 185, 255)
local WEAPON_COLOR = Color(255, 220, 130)

function MODULE:DrawPlayers()
    local client = ax.client
    if ( !ax.util:IsValidPlayer(client) or !client:IsAdmin() ) then return end

    local nameFont = "ax.huge.admin.bold"
    local subFont = "ax.regular.admin.bold"
    local detailFont = "ax.small.admin"
    local nameLineHeight = draw.GetFontHeight(nameFont) * 0.95
    local subLineHeight = draw.GetFontHeight(subFont) * 1.0
    local detailLineHeight = draw.GetFontHeight(detailFont) * 1.05

    for _, target in player.Iterator() do
        if ( target == client or !ax.util:IsValidPlayer(target) ) then continue end

        local scr = target:GetPos():ToScreen()
        if ( !scr.visible ) then continue end

        local steamName = target:SteamName()
        local teamName = team.GetName(target:Team()) or "Unknown"
        local character = target:GetCharacter()
        local characterName = nil

        if ( character ) then
            characterName = character:GetName()

            local class = character:GetClass()
            if ( class ) then
                local classTable = ax.class.instances[class]
                if ( classTable ) then
                    teamName = teamName .. " (" .. (classTable.name or "Unknown") .. ")"
                end
            end
        end

        local primaryName = characterName or steamName
        local primaryColor = characterName and CHARACTER_NAME_COLOR or STEAM_NAME_FALLBACK_COLOR
        local secondaryLine = string.format("@%s  [%d]", steamName, target:EntIndex())

        local yOffset = 0

        draw.SimpleTextOutlined(primaryName, nameFont, scr.x, scr.y + yOffset, primaryColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, OUTLINE)
        yOffset = yOffset + nameLineHeight

        if ( characterName ) then
            draw.SimpleTextOutlined(secondaryLine, subFont, scr.x, scr.y + yOffset, STEAM_NAME_COLOR, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, OUTLINE)
            yOffset = yOffset + subLineHeight
        else
            draw.SimpleTextOutlined("[" .. target:EntIndex() .. "]", subFont, scr.x, scr.y + yOffset, STEAM_NAME_COLOR, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, OUTLINE)
            yOffset = yOffset + subLineHeight
        end

        draw.SimpleTextOutlined(teamName, detailFont, scr.x, scr.y + yOffset, team.GetColor(target:Team()) or Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, OUTLINE)
        yOffset = yOffset + detailLineHeight

        local health = target:Health() or 0
        local armor = target:Armor() or 0
        local statusParts = { { text = "HP " .. health, color = HEALTH_COLOR } }
        if ( armor > 0 ) then
            statusParts[#statusParts + 1] = { text = "AR " .. armor, color = ARMOR_COLOR }
        end

        local weapon = target:GetActiveWeapon()
        if ( type(weapon) == "Weapon" ) then
            statusParts[#statusParts + 1] = { text = weapon:GetPrintName() or "Unknown", color = WEAPON_COLOR }
        end

        surface.SetFont(detailFont)
        local separator = "   "
        local separatorWidth = surface.GetTextSize(separator)
        local totalWidth = 0

        for i = 1, #statusParts do
            local partWidth = surface.GetTextSize(statusParts[i].text)
            totalWidth = totalWidth + partWidth
            if ( i < #statusParts ) then
                totalWidth = totalWidth + separatorWidth
            end
        end

        local cursorX = scr.x - totalWidth * 0.5
        for i = 1, #statusParts do
            local part = statusParts[i]
            local partWidth = surface.GetTextSize(part.text)
            draw.SimpleTextOutlined(part.text, detailFont, cursorX, scr.y + yOffset, part.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, 1, OUTLINE)
            cursorX = cursorX + partWidth + separatorWidth
        end
    end
end

-- Search for Parallax Entities and draw their name
local blacklist = {
    ["ax_item"] = true,
    ["ax_hands"] = true,
}

function MODULE:DrawEntities()
    local client = ax.client
    if ( !ax.util:IsValidPlayer(client) or !client:IsAdmin() ) then return end

    local gamemodeItems = ents.FindByClass("ax_*")

    for _ = 1, #gamemodeItems do
        local ent = gamemodeItems[_]
        if ( !IsValid(ent) or blacklist[ent:GetClass()] or ent:GetOwner() ) then continue end

        local scr = ent:GetPos():ToScreen()
        if ( !scr.visible ) then continue end

        local class = ent:GetClass() or "Unknown"
        local name = ent.PrintName or class

        draw.SimpleTextOutlined(name, "ax.regular.admin.bold", scr.x, scr.y + 4, Color(255, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0, 0, 0))
        draw.SimpleTextOutlined(class, "ax.small.admin", scr.x, scr.y - 4, Color(200, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
    end
end
