local PANEL = {}

function PANEL:Init()
    ax.gui.inventory = self

    self:Dock(FILL)

    local client = ax.client
    local character = client:GetCharacter()
    if ( !character ) then return end

    self.character = character

    local inventory = character:GetInventory()
    if ( !inventory ) then return end

    self.inventory = inventory

    self.container = self:Add("ax.scroller.vertical")
    self.container:Dock(FILL)
    self.container:GetVBar():SetWide(0)
    self.container.Paint = nil

    self.info = self:Add("EditablePanel")
    self.info:SetWide(0)
    self.info:Dock(RIGHT)
    self.info.Paint = function(this, width, height)
        ax.render.Draw(0, 0, 0, width, height, Color(0, 0, 0, 150))
    end

    self.weightProgress = self:Add("DProgress")
    self.weightProgress:SetFraction(inventory:GetWeight() / inventory:GetMaxWeight())
    self.weightProgress:SetTall(ScreenScale(12))
    self.weightProgress:Dock(TOP)
    self.weightProgress.Paint = function(this, width, height)
        ax.render.Draw(0, 0, 0, width, height, Color(0, 0, 0, 150))

        local fraction = this:GetFraction()
        ax.render.Draw(0, 0, 0, width * fraction, height, Color(100, 200, 175, 200))
    end

    local maxWeight = inventory:GetMaxWeight()
    local weight = math.Round(maxWeight * self.weightProgress:GetFraction(), 2)

    self.weightCounter = self.weightProgress:Add("ax.text")
    self.weightCounter:SetFont("ax.regular")
    self.weightCounter:SetText(weight .. "kg / " .. maxWeight .. "kg", true)
    self.weightCounter:SetContentAlignment(5)
    self.weightCounter:Dock(FILL)

    self:PopulateItems()
end

function PANEL:PopulateItems()
    local character = self.character
    local inventory = self.inventory

    if ( !character or !inventory ) then return end

    self.container:Clear()

    self.weightProgress:SetFraction(inventory:GetWeight() / inventory:GetMaxWeight())
    self.weightCounter:SetText(math.Round(inventory:GetWeight(), 2) .. "kg / " .. inventory:GetMaxWeight() .. "kg", true)

    for k, v in pairs(inventory:GetItems()) do
        if ( !ax.item.stored[v.class] ) then
            ax.util:PrintDebug("Item class '" .. tostring(v.class) .. "' not found in registry, skipping...")
            continue
        end

        local item = self.container:Add("ax.button.flat")
        item:SetFont("ax.small")
        item:SetFontDefault("ax.small")
        item:SetFontHovered("ax.regular.bold")
        item:SetText(v:GetName() or tostring(v), true)
        item:SetContentAlignment(4)
        item:SetTextInset(item:GetTall() + ScreenScale(2), 0)
        item:Dock(TOP)
        item:SetTooltip(v:GetID() or 0)

        item.DoClick = function()
            self.info:Motion(0.25, {
                Target = {wide = ScreenScale(128), fraction = 1.0},
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
        icon:SetWide(item:GetTall())
        icon:DockMargin(0, 0, ScreenScale(4), 0)
        icon:SetModel(v:GetModel() or "models/props_junk/wood_crate001a.mdl")
        icon:SetMouseInputEnabled(false)
        icon:Dock(LEFT)
    end
end

function PANEL:PopulateInfo(item)
    if ( !istable(item) ) then return end

    local title = self.info:Add("ax.text")
    title:SetFont("ax.large.bold")
    title:SetText(item:GetName() or "Unknown Item", true)
    title:SizeToContentsY()
    title:DockMargin(0, 0, 0, ScreenScaleH(4))
    title:SetContentAlignment(5)
    title:Dock(TOP)

    local description = self.info:Add("ax.text")
    description:SetFont("ax.regular")
    description:SetText(item:GetDescription() or "No description available.", true)
    description:SizeToContentsY()
    description:DockMargin(0, 0, 0, ScreenScaleH(8))
    description:SetContentAlignment(8)
    description:Dock(FILL)

    local actions = item:GetActions() or {}
    if ( table.IsEmpty(actions) ) then
        local noActions = self.info:Add("ax.text")
        noActions:SetFont("ax.regular.italic")
        noActions:SetText("No actions available for this item.", true)
        noActions:SizeToContentsY()
        noActions:DockMargin(0, 0, 0, ScreenScaleH(4))
        noActions:SetContentAlignment(5)
        noActions:Dock(BOTTOM)

        return
    end

    for k, v in pairs(actions) do
        local actionButton = self.info:Add("ax.button.flat")
        actionButton:SetFont("ax.small")
        actionButton:SetFontDefault("ax.small")
        actionButton:SetFontHovered("ax.small.italic")
        actionButton:SetText(v.name or k, true)
        actionButton:SetContentAlignment(5)
        actionButton:SetIcon(v.icon)
        actionButton:Dock(BOTTOM)

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

vgui.Register("ax.tab.inventory", PANEL, "EditablePanel")

hook.Add("PopulateTabButtons", "ax.tab.inventory", function(buttons)
    buttons["inventory"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.inventory")
        end
    }
end)
