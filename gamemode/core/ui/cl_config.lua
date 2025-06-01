local padding = ScreenScale(32)

DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)

    self.buttons = self:Add("ax.scroller.horizontal")
    self.buttons:Dock(TOP)
    self.buttons:DockMargin(0, padding / 8, 0, 0)
    self.buttons:SetTall(ScreenScale(24))
    self.buttons.Paint = nil

    self.buttons.btnLeft:SetAlpha(0)
    self.buttons.btnRight:SetAlpha(0)

    self.container = self:Add("ax.scroller.vertical")
    self.container:Dock(FILL)
    self.container:GetVBar():SetWide(0)
    self.container.Paint = nil

    local categories = {}
    for k, v in pairs(ax.config.stored) do
        if ( table.HasValue(categories, v.Category) ) then continue end

        table.insert(categories, v.Category)
    end

    for k, v in SortedPairs(categories) do
        local button = self.buttons:Add("ax.button.small")
        button:Dock(LEFT)
        button:SetText(v)
        button:SizeToContents()

        button.DoClick = function()
            self:PopulateCategory(v)
        end

        self.buttons:AddPanel(button)
    end

    if ( ax.gui.configLast ) then
        self:PopulateCategory(ax.gui.configLast)
    else
        self:PopulateCategory(categories[1])
    end
end

function PANEL:PopulateCategory(category)
    ax.gui.configLast = category

    self.container:Clear()

    local config = {}
    for k, v in pairs(ax.config.stored) do
        if ( string.lower(v.Category) == string.lower(category) ) then
            table.insert(config, v)
        end
    end

    table.sort(config, function(a, b)
        return ax.localization:GetPhrase(a.Name) < ax.localization:GetPhrase(b.Name)
    end)

    local subCategories = {}
    for k, v in ipairs(config) do
        local subCategory = string.lower(v.SubCategory or "")
        if ( subCategory and !subCategories[subCategory] ) then
            subCategories[subCategory] = true
        end
    end

    if ( table.Count(subCategories) > 1 ) then
        for k, v in SortedPairs(subCategories) do
            local label = self.container:Add("ax.text")
            label:Dock(TOP)
            label:DockMargin(0, 0, 0, ScreenScale(4))
            label:SetFont("parallax.title")
            label:SetText(string.upper(k))

            for k2, v2 in SortedPairs(config) do
                if ( string.lower(v2.SubCategory or "") == string.lower(k) ) then
                    self:AddConfig(v2)
                end
            end
        end
    else
        for k, v in SortedPairs(config) do
            self:AddConfig(v)
        end
    end
end

function PANEL:AddConfig(configData)
    local value = ax.config:Get(configData.UniqueID)

    local panel = self.container:Add("ax.button.small")
    panel:Dock(TOP)
    panel:SetText(configData.Name)
    panel:SetTall(ScreenScale(20))
    panel:SetContentAlignment(4)
    panel:SetTextInset(ScreenScale(6), 0)

    local enabled = ax.localization:GetPhrase("enabled")
    local disabled = ax.localization:GetPhrase("disabled")
    local unknown = ax.localization:GetPhrase("unknown")

    local label
    local configs
    if ( configData.Type == ax.types.bool ) then
        label = panel:Add("ax.text")
        label:Dock(RIGHT)
        label:DockMargin(0, 0, ScreenScale(8), 0)
        label:SetText(value and enabled or disabled, true)
        label:SetFont("parallax.button")
        label:SetWide(ScreenScale(128))
        label:SetContentAlignment(6)
        label.Think = function(this)
            this:SetTextColor(panel:GetTextColor())
        end

        panel.DoClick = function()
            ax.net:Start("config.set", configData.UniqueID, !value)

            value = !value

            label:SetText(value and "< " .. enabled .. " >" or "< " .. disabled .. " >", true)
        end

        panel.DoRightClick = function()
            local menu = DermaMenu()
            menu:AddOption(ax.localization:GetPhrase("reset"), function()
                ax.net:Start("config.reset", configData.UniqueID)

                value = ax.config:GetDefault(configData.UniqueID)
                label:SetText(value and enabled or disabled, true)
            end)
            menu:Open()
        end
    elseif ( configData.Type == ax.types.number ) then
        local slider = panel:Add("ax.slider")
        slider:Dock(RIGHT)
        slider:DockMargin(ScreenScale(8), ScreenScale(6), ScreenScale(8), ScreenScale(6))
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

        slider:SetMin(configData.Min or 0)
        slider:SetMax(configData.Max or 100)
        slider:SetDecimals(configData.Decimals or 0)
        slider:SetValue(value, true)

        label = panel:Add("ax.text")
        label:Dock(RIGHT)
        label:DockMargin(0, 0, -ScreenScale(4), 8)
        label:SetText(value)
        label:SetFont("parallax.button.small")
        label:SetWide(ScreenScale(128))
        label:SetContentAlignment(6)
        label.Think = function(this)
            this:SetTextColor(panel:GetTextColor())
            this:SetText(tostring(slider:GetValue()), true, true)
        end

        slider.OnValueChanged = function(this, _)
            ax.net:Start("config.set", configData.UniqueID, this:GetValue())
            ax.client:EmitSound("ui/buttonrollover.wav", 100, 100, 1, CHAN_STATIC)
        end

        panel.DoClick = function(this)
            if ( !slider.bCursorInside ) then
                ax.net:Start("config.reset", configData.UniqueID)

                value = ax.config:GetDefault(configData.UniqueID)
                slider:SetValue(value)
                label:SetText(value)

                return
            end

            slider.dragging = true
            slider:MouseCapture(true)
            slider:OnCursorMoved(slider:CursorPos())
        end

        panel.DoRightClick = function(this)
            local menu = DermaMenu()
            menu:AddOption(ax.localization:GetPhrase("reset"), function()
                ax.net:Start("config.reset", configData.UniqueID)

                value = ax.config:GetDefault(configData.UniqueID)
                slider:SetValue(value)
                label:SetText(value)
            end)
            menu:Open()
        end
    elseif ( configData.Type == ax.types.array ) then
        configs = configData:Populate()
        local keys = {}
        for k2, _ in pairs(configs) do
            table.insert(keys, k2)
        end

        local phrase = (configs and configs[value]) and ax.localization:GetPhrase(configs[value]) or unknown

        label = panel:Add("ax.text")
        label:Dock(RIGHT)
        label:DockMargin(0, 0, ScreenScale(8), 0)
        label:SetText(phrase, true)
        label:SetFont("parallax.button")
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

            ax.net:Start("config.set", configData.UniqueID, nextKey)

            value = nextKey

            label:SetText("< " .. (configs and configs[value] or "Unknown") .. " >", true)
        end

        panel.DoRightClick = function()
            local menu = DermaMenu()
            menu:AddOption(ax.localization:GetPhrase("reset"), function()
                ax.net:Start("config.reset", configData.UniqueID)

                value = ax.config:GetDefault(configData.UniqueID)
                label:SetText(configs and configs[value] or unknown, true)
            end)
            menu:AddSpacer()
            for k2, v2 in SortedPairs(configs) do
                menu:AddOption(v2, function()
                    ax.net:Start("config.set", configData.UniqueID, k2)

                    value = k2

                    phrase = (configs and configs[value]) and ax.localization:GetPhrase(configs[value]) or unknown
                    label:SetText(panel:IsHovered() and "< " .. phrase .. " >" or phrase, true)
                end)
            end
            menu:Open()
        end
    elseif ( configData.Type == ax.types.color ) then
        local color = panel:Add("EditablePanel")
        color:Dock(RIGHT)
        color:DockMargin(ScreenScale(8), ScreenScale(6), ScreenScale(8), ScreenScale(6))
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
                ax.net:Start("config.set", configData.UniqueID, value)
            end

            local frame = blocker:Add("EditablePanel")
            frame:SetSize(300, 200)
            frame:SetPos(gui.MouseX() - 150, gui.MouseY() - 100)

            local mixer = frame:Add("DColorMixer")
            mixer:Dock(FILL)
            mixer:SetAlphaBar(true)
            mixer:SetPalette(true)
            mixer:SetWangs(true)
            mixer:SetColor(value)
            mixer.ValueChanged = function(this, new)
                value = new
                color.color = new
            end
        end

        panel.DoRightClick = function()
            local menu = DermaMenu()
            menu:AddOption(ax.localization:GetPhrase("reset"), function()
                ax.net:Start("config.reset", configData.UniqueID)

                value = ax.config:GetDefault(configData.UniqueID)
                color.color = value
            end)
            menu:Open()
        end
    elseif ( configData.Type == ax.types.string ) then
        local text = panel:Add("ax.text.entry")
        text:Dock(RIGHT)
        text:DockMargin(ScreenScale(8), ScreenScale(6), ScreenScale(8), ScreenScale(6))
        text:SetWide(ScreenScale(128))
        text:SetText(value)

        text.OnEnter = function(this)
            local newValue = this:GetText()
            if ( newValue == value ) then return end

            ax.net:Start("config.set", configData.UniqueID, newValue)

            value = newValue

            ax.client:EmitSound("ui/buttonclickrelease.wav", 60, pitch, 0.1, CHAN_STATIC)
        end

        panel.DoClick = function()
            local menu = DermaMenu()
            menu:AddOption(ax.localization:GetPhrase("reset"), function()
                ax.net:Start("config.reset", configData.UniqueID)

                value = ax.config:GetDefault(configData.UniqueID)
                text:SetText(value)
            end)
            menu:Open()
        end
    end

    panel.OnHovered = function(this)
        if ( configData.Type == ax.types.bool ) then
            label:SetText(value and "< " .. enabled .. " >" or "< " .. disabled .. " >", true)
        elseif ( configData.Type == ax.types.array ) then
            local phrase = (configs and configs[value]) and ax.localization:GetPhrase(configs[value]) or unknown
            label:SetText("< " .. phrase .. " >", true)
        end

        if ( !IsValid(ax.gui.tooltip) ) then
            ax.gui.tooltip = vgui.Create("ax.tooltip")
            ax.gui.tooltip:SetText(configData.Name, configData.Description)
            ax.gui.tooltip:SizeToContents()
            ax.gui.tooltip:SetPanel(this)
        else
            ax.gui.tooltip:SetText(configData.Name, configData.Description)
            ax.gui.tooltip:SizeToContents()

            timer.Simple(0, function()
                if ( IsValid(ax.gui.tooltip) ) then
                    ax.gui.tooltip:SetPanel(this)
                end
            end)
        end
    end

    panel.OnUnHovered = function(this)
        if ( configData.Type == ax.types.bool ) then
            label:SetText(value and enabled or disabled, true)
        elseif ( configData.Type == ax.types.array ) then
            local phrase = (configs and configs[value]) and ax.localization:GetPhrase(configs[value]) or unknown
            label:SetText(phrase, true)
        end

        if ( IsValid(ax.gui.tooltip) ) then
            ax.gui.tooltip:SetPanel(nil)
        end
    end
end

vgui.Register("ax.config", PANEL, "EditablePanel")

ax.gui.configLast = nil