local padding = ScreenScale(32)
local gradientLeft = ax.util:GetMaterial("vgui/gradient-l")
local gradientBottom = ax.util:GetMaterial("vgui/gradient-d")

DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
    self.container = self:Add("ax.scroller.vertical")
    self.container:Dock(FILL)
    self.container:DockMargin(0, padding / 8, 0, 0)

    self.cache = {}
    self.cache.players = {}
end

function PANEL:Think()
    if ( #self.cache.players != player.GetCount() ) then
        self:Populate()
    end
end

function PANEL:Populate()
    self.cache.players = select(2, player.Iterator())

    -- Divide the players into teams
    local teams = {}
    for _, client in ipairs(self.cache.players) do
        local teamID = client:Team()
        if ( !istable(teams[teamID]) ) then
            teams[teamID] = {}
        end

        table.insert(teams[teamID], client)
    end

    -- Sort the teams by their team ID
    local sortedTeams = {}
    for teamID, players in pairs(teams) do
        table.insert(sortedTeams, { teamID = teamID, players = players })
    end

    table.sort(sortedTeams, function(a, b) return a.teamID < b.teamID end)

    -- Clear the current scoreboard
    self.container:Clear()

    for _, teamData in ipairs(sortedTeams) do
        local teamID = teamData.teamID
        local players = teamData.players

        -- Create a new panel for the team
        local teamPanel = self.container:Add("ax.scoreboard.team")
        teamPanel:SetTeam(teamID)

        -- Add each player to the team panel
        for _, client in ipairs(players) do
            local playerPanel = teamPanel.container:Add("ax.scoreboard.player")
            playerPanel:SetPlayer(client)

            teamPanel.players[client:SteamID64()] = playerPanel
        end
    end
end

vgui.Register("ax.scoreboard", PANEL, "EditablePanel")

PANEL = {}

function PANEL:Init()
    self:Dock(TOP)
    self:DockMargin(0, 0, 0, ScreenScale(8))

    self.teamID = 0
    self.players = {}

    self.teamName = self:Add("ax.text")
    self.teamName:SetTall(ScreenScale(10))
    self.teamName:Dock(TOP)
    self.teamName:DockMargin(ScreenScale(2), 0, 0, 0)
    self.teamName:SetFont("parallax.italic.bold")
    self.teamName:SetContentAlignment(7)

    self.container = self:Add("EditablePanel")
    self.container:Dock(FILL)
    self.container.Paint = function(this, width, height)
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(0, 0, width, height)

        surface.SetMaterial(gradientBottom)
        surface.SetDrawColor(50, 50, 50, 200)
        surface.DrawTexturedRect(0, 0, width, height)
    end
end

function PANEL:SetTeam(teamID)
    self.teamID = teamID

    if ( IsValid(self.teamName) ) then
        self.teamName:SetText(team.GetName(teamID), true, true)
    end
end

function PANEL:PerformLayout(width, height)
    -- Resize the panel height to fit the team name and the other players
    local teamNameHeight = self.teamName:GetTall()
    local containerHeight = 0

    for _, playerPanel in pairs(self.players) do
        containerHeight = containerHeight + playerPanel:GetTall()
    end

    self:SetTall(teamNameHeight + containerHeight)
end

function PANEL:Paint(width, height)
    local color = team.GetColor(self.teamID)

    surface.SetMaterial(gradientLeft)
    surface.SetDrawColor(color.r, color.g, color.b, 200)
    surface.DrawTexturedRect(0, 0, width, height)
end

vgui.Register("ax.scoreboard.team", PANEL, "EditablePanel")

PANEL = {}

function PANEL:Init()
    self:Dock(TOP)
    self:SetTall(ScreenScale(16))

    self.avatar = self:Add("AvatarImage")
    self.avatar:SetSize(self:GetTall(), self:GetTall())
    self.avatar:SetPos(0, 0)

    self.name = self:Add("ax.text")
    self.name:SetFont("parallax.large.bold")

    self.ping = self:Add("ax.text")
    self.ping:SetSize(ScreenScale(32), self:GetTall())
    self.ping:SetFont("parallax.large.bold")
    self.ping:SetContentAlignment(6)

    self:SetMouseInputEnabled(true)
end

function PANEL:SetPlayer(client)
    self.player = client

    if ( IsValid(self.avatar) ) then
        self.avatar:SetPlayer(client, self:GetTall())
    end

    if ( IsValid(self.name) ) then
        self.name:SetText(client:SteamName(), true)
        self.name:SetPos(self.avatar:GetWide() + 16, self:GetTall() / 2 - self.name:GetTall() / 2)
    end
end

function PANEL:Think()
    if ( IsValid(self.ping) and IsValid(self.player) ) then
        self.ping:SetText(self.player:Ping() .. "ms", true)
        self.ping:SetPos(self:GetWide() - self.ping:GetWide() - 16, self:GetTall() / 2 - self.ping:GetTall() / 2)
    end
end

function PANEL:OnMousePressed(keyCode)
    if ( keyCode == MOUSE_LEFT ) then
        gui.OpenURL("http://steamcommunity.com/profiles/" .. self.player:SteamID64())
    elseif ( keyCode == MOUSE_RIGHT ) then
        local result = hook.Run("ShouldPopulateScoreboardPlayerCard", self.player)
        if ( result == false ) then return end

        local dermaMenu = DermaMenu(false, self)
        dermaMenu:Open()

        dermaMenu:AddOption("Copy SteamID", function()
            SetClipboardText(self.player:SteamID64())
        end):SetIcon("icon16/page_paste.png")

        dermaMenu:AddOption("Open Profile", function()
            gui.OpenURL("http://steamcommunity.com/profiles/" .. self.player:SteamID64())
        end):SetIcon("icon16/world.png")

        dermaMenu:AddSpacer()
        hook.Run("PopulateScoreboardPlayerCard", dermaMenu, self.player)
    end
end

vgui.Register("ax.scoreboard.player", PANEL, "EditablePanel")