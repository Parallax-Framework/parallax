local function OpenActionMenu(...)
    local actionMenu = vgui.Create("ax.gui.actionmenu")
    gui.EnableScreenClicker(true)
    actionMenu:MakePopup()

    for i = 1, select("#", ...) do
        local actionName = select(i, ...)
        local callback = select(i + 1, ...)

        if ( !isfunction(callback) ) then
            callback = function()
                ax.util:PrintError("Invalid callback for action: " .. tostring(actionName))
            end
        end

        if ( isstring(actionName) ) then
            actionMenu:AddAction(actionName, callback)
        end
    end

    actionMenu:InvalidateLayout(true)
    actionMenu:SizeToChildren(false, true)

    actionMenu.selectedAction = 1
end

local ACTION_MENU = {}

function ACTION_MENU:Init()
    self:SetSize(300, 100)
    self:Center()

    self.actions = {}
    self.actionsID = {}

    ax.gui.actionMenu = self
end

function ACTION_MENU:OnMouseWheeled(scrollDelta)
    if ( scrollDelta > 0 ) then
        self.selectedAction = math.max(1, self.selectedAction - 1)
    elseif ( scrollDelta < 0 ) then
        self.selectedAction = math.min(self.selectedAction + 1, table.Count(self.actions))
    end

    print("Selected action:", self.selectedAction)

    return true
end

function ACTION_MENU:AddAction(action, callback)
    local label = self:Add("DLabel")
    label:SetFont("ax.small")
    label:SetText(action)
    label:Dock(TOP)
    label:DockMargin(0, 0, 0, 5)
    label:SetContentAlignment(5)
    label.actionID = #self.actionsID + 1

    label.Paint = function(this, w, h)
        if ( self.selectedAction == this.actionID ) then
            surface.SetDrawColor(255, 255, 255, 50)
            surface.DrawRect(0, 0, w, h)
        end
    end

    self.actions[action] = {callback = callback, label = label}
    self.actionsID[#self.actionsID + 1] = {action = action, callback = callback, label = label}

    return button
end

function ACTION_MENU:OnRemove()
    gui.EnableScreenClicker(false)
end

function ACTION_MENU:OnMousePressed(keyCode)
    local selectedAction = self.actionsID[self.selectedAction]
    if ( istable(selectedAction) and isfunction(selectedAction.callback) ) then
        selectedAction:callback(self, selectedAction.label)
    end
end

function ACTION_MENU:OnKeyCodePressed()
    if ( input.IsKeyDown(KEY_ESCAPE) ) then
        self:Remove()
    end
end

function ACTION_MENU:Paint(w, h)
    surface.SetDrawColor(0, 0, 0, 150)
    surface.DrawRect(0, 0, w, h)
end

vgui.Register("ax.gui.actionmenu", ACTION_MENU, "DPanel")