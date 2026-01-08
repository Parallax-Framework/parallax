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
    default = "",
    hide = true
})

ax.character:RegisterVar("schema", {
    field = "schema",
    fieldType = ax.type.string,
    default = "parallax",
    hide = true
})

ax.character:RegisterVar("inventory", {
    field = "inventory",
    fieldType = ax.type.number,
    default = 0,
    bNoGetter = true,
    hide = true
})

ax.character:RegisterVar("faction", {
    field = "faction",
    fieldType = ax.type.number,
    category = "00_faction",
    localized = true,
    default = 0,
    validate = function(this, value, payload, client)
        if ( !isnumber(value) or value <= 0 ) then
            return false, "Invalid faction selection. Please choose a valid faction from the available options before proceeding to the next step."
        end

        if ( ax.faction:Get(value) == nil ) then
            return false, "The selected faction does not exist or is no longer available. Please refresh the character creation menu and choose a different faction."
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
        factionList:DockMargin(0, ax.util:ScreenScaleH(32), 0, 0)
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

        local buttonWidth = ax.util:ScreenScale(256)
        for i = 1, #factions do
            local v = factions[i]
            local can, reason = ax.faction:CanBecome(v.index, ax.client)
            if ( !can ) then
                ax.util:PrintDebug("Not showing faction '" .. v.name .. "' in selection: " .. reason)
                continue
            end

            local name = (v.name and utf8.upper(v.name)) or "UNKNOWN FACTION"
            local description = (v.description and utf8.upper(v.description)) or "UNKNOWN FACTION DESCRIPTION"
            description = ax.util:CapTextWord(description, buttonWidth / 2) -- Unreliable, but it works for now

            local descriptionWrapped = ax.util:GetWrappedText(description, "ax.regular.bold", buttonWidth - ax.util:ScreenScale(16))

            local factionButton = factionList:Add("ax.button.flat")
            factionButton:SetText("", true, true)
            factionButton:SetWide(buttonWidth)
            factionButton:Dock(LEFT)
            factionButton:DockMargin(ax.util:ScreenScale(2), 0, ax.util:ScreenScale(2), 0)

            factionButton.DoClick = function()
                table.Empty(payload or {})
                payload.faction = v.index

                if ( ax.gui.main.create.OnPayloadChanged ) then
                    ax.gui.main.create:OnPayloadChanged(payload)
                end

                hook.Run("OnPayloadChanged", payload)

                ax.gui.main.create:NavigateToNextTab(parent)
            end

            local banner = v.image or hook.Run("GetFactionBanner", v.index) or "parallax/banners/unknown.png"
            if ( isstring(banner) ) then
                banner = ax.util:GetMaterial(banner)
            end

            local image = factionButton:Add("EditablePanel")
            image:SetMouseInputEnabled(false)
            image:SetSize(factionButton:GetTall(), factionButton:GetTall())
            image:Dock(FILL)
            image.Paint = function(_, width, height)
                local imageHeight = height * 0.75
                imageHeight = math.Round(imageHeight)

                ax.render.DrawMaterial(0, 0, 0, width, imageHeight, color_white, banner)

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

                draw.SimpleText(name, font, ax.util:ScreenScale(8), imageHeight - boxHeight + boxHeightStatic / 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                local textHeight = ax.util:GetTextHeight("ax.regular.bold") / 1.5
                for d = 1, #descriptionWrapped do
                    draw.SimpleText(descriptionWrapped[d], "ax.regular.bold", ax.util:ScreenScale(8), imageHeight - boxHeight + boxHeightStatic + (d - 1) * textHeight, ColorAlpha(textColor, 255 * inertia), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end

            factionList:AddPanel(factionButton)
        end
    end,
    changed = function(character, value, previousValue, isNetworked, recipients)
        local client = character:GetOwner()
        if ( IsValid(client) ) then
            client:SetTeam(value)
        end

        local previousFaction = character:GetFactionData()
        local factionTable = ax.faction:Get(value)
        if ( previousFaction and isfunction(previousFaction.OnLeave) ) then
            previousFaction:OnLeave(character, value, previousValue, isNetworked, recipients)
        end

        if ( IsValid(client) ) then
            hook.Run("PlayerLoadout", client)
        end

        hook.Run("OnCharacterFactionChanged", character, value, previousValue, isNetworked, recipients)

        if ( factionTable and isfunction(factionTable.OnSet) ) then
            factionTable:OnSet(character, value, previousValue, isNetworked, recipients)
        end
    end
})

ax.character:RegisterVar("class", {
    field = "class",
    fieldType = ax.type.number,
    default = 0,
    hide = true,
    validate = function(this, value, payload, client)
        if ( !isnumber(value) or value < 0 ) then
            return false, "Invalid class selection. Please choose a valid character class from the available options for your selected faction."
        end

        if ( ax.class:Get(value) == nil ) then
            return false, "The selected character class does not exist or is no longer available. Please choose a different class or contact an administrator if this issue persists."
        end

        return true
    end,
    changed = function(character, value, previousValue, isNetworked, recipients)
        local previousClass = ax.class:Get(previousValue)
        if ( previousClass and isfunction(previousClass.OnLeave) ) then
            previousClass:OnLeave(character, value, previousValue, isNetworked, recipients)
        end

        local client = character:GetOwner()
        if ( IsValid(client) ) then
            hook.Run("PlayerLoadout", client)
        end

        hook.Run("OnCharacterClassChanged", character, value, previousValue, isNetworked, recipients)

        local classTable = ax.class:Get(value)
        if ( classTable and isfunction(classTable.OnSet) ) then
            classTable:OnSet(character, value, previousValue, isNetworked, recipients)
        end
    end
})

ax.character:RegisterVar("name", {
    field = "name",
    fieldType = ax.type.string,
    default = "Unnamed Character",
    sortOrder = 10,
    category = "01_identity",
    hints = {
        "Your name should be fitting to the theme of the server and roleplay setting.",
        "Use proper capitalization and provide both a first and last name."
    },
    validate = function(this, value, payload, client)
        if ( !isstring(value) or value == "" ) then
            return false, "Character name is required and cannot be left empty. Please enter a valid name for your character."
        end

        -- If the selected faction provides an immutable default name that matches the value,
        -- skip other validation (this allows a faction to supply a forced name).
        local factionData = nil
        if ( payload and payload.faction ) then
            factionData = ax.faction:Get(payload.faction)
        end

        if ( factionData and factionData.GetDefaultName ) then
            local _, disable = factionData:GetDefaultName(client)
            if ( disable == true ) then
                return true
            end
        end

        if ( string.len(value) > 32 ) then
            return false, "Character name is too long (maximum 32 characters allowed). Please shorten your name to fit within the character limit."
        end

        local trimmed = string.Trim(value)
        if ( trimmed != value ) then
            return false, "Character name cannot have leading or trailing spaces. Please remove any extra spaces at the beginning or end of the name."
        end

        -- Disallow control characters and non-ASCII
        if ( string.find(value, "%c") ) then
            return false, "Character name contains invalid control characters (such as tabs or line breaks). Please use only standard letters, spaces, and basic punctuation."
        end

        if ( string.find(value, "[\128-\255]") ) then
            return false, "Non-ASCII characters are not allowed in character names. Please use only standard English letters (A-Z, a-z) and basic punctuation."
        end

        -- Disallow links or obvious attempts to paste URLs
        if ( string.find(value, "http://", 1, true) or string.find(value, "https://", 1, true) or string.find(value, "www.", 1, true) ) then
            return false, "Character names may not contain web links or URLs. Please choose a realistic character name without website addresses."
        end

        -- No leading or trailing punctuation, no consecutive punctuation, no double spaces
        if ( string.find(trimmed, "^[%p]") or string.find(trimmed, "[%p]$") ) then
            return false, "Character name cannot start or end with punctuation marks. Please ensure your name begins and ends with a letter."
        end

        if ( string.find(trimmed, "[%p]%p") ) then
            return false, "Character name contains consecutive punctuation marks. Please use only single hyphens or apostrophes where appropriate (e.g., 'O'Connor' or 'Mary-Jane')."
        end

        if ( string.find(trimmed, "%s%s") ) then
            return false, "Character name contains multiple consecutive spaces. Please use only single spaces between name parts."
        end

        -- Prevent numbers and underscores
        if ( string.find(value, "%d") or string.find(value, "_") ) then
            return false, "Character names may not contain numbers or underscores. Please use only letters, spaces, hyphens, and apostrophes for a realistic name."
        end

        -- Require at least two words (first and last name)
        local _, wordCount = string.gsub(trimmed, "%S+", "")
        if ( wordCount < 2 ) then
            return false, "Please provide at least a first and last name for your character. Example: 'John Smith' or 'Maria Rodriguez'."
        end

        -- Each word must start with an uppercase letter and not be ALL CAPS
        for word in string.gmatch(trimmed, "%S+") do
            if ( !string.find(word, "^[%u]") ) then
                return false, "Each part of your character's name must start with an uppercase letter. Please capitalize the first letter of each name (e.g., 'John Smith', not 'john smith')."
            end

            if ( string.len(word) > 1 and word == utf8.upper(word) ) then
                return false, "Please avoid using ALL CAPS in character names. Use proper capitalization instead (e.g., 'Smith' instead of 'SMITH')."
            end

            -- Allow internal hyphens and apostrophes, but disallow other punctuation in words
            if ( string.find(word, "[^%a%-']") ) then
                return false, "Character names may only contain letters, hyphens, and apostrophes. Please remove any other special characters or punctuation marks."
            end
        end

        -- Prevent excessive repeated characters
        if ( string.find(value, "(.)%1%1%1") ) then
            return false, "Character name contains too many repeated characters in a row. Please use a more realistic name without excessive repetition (e.g., avoid 'Jooooohn')."
        end

        return true
    end,
    populatePost = function(this, container, payload, option, entry)
        local factionData = ax.faction:Get(payload.faction)
        if ( !factionData ) then return end

        entry:SetPlaceholderText("Enter your character's name")

        if ( factionData.allowNonAscii == true ) then
            entry:SetAllowNonAsciiCharacters(true)
        elseif ( factionData.allowNonAscii == false ) then
            entry:SetAllowNonAsciiCharacters(false)
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

        if ( this.hints ) then
            -- Clear docking to insert hints before re-docking
            entry:Dock(NODOCK)

            local hintZPos = this.sortOrder + 0.5
            for i, hintText in ipairs(this.hints) do
                local hint = container:Add("ax.text")
                hint:SetFont("ax.small.italic")
                hint:SetText("• " .. hintText)
                hint:SetTextColor(Color(200, 200, 200))
                hint:SetZPos(hintZPos + i * 0.1)
                hint:Dock(TOP)
            end

            -- Re-dock the entry after hints
            entry:SetZPos(this.sortOrder + 5)
            entry:Dock(TOP)
            entry:DockMargin(0, ax.util:ScreenScaleH(8), 0, ax.util:ScreenScaleH(16))
        end
    end
})

ax.character:RegisterVar("description", {
    field = "description",
    fieldType = ax.type.string,
    default = "This is a character description.",
    sortOrder = 20,
    category = "01_identity",
    hints = {
        "Describe your character's appearance, personality, background, or other distinctive features.",
        "Write in detail to help other players understand who your character is."
    },
    validate = function(this, value, payload, client)
        if ( !isstring(value) or value == "" ) then
            return false, "Character description is required and cannot be left empty. Please provide a description that tells other players about your character's appearance, personality, or background."
        end

        local trimmed = string.Trim(value)
        if ( trimmed == "" ) then
            return false, "Character description cannot consist only of whitespace or empty spaces. Please write a meaningful description of your character."
        end

        -- Disallow any newline or carriage return characters: descriptions must be single-line
        if ( string.find(value, "\n", 1, true) or string.find(value, "\r", 1, true) ) then
            return false, "Character description must be written as a single line of text. Please remove any line breaks and keep your description on one line."
        end

        -- Disallow control characters (tabs, binary/control bytes, etc.)
        if ( string.find(value, "%c") ) then
            return false, "Character description contains invalid control characters (such as tabs or special formatting). Please use only standard text characters."
        end

        -- Disallow URLs to prevent advertising/spam
        if ( string.find(value, "http://", 1, true) or string.find(value, "https://", 1, true) or string.find(value, "www.", 1, true) ) then
            return false, "Web links and URLs are not allowed in character descriptions. Please focus on describing your character rather than including website addresses."
        end

        -- Must contain at least one alphanumeric character
        if ( !string.find(value, "%w") ) then
            return false, "Character description must contain letters or numbers, not just punctuation or symbols. Please write a proper description using words."
        end

        -- Prevent excessive repeated characters (eg. "aaaaaaaaaaaa" or "!!!!!!")
        if ( string.find(value, "(.)%1%1%1%1%1%1%1%1%1") ) then
            return false, "Character description contains too many repeated characters in a row. Please write a normal description without excessive repetition (e.g., avoid 'sooooo coooool')."
        end

        -- Disallow basic HTML/markup tags
        if ( string.find(value, "<.->") ) then
            return false, "Character description may not contain HTML tags or markup code. Please use plain text to describe your character."
        end

        -- Require a reasonable proportion of alphanumeric characters to avoid emoji/punctuation spam
        local totalLen = math.max(1, string.len(value))
        local alphaCount = select(2, string.gsub(value, "%w", ""))
        if ( alphaCount / totalLen < 0.20 ) then
            return false, "Character description must contain more actual words and letters. Please write a proper description using primarily text rather than symbols or punctuation."
        end

        -- Require multiple words (ensure there are spaces / word separators so users expand their description)
        local _, wordCount = string.gsub(trimmed, "%S+", "")
        if ( wordCount < 2 ) then
            return false, "Character description must contain multiple words to be meaningful. Please write at least a few words to describe your character's appearance, personality, or background."
        end

        -- Enforce capitalization: require at least one uppercase letter among alphabetic characters
        local lettersOnly = string.gsub(trimmed, "[^%a]", "")
        if ( lettersOnly != "" and lettersOnly == utf8.lower(lettersOnly) ) then
            return false, "Character description should use proper capitalization for readability. Please capitalize the first letter of sentences and proper nouns."
        end

        return true
    end,
    populatePost = function(this, container, payload, option, entry)
        entry:SetTall(entry:GetTall() * 3)
        entry:SetMultiline(true)
        entry.AllowInput = function(_, character)
            if ( character == "\n" or character == "\r" ) then
                return true
            end
        end

        if ( this.hints ) then
            -- Clear docking to insert hints before re-docking
            entry:Dock(NODOCK)

            local hintZPos = this.sortOrder + 0.5
            for i, hintText in ipairs(this.hints) do
                local hint = container:Add("ax.text")
                hint:SetFont("ax.small.italic")
                hint:SetText("• " .. hintText)
                hint:SetTextColor(Color(200, 200, 200))
                hint:SetZPos(hintZPos + i * 0.1)
                hint:Dock(TOP)
            end

            -- Re-dock the entry after hints
            entry:SetZPos(this.sortOrder + 5)
            entry:Dock(TOP)
            entry:DockMargin(0, ax.util:ScreenScaleH(8), 0, ax.util:ScreenScaleH(16))
        end
    end
})

ax.character:RegisterVar("model", {
    field = "model",
    fieldType = ax.type.string,
    default = "models/player.mdl",
    sortOrder = 30,
    category = "02_appearance",
    validate = function(this, value, payload, client)
        if ( !isstring(value) or value == "" ) then
            return false, "You must select a character model before creating your character. Please choose one of the available models from the selection below."
        end

        if ( !util.IsValidModel(value) ) then
            return false, "The selected model file is invalid or corrupted. Please choose a different model or contact a developer if this problem continues."
        end

        local factionData = nil
        if ( payload and payload.faction ) then
            factionData = ax.faction:Get(payload.faction)
        end

        if ( factionData == nil ) then
            return false, "You must select a faction before choosing a character model. Please go back and select a faction first, then return to choose your model."
        end

        local valid = false
        for k, v in ipairs(factionData:GetModels()) do
            if ( istable(v) ) then
                if ( utf8.lower(v[1]) == utf8.lower(value) ) then
                    valid = true
                    break
                end
            elseif ( utf8.lower(v) == utf8.lower(value) ) then
                valid = true
                break
            end
        end

        if ( !valid ) then
            return false, "The selected character model is not allowed for your chosen faction. Please select one of the models specifically available to your faction."
        end

        return true
    end,
    populate = function(this, container, payload)
        local option = container:Add("ax.text")
        option:SetFont("ax.regular.bold")
        option:SetText(utf8.upper(ax.util:UniqueIDToName(this.key)))
        option:SetZPos(this.sortOrder - 1)
        option:Dock(TOP)

        local layout = container:Add("DIconLayout")
        layout:SetStretchHeight(true)
        layout:SetZPos(this.sortOrder)
        layout:Dock(TOP)
        layout:DockMargin(0, 0, 0, ax.util:ScreenScaleH(16))

        local factionID = payload.faction
        if ( !factionID or ax.faction:Get(factionID) == nil ) then
            ax.util:PrintWarning("Cannot populate model selection: invalid faction ID")
            return
        end

        local size = math.min(container:GetWide() / 8, 128)
        local models = ax.faction:Get(factionID):GetModels()
        for k, v in pairs(models) do
            local model = v
            local skin = 0
            if ( istable(v) ) then
                model = v[1]
                skin = v[2] or 0
            end

            local modelButton = layout:Add("SpawnIcon")
            modelButton:SetModel(model, skin)
            modelButton:SetSize(size, size)
            modelButton:SetTooltip(model)

            modelButton.DoClick = function()
                payload.model = model
                payload.skin = skin

                if ( ax.gui.main.create.OnPayloadChanged ) then
                    ax.gui.main.create:OnPayloadChanged(payload)
                end

                hook.Run("OnPayloadChanged", payload)
            end

            modelButton.PaintOver = function(_, width, height)
                if ( payload.model == model ) then
                    surface.SetDrawColor(0, 150, 255, 100)
                    surface.DrawRect(0, 0, width, height)
                end
            end
        end

        -- If the payload has no selected model yet, pick the first available model
        -- and ensure the skin payload is set. This is important for factions that
        -- force a skin via their model table and disable skin customization.
        if ( !payload.model and models[1] ) then
            local first = models[1]
            if ( istable(first) ) then
                payload.model = first[1]
                payload.skin = first[2] or 0
            else
                payload.model = first
                payload.skin = payload.skin or 0
            end

            if ( ax.gui.main.create.OnPayloadChanged ) then
                ax.gui.main.create:OnPayloadChanged(payload)
            end

            hook.Run("OnPayloadChanged", payload)
        end

        -- If a model is already selected but the skin is unset (or nil), ensure
        -- we populate the skin from the faction model entry so creation uses
        -- the forced skin when customization is disabled.
        if ( payload.model and payload.skin == nil ) then
            for _, mv in ipairs(models) do
                if ( istable(mv) and utf8.lower(mv[1]) == utf8.lower(payload.model) ) then
                    payload.skin = mv[2] or 0
                    break
                elseif ( !istable(mv) and utf8.lower(mv) == utf8.lower(payload.model) ) then
                    payload.skin = payload.skin or 0
                    break
                end
            end
        end

        layout:SizeToChildren(layout:GetStretchWidth(), layout:GetStretchHeight())
    end,
    changed = function(character, value, previousValue, isNetworked, recipients)
        local client = character:GetOwner()
        if ( IsValid(client) and client:GetModel() != value ) then
            client:SetModel(value)

            for i = 0, client:GetNumBodyGroups() - 1 do
                client:SetBodygroup(i, 0)
            end
        end

        character:SetData("bodygroups", nil) -- Reset bodygroups on model change

        -- Reset or apply the correct skin when the model changes. If the faction
        -- disallows skin customization, use the skin defined on the faction's
        -- model entry (models can be tables like { modelPath, skinIndex }).
        local factionData = character:GetFactionData()
        if ( factionData and factionData.allowSkinCustomization == false ) then
            local forcedSkin = 0
            for _, mv in ipairs(factionData:GetModels() or {}) do
                if ( istable(mv) ) then
                    if ( utf8.lower(mv[1]) == utf8.lower(value) ) then
                        forcedSkin = mv[2] or 0
                        break
                    end
                else
                    if ( utf8.lower(mv) == utf8.lower(value) ) then
                        forcedSkin = 0
                        break
                    end
                end
            end

            character:SetSkin(forcedSkin, true)
        else
            character:SetSkin(0, true) -- Reset skin to 0 when model changes, as skins are model-specific
        end
    end
})

ax.character:RegisterVar("skin", {
    field = "skin",
    fieldType = ax.type.number,
    default = 0,
    sortOrder = 40,
    category = "02_appearance",
    validate = function(this, value, payload, client)
        if ( !tonumber(value) ) then
            return false, "You must select a valid skin number for your character model. Please use the slider to choose a skin variant (usually 0-16) that you prefer for your character's appearance."
        end

        -- If the faction disallows skin customization, ensure the provided skin
        -- matches the forced skin for the selected model (if any).
        local factionData = nil
        if ( payload and payload.faction ) then
            factionData = ax.faction:Get(payload.faction)
        end

        if ( factionData and factionData.allowSkinCustomization == false ) then
            -- Determine the forced skin for the chosen model
            local forcedSkin = nil
            if ( payload and payload.model ) then
                for _, mv in ipairs(factionData:GetModels() or {}) do
                    if ( istable(mv) ) then
                        if ( utf8.lower(mv[1]) == utf8.lower(payload.model) ) then
                            forcedSkin = mv[2] or 0
                            break
                        end
                    else
                        if ( utf8.lower(mv) == utf8.lower(payload.model) ) then
                            forcedSkin = 0
                            break
                        end
                    end
                end
            end

            if ( forcedSkin != nil ) then
                if ( tonumber(value) != tonumber(forcedSkin) ) then
                    return false, "Skin value does not match the faction-forced skin for the selected model."
                end
            else
                -- No forced skin found; disallow arbitrary skin values for safety
                return false, "Skin customization is disabled for your selected faction."
            end
        end

        return true
    end,
    canPopulate = function(this, payload, client)
        local factionData = ax.faction:Get(payload.faction)
        if ( !factionData ) then return false end

        -- Client-side: only show the skin slider when the faction allows skin
        -- customization. If customization is disabled, hide the UI control.
        if ( CLIENT ) then
            return factionData.allowSkinCustomization != false
        end

        -- Server-side: allow population when customization is enabled. If the
        -- faction disallows customization, permit population only when the
        -- payload.model matches a faction model entry that defines a forced
        -- skin so the server can accept & persist the forced skin value.
        if ( factionData.allowSkinCustomization == false ) then
            if ( payload and payload.model ) then
                for _, mv in ipairs(factionData:GetModels() or {}) do
                    if ( istable(mv) and utf8.lower(mv[1]) == utf8.lower(payload.model) ) then
                        return true
                    end
                end
            end

            return false
        end

        return true
    end,
    populate = function(this, container, payload)
        local option = container:Add("ax.text")
        option:SetFont("ax.regular.bold")
        option:SetText(utf8.upper(ax.util:UniqueIDToName(this.key)))
        option:SetZPos(this.sortOrder - 1)
        option:Dock(TOP)

        local slider = container:Add("DNumSlider")
        slider:Dock(TOP)
        slider:DockMargin(0, 0, 0, ax.util:ScreenScaleH(16))
        slider:SetZPos(this.sortOrder)
        slider:SetMin(0)
        slider:SetMax(16)
        slider:SetDecimals(0)
        slider:SetValue(payload.skin or 0)
        slider.OnValueChanged = function(_, value)
            payload.skin = math.floor(value)

            if ( ax.gui.main.create.OnPayloadChanged ) then
                ax.gui.main.create:OnPayloadChanged(payload)
            end

            hook.Run("OnPayloadChanged", payload)
        end

        payload.skin = math.floor(slider:GetValue()) -- Ensure the skin is at least set to the default
    end,
    changed = function(character, value, previousValue, isNetworked, recipients)
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
    hide = true
})

ax.character:RegisterVar("lastPlayed", {
    field = "last_played",
    fieldType = ax.type.number,
    default = 0,
    hide = true
})

ax.character:RegisterVar("data", {
    field = "data",
    fieldType = ax.type.text,
    default = "[]",
    bNoGetter = true,
    bNoSetter = true,
    hide = true
})
