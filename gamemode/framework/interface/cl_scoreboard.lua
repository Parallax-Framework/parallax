local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)

    -- Scrollable container for teams/players
    self.container = self:Add("DScrollPanel")
    self.container:Dock(FILL)
    self.container:GetVBar():SetWide(6)

    -- Initial build
    self:RebuildScoreboard()

    -- Refresh every second
    timer.Create("ax.scoreboard.refresh", 1, 0, function()
        if ( IsValid(self) ) then
            self:RebuildScoreboard()
        end
    end)
end

function PANEL:Paint(width, height)
end

function PANEL:OnRemove()
    timer.Remove("ax.scoreboard.refresh")
end

function PANEL:RebuildScoreboard()
    if ( !IsValid(self.container) ) then return end

    self.container:Clear()

    local teams = {}
    for _, client in player.Iterator() do
        local tid = client:Team() or 0
        teams[tid] = teams[tid] or {}
        table.insert(teams[tid], client)
    end

    -- Sort team ids
    local ids = {}
    for id, _ in pairs(teams) do
        table.insert(ids, id)
    end

    table.sort(ids)

    for _, tid in ipairs(ids) do
        local members = teams[tid]
        if ( !members or #members == 0 ) then continue end

        -- Team header
        local header = self.container:Add("EditablePanel")
        header:Dock(TOP)
        header.Paint = function(_, width, height)
            local col = team.GetColor(tid) or Color(80, 80, 80)
            ax.render.Draw(0, 0, 0, width, height, ColorAlpha(col, 180))
        end

        local title = header:Add("ax.text")
        title:Dock(FILL)
        title:SetFont("ax.large.italic.bold")
        title:SetText(team.GetName(tid) or ("Team " .. tostring(tid)), true)
        title:SetTextInset(ax.util:UIScreenScale(2), -ax.util:UIScreenScaleH(1))
        title:SetExpensiveShadow(2, Color(0, 0, 0, 200))

        header:SetTall(title:GetTall())

        -- Player rows
        for index, client in ipairs(members) do
            local row = self.container:Add("EditablePanel")
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, index == #members and ax.util:UIScreenScaleH(8) or 0)
            row:SetMouseInputEnabled(true)
            row.Paint = function(_, width, height)
                ax.render.Draw(0, 0, 0, width, height, Color(0, 0, 0, 150))
            end

            -- Right-click context menu support. Other modules can add entries
            -- by hooking "PopulateScoreboardPlayerContext".
            function row:OnMousePressed(code)
                if ( code == MOUSE_RIGHT ) then
                    local menu = DermaMenu()
                    menu:AddOption("View Profile", function()
                        gui.OpenURL("http://steamcommunity.com/profiles/" .. client:SteamID64())
                    end):SetIcon("icon16/user_go.png")

                    -- Allow modules to populate the menu
                    local ok, err = pcall(hook.Run, "PopulateScoreboardPlayerContext", menu, client, row)
                    if ( !ok ) then
                        ErrorNoHalt("PopulateScoreboardPlayerContext hook error: " .. tostring(err) .. "\n")
                    end

                    menu:Open()
                end
            end

            -- Avatar
            local avatar = vgui.Create("AvatarImage", row)
            avatar:SetPlayer(client, 32)
            avatar:SetMouseInputEnabled(false)
            avatar:Dock(LEFT)

            -- Name
            local name = row:Add("ax.text")
            name:Dock(LEFT)
            name:DockMargin(8, 0, 0, 0)
            name:SetFont("ax.small")
            name:SetText(client:SteamName() .. (ax.client:IsAdmin() and (client:Nick() != client:SteamName()) and " (" .. client:Nick() .. ")" or ""), true)

            -- Ping (right aligned)
            local ping = row:Add("ax.text")
            ping:Dock(RIGHT)
            ping:DockMargin(0, 0, 8, 0)
            ping:SetFont("ax.small")
            ping:SetText(client:IsBot() and "Bot" or tostring(client:Ping()) .. " ms", true)

            row:SetTall(math.max(avatar:GetTall(), name:GetTall(), ping:GetTall()) * 1.5)
            avatar:SetSize(row:GetTall(), row:GetTall())
        end
    end
end

vgui.Register("ax.tab.scoreboard", PANEL, "EditablePanel")

hook.Add("PopulateTabButtons", "ax.tab.scoreboard", function(buttons)
    buttons["scoreboard"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.scoreboard")
        end
    }
end)
