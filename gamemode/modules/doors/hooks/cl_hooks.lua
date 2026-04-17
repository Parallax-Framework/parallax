local MODULE = MODULE

function MODULE:GetEntityDisplayText(entity)
    if ( !entity:IsDoor() ) then return end

    local name = ax.localization:GetPhrase("door")
    local color = Color(255, 255, 255)

    if ( IsValid(ax.client) and ax.client:HasDoorAccess(entity) ) then
        color = Color(100, 200, 100)
    elseif ( entity:GetRelay("locked", false) ) then
        color = Color(200, 100, 100)
    end

    return name, color
end

function MODULE:HUDPaintTargetIDExtra(entity, x, y, alpha)
    if ( !entity:IsDoor() ) then return end

    local lineSpacing = ax.util:ScreenScaleH(6)
    local lineCount = 0

    local function DrawLine(text, color)
        lineCount = lineCount + 1
        local yPos = y + lineSpacing * lineCount
        draw.SimpleText(text, "ax.small", x + 1, yPos + 1, Color(0, 0, 0, alpha / 4), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(text, "ax.small", x, yPos, ColorAlpha(color, alpha / 2), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local bLocked = entity:GetRelay("locked", false)
    DrawLine(bLocked and "Locked" or "Unlocked", bLocked and Color(200, 80, 80) or Color(180, 220, 180))

    local bPurchased = entity:GetRelay("purchased", false)
    local bOwnable = entity:GetRelay("ownable", true)
    local localChar = IsValid(ax.client) and ax.client:GetCharacter() or nil
    local owner = entity:GetDoorOwner()
    local bOwnedByMe = localChar and owner and owner == localChar

    if ( bPurchased ) then
        if ( bOwnedByMe ) then
            DrawLine("Owned by you", Color(100, 200, 100))
        else
            DrawLine("Privately owned", Color(220, 160, 60))
        end
    elseif ( bOwnable ) then
        local cost = ax.config:Get("doors.purchase_cost", 10)
        DrawLine("For sale - " .. ax.currencies:Format(cost), Color(180, 180, 180))
    else
        DrawLine("Not for sale", Color(140, 140, 140))
    end

    if ( !bOwnedByMe and IsValid(ax.client) and ax.client:HasDoorAccess(entity) ) then
        DrawLine("You have access", Color(100, 160, 220))
    end
end
