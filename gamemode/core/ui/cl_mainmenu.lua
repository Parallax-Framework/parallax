local padding = ScreenScale(32)
local gradientLeft = ax.util:GetMaterial("vgui/gradient-l")
local gradientRight = ax.util:GetMaterial("vgui/gradient-r")
local gradientTop = ax.util:GetMaterial("vgui/gradient-u")
local gradientBottom = ax.util:GetMaterial("vgui/gradient-d")

DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

AccessorFunc(PANEL, "currentCreatePage", "CurrentCreatePage", FORCE_NUMBER)
AccessorFunc(PANEL, "currentCreatePayload", "CurrentCreatePayload")

AccessorFunc(PANEL, "gradientLeft", "GradientLeft", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientRight", "GradientRight", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientTop", "GradientTop", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientBottom", "GradientBottom", FORCE_NUMBER)

AccessorFunc(PANEL, "gradientLeftTarget", "GradientLeftTarget", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientRightTarget", "GradientRightTarget", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientTopTarget", "GradientTopTarget", FORCE_NUMBER)
AccessorFunc(PANEL, "gradientBottomTarget", "GradientBottomTarget", FORCE_NUMBER)

AccessorFunc(PANEL, "dim", "Dim", FORCE_NUMBER)
AccessorFunc(PANEL, "dimTarget", "DimTarget", FORCE_NUMBER)

function PANEL:Init()
    if ( IsValid(ax.gui.mainmenu) ) then
        ax.gui.mainmenu:Remove()
    end

    ax.gui.mainmenu = self

    local client = ax.client
    if ( IsValid(client) and client:IsTyping() ) then
        chat.Close()
    end

    CloseDermaMenus()

    self.gradientLeft = 0
    self.gradientRight = 0
    self.gradientTop = 0
    self.gradientBottom = 0

    self.gradientLeftTarget = 0
    self.gradientRightTarget = 0
    self.gradientTopTarget = 0
    self.gradientBottomTarget = 0

    self.dim = 0
    self.dimTarget = 0

    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:MakePopup()

    self.createPanel = self:Add("ax.mainmenu.create")
    self.selectPanel = self:Add("ax.mainmenu.load")
    self.settingsPanel = self:Add("ax.mainmenu.settings")

    self.container = self:Add("EditablePanel")
    self.container:SetSize(self:GetWide(), self:GetTall())
    self.container:SetPos(0, 0)

    if ( ax.config:Get("mainmenu.branchwarning") and BRANCH != "x86-64" )  then
        Derma_Query(ax.localization:GetPhrase("mainmenu.branchwarning"), "Parallax", "I acknowledge")
    end

    self:Populate()
end

function PANEL:Populate()
    -- Hide all other panels
    self.createPanel:SetVisible(false)
    self.selectPanel:SetVisible(false)
    self.settingsPanel:SetVisible(false)

    -- And clear them
    self.createPanel:Clear()
    self.selectPanel:Clear()
    self.settingsPanel:Clear()

    -- Set the gradients
    self:SetGradientLeftTarget(1)
    self:SetGradientRightTarget(0)
    self:SetGradientTopTarget(0)
    self:SetGradientBottomTarget(0)
    self:SetDimTarget(0)

    -- Set the container to be visible and clear it
    self.container:SetVisible(true)
    self.container:Clear()

    local sideButtons = self.container:Add("EditablePanel")
    sideButtons:Dock(LEFT)
    sideButtons:DockMargin(padding * 2, padding * 3, 0, 0)
    sideButtons:SetSize(self.container:GetWide() / 3, self.container:GetTall() - padding * 2)

    local title = sideButtons:Add("DLabel")
    title:Dock(TOP)
    title:DockMargin(0, 0, padding, 0)
    title:SetFont("parallax.title")
    title:SetText("PARALLAX")
    title:SetTextColor(ax.config:Get("color.framework"))
    title:SizeToContents()

    local subtitle = sideButtons:Add("DLabel")
    subtitle:Dock(TOP)
    subtitle:DockMargin(padding / 4, -padding / 8, 0, 0)
    subtitle:SetFont("parallax.subtitle")

    local schemaName = "UNKNOWN SCHEMA"
    if ( SCHEMA ) then
        schemaName = SCHEMA.Name
        if ( isfunction(SCHEMA.GetMenuTitle) ) then
            schemaName = SCHEMA:GetMenuTitle()
        end

        schemaName = ax.utf8:Upper(schemaName)
    else
        ax.util:PrintError("SCHEMA is not defined! Please ensure that your schema is properly set up.")
    end

    subtitle:SetText(schemaName)
    subtitle:SetTextColor(ax.config:Get("color.schema"))
    subtitle:SizeToContents()

    local buttons = sideButtons:Add("EditablePanel")
    buttons:Dock(FILL)
    buttons:DockMargin(0, padding / 4, 0, padding)

    local client = ax.client
    local clientTable = client:GetTable()
    if ( clientTable.axCharacter ) then -- client:GetCharacter() isn't validated yet, since it this panel is created before the meta tables are loaded
        local playButton = buttons:Add("ax.button")
        playButton:Dock(TOP)
        playButton:DockMargin(0, 0, 0, 16)
        playButton:SetText("mainmenu.play")

        playButton.DoClick = function(this)
            self:Remove()
        end
    end

    local createButton = buttons:Add("ax.button")
    createButton:Dock(TOP)
    createButton:DockMargin(0, 0, 0, 16)
    createButton:SetText("mainmenu.create.character")

    createButton.DoClick = function(this)
        local availableFactions = 0
        for k, v in ipairs(ax.faction:GetAll()) do
            if ( ax.faction:CanSwitchTo(ax.client, v:GetID()) ) then
                availableFactions = availableFactions + 1
            end
        end

        if ( availableFactions > 1 ) then
            self.createPanel:PopulateFactionSelect()
        elseif ( availableFactions == 1 ) then
            self.createPanel:PopulateCreateCharacter()
        else
            ax.client:Notify("You do not have any factions available to create a character for.", NOTIFY_ERROR)
            return
        end
    end

    local bHasCharacters = table.Count(clientTable.axCharacters or {}) > 0
    if ( bHasCharacters ) then
        local selectButton = buttons:Add("ax.button")
        selectButton:Dock(TOP)
        selectButton:DockMargin(0, 0, 0, 16)
        selectButton:SetText("mainmenu.select.character")

        selectButton.DoClick = function()
            self.selectPanel:Populate()
        end
    end

    local settingsButton = buttons:Add("ax.button")
    settingsButton:Dock(TOP)
    settingsButton:DockMargin(0, 0, 0, 16)
    settingsButton:SetText("mainmenu.settings")

    settingsButton.DoClick = function()
        self.settingsPanel:Populate()
    end

    local disconnectButton = buttons:Add("ax.button")
    disconnectButton:Dock(TOP)
    disconnectButton:DockMargin(0, 0, 0, 16)
    disconnectButton:SetText("mainmenu.leave")
    disconnectButton:SetTextColorProperty(ax.color:Get("maroon"))

    disconnectButton.DoClick = function()
        Derma_Query(ax.localization:GetPhrase("mainmenu.disconnect.confirmation"), "Disconnect", "Yes", function()
            RunConsoleCommand("disconnect")
        end, "No")
    end
end

function PANEL:Paint(width, height)
    local ft = FrameTime()
    local time = ft * 5

    local performanceAnimations = ax.option:Get("performance.animations", true)
    if ( !performanceAnimations ) then
        time = 1
    end

    self:SetGradientLeft(Lerp(time, self:GetGradientLeft(), self:GetGradientLeftTarget()))
    self:SetGradientRight(Lerp(time, self:GetGradientRight(), self:GetGradientRightTarget()))
    self:SetGradientTop(Lerp(time, self:GetGradientTop(), self:GetGradientTopTarget()))
    self:SetGradientBottom(Lerp(time, self:GetGradientBottom(), self:GetGradientBottomTarget()))

    self:SetDim(Lerp(time, self:GetDim(), self:GetDimTarget()))

    surface.SetDrawColor(0, 0, 0, 255 * self:GetDim())
    surface.DrawRect(0, 0, width, height)

    surface.SetDrawColor(0, 0, 0, 255 * self:GetGradientLeft())
    surface.SetMaterial(gradientLeft)
    surface.DrawTexturedRect(0, 0, width, height)

    surface.SetDrawColor(0, 0, 0, 255 * self:GetGradientRight())
    surface.SetMaterial(gradientRight)
    surface.DrawTexturedRect(0, 0, width, height)

    surface.SetDrawColor(0, 0, 0, 255 * self:GetGradientTop())
    surface.SetMaterial(gradientTop)
    surface.DrawTexturedRect(0, 0, width, height)

    surface.SetDrawColor(0, 0, 0, 255 * self:GetGradientBottom())
    surface.SetMaterial(gradientBottom)
    surface.DrawTexturedRect(0, 0, width, height)
end

vgui.Register("ax.mainmenu", PANEL, "EditablePanel")

if ( IsValid(ax.gui.mainmenu) ) then
    ax.gui.mainmenu:Remove()

    timer.Simple(0.1, function()
        vgui.Create("ax.mainmenu")
    end)
end

concommand.Add("ax_mainmenu", function(client, command, arguments)
    if ( client:Team() == 0 ) then
        return
    end

    if ( IsValid(ax.gui.mainmenu) ) then
        ax.gui.mainmenu:Remove()
    end

    vgui.Create("ax.mainmenu")
end, nil, "Opens the main menu.", FCVAR_CLIENTCMD_CAN_EXECUTE)