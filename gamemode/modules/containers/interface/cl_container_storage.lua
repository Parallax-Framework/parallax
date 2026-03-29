--[[
	Parallax Framework
	Copyright (c) 2026 Parallax Framework Contributors

	This file is part of the Parallax Framework and is licensed under the MIT License.
	You may use, copy, modify, merge, publish, distribute, and sublicense this file
	under the terms of the LICENSE file included with this project.

	Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

local PANEL = {}

local PANEL_RADIUS = 12
local REFRESH_INTERVAL = 0.1
local DRAG_DROP_CHANNEL = "ax.container.transfer"

local function GetWindowSize()
	return math.min(ScrW() * 0.82, ax.util:ScreenScale(720)), math.min(ScrH() * 0.8, ax.util:ScreenScaleH(520))
end

local function GetHeaderHeight()
	return math.max(ax.util:ScreenScaleH(88), 112)
end

local function GetActionRailWidth()
	return math.max(ax.util:ScreenScale(84), 108)
end

local function BuildInventorySignature(inventory)
	if ( !istable(inventory) ) then
		return ""
	end

	local keys = {}
	for itemID in pairs(inventory:GetItems() or {}) do
		keys[#keys + 1] = itemID
	end

	table.sort(keys)

	return table.concat(keys, ",")
end

local function GetPaneColor(isActive)
	local glass = ax.theme:GetGlass()
	local metrics = ax.theme:GetMetrics()

	if ( isActive ) then
		return ax.theme:ScaleAlpha(glass.buttonHover or glass.highlight, metrics.opacity)
	end

	return ax.theme:ScaleAlpha(glass.panel, metrics.opacity)
end

local function GetAnimatedValue(panel, key, fallback)
	local value = panel[key]
	if ( value == nil ) then
		return fallback
	end

	return value
end

local ITEM = {}

function ITEM:Init()
	self:SetTall(ax.util:ScreenScaleH(34))
	self:SetText("")
	self:SetFontDefault("ax.regular")
	self:SetFontHovered("ax.regular.bold")
	self:SetBlur(0.5)
	self:SetCursor("hand")

	self.displayName = ""
	self.description = ""
	self.weightText = ""
	self.itemID = 0
	self.isSelected = false
	self.dragAlpha = 0
	self.selectedBlend = 0
	self.hoverBlend = 0

	self.icon = self:Add("SpawnIcon")
	self.icon:Dock(LEFT)
	self.icon:SetWide(self:GetTall())
	self.icon:DockMargin(8, 8, 8, 8)
	self.icon:SetMouseInputEnabled(false)

	self.name = self:Add("ax.text")
	self.name:Dock(FILL)
	self.name:SetFont("ax.regular")
	self.name:SetContentAlignment(4)

	self.meta = self:Add("ax.text")
	self.meta:Dock(RIGHT)
	self.meta:SetFont("ax.small")
	self.meta:SetContentAlignment(6)
	self.meta:DockMargin(8, 0, 8, 0)

	self:Droppable(DRAG_DROP_CHANNEL)
end

function ITEM:SetItem(item)
	self.item = item
	self.itemID = tonumber(item and item.id) or 0
	self.displayName = tostring(item and item:GetName() or ax.localization:GetPhrase("unknown"))
	self.description = tostring(item and item:GetDescription() or "")

	local weight = item and isfunction(item.GetWeight) and tonumber(item:GetWeight()) or 0
	if ( weight > 0 ) then
		self.weightText = math.Round(weight, 2) .. ax.localization:GetPhrase("inventory.weight.abbreviation")
	else
		self.weightText = ""
	end

	self.name:SetText(self.displayName, true)
	self.meta:SetText(self.weightText, true)

	if ( item and ax.item and ax.item.ApplyAppearanceToIcon ) then
		ax.item:ApplyAppearanceToIcon(item, self.icon)
	end
end

function ITEM:SetSelected(state)
	state = state == true
	if ( self.isSelected == state ) then return end

	self.isSelected = state
	self:Motion(0.18, {
		Target = {
			selectedBlend = state and 1 or 0,
		},
		Easing = "OutQuad",
	})
end

function ITEM:DoClick()
	if ( IsValid(self:GetParent()) and isfunction(self:GetParent().OnItemPressed) ) then
		self:GetParent():OnItemPressed(self)
	end
end

function ITEM:DoDoubleClick()
	if ( IsValid(self:GetParent()) and isfunction(self:GetParent().OnItemDoubleClicked) ) then
		self:GetParent():OnItemDoubleClicked(self)
	end
end

function ITEM:OnMousePressed(code)
	if ( code == MOUSE_LEFT ) then
		self:DragMousePress(code)
	end

	return DButton.OnMousePressed(self, code)
end

function ITEM:OnMouseReleased(code)
	if ( code == MOUSE_LEFT ) then
		self:DragMouseRelease(code)
	end

	return DButton.OnMouseReleased(self, code)
end

function ITEM:Think()
	local hovered = self:IsHovered() and self:IsEnabled()
	local target = hovered and 1 or 0

	if ( math.abs(GetAnimatedValue(self, "hoverBlend", 0) - target) > 0.01 ) then
		self:Motion(0.18, {
			Target = {
				hoverBlend = target,
			},
			Easing = "OutQuad",
		})
	end

	self.dragAlpha = dragndrop.IsDragging() and 1 or 0
	self:SetTooltip(self.description != "" and self.description or nil)
	self.meta:SetVisible(self.weightText != "")
end

function ITEM:Paint(width, height)
	local glass = ax.theme:GetGlass()
	local metrics = ax.theme:GetMetrics()
	local hoverBlend = GetAnimatedValue(self, "hoverBlend", 0)
	local selectedBlend = GetAnimatedValue(self, "selectedBlend", 0)
	local fill = ax.theme:ScaleAlpha(glass.button, metrics.opacity)

	if ( hoverBlend > 0 ) then
		fill = Color(
			Lerp(hoverBlend, fill.r, glass.buttonHover.r),
			Lerp(hoverBlend, fill.g, glass.buttonHover.g),
			Lerp(hoverBlend, fill.b, glass.buttonHover.b),
			Lerp(hoverBlend, fill.a, glass.buttonHover.a)
		)
	end

	if ( selectedBlend > 0 ) then
		fill = Color(
			Lerp(selectedBlend, fill.r, glass.buttonActive.r),
			Lerp(selectedBlend, fill.g, glass.buttonActive.g),
			Lerp(selectedBlend, fill.b, glass.buttonActive.b),
			Lerp(selectedBlend, fill.a, glass.buttonActive.a)
		)
	end

	ax.theme:DrawGlassButton(0, 0, width, height, {
		fill = fill,
		blur = 0.8,
	})

	if ( selectedBlend > 0.01 ) then
		ax.util:DrawGradient(0, "right", 0, 0, width, height, ax.theme:ScaleAlpha(glass.highlight, selectedBlend * 0.8))
	end
end

vgui.Register("ax.container.item", ITEM, "ax.button")

local INVENTORY_PANE = {}

function INVENTORY_PANE:Init()
	self.titleText = ""
	self.selectedItemID = nil
	self.dropHighlight = 0

	self.header = self:Add("EditablePanel")
	self.header:Dock(TOP)
	self.header:SetTall(ax.util:ScreenScaleH(28))
	self.header.Paint = nil

	self.title = self.header:Add("ax.text")
	self.title:Dock(LEFT)
	self.title:SetFont("ax.large.bold")

	self.status = self.header:Add("ax.text")
	self.status:Dock(RIGHT)
	self.status:SetFont("ax.small.bold")
	self.status:SetContentAlignment(6)

	self.body = self:Add("EditablePanel")
	self.body:Dock(FILL)
	self.body:DockMargin(0, 8, 0, 0)
	self.body.Paint = function(this, width, height)
		local blend = GetAnimatedValue(self, "dropHighlight", 0)
		ax.theme:DrawGlassPanel(0, 0, width, height, {
			radius = PANEL_RADIUS,
			blur = 1.0,
			fill = GetPaneColor(blend > 0.01),
		})

		if ( blend > 0.01 ) then
			local glass = ax.theme:GetGlass()
			ax.render.DrawOutlined(PANEL_RADIUS, 0, 0, width, height, ax.theme:ScaleAlpha(glass.highlight, blend), 2, ax.render.SHAPE_IOS)
		end
	end

	self.scroller = self.body:Add("ax.scroller.vertical")
	self.scroller:Dock(FILL)
	self.scroller:DockMargin(8, 8, 8, 8)

	self.empty = self.body:Add("ax.text")
	self.empty:Dock(FILL)
	self.empty:SetFont("ax.regular.italic")
	self.empty:SetContentAlignment(5)
	self.empty:SetVisible(false)

	self:Receiver(DRAG_DROP_CHANNEL, function(_, panels, dropped)
		if ( !dropped or !isfunction(self.OnDropReceived) ) then return end

		local itemPanel = panels and panels[1]
		if ( !IsValid(itemPanel) or !isnumber(itemPanel.itemID) or itemPanel.itemID < 1 ) then return end

		self:OnDropReceived(itemPanel)
	end)
end

function INVENTORY_PANE:SetTitle(text)
	self.titleText = text
	self.title:SetText(text, true)
end

function INVENTORY_PANE:SetStatus(text)
	self.status:SetText(text or "", true)
end

function INVENTORY_PANE:SetDropActive(state)
	self:Motion(0.16, {
		Target = {
			dropHighlight = state and 1 or 0,
		},
		Easing = "OutQuad",
	})
end

function INVENTORY_PANE:Populate(inventory, selectedItemID, filterName)
	self.scroller:Clear()
	self.selectedItemID = selectedItemID

	if ( !istable(inventory) ) then
		self.empty:SetText(ax.localization:GetPhrase("container.empty_inventory"), true)
		self.empty:SetVisible(true)
		return
	end

	local entries = {}
	for _, item in pairs(inventory:GetItems() or {}) do
		if ( !istable(item) ) then
			continue
		end

		if ( filterName and #filterName > 0 and filterName != "") then
			if ( !string.find(string.lower(item:GetName()), string.lower(filterName), 1, true) ) then
				continue
			end
		end

		entries[#entries + 1] = item
	end

	table.sort(entries, function(a, b)
		local nameA = string.lower(tostring(a:GetName() or a.class or ""))
		local nameB = string.lower(tostring(b:GetName() or b.class or ""))

		if ( nameA == nameB ) then
			return (a.id or 0) < (b.id or 0)
		end

		return nameA < nameB
	end)

	self.empty:SetVisible(entries[1] == nil)
	self.empty:SetText(ax.localization:GetPhrase("container.empty_inventory"), true)

	for i = 1, #entries do
		local itemPanel = self.scroller:Add("ax.container.item")
		itemPanel:Dock(TOP)
		itemPanel:DockMargin(0, 0, 0, 6)
		itemPanel:SetItem(entries[i])
		itemPanel:SetSelected(selectedItemID == entries[i].id)
		itemPanel:GetParent().OnItemPressed = function(_, pressedItem)
			if ( isfunction(self.OnItemSelected) ) then
				self:OnItemSelected(pressedItem.itemID)
			end
		end
		itemPanel:GetParent().OnItemDoubleClicked = function(_, pressedItem)
			if ( isfunction(self.OnItemActivated) ) then
				self:OnItemActivated(pressedItem.itemID)
			end
		end
	end
end

vgui.Register("ax.container.inventorypane", INVENTORY_PANE, "EditablePanel")

function PANEL:Init()
	local width, height = GetWindowSize()
	self:SetSize(width, height)
	self:Center()
	self:MakePopup()
	self:SetDeleteOnClose(true)
	self:SetBackgroundBlur(true)
	self:SetTitle("")

	self.nextRefresh = 0
	self.lastPlayerSignature = ""
	self.lastContainerSignature = ""
	self.selectedPlayerItemID = nil
	self.selectedContainerItemID = nil
	self.openedBlend = 0
	self.weightFraction = 0

	self:DockPadding(16, 70, 16, 16)

	if ( IsValid(self.lblTitle) ) then
		self.lblTitle:SetVisible(false)
	end

	self.header = self:Add("EditablePanel")
	self.header:Dock(TOP)
	self.header:SetTall(GetHeaderHeight())
	self.header:DockMargin(0, 0, 0, 12)
	self.header.Paint = function(this, width, height)
		ax.theme:DrawGlassPanel(0, 0, width, height, {
			radius = PANEL_RADIUS,
			blur = 1.15,
		})
	end

	self.headerTitle = self.header:Add("ax.text")
	self.headerTitle:Dock(TOP)
	self.headerTitle:DockMargin(16, 14, 16, 0)
	self.headerTitle:SetFont("ax.huge.bold")

	self.headerSubtitle = self.header:Add("ax.text")
	self.headerSubtitle:Dock(TOP)
	self.headerSubtitle:DockMargin(16, 0, 16, 0)
	self.headerSubtitle:SetFont("ax.regular")

	self.metaStrip = self.header:Add("EditablePanel")
	self.metaStrip:Dock(BOTTOM)
	self.metaStrip:SetTall(44)
	self.metaStrip:DockMargin(12, 0, 12, 12)
	self.metaStrip.Paint = nil

	self.weightProgress = self.metaStrip:Add("EditablePanel")
	self.weightProgress:Dock(FILL)
	self.weightProgress.Paint = function(this, width, height)
		local glass = ax.theme:GetGlass()
		ax.theme:DrawGlassPanel(0, 0, width, height, {
			radius = PANEL_RADIUS - 2,
			blur = 0.65,
			fill = ax.theme:ScaleAlpha(glass.input, ax.theme:GetMetrics().opacity),
		})

		local fraction = math.Clamp(GetAnimatedValue(self, "weightFraction", 0), 0, 1)
		if ( fraction > 0 ) then
			ax.render.Draw(PANEL_RADIUS - 2, 0, 0, width * fraction, height, ax.theme:ScaleAlpha(glass.progress, 0.9), ax.render.SHAPE_IOS)
		end
	end

	self.weightText = self.weightProgress:Add("ax.text")
	self.weightText:Dock(FILL)
	self.weightText:SetFont("ax.regular.bold")
	self.weightText:SetContentAlignment(5)

	self.moneyText = self.metaStrip:Add("ax.text")
	self.moneyText:Dock(RIGHT)
	self.moneyText:SetFont("ax.regular.bold")
	self.moneyText:SetContentAlignment(6)
	self.moneyText:DockMargin(12, 0, 12, 0)

	self.content = self:Add("EditablePanel")
	self.content:Dock(FILL)
	self.content.Paint = nil

	self.playerPane = self.content:Add("ax.container.inventorypane")
	self.playerPane:Dock(LEFT)
	self.playerPane:DockMargin(0, 0, 12, 0)
	self.playerPane:SetTitle(ax.localization:GetPhrase("container.your_inventory"))
	self.playerPane.OnItemSelected = function(_, itemID)
		self.selectedPlayerItemID = itemID
		self.selectedContainerItemID = nil
		self:RefreshInventories(true)
	end
	self.playerPane.OnItemActivated = function(_, itemID)
		self.selectedPlayerItemID = itemID
		self:StoreSelected()
	end
	self.playerPane.OnDropReceived = function(_, itemPanel)
		self.selectedContainerItemID = itemPanel.itemID
		self:TakeSelected()
	end

	self.playerPaneSearch = self.playerPane.header:Add("ax.text.entry")
	self.playerPaneSearch:SetPlaceholderText(ax.localization:GetPhrase("container.search_your_inventory"))
	self.playerPaneSearch:Dock(FILL)
	self.playerPaneSearch:DockMargin(12, 18, 0, 16)
	self.playerPaneSearch:SetUpdateOnType(true)
	self.playerPaneSearch.OnTextChanged = function(this)
		local plyInv = self:GetPlayerInventory()
		if ( !plyInv ) then return end

		local val = this:GetValue()

		self.playerPane:Populate(plyInv, self.selectedPlayerItemID, val)
		self.playerPane:SetStatus(string.format("%d", table.Count(plyInv:GetItems() or {})))
	end

	self.actionRail = self.content:Add("EditablePanel")
	self.actionRail:Dock(LEFT)
	self.actionRail:SetWide(GetActionRailWidth())
	self.actionRail:DockMargin(0, 0, 12, 0)
	self.actionRail.Paint = function(this, width, height)
		ax.theme:DrawGlassPanel(0, 0, width, height, {
			radius = PANEL_RADIUS,
			blur = 1.0,
		})
	end

	self.transferLabel = self.actionRail:Add("ax.text")
	self.transferLabel:Dock(TOP)
	self.transferLabel:DockMargin(8, 18, 8, 12)
	self.transferLabel:SetFont("ax.small.bold")
	self.transferLabel:SetText(ax.localization:GetPhrase("container.transfer_actions"), true)
	self.transferLabel:SetContentAlignment(5)

	self.takeButton = self.actionRail:Add("ax.button")
	self.takeButton:Dock(TOP)
	self.takeButton:DockMargin(12, 8, 12, 8)
	self.takeButton:SetText(ax.localization:GetPhrase("container.take_button"), true)
	self.takeButton.DoClick = function()
		self:TakeSelected()
	end

	self.storeButton = self.actionRail:Add("ax.button")
	self.storeButton:Dock(TOP)
	self.storeButton:DockMargin(12, 0, 12, 8)
	self.storeButton:SetText(ax.localization:GetPhrase("container.store_button"), true)
	self.storeButton.DoClick = function()
		self:StoreSelected()
	end

	self.hintText = self.actionRail:Add("ax.text")
	self.hintText:Dock(TOP)
	self.hintText:DockMargin(10, 14, 10, 0)
	self.hintText:SetFont("ax.small")
	self.hintText:SetText(ax.localization:GetPhrase("container.drag_hint"), true)
	self.hintText:SetWrap(true)
	self.hintText:SetAutoStretchVertical(true)
	self.hintText:SetContentAlignment(5)

	self.containerPane = self.content:Add("ax.container.inventorypane")
	self.containerPane:Dock(FILL)
	self.containerPane:SetTitle(ax.localization:GetPhrase("container.contents_title"))
	self.containerPane.title:Dock(RIGHT)
	self.containerPane.status:Dock(LEFT)
	self.containerPane.OnItemSelected = function(_, itemID)
		self.selectedContainerItemID = itemID
		self.selectedPlayerItemID = nil
		self:RefreshInventories(true)
	end
	self.containerPane.OnItemActivated = function(_, itemID)
		self.selectedContainerItemID = itemID
		self:TakeSelected()
	end
	self.containerPane.OnDropReceived = function(_, itemPanel)
		self.selectedPlayerItemID = itemPanel.itemID
		self:StoreSelected()
	end

	self:PlayIntro()
end

function PANEL:PlayIntro()
	self:SetAlpha(0)
	local startX, startY = self:GetPos()
	self:SetPos(startX, startY + 24)

	self:Motion(0.22, {
		Target = {
			openedBlend = 1,
		},
		Easing = "OutQuad",
		Think = function()
			self:SetAlpha(Lerp(self.openedBlend, 0, 255))
			self:SetPos(startX, startY + (1 - self.openedBlend) * 24)
		end,
	})
end

function PANEL:SetContainer(entity, inventoryID, displayName, searchTime, money, maxWeight)
	self.entity = entity
	self.inventoryID = inventoryID
	self.displayName = isstring(displayName) and displayName or ax.localization:GetPhrase("container.title")
	self.searchTime = tonumber(searchTime) or 0
	self.money = math.max(tonumber(money) or 0, 0)
	self.maxWeight = math.max(tonumber(maxWeight) or 0, 0)

	self.headerTitle:SetText(self.displayName, true)
	self:RefreshInventories(true)
end

function PANEL:PerformLayout(width, height)
	self.BaseClass.PerformLayout(self, width, height)

	if ( !IsValid(self.content) or !IsValid(self.header) or !IsValid(self.actionRail) or !IsValid(self.playerPane) ) then
		return
	end

	local actionRailWidth = GetActionRailWidth()
	local contentWidth = self.content:GetWide()
	local paneSpacing = 24
	local paneWidth = math.max(math.floor((contentWidth - actionRailWidth - paneSpacing) * 0.5), ax.util:ScreenScale(180))

	self.header:SetTall(GetHeaderHeight())
	self.actionRail:SetWide(actionRailWidth)
	self.playerPane:SetWide(paneWidth)

	if ( IsValid(self.headerTitle) ) then
		self.headerTitle:SetWrap(true)
		self.headerTitle:SetAutoStretchVertical(true)
	end

	if ( IsValid(self.headerSubtitle) ) then
		self.headerSubtitle:SetWrap(true)
		self.headerSubtitle:SetAutoStretchVertical(true)
	end
end

function PANEL:GetPlayerInventory()
	local client = LocalPlayer()
	if ( !ax.util:IsValidPlayer(client) ) then
		return nil
	end

	local character = client:GetCharacter()
	if ( !istable(character) ) then
		return nil
	end

	return character:GetInventory()
end

function PANEL:GetContainerInventory()
	if ( !isnumber(self.inventoryID) ) then
		return nil
	end

	return ax.inventory.instances[self.inventoryID]
end

function PANEL:HandleDroppedItem(itemPanel, targetInventoryID)
	if ( !IsValid(itemPanel) or !isnumber(itemPanel.itemID) or itemPanel.itemID < 1 ) then
		return
	end

	local item = ax.item.instances[itemPanel.itemID]
	if ( !istable(item) ) then
		return
	end

	local sourceInventoryID = tonumber(item.invID) or 0
	local playerInventory = self:GetPlayerInventory()
	local containerInventory = self:GetContainerInventory()
	local playerInventoryID = istable(playerInventory) and playerInventory:GetID() or 0
	local containerInventoryID = istable(containerInventory) and containerInventory:GetID() or self.inventoryID

	if ( sourceInventoryID == targetInventoryID ) then
		return
	end

	if ( targetInventoryID == containerInventoryID ) then
		if ( sourceInventoryID != playerInventoryID ) then
			return
		end

		self.selectedPlayerItemID = item.id
		self.selectedContainerItemID = nil
		self:StoreSelected()
		return
	end

	if ( targetInventoryID == playerInventoryID ) then
		if ( sourceInventoryID != containerInventoryID ) then
			return
		end

		self.selectedContainerItemID = item.id
		self.selectedPlayerItemID = nil
		self:TakeSelected()
	end
end

function PANEL:UpdateHeader(containerInventory)
	local details = {}

	if ( self.searchTime > 0 ) then
		details[#details + 1] = ax.localization:GetPhrase("container.open_time", self.searchTime)
	end

	if ( self.money > 0 ) then
		details[#details + 1] = ax.localization:GetPhrase("container.money", self.money)
	end

	self.headerSubtitle:SetText(#details > 0 and table.concat(details, "    •    ") or ax.localization:GetPhrase("container.move_items"), true)

	local currentWeight = istable(containerInventory) and containerInventory:GetWeight() or 0
	local weightSuffix = ax.localization:GetPhrase("inventory.weight.abbreviation")
	local safeMaxWeight = math.max(self.maxWeight, 0.001)

	self.weightText:SetText(ax.localization:GetPhrase("container.capacity", math.Round(currentWeight, 2), weightSuffix, math.Round(self.maxWeight, 2), weightSuffix), true)
	self.moneyText:SetText(self.money > 0 and ax.localization:GetPhrase("container.money", self.money) or "", true)

	self:Motion(0.18, {
		Target = {
			weightFraction = math.Clamp(currentWeight / safeMaxWeight, 0, 1),
		},
		Easing = "OutQuad",
	})
end

function PANEL:UpdateButtons()
	self.takeButton:SetEnabled(isnumber(self.selectedContainerItemID) and self.selectedContainerItemID > 0)
	self.storeButton:SetEnabled(isnumber(self.selectedPlayerItemID) and self.selectedPlayerItemID > 0)
end

function PANEL:RefreshInventories(force)
	if ( !IsValid(self.entity) or self.entity:GetClass() != "ax_container" ) then
		self:Close()
		return
	end

	local playerInventory = self:GetPlayerInventory()
	local containerInventory = self:GetContainerInventory()
	if ( !istable(playerInventory) or !istable(containerInventory) ) then
		self:Close()
		return
	end

	local playerSignature = BuildInventorySignature(playerInventory)
	local containerSignature = BuildInventorySignature(containerInventory)

	if ( force or playerSignature != self.lastPlayerSignature ) then
		self.lastPlayerSignature = playerSignature
		self.playerPane:Populate(playerInventory, self.selectedPlayerItemID, self.playerPaneSearch:GetText())
		self.playerPane:SetStatus(string.format("%d", table.Count(playerInventory:GetItems() or {})))
	end

	if ( force or containerSignature != self.lastContainerSignature ) then
		self.lastContainerSignature = containerSignature
		self.containerPane:Populate(containerInventory, self.selectedContainerItemID)
		self.containerPane:SetStatus(string.format("%d", table.Count(containerInventory:GetItems() or {})))
	end

	self:UpdateHeader(containerInventory)
	self:UpdateButtons()

	local dragging = dragndrop.IsDragging()
	if ( dragging ) then
		local payload = dragndrop.GetDroppable(DRAG_DROP_CHANNEL)
		local itemPanel = payload and payload[1]
		if ( IsValid(itemPanel) ) then
			local playerInventoryID = playerInventory:GetID()
			local sourceInventoryID = itemPanel.item and itemPanel.item.invID or 0
			self.playerPane:SetDropActive(sourceInventoryID == self.inventoryID)
			self.containerPane:SetDropActive(sourceInventoryID == playerInventoryID)
			return
		end
	end

	self.playerPane:SetDropActive(false)
	self.containerPane:SetDropActive(false)
end

function PANEL:StoreSelected()
	if ( !self.selectedPlayerItemID ) then
		return
	end

	ax.net:Start("item.transfer", self.selectedPlayerItemID, self.inventoryID)
	self.selectedContainerItemID = nil
end

function PANEL:TakeSelected()
	if ( !self.selectedContainerItemID ) then
		return
	end

	local playerInventory = self:GetPlayerInventory()
	if ( !istable(playerInventory) ) then
		return
	end

	ax.net:Start("item.transfer", self.selectedContainerItemID, playerInventory:GetID())
	self.selectedPlayerItemID = nil
end

function PANEL:Think()
	if ( self.nextRefresh > CurTime() ) then
		return
	end

	self.nextRefresh = CurTime() + REFRESH_INTERVAL
	self:RefreshInventories(false)
end

function PANEL:OnRemove()
	if ( ax.container ) then
		ax.container.panel = nil
	end

	if ( self.bSkipServerClose ) then
		return
	end

	ax.net:Start("container.close", self.entity)
end

vgui.Register("ax.container.storage", PANEL, "ax.frame")
