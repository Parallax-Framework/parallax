local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)
    self:InvalidateParent(true)

    self.categories = self:Add("ax.scroller.horizontal")
    self.categories:SetSize(ScrW() - ScreenScale(32), ScreenScaleH(32))

    self.container = self:Add("DPanel")
    self.container:Dock(FILL)
    self.container:DockMargin(0, ScreenScaleH(16) + self.categories:GetTall(), 0, 0)
    self.container.Paint = nil
end

function PANEL:SetType(type)
    if ( !type or type == "" ) then
        ax.util:PrintError("ax.store: Invalid type '" .. tostring(type) .. "'")
        return
    end

    self.categories:Clear()
    self.container:Clear()

    local categories = {}
    if ( type == "config" ) then
        categories = ax.config:GetAllCategories()
    elseif ( type == "option" ) then
        categories = ax.option:GetAllCategories()
    else
        ax.util:PrintError("ax.store: Unknown type '" .. tostring(type) .. "'")
        return
    end

    for k, v in SortedPairs(categories) do
        local button = self.categories:Add("ax.button.flat")
        button:Dock(LEFT)
        button:SetText(v)

        local tab = self:CreatePage()
        tab:SetYOffset(self.categories:GetTall() + ScreenScaleH(16))
        tab:SetHeightOffset(-self.categories:GetTall() - ScreenScaleH(16))

        self:Populate(tab, type, v)

        button.tab = tab
        button.tab.index = tab.index

        button.DoClick = function()
            self:TransitionToPage(button.tab.index, ax.option:Get("tab.fade.time", 0.25))
        end
    end
end

function PANEL:Populate(panel, type, category)
    if ( !panel or !IsValid(panel) ) then return end
    if ( !type or type == "" ) then return end
    if ( !category or category == "" ) then return end

    local rows = {}
    if ( type == "config" ) then
        rows = ax.config:GetAllByCategory(category)
    elseif ( type == "option" ) then
        rows = ax.option:GetAllByCategory(category)
    else
        ax.util:PrintError("ax.store: Unknown type '" .. tostring(type) .. "'")
        return
    end

    if ( table.IsEmpty(rows) ) then
        local label = panel:Add("ax.text")
        label:Dock(FILL)
        label:SetFont("ax.large.italic")
        label:SetText(string.format("No %s found in category: %s", type, category))
        label:SetContentAlignment(5)
        label:SetTextColor(Color(200, 200, 200))
        return
    end

    for key, data in pairs(rows) do
        if ( data.type == ax.type.bool ) then
            local btn = panel:Add("ax.store.bool")
            btn:Dock(TOP)
            btn:SetType(type)
            btn:SetKey(key)
        else
            local label = panel:Add("ax.text")
            label:Dock(TOP)
            label:SetFont("ax.large.italic")
            label:SetText(string.format("Unsupported type '%s' for key: %s", tostring(data.type), tostring(key)))
            label:SetContentAlignment(5)
            label:SetTextColor(Color(200, 200, 200))
        end
    end
end

function PANEL:Paint(width, height)
end

vgui.Register("ax.store", PANEL, "ax.transition.pages")

PANEL = {}

function PANEL:Init()
    self.type = "unknown"
    self.key = "unknown"

    self:SetContentAlignment(4)
    self:SetText("unknown")
    self:SetTextInset(ScreenScale(8), 0)

    self.value = self:Add("ax.text")
    self.value:Dock(RIGHT)
    self.value:DockMargin(0, 0, ScreenScale(8), 0)
    self.value:SetText("unknown")
    self.value:SetFont("ax.large")
    self.value:SetWide(ScreenScale(192))
    self.value:SetContentAlignment(6)
    self.value.Think = function(this)
        this:SetTextColor(self:GetTextColor())
        this:SetFont(self:GetFont())
    end
end

function PANEL:SetType(type)
    if ( !type or type == "" ) then
        self:SetText("unknown")
        self.value:SetText("unknown")
        self.type = "unknown"
        ax.util:PrintError("ax.store.bool: Invalid type '" .. tostring(type) .. "' for key '" .. tostring(self.key) .. "'")
        return
    end

    if ( type == "config" ) then
        self:SetText(self.key)
        self.value:SetText(ax.config:Get(self.key) and "Enabled" or "Disabled")
    elseif ( type == "option" ) then
        self:SetText(self.key)
        self.value:SetText(ax.option:Get(self.key) and "Enabled" or "Disabled")
    else
        self:SetText("unknown")
        self.value:SetText("unknown")
        self.type = "unknown"
        ax.util:PrintError("ax.store.bool: Unknown type '" .. tostring(type) .. "' for key '" .. tostring(self.key) .. "'")
        return
    end

    self.type = type
end

function PANEL:SetKey(key)
    if ( !key or key == "" ) then
        self:SetText("unknown")
        self.value:SetText("unknown")
        self.key = "unknown"
        ax.util:PrintError("ax.store.bool: Invalid key '" .. tostring(key) .. "'")
        return
    end

    if ( self.type == "config" ) then
        if ( ax.config:Get(key) == nil ) then
            self:SetText("unknown")
            self.value:SetText("unknown")
            self.type = "unknown"
            ax.util:PrintError("ax.store.bool: Key '" .. tostring(key) .. "' does not exist in config store")
            return
        end

        self:SetText(key)
        self.value:SetText(string.format("<%s>", ax.config:Get(key) and "Enabled" or "Disabled"))
    elseif ( self.type == "option" ) then
        if ( ax.option:Get(key) == nil ) then
            self:SetText("unknown")
            self.value:SetText("unknown")
            self.type = "unknown"
            ax.util:PrintError("ax.store.bool: Key '" .. tostring(key) .. "' does not exist in option store")
            return
        end

        self:SetText(key)
        self.value:SetText(string.format("<%s>", ax.option:Get(key) and "Enabled" or "Disabled"))
    else
        self:SetText("unknown")
        self.value:SetText("unknown")
        self.type = "unknown"
        ax.util:PrintError("ax.store.bool: Unknown type '" .. tostring(self.type) .. "' for key '" .. tostring(key) .. "'")
    end

    self.key = key
end

function PANEL:DoClick()
    self:Toggle()
end

function PANEL:Toggle()
    if ( self.type == "config" ) then
        local current = ax.config:Get(self.key)
        if ( current == nil ) then
            ax.util:PrintError("ax.store.bool: Key '" .. tostring(self.key) .. "' does not exist in config store")
            self:SetText("unknown")
            self.value:SetText("unknown")
            self.type = "unknown"
            return
        end

        ax.option:Set(self.key, !current)

        self:SetText(self.key)
        self.value:SetText(string.format("<%s>", ax.option:Get(self.key) and "Enabled" or "Disabled"))
    elseif ( self.type == "option" ) then
        local current = ax.option:Get(self.key)
        if ( current == nil ) then
            ax.util:PrintError("ax.store.bool: Key '" .. tostring(self.key) .. "' does not exist in option store")
            self:SetText("unknown")
            self.value:SetText("unknown")
            self.type = "unknown"
            return
        end

        ax.option:Set(self.key, !current)

        self:SetText(self.key)
        self.value:SetText(string.format("<%s>", ax.option:Get(self.key) and "Enabled" or "Disabled"))
    else
        self:SetText("unknown")
        self.value:SetText("unknown")
        self.type = "unknown"
        ax.util:PrintError("ax.store.bool: Unknown type '" .. tostring(self.type) .. "' for key '" .. tostring(self.key) .. "'")
    end
end

vgui.Register("ax.store.bool", PANEL, "ax.button.flat")