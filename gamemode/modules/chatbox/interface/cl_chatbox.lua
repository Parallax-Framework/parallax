--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

DEFINE_BASECLASS("EditablePanel")

AccessorFunc(PANEL, "m_bIsMenuComponent", "IsMenu", FORCE_BOOL)
AccessorFunc(PANEL, "m_bDraggable", "Draggable", FORCE_BOOL)
AccessorFunc(PANEL, "m_bSizable", "Sizable", FORCE_BOOL)
AccessorFunc(PANEL, "m_bScreenLock", "ScreenLock", FORCE_BOOL)
AccessorFunc(PANEL, "m_iMinWidth", "MinWidth", FORCE_NUMBER)
AccessorFunc(PANEL, "m_iMinHeight", "MinHeight", FORCE_NUMBER)

function PANEL:GetChatType()
    return self.chatTypeState and self.chatTypeState.current or ax.chatbox.util.constants.CHAT_TYPE_DEFAULT or "ic"
end

function PANEL:IsChatboxOpen()
    return self.chatboxVisible == true
end

function PANEL:LockEntry(callback)
    self.entryLockCount = (self.entryLockCount or 0) + 1
    local ok, err = pcall(callback)
    self.entryLockCount = math.max(0, (self.entryLockCount or 1) - 1)

    if ( !ok ) then
        ax.util:PrintError("[CHATBOX] Entry lock callback failed: " .. tostring(err))
    end
end

function PANEL:QueueOptionUpdate(name, value)
    self.pendingOptions[name] = value

    timer.Create(self.optionFlushTimerID, ax.chatbox.util.constants.OPTION_FLUSH_INTERVAL or 0.12, 1, function()
        if ( !IsValid(self) ) then return end
        self:FlushOptionUpdates()
    end)
end

function PANEL:FlushOptionUpdates(force)
    if ( force ) then
        timer.Remove(self.optionFlushTimerID)
    end

    if ( !self.pendingOptions or table.IsEmpty(self.pendingOptions) ) then
        return
    end

    for name, value in pairs(self.pendingOptions) do
        ax.option:Set(name, value, false, true)
    end

    table.Empty(self.pendingOptions)
end

function PANEL:IsOverResize(mouseX, mouseY)
    local x, y = self:LocalToScreen(0, 0)
    local size = ax.chatbox.util.constants.RESIZE_HANDLE_SIZE or 20

    return mouseX > (x + self:GetWide() - size) and mouseY > (y + self:GetTall() - size)
end

function PANEL:IsOverDrag(mouseX, mouseY)
    local x, y = self:LocalToScreen(0, 0)
    local height = ax.chatbox.util.constants.DRAG_ZONE_HEIGHT or 24

    return mouseX >= x and mouseX <= (x + self:GetWide()) and mouseY >= y and mouseY <= (y + height)
end

function PANEL:ClampToScreen(x, y, width, height)
    if ( !self:GetScreenLock() ) then
        return x, y
    end

    width = width or self:GetWide()
    height = height or self:GetTall()

    return math.Clamp(x, 0, ScrW() - width), math.Clamp(y, 0, ScrH() - height)
end

function PANEL:BuildContextMenu()
    local menu = DermaMenu(false, self)

    menu:AddOption(ax.chatbox.util:GetPhrase("chatbox.menu.close", "Close Chat"), function()
        self:SetVisible(false)
    end)

    menu:AddOption(ax.chatbox.util:GetPhrase("chatbox.menu.clear_history", "Clear Chat History"), function()
        Derma_Query(
            ax.chatbox.util:GetPhrase("chatbox.menu.confirm_clear_message", "Clear all chat history?"),
            ax.chatbox.util:GetPhrase("chatbox.menu.confirm_clear_title", "Clear Chat History"),
            ax.chatbox.util:GetPhrase("yes", "Yes"),
            function()
                if ( IsValid(self.history) ) then
                    self.history:Clear()
                end
            end,
            ax.chatbox.util:GetPhrase("no", "No")
        )
    end)

    menu:AddSpacer()

    menu:AddOption(ax.chatbox.util:GetPhrase("chatbox.menu.reset_position", "Reset Position"), function()
        local x = ax.option:GetDefault("chat.x")
        local y = ax.option:GetDefault("chat.y")

        if ( isnumber(x) and isnumber(y) ) then
            self:SetPos(x, y)
            ax.option:SetToDefault("chat.x")
            ax.option:SetToDefault("chat.y")
        end
    end)

    menu:AddOption(ax.chatbox.util:GetPhrase("chatbox.menu.reset_size", "Reset Size"), function()
        local width = ax.option:GetDefault("chat.width")
        local height = ax.option:GetDefault("chat.height")

        if ( isnumber(width) and isnumber(height) ) then
            self:SetSize(width, height)
            ax.option:SetToDefault("chat.width")
            ax.option:SetToDefault("chat.height")
            self:InvalidateLayout(true)
        end
    end)

    menu:Open()
end

function PANEL:SetVisible(visible)
    visible = visible == true

    if ( visible ) then
        self.chatboxVisible = true
        self:SetAlpha(ax.chatbox.util.constants.RECOMMEND_ALPHA_VISIBLE or 255)
        self:SetMouseInputEnabled(true)
        self:SetKeyboardInputEnabled(true)
        self:MakePopup()
        self.entry:SetVisible(true)
        self.entry:RequestFocus()

        local x, y = self.entry:LocalToScreen(self.entry:GetWide() / 2, self.entry:GetTall() / 2)
        input.SetCursorPos(math.Clamp(math.floor(x), 0, ScrW()), math.Clamp(math.floor(y), 0, ScrH()))

        hook.Run("ChatboxOnVisibilityChanged", true, self)
        return
    end

    local oldType = self:GetChatType()

    self.chatboxVisible = false
    self:SetAlpha(ax.chatbox.util.constants.RECOMMEND_ALPHA_HIDDEN or 0)
    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)

    if ( ax.chatbox.recommendations.CancelDebounce ) then
        ax.chatbox.recommendations:CancelDebounce(self)
    end

    if ( ax.chatbox.recommendations.Hide ) then
        ax.chatbox.recommendations:Hide(self)
    end

    self:LockEntry(function()
        self.entry:SetText("")
        self.entry:SetCaretPos(0)
    end)

    self.entry:SetVisible(false)

    local newType = oldType
    local changed = false

    if ( ax.chatbox.recommendations.SetChatType ) then
        _, newType, changed = ax.chatbox.recommendations:SetChatType(self, ax.chatbox.util.constants.CHAT_TYPE_DEFAULT or "ic")
    end

    hook.Run("ChatboxOnTextChanged", "", newType)
    if ( changed ) then
        hook.Run("ChatboxOnChatTypeChanged", newType, oldType)
    end

    self:FlushOptionUpdates(true)
    hook.Run("ChatboxOnVisibilityChanged", false, self)
end

function PANEL:PopulateRecommendations(text, kind)
    if ( ax.chatbox.recommendations.Populate ) then
        ax.chatbox.recommendations:Populate(self, text, kind)
    end
end

function PANEL:CycleRecommendations()
    if ( ax.chatbox.recommendations.Cycle ) then
        ax.chatbox.recommendations:Cycle(self)
    end
end

function PANEL:SelectRecommendation(identifier)
    if ( ax.chatbox.recommendations.Select ) then
        ax.chatbox.recommendations:Select(self, identifier)
    end
end

local PANEL_INSTANCE_COUNTER = 0
function PANEL:Init()
    if ( IsValid(ax.gui.chatbox) and ax.gui.chatbox != self ) then
        ax.gui.chatbox:Remove()
    end

    PANEL_INSTANCE_COUNTER = PANEL_INSTANCE_COUNTER + 1
    self.instanceID = PANEL_INSTANCE_COUNTER
    self.recommendTimerID = "ax.chatbox.recommendations." .. self.instanceID
    self.optionFlushTimerID = "ax.chatbox.option.flush." .. self.instanceID

    self.chatTypeState = {
        current = ax.chatbox.util.constants.CHAT_TYPE_DEFAULT or "ic",
        previous = ax.chatbox.util.constants.CHAT_TYPE_DEFAULT or "ic",
        history = { ax.chatbox.util.constants.CHAT_TYPE_DEFAULT or "ic" }
    }

    self.historyCache = {}
    self.historyIndex = 0
    self.entryLockCount = 0
    self.chatboxVisible = false

    self.commandClosestCache = {}
    self.commandRecommendCache = {}
    self.voiceClassCache = {}
    self.voiceEntryCache = {}
    self.warnedVoiceUnavailable = false
    self.pendingOptions = {}

    self:SetFocusTopLevel(true)
    self:SetSize(hook.Run("GetChatboxSize"))
    self:SetPos(hook.Run("GetChatboxPos"))
    self:SetDraggable(true)
    self:SetSizable(true)
    self:SetScreenLock(true)
    self:SetMinWidth(ax.util:ScreenScale(225) / 3)
    self:SetMinHeight(ax.util:ScreenScaleH(150) / 3)

    if ( ax.chatbox.bottom.Build ) then
        ax.chatbox.bottom:Build(self)
    end

    local pad = ScreenScale(ax.chatbox.util.constants.SCREEN_PADDING_SCALE or 2)

    self.content = self:Add("EditablePanel")
    self.content:Dock(FILL)
    self.content:DockMargin(pad, pad, pad, pad)

    self.history = self.content:Add("ax.scroller.vertical")
    self.history:Dock(FILL)
    self.history:GetVBar():SetWide(0)
    self.history:SetInverted(true)
    self.history:SetMouseInputEnabled(false)

    self.recommendations = self.content:Add("ax.scroller.vertical")
    self.recommendations:SetVisible(false)
    self.recommendations:SetAlpha(ax.chatbox.util.constants.RECOMMEND_ALPHA_HIDDEN or 0)
    self.recommendations:GetVBar():SetWide(0)
    self.recommendations.items = {}
    self.recommendations.rows = {}
    self.recommendations.indexSelect = 0
    self.recommendations.maxSelection = 0
    self.recommendations.cycleState = ax.chatbox.util.constants.RECOMMEND_CYCLE_IDLE or 0
    self.recommendations.kind = nil
    self.recommendations.Paint = function(_, width, height)
        local glass = ax.theme:GetGlass()
        local metrics = ax.theme:GetMetrics()

        ax.theme:DrawGlassPanel(0, 0, width, height, {
            radius = math.max(4, metrics.roundness * 0.6),
            blur = 0.9,
            flags = ax.render.SHAPE_IOS,
            fill = glass.menu or glass.overlay,
            border = glass.menuBorder or glass.panelBorder
        })

        ax.theme:DrawGlassGradients(0, 0, width, height)
    end

    self.recommendations.hint = self.recommendations:Add("ax.text")
    self.recommendations.hint:Dock(TOP)
    self.recommendations.hint:DockMargin(8, ScreenScale(ax.chatbox.util.constants.INNER_PADDING_SCALE or 1), 8, ScreenScale(ax.chatbox.util.constants.INNER_PADDING_SCALE or 1))
    self.recommendations.hint:SetFont("ax.small")
    self.recommendations.hint:SetContentAlignment(4)
    self.recommendations.hint:SetZPos(-100)
    self.recommendations.hint:SetTall(draw.GetFontHeight("ax.small") + ScreenScale(ax.chatbox.util.constants.INNER_PADDING_SCALE or 1) * 2)
    self.recommendations.hint:SetVisible(false)

    self.recommendations.notice = self.recommendations:Add("ax.text")
    self.recommendations.notice:Dock(BOTTOM)
    self.recommendations.notice:DockMargin(8, 0, 8, ScreenScale(ax.chatbox.util.constants.INNER_PADDING_SCALE or 1))
    self.recommendations.notice:SetFont("ax.small")
    self.recommendations.notice:SetVisible(false)

    if ( ax.chatbox.bottom.BindCallbacks ) then
        ax.chatbox.bottom:BindCallbacks(self)
    end

    self:SetAlpha(ax.chatbox.util.constants.RECOMMEND_ALPHA_HIDDEN or 0)
    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)
    self.entry:SetVisible(false)

    chat.GetChatBoxPos = function()
        return self:GetPos()
    end

    chat.GetChatBoxSize = function()
        return self:GetSize()
    end

    self:InvalidateLayout(true)
    ax.gui.chatbox = self
end

function PANEL:Think()
    if ( input.IsKeyDown(KEY_ESCAPE) and self:IsChatboxOpen() ) then
        self:SetVisible(false)
    end

    local mouseX = math.Clamp(gui.MouseX(), 1, ScrW() - 1)
    local mouseY = math.Clamp(gui.MouseY(), 1, ScrH() - 1)

    if ( self.dragState ) then
        local x = mouseX - self.dragState.offsetX
        local y = mouseY - self.dragState.offsetY
        x, y = self:ClampToScreen(x, y)
        self:SetPos(x, y)
        self:QueueOptionUpdate("chat.x", x)
        self:QueueOptionUpdate("chat.y", y)
    end

    if ( self.resizeState ) then
        local width = mouseX - self.resizeState.offsetX
        local height = mouseY - self.resizeState.offsetY

        width = math.max(width, self:GetMinWidth())
        height = math.max(height, self:GetMinHeight())

        if ( self:GetScreenLock() ) then
            local x, y = self:GetPos()
            width = math.min(width, ScrW() - x)
            height = math.min(height, ScrH() - y)
        end

        self:SetSize(width, height)
        self:QueueOptionUpdate("chat.width", width)
        self:QueueOptionUpdate("chat.height", height)
        self:SetCursor("sizenwse")
        return
    end

    if ( self.Hovered and self:GetSizable() and self:IsOverResize(mouseX, mouseY) ) then
        self:SetCursor("sizenwse")
        return
    end

    if ( self.Hovered and self:GetDraggable() and self:IsOverDrag(mouseX, mouseY) ) then
        self:SetCursor("sizeall")
        return
    end

    self:SetCursor("arrow")

    if ( self.y < 0 ) then
        self:SetPos(self.x, 0)
    end
end

function PANEL:OnKeyCodePressed(key)
    if ( !self:IsChatboxOpen() ) then return end
    if ( key == KEY_TAB ) then self:CycleRecommendations() end
end

function PANEL:OnMousePressed(mouseCode)
    if ( mouseCode == MOUSE_RIGHT ) then
        self:BuildContextMenu()
        return
    end

    local mouseX, mouseY = gui.MouseX(), gui.MouseY()

    if ( self:GetSizable() and self:IsOverResize(mouseX, mouseY) ) then
        self.resizeState = {
            offsetX = mouseX - self:GetWide(),
            offsetY = mouseY - self:GetTall()
        }

        self:MouseCapture(true)
        return
    end

    if ( self:GetDraggable() and self:IsOverDrag(mouseX, mouseY) ) then
        local x, y = self:GetPos()

        self.dragState = {
            offsetX = mouseX - x,
            offsetY = mouseY - y
        }

        self:MouseCapture(true)
        return
    end

    self.entry:RequestFocus()
end

function PANEL:OnMouseReleased()
    local hadDrag = self.dragState != nil
    local hadResize = self.resizeState != nil

    self.dragState = nil
    self.resizeState = nil
    self:MouseCapture(false)

    if ( hadDrag or hadResize ) then
        self:FlushOptionUpdates(true)
    end
end

function PANEL:OnSizeChanged()
    self:InvalidateLayout(true)
end

function PANEL:OnRemove()
    self:FlushOptionUpdates(true)

    if ( ax.chatbox.recommendations.CancelDebounce ) then
        ax.chatbox.recommendations:CancelDebounce(self)
    end

    if ( self.optionFlushTimerID ) then
        timer.Remove(self.optionFlushTimerID)
    end

    if ( ax.gui.chatbox == self ) then
        ax.gui.chatbox = nil
    end
end

function PANEL:Paint(width, height)
    local glass = ax.theme:GetGlass()
    local metrics = ax.theme:GetMetrics()

    ax.theme:DrawGlassPanel(0, 0, width, height, {
        radius = metrics.roundness,
        blur = 1.1,
        flags = ax.render.SHAPE_IOS,
        fill = glass.panel,
        border = glass.panelBorder
    })

    ax.theme:DrawGlassGradients(0, 0, width, height)
end

function PANEL:PerformLayout(width, height)
    local pad = ScreenScale(ax.chatbox.util.constants.SCREEN_PADDING_SCALE or 2)

    if ( IsValid(self.bottom) ) then
        self.bottom:DockMargin(pad, pad, pad, pad)
    end

    if ( IsValid(self.content) ) then
        self.content:DockMargin(pad, pad, pad, pad)
    end

    if ( IsValid(self.bottom) and IsValid(self.entry) ) then
        local innerPad = ScreenScale(ax.chatbox.util.constants.INNER_PADDING_SCALE or 1)
        local entryFont = self.entry:GetFont() or "ax.small"
        local entryTall = draw.GetFontHeight(entryFont) + 8
        self.bottom:SetTall(math.max(ScreenScale(8), entryTall + innerPad * 2))
    end

    if ( IsValid(self.recommendations) and IsValid(self.content) ) then
        self.recommendations:SetPos(0, 0)
        self.recommendations:SetSize(self.content:GetWide(), math.max(0, math.floor(self.content:GetTall() * 0.5)))
    end
end

vgui.Register("ax.chatbox", PANEL, "EditablePanel")

if ( IsValid(ax.gui.chatbox) ) then
    ax.gui.chatbox:Remove()
    vgui.Create("ax.chatbox")
end
