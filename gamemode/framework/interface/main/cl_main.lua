--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Seconds the outgoing page takes to fade away.
local PAGE_OUT_TIME = 0.15

--- Seconds the incoming page takes to fade in.
local PAGE_IN_TIME = 0.2

--- Seconds the black takes to fall when the menu hands off to the world.
local FADE_OUT_TIME = 0.5

---@class ax.main : EditablePanel
--- The main menu shell. It owns `ax.gui.main`, holds one page at a time, and cross-fades between them; there is no slide system, because sliding panels are a glass-interface idiom and read wrong against hairline monochrome.
---
--- Keeping `ax.gui.main` valid is also what drives the map scene: `ax.mapscene:ShouldRenderMapScene` gates on it, so the 3D background camera and its music start and stop with this panel and must not be duplicated here.
local PANEL = {}

--- Builds the shell, claims the singleton handle, and opens on the splash the first time it is shown in a session.
---@realm client
function PANEL:Init()
    if ( IsValid(ax.gui.main) ) then
        ax.gui.main:Remove()
    end

    ax.gui.main = self

    hook.Run("PreMainMenuCreated", self)

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())
    self:MakePopup()

    self.pages = {}
    self.page = nil

    -- The splash is a first-impression card, not a landing page, so opening the menu again mid-session goes straight to the actions.
    if ( AX_SPLASH_SHOWN ) then
        self:ShowPage("home")
    else
        AX_SPLASH_SHOWN = true
        self:ShowPage("splash")
    end

    hook.Run("PostMainMenuCreated", self)
end

--- Refits the shell after a resolution change.
---@realm client
function PANEL:OnScreenSizeChanged()
    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())
end

--- The panel class backing each page name.
local PAGE_CLASSES = {
    splash = "ax.main.splash",
    home = "ax.main.home",
    load = "ax.main.load",
    create = "ax.main.create",
}

--- Swaps the visible page, fading the outgoing one away before the incoming one fades in.
---@realm client
---@param name string Page name: `"splash"`, `"home"` or `"load"`.
---@return Panel|nil page The new page, or nil when the name is unknown.
function PANEL:ShowPage(name)
    local class = PAGE_CLASSES[name]
    if ( !class ) then
        ax.util:PrintError("ax.main:ShowPage: unknown page '" .. tostring(name) .. "'")
        return nil
    end

    if ( self.page == name and IsValid(self.pages[name]) ) then
        return self.pages[name]
    end

    local previous = self.page
    local outgoing = previous and self.pages[previous]

    -- Built before the outgoing page is torn down: if a page errors in Init, the menu is left showing what it already had rather than an empty screen with no way back.
    local page = self:Add(class)
    page:Dock(FILL)
    page:SetAlpha(0)

    if ( IsValid(outgoing) ) then
        -- Input is released immediately so the dying page cannot eat a click aimed at the incoming one.
        outgoing:SetMouseInputEnabled(false)
        outgoing:SetKeyboardInputEnabled(false)

        outgoing.pageAlpha = 255
        outgoing:Motion(PAGE_OUT_TIME, {
            Target = { pageAlpha = 0 },
            Easing = "InQuad",
            Think = function(values)
                if ( IsValid(outgoing) ) then
                    outgoing:SetAlpha(values.pageAlpha)
                end
            end,
            OnComplete = function(panel)
                if ( IsValid(panel) ) then
                    panel:Remove()
                end
            end
        })

        self.pages[previous] = nil
        self[previous] = nil
    end

    page.pageAlpha = 0
    page:Motion(PAGE_IN_TIME, {
        Target = { pageAlpha = 255 },
        Easing = "OutQuad",
        Delay = IsValid(outgoing) and PAGE_OUT_TIME or 0,
        Think = function(values)
            if ( IsValid(page) ) then
                page:SetAlpha(values.pageAlpha)
            end
        end
    })

    self.pages[name] = page
    self.page = name
    self[name] = page

    hook.Run("OnMainMenuPageChanged", self, name, previous)

    return page
end

--- Picks the page to open once the splash is dismissed.
---@realm client
function PANEL:ShowAfterSplash()
    self:ShowPage("home")
end

--- Returns the local player's character list, which is nil until the server has sent it.
---@realm client
---@return table|nil characters The character list, or nil when it has not arrived yet.
function PANEL:GetCharacters()
    if ( !ax.util:IsValidPlayer(ax.client) ) then return nil end

    return ax.client:GetTable().axCharacters
end

--- Rebuilds whatever page is showing character data; a no-op when the current page does not display any.
---@realm client
function PANEL:RefreshCharacters()
    local page = self.page and self.pages[self.page]
    if ( !IsValid(page) or !page.PopulateCharacterList ) then return end

    page:PopulateCharacterList()
end

--- Called when a character is created while another is already loaded, so the menu stays open; returns to the select screen with the new character in the list.
---@realm client
---@param character table The newly created character.
function PANEL:OnCharacterCreated(character)
    self:ShowPage("load")
end

--- Raises the black, tears the menu down, and hands the screen to whatever comes next.
---@realm client
---@param callback? function Run once the black is fully up.
---@param bHoldBlack? boolean Leave the black up for the caller to lift; otherwise it lifts on its own.
function PANEL:FadeOut(callback, bHoldBlack)
    if ( self.bFadingOut ) then return end
    self.bFadingOut = true

    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)

    ax.fade:To(255, FADE_OUT_TIME, 0, function()
        if ( IsValid(self) ) then
            self:Remove()
        end

        if ( isfunction(callback) ) then
            callback()
        end

        if ( !bHoldBlack ) then
            ax.fade:To(0, AX_FADE_REVEAL_TIME, AX_FADE_HOLD_TIME)
        end
    end)
end

--- Closes the menu without a fade.
---@realm client
function PANEL:Close()
    self:Remove()
end

--- Releases the singleton handle so the map scene and the HUD stop treating the menu as open.
---@realm client
function PANEL:OnRemove()
    if ( ax.gui.main == self ) then
        ax.gui.main = nil
    end
end

--- Paints the menu ground. The map scene draws behind this panel, so an opaque fill would hide it entirely; when a scene is running the ground drops to a scrim instead, leaving the camera visible as a faint plate behind the type.
---@realm client
---@param width number Panel width in pixels.
---@param height number Panel height in pixels.
function PANEL:Paint(width, height)
    if ( ax.mapscene and ax.mapscene:ShouldRenderMapScene(ax.client) ) then
        ax.draw:Rect(0, 0, width, height, ColorAlpha(ax.color.void, 100))
        return
    end

    ax.draw:Rect(0, 0, width, height, ax.color.void)
end

vgui.Register("ax.main", PANEL, "EditablePanel")

-- The only signal that the character list has arrived. Registered at file scope rather than per-panel because the menu is a singleton and an Init/OnRemove pair is one more lifecycle to get wrong.
hook.Add("OnCharactersRestored", "ax.main.RefreshCharacters", function()
    if ( !IsValid(ax.gui.main) ) then return end

    ax.gui.main:RefreshCharacters()
end)

concommand.Add("ax_menu", function()
    if ( IsValid(ax.gui.main) ) then
        ax.gui.main:Remove()
        return
    end

    vgui.Create("ax.main")
end)
