--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

---@class ax.main.home : EditablePanel
--- The landing page: a wordmark and a left-aligned column of actions. Which actions appear depends on whether the player already has a character loaded and whether their character list has arrived.
local PANEL = {}

--- Builds the action column.
---@realm client
function PANEL:Init()
    hook.Run("PreMainMenuHomeCreated", self)

    self.buttons = {}

    self.column = self:Add("EditablePanel")

    self:PopulateActions()

    hook.Run("PostMainMenuHomeCreated", self)
end

--- Adds one action to the column.
---@realm client
---@param text string Button label.
---@param callback function Click handler.
---@param bDanger? boolean Whether the action destroys something.
---@return Panel button The created button.
function PANEL:AddAction(text, callback, bDanger)
    local button = self.column:Add("ax.button")
    button:Dock(TOP)
    button:SetTall(ax.util:ScreenScale(16))
    button:DockMargin(0, 0, 0, ax.ui:Space("sm"))
    button:SetLabel(text)
    button:SetDanger(bDanger)
    button.DoClick = callback

    self.buttons[#self.buttons + 1] = button

    return button
end

--- Builds the action list for the player's current state.
---@realm client
function PANEL:PopulateActions()
    for i = 1, #self.buttons do
        if ( IsValid(self.buttons[i]) ) then
            self.buttons[i]:Remove()
        end
    end

    self.buttons = {}

    local parent = self:GetParent()
    local client = ax.client

    -- Only offered when a character is already in the world; otherwise there is nothing to return to.
    if ( ax.util:IsValidPlayer(client) and client:GetCharacter() ) then
        self:AddAction(ax.localization:GetPhrase("mainmenu.play"), function()
            if ( IsValid(parent) ) then
                parent:FadeOut()
            end
        end)
    end

    self:AddAction(ax.localization:GetPhrase("mainmenu.load"), function()
        if ( IsValid(parent) ) then
            parent:ShowPage("load")
        end
    end)

    self:AddAction(ax.localization:GetPhrase("mainmenu.create"), function()
        if ( IsValid(parent) ) then
            parent:ShowPage("create")
        end
    end)

    self:AddAction(ax.localization:GetPhrase("mainmenu.disconnect"), function()
        if ( hook.Run("ShouldAllowDisconnect", self) == false ) then return end

        RunConsoleCommand("disconnect")
    end, true)

    self:InvalidateLayout()
end

--- Lays the column out against the lower left, leaving the upper area to the wordmark.
---@realm client
---@param width number Panel width in pixels.
---@param height number Panel height in pixels.
function PANEL:PerformLayout(width, height)
    local columnWidth = math.max(width * 0.22, ax.util:ScreenScale(160))
    local rowHeight = ax.util:ScreenScale(16) + ax.ui:Space("sm")
    local columnHeight = rowHeight * #self.buttons

    self.column:SetSize(columnWidth, columnHeight)
    self.column:SetPos(ax.util:ScreenScale(48), height - columnHeight - ax.util:ScreenScale(36))
end

--- Rebuilds the actions when the character list arrives, since PLAY depends on it.
---@realm client
function PANEL:PopulateCharacterList()
    self:PopulateActions()
end

--- Draws the wordmark and its rule.
---@realm client
---@param width number Panel width in pixels.
---@param height number Panel height in pixels.
function PANEL:Paint(width, height)
    local x = ax.util:ScreenScale(48)
    local y = ax.util:ScreenScale(42)

    local title = "Parallax"
    if ( SCHEMA and isstring(SCHEMA.name) and SCHEMA.name != "" ) then
        title = SCHEMA.name
    end

    local titleWidth = ax.draw:TextTracked(utf8.upper(title), "ax.huge.bold", x, y, ax.color.textBright, ax.util:ScreenScale(6), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    ax.draw:HLine(x, y + ax.util:ScreenScale(20), titleWidth, ax.color.line)
end

vgui.Register("ax.main.home", PANEL, "EditablePanel")
