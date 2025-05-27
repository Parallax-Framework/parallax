local padding = ScreenScale(32)

DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
    ax.gui.inventory = self

    self:Dock(FILL)

    self.buttons = self:Add("ax.scroller.horizontal")
    self.buttons:Dock(TOP)
    self.buttons:DockMargin(0, padding / 8, 0, 0)
    self.buttons:SetTall(ScreenScale(24))
    self.buttons.Paint = nil

    self.container = self:Add("ax.scroller.vertical")
    self.container:Dock(FILL)
    self.container:GetVBar():SetWide(0)
    self.container.Paint = nil

    self.info = self:Add("EditablePanel")
    self.info:Dock(RIGHT)
    self.info:DockPadding(16, 16, 16, 16)
    self.info:SetWide(ScreenScale(128))
    self.info.Paint = function(this, width, height)
        draw.RoundedBox(0, 0, 0, width, height, Color(0, 0, 0, 150))
    end

    local inventories = ax.inventory:GetByCharacterID(ax.client:GetCharacter():GetID())
    if ( #inventories == 0 ) then
        local label = self.buttons:Add("ax.text")
        label:Dock(FILL)
        label:SetFont("parallax.large")
        label:SetText("inventory.empty")
        label:SetContentAlignment(5)

        return
    end

    for _, inventory in pairs(inventories) do
        local button = self.buttons:Add("ax.button.small")
        button:Dock(LEFT)
        button:SetText(inventory:GetName())
        button:SizeToContents()

        button.DoClick = function()
            self:SetInventory(inventory:GetID())
        end
    end

    -- Pick the first inventory by default
    local firstInventory = inventories[1]
    if ( firstInventory ) then
        self:SetInventory(firstInventory:GetID())
    end
end

function PANEL:SetInventory(id)
    if ( !id ) then return end

    local inventory = ax.inventory:Get(id)
    if ( !inventory ) then return end

    self.container:Clear()

    local total = inventory:GetWeight() / ax.config:Get("inventory.max.weight", 20)

    local progress = self.container:Add("DProgress")
    progress:Dock(TOP)
    progress:SetFraction(total)
    progress:SetTall(ScreenScale(12))
    progress:DockMargin(0, 0, 5, 0)
    progress.Paint = function(this, width, height)
        draw.RoundedBox(0, 0, 0, width, height, Color(0, 0, 0, 150))

        local fraction = this:GetFraction()
        draw.RoundedBox(0, 0, 0, width * fraction, height, Color(100, 200, 175, 200))
    end

    local maxWeight = ax.config:Get("inventory.max.weight", 20)
    local weight = math.Round(maxWeight * progress:GetFraction(), 2)

    local label = progress:Add("ax.text")
    label:Dock(FILL)
    label:SetFont("parallax.large")
    label:SetText(weight .. "kg / " .. maxWeight .. "kg")
    label:SetTextColor(color_white)
    label:SetContentAlignment(5)

    local items = inventory:GetItems()
    if ( #items == 0 ) then
        label = self.container:Add("ax.text")
        label:Dock(TOP)
        label:SetFont("parallax.large")
        label:SetText("inventory.empty")
        label:SetContentAlignment(5)

        return
    end

    local sortedItems = {}
    for _, itemID in pairs(items) do
        local item = ax.item:Get(itemID)
        if ( item ) then
            table.insert(sortedItems, itemID)
        end
    end

    local sortType = ax.option:Get("inventory.sort")
    table.sort(sortedItems, function(a, b)
        local itemA = ax.item:Get(a)
        local itemB = ax.item:Get(b)

        if ( !itemA or !itemB ) then return false end

        if ( sortType == "name" ) then
            return itemA:GetName() < itemB:GetName()
        elseif ( sortType == "weight" ) then
            return itemA:GetWeight() < itemB:GetWeight()
        elseif ( sortType == "category" ) then
            return itemA:GetCategory() < itemB:GetCategory()
        end

        return false
    end)

    for _, itemData in pairs(sortedItems) do
        local itemPanel = self.container:Add("ax.item")
        itemPanel:SetItem(itemData)
        itemPanel:Dock(TOP)
        itemPanel:DockMargin(0, 0, 5, 0)
    end
end

function PANEL:SetInfo(id)
    if ( !id ) then return end

    local item = ax.item:Get(id)
    if ( !item ) then return end

    self.info:Clear()

    local icon = self.info:Add("DAdjustableModelPanel")
    icon:Dock(TOP)
    icon:SetSize(self.info:GetWide() - 32, self.info:GetWide() - 32)
    icon:SetModel(item:GetModel())
    icon:SetSkin(item:GetSkin())

    local entity = icon:GetEntity()
    local pos = entity:GetPos()
    local camData = PositionSpawnIcon(entity, pos)
    if ( camData ) then
        icon:SetCamPos(camData.origin)
        icon:SetFOV(camData.fov)
        icon:SetLookAng(camData.angles)
    end

    local name = self.info:Add("ax.text")
    name:Dock(TOP)
    name:DockMargin(0, 0, 0, -padding / 8)
    name:SetFont("parallax.huge.bold")
    name:SetText(item:GetName(), true)

    local description = item:GetDescription()
    local descriptionWrapped = ax.util:GetWrappedText(description, "parallax", self.info:GetWide() - 32)
    for k, v in pairs(descriptionWrapped) do
        local text = self.info:Add("ax.text")
        text:Dock(TOP)
        text:SetFont("parallax")
        text:SetText(v, true)
    end
end

vgui.Register("ax.inventory", PANEL, "EditablePanel")

DEFINE_BASECLASS("ax.button.small")

PANEL = {}

AccessorFunc(PANEL, "id", "ID", FORCE_NUMBER)

function PANEL:Init()
    self:SetText("")
    self:SetTall(ScreenScale(16))

    self.id = 0

    self.icon = self:Add("DModelPanel")
    self.icon:Dock(LEFT)
    self.icon:DockMargin(0, 0, padding / 8, 0)
    self.icon:SetSize(self:GetTall(), self:GetTall())
    self.icon:SetMouseInputEnabled(false)
    self.icon.LayoutEntity = function(this, entity)
        -- Disable the rotation of the model
        -- Do not set this to nil, it will spew out errors
    end

    self.name = self:Add("ax.text")
    self.name:Dock(FILL)
    self.name:SetFont("parallax.large")
    self.name:SetContentAlignment(4)
    self.name:SetMouseInputEnabled(false)

    self.weight = self:Add("ax.text")
    self.weight:Dock(RIGHT)
    self.weight:DockMargin(0, 0, padding / 8, 0)
    self.weight:SetFont("parallax")
    self.weight:SetContentAlignment(6)
    self.weight:SetWide(ScreenScale(64))
    self.weight:SetMouseInputEnabled(false)
end

function PANEL:SetItem(id)
    if ( !id ) then return end
    self:SetID(id)

    local item = ax.item:Get(id)
    if ( !item ) then return end

    self.icon:SetModel(item:GetModel())
    self.icon:SetSkin(item:GetSkin())
    self.name:SetText(item:GetName(), true)
    self.weight:SetText(item:GetWeight() .. "kg", true, true)

    local entity = self.icon:GetEntity()
    local pos = entity:GetPos()
    local camData = PositionSpawnIcon(entity, pos)
    if ( camData ) then
        self.icon:SetCamPos(camData.origin)
        self.icon:SetFOV(camData.fov)
        self.icon:SetLookAng(camData.angles)
    end

    if ( item.Actions.Equip or item.Actions.EquipUn ) then
        local equipped = item:GetData("equipped")
        if ( equipped ) then
            self:SetBackgroundColor(ax.color:Get("success"))
        else
            self:SetBackgroundColor(ax.color:Get("warning"))
        end
    end
end

function PANEL:DoClick()
    local inventoryPanel = ax.gui.inventory
    if ( !IsValid(inventoryPanel) ) then return end

    inventoryPanel:SetInfo(self:GetID())
end

function PANEL:DoRightClick()
    local itemID = self:GetID()
    local item = ax.item:Get(itemID)
    if ( !item ) then return end

    local base = ax.item:Get(item:GetUniqueID())
    if ( !base or !base.Actions ) then return end

    local menu = DermaMenu()
    for actionName, actionData in pairs(base.Actions) do
        if ( actionName == "Take" ) then continue end
        if ( isfunction(actionData.OnCanRun) and actionData:OnCanRun(item, ax.client) == false ) then continue end

        menu:AddOption(actionData.Name or actionName, function()
            ax.net:Start("item.perform", itemID, actionName)
        end)
    end

    if ( menu:ChildCount() > 0 ) then
        menu:Open()
    end
end

function PANEL:Think()
    BaseClass.Think(self)

    self.name:SetTextColor(self:GetTextColor())
    self.weight:SetTextColor(self:GetTextColor())
end

vgui.Register("ax.item", PANEL, "ax.button.small")