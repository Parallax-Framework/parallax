DEFINE_BASECLASS("DButton")

local PANEL = {}

AccessorFunc(PANEL, "soundEnter", "SoundEnter", FORCE_STRING)
AccessorFunc(PANEL, "soundClick", "SoundClick", FORCE_STRING)
AccessorFunc(PANEL, "fontDefault", "FontDefault", FORCE_STRING)
AccessorFunc(PANEL, "fontHovered", "FontHovered", FORCE_STRING)
AccessorFunc(PANEL, "inertia", "Inertia", FORCE_NUMBER)
-- AccessorFunc(PANEL, "textColor", "TextColor") -- this is already added by DButton
AccessorFunc(PANEL, "textColorMotion", "TextColorMotion")
AccessorFunc(PANEL, "textColorHovered", "TextColorHovered")
AccessorFunc(PANEL, "easing", "Easing", FORCE_STRING)

function PANEL:Init()
    self.soundEnter = "UI/buttonrollover.wav"
    self.soundClick = "UI/buttonclick.wav"
    self.fontDefault = "ax.large"
    self.fontHovered = "ax.large.bold"
    self.textColor = Color(255, 255, 255)
    self.textColorMotion = Color(255, 255, 255)
    self.textColorHovered = Color(200, 200, 240)
    self.inertia = 0
    self.easing = "OutQuint"

    self:SetFont(self.fontDefault)
    self:SetTextColor(self.textColor)
    self:SetContentAlignment(4)
end

function PANEL:SetTextInternal(text)
    BaseClass.SetText(self, text)
end

function PANEL:SetText(text, bNoTranslate, bNoSizeToContents)
    if ( !text ) then return end

    if ( !bNoTranslate and text != "" ) then
        text = ax.localization:GetPhrase(text)
    end

    self:SetTextInternal(text)

    if ( !bNoSizeToContents ) then
        self:SizeToContents()
    end
end

function PANEL:SetTextColorInternal(color)
    BaseClass.SetTextColor(self, color)
end

function PANEL:SetTextColor(color)
    self.textColor = color
    self:SetTextColorInternal(color)
end

function PANEL:SizeToContents()
    BaseClass.SizeToContents(self)

    local width, height = self:GetSize()
    self:SetSize(width + ScreenScale(8), height + ScreenScaleH(8))
end

function PANEL:OnMousePressed(mouseCode)
    if ( mouseCode == MOUSE_LEFT ) then
        if ( self.DoClick ) then
            self:DoClick()
        end
    elseif ( mouseCode == MOUSE_RIGHT ) then
        if ( self.DoRightClick ) then
            self:DoRightClick()
        end
    end

    if ( self.soundClick ) then
        surface.PlaySound(self.soundClick)
    end
end

function PANEL:Think()
    local hovering = self:IsHovered()
    if ( hovering and !self.wasHovered ) then
        surface.PlaySound(self.soundEnter)
        self:SetFont(self.fontHovered)
        self.wasHovered = true

        self:Motion(0.25, {
            Target = {inertia = 1},
            Easing = self.easing,
            Think = function(this)
                self:SetInertia(this.inertia)
            end
        })

        self:Motion(0.25, {
            Target = {textColorMotion = self.textColorHovered},
            Easing = self.easing,
            Think = function(this)
                self:SetTextColorInternal(this.textColorMotion)
            end
        })

        if ( self.OnHovered ) then
            self:OnHovered()
        end
    elseif ( !hovering and self.wasHovered ) then
        self:SetFont(self.fontDefault)
        self.wasHovered = false

        self:Motion(0.25, {
            Target = {inertia = 0},
            Easing = self.easing,
            Think = function(this)
                self:SetInertia(this.inertia)
            end
        })

        self:Motion(0.25, {
            Target = {textColorMotion = self.textColor},
            Easing = self.easing,
            Think = function(this)
                self:SetTextColorInternal(this.textColorMotion)
            end
        })

        if ( self.OnUnHovered ) then
            self:OnUnHovered()
        end
    end

    if ( self.OnThink ) then
        self:OnThink()
    end
end

function PANEL:OnHovered()
    -- Override this method to add custom behavior
end

function PANEL:OnUnHovered()
    -- Override this method to add custom behavior
end

function PANEL:OnThink()
    -- Override this method to add custom behavior
end

function PANEL:Paint()
end

vgui.Register("ax.button.core", PANEL, "DButton")

DEFINE_BASECLASS("ax.button.core")

PANEL = {}

AccessorFunc(PANEL, "baseHeight", "BaseHeight", FORCE_NUMBER)
AccessorFunc(PANEL, "baseHeightMotion", "BaseHeightMotion", FORCE_NUMBER)
AccessorFunc(PANEL, "baseHeightHovered", "BaseHeightHovered", FORCE_NUMBER)
AccessorFunc(PANEL, "textInsetX", "TextInsetX", FORCE_NUMBER)
AccessorFunc(PANEL, "textInsetXMotion", "TextInsetXMotion", FORCE_NUMBER)
AccessorFunc(PANEL, "textInsetXHovered", "TextInsetXHovered", FORCE_NUMBER)
AccessorFunc(PANEL, "textInsetY", "TextInsetY", FORCE_NUMBER)
AccessorFunc(PANEL, "textInsetYMotion", "TextInsetYMotion", FORCE_NUMBER)
AccessorFunc(PANEL, "textInsetYHovered", "TextInsetYHovered", FORCE_NUMBER)

function PANEL:Init()
    BaseClass.Init(self)

    self.baseHeight = ScreenScaleH(20)
    self.baseHeightMotion = ScreenScaleH(20)
    self.baseHeightHovered = ScreenScaleH(20) * 1.25
    self.textInsetX = ScreenScale(2)
    self.textInsetXMotion = 0
    self.textInsetXHovered = ScreenScale(8)
    self.textInsetY = 0
    self.textInsetYMotion = 0
    self.textInsetYHovered = 0

    self:SetTall(self.baseHeight)
    self:SetTextInset(self.textInsetX, self.textInsetY)
end

function PANEL:SetText(text)
    if ( !text ) then return end

    BaseClass.SetText(self, text)

    text = self:GetText()
    text = string.upper(text)

    self:SetTextInternal(text)
end

function PANEL:SizeToContents()
    BaseClass.SizeToContents(self)

    local width, _ = self:GetSize()
    self:SetSize(width + ScreenScale(8), self.baseHeight)
end

function PANEL:Think()
    local hovering = self:IsHovered()
    if ( hovering and !self.wasHovered ) then
        surface.PlaySound(self.soundEnter)
        self:SetFont(self.fontHovered)
        self.wasHovered = true

        self:Motion(0.25, {
            Target = {inertia = 1},
            Easing = self.easing,
            Think = function(this)
                self:SetInertia(this.inertia)
            end
        })

        self:Motion(0.25, {
            Target = {textColorMotion = self.textColorHovered},
            Easing = self.easing,
            Think = function(this)
                self:SetTextColorInternal(this.textColorMotion)
            end
        })

        self:Motion(0.25, {
            Target = {baseHeightMotion = self.baseHeightHovered},
            Easing = self.easing,
            Think = function(this)
                self:SetTall(this.baseHeightMotion)
            end
        })

        self:Motion(0.25, {
            Target = {textInsetXMotion = self.textInsetXHovered, textInsetYMotion = self.textInsetYHovered},
            Easing = self.easing,
            Think = function(this)
                self:SetTextInset(this.textInsetXMotion, this.textInsetYMotion)
            end
        })

        if ( self.OnHovered ) then
            self:OnHovered()
        end
    elseif ( !hovering and self.wasHovered ) then
        self:SetFont(self.fontDefault)
        self.wasHovered = false

        self:Motion(0.25, {
            Target = {inertia = 0},
            Easing = self.easing,
            Think = function(this)
                self:SetInertia(this.inertia)
            end
        })

        self:Motion(0.25, {
            Target = {textColorMotion = self.textColor},
            Easing = self.easing,
            Think = function(this)
                self:SetTextColorInternal(this.textColorMotion)
            end
        })

        self:Motion(0.25, {
            Target = {baseHeightMotion = self.baseHeight},
            Easing = self.easing,
            Think = function(this)
                self:SetTall(this.baseHeightMotion)
            end
        })

        self:Motion(0.25, {
            Target = {textInsetXMotion = self.textInsetX, textInsetYMotion = self.textInsetY},
            Easing = self.easing,
            Think = function(this)
                self:SetTextInset(this.textInsetXMotion, this.textInsetYMotion)
            end
        })

        if ( self.OnUnHovered ) then
            self:OnUnHovered()
        end
    end

    if ( self.OnThink ) then
        self:OnThink()
    end
end

function PANEL:Paint(width, height)
    local backgroundColor = Color(self.textColor.r / 8, self.textColor.g / 8, self.textColor.b / 8)
    draw.RoundedBox(0, 0, 0, width, height, ColorAlpha(backgroundColor, 100 * self.inertia))

    surface.SetDrawColor(self.textColor.r, self.textColor.g, self.textColor.b, 200 * self.inertia)
    surface.DrawRect(0, 0, ScreenScale(4) * self.inertia, height)
end

vgui.Register("ax.button", PANEL, "ax.button.core")

DEFINE_BASECLASS("ax.button.core")

PANEL = {}

AccessorFunc(PANEL, "backgroundColor", "BackgroundColor")
AccessorFunc(PANEL, "backgroundAlpha", "BackgroundAlpha", FORCE_NUMBER)
AccessorFunc(PANEL, "backgroundAlphaHovered", "BackgroundAlphaHovered", FORCE_NUMBER)

function PANEL:Init()
    BaseClass.Init(self)

    self.backgroundColor = Color(255, 255, 255)
    self.backgroundAlphaHovered = 255
    self.backgroundAlphaUnHovered = 0

    self:SetTextColorHovered(Color(0, 0, 0))
    self:SetContentAlignment(5)
end

function PANEL:SetText(text)
    if ( !text ) then return end

    BaseClass.SetText(self, text)

    text = self:GetText()
    text = string.upper(text)

    self:SetTextInternal(text)
end

function PANEL:SizeToContents()
    BaseClass.SizeToContents(self)

    local width, height = self:GetSize()
    self:SetSize(width + ScreenScale(8), height + ScreenScaleH(8))
end

function PANEL:Paint(width, height)
    surface.SetDrawColor(self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b, self.backgroundAlphaHovered * self.inertia)
    surface.DrawRect(0, 0, width, height)
end

vgui.Register("ax.button.flat", PANEL, "ax.button.core")