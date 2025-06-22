--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("ax.button.flat")

local PANEL = {}

AccessorFunc(PANEL, "id", "ID", FORCE_NUMBER)

function PANEL:Init()
    self:SetText("")
    self:SetContentAlignment(4)

    self.id = 0

    self.icon = self:Add("DModelPanel")
    self.icon:Dock(LEFT)
    self.icon:SetMouseInputEnabled(false)
    self.icon.LayoutEntity = function(this, entity)
        -- Disable the rotation of the model
        -- Do not set this to nil, it will spew out errors
    end

    self.weight = self:Add("ax.text")
    self.weight:Dock(RIGHT)
    self.weight:DockMargin(0, 0, ScreenScale(2), 0)
    self.weight:SetFont("parallax")
    self.weight:SetContentAlignment(6)
    self.weight:SetWide(ScreenScale(64))
    self.weight:SetMouseInputEnabled(false)
end

function PANEL:SetCount(count)
    if ( count and count > 1 ) then
        self:SetText(self.item:GetName() .. " (" .. count .. "x)")
    else
        self:SetText(self.item:GetName())
    end

    self:SetTall(self:GetTall() / 1.5)
    self:SetTextInset(self:GetTall() + ScreenScale(2), 0)
    self.icon:SetSize(self:GetTall(), self:GetTall())
end

function PANEL:SetItem(id)
    if ( !id ) then return end
    self:SetID(id)

    local item = ax.item:Get(id)
    if ( !item ) then return end

    self.item = item

    self:SetText(item:GetName())
    self:SetTall(self:GetTall() / 1.5)
    self:SetTextInset(self:GetTall() + ScreenScale(2), 0)
    self.icon:SetSize(self:GetTall(), self:GetTall())

    self.icon:SetModel(item:GetModel())
    self.icon:SetSkin(item:GetSkin())
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
            self:SetBackgroundColor(ax.config:Get("color.success"))
        else
            self:SetBackgroundColor(ax.config:Get("color.warning"))
        end
    end
end

function PANEL:DoClick()
    local inventoryPanel = ax.gui.Inventory
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

    self.weight:SetTextColor(self:GetTextColor())
end

vgui.Register("ax.item", PANEL, "ax.button.flat")