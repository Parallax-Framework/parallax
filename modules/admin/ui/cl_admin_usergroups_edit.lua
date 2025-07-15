--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:ShowEditGroupDialog(groupName, groupData)
    if (!groupData.Custom) then
        ax.notification:Send(ax.client, "Cannot edit default usergroups.")
        return
    end

    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 300)
    frame:Center()
    frame:SetTitle("Edit Usergroup: " .. groupName)
    frame:MakePopup()

    -- Same layout as create dialog but with current values
    local nameLabel = vgui.Create("DLabel", frame)
    nameLabel:SetPos(20, 40)
    nameLabel:SetSize(100, 20)
    nameLabel:SetText("Name: " .. groupName)

    local inheritsLabel = vgui.Create("DLabel", frame)
    inheritsLabel:SetPos(20, 80)
    inheritsLabel:SetSize(100, 20)
    inheritsLabel:SetText("Inherits:")

    local inheritsCombo = vgui.Create("DComboBox", frame)
    inheritsCombo:SetPos(120, 80)
    inheritsCombo:SetSize(260, 25)
    inheritsCombo:SetValue(groupData.Inherits or "user")

    for name, _ in pairs(MODULE.ClientGroups) do
        inheritsCombo:AddChoice(name)
    end

    local levelLabel = vgui.Create("DLabel", frame)
    levelLabel:SetPos(20, 120)
    levelLabel:SetSize(100, 20)
    levelLabel:SetText("Level:")

    local levelSlider = vgui.Create("DNumSlider", frame)
    levelSlider:SetPos(120, 120)
    levelSlider:SetSize(260, 25)
    levelSlider:SetText("")
    levelSlider:SetMin(0)
    levelSlider:SetMax(4)
    levelSlider:SetDecimals(0)
    levelSlider:SetValue(groupData.Level or 1)

    local immunityLabel = vgui.Create("DLabel", frame)
    immunityLabel:SetPos(20, 160)
    immunityLabel:SetSize(100, 20)
    immunityLabel:SetText("Immunity:")

    local immunitySlider = vgui.Create("DNumSlider", frame)
    immunitySlider:SetPos(120, 160)
    immunitySlider:SetSize(260, 25)
    immunitySlider:SetText("")
    immunitySlider:SetMin(0)
    immunitySlider:SetMax(100)
    immunitySlider:SetDecimals(0)
    immunitySlider:SetValue(groupData.Immunity or 0)

    local colorLabel = vgui.Create("DLabel", frame)
    colorLabel:SetPos(20, 200)
    colorLabel:SetSize(100, 20)
    colorLabel:SetText("Color:")

    local colorMixer = vgui.Create("DColorMixer", frame)
    colorMixer:SetPos(120, 200)
    colorMixer:SetSize(260, 60)
    colorMixer:SetPalette(true)
    colorMixer:SetAlphaBar(false)
    colorMixer:SetWangs(true)
    colorMixer:SetColor(groupData.Color or Color(255, 255, 255))

    local saveBtn = vgui.Create("DButton", frame)
    saveBtn:SetPos(20, 270)
    saveBtn:SetSize(100, 25)
    saveBtn:SetText("Save")
    saveBtn.DoClick = function()
        local inherits = inheritsCombo:GetValue()
        local level = levelSlider:GetValue()
        local immunity = immunitySlider:GetValue()
        local color = colorMixer:GetColor()

        net.Start("ax.admin.usergroup.edit")
            net.WriteString(groupName)
            net.WriteTable({
                Inherits = inherits,
                Level = level,
                Immunity = immunity,
                Color = color
            })
        net.SendToServer()

        frame:Close()
    end

    local cancelBtn = vgui.Create("DButton", frame)
    cancelBtn:SetPos(280, 270)
    cancelBtn:SetSize(100, 25)
    cancelBtn:SetText("Cancel")
    cancelBtn.DoClick = function()
        frame:Close()
    end
end