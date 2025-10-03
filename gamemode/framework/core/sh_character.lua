--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.character:RegisterVar("steamID64", {
    field = "steamid64",
    fieldType = ax.type.steamid64,
    default = ""
})

ax.character:RegisterVar("schema", {
    field = "schema",
    fieldType = ax.type.string,
    default = "parallax"
})

ax.character:RegisterVar("inventory", {
    field = "inventory",
    fieldType = ax.type.number,
    default = 0,
    bNoGetter = true
})

ax.character:RegisterVar("faction", {
    field = "faction",
    fieldType = ax.type.number,
    category = "faction",
    default = 0,
    validate = function(this, value)
        if ( !isnumber(value) or value <= 0 ) then
            return false, "Invalid faction ID"
        end

        if ( ax.faction:Get(value) == nil ) then
            return false, "Faction does not exist"
        end

        return true
    end,
    populate = function(this, container, payload)
        local parent = container:GetParent()
        if ( !IsValid(parent) ) then
            ax.util:PrintWarning("Cannot populate faction selection: invalid parent container")
            return
        end

        parent:DeleteNavigationButtonByText("next")

        local factionList = container:Add("ax.scroller.horizontal")
        factionList:Dock(FILL)
        factionList:DockMargin(0, ScreenScaleH(32), 0, 0)
        factionList:InvalidateParent(true)
        factionList.Paint = nil

        factionList.btnLeft:SetAlpha(0)
        factionList.btnRight:SetAlpha(0)

        local factions = table.Copy(ax.faction:GetAll())
        table.sort(factions, function(a, b)
            local aSort = a.sortOrder or 100
            local bSort = b.sortOrder or 100

            -- If the sort orders are equal, sort by name
            if ( aSort == bSort ) then
                return a.name < b.name
            end

            return aSort < bSort
        end)

        local buttonWidth = ScreenScale(256)
        for i = 1, #factions do
            local v = factions[i]
            if ( !ax.faction:CanBecome(v.index, ax.client) ) then continue end

            local name = (v.name and string.upper(v.name)) or "UNKNOWN FACTION"
            local description = (v.description and string.upper(v.description)) or "UNKNOWN FACTION DESCRIPTION"
            description = ax.util:CapTextWord(description, buttonWidth / 2) -- Unreliable, but it works for now

            local descriptionWrapped = ax.util:GetWrappedText(description, "ax.regular.bold", buttonWidth - ScreenScale(16))

            local factionButton = factionList:Add("ax.button.flat")
            factionButton:SetText("", true, true)
            factionButton:SetWide(buttonWidth)
            factionButton:Dock(LEFT)
            factionButton:DockMargin(ScreenScale(2), 0, ScreenScale(2), 0)

            factionButton.DoClick = function()
                payload.faction = v.index

                for k2, v2 in pairs(ax.gui.main.create.tabs) do
                    if ( parent.index + 1 == v2.index ) then
                        if ( !IsValid(v2) ) then continue end

                        parent:SlideLeft()
                        v2:SlideToFront()
                        ax.gui.main.create:ClearVars(k2)
                        ax.gui.main.create:PopulateVars(k2)
                        break
                    end
                end
            end

            local banner = v.image or hook.Run("GetFactionBanner", v.index) or "gamepadui/hl2/chapter14"
            if ( isstring( banner ) ) then
                banner = ax.util:GetMaterial(banner)
            end

            local image = factionButton:Add("EditablePanel")
            image:SetMouseInputEnabled(false)
            image:SetSize(factionButton:GetTall(), factionButton:GetTall())
            image:Dock(FILL)
            image.Paint = function(this, width, height)
                local imageHeight = height * 0.75
                imageHeight = math.Round(imageHeight)

                surface.SetDrawColor(color_white)
                surface.SetMaterial(banner)
                surface.DrawTexturedRect(0, 0, width, imageHeight)

                local inertia = factionButton:GetInertia()
                local boxHeightStatic = (height * 0.15)
                boxHeightStatic = math.Round(boxHeightStatic)

                local boxHeight = boxHeightStatic * inertia
                boxHeight = math.Round(boxHeight)
                ax.render.Draw(0, 0, imageHeight - boxHeight, width, boxHeight, Color(255, 255, 255, 255 * inertia))

                local textColor = factionButton:GetTextColor()
                local hovered = factionButton:IsHovered()
                local font = "ax.huge"
                if ( v.Font ) then
                    font = v.Font
                elseif ( name:len() > 22 ) then
                    font = "ax.massive"
                end

                if ( hovered ) then
                    font = font .. ".bold"
                end

                draw.SimpleText(name, font, ScreenScale(8), imageHeight - boxHeight + boxHeightStatic / 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                local textHeight = ax.util:GetTextHeight("ax.regular.bold") / 1.5
                for d = 1, #descriptionWrapped do
                    draw.SimpleText(descriptionWrapped[d], "ax.regular.bold", ScreenScale(8), imageHeight - boxHeight + boxHeightStatic + (d - 1) * textHeight, ColorAlpha(textColor, 255 * inertia), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end

            factionList:AddPanel(factionButton)
        end
    end,
    changed = function(character, value, isNetworked, recipients)
        local client = character:GetOwner()
        if ( IsValid(client) ) then
            client:SetTeam(value)
        end
    end
})

ax.character:RegisterVar("class", {
    field = "class",
    fieldType = ax.type.number,
    default = 0,
    hide = true,
    validate = function(this, value)
        if ( !isnumber(value) or value < 0 ) then
            return false, "Invalid class ID"
        end

        if ( ax.class:Get(value) == nil ) then
            return false, "Class does not exist"
        end

        return true
    end
})

ax.character:RegisterVar("name", {
    field = "name",
    fieldType = ax.type.string,
    default = "Unnamed Character",
    sortOrder = 1,
    validate = function(this, value)
        if ( !isstring(value) or value == "" ) then
            return false, "Name cannot be empty"
        end

        if ( string.len(value) > 32 ) then
            return false, "Name cannot exceed 32 characters"
        end

        return true
    end,
    populatePost = function(this, container, payload, option, entry)
        local factionData = ax.faction:Get(payload.faction)
        if ( !factionData ) then return end

        entry:SetPlaceholderText(factionData:GetDefaultName(ax.client) or "Enter your character's name")

        if ( factionData.allowNonAscii == true ) then
            entry:SetAllowNonAsciiCharacters(true)
        elseif ( factionData.allowNonAscii == false ) then
            entry:SetAllowNonAsciiCharacters(false)
        else
            -- Don't change the default setting
        end

        if ( factionData.GetDefaultName ) then
            local name, disable = factionData:GetDefaultName(ax.client)
            if ( disable == true ) then
                entry:SetDisabled(true)
            else
                entry:SetDisabled(false)
            end

            payload.name = name
            entry:SetText(name)
        end
    end
})

ax.character:RegisterVar("description", {
    field = "description",
    fieldType = ax.type.string,
    default = "This is a character description.",
    sortOrder = 2,
    validate = function(this, value)
        if ( !isstring(value) or value == "" ) then
            return false, "Description cannot be empty"
        end

        if ( string.len(value) > 256 ) then
            return false, "Description cannot exceed 256 characters"
        end

        return true
    end,
    populatePost = function(this, container, payload, option, entry)
        entry:SetTall(entry:GetTall() * 2)
        entry:SetMultiline(true)
    end
})

ax.character:RegisterVar("model", {
    field = "model",
    fieldType = ax.type.string,
    default = "models/player.mdl",
    sortOrder = 3,
    validate = function(this, value)
        if ( !isstring(value) or value == "" ) then
            return false, "Model cannot be empty"
        end

        if ( !util.IsValidModel(value) ) then
            return false, "Invalid model"
        end

        return true
    end,
    populate = function(this, container, payload)
        local option = container:Add("ax.text")
        option:SetFont("ax.regular.bold")
        option:SetText(string.upper(ax.util:UniqueIDToName(this.key)))
        option:Dock(TOP)

        local layout = container:Add("DIconLayout")
        layout:SetStretchHeight(true)
        layout:Dock(TOP)
        layout:DockMargin(0, 0, 0, ScreenScaleH(16))

        local factionID = payload.faction
        if ( !factionID or ax.faction:Get(factionID) == nil ) then
            ax.util:PrintWarning("Cannot populate model selection: invalid faction ID")
            return
        end

        local size = math.min(container:GetWide() / 8, 128)
        for k, v in pairs(ax.faction:Get(factionID):GetModels()) do
            if ( istable(v) ) then v = v[1] end

            local modelButton = layout:Add("SpawnIcon")
            modelButton:SetModel(v)
            modelButton:SetSize(size, size)
            modelButton:SetTooltip(v)

            modelButton.DoClick = function()
                payload.model = v

                if ( ax.gui.main.create.OnPayloadChanged ) then
                    ax.gui.main.create:OnPayloadChanged(payload)
                end

                hook.Run("OnPayloadChanged", payload)
            end

            modelButton.PaintOver = function(this, width, height)
                if ( payload.model == v ) then
                    surface.SetDrawColor(0, 150, 255, 100)
                    surface.DrawRect(0, 0, width, height)
                end
            end
        end

        layout:SizeToChildren(layout:GetStretchWidth(), layout:GetStretchHeight())
    end,
    changed = function(character, value, isNetworked, recipients)
        local client = character:GetOwner()
        if ( IsValid(client) and client:GetModel() != value ) then
            client:SetModel(value)
        end
    end
})

ax.character:RegisterVar("skin", {
    field = "skin",
    fieldType = ax.type.number,
    default = 0,
    sortOrder = 4,
    validate = function(this, value)
        if ( !isnumber(value) ) then
            return false, "Skin must be a number"
        end

        return true
    end,
    populate = function(this, container, payload)
        local option = container:Add("ax.text")
        option:SetFont("ax.regular.bold")
        option:SetText(string.upper(ax.util:UniqueIDToName(this.key)))
        option:Dock(TOP)

        local slider = container:Add("DNumSlider")
        slider:SetMin(0)
        slider:SetMax(16)
        slider:SetDecimals(0)
        slider:SetValue(payload.skin or 0)
        slider:Dock(TOP)
        slider:DockMargin(0, 0, 0, ScreenScaleH(16))
        slider.OnValueChanged = function(this, value)
            payload.skin = math.floor(value)

            if ( ax.gui.main.create.OnPayloadChanged ) then
                ax.gui.main.create:OnPayloadChanged(payload)
            end

            hook.Run("OnPayloadChanged", payload)
        end
    end,
    changed = function(character, value, isNetworked, recipients)
        local client = character:GetOwner()
        if ( IsValid(client) and client:GetModel() != value ) then
            client:SetSkin(value)
        end
    end
})

ax.character:RegisterVar("creationTime", {
    field = "creation_time",
    fieldType = ax.type.number,
    default = 0,
})

ax.character:RegisterVar("lastPlayed", {
    field = "last_played",
    fieldType = ax.type.number,
    default = 0,
})

ax.character:RegisterVar("data", {
    field = "data",
    fieldType = ax.type.text,
    default = "[]",
    bNoGetter = true,
    bNoSetter = true
})
