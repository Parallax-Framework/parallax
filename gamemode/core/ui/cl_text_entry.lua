DEFINE_BASECLASS("DTextEntry")

local PANEL = {}

function PANEL:Init()
    self:SetFont("parallax")
    self:SetTextColor(ax.color:Get("text.light"))
    self:SetPaintBackground(false)
    self:SetUpdateOnType(true)
    self:SetCursorColor(ax.color:Get("text.light"))
    self:SetHighlightColor(ax.color:Get("text.light"))

    self:SetTall(ScreenScale(12))
end

function PANEL:SizeToContents()
    BaseClass.SizeToContents(self)

    local width, height = self:GetSize()
    self:SetSize(width + 8, height + 4)
end

function PANEL:Paint(width, height)
    surface.SetDrawColor(ax.color:Get("background.transparent"))
    surface.DrawRect(0, 0, width, height
)
    BaseClass.Paint(self, width, height)
end


vgui.Register("ax.text.entry", PANEL, "DTextEntry")