local PANEL = {}

AccessorFunc(PANEL, "min", "Min", FORCE_NUMBER)
AccessorFunc(PANEL, "max", "Max", FORCE_NUMBER)
AccessorFunc(PANEL, "decimals", "Decimals", FORCE_NUMBER)

function PANEL:Init()
    self.min = 0
    self.max = 100
    self.decimals = 0
    self.value = 0
    self.dragging = false
end

function PANEL:SetValue(value, bNoNotify)
    if ( value < self.min ) then value = self.min end
    if ( value > self.max ) then value = self.max end

    self.value = math.Round(value, self.decimals)

    if ( !bNoNotify and self.value != value ) then
        local pitch = math.Clamp((self.value - self.min) / (self.max - self.min), 0, 1) * 100 + 50
        ax.client:EmitSound("ui/buttonrollover.wav", 60, pitch, 0.05, CHAN_STATIC)

        if ( self.OnValueSet ) then
            self:OnValueSet(self.value)
        end
    end
end

function PANEL:GetValue()
    return self.value
end

function PANEL:OnValueChanged(value)
    -- Override this function to handle value changes
end

function PANEL:Paint(width, height)
    draw.RoundedBox(0, 0, 0, width, height, ax.color:Get("background.slider"))
    local fraction = (self.value - self.min) / (self.max - self.min)
    local barWidth = math.Clamp(fraction * width, 0, width)
    draw.RoundedBox(0, 0, 0, barWidth, height, color_white)
end

function PANEL:OnMousePressed(mouseCode)
    if ( mouseCode == MOUSE_LEFT ) then
        self.dragging = true
        self:MouseCapture(true)
        self:OnCursorMoved(self:CursorPos())
    end
end

function PANEL:OnMouseReleased()
    self.dragging = false
    self:MouseCapture(false)

    if ( self.OnValueChanged ) then
        self:OnValueChanged(self.value)
    end
end

function PANEL:OnCursorMoved(x, y)
    if ( !self.dragging ) then return end

    local width = self:GetWide()
    local fraction = math.Clamp(x / width, 0, 1) -- Ensure fraction is always between 0 and 1

    local value = nil -- Initialize value to ensure it is always defined

    -- Snap to min or max if the cursor is near the edges
    if ( fraction <= 0.01 ) then
        value = self.min
    elseif ( fraction >= 0.99 ) then
        value = self.max
    else
        value = fraction * (self.max - self.min) + self.min
    end

    -- Ensure value is always set
    if ( value == nil ) then
        value = self.min -- Fallback to min if value is somehow nil
    end

    self:SetValue(value)
end

vgui.Register("ax.slider", PANEL, "EditablePanel")