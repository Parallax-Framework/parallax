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
    self:Dock(FILL)

    self.buttons = self:Add("ax.scroller.horizontal")
    self.buttons:Dock(TOP)
    self.buttons:DockMargin(0, ScreenScaleH(4), 0, 0)
    self.buttons:SetTall(ScreenScaleH(24))
    self.buttons.Paint = nil

    self.buttons.btnLeft:SetAlpha(0)
    self.buttons.btnRight:SetAlpha(0)

    self.container = self:Add("ax.scroller.vertical")
    self.container:Dock(FILL)
    self.container:GetVBar():SetWide(0)
    self.container.Paint = nil

    self.search = self:Add("ax.text.entry")
    self.search:Dock(TOP)
    self.search:SetUpdateOnType(true)
    self.search:SetPlaceholderText(ax.localization:GetPhrase("search.description.options"))
    self.search.OnValueChange = function(this, value)
        if ( value and value != "" ) then
            self:PopulateCategory(nil, value)
        else
            self:PopulateCategory(ax.gui.OptionsLast)
        end
    end

    local categories = {}
    for k, v in pairs(ax.option.stored) do
        local found = false
        for i = 1, #categories do
            if ( categories[i] == v.Category ) then
                found = true
                break
            end
        end

        if ( found ) then continue end

        table.insert(categories, v.Category)
    end

    for k, v in SortedPairs(categories) do
        local button = self.buttons:Add("ax.button.flat")
        button:Dock(LEFT)
        button:SetText(v)
        button:SizeToContents()

        button.DoClick = function()
            self:PopulateCategory(v)
        end

        self.buttons:AddPanel(button)
    end

    if ( ax.gui.OptionsLast ) then
        self:PopulateCategory(ax.gui.OptionsLast)
    else
        self:PopulateCategory(categories[1])
    end
end

function PANEL:PopulateCategory(category, toSearch)
    if ( category ) then
        ax.gui.OptionsLast = category
    end

    self.container:Clear()

    local options = {}
    for k, v in pairs(ax.option.stored) do
        if ( category and ax.util:FindString(v.Category, category) == false ) then
            continue
        end

        if ( toSearch and ax.util:FindString(ax.localization:GetPhrase(v.Name), toSearch) == false ) then
            continue
        end

        table.insert(options, v)
    end

    table.sort(options, function(a, b)
        return ax.localization:GetPhrase(a.Name) < ax.localization:GetPhrase(b.Name)
    end)

    local subCategories = {}
    for i = 1, #options do
        local v = options[i]
        local subCategory = string.lower(v.SubCategory or "")
        if ( subCategory and !subCategories[subCategory] ) then
            subCategories[subCategory] = true
        end
    end

    if ( table.Count(subCategories) > 1 ) then
        for k, v in SortedPairs(subCategories) do
            local label = self.container:Add("ax.text")
            label:Dock(TOP)
            label:DockMargin(0, 0, 0, ScreenScaleH(4))
            label:SetFont("ax.huge.bold")
            label:SetText(string.upper(k))

            for k2, v2 in SortedPairs(options) do
                if ( string.lower(v2.SubCategory or "") == string.lower(k) ) then
                    self:AddOption(v2)
                end
            end
        end
    else
        for k, v in SortedPairs(options) do
            self:AddOption(v)
        end
    end
end

function PANEL:AddOption(optionData)
    local value = ax.option:Get(optionData.UniqueID)

    local panel = self.container:Add("ax.button.flat")
    panel:Dock(TOP)
    panel:SetText(optionData.Name)
    panel:SetTall(ScreenScaleH(26))
    panel:SetContentAlignment(4)
    panel:SetTextInset(ScreenScale(6), 0)

    local enabled = ax.localization:GetPhrase("enabled")
    local enable = ax.localization:GetPhrase("enable")
    local disabled = ax.localization:GetPhrase("disabled")
    local disable = ax.localization:GetPhrase("disable")
    local unknown = ax.localization:GetPhrase("unknown")

    local label
    local options
    if ( optionData.Type == ax.types.bool ) then
        label = panel:Add("ax.text")
        label:Dock(RIGHT)
        label:DockMargin(0, 0, ScreenScale(8), 0)
        label:SetText(value and enabled or disabled, true)
        label:SetFont("ax.large")
        label:SetWide(ScreenScale(128))
        label:SetContentAlignment(6)
        label.Think = function(this)
            this:SetTextColor(panel:GetTextColor())
        end

        panel.DoClick = function()
            ax.option:Set(optionData.UniqueID, !value)
            value = !value

            label:SetText(value and "< " .. enabled .. " >" or "< " .. disabled .. " >", true)
        end

        panel.DoRightClick = function(this)
            local menu = DermaMenu()
            menu:AddOption(ax.localization:GetPhrase("reset"), function()
                ax.option:Reset(optionData.UniqueID)
                value = ax.option:Get(optionData.UniqueID)

                label:SetText(value and enabled or disabled, true)
            end):SetIcon("icon16/arrow_refresh.png")
            menu:AddSpacer()
            menu:AddOption(value and disable or enable, function()
                ax.option:Set(optionData.UniqueID, !value)
                value = !value

                label:SetText(value and "< " .. enabled .. " >" or "< " .. disabled .. " >", true)
            end):SetIcon(value and "icon16/cross.png" or "icon16/tick.png")

            if ( ax.client:IsDeveloper() and ax.config:Get("debug.developer") ) then
                menu:AddSpacer()
                menu:AddOption(ax.localization:GetPhrase("copy"), function()
                    SetClipboardText(configData.UniqueID)
                    ax.client:EmitSound("ui/buttonclickrelease.wav", 60, 100, 0.1, CHAN_STATIC)
                end):SetIcon("icon16/pencil.png")
            end

            menu:Open()
        end
    elseif ( optionData.Type == ax.types.number and optionData.IsKeybind ) then
        local bind = panel:Add("ax.binder")
        bind:Dock(RIGHT)
        bind:DockMargin(ScreenScale(8), ScreenScaleH(4), ScreenScale(8), ScreenScaleH(4))
        bind:SetWide(ScreenScale(128))
        bind:SetValue(value)

        bind.OnChange = function(this, newValue)
            ax.option:Set(optionData.UniqueID, newValue)
            value = newValue
            ax.client:EmitSound("ui/buttonclickrelease.wav", 60, pitch, 0.1, CHAN_STATIC)
        end

        panel.DoRightClick = function()
            local menu = DermaMenu()
            menu:AddOption(ax.localization:GetPhrase("reset"), function()
                ax.option:Reset(optionData.UniqueID)
                value = ax.option:Get(optionData.UniqueID)

                bind:SetValue(value)
            end):SetIcon("icon16/arrow_refresh.png")

            if ( ax.client:IsDeveloper() and ax.config:Get("debug.developer") ) then
                menu:AddSpacer()
                menu:AddOption(ax.localization:GetPhrase("copy"), function()
                    SetClipboardText(configData.UniqueID)
                    ax.client:EmitSound("ui/buttonclickrelease.wav", 60, 100, 0.1, CHAN_STATIC)
                end):SetIcon("icon16/pencil.png")
            end

            menu:Open()
        end
    elseif ( optionData.Type == ax.types.number ) then
        local slider = panel:Add("ax.slider")
        slider:Dock(RIGHT)
        slider:DockMargin(ScreenScale(8), ScreenScaleH(4), ScreenScale(8), ScreenScaleH(4))
        slider:SetWide(ScreenScale(128))
        slider:SetMouseInputEnabled(false)

        slider.Paint = function(this, width, height)
            draw.RoundedBox(0, 0, 0, width, height, ax.color:Get("background.slider"))
            local fraction = (this.value - this.min) / (this.max - this.min)
            local barWidth = math.Clamp(fraction * width, 0, width)
            local inertia = panel:GetInertia()
            local full = 255 * (-inertia + 1)
            draw.RoundedBox(0, 0, 0, barWidth, height, Color(full, full, full, 255))
        end

        slider.Think = function(this)
            local x, y = this:CursorPos()
            local w, h = this:GetSize()
            if ( x >= 0 and x <= w and y >= 0 and y <= h ) then
                this.bCursorInside = true
            else
                this.bCursorInside = false
            end
        end

        slider:SetMin(optionData.Min or 0)
        slider:SetMax(optionData.Max or 100)
        slider:SetDecimals(optionData.Decimals or 0)
        slider:SetValue(value, true)

        label = panel:Add("ax.text")
        label:Dock(RIGHT)
        label:DockMargin(0, 0, -ScreenScale(4), 8)
        label:SetText(value, true, true, true)
        label:SetFont("ax.large")
        label:SetWide(ScreenScale(128))
        label:SetContentAlignment(6)
        label.Think = function(this)
            this:SetTextColor(panel:GetTextColor())
            this:SetText(tostring(slider:GetValue()), true, true)
        end

        slider.OnValueChanged = function(this, _)
            ax.option:Set(optionData.UniqueID, this:GetValue())
            ax.client:EmitSound("ui/buttonrollover.wav", 100, 100, 1, CHAN_STATIC)
        end

        panel.DoClick = function(this)
            if ( !slider.bCursorInside ) then
                local oldValue = value
                ax.option:Reset(optionData.UniqueID)

                value = ax.option:Get(optionData.UniqueID)
                slider:SetValue(value, true)
                label:SetText(value, true, true, true)

                if ( isfunction(optionData.OnReset) ) then
                    optionData:OnReset(oldValue, value)
                end

                return
            end

            slider.dragging = true
            slider:MouseCapture(true)
            slider:OnCursorMoved(slider:CursorPos())
        end

        panel.DoRightClick = function(this)
            local menu = DermaMenu()
            menu:AddOption(ax.localization:GetPhrase("reset"), function()
                ax.option:Reset(optionData.UniqueID)
                value = ax.option:Get(optionData.UniqueID)

                slider:SetValue(value, true)
                label:SetText(value, true, true, true)

                if ( isfunction(optionData.OnReset) ) then
                    optionData:OnReset(oldValue, value)
                end
            end):SetIcon("icon16/arrow_refresh.png")
            menu:AddSpacer()
            menu:AddOption(ax.localization:GetPhrase("set", optionData.Name), function()
                Derma_StringRequest(
                    ax.localization:GetPhrase("set", optionData.Name),
                    ax.localization:GetPhrase("set.description.options", optionData.Name),
                    value,
                    function(text)
                        if ( text == "" ) then return  end

                        local num = tonumber(text)

                        if ( num ) then
                            ax.option:Set(optionData.UniqueID, num)
                            value = num

                            slider:SetValue(value, true)
                            label:SetText(value, true, true, true)
                        end
                    end
                )
            end):SetIcon("icon16/pencil.png")

            if ( ax.client:IsDeveloper() and ax.config:Get("debug.developer") ) then
                menu:AddSpacer()
                menu:AddOption(ax.localization:GetPhrase("copy"), function()
                    SetClipboardText(configData.UniqueID)
                    ax.client:EmitSound("ui/buttonclickrelease.wav", 60, 100, 0.1, CHAN_STATIC)
                end):SetIcon("icon16/pencil.png")
            end

            menu:Open()
        end
    elseif ( optionData.Type == ax.types.array ) then
        options = optionData:Populate()
        local keys = {}
        for k2, _ in pairs(options) do
            table.insert(keys, k2)
        end

        local phrase = (options and options[value]) and ax.localization:GetPhrase(options[value]) or unknown

        label = panel:Add("ax.text")
        label:Dock(RIGHT)
        label:DockMargin(0, 0, ScreenScale(8), 0)
        label:SetText(phrase, true)
        label:SetFont("ax.large")
        label:SetWide(ScreenScale(128))
        label:SetContentAlignment(6)
        label.Think = function(this)
            this:SetTextColor(panel:GetTextColor())
        end

        panel.DoClick = function()
            -- Pick the next key depending on where the cursor is near the label, if the cursor is near the left side of the label, pick the previous key, if it's near the right side, pick the next key.
            local x, _ = label:CursorPos() -- not used
            local w, _ = label:GetSize() -- not used
            local percent = x / w
            local nextKey = nil
            for i = 1, #keys do
                if ( keys[i] == value ) then
                    nextKey = keys[i + (percent < 0.5 and -1 or 1)] or keys[1]
                    break
                end
            end

            nextKey = nextKey or keys[1]
            nextKey = tostring(nextKey)

            ax.option:Set(optionData.UniqueID, nextKey)
            value = nextKey

            label:SetText("< " .. (options and options[value] or unknown) .. " >", true)
        end

        panel.DoRightClick = function()
            local menu = DermaMenu()
            menu:AddOption(ax.localization:GetPhrase("reset"), function()
                ax.option:Reset(optionData.UniqueID)
                value = ax.option:Get(optionData.UniqueID)

                label:SetText("< " .. (options and options[value] or unknown) .. " >", true)
            end):SetIcon("icon16/arrow_refresh.png")
            menu:AddSpacer()
            for k2, v2 in SortedPairs(options) do
                menu:AddOption(v2, function()
                    ax.option:Set(optionData.UniqueID, k2)
                    value = k2

                    phrase = (options and options[value]) and ax.localization:GetPhrase(options[value]) or unknown
                    label:SetText(panel:IsHovered() and "< " .. phrase .. " >" or phrase, true)
                end):SetIcon("icon16/tick.png")
            end

            if ( ax.client:IsDeveloper() and ax.config:Get("debug.developer") ) then
                menu:AddSpacer()
                menu:AddOption(ax.localization:GetPhrase("copy"), function()
                    SetClipboardText(configData.UniqueID)
                    ax.client:EmitSound("ui/buttonclickrelease.wav", 60, 100, 0.1, CHAN_STATIC)
                end):SetIcon("icon16/pencil.png")
            end

            menu:Open()
        end
    elseif ( optionData.Type == ax.types.color ) then
        local color = panel:Add("EditablePanel")
        color:Dock(RIGHT)
        color:DockMargin(ScreenScale(8), ScreenScaleH(4), ScreenScale(8), ScreenScaleH(4))
        color:SetWide(ScreenScale(128))
        color:SetMouseInputEnabled(false)
        color.color = value
        color.Paint = function(this, width, height)
            draw.RoundedBox(0, 0, 0, width, height, this.color)
        end

        panel.DoClick = function()
            local blocker = vgui.Create("EditablePanel", self)
            blocker:SetSize(ScrW(), ScrH())
            blocker:SetPos(0, 0)
            blocker:MakePopup()
            blocker.Paint = function(this, width, height)
                ax.util:DrawBlur(this, 2)
                draw.RoundedBox(0, 0, 0, width, height, Color(0, 0, 0, 200))
            end
            blocker.OnMousePressed = function(this, key)
                if ( key == MOUSE_LEFT ) then
                    this:Remove()
                end
            end
            blocker.OnKeyPressed = function(this, key)
                this:Remove()
            end
            blocker.Think = function(this)
                if ( ! system.HasFocus() ) then
                    this:Remove()
                end
            end
            blocker.OnRemove = function(this)
                ax.option:Set(optionData.UniqueID, value)
            end

            local frame = blocker:Add("EditablePanel")
            frame:SetSize(300, 200)
            frame:SetPos(gui.MouseX() - 150, gui.MouseY() - 100)

            local mixer = frame:Add("DColorMixer")
            mixer:Dock(FILL)
            mixer:SetAlphaBar(false)
            mixer:SetPalette(true)
            mixer:SetWangs(true)
            mixer:SetColor(value)
            mixer.ValueChanged = function(this, old)
                local new = Color(old.r, old.g, old.b, 255)
                value = new
                color.color = new
            end
        end

        panel.DoRightClick = function(this)
            local menu = DermaMenu()
            menu:AddOption(ax.localization:GetPhrase("reset"), function()
                ax.option:Reset(optionData.UniqueID)
                value = ax.option:Get(optionData.UniqueID)

                color.color = value
            end):SetIcon("icon16/arrow_refresh.png")

            if ( ax.client:IsDeveloper() and ax.config:Get("debug.developer") ) then
                menu:AddSpacer()
                menu:AddOption(ax.localization:GetPhrase("copy"), function()
                    SetClipboardText(configData.UniqueID)
                    ax.client:EmitSound("ui/buttonclickrelease.wav", 60, 100, 0.1, CHAN_STATIC)
                end):SetIcon("icon16/pencil.png")
            end

            menu:Open()
        end
    elseif ( optionData.Type == ax.types.string ) then
        local text = panel:Add("ax.text.entry")
        text:Dock(RIGHT)
        text:DockMargin(ScreenScale(8), ScreenScaleH(4), ScreenScale(8), ScreenScaleH(4))
        text:SetWide(ScreenScale(128))
        text:SetFont("ax.large")
        text:SetText(value)

        text.OnEnter = function(this)
            local newValue = this:GetText()
            if ( newValue == value ) then return end

            ax.option:Set(optionData.UniqueID, newValue)
            value = newValue

            ax.client:EmitSound("ui/buttonclickrelease.wav", 60, pitch, 0.1, CHAN_STATIC)
        end

        panel.DoRightClick = function()
            local menu = DermaMenu()
            menu:AddOption(ax.localization:GetPhrase("reset"), function()
                ax.option:Reset(optionData.UniqueID)
                value = ax.option:Get(optionData.UniqueID)

                text:SetText(value)
            end):SetIcon("icon16/arrow_refresh.png")
            menu:AddSpacer()
            menu:AddOption(ax.localization:GetPhrase("set", optionData.Name), function()
                Derma_StringRequest(
                    ax.localization:GetPhrase("set", optionData.Name),
                    ax.localization:GetPhrase("set.description.options", optionData.Name),
                    value,
                    function(textString)
                        if ( textString != "" ) then
                            ax.option:Set(optionData.UniqueID, textString)
                            value = textString

                            text:SetText(textString)
                        end
                    end
                )
            end):SetIcon("icon16/pencil.png")

            if ( ax.client:IsDeveloper() and ax.config:Get("debug.developer") ) then
                menu:AddSpacer()
                menu:AddOption(ax.localization:GetPhrase("copy"), function()
                    SetClipboardText(configData.UniqueID)
                    ax.client:EmitSound("ui/buttonclickrelease.wav", 60, 100, 0.1, CHAN_STATIC)
                end):SetIcon("icon16/pencil.png")
            end

            menu:Open()
        end
    else
        return
    end

    panel.OnHovered = function(this)
        if ( optionData.Type == ax.types.bool ) then
            label:SetText(value and "< " .. enabled .. " >" or "< " .. disabled .. " >", true)
        elseif ( optionData.Type == ax.types.array ) then
            local phrase = (options and options[value]) and ax.localization:GetPhrase(options[value]) or unknown
            label:SetText("< " .. phrase .. " >", true)
        end

        if ( !IsValid(ax.gui.Tooltip) ) then
            ax.gui.Tooltip = vgui.Create("ax.tooltip")
            ax.gui.Tooltip:SetText(optionData.Name, optionData.Description)
            ax.gui.Tooltip:SizeToContents()
            ax.gui.Tooltip:SetPanel(this)
        else
            ax.gui.Tooltip:SetText(optionData.Name, optionData.Description)
            ax.gui.Tooltip:SizeToContents()

            timer.Simple(0, function()
                if ( IsValid(ax.gui.Tooltip) ) then
                    ax.gui.Tooltip:SetPanel(this)
                end
            end)
        end
    end

    panel.OnUnHovered = function(this)
        if ( optionData.Type == ax.types.bool ) then
            label:SetText(value and enabled or disabled, true)
        elseif ( optionData.Type == ax.types.array ) then
            local phrase = (options and options[value]) and ax.localization:GetPhrase(options[value]) or unknown
            label:SetText(phrase, true)
        end

        if ( IsValid(ax.gui.Tooltip) ) then
            ax.gui.Tooltip:SetPanel(nil)
        end
    end
end

vgui.Register("ax.options", PANEL, "EditablePanel")

ax.gui.OptionsLast = nil