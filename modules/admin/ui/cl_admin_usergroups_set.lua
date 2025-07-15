--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:ShowSetGroupDialog(player)
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 250)
    frame:Center()
    frame:SetTitle("Set Usergroup: " .. player:SteamName())
    frame:MakePopup()

    -- Group selection
    local groupLabel = vgui.Create("DLabel", frame)
    groupLabel:SetPos(20, 40)
    groupLabel:SetSize(100, 20)
    groupLabel:SetText("Usergroup:")

    local groupCombo = vgui.Create("DComboBox", frame)
    groupCombo:SetPos(120, 40)
    groupCombo:SetSize(260, 25)
    groupCombo:SetValue(player:GetUserGroup())

    for name, _ in pairs(MODULE.ClientGroups) do
        groupCombo:AddChoice(name)
    end

    -- Duration
    local durationLabel = vgui.Create("DLabel", frame)
    durationLabel:SetPos(20, 80)
    durationLabel:SetSize(100, 20)
    durationLabel:SetText("Duration (min):")

    local durationSlider = vgui.Create("DNumSlider", frame)
    durationSlider:SetPos(120, 80)
    durationSlider:SetSize(260, 25)
    durationSlider:SetText("")
    durationSlider:SetMin(0)
    durationSlider:SetMax(10080)
    durationSlider:SetDecimals(0)
    durationSlider:SetValue(0)

    -- Reason
    local reasonLabel = vgui.Create("DLabel", frame)
    reasonLabel:SetPos(20, 120)
    reasonLabel:SetSize(100, 20)
    reasonLabel:SetText("Reason:")

    local reasonEntry = vgui.Create("DTextEntry", frame)
    reasonEntry:SetPos(120, 120)
    reasonEntry:SetSize(260, 25)
    reasonEntry:SetPlaceholderText("Enter reason...")

    -- Buttons
    local setBtn = vgui.Create("DButton", frame)
    setBtn:SetPos(20, 170)
    setBtn:SetSize(100, 25)
    setBtn:SetText("Set Group")
    setBtn.DoClick = function()
        local group = groupCombo:GetValue()
        local duration = durationSlider:GetValue()
        local reason = reasonEntry:GetValue()

        if (reason == "") then
            ax.notification:Send(ax.client, "Reason cannot be empty.")
            return
        end

        net.Start("ax.admin.usergroup.set")
            net.WriteString(player:SteamID64())
            net.WriteString(group)
            net.WriteUInt(duration, 32)
            net.WriteString(reason)
        net.SendToServer()

        frame:Close()
    end

    local cancelBtn = vgui.Create("DButton", frame)
    cancelBtn:SetPos(280, 170)
    cancelBtn:SetSize(100, 25)
    cancelBtn:SetText("Cancel")
    cancelBtn.DoClick = function()
        frame:Close()
    end

    reasonEntry:RequestFocus()
end