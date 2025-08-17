local PANEL = {}

DEFINE_BASECLASS("EditablePanel")

function PANEL:Init()
    if ( IsValid(ax.gui.chatbox) ) then
        ax.gui.chatbox:Remove()
    end

    ax.gui.chatbox = self

    -- Base/default size
    self:SetSize(hook.Run("GetChatboxSize"))

    -- Restore saved size if available
    local sw = tonumber(cookie.GetString("ax.chatbox.w") or "")
    local sh = tonumber(cookie.GetString("ax.chatbox.h") or "")
    if ( sw and sh ) then
        local minW, minH = 260, 180
        local maxW, maxH = ScrW(), ScrH()
        self:SetSize(math.Clamp(sw, minW, maxW), math.Clamp(sh, minH, maxH))
    end

    -- Try to restore last saved position if available, otherwise use hook default
    local cx = tonumber(cookie.GetString("ax.chatbox.x") or "")
    local cy = tonumber(cookie.GetString("ax.chatbox.y") or "")
    if ( cx and cy ) then
        local maxX = math.max(0, ScrW() - self:GetWide())
        local maxY = math.max(0, ScrH() - self:GetTall())
        self:SetPos(math.Clamp(cx, 0, maxX), math.Clamp(cy, 0, maxY))
    else
        self:SetPos(hook.Run("GetChatboxPos"))
    end

    self.top = self:Add("ax.text")
    self.top:Dock(TOP)
    self.top:SetTextInset(8, 0)
    self.top:SetFont("ax.chatbox.text")
    self.top:SetText(GetHostName(), true)
    self.top.Paint = function(this, width, height)
        surface.SetDrawColor(0, 0, 0, 100)
        surface.DrawRect(0, 0, width, height)
    end

    -- Enable dragging the chatbox by grabbing the top bar
    self.top:SetMouseInputEnabled(true)
    self.top:SetCursor("sizeall")
    self.top.OnMousePressed = function(this, code)
        if ( code == MOUSE_LEFT ) then
            local px, py = self:GetPos()
            this.dragOffsetX = gui.MouseX() - px
            this.dragOffsetY = gui.MouseY() - py
            this.dragging = true
            this:MouseCapture(true)
        elseif ( code == MOUSE_RIGHT ) then
            local menu = DermaMenu()
            menu:AddOption("Reset Position", function()
                local rx, ry = hook.Run("GetChatboxPos")
                self:SetPos(rx, ry)

                cookie.Set("ax.chatbox.x", tostring(rx))
                cookie.Set("ax.chatbox.y", tostring(ry))
            end)
            menu:AddOption("Reset Size", function()
                local rw, rh = hook.Run("GetChatboxSize")
                self:SetSize(rw, rh)
                cookie.Set("ax.chatbox.w", tostring(rw))
                cookie.Set("ax.chatbox.h", tostring(rh))
                self:InvalidateLayout(true)
            end)
            menu:Open()
        end
    end
    self.top.OnMouseReleased = function(this, code)
        if ( this.dragging ) then
            this.dragging = false
            this:MouseCapture(false)

            -- Persist new position
            local x, y = self:GetPos()
            cookie.Set("ax.chatbox.x", tostring(x))
            cookie.Set("ax.chatbox.y", tostring(y))
        end
    end
    self.top.Think = function(this)
        if ( this.dragging ) then
            local mx, my = gui.MouseX(), gui.MouseY()
            local nx = mx - (this.dragOffsetX or 0)
            local ny = my - (this.dragOffsetY or 0)

            local maxX = math.max(0, ScrW() - self:GetWide())
            local maxY = math.max(0, ScrH() - self:GetTall())
            self:SetPos(math.Clamp(nx, 0, maxX), math.Clamp(ny, 0, maxY))
        end
    end

    local bottom = self:Add("EditablePanel")
    bottom:Dock(BOTTOM)
    bottom:DockMargin(8, 8, 8, 8)

    self.chatType = bottom:Add("ax.text.typewriter")
    self.chatType:Dock(LEFT)
    self.chatType:SetTextInset(8, 0)
    self.chatType:SetFont("ax.chatbox.text")
    self.chatType:SetText("IC", true, true)
    self.chatType:SetTypingSpeed(0.05)
    self.chatType.PostThink = function(this)
        this:SetWide(ax.util:GetTextWidth(this:GetFont(), this:GetText()) + 16)
    end
    self.chatType.Paint = function(this, width, height)
        surface.SetDrawColor(0, 0, 0, 100)
        surface.DrawRect(0, 0, width, height)
    end

    self.entry = bottom:Add("ax.text.entry")
    self.entry:Dock(FILL)
    self.entry:DockMargin(8, 0, 0, 0)
    self.entry:SetFont("ax.chatbox.text")
    self.entry:SetPlaceholderText("Say something...")
    self.entry:SetDrawLanguageID(false)
    self.entry:SetTabbingDisabled(true)

    bottom:SizeToChildren(false, true)
    bottom:SetTall(self.entry:GetTall() / 1.5)

    self.entry.OnEnter = function(this)
        local text = this:GetValue()
        if ( #text > 0 ) then
            net.Start("ax.chatbox.send")
                net.WriteString(text)
            net.SendToServer()

            this:SetText("")
        end

        self:SetVisible(false)
    end

    self.entry.OnChange = function(this)
        local chatType = "IC"
        local text = this:GetValue()
        if ( string.sub(text, 1, 3) == ".//" ) then
            -- Check if it's a way of using local out of character chat using .// prefix
            local data = ax.command:Get("looc")
            if ( data ) then
                ax.chat.currentType = data.UniqueID
                chatType = string.upper(data.UniqueID)
            end
        elseif ( string.sub(text, 1, 1) == "/" ) then
            -- This is a command, so we need to parse it
            local arguments = string.Explode(" ", string.sub(text, 2))
            local command = arguments[1]
            local data = ax.command:Get(command)
            if ( data ) then
                ax.chat.currentType = data.UniqueID
                chatType = string.upper(data.UniqueID)
            end

            self:PopulateRecommendations(command)
        else
            self:PopulateRecommendations()
        end

        hook.Run("ChatboxOnTextChanged", text, chatType)

        -- Prevent the chat type from being set to the same value
        if ( ax.util:FindString(self.chatType.fullText, chatType) ) then
            return
        end

        self.chatType.previousChatType = chatType or self.chatType.previousChatType or "IC"
        self.chatType:SetText(chatType, true, true)
        self.chatType:RestartTyping()

        hook.Run("ChatboxOnChatTypeChanged", chatType, self.chatType.previousChatType)
    end

    self.entry.OnKeyCode = function(this, key)
        if ( key == KEY_TAB ) then
            self:CycleRecommendations()
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
        ax.util:DrawPanelBlur(this)

        surface.SetDrawColor(0, 0, 0, 100)
        surface.DrawRect(0, 0, width, height)
    end

    -- Resizer handle (corner-based, position-adaptive)
    self.sizer = self:Add("DPanel")
    self.sizer:SetSize(self.top:GetTall(), self.top:GetTall())
    self.sizer.anchorX = "right"
    self.sizer.anchorY = "top"
    self.sizer:SetCursor("sizenesw")
    self.sizer.Paint = function(this, w, h)
        surface.SetDrawColor(255, 255, 255, 25)
        -- simple corner grip
        for i = 0, 2 do
            surface.DrawLine(w - 1 - i * 4, h - 1, w - 1, h - 1 - i * 4)
        end
    end
    self.sizer.OnMousePressed = function(this, code)
        if ( code == MOUSE_LEFT ) then
            -- Determine which corner the sizer is in at press time
            local sCx = this.x + this:GetWide() * 0.5
            local sCy = this.y + this:GetTall() * 0.5
            local pw = self:GetWide()
            local ph = self:GetTall()
            this.anchorX = (sCx > pw * 0.5) and "right" or "left"
            this.anchorY = (sCy > ph * 0.5) and "bottom" or "top"

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
            cookie.Set("ax.chatbox.w", tostring(w))
            cookie.Set("ax.chatbox.h", tostring(h))
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

    self:PerformLayout()
end

function PANEL:GetChatType()
    return self.chatType.previousChatType or "IC"
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

    for key, command in SortedPairsByMemberValue(ax.command:GetAll(), "UniqueID") do
        if ( ax.util:FindString(command.UniqueID, text, true) or ( command.Prefixes and ax.util:FindInTable(command.Prefixes, text, true) ) ) then
            self.recommendations.list[#self.recommendations.list + 1] = command
        end
    end

    if ( self.recommendations.list[1] ~= nil ) then
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
            rec:DockMargin(4, 4, 4, 0)
            rec.index = i
            rec.Paint = function(_, width, height)
                surface.SetDrawColor(0, 0, 0, 100)
                surface.DrawRect(0, 0, width, height)

                if ( self.recommendations.indexSelect == i ) then
                    surface.SetDrawColor(ax.config:Get("color.schema"))
                    surface.DrawRect(0, 0, width, height)
                end
            end

            local height = 0

            local title = rec:Add("ax.text")
            title:Dock(TOP)
            title:DockMargin(8, 0, 8, 0)
            title:SetFont("ax.chatbox.text")
            title:SetText(command.UniqueID, true)
            height = height + title:GetTall()

            local descriptionWrapped = command.Description
            if ( !descriptionWrapped or descriptionWrapped == "" ) then
                descriptionWrapped = "No description provided."
            end

            descriptionWrapped = ax.util:GetWrappedText(descriptionWrapped, "ax.tiny", self.recommendations:GetWide() - 16)
            for k = 1, #descriptionWrapped do
                local v = descriptionWrapped[k]
                local descLine = rec:Add("ax.text")
                descLine:Dock(TOP)
                descLine:DockMargin(8, -2, 8, 0)
                descLine:SetFont("ax.tiny")
                descLine:SetText(v, true)
                descLine:SetTextColor(255, 255, 255)
                height = height + descLine:GetTall()
            end

            rec:SetTall(height)

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

    self.entry:SetText("/" .. data.UniqueID)
    self.entry:RequestFocus()
    self.entry:SetCaretPos(2 + #data.UniqueID)

    self.chatType:SetText(data.UniqueID, true, true)
    self.chatType:RestartTyping()

    surface.PlaySound("ax.button.enter")
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
        self.entry:SetText("")
        self.entry:SetCaretPos(0)
        self.entry:SetVisible(false)
        self.chatType:SetText("IC", true, true)
        self.chatType:RestartTyping()
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

    if ( key ~= KEY_TAB ) then
        return
    end

    self:CycleRecommendations()
end

function PANEL:Paint(width, height)
    ax.util:DrawPanelBlur(self)

    surface.SetDrawColor(0, 0, 0, 100)
    surface.DrawRect(0, 0, width, height)
end

function PANEL:PerformLayout(width, height)
    -- Recompute dynamic layout on size changes
    if ( IsValid(self.top) and IsValid(self.entry) and IsValid(self.history) ) then
        local w, h = self:GetSize()
        local histW = w - 16
        local histH = h - 24 - self.top:GetTall() - self.entry:GetTall()
        self.history:SetSize(math.max(0, histW), math.max(0, histH))
        self.history:SetPos(8, self.top:GetTall() + 8)
    end

    if ( IsValid(self.recommendations) and IsValid(self.history) ) then
        local rw = self.history:GetWide()
        local rh = math.max(0, self.history:GetTall() - 8)
        self.recommendations:SetSize(rw, rh)
        self.recommendations:SetPos(8, self.history:GetY() + self.history:GetTall() - self.recommendations:GetTall() - 8)
    end

    if ( IsValid(self.sizer) ) then
        -- Keep sizer sized like the top bar for a clean look
        local sz = IsValid(self.top) and self.top:GetTall() or self.sizer:GetTall()
        self.sizer:SetSize(sz, sz)

        local x = (self.sizer.anchorX == "right") and (self:GetWide() - self.sizer:GetWide()) or 0
        local y = (self.sizer.anchorY == "bottom") and (self:GetTall() - self.sizer:GetTall()) or 0
        self.sizer:SetPos(x, y)

        local diag = (self.sizer.anchorX == "right" and self.sizer.anchorY == "bottom") or (self.sizer.anchorX == "left" and self.sizer.anchorY == "top")
        self.sizer:SetCursor(diag and "sizenwse" or "sizenesw")
    end
end

vgui.Register("ax.chatbox", PANEL, "EditablePanel")

if ( IsValid(ax.gui.chatbox) ) then
    ax.gui.chatbox:Remove()

    vgui.Create("ax.chatbox")
end