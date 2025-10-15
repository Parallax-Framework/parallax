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
    self:ClearVars(category)
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
                if ( tab.index == 1 ) then
                    self:SlideDown(nil, function()
                        self:ClearVars()
                    end)
                    self:GetParent().splash:SlideToFront()
                else
                    for k2, v2 in pairs(self.tabs) do
                        if ( tab.index - 1 == v2.index ) then
                            if ( !IsValid(v2) ) then continue end

                            tab:SlideRight()
                            v2:SlideToFront()
                            self:ClearVars(k2)
                            self:PopulateVars(k2)
                            break
                        end
                    end
                end
            end, "next", function()
                for k2, v2 in pairs(self.tabs) do
                    if ( tab.index == table.Count(self.tabs) ) then
                        net.Start("ax.character.create")
                            net.WriteTable(self.payload)
                        net.SendToServer()

                        break
                    elseif ( tab.index + 1 == v2.index ) then
                        if ( !IsValid(v2) ) then continue end

                        tab:SlideLeft()
                        v2:SlideToFront()
                        self:ClearVars(k2)
                        self:PopulateVars(k2)
                        break
                    end
                end
            end)

            tab.container = tab:Add("EditablePanel")
            tab.container:Dock(FILL)
            tab.container:DockMargin(ax.util:UIScreenScale(32), ax.util:UIScreenScaleH(32), ax.util:UIScreenScale(32), ax.util:UIScreenScaleH(32))
            tab.container:InvalidateParent(true)

            self.tabs[category] = tab

            title = tab:Add("ax.text")
            title:SetFont("ax.huge.bold")
            title:SetText(string.upper(category))
            title:Dock(TOP)
            title:DockMargin(ax.util:UIScreenScale(32), ax.util:UIScreenScaleH(32), 0, 0)

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
            entry:DockMargin(0, 0, 0, ax.util:UIScreenScaleH(16))

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
            slider:DockMargin(0, 0, 0, ax.util:UIScreenScaleH(16))

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
    if ( ax.util:FindString(category, "misc") ) then
        self.miscModel = container:Add("DModelPanel")
        self.miscModel:SetModel(payload.model or "models/props_c17/oildrum001.mdl")
        self.miscModel:SetWide(container:GetWide() / 4)
        self.miscModel:SetFOV(ax.util:UIScreenScale(12))
        self.miscModel:Dock(LEFT)
        self.miscModel:DockMargin(0, 0, ax.util:UIScreenScale(32), 0)
        self.miscModel:SetZPos(-1)

        self.miscModel.LayoutEntity = function(this, entity)
            this:RunAnimation()
            entity:SetAngles(Angle(0, 90, 0))
        end
    end
end

function PANEL:OnPayloadChanged(payload)
    if ( IsValid(self.miscModel) ) then
        if ( payload.model and self.miscModel:GetModel() != payload.model ) then
            self.miscModel:SetModel(payload.model)
        end

        self.miscModel:GetEntity():SetSkin(payload.skin or 0)
    end
end

function PANEL:Paint(width, height)
end

vgui.Register("ax.main.create", PANEL, "ax.transition.pages")
