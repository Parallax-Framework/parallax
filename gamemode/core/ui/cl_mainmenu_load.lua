--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:SetVisible(false)
end

function PANEL:Populate()
    local client = Parallax.Client
    if ( !IsValid(client) ) then return end

    local parent = self:GetParent()
    parent:SetGradientLeftTarget(0)
    parent:SetGradientRightTarget(0)
    parent:SetGradientTopTarget(1)
    parent:SetGradientBottomTarget(1)
    parent:SetDimTarget(0.25)
    parent.container:Clear()
    parent.container:SetVisible(false)

    self:Clear()
    self:SetVisible(true)

    local title = self:Add("Parallax.Text")
    title:Dock(TOP)
    title:DockMargin(ScreenScale(32), ScreenScaleH(32), 0, 0)
    title:SetFont("Parallax.Huge.bold")
    title:SetText(string.upper("mainmenu.select.character"))

    local navigation = self:Add("EditablePanel")
    navigation:Dock(BOTTOM)
    navigation:DockMargin(ScreenScale(32), 0, ScreenScale(32), ScreenScaleH(32))
    navigation:SetTall(ScreenScaleH(24))

    local backButton = navigation:Add("Parallax.Button.Flat")
    backButton:Dock(LEFT)
    backButton:SetText("back")
    backButton.DoClick = function()
        self:Clear()
        self:SetVisible(false)
        parent:Populate()
    end

    navigation:SetTall(backButton:GetTall())

    local characterList = self:Add("Parallax.Scroller.Vertical")
    characterList:Dock(FILL)
    characterList:DockMargin(ScreenScale(32) * 4, ScreenScaleH(32), ScreenScale(32) * 4, ScreenScaleH(32))
    characterList:InvalidateParent(true)
    characterList:GetVBar():SetWide(0)
    characterList.Paint = nil

    local clientTable = client:GetTable()
    for k, v in pairs(clientTable.axCharacters) do
        local button = characterList:Add("Parallax.Button.Flat")
        button:Dock(TOP)
        button:DockMargin(0, 0, 0, ScreenScaleH(4))
        button:SetText("", true, true, true)
        button:SetTall(characterList:GetWide() / 8)

        button.DoClick = function()
            Parallax.Net:Start("character.load", v:GetID())
        end

        local banner = hook.Run("GetCharacterBanner", v:GetID()) or "gamepadui/hl2/chapter14"
        if ( type(banner) == "string" ) then
            banner = Parallax.Util:GetMaterial(banner)
        end

        local image = button:Add("DPanel")
        image:Dock(LEFT)
        image:DockMargin(0, 0, ScreenScale(8), 0)
        image:SetSize(button:GetTall() * 1.75, button:GetTall())
        image.Paint = function(this, width, height)
            surface.SetDrawColor(Parallax.Color:Get("white"))
            surface.SetMaterial(banner)
            surface.DrawTexturedRect(0, 0, width, height)
        end

        local deleteButton = button:Add("Parallax.Button.Flat")
        deleteButton:Dock(RIGHT)
        deleteButton:DockMargin(ScreenScale(8), 0, 0, 0)
        deleteButton:SetText("X")
        deleteButton:SetTextColorProperty(Parallax.Config:Get("color.error"))
        deleteButton:SetSize(0, button:GetTall())
        deleteButton:SetContentAlignment(5)
        deleteButton.baseTextColorTarget = Parallax.Color:Get("black")
        deleteButton.backgroundColor = Parallax.Config:Get("color.error")
        deleteButton.width = 0
        deleteButton.DoClick = function()
            self:PopulateDelete(v:GetID())
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

        local name = button:Add("Parallax.Text")
        name:Dock(TOP)
        name:SetFont("Parallax.Huge.bold")
        name:SetText(v:GetName():upper())
        name.Think = function(this)
            this:SetTextColor(button:GetTextColor())
        end

        -- Example: Sat Feb 19 19:49:00 2022
        local lastPlayedDate = os.date("%a %b %d %H:%M:%S %Y", v:GetLastPlayed())

        local lastPlayed = button:Add("Parallax.Text")
        lastPlayed:Dock(BOTTOM)
        lastPlayed:DockMargin(0, 0, 0, ScreenScaleH(8))
        lastPlayed:SetFont("Parallax.Large")
        lastPlayed:SetText(lastPlayedDate, true)
        lastPlayed.Think = function(this)
            this:SetTextColor(button:GetTextColor())
        end
    end
end

function PANEL:PopulateDelete(characterID)
    self:Clear()

    local title = self:Add("Parallax.Text")
    title:Dock(TOP)
    title:DockMargin(ScreenScale(32), ScreenScaleH(32), 0, 0)
    title:SetFont("Parallax.Huge.bold")
    title:SetText(string.upper("mainmenu.delete.character"))

    local confirmation = self:Add("Parallax.Text")
    confirmation:Dock(TOP)
    confirmation:DockMargin(ScreenScale(64), ScreenScaleH(16), 0, 0)
    confirmation:SetFont("Parallax.Large")
    confirmation:SetText("mainmenu.delete.character.confirm")

    local navigation = self:Add("EditablePanel")
    navigation:Dock(BOTTOM)
    navigation:DockMargin(ScreenScale(32), 0, ScreenScale(32), ScreenScaleH(32))

    local cancelButton = navigation:Add("Parallax.Button.Flat")
    cancelButton:Dock(LEFT)
    cancelButton:SetText("CANCEL")
    cancelButton.DoClick = function()
        self:Populate()
    end

    local okButton = navigation:Add("Parallax.Button.Flat")
    okButton:Dock(RIGHT)
    okButton:SetText("OK")
    okButton.DoClick = function()
        Derma_Query(
            "Are you REALLY sure you want to delete this character? This action cannot be undone.",
            "Delete Character",
            "Yes", function()
                Parallax.Net:Start("character.delete", characterID)
            end,
            "No", function() end
        )
    end

    navigation:SetTall(math.max(cancelButton:GetTall(), okButton:GetTall()))
end

vgui.Register("Parallax.Mainmenu.Load", PANEL, "EditablePanel")