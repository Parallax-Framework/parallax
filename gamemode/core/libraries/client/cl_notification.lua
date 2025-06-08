ax.notification = ax.notification or {}
ax.notification.stored = ax.notification.stored or {}

-- Configuration
local PANEL_WIDTH = ScrW() / 2.5
local PANEL_MARGIN = 8
local PANEL_SPACING = 4
local INTERP_SPEED = 8
local FONT_NAME = "parallax.bold"

-- Utility function to create a notification
function ax.notification:Add(text, duration, bgColor)
    duration = duration or 3
    bgColor.a = 200

    -- Create panel
    local panel = vgui.Create("DPanel")
    panel:SetWide(PANEL_WIDTH)
    panel:SetDrawOnTop(true)

    -- Prepare wrapped lines
    local maxTextWidth = PANEL_WIDTH - PANEL_MARGIN * 2
    local lines = ax.util:GetWrappedText(text, FONT_NAME, maxTextWidth)
    surface.SetFont(FONT_NAME)
    local _, lineHeight = surface.GetTextSize("Ay")
    local totalHeight = #lines * lineHeight + PANEL_MARGIN * 2
    panel:SetTall(totalHeight)

    -- Paint background and text
    panel.Paint = function(this, width, height)
        surface.SetDrawColor(bgColor)
        surface.DrawRect(0, 0, width, height)

        -- draw each line
        for i, line in ipairs(lines) do
            draw.SimpleText(
                line,
                FONT_NAME,
                PANEL_MARGIN,
                PANEL_MARGIN + (i - 1) * lineHeight,
                ax.color:Get("white"),
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_TOP
            )
        end
    end

    -- Initial position off-screen
    local scrW, _ = ScrW(), ScrH()
    panel.CurrentX = (scrW - PANEL_WIDTH) / 2
    panel.CurrentY = -panel:GetTall()
    panel.TargetX = panel.CurrentX
    panel.TargetY = panel.CurrentY
    panel:SetPos(panel.CurrentX, panel.CurrentY)

    -- Think hook for interpolation
    panel.Think = function(this)
        this.CurrentX = Lerp(FrameTime() * INTERP_SPEED, this.CurrentX, this.TargetX)
        this.CurrentY = Lerp(FrameTime() * INTERP_SPEED, this.CurrentY, this.TargetY)
        this:SetPos(this.CurrentX, this.CurrentY)
    end

    -- Insert at beginning
    table.insert(self.stored, 1, panel)

    -- Animate all notifications to new positions
    self:RepositionAll()

    -- Fade in
    panel:SetAlpha(0)
    panel:AlphaTo(255, 0.2, 0)

    -- Remove after duration
    timer.Simple(duration, function()
        if ( IsValid(panel) ) then
            panel:AlphaTo(0, 0.2, 0, function() panel:Remove() end)
            -- Remove and reposition
            timer.Simple(0.35, function()
                for i, v in ipairs(self.stored) do
                    if v == panel then
                        table.remove(self.stored, i)
                        break
                    end
                end
                self:RepositionAll()
            end)
        end
    end)
end

-- Reposition notifications using Lerp targets
function ax.notification:RepositionAll()
    local scrW = ScrW()
    for i, panel in ipairs(self.stored) do
        if ( IsValid(panel) ) then
            panel.TargetX = (scrW - PANEL_WIDTH) / 2
            panel.TargetY = PANEL_SPACING + (i - 1) * (panel:GetTall() + PANEL_SPACING)
        end
    end
end

notification.AddLegacy = function(text, type, length)
    local color
    if ( type == NOTIFY_ERROR ) then
        color = ax.config:Get("color.error")
        ax.client:EmitSound("ax.notification.error")
    elseif ( type == NOTIFY_HINT ) then
        color = ax.config:Get("color.success")
        ax.client:EmitSound("ax.notification.hint")
    else
        color = ax.config:Get("color.info")
        ax.client:EmitSound("ax.notification.generic")
    end

    ax.notification:Add(text, length or 3, color)
end

concommand.Add("test_notification", function(client, cmd, arguments)
    local text = table.concat(arguments, " ")
    ax.notification:Add(text, 5)
end)

sound.Add({
    name = "ax.notification.error",
    channel = CHAN_STATIC,
    volume = 1.0,
    level = 80,
    sound = "parallax/ui/error.wav"
})

sound.Add({
    name = "ax.notification.hint",
    channel = CHAN_STATIC,
    volume = 1.0,
    level = 80,
    sound = "parallax/ui/hint.wav"
})

sound.Add({
    name = "ax.notification.generic",
    channel = CHAN_STATIC,
    volume = 1.0,
    level = 80,
    sound = "parallax/ui/generic.wav"
})