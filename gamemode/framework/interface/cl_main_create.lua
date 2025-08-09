local PANEL = {}

--[[
net.Start("ax.character.create")
    net.WriteTable({
        name = "John Doe",
        description = "A new character",
    })
net.SendToServer()
]]

local function CreateNavigation(parent, backText, backCallback, nextText, nextCallback)
    local navigation = parent:Add("EditablePanel")
    navigation:Dock(BOTTOM)
    navigation:DockMargin(ScreenScale(32), 0, ScreenScale(32), ScreenScaleH(32))

    local backButton = navigation:Add("ax.button.flat")
    backButton:Dock(LEFT)
    backButton:SetText(backText)
    backButton.DoClick = backCallback

    if ( nextText and nextCallback ) then
        local nextButton = navigation:Add("ax.button.flat")
        nextButton:Dock(RIGHT)
        nextButton:SetText(nextText)
        nextButton.DoClick = nextCallback
    end

    navigation:SetTall(math.max(backButton:GetTall(), nextButton and nextButton:GetTall() or 0))

    return navigation
end

function PANEL:Init()
    local parent = self:GetParent()

    self.payload = {}

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())

    self.factionSelection = self:Add("ax.transition")
    self.factionSelection:SlideToFront()

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

        local descriptionWrapped = ax.util:GetWrappedText(description, "ax.regular.bold", factionList:GetTall() * 1.25)

        local factionButton = factionList:Add("ax.button.flat")
        factionButton:Dock(LEFT)
        factionButton:DockMargin(0, 0, 0, 0)
        factionButton:SetText("", true, true)
        factionButton:SetWide(math.min(factionList:GetTall() * 1.25, factionList:GetWide() / 2))

        factionButton.DoClick = function()
            self.payload.faction = v.id

            self.factionSelection:SlideLeft()
            self.characterOptions:SlideToFront()
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
            local x, y = ScreenScale(4), ScreenScaleH(4)
            width, height = width - x * 2, height - y * 2
            local imageHeight = height * 0.85
            imageHeight = math.Round(imageHeight)

            surface.SetDrawColor(color_white)
            surface.SetMaterial(banner)
            surface.DrawTexturedRect(x, y, width, imageHeight)

            local inertia = factionButton:GetInertia()
            local boxHeightStatic = (height * 0.15)
            boxHeightStatic = math.Round(boxHeightStatic)

            local boxHeight = boxHeightStatic * inertia
            boxHeight = math.Round(boxHeight)
            draw.RoundedBox(0, x, imageHeight - boxHeight, width, boxHeight, Color(255, 255, 255, 255 * inertia))

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

    title = self.characterOptions:Add("ax.text")
    title:Dock(TOP)
    title:DockMargin(ScreenScale(32), ScreenScaleH(32), 0, 0)
    title:SetFont("ax.huge.bold")
    title:SetText("CUSTOMIZE YOUR CHARACTER")

    CreateNavigation(self.factionSelection, "back", function()
        self:SlideDown()
        parent.splash:SlideToFront()
    end)

    CreateNavigation(self.characterOptions, "back", function()
        self.characterOptions:SlideRight()
        self.factionSelection:SlideToFront()
    end, "next", function()
        -- TODO: Implement character customization options
    end)
end

vgui.Register("ax.main.create", PANEL, "ax.transition")