--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("DButton")

--- Seconds the black takes to rise before the load request is sent, so the reply lands behind a covered screen.
local LOAD_FADE_TIME = 0.5

--- Seconds a row's hover transition takes to settle.
local HOVER_TIME = 0.18

--- Played as the cursor lands on a button.
local SOUND_ROLLOVER = "parallax/ui/widgets/button/rollover.wav"

--- Played as a button is pressed.
local SOUND_PRESS = "parallax/ui/widgets/button/press.wav"

---@class ax.main.load.row : DButton
--- One character in the select rail. Selection is marked with a left rule rather than a fill change, because in this interface brightness alone carries state.
local ROW = {}

--- Initialises the row.
---@realm client
function ROW:Init()
    self:SetText("")
    self:SetPaintBackground(false)

    self.character = nil
    self.hoverFrac = 0
    self.bSelected = false
end

--- Binds a character to the row.
---@realm client
---@param character table The character to display.
function ROW:SetCharacter(character)
    self.character = character
end

--- Marks the row as the current selection.
---@realm client
---@param bSelected boolean Whether this row is selected.
function ROW:SetSelected(bSelected)
    self.bSelected = bSelected and true or false
end

--- Plays the rollover cue and eases the hover state in.
---@realm client
function ROW:OnCursorEntered()
    if ( self:GetDisabled() ) then return end

    surface.PlaySound(SOUND_ROLLOVER)

    self:Motion(HOVER_TIME, {
        Target = { hoverFrac = 1 },
        Easing = "OutQuad"
    })
end

--- Eases the hover state back out.
---@realm client
function ROW:OnCursorExited()
    self:Motion(HOVER_TIME, {
        Target = { hoverFrac = 0 },
        Easing = "OutQuad"
    })
end

--- Plays the press cue, then hands off to the stock button so `DoClick` still fires.
---@realm client
---@param code number The mouse code pressed.
function ROW:OnMousePressed(code)
    if ( !self:GetDisabled() and code == MOUSE_LEFT ) then
        surface.PlaySound(SOUND_PRESS)
    end

    BaseClass.OnMousePressed(self, code)
end

--- Draws the row surface, its rule and its text.
---@realm client
---@param width number Panel width in pixels.
---@param height number Panel height in pixels.
function ROW:Paint(width, height)
    -- Selection reads as fully lit whether or not the cursor is on it, so the two states share one ramp.
    local fraction = math.max(self.hoverFrac or 0, self.bSelected and 1 or 0)

    ax.draw:Rect(0, 0, width, height, ax.ui:Mix(ax.color.panel, ax.color.fillHover, fraction))
    ax.draw:Hairline(0, 0, width, height, ax.ui:Mix(ax.color.line, ax.color.lineStrong, fraction))

    if ( self.bSelected ) then
        ax.draw:Edge(0, 0, width, height, "left", ax.color.accent)
    end

    local character = self.character
    if ( !istable(character) ) then return end

    local padding = ax.ui:Space("lg")
    local name = character:GetName() or "Unnamed"

    ax.draw:TextTracked(utf8.upper(name), "ax.regular.bold", padding, height * 0.34, ax.ui:Mix(ax.color.text, ax.color.textBright, fraction), ax.util:ScreenScale(2), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    local factionData = character:GetFactionData()
    local factionName = istable(factionData) and factionData.name or "Unknown"

    draw.SimpleText(factionName, "ax.small", padding, height * 0.68, ax.color.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    local lastPlayed = character:GetLastPlayed()
    if ( isnumber(lastPlayed) and lastPlayed > 0 ) then
        draw.SimpleText(os.date("%d/%m/%y", lastPlayed), "ax.tiny", width - padding, height * 0.68, ax.color.textFaint, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
end

vgui.Register("ax.main.load.row", ROW, "DButton")

---@class ax.main.load : EditablePanel
--- The character select screen: a rail of characters on the left, a preview of the selection on the right, and the actions along the bottom.
local PANEL = {}

--- Builds the two columns and the action rail.
---@realm client
function PANEL:Init()
    hook.Run("PreMainMenuLoadCreated", self)

    self.rows = {}
    self.selectedID = nil
    self.bSending = false

    self.actions = self:Add("EditablePanel")
    self.actions:Dock(BOTTOM)
    self.actions:SetTall(ax.util:ScreenScale(20))
    self.actions:DockMargin(ax.util:ScreenScale(48), ax.ui:Space("lg"), ax.util:ScreenScale(48), ax.util:ScreenScale(30))

    self:BuildActions()

    -- Derma lays docked children out in the order they were added, so the bottom rail has to exist before the filling columns.
    self.rail = self:Add("ax.scroller")
    self.rail:Dock(LEFT)
    self.rail:DockMargin(ax.util:ScreenScale(48), ax.util:ScreenScale(42), 0, 0)

    self.preview = self:Add("EditablePanel")
    self.preview:Dock(FILL)
    self.preview:DockMargin(ax.util:ScreenScale(24), ax.util:ScreenScale(42), ax.util:ScreenScale(48), 0)

    self.model = self.preview:Add("ax.model")
    self.model:Dock(FILL)
    self.model:SetRotating(true)

    self:PopulateCharacterList()

    hook.Run("PostMainMenuLoadCreated", self)
end

--- Builds the bottom action rail.
---@realm client
function PANEL:BuildActions()
    local parent = self:GetParent()

    self.playButton = self.actions:Add("ax.button")
    self.playButton:Dock(LEFT)
    self.playButton:SetWide(ax.util:ScreenScale(96))
    self.playButton:SetLabel(ax.localization:GetPhrase("mainmenu.play"))
    self.playButton:SetAlign(TEXT_ALIGN_CENTER)
    self.playButton.DoClick = function()
        self:LoadSelected()
    end

    self.deleteButton = self.actions:Add("ax.button")
    self.deleteButton:Dock(LEFT)
    self.deleteButton:SetWide(ax.util:ScreenScale(96))
    self.deleteButton:DockMargin(ax.ui:Space("sm"), 0, 0, 0)
    self.deleteButton:SetLabel("Delete")
    self.deleteButton:SetAlign(TEXT_ALIGN_CENTER)
    self.deleteButton:SetDanger(true)
    self.deleteButton.DoClick = function()
        self:ShowDeleteConfirm()
    end

    local create = self.actions:Add("ax.button")
    create:Dock(LEFT)
    create:SetWide(ax.util:ScreenScale(120))
    create:DockMargin(ax.ui:Space("sm"), 0, 0, 0)
    create:SetLabel(ax.localization:GetPhrase("mainmenu.create"))
    create:SetAlign(TEXT_ALIGN_CENTER)
    create.DoClick = function()
        if ( IsValid(parent) ) then
            parent:ShowPage("create")
        end
    end

    local back = self.actions:Add("ax.button")
    back:Dock(RIGHT)
    back:SetWide(ax.util:ScreenScale(96))
    back:SetLabel("Back")
    back:SetAlign(TEXT_ALIGN_CENTER)
    back.DoClick = function()
        if ( IsValid(parent) ) then
            parent:ShowPage("home")
        end
    end
end

--- Returns the character list, which is nil until the server has sent it.
---@realm client
---@return table|nil characters The character list, or nil when it has not arrived.
function PANEL:GetCharacters()
    if ( !ax.util:IsValidPlayer(ax.client) ) then return nil end

    return ax.client:GetTable().axCharacters
end

--- Rebuilds the rail from the current character list, preserving the selection where it still exists.
---@realm client
function PANEL:PopulateCharacterList()
    if ( !IsValid(self.rail) ) then return end

    self.rail:Clear()
    self.rows = {}

    local characters = self:GetCharacters()
    if ( !istable(characters) ) then
        self:UpdateActionState()
        return
    end

    -- Most recently played first, so the character the player wants is the one under the cursor.
    local sorted = {}
    for i = 1, #characters do
        sorted[#sorted + 1] = characters[i]
    end

    table.sort(sorted, function(a, b)
        return (a:GetLastPlayed() or 0) > (b:GetLastPlayed() or 0)
    end)

    local bStillSelected = false

    for i = 1, #sorted do
        local character = sorted[i]

        local row = self.rail:Add("ax.main.load.row")
        row:Dock(TOP)
        row:SetTall(ax.util:ScreenScale(22))
        row:DockMargin(0, 0, ax.ui:Space("md"), ax.ui:Space("sm"))
        row:SetCharacter(character)
        row.DoClick = function()
            self:SelectCharacter(character.id)
        end

        self.rows[character.id] = row

        if ( self.selectedID == character.id ) then
            bStillSelected = true
        end
    end

    if ( !bStillSelected ) then
        self.selectedID = sorted[1] and sorted[1].id or nil
    end

    self:SelectCharacter(self.selectedID)
end

--- Selects a character, updating the rail highlight and the preview.
---@realm client
---@param id number|nil The character id to select, or nil to clear the selection.
function PANEL:SelectCharacter(id)
    self.selectedID = id

    for rowID, row in pairs(self.rows) do
        if ( IsValid(row) ) then
            row:SetSelected(rowID == id)
        end
    end

    local character = id and ax.character:Get(id)
    if ( IsValid(self.model) ) then
        if ( istable(character) ) then
            self.model:SetCharacterModel(character:GetModel(), character:GetSkin())
            self.model:SetVisible(true)
        else
            self.model:SetVisible(false)
        end
    end

    self:UpdateActionState()
end

--- Enables or disables the actions for the current selection.
---@realm client
function PANEL:UpdateActionState()
    local bHasSelection = self.selectedID != nil and istable(ax.character:Get(self.selectedID))

    if ( IsValid(self.playButton) ) then
        self.playButton:SetDisabled(!bHasSelection or self.bSending)
    end

    if ( IsValid(self.deleteButton) ) then
        self.deleteButton:SetDisabled(!bHasSelection or self.bSending)
    end
end

--- Raises the black and then asks the server to load the selection; the fade goes up first so the reply lands behind a covered screen.
---@realm client
function PANEL:LoadSelected()
    if ( self.bSending ) then return end

    local id = self.selectedID
    if ( !id or !istable(ax.character:Get(id)) ) then return end

    -- `ax.net` drops a second send of the same message within its cooldown, so this guard is load-bearing rather than cosmetic.
    self.bSending = true
    self:UpdateActionState()

    ax.fade:To(255, LOAD_FADE_TIME, 0, function()
        ax.net:Start("character.load", id)
    end)
end

--- Opens the delete confirmation over the screen.
---@realm client
function PANEL:ShowDeleteConfirm()
    if ( self.bSending or IsValid(self.confirm) ) then return end

    local id = self.selectedID
    local character = id and ax.character:Get(id)
    if ( !istable(character) ) then return end

    -- Parented to the root rather than to this page: a second FILL child would fight the preview for the remaining space, and the overlay has to cover the action rail too.
    local root = self:GetParent()
    if ( !IsValid(root) ) then return end

    local confirm = root:Add("EditablePanel")
    confirm:SetSize(root:GetWide(), root:GetTall())
    confirm:SetPos(0, 0)
    confirm:SetZPos(32000)
    confirm:SetMouseInputEnabled(true)
    confirm:MoveToFront()
    confirm.Paint = function(_, width, height)
        ax.draw:Scrim(1)

        local boxWidth = math.max(width * 0.32, ax.util:ScreenScale(240))
        local boxHeight = ax.util:ScreenScale(68)
        local boxX = width / 2 - boxWidth / 2
        local boxY = height / 2 - boxHeight / 2

        ax.draw:Panel(boxX, boxY, boxWidth, boxHeight, ax.color.panel, ax.color.danger)

        ax.draw:TextTracked("DELETE CHARACTER", "ax.regular.bold", width / 2, boxY + ax.util:ScreenScale(14), ax.color.danger, ax.util:ScreenScale(3), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(character:GetName() or "Unnamed", "ax.medium.bold", width / 2, boxY + ax.util:ScreenScale(28), ax.color.textBright, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("This cannot be undone.", "ax.small", width / 2, boxY + ax.util:ScreenScale(39), ax.color.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    self.confirm = confirm

    local buttonWidth = ax.util:ScreenScale(88)
    local buttonHeight = ax.util:ScreenScale(15)

    local cancel = confirm:Add("ax.button")
    cancel:SetSize(buttonWidth, buttonHeight)
    cancel:SetLabel("Cancel")
    cancel:SetAlign(TEXT_ALIGN_CENTER)
    cancel.DoClick = function()
        confirm:Remove()
    end

    local accept = confirm:Add("ax.button")
    accept:SetSize(buttonWidth, buttonHeight)
    accept:SetLabel("Delete")
    accept:SetAlign(TEXT_ALIGN_CENTER)
    accept:SetDanger(true)
    accept.DoClick = function()
        self:DeleteCharacter(id)
        confirm:Remove()
    end

    confirm.PerformLayout = function(_, width, height)
        local boxHeight = ax.util:ScreenScale(68)
        local y = height / 2 + boxHeight / 2 - buttonHeight - ax.ui:Space("md")

        cancel:SetPos(width / 2 - buttonWidth - ax.ui:Space("sm"), y)
        accept:SetPos(width / 2 + ax.ui:Space("sm"), y)
    end
end

--- Asks the server to delete a character.
---@realm client
---@param id number The character id to delete.
function PANEL:DeleteCharacter(id)
    if ( self.bSending ) then return end

    self.bSending = true
    self:UpdateActionState()

    ax.net:Start("character.delete", id)

    -- The list is rebuilt from the server's reply, not optimistically, so a rejected delete cannot leave a phantom gap in the rail.
    timer.Simple(0.5, function()
        if ( !IsValid(self) ) then return end

        self.bSending = false
        self:UpdateActionState()
    end)
end

--- Sizes the rail against the panel width.
---@realm client
---@param width number Panel width in pixels.
---@param height number Panel height in pixels.
function PANEL:PerformLayout(width, height)
    if ( IsValid(self.rail) ) then
        self.rail:SetWide(math.max(width * 0.34, ax.util:ScreenScale(200)))
    end
end

--- Draws the heading and the empty states.
---@realm client
---@param width number Panel width in pixels.
---@param height number Panel height in pixels.
function PANEL:Paint(width, height)
    local x = ax.util:ScreenScale(48)
    local y = ax.util:ScreenScale(26)

    local headingWidth = ax.draw:TextTracked("SELECT CHARACTER", "ax.large.bold", x, y, ax.color.textBright, ax.util:ScreenScale(5), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    ax.draw:HLine(x, y + ax.util:ScreenScale(9), headingWidth, ax.color.line)

    local characters = self:GetCharacters()
    if ( istable(characters) and characters[1] != nil ) then return end

    -- A list that has not arrived is a different state from one that arrived empty, and saying so avoids "you have no characters" flashing during a slow join.
    local message = istable(characters) and "NO CHARACTERS" or "RETRIEVING CHARACTERS"

    ax.draw:TextTracked(message, "ax.regular.bold", x, height * 0.45, ax.color.textFaint, ax.util:ScreenScale(4), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

vgui.Register("ax.main.load", PANEL, "EditablePanel")
