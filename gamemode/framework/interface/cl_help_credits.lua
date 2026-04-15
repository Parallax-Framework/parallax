ax.localization:AddPhrase("en", "tab.help.credits", "Credits")

ax.localization:AddPhrase("en", "credit.framework_dev", "Framework Developer")
ax.localization:AddPhrase("en", "credit.contributor", "Contributor")
ax.localization:AddPhrase("en", "credit.brainfucker", "Brainfucker")

local CREDITS = {
    -- steamid64           username        contribution
    {"76561197963057641", "riggs9162", ax.localization:GetPhrase("credit.framework_dev")},      -- https://steamcommunity.com/profiles/76561197963057641/
    {"76561198373309941", "bloodycop6385", ax.localization:GetPhrase("credit.framework_dev")},  -- https://steamcommunity.com/profiles/76561198373309941/

    {"76561199122803303", "Winkarst-cpu", ax.localization:GetPhrase("credit.contributor")},           -- https://steamcommunity.com/profiles/76561199122803303/
    {"76561199208575979", "Flexgg13", ax.localization:GetPhrase("credit.contributor")},              -- https://steamcommunity.com/profiles/76561199208575979/

    {"76561198882429953", "reallordmax", ax.localization:GetPhrase("credit.brainfucker")}                 -- https://steamcommunity.com/profiles/76561198882429953/
}

local function PopulateCredits(this, panel)
    local scroller = ax.help:CreateScroller(panel)
    local width = ax.help:GetContentWidth(panel)

    scroller.Paint = function(this2, width, height)
        ax.render.Draw(0, 0, 0, 3, height, color_white)
    end

    for i = 1, #CREDITS do
        local data = CREDITS[i]

        local panel = scroller:Add("EditablePanel")
        panel:Dock(TOP)
        panel:DockMargin(0, 5, 0, 0)
        panel:SetTall(96)
        panel.Paint = nil

        panel.avatar = panel:Add("AvatarImage")
        panel.avatar:SetSteamID(data[1], 184)
        panel.avatar:Dock(LEFT)
        panel.avatar:SetWide(64)
        panel.avatar:DockMargin(16, 16, 16, 16)

        local textPanel = panel:Add("EditablePanel")
        textPanel:Dock(FILL)
        textPanel.Paint = nil

        textPanel.name = textPanel:Add("ax.text")
        textPanel.name:SetFont("ax.massive.bold")
        textPanel.name:SetText(data[2], true)
        textPanel.name:Dock(TOP)
        textPanel.name:DockMargin(0, 14, 0, 0)
        textPanel.name:SizeToContents()

        textPanel.description = textPanel:Add("ax.text")
        textPanel.description:SetFont("ax.medium")
        textPanel.description:SetText(data[3], true)
        textPanel.description:Dock(TOP)
        textPanel.description:SizeToContents()
    end

    panel:SizeToContents()
end

hook.Remove("PopulateHelpCategories", "ax.tab.help.credits")
hook.Add("PopulateHelpCategories", "ax.tab.help.credits", function(categories)
    categories["credits"] = {
        sort = 999,
        name = "Credits",
        Populate = PopulateCredits
    }
end)
