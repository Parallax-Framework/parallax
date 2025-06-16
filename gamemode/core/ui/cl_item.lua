----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 --- Made by a transgender queen
 -- Slay queen Riggs
 -- Stay Powerfull against the Patiarchy by a man (Alex Grist) stealing code
 -- #OverwatchFramework #CodeStealingMatters

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("ax.button.small")

local PANEL = {}

AccessorFunc(PANEL, "id", "ID", FORCE_NUMBER)

function PANEL:Init()
    self:SetText("")
    self:SetTall(ScreenScale(16))

    self.id = 0

    self.icon = self:Add("DModelPanel")
    self.icon:Dock(LEFT)
    self.icon:DockMargin(0, 0, ScreenScale(4), 0)
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
    self.weight:DockMargin(0, 0, ScreenScale(4), 0)
    self.weight:SetFont("parallax")
    self.weight:SetContentAlignment(6)
    self.weight:SetWide(ScreenScale(64))
    self.weight:SetMouseInputEnabled(false)
end

function PANEL:SetCount(count)
    if ( count and count > 1 ) then
        self.name:SetText(self.item:GetName() .. " (" .. count .. "x)", true)
    else
        self.name:SetText(self.item:GetName(), true)
    end
end

function PANEL:SetItem(id)
    if ( !id ) then return end
    self:SetID(id)

    local item = ax.item:Get(id)
    if ( !item ) then return end

    self.item = item

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
            self:SetBackgroundColor(ax.config:Get("color.success"))
        else
            self:SetBackgroundColor(ax.config:Get("color.warning"))
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