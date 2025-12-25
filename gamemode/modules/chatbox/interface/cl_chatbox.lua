--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

DEFINE_BASECLASS("EditablePanel")

function PANEL:Init()
    -- Remove any existing chatbox instance before creating a new one
    if ( IsValid(ax.gui.chatbox) ) then
        ax.gui.chatbox:Remove()
    end

    self.chatType = "ic"
    self.chatTypePrevious = "ic"

    self:SetSize(hook.Run("GetChatboxSize"))
    self:SetPos(hook.Run("GetChatboxPos"))

    self.categories = self:Add("ax.scroller.horizontal")
    self.categories:Dock(TOP)
    self.categories:InvalidateParent(true)
    self.categories.Paint = function(this, width, height)
        ax.render.Draw(0, 0, 0, width, height, Color(0, 0, 0, 150))
    end

    -- Enable dragging the chatbox by grabbing the top bar
    self.categories:SetMouseInputEnabled(true)
    self.categories:SetCursor("sizeall")
    self.categories.OnMousePressed = function(this, code)
        if ( code == MOUSE_LEFT ) then
            local px, py = self:GetPos()
            this.dragOffsetX = gui.MouseX() - px
            this.dragOffsetY = gui.MouseY() - py
            this.dragging = true
            this:MouseCapture(true)
        elseif ( code == MOUSE_RIGHT ) then
            local menu = DermaMenu()
            menu:AddOption("Reset Position", function()
                ax.option:SetToDefault("chat.x")
                ax.option:SetToDefault("chat.y")

                local rx, ry = hook.Run("GetChatboxPos")
                self:SetPos(rx, ry)
            end)
            menu:AddOption("Reset Size", function()
                ax.option:SetToDefault("chat.width")
                ax.option:SetToDefault("chat.height")

                local rw, rh = hook.Run("GetChatboxSize")
                self:SetSize(rw, rh)
                self:InvalidateLayout(true)
            end)
            menu:Open()
        end
    end
    self.categories.OnMouseReleased = function(this, code)
        if ( this.dragging ) then
            this.dragging = false
            this:MouseCapture(false)

            -- Persist new position
            local x, y = self:GetPos()
            ax.option:Set("chat.x", x)
            ax.option:Set("chat.y", y)
        end
    end
    self.categories.Think = function(this)
        if ( this.dragging ) then
            local mx, my = gui.MouseX(), gui.MouseY()
            local nx = mx - (this.dragOffsetX or 0)
            local ny = my - (this.dragOffsetY or 0)

            local maxX = math.max(0, ScrW() - self:GetWide())
            local maxY = math.max(0, ScrH() - self:GetTall())
            self:SetPos(math.Clamp(nx, 0, maxX), math.Clamp(ny, 0, maxY))
        end
    end

    -- Add some temporary filler categories
    -- TODO: Implement a category system where you can select chat types to show and hide.
    for i = 1, 3 do
        local cat = self.categories:Add("ax.button.flat")
        cat:Dock(LEFT)
        cat:SetFont("ax.small")
        cat:SetFontDefault("ax.small")
        cat:SetFontHovered("ax.small.bold")
        cat:SetText(tostring(i))
        cat:SetTall(cat:GetTall() / 2)

        self.categories:SetTall(math.max(self.categories:GetTall(), cat:GetTall()))
    end

    local bottom = self:Add("EditablePanel")
    bottom:Dock(BOTTOM)
    bottom:DockMargin(ScreenScale(2), ScreenScale(2), ScreenScale(2), ScreenScale(2))

    self.entry = bottom:Add("ax.text.entry")
    self.entry:Dock(FILL)
    self.entry:DockMargin(ScreenScale(1), ScreenScale(1), ScreenScale(1), ScreenScale(1))
    self.entry:SetFont("ax.small")
    self.entry:SetPlaceholderText("Say something...")
    self.entry:SetDrawLanguageID(false)
    self.entry:SetTabbingDisabled(true)
    self.entry.Paint = function(this, width, height)
        this:PaintInternal(width, height)
    end

    bottom:SizeToChildren(false, true)
    bottom:SetTall(self.entry:GetTall())
    bottom.Paint = function(this, width, height)
        ax.render.Draw(0, 0, 0, width, height, Color(0, 0, 0, 100))
    end

    self.entry.OnEnter = function(this)
        local text = this:GetValue()
        if ( #text > 0 ) then
            net.Start("ax.chat.send")
                net.WriteString(text)
            net.SendToServer()

            self.historyCache = self.historyCache or {}
            table.insert(self.historyCache, 1, text)

            if ( #self.historyCache > 128 ) then
                table.remove(self.historyCache, #self.historyCache)
            end

            this:SetText("")

            self.historyIndex = 0
        end

        self:SetVisible(false)
    end

    self.entry.OnChange = function(this)
        self.chatTypePrevious = self.chatType or "ic"
        self.chatType = "ic"

        local text = this:GetValue()
        if ( string.sub(text, 1, 3) == ".//" ) then
            -- Check if it's a way of using local out of character chat using .// prefix
            local data = ax.command:FindClosest("looc")
            if ( data ) then
                ax.chat.currentType = data.displayName
                self.chatTypePrevious = self.chatType or "ic"
                self.chatType = utf8.lower(data.name)
            end
        elseif ( string.sub(text, 1, 1) == "/" ) then
            -- This is a command, so we need to parse it
            local arguments = string.Explode(" ", string.sub(text, 2))
            local command = arguments[1]
            self:PopulateRecommendations(command)

            local data = ax.command:FindClosest(command)
            if ( data ) then
                ax.chat.currentType = data.displayName
                self.chatTypePrevious = self.chatType or "ic"
                self.chatType = utf8.lower(data.name)
                self:SelectRecommendation(data.displayName)
            end
        else
            self:PopulateRecommendations()
        end

        hook.Run("ChatboxOnTextChanged", text, self.chatType)
        hook.Run("ChatboxOnChatTypeChanged", self.chatType, self.chatTypePrevious)
    end

    self.entry.OnKeyCode = function(this, key)
        if ( key == KEY_TAB ) then
            self:CycleRecommendations()
            return true
        end

        -- Navigate history with Up/Down
        if ( key == KEY_UP or key == KEY_DOWN ) then
            self.historyCache = self.historyCache or {}
            if ( #self.historyCache == 0 ) then return end

            this:SetCaretPos(0)
            self.historyIndex = self.historyIndex or 0

            if ( key == KEY_UP ) then
                self.historyIndex = math.min(#self.historyCache, (self.historyIndex or 0) + 1)
            else
                self.historyIndex = math.max(0, (self.historyIndex or 0) - 1)
            end

            if ( self.historyIndex > 0 ) then
                this:SetText(self.historyCache[self.historyIndex])
                this:SetCaretPos(#this:GetText())
            else
                this:SetText("")
            end

            return true
        end
    end

    self.history = self:Add("ax.scroller.vertical")
    self.history:GetVBar():SetWide(0)
    self.history:SetInverted(true)

    self.recommendations = self:Add("ax.scroller.vertical")
    self.recommendations:SetVisible(false)
    self.recommendations:SetAlpha(0)
    self.recommendations:GetVBar():SetWide(0)
    self.recommendations.list = {}
    self.recommendations.panels = {}
    self.recommendations.indexSelect = 0
    self.recommendations.maxSelection = 0
    self.recommendations.Paint = function(this, width, height)
        ax.util:DrawBlur(0, 0, 0, width, height, color_white)
        ax.render.Draw(0, 0, 0, width, height, Color(0, 0, 0, 100))
    end

    -- Resizer handle (corner-based, position-adaptive)
    self.sizer = self:Add("EditablePanel")
    self.sizer:SetSize(self.categories:GetTall(), self.categories:GetTall())
    self.sizer.anchorX = "right"
    self.sizer.anchorY = "top"
    self.sizer:SetCursor("sizenesw")
    self.sizer.Paint = function(this, w, h)
        surface.SetDrawColor(255, 255, 255, 25)
        for i = 0, math.floor(ScreenScale(1)) do
            surface.DrawLine(w - 1 - i * ScreenScale(1), 0, w - 1, i * ScreenScale(1))
        end
    end
    self.sizer.OnMousePressed = function(this, code)
        if ( code == MOUSE_LEFT ) then
            -- Determine which corner the sizer is in at press time
            local sCx = this.x + this:GetWide() / 2
            local sCy = this.y + this:GetTall() / 2
            local pw = self:GetWide()
            local ph = self:GetTall()
            this.anchorX = (sCx > pw / 2) and "right" or "left"
            this.anchorY = (sCy > ph / 2) and "bottom" or "top"

            -- Set cursor based on corner
            local diag = (this.anchorX == "right" and this.anchorY == "bottom") or (this.anchorX == "left" and this.anchorY == "top")
            this:SetCursor(diag and "sizenwse" or "sizenesw")

            -- Cache starting rect in screen space
            local px, py = self:GetPos()
            this.start = {
                left = px,
                top = py,
                right = px + self:GetWide(),
                bottom = py + self:GetTall()
            }
            this.dragging = true
            this:MouseCapture(true)
        end
    end
    self.sizer.OnMouseReleased = function(this)
        if ( this.dragging ) then
            this.dragging = false
            this:MouseCapture(false)

            local w, h = self:GetSize()
            ax.option:Set("chat.width", w)
            ax.option:Set("chat.height", h)
        end
    end
    self.sizer.Think = function(this)
        if ( this.dragging ) then
            local minW, minH = 260, 180
            local mx, my = gui.MouseX(), gui.MouseY()

            local left = this.start.left
            local topY = this.start.top
            local right = this.start.right
            local sBottom = this.start.bottom

            local newX, newY, newW, newH

            -- Horizontal (left/right anchored)
            if ( this.anchorX == "right" ) then
                -- left edge fixed, right follows mouse
                newX = left
                newW = math.Clamp(mx - left, minW, ScrW() - left)
            else
                -- right edge fixed, left follows mouse
                local candidateW = math.Clamp(right - mx, minW, right)
                newX = right - candidateW
                newX = math.Clamp(newX, 0, right - minW)
                newW = right - newX
            end

            -- Vertical (top/bottom anchored)
            if ( this.anchorY == "bottom" ) then
                -- top fixed, bottom follows mouse
                newY = topY
                newH = math.Clamp(my - topY, minH, ScrH() - topY)
            else
                -- bottom fixed, top follows mouse
                local candidateH = math.Clamp(sBottom - my, minH, sBottom)
                newY = sBottom - candidateH
                newY = math.Clamp(newY, 0, sBottom - minH)
                newH = sBottom - newY
            end

            self:SetPos(newX, newY)
            self:SetSize(newW, newH)
            self:InvalidateLayout(true)
        end
    end

    self:SetVisible(false)
    self:InvalidateLayout(true)

    chat.GetChatBoxPos = function()
        return self:GetPos()
    end

    chat.GetChatBoxSize = function()
        return self:GetSize()
    end

    self:PerformLayout(self:GetWide(), self:GetTall())

    -- Register this chatbox as the global instance
    ax.gui.chatbox = self
end

function PANEL:GetChatType()
    return "ic"
end

function PANEL:PopulateRecommendations(text)
    if ( !text ) then
        if ( self.recommendations:GetAlpha() > 0 ) then
            self.recommendations:AlphaTo(0, 0.2, 0, function()
                self.recommendations:Clear()
            end)

            self.recommendations.list = {}
            self.recommendations.panels = {}
            self.recommendations.indexSelect = 0
            self.recommendations.maxSelection = 0
        end

        return
    end

    self.recommendations.list = {}
    self.recommendations.panels = {}

    local matches = {}
    if ( text == "" ) then
        matches = ax.command:GetAll()
    else
        matches = ax.command:FindAll(text)
    end

    for key, command in SortedPairs(matches) do
        self.recommendations.list[#self.recommendations.list + 1] = command
    end

    if ( self.recommendations.list[1] != nil ) then
        self.recommendations:Clear()
        self.recommendations:SetVisible(true)
        self.recommendations:AlphaTo(255, 0.2, 0)

        self.recommendations.panels = {}
        self.recommendations.maxSelection = #self.recommendations.list
        if ( self.recommendations.indexSelect > self.recommendations.maxSelection ) then
            self.recommendations.indexSelect = 1
        end

        for i = 1, #self.recommendations.list do
            local command = self.recommendations.list[i]
            local rec = self.recommendations:Add("DPanel")
            rec:Dock(TOP)
            rec:SetMouseInputEnabled(true)
            rec:SetCursor("hand")
            rec.index = i
            rec.OnMousePressed = function()
                self.recommendations.indexSelect = rec.index

                local data = self.recommendations.list[rec.index]
                if ( !data ) then
                    return
                end

                self.entry:SetText("/" .. data.name)
                self.entry:RequestFocus()
                self.entry:SetCaretPos(2 + #data.name)

                surface.PlaySound("ui/buttonrollover.wav")
            end
            rec.Paint = function(_, width, height)
                if ( self.recommendations.indexSelect == i ) then
                    ax.render.Draw(0, 0, 0, width, height, Color(200, 50, 50, 150))
                end
            end

            local title = rec:Add("ax.text")
            title:Dock(LEFT)
            title:DockMargin(8, 0, 8, 0)
            title:SetFont("ax.small")
            title:SetText(command.displayName, true)

            local descriptionText = command.description
            if ( !descriptionText or descriptionText == "" ) then
                descriptionText = "No description provided."
            end

            local description = rec:Add("ax.text")
            description:Dock(RIGHT)
            description:DockMargin(8, 0, 8, 0)
            description:SetFont("ax.tiny")
            description:SetText(descriptionText, true)

            rec:SetTall(math.max(title:GetTall(), description:GetTall()) + ScreenScale(2))

            self.recommendations.panels[i] = rec
        end
    else
        self.recommendations:AlphaTo(0, 0.2, 0, function()
            self.recommendations:Clear()
            self.recommendations:SetVisible(false)
        end)
    end
end

function PANEL:CycleRecommendations()
    if ( self.recommendations:GetAlpha() < 0 and self.recommendations.maxSelection < 0 ) then
        return
    end

    local recommendations = self.recommendations.list
    if ( #recommendations < 1 ) then
        return
    end

    local index = self.recommendations.indexSelect
    index = index + 1

    if ( index > self.recommendations.maxSelection ) then
        index = 1
    end

    self.recommendations.indexSelect = index

    for i = 1, #self.recommendations.panels do
        local panel = self.recommendations.panels[i]
        panel.index = panel.index or 1
        if ( panel.index == index ) then
            self.recommendations:ScrollToChild(panel)
        end
    end

    local data = recommendations[index]
    if ( !data ) then
        return
    end

    print( data.name )
    self.entry:SetText("/" .. data.name)
    self.entry:RequestFocus()
    self.entry:SetCaretPos(2 + #data.name)

    surface.PlaySound("ui/buttonrollover.wav")
end

function PANEL:SelectRecommendation(identifier)
    local recommendations = self.recommendations.list
    if ( #recommendations < 1 ) then
        return
    end

    for i = 1, #recommendations do
        local command = recommendations[i]
        if ( command.displayName == identifier ) then
            self.recommendations.indexSelect = i

            for j = 1, #self.recommendations.panels do
                local panel = self.recommendations.panels[j]
                panel.index = panel.index or 1
                if ( panel.index == i ) then
                    self.recommendations:ScrollToChild(panel)
                end
            end

            return
        end
    end
end

function PANEL:SetVisible(visible)
    if ( visible ) then
        input.SetCursorPos(self:LocalToScreen(self:GetWide() / 2, self:GetTall() / 2))

        self:SetAlpha(255)
        self:MakePopup()
        self.entry:RequestFocus()
        self.entry:SetVisible(true)
    else
        self:SetAlpha(0)
        self:SetMouseInputEnabled(false)
        self:SetKeyboardInputEnabled(false)

        -- Suppress OnChange callback while clearing text to prevent network spam
        self.suppressOnChange = true
        self.entry:SetText("")
        self.entry:SetCaretPos(0)
        self.suppressOnChange = false

        self.entry:SetVisible(false)

        -- Only send network update when closing the chatbox
        hook.Run("ChatboxOnTextChanged", "", "IC")
    end

    self:PopulateRecommendations()
end

function PANEL:Think()
    if ( input.IsKeyDown(KEY_ESCAPE) and self:IsVisible() ) then
        self:SetVisible(false)
    end
end

function PANEL:OnKeyCodePressed(key)
    if ( !self:IsVisible() ) then return end

    if ( key != KEY_TAB ) then
        return
    end

    self:CycleRecommendations()
end

function PANEL:Paint(width, height)
    ax.util:DrawBlur(0, 0, 0, width, height, color_white)
    ax.render.Draw(0, 0, 0, width, height, Color(0, 0, 0, 50))
end

function PANEL:PerformLayout(width, height)
    -- Recompute dynamic layout on size changes
    if ( IsValid(self.categories) and IsValid(self.entry) and IsValid(self.history) ) then
        self.history:SetSize(width, height - self.categories:GetTall() - self.entry:GetTall() - ScreenScale(8))
        self.history:SetPos(ScreenScale(2), self.categories:GetTall() + ScreenScale(2))
    end

    if ( IsValid(self.recommendations) and IsValid(self.history) ) then
        self.recommendations:SetSize(width - ScreenScale(4), height - self.categories:GetTall() - self.entry:GetTall() - ScreenScale(8))
        self.recommendations:SetPos(ScreenScale(2), self.categories:GetTall() + ScreenScale(2))
    end

    if ( IsValid(self.sizer) ) then
        -- Keep sizer sized like the top bar for a clean look
        local sz = IsValid(self.categories) and self.categories:GetTall() or self.sizer:GetTall()
        self.sizer:SetSize(sz, sz)

        local x = (self.sizer.anchorX == "right") and (self:GetWide() - self.sizer:GetWide()) or 0
        local y = (self.sizer.anchorY == "bottom") and (self:GetTall() - self.sizer:GetTall()) or 0
        self.sizer:SetPos(x, y)

        local diag = (self.sizer.anchorX == "right" and self.sizer.anchorY == "bottom") or (self.sizer.anchorX == "left" and self.sizer.anchorY == "top")
        self.sizer:SetCursor(diag and "sizenwse" or "sizenesw")
    end
end

vgui.Register("ax.chatbox", PANEL, "EditablePanel")

-- If any existing chatbox instance exists, remove it and create a new one
if ( IsValid(ax.gui.chatbox) ) then
    ax.gui.chatbox:Remove()

    -- Create a new chatbox instance
    vgui.Create("ax.chatbox")
end
