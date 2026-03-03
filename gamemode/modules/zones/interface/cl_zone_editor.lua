--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("ax.frame")

local PANEL = {}

local GLASS_FLAGS = ax.render.SHAPE_IOS
local GLASS_HEADER_FLAGS = bit.bor(GLASS_FLAGS, ax.render.NO_BL, ax.render.NO_BR)

local FRAME_MARGIN = 12
local FRAME_MAX_HEIGHT = 980
local SECTION_PADDING = 12
local EMPTY_LIST_HEIGHT = 18

local function Phrase(key, ...)
    return ax.localization:GetPhrase(key, ...)
end

local function GetSourceLabel(source)
    local key = "zones.source." .. string.lower(tostring(source or "runtime"))

    return Phrase(key)
end

local function GetValueTypeLabel(valueType)
    local key = "zones.value_type." .. string.lower(tostring(valueType or "unknown"))

    return Phrase(key)
end

local function AddHeader(parent, title, subtitle)
    local header = parent:Add("DPanel")
    header:Dock(TOP)
    header:SetPaintBackground(false)

    local titleLabel = header:Add("ax.text")
    titleLabel:Dock(TOP)
    titleLabel:SetFont("ax.small.bold")
    titleLabel:SetTextColor(color_white)
    titleLabel:SetText(Phrase(title), true)

    local subtitleLabel = header:Add("ax.text")
    subtitleLabel:Dock(TOP)
    subtitleLabel:SetFont("ax.small")
    subtitleLabel:SetTextColor(Color(210, 210, 210, 200))
    subtitleLabel:SetText(subtitle and Phrase(subtitle) or "", true)

    header:SetTall(titleLabel:GetTall() + subtitleLabel:GetTall())

    return header
end

local function AddSection(parent, title, subtitle, height)
    local section = parent:Add("DPanel")
    section:Dock(TOP)
    section:DockMargin(0, 0, 0, 12)
    section:DockPadding(SECTION_PADDING, SECTION_PADDING, SECTION_PADDING, SECTION_PADDING)
    section.Paint = function(this, width, panelHeight)
        local glass = ax.theme:GetGlass()
        ax.theme:DrawGlassPanel(0, 0, width, panelHeight, {
            radius = 12,
            blur = 1.1,
            flags = GLASS_FLAGS,
            fill = glass.panel
        })
    end

    local header = AddHeader(section, title, subtitle)
    section:SetTall(header:GetTall())
    section.axPadding = SECTION_PADDING

    return section
end

local function AddButton(parent, text, callback)
    local button = parent:Add("ax.button")
    button:Dock(TOP)
    button:DockMargin(0, 0, 0, 6)
    button:SetFont("ax.small")
    button:SetFontDefault("ax.small")
    button:SetFontHovered("ax.small")
    button:SetText(text)
    button.DoClick = callback
    return button
end

local function AddButtonRow(parent, definitions)
    local row = parent:Add("DPanel")
    row:Dock(TOP)
    row:SetPaintBackground(false)
    row.buttons = {}

    for i = 1, #definitions do
        local definition = definitions[i]
        local button = row:Add("ax.button")
        button:SetFont("ax.small")
        button:SetFontDefault("ax.small")
        button:SetFontHovered("ax.small")
        button:SetText(definition.text)
        button.DoClick = definition.callback
        row.buttons[#row.buttons + 1] = button
    end

    local buttonMaxHeight = 0
    for i = 1, #row.buttons do
        buttonMaxHeight = math.max(buttonMaxHeight, row.buttons[i]:GetTall())
    end

    row:SetTall(buttonMaxHeight)

    row.PerformLayout = function(this, width, height)
        local count = #this.buttons
        if ( count < 1 ) then return end

        local spacing = 6
        local buttonWidth = math.floor((width - spacing * (count - 1)) / count)
        local x = 0

        local buttonMaxHeight = 0
        for i = 1, count do
            buttonMaxHeight = math.max(buttonMaxHeight, this.buttons[i]:GetTall())
        end

        for i = 1, count do
            local button = this.buttons[i]
            button:SetPos(x, 0)
            button:SetSize(buttonWidth, buttonMaxHeight)
            x = x + buttonWidth + spacing
        end

        this:SetTall(buttonMaxHeight)
    end

    return row
end

local function AddInfoLine(parent)
    local line = parent:Add("ax.text")
    line:Dock(TOP)
    line:DockMargin(0, 0, 0, 4)
    line:SetWrap(false)
    line:SetFont("ax.small")
    line:SetTextColor(Color(232, 232, 232))
    return line
end

local function AddWrappedInfoBlock(parent)
    local block = parent:Add("DPanel")
    block:Dock(TOP)
    block:SetPaintBackground(false)
    block.axText = ""
    block.axLines = {}
    block.axFont = "ax.small"
    block.axTextColor = Color(232, 232, 232)

    function block:SetFont(font)
        self.axFont = font or "ax.small"
        self:RebuildWrappedLines(self:GetWide())
    end

    function block:SetTextColor(color)
        self.axTextColor = color or color_white
    end

    function block:SetText(text)
        self.axText = tostring(text or "")
        self:RebuildWrappedLines(self:GetWide())
    end

    function block:RebuildWrappedLines(width)
        width = math.max(width or self:GetWide(), 0)
        local availableWidth = math.max(width - 4, 1)
        self.axLines = ax.util:GetWrappedText(self.axText, self.axFont, availableWidth) or { self.axText }

        local lineHeight = ax.util:GetTextHeight(self.axFont)
        self:SetTall(math.max(#self.axLines, 1) * lineHeight + 4)
    end

    function block:PerformLayout(width)
        self:RebuildWrappedLines(width)
    end

    function block:Paint(width, height)
        local lineHeight = ax.util:GetTextHeight(self.axFont)

        for index, line in ipairs(self.axLines) do
            draw.SimpleText(line, self.axFont, 0, (index - 1) * lineHeight, self.axTextColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end

    return block
end

local function AddStack(parent)
    local stack = parent:Add("DPanel")
    stack:Dock(TOP)
    stack:SetTall(0)
    stack:SetPaintBackground(false)
    return stack
end

local function GetDockHeight(panel, minimumHeight)
    local height = 0

    for _, child in ipairs(panel:GetChildren()) do
        if ( !IsValid(child) or !child:IsVisible() ) then
            continue
        end

        local _, marginTop, _, marginBottom = child:GetDockMargin()
        height = height + child:GetTall() + marginTop + marginBottom
    end

    return math.max(height, minimumHeight or 0)
end

local function RefreshStackHeight(panel, minimumHeight)
    if ( !IsValid(panel) ) then return 0 end

    panel:InvalidateLayout(true)
    local height = GetDockHeight(panel, minimumHeight or 0)
    panel:SetTall(height)

    return height
end

local function RefreshSectionHeight(section)
    if ( !IsValid(section) ) then return 0 end

    section:InvalidateLayout(true)

    local padding = section.axPadding or SECTION_PADDING
    local height = GetDockHeight(section, 0) + padding * 2
    section:SetTall(height)

    return height
end

local function MeasureSectionHeight(section)
    if ( !IsValid(section) ) then return 0 end

    local padding = section.axPadding or SECTION_PADDING
    return GetDockHeight(section, 0) + padding * 2
end

local function RefreshWrappedLabelHeight(label, availableWidth)
    if ( !IsValid(label) ) then return 0 end

    local width = math.max(availableWidth or 0, 0)
    label:SetWide(width)

    if ( label.RebuildWrappedLines ) then
        label:RebuildWrappedLines(width)
    end

    label:InvalidateLayout(true)

    return label:GetTall()
end

function PANEL:Init()
    self:SetSize(math.min(520, ScrW() * 0.32), math.min(FRAME_MAX_HEIGHT, ScrH() - FRAME_MARGIN * 2))
    self:SetPos(ScrW() - self:GetWide() - FRAME_MARGIN, FRAME_MARGIN)
    self:SetTitle(Phrase("zones.editor.title"))
    self:SetDraggable(false)
    self:SetScreenLock(true)
    self:SetDeleteOnClose(true)
    self:SetBackgroundBlur(false)

    self.controller = ax.zones.editor

    self.scroll = self:Add("ax.scroller.vertical")
    self.scroll:Dock(FILL)

    self.sessionSection = AddSection(self.scroll, "zones.editor.section.workflow", "zones.editor.section.workflow.subtitle")
    self.contextLabel = AddInfoLine(self.sessionSection)
    self.selectionLabel = AddInfoLine(self.sessionSection)
    self.draftLabel = AddInfoLine(self.sessionSection)
    self.gridSnapButton = AddButton(self.sessionSection, "", function()
        self.controller:ToggleGridSnap()
    end)
    self.snapDraftButton = AddButton(self.sessionSection, "zones.editor.button.snap_current", function()
        self.controller:SnapDraftToGrid()
    end)
    self.gridSizeLabel = AddInfoLine(self.sessionSection)
    self.gridStepRow = AddButtonRow(self.sessionSection, {
        {
            text = "zones.editor.button.grid_smaller",
            callback = function()
                self.controller:StepGridSnapSize(-1)
            end
        },
        {
            text = "zones.editor.button.grid_larger",
            callback = function()
                self.controller:StepGridSnapSize(1)
            end
        }
    }):DockMargin(0, 0, 0, 6)

    AddButtonRow(self.sessionSection, {
        {
            text = "zones.editor.button.select_look_target",
            callback = function()
                self.controller:SelectLookTarget()
            end
        },
        {
            text = "zones.editor.button.revert_to_saved",
            callback = function()
                local zone = self.controller:GetSelectedZone()
                if ( zone ) then
                    self.controller:LoadZone(zone.id, true)
                end
            end
        }
    }):DockMargin(0, 0, 0, 6)

    AddButtonRow(self.sessionSection, {
        {
            text = "zones.editor.button.new_box",
            callback = function()
                self.controller:BeginNew("box", false)
            end
        },
        {
            text = "zones.editor.button.new_sphere",
            callback = function()
                self.controller:BeginNew("sphere", false)
            end
        }
    }):DockMargin(0, 0, 0, 6)

    AddButtonRow(self.sessionSection, {
        {
            text = "zones.editor.button.new_pvs",
            callback = function()
                self.controller:BeginNew("pvs", false)
            end
        },
        {
            text = "zones.editor.button.new_trace",
            callback = function()
                self.controller:BeginNew("trace", false)
            end
        }
    }):DockMargin(0, 0, 0, 6)

    self.zoneListSection = AddSection(self.scroll, "zones.editor.section.saved", "zones.editor.section.saved.subtitle")
    self.zoneCountLabel = AddInfoLine(self.zoneListSection)
    self.zoneList = AddStack(self.zoneListSection)

    self.detailSection = AddSection(self.scroll, "zones.editor.section.draft", "zones.editor.section.draft.subtitle")
    self.nameLabel = AddInfoLine(self.detailSection)
    self.typeLabel = AddInfoLine(self.detailSection)
    self.priorityLabel = AddInfoLine(self.detailSection)
    self.summaryLabel = AddInfoLine(self.detailSection)
    self.sourceLabel = AddInfoLine(self.detailSection)

    AddButtonRow(self.detailSection, {
        {
            text = "zones.editor.button.rename",
            callback = function()
                self.controller:PromptName()
            end
        },
        {
            text = "zones.editor.button.priority",
            callback = function()
                self.controller:PromptPriority()
            end
        }
    }):DockMargin(0, 0, 0, 6)

    AddButtonRow(self.detailSection, {
        {
            text = "zones.editor.button.use_box",
            callback = function()
                self.controller:SetDraftType("box")
            end
        },
        {
            text = "zones.editor.button.use_sphere",
            callback = function()
                self.controller:SetDraftType("sphere")
            end
        }
    }):DockMargin(0, 0, 0, 6)

    AddButtonRow(self.detailSection, {
        {
            text = "zones.editor.button.use_pvs",
            callback = function()
                self.controller:SetDraftType("pvs")
            end
        },
        {
            text = "zones.editor.button.use_trace",
            callback = function()
                self.controller:SetDraftType("trace")
            end
        }
    }):DockMargin(0, 0, 0, 6)

    self.geometryPanel = AddStack(self.detailSection)

    self.flagsSection = AddSection(self.scroll, "zones.editor.section.flags", "zones.editor.section.flags.subtitle")
    AddButton(self.flagsSection, "zones.editor.button.add_flag", function()
        self.controller:OpenPropertyMenu("flags")
    end)
    self.flagList = AddStack(self.flagsSection)

    self.dataSection = AddSection(self.scroll, "zones.editor.section.data", "zones.editor.section.data.subtitle")
    AddButton(self.dataSection, "zones.editor.button.add_data", function()
        self.controller:OpenPropertyMenu("data")
    end)
    self.dataList = AddStack(self.dataSection)

    self.actionSection = AddSection(self.scroll, "zones.editor.section.actions", "zones.editor.section.actions.subtitle")
    self.actionPrimaryRow = AddButtonRow(self.actionSection, {
        {
            text = "zones.editor.button.save_draft",
            callback = function()
                self.controller:SaveDraft()
            end
        },
        {
            text = "zones.editor.button.duplicate_zone",
            callback = function()
                self.controller:DuplicateSelected()
            end
        }
    })
    self.actionPrimaryRow:DockMargin(0, 0, 0, 6)

    AddButtonRow(self.actionSection, {
        {
            text = "zones.editor.button.teleport_to_zone",
            callback = function()
                self.controller:TeleportSelected()
            end
        },
        {
            text = "zones.editor.button.delete_zone",
            callback = function()
                self.controller:DeleteSelected()
            end
        }
    })

    self.footerLabel = AddWrappedInfoBlock(self.actionSection)
    self.footerLabel:Dock(TOP)
    self.footerLabel:DockMargin(0, 2, 0, 0)
    self.footerLabel:SetFont("ax.small")
    self.footerLabel:SetTextColor(Color(232, 232, 232))

    self:RefreshContents()
end

function PANEL:UpdateContextState(enabled)
    if ( !IsValid(self.contextLabel) ) then return end

    if ( enabled ) then
        self.contextLabel:SetText(Phrase("zones.editor.context_open"), true)
    else
        self.contextLabel:SetText(Phrase("zones.editor.context_closed"), true)
    end
end

function PANEL:RefreshZoneList()
    self.zoneList:Clear()

    local zones = self.controller:GetZones()
    self.zoneCountLabel:SetText(Phrase("zones.editor.loaded_zones", #zones), true)

    if ( #zones < 1 ) then
        local empty = self.zoneList:Add("ax.text")
        empty:Dock(TOP)
        empty:SetFont("ax.small")
        empty:SetTextColor(Color(200, 200, 200, 170))
        empty:SetText(Phrase("zones.editor.no_saved_zones"), true)
        RefreshStackHeight(self.zoneList, EMPTY_LIST_HEIGHT)
        return
    end

    for i = 1, #zones do
        local zone = zones[i]
        local button = self.zoneList:Add("ax.button")
        button:Dock(TOP)
        button:DockMargin(0, 0, 0, 6)
        button:SetFont("ax.small")
        button:SetFontDefault("ax.small")
        button:SetFontHovered("ax.small")
        button:SetText(Phrase("zones.editor.zone_button", zone.id, zone.name or Phrase("zones.common.unnamed")), true)
        button:SetTextInset(8, 0)
        button:SetContentAlignment(4)
        button.DoClick = function()
            self.controller:LoadZone(zone.id, false)
        end
        button.PaintAdditional = function(this, width, height)
            local selected = self.controller.selectedId == zone.id
            if ( selected ) then
                surface.SetDrawColor(255, 206, 106, 70)
                surface.DrawRect(0, 0, 6, height)
            end

            draw.SimpleText(
                Phrase("zones.editor.zone_meta", self.controller:GetTypeLabel(zone.type), zone.priority or 0, GetSourceLabel(zone.source)),
                "ax.small",
                width - 8,
                height / 2,
                Color(220, 220, 220, 190),
                TEXT_ALIGN_RIGHT,
                TEXT_ALIGN_CENTER
            )
        end
    end

    RefreshStackHeight(self.zoneList, EMPTY_LIST_HEIGHT)
end

function PANEL:RefreshPropertyList(listPanel, rows, kind)
    listPanel:Clear()

    if ( #rows < 1 ) then
        local empty = listPanel:Add("ax.text")
        empty:Dock(TOP)
        empty:SetFont("ax.small")
        empty:SetTextColor(Color(200, 200, 200, 170))
        empty:SetText(Phrase("zones.editor.no_entries"), true)
        RefreshStackHeight(listPanel, EMPTY_LIST_HEIGHT)
        return
    end

    for i = 1, #rows do
        local row = rows[i]
        local button = listPanel:Add("ax.button")
        button:Dock(TOP)
        button:DockMargin(0, 0, 0, 6)
        button:SetFont("ax.small")
        button:SetFontDefault("ax.small")
        button:SetFontHovered("ax.small")
        button:SetText(Phrase("zones.editor.property_row", row.key, row.formatted), true)
        button:SetTextInset(8, 0)
        button:SetContentAlignment(4)
        button.DoClick = function()
            self.controller:OpenPropertyMenu(kind, row.key)
        end
        button.PaintAdditional = function(this, width, height)
            draw.SimpleText(
                GetValueTypeLabel(row.valueType),
                "ax.small",
                width - 8,
                height / 2,
                Color(220, 220, 220, 170),
                TEXT_ALIGN_RIGHT,
                TEXT_ALIGN_CENTER
            )
        end
    end

    RefreshStackHeight(listPanel, EMPTY_LIST_HEIGHT)
end

function PANEL:RefreshGeometryPanel()
    self.geometryPanel:Clear()

    local draft = self.controller:BuildPreviewZone()
    if ( !draft ) then
        local empty = self.geometryPanel:Add("ax.text")
        empty:Dock(TOP)
        empty:SetFont("ax.small")
        empty:SetTextColor(Color(220, 220, 220, 180))
        empty:SetText(Phrase("zones.editor.geometry_empty"), true)
        RefreshStackHeight(self.geometryPanel, empty:GetTall())
        return
    end

    if ( draft.type == "box" ) then
        local cornerALabel = AddInfoLine(self.geometryPanel)
        cornerALabel:SetText(Phrase("zones.editor.corner_a", self.controller:FormatVector(draft.cornerA or draft.mins)), true)

        local cornerBLabel = AddInfoLine(self.geometryPanel)
        cornerBLabel:SetText(Phrase("zones.editor.corner_b", self.controller:FormatVector(draft.cornerB or draft.maxs)), true)

        AddButtonRow(self.geometryPanel, {
            {
                text = "zones.editor.button.corner_a_look",
                callback = function()
                    self.controller:CaptureBoxCorner("A", "look")
                end
            },
            {
                text = "zones.editor.button.corner_a_me",
                callback = function()
                    self.controller:CaptureBoxCorner("A", "player")
                end
            }
        }):DockMargin(0, 0, 0, 6)

        AddButtonRow(self.geometryPanel, {
            {
                text = "zones.editor.button.corner_b_look",
                callback = function()
                    self.controller:CaptureBoxCorner("B", "look")
                end
            },
            {
                text = "zones.editor.button.corner_b_me",
                callback = function()
                    self.controller:CaptureBoxCorner("B", "player")
                end
            }
        }):DockMargin(0, 0, 0, 6)

        AddButton(self.geometryPanel, "zones.editor.button.reset_box", function()
            self.controller:ResetBoxAroundPlayer()
        end)

        AddButton(self.geometryPanel, "zones.editor.button.best_guess_room", function()
            self.controller:GuessBoxFromRoom()
        end)

        RefreshStackHeight(self.geometryPanel)
        return
    end

    local originLabel = AddInfoLine(self.geometryPanel)
    if ( draft.type == "sphere" ) then
        originLabel:SetText(Phrase("zones.editor.center", self.controller:FormatVector(draft.center or draft.origin)), true)
    else
        originLabel:SetText(Phrase("zones.editor.origin", self.controller:FormatVector(draft.center or draft.origin)), true)
    end

    AddButtonRow(self.geometryPanel, {
        {
            text = "zones.editor.button.use_look_position",
            callback = function()
                self.controller:CaptureOrigin("look")
            end
        },
        {
            text = "zones.editor.button.use_my_position",
            callback = function()
                self.controller:CaptureOrigin("player")
            end
        }
    })

    if ( draft.type == "sphere" or draft.type == "pvs" or draft.type == "trace" ) then
        local radiusLabel = AddInfoLine(self.geometryPanel)
        radiusLabel:SetText(Phrase("zones.editor.radius", tostring(draft.radius or 0)), true)

        AddButtonRow(self.geometryPanel, {
            {
                text = "-64",
                callback = function()
                    self.controller:AdjustRadius(-64)
                end
            },
            {
                text = "-16",
                callback = function()
                    self.controller:AdjustRadius(-16)
                end
            },
            {
                text = "+16",
                callback = function()
                    self.controller:AdjustRadius(16)
                end
            },
            {
                text = "+64",
                callback = function()
                    self.controller:AdjustRadius(64)
                end
            }
        })

        AddButton(self.geometryPanel, "zones.editor.button.set_radius", function()
            self.controller:PromptRadius()
        end)
    end

    RefreshStackHeight(self.geometryPanel)
end

function PANEL:RefreshDetails()
    local draft = self.controller:BuildPreviewZone()
    local selectedZone = self.controller:GetSelectedZone()

    if ( draft ) then
        self.nameLabel:SetText(Phrase("zones.editor.name_value", draft.name or Phrase("zones.common.unnamed")), true)
        self.typeLabel:SetText(Phrase("zones.editor.type_value", self.controller:GetTypeLabel(draft.type)), true)
        self.priorityLabel:SetText(Phrase("zones.editor.priority_value", tostring(draft.priority or 0)), true)
        self.summaryLabel:SetText(Phrase("zones.editor.geometry_value", self.controller:GetTypeSummary(draft)), true)
        self.sourceLabel:SetText(Phrase("zones.editor.saved_state_value", draft.id and Phrase("zones.editor.saved_state_editing", draft.id) or Phrase("zones.editor.saved_state_new")), true)
    else
        self.nameLabel:SetText(Phrase("zones.editor.name_value", Phrase("zones.common.none")), true)
        self.typeLabel:SetText(Phrase("zones.editor.type_value", Phrase("zones.common.none")), true)
        self.priorityLabel:SetText(Phrase("zones.editor.priority_value", Phrase("zones.common.none")), true)
        self.summaryLabel:SetText(Phrase("zones.editor.geometry_value", Phrase("zones.common.none")), true)
        self.sourceLabel:SetText(Phrase("zones.editor.saved_state_value", Phrase("zones.common.none")), true)
    end

    if ( selectedZone and selectedZone.source == "static" ) then
        self.footerLabel:SetText(Phrase("zones.editor.footer_static"), true)
    else
        self.footerLabel:SetText(Phrase("zones.editor.footer_runtime"), true)
    end

    self:RefreshGeometryPanel()
end

function PANEL:RefreshWorkflow()
    local selectedZone = self.controller:GetSelectedZone()
    local draft = self.controller:BuildPreviewZone()
    local lookTargetId = self.controller.lookTargetId
    local zoneCount = #self.controller:GetZones()
    local gridSize = self.controller:GetGridSnapSize()

    self.selectionLabel:SetText(selectedZone and Phrase("zones.editor.selected_zone", selectedZone.id, selectedZone.name or Phrase("zones.common.unnamed")) or Phrase("zones.editor.selected_zone_none"), true)
    self.draftLabel:SetText(draft and Phrase("zones.editor.draft_status", self.controller:GetTypeSummary(draft), self.controller:IsDirty() and ("  |  " .. Phrase("zones.common.unsaved")) or "") or Phrase("zones.editor.draft_status_none"), true)

    if ( IsValid(self.gridSnapButton) ) then
        local key = self.controller:IsGridSnapEnabled() and "zones.editor.button.grid_snap_on" or "zones.editor.button.grid_snap_off"
        self.gridSnapButton:SetText(Phrase(key, gridSize), true)
    end

    if ( IsValid(self.snapDraftButton) ) then
        self.snapDraftButton:SetEnabled(draft != nil)
    end

    if ( IsValid(self.gridSizeLabel) ) then
        self.gridSizeLabel:SetText(Phrase("zones.editor.grid_size_value", gridSize), true)
    end

    if ( IsValid(self.gridStepRow) ) then
        if ( IsValid(self.gridStepRow.buttons[1]) ) then
            self.gridStepRow.buttons[1]:SetEnabled(gridSize > (self.controller.gridSnapMin or 1))
        end

        if ( IsValid(self.gridStepRow.buttons[2]) ) then
            self.gridStepRow.buttons[2]:SetEnabled(gridSize < (self.controller.gridSnapMax or 256))
        end
    end

    local zoneCountText = Phrase("zones.editor.loaded_zones", zoneCount)
    if ( lookTargetId ) then
        zoneCountText = zoneCountText .. "  |  " .. Phrase("zones.editor.look_target", lookTargetId)
    end

    self.zoneCountLabel:SetText(zoneCountText, true)

    RefreshSectionHeight(self.sessionSection)
end

function PANEL:RefreshActionSectionLayout()
    if ( !IsValid(self.actionSection) or !IsValid(self.footerLabel) ) then return end

    local actionSectionWidth = self.actionSection:GetWide()
    if ( actionSectionWidth <= 0 ) then
        actionSectionWidth = self:GetWide() - SECTION_PADDING * 2
    end

    RefreshWrappedLabelHeight(
        self.footerLabel,
        math.max(actionSectionWidth - (self.actionSection.axPadding or SECTION_PADDING) * 2, 0)
    )

    self.actionSection:SetTall(MeasureSectionHeight(self.actionSection))
end

function PANEL:RefreshContents()
    self:UpdateContextState(self.controller.contextOpen == true)
    self:RefreshZoneList()
    self:RefreshDetails()
    self:RefreshPropertyList(self.flagList, self.controller:GetPropertyRows("flags"), "flags")
    self:RefreshPropertyList(self.dataList, self.controller:GetPropertyRows("data"), "data")
    self:RefreshWorkflow()
    RefreshSectionHeight(self.zoneListSection)
    RefreshSectionHeight(self.detailSection)
    RefreshSectionHeight(self.flagsSection)
    RefreshSectionHeight(self.dataSection)
    self.actionSection:InvalidateLayout(true)
    self:RefreshActionSectionLayout()
    self.scroll:InvalidateLayout(true)
end

function PANEL:PerformLayout(width, height)
    BaseClass.PerformLayout(self, width, height)

    if ( self.axRefreshingActionLayout ) then return end

    self.axRefreshingActionLayout = true
    self:RefreshActionSectionLayout()
    self.axRefreshingActionLayout = false
end

function PANEL:OnClose()
    if ( self.axSilentClose ) then return end

    if ( self.controller and self.controller.active ) then
        ax.command:Send("/ZoneEditor")
    end
end

vgui.Register("ax.zone.editor", PANEL, "ax.frame")
