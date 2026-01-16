--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

function PANEL:Init()
    hook.Run("PreMainMenuLoadCreated", self)

    local parent = self:GetParent()

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())

    self.characterList = self:Add("ax.transition")
    self.characterList:StartAtBottom()

    self:CreateNavigation(self.characterList, "back", function()
        self:SlideDown()
        parent.splash:SlideToFront()
    end)

    self.characters = self.characterList:Add("ax.scroller.vertical")
    self.characters:Dock(FILL)
    self.characters:DockMargin(ax.util:ScreenScale(128), ax.util:ScreenScaleH(32), ax.util:ScreenScale(128), ax.util:ScreenScaleH(32))
    self.characters:InvalidateParent(true)
    self.characters:GetVBar():SetWide(0)
    self.characters.Paint = nil

    self.deletePanel = self:Add("ax.transition")
    self.deletePanel:StartAtRight()

    self.deleteContainer = self.deletePanel:Add("EditablePanel")
    self.deleteContainer:Dock(FILL)
    self.deleteContainer:InvalidateParent(true)

    hook.Run("PostMainMenuLoadCreated", self)
end

function PANEL:OnSlideStart()
    if ( !IsValid(self.characters) ) then return end
    if ( !IsValid(self.deleteContainer) ) then return end

    self.characterList:SlideToFront()
    self:PopulateCharacterList()
end

function PANEL:PopulateCharacterList()
    self.characters:Clear()
    local clientTable = ax.client:GetTable()
    if ( !istable( clientTable.axCharacters ) ) then clientTable.axCharacters = {} end
    if ( clientTable.axCharacters[1] == nil ) then return end -- literally no reason to continue

    for k, v in pairs(clientTable.axCharacters or {}) do
        local button = self.characters:Add("ax.button.flat")
        button:Dock(TOP)
        button:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
        button:SetText("", true, true, true)
        button:SetTall(self.characters:GetWide() / 8)

        button.DoClick = function()
            net.Start("ax.character.load")
                net.WriteUInt(v.id, 32)
            net.SendToServer()
        end

        local faction = v:GetFactionData()
        local banner = hook.Run("GetCharacterBanner", v.id) or (faction and faction.image) or "gamepadui/hl2/chapter14"
        if ( isstring(banner) ) then
            banner = ax.util:GetMaterial(banner)
        end

        local image = button:Add("EditablePanel")
        image:Dock(LEFT)
        image:DockMargin(0, 0, ax.util:ScreenScale(8), 0)
        image:SetSize(button:GetTall() * 1.75, button:GetTall())
        image:SetMouseInputEnabled(false)
        image.Paint = function(this, width, height)
            surface.SetDrawColor(color_white)
            surface.SetMaterial(banner)
            surface.DrawTexturedRect(0, 0, width, height)
        end

        local deleteButton = button:Add("ax.button.flat")
        deleteButton:Dock(RIGHT)
        deleteButton:DockMargin(ax.util:ScreenScale(8), 0, 0, 0)
        deleteButton:SetText("X")
        deleteButton:SetTextColor(Color(200, 100, 100))
        deleteButton:SetBackgroundColor(Color(200, 100, 100))
        deleteButton:SetSize(0, button:GetTall())
        deleteButton:SetContentAlignment(5)
        deleteButton.width = 0
        deleteButton.DoClick = function()
            self:PopulateDeletePanel(v)
        end

        -- Sorry for this pyramid of code, but eon wanted me to make the delete button extend when hovered over the character button.
        local isDeleteButtonExtended = false
        button.OnThink = function()
            if ( button:IsHovered() or deleteButton:IsHovered() ) then
                if ( !isDeleteButtonExtended ) then
                    isDeleteButtonExtended = true
                    deleteButton:Motion(0.2, {
                        Target = {width = button:GetTall()},
                        Easing = "OutQuad",
                        Think = function(this)
                            deleteButton:SetWide(this.width)
                        end
                    })
                end
            else
                if ( isDeleteButtonExtended ) then
                    isDeleteButtonExtended = false
                    deleteButton:Motion(0.2, {
                        Target = {width = 0},
                        Easing = "OutQuad",
                        Think = function(this)
                            deleteButton:SetWide(this.width)
                        end
                    })
                end
            end
        end

        local name = button:Add("ax.text")
        name:Dock(TOP)
        name:SetFont("ax.huge.bold")
        name:SetText(v:GetName():upper())
        name.Think = function(this)
            this:SetTextColor(button:GetTextColor())
        end

        local lastPlayed = button:Add("ax.text")
        lastPlayed:Dock(BOTTOM)
        lastPlayed:DockMargin(0, 0, 0, ax.util:ScreenScaleH(8))
        lastPlayed:SetFont("ax.large")
        lastPlayed:SetText(os.date("%a %b %d %H:%M:%S %Y", v:GetLastPlayed()), true)
        lastPlayed.Think = function(this)
            this:SetTextColor(button:GetTextColor())
        end
    end
end

function PANEL:PopulateDeletePanel(character)
    self.characterList:SlideLeft()
    self.deletePanel:SlideToFront()
    self.deleteContainer:Clear()

    local title = self.deleteContainer:Add("ax.text")
    title:Dock(TOP)
    title:DockMargin(ax.util:ScreenScale(32), ax.util:ScreenScaleH(32), 0, 0)
    title:SetFont("ax.huge.bold")
    title:SetText("ARE YOU SURE YOU WANT TO DELETE")

    local name = self.deleteContainer:Add("ax.text")
    name:Dock(TOP)
    name:DockMargin(ax.util:ScreenScale(64), 0, 0, ax.util:ScreenScaleH(16))
    name:SetFont("ax.huge.bold")
    name:SetText(character:GetName():upper())
    name:SetTextColor(team.GetColor(character:GetFaction()) or color_white)

    local mark = name:Add("ax.text")
    mark:Dock(LEFT)
    mark:DockMargin(name:GetWide(), 0, 0, 0)
    mark:SetFont("ax.huge.bold")
    mark:SetText("?")

    local model = self.deleteContainer:Add("DModelPanel")
    model:SetModel(character:GetModel() or "models/player/kleiner.mdl")
    model:SetFOV(15)
    model:SetSize(self.deleteContainer:GetWide() / 3, self.deleteContainer:GetTall())
    model:Center()
    model:SetMouseInputEnabled(false)
    model.LayoutEntity = function(this, ent)
        ent:SetAngles(Angle(0, RealTime() * 10 % 360, 0))
        ent:SetPos(-Vector(128, 128, 32))
        ent:SetEyeTarget(ent:GetPos() * ent:GetAngles():Forward())
        ent:SetIK(false)

        this:RunAnimation()
    end

    self:CreateNavigation(self.deleteContainer, "back", function()
        self.characterList:SlideToFront()
        self.deletePanel:SlideRight()
    end, "confirm", function()
        net.Start("ax.character.delete")
            net.WriteUInt(character.id, 32)
        net.SendToServer()

        self:PopulateCharacterList()
        self.characterList:SlideToFront()
        self.deletePanel:SlideRight()
    end)
end

function PANEL:Paint(width, height)
    ax.util:DrawGradient("down", 0, 0, width, height, Color(0, 0, 0, 200))
end

vgui.Register("ax.main.load", PANEL, "ax.transition")
