local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)

    local client = ax.client
    local character = client:GetCharacter()
    if ( !character ) then
        return
    end

    local inventory = character:GetInventory()
    if ( !inventory ) then
        return
    end

    self.container = self:Add("ax.scroller.vertical")
    self.container:Dock(FILL)
    self.container:GetVBar():SetWide(0)
    self.container.Paint = nil

    self.info = self:Add("EditablePanel")
    self.info:Dock(RIGHT)
    self.info:DockPadding(ScreenScale(4), ScreenScaleH(4), ScreenScale(4), ScreenScaleH(4))
    self.info:SetWide(0)
    self.info.Paint = function(this, width, height)
        draw.RoundedBox(0, 0, 0, width, height, Color(0, 0, 0, 150))
    end

    local total = inventory:GetWeight() / inventory:GetMaxWeight()

    local progress = self.container:Add("DProgress")
    progress:Dock(TOP)
    progress:SetFraction(total)
    progress:SetTall(ScreenScale(12))
    progress.Paint = function(this, width, height)
        draw.RoundedBox(0, 0, 0, width, height, Color(0, 0, 0, 150))

        local fraction = this:GetFraction()
        draw.RoundedBox(0, 0, 0, width * fraction, height, Color(100, 200, 175, 200))
    end

    local maxWeight = inventory:GetMaxWeight()
    local weight = math.Round(maxWeight * progress:GetFraction(), 2)

    local label = progress:Add("ax.text")
    label:Dock(FILL)
    label:SetFont("ax.regular")
    label:SetText(weight .. "kg / " .. maxWeight .. "kg")
    label:SetContentAlignment(5)

    for k, v in pairs(inventory:GetItems()) do
        if ( !ax.item.stored[v.class] ) then
            ax.util:PrintDebug("Item class '" .. tostring(v.class) .. "' not found in registry, skipping...")
            continue
        end

        PrintTable(v)

        local item = self.container:Add("ax.button.flat")
        item:Dock(TOP)
        item:SetFont("ax.small")
        item:SetFontDefault("ax.small")
        item:SetFontHovered("ax.regular.bold")
        item:SetText(v:GetName() or tostring(v))
        item:SetContentAlignment(4)
        item:SetTextInset(item:GetTall() + ScreenScale(2), 0)

        item.DoClick = function()
            self.info:Motion(0.25, {
                Target = {wide = ScreenScale(196), fraction = 1.0},
                Easing = "OutQuad",
                Think = function(this)
                    self.info:SetWide(this.wide)
                    self.info:DockMargin(ScreenScale(16) * this.fraction, 0, 0, 0)
                end
            })

            self.info:Clear()

            self:PopulateInfo(v)
        end

        local icon = item:Add("SpawnIcon")
        icon:Dock(LEFT)
        icon:SetWide(item:GetTall())
        icon:DockMargin(0, 0, ScreenScale(4), 0)
        icon:SetModel(v:GetModel() or "models/props_junk/wood_crate001a.mdl")
        icon:SetMouseInputEnabled(false)
    end
end

function PANEL:PopulateInfo(item)
    if ( !istable(item) ) then return end

    local title = self.info:Add("ax.text")
    title:Dock(TOP)
    title:SetFont("ax.large.bold")
    title:SetText(item:GetName() or "Unknown Item")
    title:SizeToContentsY()
    title:DockMargin(0, 0, 0, ScreenScaleH(4))
    title:SetContentAlignment(5)

    local description = self.info:Add("ax.text")
    description:Dock(TOP)
    description:SetFont("ax.regular")
    description:SetText(item:GetDescription() or "No description available.")
    description:SizeToContentsY()
    description:DockMargin(0, 0, 0, ScreenScaleH(8))
    description:SetContentAlignment(5)

    local actions = item:GetActions() or {}
    if ( table.IsEmpty(actions) ) then
        local noActions = self.info:Add("ax.text")
        noActions:Dock(TOP)
        noActions:SetFont("ax.regular.italic")
        noActions:SetText("No actions available for this item.")
        noActions:SizeToContentsY()
        noActions:DockMargin(0, 0, 0, ScreenScaleH(4))
        noActions:SetContentAlignment(5)

        return
    end

    for k, v in pairs(actions) do
        local actionButton = self.info:Add("ax.button.flat")
        actionButton:Dock(TOP)
        actionButton:SetFont("ax.regular")
        actionButton:SetText(v.name or k)
        actionButton:DockMargin(0, 0, 0, ScreenScaleH(4))
        actionButton:SetContentAlignment(5)

        actionButton.DoClick = function()
            net.Start("ax.inventory.item.action")
            net.WriteUInt(item.id, 32)
            net.WriteString(k)
            net.SendToServer()

            self.info:Motion(0.25, {
                Target = {wide = 0.0, fraction = 0.0},
                Easing = "OutQuad",
                Think = function(this)
                    self.info:SetWide(this.wide)
                    self.info:DockMargin(ScreenScale(16) * this.fraction, 0, 0, 0)
                end
            })
        end
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
