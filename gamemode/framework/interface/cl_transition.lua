local PANEL = {}

AccessorFunc(PANEL, "currentAlpha", "CurrentAlpha", FORCE_NUMBER)
AccessorFunc(PANEL, "currentX", "CurrentX", FORCE_NUMBER)
AccessorFunc(PANEL, "currentY", "CurrentY", FORCE_NUMBER)
AccessorFunc(PANEL, "active", "Active", FORCE_BOOL)
AccessorFunc(PANEL, "easing", "Easing", FORCE_STRING)

function PANEL:Init()
    local parent = self:GetParent()
    if ( !IsValid(parent) ) then
        ErrorNoHaltWithStack("Created ax.transition without a parent panel!\n")
        self:Remove()
        return
    end

    self:SetSize(parent:GetWide(), parent:GetTall())
    self:SetPos(0, 0)

    self.currentAlpha = 0
    self.currentX = 0
    self.currentY = self:GetTall()
    self.active = false
    self.easing = "OutBounce"

    self:HidePanel() -- quickly hide the panel so it doesn't show up in the middle of the screen
end

function PANEL:CreateNavigation(parent, backText, backCallback, nextText, nextCallback)
    local navigation = parent:Add("EditablePanel")
    navigation:Dock(BOTTOM)
    navigation:DockMargin(ScreenScale(32), 0, ScreenScale(32), ScreenScaleH(32))

    local backButton = navigation:Add("ax.button.flat")
    backButton:Dock(LEFT)
    backButton:SetText(backText)
    backButton.DoClick = backCallback

    if ( nextText and nextCallback ) then
        local nextButton = navigation:Add("ax.button.flat")
        nextButton:Dock(RIGHT)
        nextButton:SetText(nextText)
        nextButton.DoClick = nextCallback
    end

    navigation:SetTall(math.max(backButton:GetTall(), nextButton and nextButton:GetTall() or 0))

    return navigation
end

function PANEL:StartAtLeft()
    self.currentX = -self:GetWide()
    self.currentY = 0

    self:SetPos(self.currentX, self.currentY)
end

function PANEL:StartAtTop()
    self.currentX = 0
    self.currentY = -self:GetTall()

    self:SetPos(self.currentX, self.currentY)
end

function PANEL:StartAtRight()
    self.currentX = ScrW()
    self.currentY = 0

    self:SetPos(self.currentX, self.currentY)
end

function PANEL:StartAtBottom()
    self.currentX = 0
    self.currentY = ScrH()

    self:SetPos(self.currentX, self.currentY)
end

function PANEL:SlideToFront(time)
    if ( self.active ) then return end

    self:SetZPos(CurTime() / 1000) -- Set a high ZPos to ensure this panel is on top
    self:SetVisible(true)
    self:SetMouseInputEnabled(true)
    self:SetKeyboardInputEnabled(true)

    self:Motion(time or 1, {
        Target = { currentX = 0, currentY = 0, currentAlpha = 255 },
        Easing = self.easing,
        Delay = 0,
        Think = function(this)
            self:SetPos(this.currentX, this.currentY)
            self:SetAlpha(this.currentAlpha)
        end
    })

    self.active = true
end

-- 4 Variants of transitions of hiding the transition panel
-- left, up, right, down
-- create a helper function to handle the hiding logic, then create the 4 variants
function PANEL:HidePanel()
    self:SetZPos(0)
    self:SetVisible(false)

    self.active = false
end

function PANEL:SlideLeft(time)
    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)

    self:Motion(time or 1, {
        Target = { currentX = -self:GetWide(), currentY = 0, currentAlpha = 0 },
        Easing = self.easing,
        Delay = 0,
        Think = function(this)
            self:SetPos(this.currentX, this.currentY)
            self:SetAlpha(this.currentAlpha)
        end,
        OnComplete = function()
            self:HidePanel()
        end
    })
end

function PANEL:SlideUp(time)
    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)

    self:Motion(time or 1, {
        Target = { currentX = 0, currentY = -self:GetTall(), currentAlpha = 0 },
        Easing = self.easing,
        Delay = 0,
        Think = function(this)
            self:SetPos(this.currentX, this.currentY)
            self:SetAlpha(this.currentAlpha)
        end,
        OnComplete = function()
            self:HidePanel()
        end
    })
end

function PANEL:SlideRight(time)
    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)

    self:Motion(time or 1, {
        Target = { currentX = self:GetWide(), currentY = 0, currentAlpha = 0 },
        Easing = self.easing,
        Delay = 0,
        Think = function(this)
            self:SetPos(this.currentX, this.currentY)
            self:SetAlpha(this.currentAlpha)
        end,
        OnComplete = function()
            self:HidePanel()
        end
    })
end

function PANEL:SlideDown(time)
    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)

    self:Motion(time or 1, {
        Target = { currentX = 0, currentY = self:GetTall(), currentAlpha = 0 },
        Easing = self.easing,
        Delay = 0,
        Think = function(this)
            self:SetPos(this.currentX, this.currentY)
            self:SetAlpha(this.currentAlpha)
        end,
        OnComplete = function()
            self:HidePanel()
        end
    })
end

vgui.Register("ax.transition", PANEL, "EditablePanel")