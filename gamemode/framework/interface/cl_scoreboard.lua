--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

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
    for _, client in ipairs(player.GetAll()) do
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
            local glass = ax.theme:GetGlass()
            ax.theme:DrawGlassPanel(0, 0, width, height, {
                radius = 8,
                blur = 0.8,
                flags = ax.render.SHAPE_IOS,
                fill = glass.panel
            })
            ax.render.Draw(8, 0, 0, width, height, ColorAlpha(col, 90), ax.render.SHAPE_IOS)
            ax.render.Draw(8, 0, 0, width, height, glass.highlight, ax.render.SHAPE_IOS)
        end

        local darkTheme = ax.theme:Get("dark")
        local lightTheme = ax.theme:Get("light")

        local title = header:Add("ax.text")
        title:Dock(FILL)
        title:SetFont("ax.large.bold.italic")
        title:SetText(team.GetName(tid) or ("Team " .. tostring(tid)), true)
        title:SetTextInset(ax.util:ScreenScale(2), -ax.util:ScreenScaleH(1))
        title:SetTextColor(!team.GetColor(tid):IsDark() and lightTheme.glass.text or darkTheme.glass.text)
        title:SetExpensiveShadow(2, Color(0, 0, 0, 200))

        header:SetTall(title:GetTall())

        -- Player rows
        for index, client in ipairs(members) do
            local row = self.container:Add("EditablePanel")
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, index == #members and ax.util:ScreenScaleH(12) or 0)
            row:SetMouseInputEnabled(true)
            row.Paint = function(_, width, height)
                ax.theme:DrawGlassPanel(0, 0, width, height, {
                    radius = 8,
                    blur = 0.7,
                    flags = ax.render.SHAPE_IOS
                })
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

            local steamName = client:SteamName()
            local toDisplay = ""
            if ( ax.client:IsAdmin() and client:Nick() != steamName ) then
                toDisplay = {client:Nick()}

                local classData = client:GetClassData()
                local rankData = client:GetRankData()
                if ( classData ) then
                    toDisplay[#toDisplay + 1] = classData.name
                end

                if ( rankData ) then
                    toDisplay[#toDisplay + 1] = rankData.name
                end

                toDisplay = table.concat(toDisplay, ", ")
            end

            name:SetText(steamName .. (toDisplay != "" and " (" .. toDisplay .. ")" or ""), true)

            -- Ping (right aligned)
            local ping = row:Add("ax.text")
            ping:Dock(RIGHT)
            ping:DockMargin(0, 0, 8, 0)
            ping:SetText(client:IsBot() and "Bot" or tostring(client:Ping()) .. " ms", true)

            row:SetTall(math.max(avatar:GetTall(), name:GetTall(), ping:GetTall()) * 1.5)
            avatar:SetSize(row:GetTall(), row:GetTall())
        end
    end
end

vgui.Register("ax.tab.scoreboard", PANEL, "EditablePanel")

-- Clean up existing hook to prevent duplicates on reload
hook.Remove("PopulateTabButtons", "ax.tab.scoreboard")

hook.Add("PopulateTabButtons", "ax.tab.scoreboard", function(buttons)
    buttons["scoreboard"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.scoreboard")
        end
    }
end)
