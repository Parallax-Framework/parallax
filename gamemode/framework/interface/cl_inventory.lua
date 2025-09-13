local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)

    local title = self:Add("ax.text")
    title:Dock(TOP)
    title:SetFont("ax.huge.bold")
    title:SetText("INVENTORY")
    title:SetContentAlignment(9)

    local inventory = ax.client:GetCharacter():GetInventory()
    if ( !inventory ) then
        title:SetText("NO INVENTORY")
        return
    end

    self.container = self:Add("ax.scroller.vertical")
    self.container:Dock(FILL)
    self.container:GetVBar():SetWide(0)
    self.container.Paint = nil

    self.info = self:Add("EditablePanel")
    self.info:Dock(RIGHT)
    self.info:DockPadding(ScreenScale(4), ScreenScaleH(4), ScreenScale(4), ScreenScaleH(4))
    self.info:SetWide(0) -- ScreenScale(128)
    self.info.Paint = function(this, width, height)
        draw.RoundedBox(0, 0, 0, width, height, Color(0, 0, 0, 150))
    end

    local total = inventory:GetWeight() / ax.config:Get("inventory.max.weight", 20)

    local progress = self.container:Add("DProgress")
    progress:Dock(TOP)
    progress:SetFraction(total)
    progress:SetTall(ScreenScale(12))
    progress:DockMargin(0, 0, ScreenScale(8), 0)
    progress.Paint = function(this, width, height)
        draw.RoundedBox(0, 0, 0, width, height, Color(0, 0, 0, 150))

        local fraction = this:GetFraction()
        draw.RoundedBox(0, 0, 0, width * fraction, height, Color(100, 200, 175, 200))
    end

    local maxWeight = ax.config:Get("inventory.max.weight", 20)
    local weight = math.Round(maxWeight * progress:GetFraction(), 2)

    local label = progress:Add("ax.text")
    label:Dock(FILL)
    label:SetFont("ax.regular")
    label:SetText(weight .. "kg / " .. maxWeight .. "kg")
    label:SetContentAlignment(5)

    -- temporary filler items
    for i = 1, 16 do
        local item = self.container:Add("ax.button.flat")
        item:Dock(TOP)
        item:SetText("Item " .. i)
        item:SetContentAlignment(4)
        item:SetTextInset(item:GetTall() + ScreenScale(2), 0)

        local icon = item:Add("SpawnIcon")
        icon:Dock(LEFT)
        icon:SetWide(item:GetTall())
        icon:DockMargin(0, 0, ScreenScale(4), 0)
        icon:SetModel("models/props_junk/PopCan01a.mdl")
        icon:SetMouseInputEnabled(false)
    end
end

function PANEL:Paint(width, height)
end

vgui.Register("ax.tab.inventory", PANEL, "DPanel")

hook.Add("PopulateTabButtons", "ax.tab.inventory", function(buttons)
    buttons["inventory"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.inventory")
        end
    }
end)