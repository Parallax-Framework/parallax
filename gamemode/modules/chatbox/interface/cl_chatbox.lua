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

AccessorFunc(PANEL, "m_bIsMenuComponent", "IsMenu", FORCE_BOOL)
AccessorFunc(PANEL, "m_bDraggable", "Draggable", FORCE_BOOL)
AccessorFunc(PANEL, "m_bSizable", "Sizable", FORCE_BOOL)
AccessorFunc(PANEL, "m_bScreenLock", "ScreenLock", FORCE_BOOL)
AccessorFunc(PANEL, "m_iMinWidth", "MinWidth", FORCE_NUMBER)
AccessorFunc(PANEL, "m_iMinHeight", "MinHeight", FORCE_NUMBER)

function PANEL:Init()
    -- Remove any existing chatbox instance before creating a new one
    if ( IsValid(ax.gui.chatbox) ) then
        ax.gui.chatbox:Remove()
    end

    self.chatType = "ic"
    self.chatTypePrevious = "ic"

    self:SetFocusTopLevel(true)

    self:SetSize(hook.Run("GetChatboxSize"))
    self:SetPos(hook.Run("GetChatboxPos"))

    self:SetDraggable(true)
    self:SetSizable(true)
    self:SetScreenLock(true)

    self:SetMinWidth(ax.util:ScreenScale(225) / 3)
    self:SetMinHeight(ax.util:ScreenScaleH(150) / 3)

    self.bottom = self:Add("DPanel")
    self.bottom:Dock(BOTTOM)
    self.bottom:DockMargin(ScreenScale(2), ScreenScale(2), ScreenScale(2), ScreenScale(2))
    self.bottom.Paint = function(this, width, height)
        ax.render.Draw(0, 0, 0, width, height, Color(0, 0, 0, 100))
    end

    self.entry = self.bottom:Add("ax.text.entry")
    self.entry:Dock(FILL)
    self.entry:SetFont("ax.tiny")
    self.entry:SetPlaceholderText("Say something...")
    self.entry:SetDrawLanguageID(false)
    self.entry:SetTabbingDisabled(true)
    self.entry.Paint = function(this, width, height)
        this:PaintInternal(width, height)
    end

    self.bottom:SetTall(ScreenScale(8))

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

            -- Populate voice recommendations for the text after the .// prefix
            local voiceText = string.sub(text, 4)
            if ( voiceText and #voiceText > 0 ) then
                self:PopulateRecommendations(voiceText, "voices")
            else
                self:PopulateRecommendations()
            end
        elseif ( string.sub(text, 1, 1) == "/" ) then
            -- This is a command, so we need to parse it
            local arguments = string.Explode(" ", string.sub(text, 2))
            local command = arguments[1]
            self:PopulateRecommendations(command, "commands")

            local data = ax.command:FindClosest(command)
            if ( data ) then
                ax.chat.currentType = data.displayName
                self.chatTypePrevious = self.chatType or "ic"
                self.chatType = utf8.lower(data.name)
                self:SelectRecommendation(data.displayName)

                -- Populate voice recommendations for arguments after the command
                if ( #arguments > 1 ) then
                    local argumentText = table.concat(arguments, " ", 2)
                    self:PopulateRecommendations(argumentText, "voices")
                end
            end
        else
            -- Check if text ends with a space followed by optional text (i.e. a voice line was selected and space was added)
            local lastSpacePos = string.find(text, " ", 1, true)
            if ( lastSpacePos ) then
                -- Get text after the last space for voice recommendations
                local voiceText = string.sub(text, lastSpacePos + 1)
                if ( voiceText and #voiceText > 0 ) then
                    self:PopulateRecommendations(voiceText, "voices")
                else
                    -- Just a space, show all available voice lines
                    self:PopulateRecommendations("", "voices")
                end
            else
                -- No space yet, populate based on full text
                self:PopulateRecommendations(text, "voices")
            end
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
    self.history:SetMouseInputEnabled(false)

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

function PANEL:PopulateRecommendations(text, recommendationType)
    if ( !text ) then
        if ( IsValid(self.recommendations) and self.recommendations:GetAlpha() > 0 ) then
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

    if ( recommendationType == "commands" ) then
        if ( text == "" ) then
            matches = ax.command:GetAll()
        else
            matches = ax.command:FindAll(text)
        end

        for key, command in SortedPairs(matches) do
            self.recommendations.list[#self.recommendations.list + 1] = command
        end
    elseif ( recommendationType == "voices" ) then
        -- Get available voice classes for the current player
        if ( ax.voices and ax.voices.GetClass ) then
            local voiceClasses = ax.voices:GetClass(ax.client, self.chatType)
            for _, voiceClass in ipairs(voiceClasses) do
                if ( !ax.voices.stored[voiceClass] ) then
                    ax.util:PrintDebug("Voice class \"" .. tostring(voiceClass) .. "\" has no stored voice lines!\n")
                    continue
                end

                for voiceKey, voiceData in pairs(ax.voices.stored[voiceClass]) do
                    if ( ax.util:FindText(utf8.lower(voiceKey), utf8.lower(text)) == false and
                         ax.util:FindText(utf8.lower(voiceData.text or ""), utf8.lower(text)) == false ) then
                        continue
                    end

                    self.recommendations.list[#self.recommendations.list + 1] = {
                        name = voiceKey,
                        displayName = voiceKey,
                        description = voiceData.text,
                        isVoice = true
                    }

                    if ( #self.recommendations.list >= 20 ) then
                        break
                    end
                end
            end
        else
            ax.util:PrintWarning("Attempted to populate voice line recommendations, but voice module is not loaded!")
        end
    end

    if ( self.recommendations.list[1] != nil ) then
        self.recommendations:Clear()
        self.recommendations:SetVisible(true)
        self.recommendations:AlphaTo(255, 0.2, 0)

        self.recommendations.panels = {}
        self.recommendations.maxSelection = #self.recommendations.list
        if ( self.recommendations.indexSelect > self.recommendations.maxSelection ) then
            self.recommendations.indexSelect = 0
        end

        for i = 1, #self.recommendations.list do
            local item = self.recommendations.list[i]
            local rec = self.recommendations:Add("DPanel")
            rec:Dock(TOP)
            rec:SetMouseInputEnabled(true)
            rec:SetCursor("hand")
            rec.index = i
            rec.isVoice = item.isVoice or false
            rec.OnMousePressed = function()
                self.recommendations.indexSelect = rec.index

                local data = self.recommendations.list[rec.index]
                if ( !data ) then
                    return
                end

                if ( rec.isVoice ) then
                    self.entry:SetText(data.name)
                else
                    self.entry:SetText("/" .. data.name)
                end

                self.entry:RequestFocus()
                self.entry:SetCaretPos(#self.entry:GetText())

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
            title:SetFont("ax.tiny")
            title:SetText(item.displayName, true)

            local descriptionText = item.description
            if ( !descriptionText or descriptionText == "" ) then
                descriptionText = "No description provided."
            end

            local description = rec:Add("ax.text")
            description:Dock(RIGHT)
            description:DockMargin(8, 0, 8, 0)
            description:SetFont("ax.tiny")
            description:SetText(descriptionText, true)
            description:SetTextColor(Color(255, 255, 255, 150))

            rec:SetTall(math.max(title:GetTall(), description:GetTall()) + ScreenScale(1))

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
    if ( #recommendations < 1 ) then return end

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

    if ( data.isVoice ) then
        self.entry:SetText(data.name)
    else
        self.entry:SetText("/" .. data.name)
    end

    self.entry:RequestFocus()
    self.entry:SetCaretPos(#self.entry:GetText())

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

    local mousex = math.Clamp(gui.MouseX(), 1, ScrW() - 1)
    local mousey = math.Clamp(gui.MouseY(), 1, ScrH() - 1)

    if ( self.Dragging ) then
        local x = mousex - self.Dragging[1]
        local y = mousey - self.Dragging[2]

        -- Lock to screen bounds if screenlock is enabled
        if ( self:GetScreenLock() ) then
            x = math.Clamp(x, 0, ScrW() - self:GetWide())
            y = math.Clamp(y, 0, ScrH() - self:GetTall())
        end

        self:SetPos(x, y)

        ax.option:Set("chat.x", x, false, true)
        ax.option:Set("chat.y", y, false, true)
    end

    if ( self.Sizing ) then
        local x = mousex - self.Sizing[1]
        local y = mousey - self.Sizing[2]
        local px, py = self:GetPos()

        if ( x < self.m_iMinWidth ) then x = self.m_iMinWidth elseif ( x > ScrW() - px and self:GetScreenLock() ) then x = ScrW() - px end
        if ( y < self.m_iMinHeight ) then y = self.m_iMinHeight elseif ( y > ScrH() - py and self:GetScreenLock() ) then y = ScrH() - py end

        self:SetSize(x, y)
        ax.option:Set("chat.width", x, false, true)
        ax.option:Set("chat.height", y, false, true)
        self:SetCursor("sizenwse")
        return
    end

    local screenX, screenY = self:LocalToScreen( 0, 0 )
    if ( self.Hovered and self.m_bSizable and mousex > ( screenX + self:GetWide() - 20 ) and mousey > ( screenY + self:GetTall() - 20 ) ) then
        self:SetCursor("sizenwse")
        return
    end

    if ( self.Hovered and self:GetDraggable() and mousey < ( screenY + 24 ) ) then
        self:SetCursor("sizeall")
        return
    end

    self:SetCursor("arrow")

    -- Don't allow the frame to go higher than 0
    if ( self.y < 0 ) then
        self:SetPos(self.x, 0)
    end
end

function PANEL:OnKeyCodePressed(key)
    if ( !self:IsVisible() ) then return end

    if ( key != KEY_TAB ) then
        return
    end

    self:CycleRecommendations()
end

function PANEL:OnMousePressed(mouseCode)
    if ( mouseCode == MOUSE_RIGHT ) then
        local menu = DermaMenu(false, self)
        menu:AddOption("Close Chat", function()
            self:SetVisible(false)
        end)

        menu:AddOption("Clear Chat History", function()
            self.history:Clear()
        end)

        menu:AddSpacer()

        menu:AddOption("Reset Position", function()
            local x, y = ax.option:GetDefault("chat.x"), ax.option:GetDefault("chat.y")

            self:SetPos(x, y)

            ax.option:SetToDefault("chat.x")
            ax.option:SetToDefault("chat.y")
        end)

        menu:AddOption("Reset Size", function()
            local width, height = ax.option:GetDefault("chat.width"), ax.option:GetDefault("chat.height")

            self:SetSize(width, height)

            ax.option:SetToDefault("chat.width")
            ax.option:SetToDefault("chat.height")
        end)

        menu:Open()
        return
    end

    local screenX, screenY = self:LocalToScreen(0, 0)
    if ( self.m_bSizable and gui.MouseX() > ( screenX + self:GetWide() - 20 ) and gui.MouseY() > ( screenY + self:GetTall() - 20 ) ) then
        self.Sizing = {gui.MouseX() - self:GetWide(), gui.MouseY() - self:GetTall()}
        self:MouseCapture(true)
        return
    end

    if ( self:GetDraggable() and gui.MouseY() < ( screenY + 24 ) ) then
        self.Dragging = {gui.MouseX() - self.x, gui.MouseY() - self.y}
        self:MouseCapture(true)
        return
    end

    self.entry:RequestFocus()
end

function PANEL:OnMouseReleased()
    self.Dragging = nil
    self.Sizing = nil
    self:MouseCapture(false)
end

function PANEL:Paint(width, height)
    ax.util:DrawBlur(0, 0, 0, width, height, color_white)

    ax.render.Draw(0, 0, 0, width, height, Color(50, 50, 50, 100))
    ax.render.DrawMaterial(0, 0, 0, width, height, Color(0, 0, 0, 200), ax.util:GetMaterial("parallax/overlays/vignette.png"))
end

function PANEL:PerformLayout(width, height)
    if ( IsValid(self.bottom) and IsValid(self.history) ) then
        self.history:SetSize(width - ScreenScale(4), height - self.bottom:GetTall() - ScreenScale(4) - ScreenScale(2))
        self.history:SetPos(ScreenScale(2), ScreenScale(2))
    end

    if ( IsValid(self.recommendations) and IsValid(self.history) ) then
        self.recommendations:SetSize(width - ScreenScale(4), height / 2 - self.bottom:GetTall() - ScreenScale(8))
        self.recommendations:SetPos(ScreenScale(2), ScreenScale(2))
    end
end

vgui.Register("ax.chatbox", PANEL, "EditablePanel")

-- If any existing chatbox instance exists, remove it and create a new one
if ( IsValid(ax.gui.chatbox) ) then
    ax.gui.chatbox:Remove()

    -- Create a new chatbox instance
    vgui.Create("ax.chatbox")
end
