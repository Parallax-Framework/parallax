local PANEL = {}

function PANEL:Init()
    local parent = self:GetParent()

    self.payload = {}

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())

    self.factionSelection = self:Add("ax.transition")
    self.factionSelection:SlideToFront()

    self:CreateNavigation(self.factionSelection, "back", function()
        self:SlideDown()
        parent.splash:SlideToFront()
    end)

    local title = self.factionSelection:Add("ax.text")
    title:Dock(TOP)
    title:DockMargin(ScreenScale(32), ScreenScaleH(32), 0, 0)
    title:SetFont("ax.huge.bold")
    title:SetText("SELECT YOUR FACTION")

    local factionList = self.factionSelection:Add("ax.scroller.horizontal")
    factionList:Dock(FILL)
    factionList:DockMargin(ScreenScale(32), ScreenScaleH(32) * 2, ScreenScale(32), ScreenScaleH(32))
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
        if ( !ax.faction:CanBecome(v.id, ax.client) ) then continue end

        local name = (v.Name and string.upper(v.Name)) or "UNKNOWN FACTION"
        local description = (v.Description and string.upper(v.Description)) or "UNKNOWN FACTION DESCRIPTION"
        description = ax.util:CapTextWord(description, factionList:GetTall() / 3) -- Unreliable, but it works for now

        local descriptionWrapped = ax.util:GetWrappedText(description, "ax.regular.bold", math.min(factionList:GetTall() * 1.125, factionList:GetWide() / 2))

        local factionButton = factionList:Add("ax.button.flat")
        factionButton:Dock(LEFT)
        factionButton:DockMargin(8, 0, 8, 0)
        factionButton:SetText("", true, true)
        factionButton:SetWide(math.min(factionList:GetTall() * 1.25, factionList:GetWide() / 2))

        factionButton.DoClick = function()
            self.payload.faction = v.id

            self.factionSelection:SlideLeft()
            self.characterOptions:SlideToFront()
            self:PopulateVars()
        end

        local banner = v.Image or hook.Run("GetFactionBanner", v.id) or "gamepadui/hl2/chapter14"
        if ( type(banner) == "string" ) then
            banner = ax.util:GetMaterial(banner)
        end

        local image = factionButton:Add("DPanel")
        image:Dock(FILL)
        image:SetMouseInputEnabled(false)
        image:SetSize(factionButton:GetTall(), factionButton:GetTall())
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
            draw.RoundedBox(0, 0, imageHeight - boxHeight, width, boxHeight, Color(255, 255, 255, 255 * inertia))

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

    self.characterOptions = self:Add("ax.transition")
    self.characterOptions:StartAtRight()

    self:CreateNavigation(self.characterOptions, "back", function()
        self.characterOptions:SlideRight()
        self.factionSelection:SlideToFront()

        self:ClearVars()
    end, "finish", function()
        -- temporarily send payload
        net.Start("ax.character.create")
            net.WriteTable({
                name = "John Doe",
                description = "A new character",
            })
        net.SendToServer()
    end)

    title = self.characterOptions:Add("ax.text")
    title:Dock(TOP)
    title:DockMargin(ScreenScale(32), ScreenScaleH(32), 0, 0)
    title:SetFont("ax.huge.bold")
    title:SetText("CUSTOMIZE YOUR CHARACTER")

    self.characterOptions.container = self.characterOptions:Add("EditablePanel")
    self.characterOptions.container:Dock(FILL)
    self.characterOptions.container:DockMargin(ScreenScale(32), ScreenScaleH(32), ScreenScale(32), 0)
end

function PANEL:ClearVars()
    local container = self.characterOptions.container
    if ( !container ) then return end

    container:Clear()
end

function PANEL:PopulateVars()
    local container = self.characterOptions.container
    if ( !container ) then return end

    for k, v in pairs(ax.character.vars) do
        print(k, v)

        if ( isfunction(v.populate) ) then
            v:populate(container, self.payload)
            continue
        end

        if ( v.fieldType == ax.type.string ) then
            local option = container:Add("ax.text")
            option:SetText(v.field)
            option:Dock(TOP)

            local entry = container:Add("ax.text.entry")
            entry:SetText(v.default)
            entry:Dock(TOP)
            entry:DockMargin(0, 0, 0, ScreenScaleH(16))

            entry.OnValueChange = function(this)
                print(this:GetText())
            end
        elseif ( v.fieldType == ax.type.number ) then
            local option = container:Add("ax.text")
            option:SetText(v.field)
            option:Dock(TOP)

            local slider = container:Add("DNumSlider")
            slider:SetMin(0)
            slider:SetMax(100)
            slider:SetValue(v.default)
            slider:Dock(TOP)
            slider:DockMargin(0, 0, 0, ScreenScaleH(16))

            slider.OnValueChanged = function(this, value)
                print(value)
            end
        end
    end
end

vgui.Register("ax.main.create", PANEL, "ax.transition")