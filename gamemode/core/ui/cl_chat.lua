local PANEL = {}

DEFINE_BASECLASS("EditablePanel")

function PANEL:Init()
    if ( IsValid(ax.gui.chatbox) ) then
        ax.gui.chatbox:Remove()
    end

    ax.gui.chatbox = self

    self:SetSize(hook.Run("GetChatboxSize"))
    self:SetPos(hook.Run("GetChatboxPos"))

    local label = self:Add("ax.text")
    label:Dock(TOP)
    label:SetTextInset(8, -2)
    label:SetFont("parallax.small")
    label:SetText(GetHostName(), true)
    label.Paint = function(this, width, height)
        surface.SetDrawColor(ax.color:Get("background.transparent"))
        surface.DrawRect(0, 0, width, height)
    end

    local bottom = self:Add("EditablePanel")
    bottom:Dock(BOTTOM)
    bottom:DockMargin(8, 8, 8, 8)

    self.chatType = bottom:Add("ax.text.typewriter")
    self.chatType:Dock(LEFT)
    self.chatType:SetTextInset(8, -2)
    self.chatType:SetFont("parallax.small")
    self.chatType:SetText("IC", true, true)
    self.chatType:SetTypingSpeed(0.05)
    self.chatType.PostThink = function(this)
        this:SetWide(ax.util:GetTextWidth(this:GetFont(), this:GetText()) + 16)
    end
    self.chatType.Paint = function(this, width, height)
        surface.SetDrawColor(ax.color:Get("background.transparent"))
        surface.DrawRect(0, 0, width, height)
    end

    self.entry = bottom:Add("ax.text.entry")
    self.entry:Dock(FILL)
    self.entry:DockMargin(8, 0, 0, 0)
    self.entry:SetPlaceholderText("Say something...")
    self.entry:SetDrawLanguageID(false)
    self.entry:SetTabbingDisabled(true)

    bottom:SizeToChildren(false, true)

    self.entry.OnEnter = function(this)
        local text = this:GetValue()
        if ( #text > 0 ) then
            RunConsoleCommand("say", text)
            this:SetText("")
        end

        self:SetVisible(false)
    end

    self.entry.OnTextChanged = function(this)
        local chatType = "IC"
        local text = this:GetValue()
        if ( string.sub(text, 1, 3) == ".//" ) then
            -- Check if it's a way of using local out of character chat using .// prefix
            local data = ax.command:Get("looc")
            if ( data ) then
                chatType = string.upper(data.UniqueID)
            end
        elseif ( string.sub(text, 1, 1) == "/" ) then
            -- This is a command, so we need to parse it
            local arguments = string.Explode(" ", string.sub(text, 2))
            local command = arguments[1]
            local data = ax.command:Get(command)
            if ( data ) then
                chatType = string.upper(data.UniqueID)
            end

            self:PopulateRecommendations(command)
        else
            self:PopulateRecommendations()
        end

        -- Prevent the chat type from being set to the same value
        if ( ax.util:FindString(self.chatType:GetText(), chatType) ) then
            return
        end

        self.chatType:SetText(chatType, true, true)
        self.chatType:RestartTyping()
    end

    self.entry.OnKeyCode = function(this, key)
        if ( key == KEY_TAB ) then
            self:CycleRecommendations()
            return true
        end
    end

    self.history = self:Add("DScrollPanel")
    self.history:SetSize(self:GetWide() - 16, self:GetTall() - 16 - label:GetTall() - self.entry:GetTall())
    self.history:SetPos(8, label:GetTall() + 8)
    self.history:GetVBar():SetWide(0)

    self.recommendations = self:Add("ax.scroller.vertical")
    self.recommendations:SetSize(self.history:GetWide(), self.history:GetTall() - 8)
    self.recommendations:SetPos(8, self.history:GetY() + self.history:GetTall() - self.recommendations:GetTall() - 8)
    self.recommendations:SetAlpha(0)
    self.recommendations:GetVBar():SetWide(0)
    self.recommendations.list = {}
    self.recommendations.panels = {}
    self.recommendations.indexSelect = 0
    self.recommendations.maxSelection = 0
    self.recommendations.Paint = function(this, width, height)
        ax.util:DrawBlur(this)

        surface.SetDrawColor(ax.color:Get("background.transparent"))
        surface.DrawRect(0, 0, width, height)
    end

    self:SetVisible(false)

    chat.GetChatBoxPos = function()
        return self:GetPos()
    end

    chat.GetChatBoxSize = function()
        return self:GetSize()
    end
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
            table.insert(self.recommendations.list, command)
        end
    end

    if ( #self.recommendations.list > 0 ) then
        self.recommendations:Clear()
        self.recommendations:AlphaTo(255, 0.2, 0)

        self.recommendations.panels = {}
        self.recommendations.maxSelection = #self.recommendations.list
        if ( self.recommendations.indexSelect > self.recommendations.maxSelection ) then
            self.recommendations.indexSelect = 1
        end

        for index, command in ipairs(self.recommendations.list) do
            local rec = self.recommendations:Add("DPanel")
            rec:Dock(TOP)
            rec:DockMargin(4, 4, 4, 0)
            rec.index = index
            rec.Paint = function(_, width, height)
                surface.SetDrawColor(ax.color:Get("background.transparent"))
                surface.DrawRect(0, 0, width, height)

                if ( self.recommendations.indexSelect == index ) then
                    surface.SetDrawColor(ax.config:Get("color.schema"))
                    surface.DrawRect(0, 0, width, height)
                end
            end

            local height = 0

            local title = rec:Add("ax.text")
            title:Dock(TOP)
            title:DockMargin(8, 0, 8, 0)
            title:SetFont("parallax.small")
            title:SetText(command.UniqueID, true)
            height = height + title:GetTall()

            local descriptionWrapped = command.Description
            if ( !descriptionWrapped or descriptionWrapped == "" ) then
                descriptionWrapped = "No description provided."
            end

            descriptionWrapped = ax.util:GetWrappedText(descriptionWrapped, "parallax.tiny", self.recommendations:GetWide() - 16)
            for k, v in ipairs(descriptionWrapped) do
                local descLine = rec:Add("ax.text")
                descLine:Dock(TOP)
                descLine:DockMargin(8, -2, 8, 0)
                descLine:SetFont("parallax.tiny")
                descLine:SetText(v, true)
                descLine:SetTextColor(ax.color:Get("text"))
                height = height + descLine:GetTall()
            end

            rec:SetTall(height)

            self.recommendations.panels[index] = rec
        end
    else
        self.recommendations:AlphaTo(0, 0.2, 0, function()
            self.recommendations:Clear()
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

    for _, panel in ipairs(self.recommendations.panels) do
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

    if ( key != KEY_TAB ) then
        return
    end

    self:CycleRecommendations()
end

function PANEL:Paint(width, height)
    ax.util:DrawBlur(self)

    surface.SetDrawColor(ax.color:Get("background.transparent"))
    surface.DrawRect(0, 0, width, height)
end

vgui.Register("ax.chatbox", PANEL, "EditablePanel")

if ( IsValid(ax.gui.chatbox) ) then
    ax.gui.chatbox:Remove()

    vgui.Create("ax.chatbox")
end