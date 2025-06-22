--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:SetVisible(false)

    self.currentCreatePage = 0
end

function PANEL:ResetPayload()
    self.currentCreatePage = 0

    for k, v in pairs(ax.character.variables) do
        if ( v.Editable != true ) then continue end

        -- This is a bit of a hack, but it works for now.
        if ( v.Type == ax.types.string or v.Type == ax.types.text ) then
            self:SetPayload(k, "")
        end
    end
end

function PANEL:SetPayload(key, value)
    if ( !self.currentCreatePayload ) then
        self.currentCreatePayload = {}
    end

    self.currentCreatePayload[key] = value
end

function PANEL:GetPayload(key)
    if ( !self.currentCreatePayload ) then
        self.currentCreatePayload = {}
    end

    return self.currentCreatePayload[key]
end

function PANEL:PopulateFactionSelect()
    local parent = self:GetParent()
    parent:SetGradientLeftTarget(0)
    parent:SetGradientRightTarget(0)
    parent:SetGradientTopTarget(1)
    parent:SetGradientBottomTarget(1)
    parent:SetDimTarget(0.25)
    parent.container:Clear()
    parent.container:SetVisible(false)

    self:Clear()
    self:SetVisible(true)

    local title = self:Add("ax.text")
    title:Dock(TOP)
    title:DockMargin(ScreenScale(32), ScreenScaleH(32), 0, 0)
    title:SetFont("ax.huge.bold")
    title:SetText(string.upper("mainmenu.create.character.faction"))

    local navigation = self:Add("EditablePanel")
    navigation:Dock(BOTTOM)
    navigation:DockMargin(ScreenScale(32), 0, ScreenScale(32), ScreenScaleH(32))
    navigation:SetTall(ScreenScaleH(24))

    local backButton = navigation:Add("ax.button.flat")
    backButton:Dock(LEFT)
    backButton:SetText("back")
    backButton.DoClick = function()
        self.currentCreatePage = 0
        self:ResetPayload()

        self:Clear()
        self:SetVisible(false)
        parent:Populate()
    end

    navigation:SetTall(backButton:GetTall())

    local factionList = self:Add("ax.scroller.horizontal")
    factionList:Dock(FILL)
    factionList:DockMargin(ScreenScale(32), ScreenScale(32) * 2, ScreenScale(32), ScreenScale(32))
    factionList:InvalidateParent(true)
    factionList.Paint = nil

    factionList.btnLeft:SetAlpha(0)
    factionList.btnRight:SetAlpha(0)

    local factions = table.Copy(ax.faction:GetAll())
    table.sort(factions, function(a, b)
        local aSort = a.SortOrder or 100
        local bSort = b.SortOrder or 100

        -- If the sort orders are equal, sort by name
        if ( aSort == bSort ) then
            return a.Name < b.Name
        end

        return aSort < bSort
    end)

    for i = 1, #factions do
        local v = factions[i]
        if ( !ax.faction:CanSwitchTo(ax.client, v:GetID()) ) then continue end

        local name = (v.Name and ax.utf8:Upper(v.Name)) or "UNKNOWN FACTION"
        local description = (v.Description and ax.utf8:Upper(v.Description)) or "UNKNOWN FACTION DESCRIPTION"
        description = ax.util:CapTextWord(description, factionList:GetTall() / 3) -- Unreliable, but it works for now

        local descriptionWrapped = ax.util:GetWrappedText(description, "ax.bold", factionList:GetTall() * 1.25)

        local factionButton = factionList:Add("ax.button.flat")
        factionButton:Dock(LEFT)
        factionButton:DockMargin(0, 0, 16, 0)
        factionButton:SetText(v.Name or "Unknown Faction")
        factionButton:SetWide(factionList:GetTall() * 1.5)

        factionButton.DoClick = function()
            self.currentCreatePage = 0
            self:ResetPayload()
            self:SetPayload("faction", v:GetID())

            self:PopulateCreateCharacter()
        end

        local banner = v.Image or hook.Run("GetFactionBanner", v:GetID()) or "gamepadui/hl2/chapter14"
        if ( type(banner) == "string" ) then
            banner = ax.util:GetMaterial(banner)
        end

        local image = factionButton:Add("DPanel")
        image:Dock(FILL)
        image:SetMouseInputEnabled(false)
        image:SetSize(factionButton:GetTall(), factionButton:GetTall())
        image.Paint = function(this, width, height)
            local imageHeight = height * 0.85
            imageHeight = math.Round(imageHeight)

            surface.SetDrawColor(ax.color:Get("white"))
            surface.SetMaterial(banner)
            surface.DrawTexturedRect(0, 0, width, imageHeight)

            local inertia = factionButton:GetInertia()
            local boxHeightStatic = (height * 0.15)
            boxHeightStatic = math.Round(boxHeightStatic)

            local boxHeight = boxHeightStatic * inertia
            boxHeight = math.Round(boxHeight)
            draw.RoundedBox(0, 0, imageHeight - boxHeight, width, boxHeight, ColorAlpha(ax.color:Get("white"), 255 * inertia))

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

            local textHeight = ax.util:GetTextHeight("ax.bold") / 1.5
            for d = 1, #descriptionWrapped do
                draw.SimpleText(descriptionWrapped[d], "ax.bold", ScreenScale(8), imageHeight - boxHeight + boxHeightStatic + (d - 1) * textHeight, ColorAlpha(textColor, 255 * inertia), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end

        factionList:AddPanel(factionButton)
    end
end

function PANEL:PopulateCreateCharacter()
    -- If we have no payload, reset it
    if ( !self.currentCreatePayload ) then
        self.currentCreatePayload = {}
    end

    -- If we have no faction select the 1st one available
    if ( !self.currentCreatePayload.faction or self.currentCreatePayload.faction == 0 ) then
        local factions = ax.faction:GetAll()
        if ( factions[1] != nil ) then
            for i = 1, #factions do
                if ( ax.faction:CanSwitchTo(ax.client, factions[i]:GetID()) ) then
                    self.currentCreatePayload.faction = factions[i]:GetID()
                    break
                end
            end
        else
            ax.util:PrintError("No factions available for character creation!")
            return
        end
    end

    local parent = self:GetParent()
    parent:SetGradientLeftTarget(0)
    parent:SetGradientRightTarget(0)
    parent:SetGradientTopTarget(1)
    parent:SetGradientBottomTarget(1)
    parent.container:Clear()
    parent.container:SetVisible(false)

    self:Clear()
    self:SetVisible(true)

    local title = self:Add("ax.text")
    title:Dock(TOP)
    title:DockMargin(ScreenScale(32), ScreenScaleH(32), 0, 0)
    title:SetFont("ax.huge.bold")
    title:SetText(string.upper("mainmenu.create.character"))

    local navigation = self:Add("EditablePanel")
    navigation:Dock(BOTTOM)
    navigation:DockMargin(ScreenScale(32), 0, ScreenScale(32), ScreenScaleH(32))
    navigation:SetTall(ScreenScaleH(24))

    local backButton = navigation:Add("ax.button.flat")
    backButton:Dock(LEFT)
    backButton:SetText("back")

    backButton.DoClick = function()
        if ( self.currentCreatePage == 0 ) then
            local availableFactions = 0
            for i = 1, #ax.faction:GetAll() do
                local v = ax.faction:GetAll()[i]
                if ( ax.faction:CanSwitchTo(ax.client, v:GetID()) ) then
                    availableFactions = availableFactions + 1
                end
            end

            if ( availableFactions > 1 ) then
                self:PopulateFactionSelect()
            else
                self.currentCreatePage = 0
                self:ResetPayload()
                parent:Populate()
                self:Clear()
            end
        else
            self.currentCreatePage = self.currentCreatePage - 1
            self:PopulateCreateCharacterForm()
        end
    end

    local nextButton = navigation:Add("ax.button.flat")
    nextButton:Dock(RIGHT)
    nextButton:SetText("next")

    nextButton.DoClick = function()
        local isNextEmpty = true
        for k, v in pairs(ax.character.variables) do
            if ( v.Editable != true ) then continue end

            if ( isfunction(v.OnValidate) ) then
                local isValid, errorMessage = v:OnValidate(self.characterCreateForm, self.currentCreatePayload, ax.client)
                if ( !isValid ) then
                    ax.client:Notify(errorMessage)
                    return
                end
            end

            local page = v.Page or 0
            if ( page != self.currentCreatePage + 1 ) then continue end

            if ( isfunction(v.OnValidate) ) then
                isNextEmpty = v:OnValidate(self.characterCreateForm, self.currentCreatePayload, ax.client)
                if ( isNextEmpty ) then continue end
            end

            if ( v.Type == ax.types.string or v.Type == ax.types.text ) then
                local entry = self.characterCreateForm:GetChild(k)
                if ( entry and entry:GetValue() != "" ) then
                    self:SetPayload(k, entry:GetValue())
                    isNextEmpty = false
                end
            end
        end

        if ( isNextEmpty ) then
            ax.net:Start("character.create", self.currentCreatePayload)
        else
            self.currentCreatePage = self.currentCreatePage + 1
            self:PopulateCreateCharacterForm()
        end
    end

    navigation:SetTall(math.max(backButton:GetTall(), nextButton:GetTall()))

    self:PopulateCreateCharacterForm()
end

function PANEL:PopulateCreateCharacterForm()
    self:SetVisible(true)

    if ( !IsValid(self.characterCreateForm) ) then
        self.characterCreateForm = self:Add("EditablePanel")
        self.characterCreateForm:Dock(FILL)
        self.characterCreateForm:DockMargin(ScreenScale(32) * 6, ScreenScaleH(16), ScreenScale(32) * 6, ScreenScaleH(32))
    else
        self.characterCreateForm:Clear()
    end

    local factionData = ax.faction:Get(self.currentCreatePayload.faction)
    if ( !factionData ) then
        ax.util:PrintError("No faction data found for faction ID: " .. tostring(self.currentCreatePayload.faction))
        return
    end

    local zPos = 0
    for k, v in pairs(ax.character.variables) do
        if ( v.Editable != true ) then continue end

        local page = v.Page or 0
        if ( page != self.currentCreatePage ) then continue end

        if ( isfunction(v.OnPopulate) ) then
            v:OnPopulate(self.characterCreateForm, self.currentCreatePayload)
            continue
        end

        local translation = ax.localization:GetPhrase(v.Name)
        local bTranslated = translation != v.Name

        if ( v.Type == ax.types.string ) then
            zPos = zPos + 1 + v.ZPos

            local label = self.characterCreateForm:Add("ax.text")
            label:Dock(TOP)
            label:SetFont("ax.large.bold")

            label:SetText(bTranslated and translation or v.Name or k)

            zPos = zPos - 1
            label:SetZPos(zPos)
            zPos = zPos + 1

            local entry = self.characterCreateForm:Add("ax.text.entry")
            entry:Dock(TOP)
            entry:DockMargin(0, 0, 0, ScreenScaleH(16))
            entry:SetFont("parallax")
            entry:SetPlaceholderText(v.Default or "")
            entry:SetTall(ScreenScaleH(16))
            entry:SetZPos(zPos)

            entry:SetNumeric(v.Numeric or false)
            entry:SetAllowNonAsciiCharacters(v.AllowNonAscii or false)

            entry.OnTextChanged = function(this)
                local text = this:GetValue()

                if ( isfunction(v.OnChange) ) then
                    v:OnChange(this, text, self.currentCreatePayload)
                end

                self:SetPayload(k, text)
            end

            if ( factionData.GetDefaultName and k == "name" ) then
                local defaultName, forced = factionData:GetDefaultName(ax.client)
                if ( defaultName and defaultName != "" ) then
                    entry:SetValue(defaultName)
                    self:SetPayload(k, defaultName)

                    if ( forced ) then
                        entry:SetEnabled(false)
                        entry:SetTooltip("This field is automatically generated by the faction.")
                    end
                end
            end
        elseif ( v.Type == ax.types.text ) then
            zPos = zPos + 1 + v.ZPos

            local label = self.characterCreateForm:Add("ax.text")
            label:Dock(TOP)
            label:SetText(bTranslated and translation or v.Name or k)
            label:SetFont("ax.large.bold")
            label:SizeToContents()

            zPos = zPos - 1
            label:SetZPos(zPos)
            zPos = zPos + 1

            local entry = self.characterCreateForm:Add("ax.text.entry")
            entry:Dock(TOP)
            entry:DockMargin(0, 0, 0, ScreenScaleH(16))
            entry:SetFont("parallax")
            entry:SetPlaceholderText(v.Default or "")
            entry:SetMultiline(true)
            entry:SetTall(ScreenScaleH(12) * 4)
            entry:SetZPos(zPos)

            entry.OnTextChanged = function(this)
                local text = this:GetValue()

                if ( isfunction(v.OnChange) ) then
                    v:OnChange(this, text, self.currentCreatePayload)
                end

                self:SetPayload(k, text)
            end

            if ( factionData.GetDefaultDescription and k == "description" ) then
                local defaultDescription = factionData:GetDefaultDescription(ax.client)
                if ( defaultDescription and defaultDescription != "" ) then
                    entry:SetValue(defaultDescription)
                    self:SetPayload(k, defaultDescription)
                end
            end
        end
    end
end

vgui.Register("ax.mainmenu.create", PANEL, "EditablePanel")