--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Category used by any var that does not name one.
local DEFAULT_CATEGORY = "03_other"

--- Seconds a step takes to fade in as the wizard advances.
local STEP_FADE_TIME = 0.2

---@class ax.main.create.step : EditablePanel
--- One category of the creation wizard. Each step owns a `container` that character vars populate into, plus the navigation rail beneath it.
---
--- The navigation lives on the step rather than on the wizard because a var's `populate` reaches it as `container:GetParent()` -- `faction` removes the NEXT button that way, since choosing a faction is itself the advance.
local STEP = {}

--- Initialises the step's container and navigation rail.
---@realm client
function STEP:Init()
    self.category = nil
    self.index = 1
    self.navigation = {}

    self.rail = self:Add("EditablePanel")
    self.rail:Dock(BOTTOM)
    self.rail:SetTall(ax.util:ScreenScale(20))
    self.rail:DockMargin(0, ax.ui:Space("lg"), 0, 0)

    -- Derma lays docked children out in add order, so the rail has to exist before the filling container.
    self.container = self:Add("ax.scroller")
    self.container:Dock(FILL)
end

--- Adds the back and next buttons to the rail.
---@realm client
---@param backText string Label for the back button.
---@param backCallback function Click handler for back.
---@param nextText? string Label for the next button; omitted for a step that advances itself.
---@param nextCallback? function Click handler for next.
function STEP:CreateNavigation(backText, backCallback, nextText, nextCallback)
    local back = self.rail:Add("ax.button")
    back:Dock(LEFT)
    back:SetWide(ax.util:ScreenScale(96))
    back:SetLabel(backText)
    back:SetAlign(TEXT_ALIGN_CENTER)
    back.DoClick = backCallback

    self.navigation[utf8.lower(backText)] = back

    if ( !nextText ) then return end

    local next = self.rail:Add("ax.button")
    next:Dock(RIGHT)
    next:SetWide(ax.util:ScreenScale(96))
    next:SetLabel(nextText)
    next:SetAlign(TEXT_ALIGN_CENTER)
    next.DoClick = nextCallback

    self.navigation[utf8.lower(nextText)] = next
end

--- Removes a navigation button by its label; used by vars that drive their own advance.
---@realm client
---@param text string The button label, matched case-insensitively.
function STEP:DeleteNavigationButtonByText(text)
    if ( !isstring(text) ) then return end

    local key = utf8.lower(text)
    local button = self.navigation[key]
    if ( !IsValid(button) ) then return end

    button:Remove()
    self.navigation[key] = nil
end

--- Returns a navigation button by its label.
---@realm client
---@param text string The button label, matched case-insensitively.
---@return Panel|nil button The button, or nil when absent.
function STEP:GetNavigationButtonByText(text)
    if ( !isstring(text) ) then return nil end

    return self.navigation[utf8.lower(text)]
end

vgui.Register("ax.main.create.step", STEP, "EditablePanel")

---@class ax.main.create : EditablePanel
--- The character creation wizard: one step per character-var category, a live model preview, and a payload that is handed to the server on the final step.
---
--- Field rendering stays with the vars themselves. A var with a `populate` owns its field outright; everything else gets a control chosen from its `fieldType`. That contract is unchanged from the previous interface, so a schema var keeps working.
local PANEL = {}

--- Builds the wizard chrome and opens the first step.
---@realm client
function PANEL:Init()
    hook.Run("PreMainMenuCreateCreated", self)

    self.payload = {}
    self.bSending = false
    self.steps = {}
    self.step = nil

    self.preview = self:Add("ax.model")
    self.preview:Dock(LEFT)
    self.preview:DockMargin(ax.util:ScreenScale(48), ax.util:ScreenScale(42), 0, ax.util:ScreenScale(30))

    self.body = self:Add("EditablePanel")
    self.body:Dock(FILL)
    self.body:DockMargin(ax.util:ScreenScale(24), ax.util:ScreenScale(42), ax.util:ScreenScale(48), ax.util:ScreenScale(30))

    self:Reset()

    -- Applies the seeded payload once so the preview column collapses when there is no model yet, instead of reserving space for nothing.
    self:OnPayloadChanged(self.payload)

    -- The first step is deliberately NOT built here. Init runs before this panel has been docked, so it is still at Derma's default 64x24, and any field that sizes itself from its container would come out microscopic. PerformLayout starts the wizard once real dimensions exist.
    self.bStarted = false

    hook.Run("PostMainMenuCreateCreated", self)
end

--- Wipes the payload back to defaults and destroys every built step, so re-entering the wizard is always a fresh character.
---@realm client
function PANEL:Reset()
    self.payload = {}
    self.bSending = false

    local vars = self:GetVars()
    for key, var in pairs(vars) do
        if ( !var.validate or var.hide ) then continue end
        if ( !self:CanPopulate(var, key) ) then continue end

        if ( var.default != nil and self.payload[key] == nil ) then
            self.payload[key] = var.default
        end
    end

    for category, step in pairs(self.steps) do
        if ( IsValid(step) ) then
            step:Remove()
        end

        self.steps[category] = nil
    end

    self.steps = {}
    self.step = nil
end

--- Returns a copy of the character var registry with categories and sort orders filled in.
---@realm client
---@return table vars Var definitions keyed by name.
function PANEL:GetVars()
    local vars = table.Copy(ax.character.vars)
    local sortOrder = 0

    for _, var in pairs(vars) do
        var.category = var.category or DEFAULT_CATEGORY
        var.sortOrder = var.sortOrder or sortOrder
        sortOrder = sortOrder + 2
    end

    return vars
end

--- Runs a var's `canPopulate` against the current payload, treating an error as a refusal.
---@realm client
---@param var table The var definition.
---@param key string The var name, for reporting.
---@return boolean bCanPopulate Whether the var applies to the current payload.
function PANEL:CanPopulate(var, key)
    if ( !isfunction(var.canPopulate) ) then return true end

    local success, result = pcall(var.canPopulate, var, self.payload, ax.client)
    if ( !success ) then
        ax.util:PrintWarning(Format("Failed to check canPopulate for character var '%s': %s", tostring(key), tostring(result)))
        return false
    end

    return result and true or false
end

--- Returns the ordered list of categories that apply to the current payload; a numeric filename-style prefix on the category name wins over the sort order of the vars inside it.
---@realm client
---@return table categories Ordered array of category names.
function PANEL:GetOrderedCategories()
    local vars = self:GetVars()
    local orders = {}

    for key, var in pairs(vars) do
        if ( !var.validate or var.hide ) then continue end
        if ( !self:CanPopulate(var, key) ) then continue end

        local category = var.category
        orders[category] = math.min(orders[category] or var.sortOrder, var.sortOrder)
    end

    local list = {}
    for name, order in pairs(orders) do
        local prefix = string.match(name, "^(%d+)[_%-]")

        list[#list + 1] = {
            name = name,
            order = prefix and (tonumber(prefix) * 100000 + order) or order,
        }
    end

    table.sort(list, function(a, b)
        if ( a.order == b.order ) then return a.name < b.name end

        return a.order < b.order
    end)

    local ordered = {}
    for i = 1, #list do
        ordered[#ordered + 1] = list[i].name
    end

    return ordered
end

--- Validates every applicable var in one category against the payload.
---@realm client
---@param category string The category to validate.
---@return boolean bValid Whether the category passed.
---@return string|nil reason Why it failed.
function PANEL:ValidateCategory(category)
    local vars = self:GetVars()

    for key, var in SortedPairsByMemberValue(vars, "sortOrder") do
        if ( !var.validate or var.hide ) then continue end
        if ( var.category != category ) then continue end
        if ( !self:CanPopulate(var, key) ) then continue end

        local success, bValid, reason = pcall(var.validate, var, self.payload[key], self.payload, ax.client)
        if ( !success ) then
            ax.util:PrintWarning(Format("Failed to validate character var '%s': %s", tostring(key), tostring(bValid)))
            return false, "An error occurred while validating this field"
        end

        if ( !bValid ) then
            return false, reason or "This field is invalid"
        end
    end

    return true
end

--- Builds a step for a category, or returns the one already built.
---@realm client
---@param category string The category the step covers.
---@param index number The step's position in the ordered list.
---@return Panel step The step panel.
function PANEL:GetStep(category, index)
    local step = self.steps[category]
    if ( IsValid(step) ) then
        step.index = index or step.index
        return step
    end

    step = self.body:Add("ax.main.create.step")
    step:Dock(FILL)
    step.category = category
    step.index = index or 1

    step:CreateNavigation("back", function()
        self:NavigateToPreviousStep(step)
    end, "next", function()
        self:NavigateToNextStep(step)
    end)

    self.steps[category] = step

    return step
end

--- Shows a step, hiding whichever one was showing.
---@realm client
---@param category string The category to show.
---@param index number The step's position in the ordered list.
function PANEL:ShowStep(category, index)
    local previous = self.step and self.steps[self.step]
    if ( IsValid(previous) ) then
        previous:SetVisible(false)
    end

    local step = self:GetStep(category, index)
    step:SetVisible(true)
    step:SetAlpha(0)

    step.stepAlpha = 0
    step:Motion(STEP_FADE_TIME, {
        Target = { stepAlpha = 255 },
        Easing = "OutQuad",
        Think = function(values)
            if ( IsValid(step) ) then
                step:SetAlpha(values.stepAlpha)
            end
        end
    })

    -- A freshly created step has not been through a layout pass, so its container is still at the default size. Resolving the docking here means every var's populate measures real dimensions.
    step:InvalidateLayout(true)

    if ( IsValid(step.container) ) then
        step.container:InvalidateLayout(true)
    end

    self.step = category

    self:PopulateVars(category)
    self:UpdateNavigation(step, index)

    -- Stepping does not necessarily touch the payload -- going back leaves it untouched -- so visibility is re-evaluated here rather than only when a value is written.
    self:OnPayloadChanged(self.payload)
end

--- Opens the first applicable step.
---@realm client
function PANEL:ShowFirstStep()
    local categories = self:GetOrderedCategories()
    if ( #categories == 0 ) then return end

    self:ShowStep(categories[1], 1)
end

--- Relabels the next button to CREATE on the final step, so the last click reads as a commitment rather than another page turn.
---@realm client
---@param step Panel The step being shown.
---@param index number Its position in the ordered list.
function PANEL:UpdateNavigation(step, index)
    local categories = self:GetOrderedCategories()
    local button = step:GetNavigationButtonByText("next")
    if ( !IsValid(button) ) then return end

    button:SetLabel(index >= #categories and ax.localization:GetPhrase("mainmenu.create") or "next")
end

--- Clears and rebuilds the fields for one category.
---@realm client
---@param category string The category to populate.
function PANEL:PopulateVars(category)
    local step = self.steps[category]
    if ( !IsValid(step) ) then return end

    local container = step.container
    if ( !IsValid(container) ) then return end

    container:Clear()

    local vars = self:GetVars()

    for key, var in SortedPairsByMemberValue(vars, "sortOrder") do
        if ( !var.validate or var.hide ) then continue end
        if ( var.category != category ) then continue end
        if ( !self:CanPopulate(var, key) ) then continue end

        -- A var with a populate owns its field outright; the wizard builds nothing for it.
        if ( isfunction(var.populate) ) then
            local success, err = pcall(var.populate, var, container, self.payload)
            if ( !success ) then
                ax.util:PrintWarning(Format("Failed to populate character var '%s': %s", tostring(key), tostring(err)))
            end

            continue
        end

        self:BuildField(container, key, var)
    end

    if ( self.OnPopulateVars ) then
        self:OnPopulateVars(container, category, self.payload)
    end

    hook.Run("OnCharacterPopulateVars", container, category, self.payload)
end

--- Builds the default control for a var from its field type.
---@realm client
---@param container Panel The step container to build into.
---@param key string The var name.
---@param var table The var definition.
function PANEL:BuildField(container, key, var)
    local label = container:Add("ax.text")
    label:SetFont("ax.regular.bold")
    label:SetTracking(ax.util:ScreenScale(2))
    label:SetTextColor(ax.color.textMuted)
    -- A schema var whose field has no phrase would otherwise hand nil to utf8.upper.
    label:SetText(utf8.upper(tostring(ax.localization:GetPhrase(var.field) or var.field)))
    label:SetZPos(var.sortOrder - 1)
    label:Dock(TOP)
    label:DockMargin(0, 0, 0, ax.ui:Space("sm"))

    local control

    if ( var.fieldType == ax.type.number ) then
        control = container:Add("ax.slider")
        control:SetTall(ax.util:ScreenScale(14))
        control:SetDecimals(var.decimals or 0)
        control:SetMin(var.min or 0)
        control:SetMax(var.max or 100)
        control:SetValue(self.payload[key] or var.default or 0)
        control.OnValueChanged = function(_, value)
            self:SetPayloadValue(key, value)
        end
    elseif ( var.fieldType == ax.type.bool ) then
        control = container:Add("ax.checkbox")
        control:SetTall(ax.util:ScreenScale(14))
        control:SetChecked(self.payload[key] == true)
        control.OnChanged = function(_, bChecked)
            self:SetPayloadValue(key, bChecked)
        end
    else
        control = container:Add("ax.entry")
        control:SetTall(ax.util:ScreenScale(16))
        control:SetPlaceholderText(tostring(var.default or ""))

        if ( var.fieldType == ax.type.text ) then
            control:SetMultiline(true)
            control:SetTall(ax.util:ScreenScale(48))
        end

        if ( self.payload[key] != nil ) then
            control:SetText(tostring(self.payload[key]), true)
        end

        control.OnValueChange = function(this)
            self:SetPayloadValue(key, this:GetText())
        end
    end

    control:SetZPos(var.sortOrder)
    control:Dock(TOP)
    control:DockMargin(0, 0, 0, ax.ui:Space("lg"))

    if ( isfunction(var.populatePost) ) then
        local success, err = pcall(var.populatePost, var, container, self.payload, label, control)
        if ( !success ) then
            ax.util:PrintWarning(Format("Failed to run populatePost for character var '%s': %s", tostring(key), tostring(err)))
        end
    end
end

--- Rebuilds the fields of the step currently showing. A var whose value changes what another var offers -- gender re-filtering the model pool being the shipped case -- calls this after writing the payload.
---@realm client
function PANEL:RefreshStep()
    if ( !self.step ) then return end

    self:PopulateVars(self.step)
end

--- The single entry point for mutating the payload; writes the value, refreshes the preview, and notifies listeners.
---@realm client
---@param key string The var name.
---@param value any The value to store.
function PANEL:SetPayloadValue(key, value)
    self.payload[key] = value

    self:OnPayloadChanged(self.payload)

    hook.Run("OnPayloadChanged", self.payload)
end

--- Refreshes anything bound to the payload; also the documented callback a var's `populate` fires after it writes.
---@realm client
---@param payload table The current payload.
function PANEL:OnPayloadChanged(payload)
    if ( !IsValid(self.preview) ) then return end

    -- The faction step has no model concept, so the preview stays down while it is showing. Without this, stepping back onto it from appearance leaves the previously chosen body on screen, because the payload it was built from has not changed.
    local factionVar = ax.character.vars.faction
    local factionCategory = istable(factionVar) and (factionVar.category or DEFAULT_CATEGORY) or nil

    local bShow = true
    if ( factionCategory and self.step == factionCategory ) then
        bShow = false
    elseif ( !payload.model or !payload.faction or payload.faction <= 0 ) then
        -- The model var carries a placeholder default, so without this the wizard opens on a stand-in body before the player has chosen anything.
        bShow = false
    end

    -- Hiding a docked panel does not reflow its siblings by itself, so without invalidating here the body keeps the whole preview column reserved and its content sits off-centre against empty space.
    if ( self.preview:IsVisible() != bShow ) then
        self.preview:SetVisible(bShow)
        self:InvalidateLayout()
    end

    if ( !bShow ) then return end

    self.preview:SetCharacterModel(payload.model, payload.skin)
end

--- Advances to the next step, validating the current one first; on the final step this submits the character instead.
---@realm client
---@param step Panel The step being left.
function PANEL:NavigateToNextStep(step)
    local categories = self:GetOrderedCategories()
    if ( #categories == 0 ) then return end

    local category = step.category
    local index

    for i = 1, #categories do
        if ( categories[i] == category ) then
            index = i
            break
        end
    end

    if ( !index ) then return end

    local bValid, reason = self:ValidateCategory(category)
    if ( !bValid ) then
        ax.client:Notify(reason)
        return
    end

    if ( index >= #categories ) then
        self:Submit()
        return
    end

    self:ShowStep(categories[index + 1], index + 1)
end

--- Steps backwards, leaving the wizard entirely from the first step.
---@realm client
---@param step Panel The step being left.
function PANEL:NavigateToPreviousStep(step)
    local categories = self:GetOrderedCategories()
    local category = step.category
    local index

    for i = 1, #categories do
        if ( categories[i] == category ) then
            index = i
            break
        end
    end

    local parent = self:GetParent()

    if ( !index or index <= 1 ) then
        if ( IsValid(parent) ) then
            parent:ShowPage("home")
        end

        return
    end

    self:ShowStep(categories[index - 1], index - 1)
end

--- Kept for the var contract: `faction` advances the wizard itself once a faction is chosen.
---@realm client
---@param step Panel The step to advance from.
function PANEL:NavigateToNextTab(step)
    self:NavigateToNextStep(step)
end

--- Sends the payload to the server.
---@realm client
function PANEL:Submit()
    if ( self.bSending ) then return end

    self.bSending = true

    ax.net:Start("character.create", self.payload)

    -- A rejected creation replies only with a notification, so the guard is released on a timer or the wizard would stay dead until it was rebuilt.
    timer.Simple(1, function()
        if ( !IsValid(self) ) then return end

        self.bSending = false
    end)
end

--- Sizes the preview column.
---@realm client
---@param width number Panel width in pixels.
---@param height number Panel height in pixels.
function PANEL:PerformLayout(width, height)
    if ( IsValid(self.preview) ) then
        self.preview:SetWide(math.max(width * 0.24, ax.util:ScreenScale(140)))
    end

    -- Derma's default panel width is 64, so anything above a small threshold means docking has resolved and the wizard can safely build fields that measure their container.
    if ( !self.bStarted and width > 128 ) then
        self.bStarted = true
        self:ShowFirstStep()
    end
end

--- Draws the heading and the step counter.
---@realm client
---@param width number Panel width in pixels.
---@param height number Panel height in pixels.
function PANEL:Paint(width, height)
    local x = ax.util:ScreenScale(48)
    local y = ax.util:ScreenScale(26)

    local title = "NEW CHARACTER"
    if ( self.step ) then
        title = utf8.upper(tostring(ax.localization:GetPhrase("mainmenu.category." .. self.step) or self.step))
    end

    local titleWidth = ax.draw:TextTracked(title, "ax.large.bold", x, y, ax.color.textBright, ax.util:ScreenScale(5), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    ax.draw:HLine(x, y + ax.util:ScreenScale(9), titleWidth, ax.color.line)

    local categories = self:GetOrderedCategories()
    if ( #categories == 0 or !self.step ) then return end

    local step = self.steps[self.step]
    local index = IsValid(step) and step.index or 1

    ax.draw:TextTracked(Format("%02d / %02d", index, #categories), "ax.small.bold", x + titleWidth + ax.ui:Space("lg"), y, ax.color.textFaint, ax.util:ScreenScale(3), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

vgui.Register("ax.main.create", PANEL, "EditablePanel")
