----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 --- Made by a transgender queen
 -- Slay queen Riggs
 -- Stay Powerfull against the Patiarchy by a man (Alex Grist) stealing code
 -- #OverwatchFramework #CodeStealingMatters

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.derma = ax.derma or {}
ax.derma.open = ax.derma.open or {}

local matBlurScreen = Material("pp/blurscreen")

function Derma_DrawBackgroundBlur(panel, starttime)
    local fraction = 1

    if ( starttime ) then
        fraction = math.Clamp((SysTime() - starttime) / 1, 0, 1)
    end

    local x, y = panel:LocalToScreen(0, 0)
    local wasEnabled = DisableClipping(true)

    if ( !MENU_DLL ) then
        surface.SetMaterial(matBlurScreen)
        surface.SetDrawColor(255, 255, 255, 255)

        for i = 0.33, 1, 0.33 do
            matBlurScreen:SetFloat("$blur", fraction * 5 * i)
            matBlurScreen:Recompute()
            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
        end
    end

    surface.SetDrawColor(10, 10, 10, 200 * fraction)
    surface.DrawRect(x * -1, y * -1, ScrW(), ScrH())

    DisableClipping(wasEnabled)
end

function Derma_Message(text, title, buttonText)
    title = title or "Notice"
    text = text or "Message Text"
    buttonText = buttonText or "OK"

    local frame = vgui.Create("EditablePanel")
    frame:SetSize(ScrW() / 2, ScrH() / 4)
    frame:Center()
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.1, 0)
    frame.starttime = SysTime()
    frame.Paint = function(this, w, h)
        Derma_DrawBackgroundBlur(this, this.starttime)
    end
    frame.Close = function(this)
        if ( IsValid(this) ) then
            this:AlphaTo(0, 0.1, 0, function()
                this:Remove()
            end)
        end
    end

    table.insert(ax.derma.open, frame)

    local label = frame:Add("ax.text")
    label:Dock(TOP)
    label:DockMargin(0, ScreenScaleH(8), 0, 0)
    label:SetFont("parallax.subtitle")
    label:SetText(string.upper(title), true)

    local wrapped = ax.util:GetWrappedText(text, "parallax", frame:GetWide() - ScreenScale(16))
    local textHeight = 0
    for _, line in ipairs(wrapped) do
        local textLabel = frame:Add("ax.text")
        textLabel:Dock(TOP)
        textLabel:SetText(line, true)
        textHeight = textHeight + textLabel:GetTall()
    end

    local btnPanel = frame:Add("EditablePanel")
    btnPanel:Dock(BOTTOM)

    local btn = btnPanel:Add("ax.button.small")
    btn:Dock(FILL)
    btn:SetText(buttonText)
    btn.DoClick = function()
        frame:Close()
    end

    btnPanel:SetTall(btn:GetTall())
    frame:SetTall(label:GetTall() + textHeight + btnPanel:GetTall() + ScreenScaleH(24))
    frame:Center()

    frame:MakePopup()
    frame:DoModal()

    return frame
end

function Derma_Query(text, title, ...)
    title = title or "Query"
    text = text or "Are you sure?"

    local frame = vgui.Create("EditablePanel")
    frame:SetSize(ScrW() / 2, ScrH() / 4)
    frame:Center()
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.1, 0)
    frame.starttime = SysTime()
    frame.Paint = function(this, w, h)
        Derma_DrawBackgroundBlur(this, this.starttime)
    end
    frame.Close = function(this)
        if ( IsValid(this) ) then
            this:AlphaTo(0, 0.1, 0, function()
                this:Remove()
            end)
        end
    end

    table.insert(ax.derma.open, frame)

    local label = frame:Add("ax.text")
    label:Dock(TOP)
    label:DockMargin(0, ScreenScaleH(8), 0, 0)
    label:SetFont("parallax.subtitle")
    label:SetText(string.upper(title), true)

    local wrapped = ax.util:GetWrappedText(text, "parallax", frame:GetWide() - ScreenScale(16))
    local textHeight = 0
    for _, line in ipairs(wrapped) do
        local textLabel = frame:Add("ax.text")
        textLabel:Dock(TOP)
        textLabel:SetText(line, true)
        textHeight = textHeight + textLabel:GetTall()
    end

    local btnPanel = frame:Add("EditablePanel")
    btnPanel:Dock(BOTTOM)
    btnPanel:SetTall(ScreenScaleH(24))

    local numOptions = 0

    for i = 1, 8, 2 do
        local txt = select(i, ...)
        if ( txt == nil ) then break end

        local fn = select(i + 1, ...) or function() end

        local btn = btnPanel:Add("ax.button.small")
        btn:Dock(LEFT)
        btn:DockMargin(0, 0, ScreenScale(4), 0)
        btn:SetText(txt, true)
        btn.DoClick = function()
            frame:Close()
            fn()
        end

        numOptions = numOptions + 1
    end

    frame:SetTall(label:GetTall() + textHeight + btnPanel:GetTall() + ScreenScaleH(24))
    frame:Center()

    frame:MakePopup()
    frame:DoModal()

    if ( numOptions == 0 ) then
        frame:Remove()
        Error("Derma_Query: Created query with no options!")
        return nil
    end

    return frame
end

function Derma_StringRequest(title, text, defaultText, onEnter, onCancel, okText, cancelText)
    title = title or "String Request"
    text = text or "Please enter a value:"
    defaultText = defaultText or ""

    local frame = vgui.Create("EditablePanel")
    frame:SetSize(ScrW() / 2, ScrH() / 4)
    frame:Center()
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.1, 0)
    frame.starttime = SysTime()
    frame.Paint = function(this, width, height)
        Derma_DrawBackgroundBlur(this, this.starttime)
    end
    frame.Close = function(this)
        if ( IsValid(this) ) then
            this:AlphaTo(0, 0.1, 0, function()
                this:Remove()
            end)
        end
    end

    table.insert(ax.derma.open, frame)

    local label = frame:Add("ax.text")
    label:Dock(TOP)
    label:DockMargin(0, ScreenScaleH(8), 0, 0)
    label:SetFont("parallax.subtitle")
    label:SetText(string.upper(title), true)

    local wrapped = ax.util:GetWrappedText(text, "parallax", frame:GetWide() - ScreenScale(16))
    local textHeight = 0
    for i, line in ipairs(wrapped) do
        local textLabel = frame:Add("ax.text")
        textLabel:Dock(TOP)
        textLabel:SetText(line, true)

        textHeight = textHeight + textLabel:GetTall()
    end

    local entry = frame:Add("ax.text.entry")
    entry:Dock(TOP)
    entry:DockMargin(0, ScreenScaleH(8), 0, ScreenScaleH(8))
    entry:SetText(defaultText)
    entry.OnEnter = function()
        frame:Close()
        onEnter(entry:GetValue())
    end

    local btnPanel = frame:Add("EditablePanel")
    btnPanel:Dock(BOTTOM)

    local btnOK = btnPanel:Add("ax.button.small")
    btnOK:Dock(LEFT)
    btnOK:SetText(okText or "OK")
    btnOK.DoClick = function()
        frame:Close()
        onEnter(entry:GetValue())
    end

    local btnCancel = btnPanel:Add("ax.button.small")
    btnCancel:Dock(RIGHT)
    btnCancel:SetText(cancelText or "Cancel")
    btnCancel.DoClick = function()
        frame:Close()
        if ( onCancel ) then onCancel(entry:GetValue()) end
    end

    btnPanel:SetTall(math.max(btnOK:GetTall(), btnCancel:GetTall()))

    frame:SetTall(label:GetTall() + textHeight + entry:GetTall() + btnPanel:GetTall() + ScreenScaleH(32))
    frame:Center()

    entry:RequestFocus()
    entry:SetCaretPos(string.len(defaultText))

    frame:MakePopup()
    frame:DoModal()

    return frame
end

function Derma_HideAll()
    for _, frame in ipairs(ax.derma.open) do
        if ( IsValid(frame) ) then
            frame:Remove()
        end
    end

    ax.derma.open = {}
end

concommand.Add("ax_derma_hideall", function()
    Derma_HideAll()
end)

hook.Add("OnReloaded", "ax_derma_hideall", function()
    Derma_HideAll()
end)