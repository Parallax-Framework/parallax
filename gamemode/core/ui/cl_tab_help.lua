DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)
    self:InvalidateParent(true)

    local title = self:Add("ax.text")
    title:Dock(TOP)
    title:SetFont("parallax.title")
    title:SetText("HELP")

    self.buttons = self:Add("ax.scroller.horizontal")
    self.buttons:Dock(TOP)
    self.buttons:DockMargin(0, ScreenScaleH(4), 0, 0)
    self.buttons:SetTall(ScreenScaleH(24))
    self.buttons.Paint = nil

    self.buttons.btnLeft:SetAlpha(0)
    self.buttons.btnRight:SetAlpha(0)

    self.container = self:Add("EditablePanel")
    self.container:Dock(FILL)
    self.container:InvalidateParent(true)
    self.container.Paint = nil

    local categories = {}
    hook.Run("PopulateHelpCategories", categories)
    for k, v in SortedPairs(categories) do
        local button = self.buttons:Add("ax.button.small")
        button:Dock(LEFT)
        button:SetText(k)
        button:SizeToContents()

        button.DoClick = function()
            ax.gui.helpLast = k

            self:Populate(v)
        end

        self.buttons:AddPanel(button)
    end

    for k, v in SortedPairs(categories) do
        if ( ax.gui.helpLast ) then
            if ( ax.gui.helpLast == k ) then
                self:Populate(v)
                break
            end
        else
            self:Populate(v)
            break
        end
    end
end

function PANEL:Populate(data)
    if ( !data ) then return end

    self.container:Clear()

    if ( istable(data) ) then
        if ( isfunction(data.Populate) ) then
            data:Populate(self.container)
        end

        if ( data.OnClose ) then
            self:CallOnRemove("ax.tab.help." .. data.name, function()
                data.OnClose()
            end)
        end
    elseif ( isfunction(data) ) then
        data(self.container)
    end
end

vgui.Register("ax.tab.help", PANEL, "EditablePanel")

ax.gui.helpLast = nil