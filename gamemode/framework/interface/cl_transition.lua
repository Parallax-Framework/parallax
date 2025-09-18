local PANEL = {}

AccessorFunc(PANEL, "currentAlpha", "CurrentAlpha", FORCE_NUMBER)
AccessorFunc(PANEL, "currentX", "CurrentX", FORCE_NUMBER)
AccessorFunc(PANEL, "currentY", "CurrentY", FORCE_NUMBER)
AccessorFunc(PANEL, "active", "Active", FORCE_BOOL)
AccessorFunc(PANEL, "easing", "Easing", FORCE_STRING)
AccessorFunc(PANEL, "xOffset", "XOffset", FORCE_NUMBER)
AccessorFunc(PANEL, "yOffset", "YOffset", FORCE_NUMBER)
AccessorFunc(PANEL, "widthOffset", "WidthOffset", FORCE_NUMBER)
AccessorFunc(PANEL, "heightOffset", "HeightOffset", FORCE_NUMBER)

function PANEL:Init()
    local parent = self:GetParent()
    if ( !IsValid(parent) ) then
        ErrorNoHaltWithStack("Created ax.transition without a parent panel!\n")
        self:Remove()
        return
    end

    -- Initialize offset values
    self.xOffset = 0
    self.yOffset = 0
    self.widthOffset = 0
    self.heightOffset = 0

    self:SetSize(parent:GetWide() + self.widthOffset, parent:GetTall() + self.heightOffset)
    self:SetPos(self.xOffset, self.yOffset)

    self.currentAlpha = 0
    self.currentX = self.xOffset
    self.currentY = self:GetTall()
    self.active = false
    self.easing = "InOutQuart"

    self.guard = self:Add("Panel")
    self.guard:SetPos(0, 0)
    self.guard:SetSize(self:GetWide(), self:GetTall())

    -- Track last-applied offsets to preserve animated deltas on change
    self._lastXOffset = self.xOffset
    self._lastYOffset = self.yOffset

    self:HidePanel()
end

-- Applies current offsets to size and position without breaking ongoing motion.
function PANEL:ReflowFromOffsets()
    local parent = self:GetParent()
    if ( !IsValid(parent) ) then return end

    -- Always match our size to parent plus offsets
    self:SetSize(parent:GetWide() + (self.widthOffset or 0), parent:GetTall() + (self.heightOffset or 0))

    -- Preserve current animated position by shifting with the delta of offsets
    local dx = (self.xOffset or 0) - (self._lastXOffset or 0)
    local dy = (self.yOffset or 0) - (self._lastYOffset or 0)

    self.currentX = (self.currentX or 0) + dx
    self.currentY = (self.currentY or 0) + dy
    self:SetPos(self.currentX, self.currentY)

    if ( IsValid(self.guard) ) then
        self.guard:SetSize(self:GetWide(), self:GetTall())
    end

    self._lastXOffset = self.xOffset or 0
    self._lastYOffset = self.yOffset or 0
end

-- Override setter to reflow when offsets change.
function PANEL:SetXOffset(value)
    value = tonumber(value) or 0
    if ( self.xOffset == value ) then return end
    self.xOffset = value
    self:ReflowFromOffsets()
end

function PANEL:SetYOffset(value)
    value = tonumber(value) or 0
    if ( self.yOffset == value ) then return end
    self.yOffset = value
    self:ReflowFromOffsets()
end

function PANEL:SetWidthOffset(value)
    value = tonumber(value) or 0
    if ( self.widthOffset == value ) then return end
    self.widthOffset = value
    self:ReflowFromOffsets()
end

function PANEL:SetHeightOffset(value)
    value = tonumber(value) or 0
    if ( self.heightOffset == value ) then return end
    self.heightOffset = value
    self:ReflowFromOffsets()
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
    self.currentY = self.yOffset

    self:SetPos(self.currentX, self.currentY)
end

function PANEL:StartAtTop()
    self.currentX = self.xOffset
    self.currentY = -self:GetTall()

    self:SetPos(self.currentX, self.currentY)
end

function PANEL:StartAtRight()
    self.currentX = ScrW()
    self.currentY = self.yOffset

    self:SetPos(self.currentX, self.currentY)
end

function PANEL:StartAtBottom()
    self.currentX = self.xOffset
    self.currentY = ScrH()

    self:SetPos(self.currentX, self.currentY)
end

function PANEL:SlideToFront(time, callback)
    if ( self.active ) then return end

    self:SetZPos(CurTime() / 1000) -- Set a high ZPos to ensure this panel is on top
    self:SetVisible(true)
    self:SetMouseInputEnabled(true)
    self:SetKeyboardInputEnabled(true)

    self.guard:SetVisible(true)
    self.guard:SetZPos(CurTime() / 1000 + 1)

    if ( self.OnSlideStart ) then
        self:OnSlideStart()
    end

    self:Motion(time or 1, {
        Target = { currentX = self.xOffset, currentY = self.yOffset, currentAlpha = 255 },
        Easing = self.easing,
        Delay = 0,
        Think = function(this)
            self:SetPos(this.currentX, this.currentY)
            self:SetAlpha(this.currentAlpha)
        end,
        OnComplete = function(this)
            if ( this.OnSlideComplete ) then
                this:OnSlideComplete()
            end

            self.guard:SetVisible(false)

            if ( isfunction(callback) ) then
                callback()
            end
        end
    })

    self.active = true
end

function PANEL:HidePanel()
    if ( !self.active ) then return end

    self:SetZPos(0)
    self:SetVisible(false)

    self.guard:SetVisible(false)

    self.active = false
end

function PANEL:SlideLeft(time, callback)
    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)

    self.guard:SetVisible(true)

    self:Motion(time or 1, {
        Target = { currentX = -self:GetWide(), currentY = self.yOffset, currentAlpha = 0 },
        Easing = self.easing,
        Delay = 0,
        Think = function(this)
            self:SetPos(this.currentX, this.currentY)
            self:SetAlpha(this.currentAlpha)
        end,
        OnComplete = function()
            self:HidePanel()

            if ( isfunction(callback) ) then
                callback()
            end
        end
    })
end

function PANEL:SlideUp(time, callback)
    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)

    self.guard:SetVisible(true)

    self:Motion(time or 1, {
        Target = { currentX = self.xOffset, currentY = -self:GetTall(), currentAlpha = 0 },
        Easing = self.easing,
        Delay = 0,
        Think = function(this)
            self:SetPos(this.currentX, this.currentY)
            self:SetAlpha(this.currentAlpha)
        end,
        OnComplete = function()
            self:HidePanel()

            if ( isfunction(callback) ) then
                callback()
            end
        end
    })
end

function PANEL:SlideRight(time, callback)
    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)

    self.guard:SetVisible(true)

    self:Motion(time or 1, {
        Target = { currentX = self:GetWide(), currentY = self.yOffset, currentAlpha = 0 },
        Easing = self.easing,
        Delay = 0,
        Think = function(this)
            self:SetPos(this.currentX, this.currentY)
            self:SetAlpha(this.currentAlpha)
        end,
        OnComplete = function()
            self:HidePanel()

            if ( isfunction(callback) ) then
                callback()
            end
        end
    })
end

function PANEL:SlideDown(time, callback)
    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)

    self.guard:SetVisible(true)

    self:Motion(time or 1, {
        Target = { currentX = self.xOffset, currentY = self:GetTall(), currentAlpha = 0 },
        Easing = self.easing,
        Delay = 0,
        Think = function(this)
            self:SetPos(this.currentX, this.currentY)
            self:SetAlpha(this.currentAlpha)
        end,
        OnComplete = function()
            self:HidePanel()

            if ( isfunction(callback) ) then
                callback()
            end
        end
    })
end

vgui.Register("ax.transition", PANEL, "EditablePanel")

PANEL = {}

AccessorFunc(PANEL, "currentPage", "CurrentPage", FORCE_NUMBER)
AccessorFunc(PANEL, "pages", "Pages")

function PANEL:Init()
    self.pages = {}
    self.currentPage = 0
end

function PANEL:CreatePage()
    local page = vgui.Create("ax.transition", self)
    page.index = #self.pages + 1
    self.pages[#self.pages + 1] = page
    return page
end

function PANEL:GetPages()
    return self.pages
end

function PANEL:TransitionToPage(targetPageIndex, duration, skipStartAt)
    if ( targetPageIndex < 1 or targetPageIndex > #self.pages ) then return end

    local currentPageIndex = self:GetCurrentPage()
    local currentPage = self.pages[currentPageIndex]
    local targetPage = self.pages[targetPageIndex]

    if ( currentPageIndex == targetPageIndex ) then
        return
    else
        -- If our current page is lower than our requested page, slide the target page in from the right
        if ( currentPageIndex < targetPageIndex ) then
            -- Slide out the current page to the left
            if ( IsValid(currentPage) ) then
                currentPage:SlideLeft(duration)
            end

            if ( !skipStartAt ) then
                targetPage:StartAtRight(duration)
            end

            targetPage:SlideToFront(duration)
        else
            -- Slide out the current page to the right
            if ( IsValid(currentPage) ) then
                currentPage:SlideRight(duration)
            end

            if ( !skipStartAt ) then
                targetPage:StartAtLeft(duration)
            end

            targetPage:SlideToFront(duration)
        end
    end

    self.currentPage = targetPageIndex
end

function PANEL:HideAllPages()
    for k, v in pairs(self.pages) do
        if ( IsValid(v) ) then
            v:HidePanel()
        end
    end

    self.currentPage = 0
end

function PANEL:Paint(width, height)
    ax.render.Draw(0, 0, 0, width, height, Color(0, 0, 0, 150))
end

vgui.Register("ax.transition.pages", PANEL, "DPanel")