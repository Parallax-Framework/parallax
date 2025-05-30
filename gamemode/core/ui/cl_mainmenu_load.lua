local padding = ScreenScale(32)
local smallPadding = ScreenScale(16) -- not used
local tinyPadding = ScreenScale(8)

DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:SetVisible(false)
end

function PANEL:Populate()
    local client = ax.client
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

    local title = self:Add("ax.text")
    title:Dock(TOP)
    title:DockMargin(padding, padding, 0, 0)
    title:SetFont("parallax.title")
    title:SetText(string.upper("mainmenu.select.character"))

    local navigation = self:Add("EditablePanel")
    navigation:Dock(BOTTOM)
    navigation:DockMargin(padding, 0, padding, padding)
    navigation:SetTall(ScreenScale(24))

    local backButton = navigation:Add("ax.button.small")
    backButton:Dock(LEFT)
    backButton:SetText("BACK")
    backButton.DoClick = function()
        self:Clear()
        self:SetVisible(false)
        parent:Populate()
    end

    local characterList = self:Add("ax.scroller.vertical")
    characterList:Dock(FILL)
    characterList:DockMargin(padding * 4, padding, padding * 4, padding)
    characterList:InvalidateParent(true)
    characterList:GetVBar():SetWide(0)
    characterList.Paint = nil

    local clientTable = client:GetTable()
    for k, v in pairs(clientTable.axCharacters) do
        local button = characterList:Add("ax.button.small")
        button:Dock(TOP)
        button:DockMargin(0, 0, 0, 16)
        button:SetText("", true, true, true)
        button:SetTall(characterList:GetWide() / 8)

        button.DoClick = function()
            ax.net:Start("character.load", v:GetID())
        end

        local image = button:Add("DImage")
        image:Dock(LEFT)
        image:DockMargin(0, 0, tinyPadding, 0)
        image:SetSize(button:GetTall() * 1.75, button:GetTall())
        image:SetImage(v.Image or "gamepadui/hl2/chapter14")

        local deleteButton = button:Add("ax.button.small")
        deleteButton:Dock(RIGHT)
        deleteButton:DockMargin(tinyPadding, 0, 0, 0)
        deleteButton.baseTextColor = ax.color:Get("error")
        deleteButton.baseTextColorTarget = ax.color:Get("black")
        deleteButton.backgroundColor = ax.color:Get("error")
        deleteButton:SetText("X")
        deleteButton:SetWide(button:GetTall())
        deleteButton:SetTall(button:GetTall())
        deleteButton:SetContentAlignment(5)
        deleteButton.DoClick = function()
            self:PopulateDelete(v:GetID())
        end

        local name = button:Add("ax.text")
        name:Dock(TOP)
        name:SetFont("parallax.title")
        name:SetText(v:GetName():upper())
        name.Think = function(this)
            this:SetTextColor(button:GetTextColor())
        end

        -- Example: Sat Feb 19 19:49:00 2022
        local lastPlayedDate = os.date("%a %b %d %H:%M:%S %Y", v:GetLastPlayed())

        local lastPlayed = button:Add("ax.text")
        lastPlayed:Dock(BOTTOM)
        lastPlayed:DockMargin(0, 0, 0, tinyPadding)
        lastPlayed:SetFont("parallax.button")
        lastPlayed:SetText(lastPlayedDate, true)
        lastPlayed.Think = function(this)
            this:SetTextColor(button:GetTextColor())
        end
    end
end

function PANEL:PopulateDelete(characterID)
    self:Clear()

    local title = self:Add("ax.text")
    title:Dock(TOP)
    title:DockMargin(padding, padding, 0, 0)
    title:SetFont("parallax.title")
    title:SetText(string.upper("mainmenu.delete.character"))

    local confirmation = self:Add("ax.text")
    confirmation:Dock(TOP)
    confirmation:DockMargin(padding, smallPadding, 0, 0)
    confirmation:SetFont("parallax.button.large.hover")
    confirmation:SetText("mainmenu.delete.character.confirm")

    local navigation = self:Add("EditablePanel")
    navigation:Dock(BOTTOM)
    navigation:DockMargin(padding, 0, padding, padding)
    navigation:SetTall(ScreenScale(24))

    local cancelButton = navigation:Add("ax.button.small")
    cancelButton:Dock(LEFT)
    cancelButton:SetText("CANCEL")
    cancelButton.DoClick = function()
        self:Populate()
    end

    local okButton = navigation:Add("ax.button.small")
    okButton:Dock(RIGHT)
    okButton:SetText("OK")
    okButton.DoClick = function()
        ax.net:Start("character.delete", characterID)
    end
end

vgui.Register("ax.mainmenu.load", PANEL, "EditablePanel")