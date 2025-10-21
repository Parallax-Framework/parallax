local title

local PANEL = {}

function PANEL:Init()
    self.payload = {}
    self.tabs = {}

    -- Set payloads to defaults
    local vars = self:GetVars()
    for k, v in pairs(vars) do
        if ( !v.validate ) then continue end
        if ( v.hide ) then continue end

        -- Check if the variable can be populated during character creation
        if ( isfunction(v.canPopulate) ) then
            local canPop, err = pcall(function()
                return v:canPopulate(self.payload, ax.client)
            end)

            if ( !canPop ) then
                ax.util:PrintWarning(("Failed to check canPopulate for character var '%s': %s"):format(tostring(k), tostring(err)))
                continue
            end

            if ( !err ) then
                continue -- canPopulate returned false, skip this variable
            end
        end

        -- self.payload[k] = v.default -- Disabled default population for now
    end

    self:StartAtBottom()
    self:ClearVars() -- comment@bloodycop6385 > 'category' is nil here.
end

function PANEL:OnSlideStart()
    self:PopulateTabs()
end

function PANEL:GetVars()
    local vars = table.Copy(ax.character.vars)
    for k, v in pairs(vars) do
        v.category = v.category or "misc"
        v.sortOrder = v.sortOrder or 100
    end

    return vars
end

function PANEL:NavigateToNextTab(currentTab)
    -- If this is the last tab, submit the character
    if ( currentTab.index == table.Count(self.tabs) ) then
        net.Start("ax.character.create")
            net.WriteTable(self.payload)
        net.SendToServer()

        return
    end

    -- Otherwise, find and navigate to the next tab
    for k2, v2 in pairs(self.tabs) do
        if ( currentTab.index + 1 != v2.index ) then continue end
        if ( !IsValid(v2) ) then continue end

        currentTab:SlideLeft()
        v2:SlideToFront()
        self:ClearVars(k2)
        self:PopulateVars(k2)
        break
    end
end

function PANEL:NavigateToPreviousTab(currentTab)
    -- If this is the first tab, return to splash screen
    if ( currentTab.index == 1 ) then
        self:SlideDown(nil, function()
            self:ClearVars()
        end)
        self:GetParent().splash:SlideToFront()

        return
    end

    -- Otherwise, find and navigate to the previous tab
    for k2, v2 in pairs(self.tabs) do
        if ( currentTab.index - 1 != v2.index ) then continue end
        if ( !IsValid(v2) ) then continue end

        currentTab:SlideRight()
        v2:SlideToFront()
        self:ClearVars(k2)
        self:PopulateVars(k2)
        break
    end
end

function PANEL:PopulateTabs()
    local vars = self:GetVars()

    local index = 1
    for k, v in SortedPairsByMemberValue(vars, "category") do
        if ( !v.validate ) then continue end
        if ( v.hide ) then continue end

        local category = v.category or "misc"

        local tab = self.tabs[category]
        if ( !tab ) then
            tab = self:CreatePage(category)
            tab.index = index
            tab:StartAtRight()
            tab:CreateNavigation(tab, "back", function()
                self:NavigateToPreviousTab(tab)
            end, "next", function()
                self:NavigateToNextTab(tab)
            end)

            tab.container = tab:Add("EditablePanel")
            tab.container:Dock(FILL)
            tab.container:DockMargin(ax.util:ScreenScale(32), ax.util:ScreenScaleH(32), ax.util:ScreenScale(32), ax.util:ScreenScaleH(32))
            tab.container:InvalidateParent(true)

            self.tabs[category] = tab

            title = tab:Add("ax.text")
            title:SetFont("ax.huge.bold")
            title:SetText(string.upper(category))
            title:Dock(TOP)
            title:DockMargin(ax.util:ScreenScale(32), ax.util:ScreenScaleH(32), 0, 0)

            index = index + 1
        end
    end

    for k, v in SortedPairs(self.tabs) do
        if ( v.index != 1 ) then continue end

        v:SlideToFront(0)
        self:PopulateVars(k)
    end
end

function PANEL:GetContainer(category)
    category = category or "misc"

    local container = self.tabs[category]
    if ( !IsValid(container) ) then return end

    container = container.container
    if ( !IsValid(container) ) then return end

    return container
end

function PANEL:ClearVars(category)
    if ( !category ) then
        for k, v in pairs(self.tabs) do
            self:ClearVars(k)
        end

        return
    end

    local container = self:GetContainer(category)
    if ( !IsValid(container) ) then return end

    container:Clear()
end

function PANEL:PopulateVars(category)
    local vars = self:GetVars()

    category = category or "misc"

    local container = self:GetContainer(category)
    if ( !IsValid(container) ) then return end

    for k, v in SortedPairsByMemberValue(vars, "sortOrder") do
        if ( !v.validate ) then continue end
        if ( v.hide ) then continue end
        if ( (v.category or "misc") != category ) then continue end

        -- Check if the variable can be populated during character creation
        if ( isfunction(v.canPopulate) ) then
            local canPop, err = pcall(function()
                return v:canPopulate(self.payload, ax.client)
            end)

            if ( !canPop ) then
                ax.util:PrintWarning(("Failed to check canPopulate for character var '%s': %s"):format(tostring(k), tostring(err)))
                continue
            end

            if ( !err ) then
                continue -- canPopulate returned false, skip this variable
            end
        end

        if ( isfunction(v.populate) ) then
            local ok, err = pcall(function()
                v:populate(container, self.payload)
            end)

            if ( !ok ) then
                ax.util:PrintWarning(("Failed to populate character var '%s': %s"):format(tostring(k), tostring(err)))
            end

            continue
        end

        if ( v.fieldType == ax.type.string ) then
            local option = container:Add("ax.text")
            option:SetFont("ax.regular.bold")
            option:SetText(string.upper(ax.util:UniqueIDToName(k)))
            option:Dock(TOP)

            local entry = container:Add("ax.text.entry")
            entry:SetPlaceholderText(v.default)
            entry:Dock(TOP)
            entry:DockMargin(0, 0, 0, ax.util:ScreenScaleH(16))

            entry.OnValueChange = function(this)
                self.payload[k] = this:GetText()

                if ( self.OnPayloadChanged ) then
                    self:OnPayloadChanged(self.payload)
                end

                hook.Run("OnPayloadChanged", self.payload)
            end

            if ( isfunction(v.populatePost) ) then
                v:populatePost(container, self.payload, option, entry)
            end
        elseif ( v.fieldType == ax.type.number ) then
            local option = container:Add("ax.text")
            option:SetFont("ax.regular.bold")
            option:SetText(string.upper(ax.util:UniqueIDToName(k)))
            option:Dock(TOP)

            local slider = container:Add("DNumSlider")
            slider:SetMin(0)
            slider:SetMax(100)
            slider:SetValue(v.default)
            slider:Dock(TOP)
            slider:DockMargin(0, 0, 0, ax.util:ScreenScaleH(16))

            slider.OnValueChanged = function(this, value)
                self.payload[k] = value

                if ( self.OnPayloadChanged ) then
                    self:OnPayloadChanged(self.payload)
                end

                hook.Run("OnPayloadChanged", self.payload)
            end

            if ( isfunction(v.populatePost) ) then
                v:populatePost(container, self.payload, option, slider)
            end
        end
    end

    if ( self.OnPopulateVars ) then
        self:OnPopulateVars(container, category, self.payload)
    end

    hook.Run("OnCharacterPopulateVars", container, category, self.payload)
end

function PANEL:OnPopulateVars(container, category, payload)
    local targetCategory = category or "misc"
    for k, v in pairs(self:GetVars()) do
        if ( v.field == "model" ) then
            targetCategory = v.category or "misc"
            break
        end
    end

    if ( ax.util:FindString(category, targetCategory) ) then
        self.miscModel = container:Add("DModelPanel")
        self.miscModel:SetModel(payload.model or "models/player.mdl")
        self.miscModel:SetWide(0)
        self.miscModel:SetFOV(ax.util:ScreenScale(12))
        self.miscModel:Dock(LEFT)
        self.miscModel:DockMargin(0, 0, 0, 0)
        self.miscModel:SetZPos(-1)

        self.miscModel.LayoutEntity = function(this, entity)
            this:RunAnimation()
            entity:SetAngles(Angle(0, 90, 0))
        end

        local entity = self.miscModel:GetEntity()
        if ( IsValid(entity) ) then
            entity:SetSkin(payload.skin or 0)
        end

        payload.skin = nil -- Prevent skin from being set again in OnPayloadChanged
    end
end

function PANEL:OnPayloadChanged(payload)
    if ( IsValid(self.miscModel) ) then
        if ( payload.model and self.miscModel:GetModel() != payload.model ) then
            self.miscModel:SetModel(payload.model)
            if ( self.miscModel:GetWide() == 0 ) then
                self.miscModel:Motion(1, {
                    Target = {
                        width = self.miscModel:GetParent():GetWide() / 4,
                        rightPadding = ax.util:ScreenScale(32)
                    },
                    Easing = "OutQuad",
                    Think = function(this)
                        self.miscModel:SetWide(this.width)
                        self.miscModel:DockMargin(0, 0, this.rightPadding, 0)
                    end
                })
            end
        end

        self.miscModel:GetEntity():SetSkin(payload.skin or 0)
    end
end

function PANEL:Paint(width, height)
end

vgui.Register("ax.main.create", PANEL, "ax.transition.pages")
