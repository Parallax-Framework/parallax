local Material = Material
local DisableClipping = DisableClipping
local language = language
local math = math
local derma = derma
local hook = hook
local surface = surface
local Color = Color
local draw = draw

ax.util:AddSound("ax.gui.menu.return", "parallax/ui/pano_menu_return.ogg", 0.25, 100, CHAN_STATIC)
ax.util:AddSound("ax.gui.menu.close", "parallax/ui/pano_menu_close.ogg", 0.25, 100, CHAN_STATIC)

ax.util:AddSound("ax.gui.button.enter", "parallax/ui/pano_rollover.ogg", 0.25, 100, CHAN_STATIC)
ax.util:AddSound("ax.gui.button.click", "parallax/ui/pano_select.ogg", 1, 100, CHAN_STATIC)

SKIN = {}
SKIN.PrintName = "Parallax Dark Mode"
SKIN.Author = "Parallax Framework"
SKIN.DermaVersion = 1

-- Dark purple-ish color scheme
SKIN.bg_alt1 = Color(20, 16, 30, 255)
SKIN.bg_alt2 = Color(25, 20, 35, 255)
SKIN.bg_color = Color(25, 20, 35, 255)
SKIN.bg_color_bright = Color(35, 28, 50, 255)
SKIN.bg_color_dark = Color(15, 12, 22, 255)
SKIN.bg_color_sleep = Color(18, 15, 25, 255)
SKIN.category_header_bg = Color(45, 35, 65, 255)
SKIN.category_header_bg_closed = Color(35, 28, 50, 255)
SKIN.colButtonBorder = Color(60, 45, 85, 255)
SKIN.colButtonBorderHighlight = Color(130, 90, 200, 150)
SKIN.colButtonBorderShadow = Color(0, 0, 0, 180)
SKIN.colButtonText = Color(220, 210, 240, 255)
SKIN.colButtonTextDisabled = Color(100, 90, 120, 255)
SKIN.colCategoryText = Color(250, 245, 255, 255)
SKIN.colCategoryTextInactive = Color(200, 195, 215, 255)
SKIN.colCollapsibleCategory = Color(35, 28, 50, 200)
SKIN.colMenuBG = Color(30, 24, 42, 245)
SKIN.colMenuBorder = Color(60, 45, 85, 255)
SKIN.colNumSliderNotch = Color(80, 60, 110, 150)
SKIN.colNumberWangBG = Color(35, 28, 50, 255)
SKIN.colPropertySheet = Color(35, 28, 50, 255)
SKIN.colTab = SKIN.colPropertySheet
SKIN.colTabInactive = Color(25, 20, 35, 255)
SKIN.colTabShadow = Color(0, 0, 0, 200)
SKIN.colTabText = Color(250, 245, 255, 255)
SKIN.colTabTextInactive = Color(200, 195, 215, 255)
SKIN.colTextEntryBG = Color(30, 24, 42, 255)
SKIN.colTextEntryBorder = Color(60, 45, 85, 255)
SKIN.colTextEntryText = Color(220, 210, 240, 255)
SKIN.colTextEntryTextCursor = Color(180, 140, 255, 255)
SKIN.colTextEntryTextHighlight = Color(130, 90, 200, 255)
SKIN.colTextEntryTextPlaceholder = Color(120, 110, 140, 255)
SKIN.combobox_selected = SKIN.listview_selected
SKIN.control_color = Color(80, 60, 110, 255)
SKIN.control_color_active = Color(130, 90, 200, 255)
SKIN.control_color_bright = Color(150, 110, 220, 255)
SKIN.control_color_dark = Color(50, 40, 70, 255)
SKIN.control_color_highlight = Color(110, 85, 150, 255)
SKIN.fontCategoryHeader = "ax.regular"
SKIN.fontFrame = "ax.small"
SKIN.fontTab = "ax.small"
SKIN.frame_border = Color(60, 45, 85, 255)
SKIN.listview_hover = Color(45, 35, 65, 255)
SKIN.listview_selected = Color(100, 70, 150, 255)
SKIN.panel_transback = Color(25, 20, 35, 150)
SKIN.tab_bg_active = Color(70, 50, 100, 255)
SKIN.tab_bg_inactive = Color(35, 25, 50, 255)
SKIN.texGradientDown = Material("gui/gradient_down")
SKIN.texGradientUp = Material("gui/gradient_up")
SKIN.text_bright = Color(240, 235, 250, 255)
SKIN.text_dark = Color(120, 110, 140, 255)
SKIN.text_highlight = Color(180, 120, 255, 255)
SKIN.text_normal = Color(200, 195, 215, 255)
SKIN.tooltip = Color(45, 35, 65, 245)
SKIN.tree_bg_hover = Color(45, 35, 65, 255)
SKIN.tree_bg_normal = Color(25, 20, 35, 255)
SKIN.tree_bg_selected = Color(100, 70, 150, 255)

-- Helper functions for drawing UI elements
local function DrawBorderedBox(x, y, w, h, bg, border, borderSize)
    borderSize = borderSize or 1
    --ax.util:DrawBlur(0, x, y, w, h, color_white)
    ax.render.Draw(0, x, y, w, h, Color(border.r, border.g, border.b, border.a))
    ax.render.Draw(0, x + borderSize, y + borderSize, w - borderSize * 2, h - borderSize * 2, Color(bg.r, bg.g, bg.b, bg.a))
end

local function DrawRoundedBox(x, y, w, h, color, cornerRadius)
    cornerRadius = cornerRadius or 4
    --ax.util:DrawBlur(cornerRadius, x, y, w, h, color_white)
    ax.render.Draw(cornerRadius, x, y, w, h, color)
end

local function DrawArrow(x, y, size, dir, color)
    surface.SetDrawColor(color.r, color.g, color.b, color.a)
    local points = {}
    if dir == "down" then
        points = {
            {
                x = x,
                y = y
            },
            {
                x = x + size,
                y = y
            },
            {
                x = x + size / 2,
                y = y + size
            }
        }
    elseif dir == "up" then
        points = {
            {
                x = x,
                y = y + size
            },
            {
                x = x + size,
                y = y + size
            },
            {
                x = x + size / 2,
                y = y
            }
        }
    elseif dir == "right" then
        points = {
            {
                x = x,
                y = y
            },
            {
                x = x,
                y = y + size
            },
            {
                x = x + size,
                y = y + size / 2
            }
        }
    elseif dir == "left" then
        points = {
            {
                x = x + size,
                y = y
            },
            {
                x = x + size,
                y = y + size
            },
            {
                x = x,
                y = y + size / 2
            }
        }
    end

    surface.DrawPoly(points)
end

SKIN.Colours = {}
SKIN.Colours.Button = {}
SKIN.Colours.Button.Disabled = Color(40, 32, 55, 255)
SKIN.Colours.Button.Down = Color(130, 90, 200, 255)
SKIN.Colours.Button.Hover = Color(100, 75, 140, 255)
SKIN.Colours.Button.Normal = Color(70, 55, 100, 255)

-- NOTE:
-- Derma uses SKIN.Colours.Button for button label text colors.
-- Keep a separate set for button backgrounds so we can brighten labels
-- without washing out fills.
SKIN.Colours.ButtonBG = {}
SKIN.Colours.ButtonBG.Disabled = SKIN.Colours.Button.Disabled
SKIN.Colours.ButtonBG.Down = SKIN.Colours.Button.Down
SKIN.Colours.ButtonBG.Hover = SKIN.Colours.Button.Hover
SKIN.Colours.ButtonBG.Normal = SKIN.Colours.Button.Normal

-- Brightened button label text colors.
SKIN.Colours.Button.Disabled = Color(130, 120, 150, 255)
SKIN.Colours.Button.Down = Color(180, 120, 255, 255)
SKIN.Colours.Button.Hover = Color(250, 245, 255, 255)
SKIN.Colours.Button.Normal = Color(220, 210, 240, 255)
SKIN.Colours.Category = {}
SKIN.Colours.Category.Header = Color(250, 245, 255, 255)
SKIN.Colours.Category.Header_Closed = Color(240, 235, 250, 255)
SKIN.Colours.Category.Line = {}
SKIN.Colours.Category.Line.Button = Color(70, 55, 100, 255)
SKIN.Colours.Category.Line.Button_Disabled = Color(40, 32, 55, 255)
SKIN.Colours.Category.Line.Button_Hover = Color(100, 75, 140, 255)
SKIN.Colours.Category.Line.Button_Selected = Color(130, 90, 200, 255)
SKIN.Colours.Category.Line.Text = Color(240, 235, 250, 255)
SKIN.Colours.Category.Line.Text_Disabled = Color(150, 140, 170, 255)
SKIN.Colours.Category.Line.Text_Hover = Color(250, 245, 255, 255)
SKIN.Colours.Category.Line.Text_Selected = Color(255, 250, 255, 255)
SKIN.Colours.Category.LineAlt = {}
SKIN.Colours.Category.LineAlt.Button = Color(65, 50, 90, 255)
SKIN.Colours.Category.LineAlt.Button_Disabled = Color(38, 30, 52, 255)
SKIN.Colours.Category.LineAlt.Button_Hover = Color(95, 70, 130, 255)
SKIN.Colours.Category.LineAlt.Button_Selected = Color(125, 85, 190, 255)
SKIN.Colours.Category.LineAlt.Text = Color(240, 235, 250, 255)
SKIN.Colours.Category.LineAlt.Text_Disabled = Color(150, 140, 170, 255)
SKIN.Colours.Category.LineAlt.Text_Hover = Color(250, 245, 255, 255)
SKIN.Colours.Category.LineAlt.Text_Selected = Color(255, 250, 255, 255)
SKIN.Colours.Label = {}
SKIN.Colours.Label.Bright = Color(255, 250, 255, 255)
SKIN.Colours.Label.Dark = Color(240, 235, 250, 255)
SKIN.Colours.Label.Default = Color(240, 235, 250, 255)
SKIN.Colours.Label.Highlight = Color(180, 120, 255, 255)
SKIN.Colours.Properties = {}
SKIN.Colours.Properties.Border = Color(60, 45, 85, 255)
SKIN.Colours.Properties.Column_Disabled = Color(40, 32, 55, 255)
SKIN.Colours.Properties.Column_Hover = Color(45, 35, 65, 255)
SKIN.Colours.Properties.Column_Normal = Color(30, 24, 42, 255)
SKIN.Colours.Properties.Column_Selected = Color(100, 70, 150, 255)
SKIN.Colours.Properties.Label_Disabled = Color(150, 140, 170, 255)
SKIN.Colours.Properties.Label_Hover = Color(250, 240, 255, 255)
SKIN.Colours.Properties.Label_Normal = Color(240, 235, 250, 255)
SKIN.Colours.Properties.Label_Selected = Color(255, 250, 255, 255)
SKIN.Colours.Properties.Line_Hover = Color(45, 35, 65, 255)
SKIN.Colours.Properties.Line_Normal = Color(25, 20, 35, 255)
SKIN.Colours.Properties.Line_Selected = Color(100, 70, 150, 255)
SKIN.Colours.Properties.Title = Color(60, 45, 85, 255)
SKIN.Colours.Tab = {}
SKIN.Colours.Tab.Active = {}
SKIN.Colours.Tab.Active.Disabled = Color(120, 110, 140, 255)
SKIN.Colours.Tab.Active.Down = Color(180, 120, 255, 255)
SKIN.Colours.Tab.Active.Hover = Color(250, 245, 255, 255)
SKIN.Colours.Tab.Active.Normal = Color(240, 235, 250, 255)
SKIN.Colours.Tab.Inactive = {}
SKIN.Colours.Tab.Inactive.Disabled = Color(100, 90, 120, 255)
SKIN.Colours.Tab.Inactive.Down = Color(150, 100, 220, 255)
SKIN.Colours.Tab.Inactive.Hover = Color(230, 225, 245, 255)
SKIN.Colours.Tab.Inactive.Normal = Color(200, 195, 215, 255)
SKIN.Colours.TooltipText = Color(220, 210, 240, 255)
SKIN.Colours.Tree = {}
SKIN.Colours.Tree.Hover = Color(250, 245, 255, 255)
SKIN.Colours.Tree.Lines = Color(140, 120, 180, 255)
SKIN.Colours.Tree.Normal = Color(240, 235, 250, 255)
SKIN.Colours.Tree.Selected = Color(180, 120, 255, 255)
SKIN.Colours.Window = {}
SKIN.Colours.Window.TitleActive = Color(130, 90, 200, 255)
SKIN.Colours.Window.TitleInactive = Color(60, 45, 85, 255)

--[[---------------------------------------------------------
	Panel
-----------------------------------------------------------]]
function SKIN:PaintPanel(panel, w, h)
    if not panel.m_bBackground then return end
    local bgColor = panel.m_bgColor or self.bg_color
    DrawRoundedBox(0, 0, w, h, bgColor, 4)
end

--[[---------------------------------------------------------
	Panel Shadow
-----------------------------------------------------------]]
function SKIN:PaintShadow(panel, w, h)
    local shadowColor = Color(0, 0, 0, 80)
    DrawRoundedBox(0, 0, w, h, shadowColor, 4)
end

--[[---------------------------------------------------------
	Frame
-----------------------------------------------------------]]
function SKIN:PaintFrame(panel, w, h)
    if panel.m_bPaintShadow then
        local wasEnabled = DisableClipping(true)
        local shadowColor = Color(0, 0, 0, 100)
        for i = 1, 4 do
            surface.SetDrawColor(shadowColor.r, shadowColor.g, shadowColor.b, shadowColor.a / i)
            surface.DrawOutlinedRect(-i, -i, w + i * 2, h + i * 2, i)
        end

        DisableClipping(wasEnabled)
    end

    local titleCol = panel:HasHierarchicalFocus() and self.Colours.Window.TitleActive or self.Colours.Window.TitleInactive
    DrawBorderedBox(0, 0, w, h, self.bg_color, self.frame_border, 1)
    DrawRoundedBox(1, 1, w - 2, 24, titleCol, 0)
end

--[[---------------------------------------------------------
	Button
-----------------------------------------------------------]]
function SKIN:PaintButton(panel, w, h)
    if not panel.m_bBackground then return end
    local col
    if panel.Depressed or panel:IsSelected() or panel:GetToggle() then
        col = self.Colours.ButtonBG.Down
    elseif not panel:IsEnabled() then
        col = self.Colours.ButtonBG.Disabled
    elseif panel.Hovered then
        col = self.Colours.ButtonBG.Hover
    else
        col = self.Colours.ButtonBG.Normal
    end

    DrawBorderedBox(0, 0, w, h, col, self.colButtonBorder, 1)
end

--[[---------------------------------------------------------
	Tree
-----------------------------------------------------------]]
function SKIN:PaintTree(panel, w, h)
    if not panel.m_bBackground then return end
    local bgColor = panel.m_bgColor or self.tree_bg_normal
    DrawRoundedBox(0, 0, w, h, bgColor, 4)
end

--[[---------------------------------------------------------
	CheckBox
-----------------------------------------------------------]]
function SKIN:PaintCheckBox(panel, w, h)
    local enabled = panel:IsEnabled()
    local checked = panel:GetChecked()
    local bg = enabled and Color(30, 24, 42, 255) or Color(20, 16, 30, 255)
    local border = enabled and Color(80, 60, 110, 255) or Color(50, 40, 70, 255)
    DrawBorderedBox(0, 0, w, h, bg, border, 1)
    if checked then
        local checkColor = enabled and Color(130, 90, 200, 255) or Color(80, 60, 110, 255)
        surface.SetDrawColor(checkColor.r, checkColor.g, checkColor.b, checkColor.a)
        surface.DrawLine(3, h / 2, w / 2, h - 3)
        surface.DrawLine(w / 2, h - 3, w - 3, 3)
        surface.DrawLine(4, h / 2, w / 2 + 1, h - 3)
        surface.DrawLine(w / 2 + 1, h - 3, w - 2, 3)
    end
end

--[[---------------------------------------------------------
	RadioButton
-----------------------------------------------------------]]
function SKIN:PaintRadioButton(panel, w, h)
    local enabled = panel:IsEnabled()
    local checked = panel:GetChecked()
    local bg = enabled and Color(30, 24, 42, 255) or Color(20, 16, 30, 255)
    local border = enabled and Color(80, 60, 110, 255) or Color(50, 40, 70, 255)
    surface.SetDrawColor(border.r, border.g, border.b, border.a)
    draw.NoTexture()
    surface.DrawCircle(w / 2, h / 2, w / 2, border.r, border.g, border.b, border.a)
    surface.SetDrawColor(bg.r, bg.g, bg.b, bg.a)
    surface.DrawCircle(w / 2, h / 2, w / 2 - 1, bg.r, bg.g, bg.b, bg.a)
    if checked then
        local checkColor = enabled and Color(130, 90, 200, 255) or Color(80, 60, 110, 255)
        surface.SetDrawColor(checkColor.r, checkColor.g, checkColor.b, checkColor.a)
        surface.DrawCircle(w / 2, h / 2, w / 2 - 3, checkColor.r, checkColor.g, checkColor.b, checkColor.a)
    end
end

--[[---------------------------------------------------------
	ExpandButton
-----------------------------------------------------------]]
function SKIN:PaintExpandButton(panel, w, h)
    local col = self.text_normal
    if not panel:GetExpanded() then
        DrawArrow(w / 2 - 4, h / 2 - 4, 8, "right", col)
    else
        DrawArrow(w / 2 - 4, h / 2 - 4, 8, "down", col)
    end
end

--[[---------------------------------------------------------
	TextEntry
-----------------------------------------------------------]]
function SKIN:PaintTextEntry(panel, w, h)
    if panel.m_bBackground then
        local bg, border
        if not panel:IsEnabled() then
            bg = Color(20, 16, 30, 255)
            border = Color(50, 40, 70, 255)
        elseif panel:HasFocus() then
            bg = self.colTextEntryBG
            border = self.control_color_active
        else
            bg = self.colTextEntryBG
            border = self.colTextEntryBorder
        end

        DrawBorderedBox(0, 0, w, h, bg, border, 1)
    end

    -- Placeholder text handling
    if panel.GetPlaceholderText and panel.GetPlaceholderColor and panel:GetPlaceholderText() and panel:GetPlaceholderText():Trim() ~= "" and panel:GetPlaceholderColor() and (not panel:GetText() or panel:GetText() == "") then
        local oldText = panel:GetText()
        local str = panel:GetPlaceholderText()
        if str:StartsWith("#") then str = str:sub(2) end
        str = language.GetPhrase(str)
        panel:SetText(str)
        panel:DrawTextEntryText(panel:GetPlaceholderColor(), panel:GetHighlightColor(), panel:GetCursorColor())
        panel:SetText(oldText)
        return
    end

    panel:DrawTextEntryText(panel:GetTextColor(), panel:GetHighlightColor(), panel:GetCursorColor())
end

--[[---------------------------------------------------------
	Menu
-----------------------------------------------------------]]
function SKIN:PaintMenu(panel, w, h)
    DrawBorderedBox(0, 0, w, h, self.colMenuBG, self.colMenuBorder, 1)
end

--[[---------------------------------------------------------
	Menu Spacer
-----------------------------------------------------------]]
function SKIN:PaintMenuSpacer(panel, w, h)
    surface.SetDrawColor(60, 45, 85, 255)
    surface.DrawRect(0, 0, w, h)
end

--[[---------------------------------------------------------
	MenuOption
-----------------------------------------------------------]]
function SKIN:PaintMenuOption(panel, w, h)
    if panel.m_bBackground and not panel:IsEnabled() then
        surface.SetDrawColor(0, 0, 0, 80)
        surface.DrawRect(0, 0, w, h)
    end

    if panel.m_bBackground and panel:IsEnabled() and (panel.Hovered or panel.Highlight) then
        surface.SetDrawColor(45, 35, 65, 255)
        surface.DrawRect(0, 0, w, h)
    end

    if panel:GetRadio() then
        self:PaintRadioButton({
            GetChecked = function() return panel:GetChecked() end,
            IsEnabled = function() return panel:IsEnabled() end
        }, 15, 15)
    else
        if panel:GetChecked() then
            local checkColor = panel:IsEnabled() and Color(130, 90, 200, 255) or Color(80, 60, 110, 255)
            surface.SetDrawColor(checkColor.r, checkColor.g, checkColor.b, checkColor.a)
            surface.DrawLine(5 + 3, h / 2, 5 + 7, h / 2 + 4)
            surface.DrawLine(5 + 7, h / 2 + 4, 5 + 12, h / 2 - 4)
        end
    end
end

--[[---------------------------------------------------------
	MenuRightArrow
-----------------------------------------------------------]]
function SKIN:PaintMenuRightArrow(panel, w, h)
    DrawArrow(w / 2 - 3, h / 2 - 3, 6, "right", self.text_normal)
end

--[[---------------------------------------------------------
	PropertySheet
-----------------------------------------------------------]]
function SKIN:PaintPropertySheet(panel, w, h)
    local ActiveTab = panel:GetActiveTab()
    local Offset = 0
    if ActiveTab then Offset = ActiveTab:GetTall() - 8 end
    DrawBorderedBox(0, Offset, w, h - Offset, self.bg_color, self.frame_border, 1)
end

--[[---------------------------------------------------------
	Tab
-----------------------------------------------------------]]
function SKIN:PaintTab(panel, w, h)
    if panel:IsActive() then return self:PaintActiveTab(panel, w, h) end
    DrawRoundedBox(0, 0, w, h, self.tab_bg_inactive, 4)
end

function SKIN:PaintActiveTab(panel, w, h)
    DrawRoundedBox(0, 0, w, h, self.tab_bg_active, 4)
end

--[[---------------------------------------------------------
	Window Control Buttons
-----------------------------------------------------------]]
function SKIN:PaintWindowCloseButton(panel, w, h)
    if not panel.m_bBackground then return end
    local col
    if not panel:IsEnabled() then
        col = Color(255, 100, 100, 50)
    elseif panel.Depressed or panel:IsSelected() then
        col = Color(220, 50, 50, 255)
    elseif panel.Hovered then
        col = Color(255, 80, 80, 255)
    else
        col = Color(180, 60, 60, 200)
    end

    DrawRoundedBox(0, 0, w, h, col, 2)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawLine(w / 4, h / 4, w - w / 4, h - h / 4)
    surface.DrawLine(w - w / 4, h / 4, w / 4, h - h / 4)
end

function SKIN:PaintWindowMinimizeButton(panel, w, h)
    if not panel.m_bBackground then return end
    local col
    if not panel:IsEnabled() then
        col = self.Colours.ButtonBG.Disabled
    elseif panel.Depressed or panel:IsSelected() then
        col = self.Colours.ButtonBG.Down
    elseif panel.Hovered then
        col = self.Colours.ButtonBG.Hover
    else
        col = self.Colours.ButtonBG.Normal
    end

    DrawRoundedBox(0, 0, w, h, col, 2)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawRect(w / 4, h - h / 3, w - w / 2, 2)
end

function SKIN:PaintWindowMaximizeButton(panel, w, h)
    if not panel.m_bBackground then return end
    local col
    if not panel:IsEnabled() then
        col = self.Colours.ButtonBG.Disabled
    elseif panel.Depressed or panel:IsSelected() then
        col = self.Colours.ButtonBG.Down
    elseif panel.Hovered then
        col = self.Colours.ButtonBG.Hover
    else
        col = self.Colours.ButtonBG.Normal
    end

    DrawRoundedBox(0, 0, w, h, col, 2)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawOutlinedRect(w / 4, h / 4, w - w / 2, h - h / 2, 1)
end

--[[---------------------------------------------------------
	VScrollBar
-----------------------------------------------------------]]
function SKIN:PaintVScrollBar(panel, w, h)
    DrawRoundedBox(0, 0, w, h, Color(20, 16, 30, 255), 2)
end

--[[---------------------------------------------------------
	HScrollBar
-----------------------------------------------------------]]
function SKIN:PaintHScrollBar(panel, w, h)
    DrawRoundedBox(0, 0, w, h, Color(20, 16, 30, 255), 2)
end

--[[---------------------------------------------------------
	ScrollBarGrip
-----------------------------------------------------------]]
function SKIN:PaintScrollBarGrip(panel, w, h)
    local col
    if not panel:IsEnabled() then
        col = self.Colours.ButtonBG.Disabled
    elseif panel.Depressed then
        col = self.Colours.ButtonBG.Down
    elseif panel.Hovered then
        col = self.Colours.ButtonBG.Hover
    else
        col = self.Colours.ButtonBG.Normal
    end

    DrawRoundedBox(0, 0, w, h, col, 2)
end

--[[---------------------------------------------------------
	Scroller Button Down
-----------------------------------------------------------]]
function SKIN:PaintButtonDown(panel, w, h)
    if not panel.m_bBackground then return end
    local col
    if panel.Depressed or panel:IsSelected() then
        col = self.Colours.ButtonBG.Down
    elseif not panel:IsEnabled() then
        col = self.Colours.ButtonBG.Disabled
    elseif panel.Hovered then
        col = self.Colours.ButtonBG.Hover
    else
        col = self.Colours.ButtonBG.Normal
    end

    DrawRoundedBox(0, 0, w, h, col, 2)
    DrawArrow(w / 2 - 3, h / 2 - 3, 6, "down", self.text_normal)
end

--[[---------------------------------------------------------
	Scroller Button Up
-----------------------------------------------------------]]
function SKIN:PaintButtonUp(panel, w, h)
    if not panel.m_bBackground then return end
    local col
    if panel.Depressed or panel:IsSelected() then
        col = self.Colours.ButtonBG.Down
    elseif not panel:IsEnabled() then
        col = self.Colours.ButtonBG.Disabled
    elseif panel.Hovered then
        col = self.Colours.ButtonBG.Hover
    else
        col = self.Colours.ButtonBG.Normal
    end

    DrawRoundedBox(0, 0, w, h, col, 2)
    DrawArrow(w / 2 - 3, h / 2 - 3, 6, "up", self.text_normal)
end

--[[---------------------------------------------------------
	Scroller Button Left
-----------------------------------------------------------]]
function SKIN:PaintButtonLeft(panel, w, h)
    if not panel.m_bBackground then return end
    local col
    if panel.Depressed or panel:IsSelected() then
        col = self.Colours.ButtonBG.Down
    elseif not panel:IsEnabled() then
        col = self.Colours.ButtonBG.Disabled
    elseif panel.Hovered then
        col = self.Colours.ButtonBG.Hover
    else
        col = self.Colours.ButtonBG.Normal
    end

    DrawRoundedBox(0, 0, w, h, col, 2)
    DrawArrow(w / 2 - 3, h / 2 - 3, 6, "left", self.text_normal)
end

--[[---------------------------------------------------------
	Scroller Button Right
-----------------------------------------------------------]]
function SKIN:PaintButtonRight(panel, w, h)
    if not panel.m_bBackground then return end
    local col
    if panel.Depressed or panel:IsSelected() then
        col = self.Colours.ButtonBG.Down
    elseif not panel:IsEnabled() then
        col = self.Colours.ButtonBG.Disabled
    elseif panel.Hovered then
        col = self.Colours.ButtonBG.Hover
    else
        col = self.Colours.ButtonBG.Normal
    end

    DrawRoundedBox(0, 0, w, h, col, 2)
    DrawArrow(w / 2 - 3, h / 2 - 3, 6, "right", self.text_normal)
end

--[[---------------------------------------------------------
	ComboDownArrow
-----------------------------------------------------------]]
function SKIN:PaintComboDownArrow(panel, w, h)
    local col
    if not panel.ComboBox:IsEnabled() then
        col = self.Colours.ButtonBG.Disabled
    elseif panel.ComboBox.Depressed or panel.ComboBox:IsMenuOpen() then
        col = self.Colours.ButtonBG.Down
    elseif panel.ComboBox.Hovered then
        col = self.Colours.ButtonBG.Hover
    else
        col = self.Colours.ButtonBG.Normal
    end

    DrawRoundedBox(0, 0, w, h, col, 0)
    DrawArrow(w / 2 - 4, h / 2 - 2, 8, "down", self.text_normal)
end

--[[---------------------------------------------------------
	ComboBox
-----------------------------------------------------------]]
function SKIN:PaintComboBox(panel, w, h)
    local bg, border
    if not panel:IsEnabled() then
        bg = Color(20, 16, 30, 255)
        border = Color(50, 40, 70, 255)
    elseif panel.Depressed or panel:IsMenuOpen() then
        bg = self.colTextEntryBG
        border = self.control_color_active
    elseif panel.Hovered then
        bg = self.colTextEntryBG
        border = self.control_color_highlight
    else
        bg = self.colTextEntryBG
        border = self.colTextEntryBorder
    end

    DrawBorderedBox(0, 0, w, h, bg, border, 1)
end

--[[---------------------------------------------------------
	ListBox
-----------------------------------------------------------]]
function SKIN:PaintListBox(panel, w, h)
    DrawBorderedBox(0, 0, w, h, self.bg_color_dark, self.colTextEntryBorder, 1)
end

--[[---------------------------------------------------------
	NumberUp
-----------------------------------------------------------]]
function SKIN:PaintNumberUp(panel, w, h)
    local col
    if not panel:IsEnabled() then
        col = self.Colours.ButtonBG.Disabled
    elseif panel.Depressed then
        col = self.Colours.ButtonBG.Down
    elseif panel.Hovered then
        col = self.Colours.ButtonBG.Hover
    else
        col = self.Colours.ButtonBG.Normal
    end

    DrawRoundedBox(0, 0, w, h, col, 2)
    DrawArrow(w / 2 - 3, h / 2 - 2, 6, "up", self.text_normal)
end

--[[---------------------------------------------------------
	NumberDown
-----------------------------------------------------------]]
function SKIN:PaintNumberDown(panel, w, h)
    local col
    if not panel:IsEnabled() then
        col = self.Colours.ButtonBG.Disabled
    elseif panel.Depressed then
        col = self.Colours.ButtonBG.Down
    elseif panel.Hovered then
        col = self.Colours.ButtonBG.Hover
    else
        col = self.Colours.ButtonBG.Normal
    end

    DrawRoundedBox(0, 0, w, h, col, 2)
    DrawArrow(w / 2 - 3, h / 2 - 1, 6, "down", self.text_normal)
end

function SKIN:PaintTreeNode(panel, w, h)
    if not panel.m_bDrawLines then return end
    local skinColor = self.Colours.Tree.Lines
    surface.SetDrawColor(skinColor.r, skinColor.g, skinColor.b, skinColor.a)
    if panel.m_bLastChild then
        surface.DrawRect(9, 0, 1, 7)
        surface.DrawRect(9, 7, 9, 1)
    else
        surface.DrawRect(9, 0, 1, h)
        surface.DrawRect(9, 7, 9, 1)
    end
end

function SKIN:PaintTreeNodeButton(panel, w, h)
    if not panel.m_bSelected then return end
    local panelW, _ = panel:GetTextSize()
    surface.SetDrawColor(100, 70, 150, 100)
    surface.DrawRect(38, 0, panelW + 6, h)
end

function SKIN:PaintSelection(panel, w, h)
    surface.SetDrawColor(100, 70, 150, 100)
    surface.DrawRect(0, 0, w, h)
end

function SKIN:PaintSliderKnob(panel, w, h)
    local col
    if not panel:IsEnabled() then
        col = self.Colours.ButtonBG.Disabled
    elseif panel.Depressed then
        col = self.Colours.ButtonBG.Down
    elseif panel.Hovered then
        col = self.Colours.ButtonBG.Hover
    else
        col = self.Colours.ButtonBG.Normal
    end

    DrawRoundedBox(0, 0, w, h, col, 3)
end

local function PaintNotches(x, y, w, h, num)
    if not num then return end
    local space = w / num
    if space < 2 then
        space = 2
        num = w / space
    end

    for i = 0, math.ceil(num) do
        surface.DrawRect(x + i * space, y + 4, 1, 5)
    end
end

function SKIN:PaintNumSlider(panel, w, h)
    local notchColor = panel:GetNotchColor()
    surface.SetDrawColor(notchColor.r, notchColor.g, notchColor.b, notchColor.a)
    surface.DrawRect(8, h / 2 - 1, w - 15, 1)
    PaintNotches(8, h / 2 - 1, w - 16, 1, panel:GetNotches())
end

function SKIN:PaintProgress(panel, w, h)
    DrawBorderedBox(0, 0, w, h, self.bg_color_dark, self.frame_border, 1)
    local progressCol = Color(130, 90, 200, 255)
    DrawRoundedBox(2, 2, (w - 4) * panel:GetFraction(), h - 4, progressCol, 2)
end

function SKIN:PaintCollapsibleCategory(panel, w, h)
    if h <= panel:GetHeaderHeight() then
        DrawRoundedBox(0, 0, w, h, self.category_header_bg, 4)
        if not panel:GetExpanded() then DrawArrow(w - 14, h / 2 - 4, 8, "down", self.text_normal) end
        return
    end

    DrawRoundedBox(0, 0, w, panel:GetHeaderHeight(), self.category_header_bg, 4)
    DrawRoundedBox(0, panel:GetHeaderHeight(), w, h - panel:GetHeaderHeight(), self.bg_color, 0)
end

function SKIN:PaintCategoryList(panel, w, h)
    local bgColor = panel:GetBackgroundColor() or self.bg_color
    DrawBorderedBox(0, 0, w, h, bgColor, self.frame_border, 1)
end

function SKIN:PaintCategoryButton(panel, w, h)
    local skinColor
    if panel.AltLine then
        if not panel:IsEnabled() then
            skinColor = self.Colours.Category.LineAlt.Button_Disabled
        elseif panel.Depressed or panel.m_bSelected then
            skinColor = self.Colours.Category.LineAlt.Button_Selected
        elseif panel.Hovered then
            skinColor = self.Colours.Category.LineAlt.Button_Hover
        else
            skinColor = self.Colours.Category.LineAlt.Button
        end
    else
        if not panel:IsEnabled() then
            skinColor = self.Colours.Category.Line.Button_Disabled
        elseif panel.Depressed or panel.m_bSelected then
            skinColor = self.Colours.Category.Line.Button_Selected
        elseif panel.Hovered then
            skinColor = self.Colours.Category.Line.Button_Hover
        else
            skinColor = self.Colours.Category.Line.Button
        end
    end

    surface.SetDrawColor(skinColor.r, skinColor.g, skinColor.b, skinColor.a)
    surface.DrawRect(0, 0, w, h)
end

function SKIN:PaintListViewLine(panel, w, h)
    if panel:IsSelected() then
        surface.SetDrawColor(100, 70, 150, 255)
        surface.DrawRect(0, 0, w, h)
    elseif panel.Hovered then
        surface.SetDrawColor(45, 35, 65, 255)
        surface.DrawRect(0, 0, w, h)
    elseif panel.m_bAlt then
        surface.SetDrawColor(20, 16, 30, 255)
        surface.DrawRect(0, 0, w, h)
    end
end

function SKIN:PaintListView(panel, w, h)
    if not panel.m_bBackground then return end
    DrawBorderedBox(0, 0, w, h, self.bg_color_dark, self.colTextEntryBorder, 1)
end

function SKIN:PaintTooltip(panel, w, h)
    DrawBorderedBox(0, 0, w, h, self.tooltip, Color(80, 60, 110, 255), 1)
end

function SKIN:PaintMenuBar(panel, w, h)
    DrawRoundedBox(0, 0, w, h, Color(30, 24, 42, 255), 0)
end

derma.DefineSkin("Parallax", "Parallax Dark Mode skin with purple accents", SKIN)
hook.Add("ForceDermaSkin", "SetDefaultDermaSkin", function() return "Parallax" end)
