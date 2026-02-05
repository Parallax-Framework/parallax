

local PANEL = {}

AccessorFunc( PANEL, "m_bBorder",			"DrawBorder" )
AccessorFunc( PANEL, "m_bDeleteSelf",		"DeleteSelf" )
AccessorFunc( PANEL, "m_iMinimumWidth",		"MinimumWidth" )
AccessorFunc( PANEL, "m_bDrawColumn",		"DrawColumn" )
AccessorFunc( PANEL, "m_iMaxHeight",		"MaxHeight" )

AccessorFunc( PANEL, "m_pOpenSubMenu",		"OpenSubMenu" )

function PANEL:Init()

	self:SetIsMenu( true )
	self:SetDrawBorder( true )
	self:SetPaintBackground( true )
	self:SetMinimumWidth( 100 )
	self:SetDrawOnTop( true )
	self:SetMaxHeight( ScrH() * 0.9 )
	self:SetDeleteSelf( true )

	self:SetPadding( 0 )

	-- Automatically remove this panel when menus are to be closed
	RegisterDermaMenuForClose( self )

end

function PANEL:AddPanel( pnl )

	self:AddItem( pnl )
	pnl.ParentMenu = self

end

local MENU_OPTION_HOVERED_COLOR = Color(11, 11, 11, 50)
local MENU_OPTION_HOVERED_MATERIAL = Material("parallax/icons/chevron-right.png")
function PANEL:AddOption( strText, funcFunction )

	local pnl = vgui.Create( "DMenuOption", self )
	pnl:SetMenu( self )
	pnl:SetText( ax.localization:GetPhrase(strText) )
	pnl:SetFont( "ax.small" )
	if ( funcFunction ) then pnl.DoClick = funcFunction end

	pnl.Paint = function( p, w, h )
		--derma.SkinHook( "Paint", "MenuOption", p, w, h )

		if ( p.Hovered ) then
			local theme = ax.theme:GetGlass()

			ax.util:DrawGradient(0, "left", 0, 0, w, h, MENU_OPTION_HOVERED_COLOR)

			ax.render.DrawMaterial(0, 8, h / 2 - 8, 16, 16, theme.comboboxHoveredArrow, MENU_OPTION_HOVERED_MATERIAL)
		end
	end

	pnl.UpdateColours = function(p)
		if ( p.Hovered ) then
			return p:SetTextColor( color_white )
		end

		p:SetTextColor( color_white )
	end

	self:AddPanel( pnl )

	return pnl

end

function PANEL:AddCVar( strText, convar, on, off, funcFunction )

	local pnl = vgui.Create( "DMenuOptionCVar", self )
	pnl:SetMenu( self )
	pnl:SetText( ax.localization:GetPhrase(strText) )
	pnl:SetFont( "ax.regular" )
	if ( funcFunction ) then pnl.DoClick = funcFunction end

	pnl:SetConVar( convar )
	pnl:SetValueOn( on )
	pnl:SetValueOff( off )

	self:AddPanel( pnl )

	return pnl

end

function PANEL:AddSpacer()

	local pnl = vgui.Create( "DPanel", self )
	pnl.Paint = function( p, w, h )
		--derma.SkinHook( "Paint", "MenuSpacer", p, w, h )
	end

	pnl:SetTall( 1 )
	self:AddPanel( pnl )

	return pnl

end

function PANEL:AddSubMenu( strText, funcFunction )

	local pnl = vgui.Create( "DMenuOption", self )
	local SubMenu = pnl:AddSubMenu()

	pnl:SetText( ax.localization:GetPhrase(strText) )
	pnl:SetFont( "ax.regular" )
	if ( funcFunction ) then pnl.DoClick = funcFunction end

	self:AddPanel( pnl )

	return SubMenu, pnl

end

function PANEL:Hide()

	local openmenu = self:GetOpenSubMenu()
	if ( openmenu ) then
		openmenu:Hide()
	end

	self:SetVisible( false )
	self:SetOpenSubMenu( nil )

end

function PANEL:OpenSubMenu( item, menu )

	-- Do we already have a menu open?
	local openmenu = self:GetOpenSubMenu()
	if ( IsValid( openmenu ) && openmenu:IsVisible() ) then

		-- Don't open it again!
		if ( menu && openmenu == menu ) then return end

		-- Close it!
		self:CloseSubMenu( openmenu )

	end

	if ( !IsValid( menu ) ) then return end

	local x, y = item:LocalToScreen( self:GetWide(), 0 )
	menu:Open( x - 3, y, false, item )

	self:SetOpenSubMenu( menu )

end

function PANEL:CloseSubMenu( menu )

	menu:Hide()
	self:SetOpenSubMenu( nil )

end

function PANEL:Paint( w, h )

	if ( !self:GetPaintBackground() ) then return end

	--derma.SkinHook( "Paint", "Menu", self, w, h )

	ax.theme:DrawGlassPanel(0, 0, w, h, {
		radius = 8,
		blur = 0.9,
		flags = ax.render.SHAPE_IOS,
		fill = ax.theme:GetGlass().menu,
		border = ax.theme:GetGlass().menuBorder
	})
	return true

end

function PANEL:ChildCount()
	return #self:GetCanvas():GetChildren()
end

function PANEL:GetChild( num )
	return self:GetCanvas():GetChildren()[ num ]
end

function PANEL:PerformLayout( w, h )

	local minW = self:GetMinimumWidth()

	-- Find the widest one
	for k, pnl in ipairs( self:GetCanvas():GetChildren() ) do

		pnl:InvalidateLayout( true )
		minW = math.max( minW, pnl:GetWide() )

	end

	self:SetWide( minW )

	local y = 0 -- for padding

	for k, pnl in ipairs( self:GetCanvas():GetChildren() ) do

		pnl:SetWide( minW )
		pnl:SetPos( 0, y )
		pnl:InvalidateLayout( true )

		y = y + pnl:GetTall()

	end

	y = math.min( y, self:GetMaxHeight() )

	self:SetTall( y )

	--derma.SkinHook( "Layout", "Menu", self )



	DScrollPanel.PerformLayout( self, minW, h )

end

--[[---------------------------------------------------------
	Open - Opens the menu.
	x and y are optional, if they're not provided the menu
		will appear at the cursor.
-----------------------------------------------------------]]
function PANEL:Open( x, y, skipanimation, ownerpanel )

	RegisterDermaMenuForClose( self )

	local maunal = x && y

	x = x or gui.MouseX()
	y = y or gui.MouseY()

	local OwnerHeight = 0
	local OwnerWidth = 0

	if ( ownerpanel ) then
		OwnerWidth, OwnerHeight = ownerpanel:GetSize()
	end

	self:InvalidateLayout( true )

	local w = self:GetWide()
	local h = self:GetTall()

	self:SetSize( w, h )

	if ( y + h > ScrH() ) then y = ( ( maunal && ScrH() ) or ( y + OwnerHeight ) ) - h end
	if ( x + w > ScrW() ) then x = ( ( maunal && ScrW() ) or x ) - w end
	if ( y < 1 ) then y = 1 end
	if ( x < 1 ) then x = 1 end

	local p = self:GetParent()
	if ( IsValid( p ) && p:IsModal() ) then
		-- Can't popup while we are parented to a modal panel
		-- We will end up behind the modal panel in that case

		x, y = p:ScreenToLocal( x, y )

		-- We have to reclamp the values
		if ( y + h > p:GetTall() ) then y = p:GetTall() - h end
		if ( x + w > p:GetWide() ) then x = p:GetWide() - w end
		if ( y < 1 ) then y = 1 end
		if ( x < 1 ) then x = 1 end

		self:SetPos( x, y )
	else
		self:SetPos( x, y )

		-- Popup!
		self:MakePopup()
	end

	-- Make sure it's visible!
	self:SetVisible( true )

	-- Keep the mouse active while the menu is visible.
	self:SetKeyboardInputEnabled( false )

end

--
-- Called by DMenuOption
--
function PANEL:OptionSelectedInternal( option )

	self:OptionSelected( option, option:GetText() )

end

function PANEL:OptionSelected( option, text )

	-- For override

end

function PANEL:ClearHighlights()

	for k, pnl in ipairs( self:GetCanvas():GetChildren() ) do
		pnl.Highlight = nil
	end

end

function PANEL:HighlightItem( item )

	for k, pnl in ipairs( self:GetCanvas():GetChildren() ) do
		if ( pnl == item ) then
			pnl.Highlight = true
		end
	end

end

function PANEL:GenerateExample( ClassName, PropertySheet, Width, Height )

	local MenuItemSelected = function()
		Derma_Message( "Choosing a menu item worked!" )
	end

	local ctrl = vgui.Create( "Button" )
	ctrl:SetText( "Test Me!" )
	ctrl.DoClick = function()
		local menu = DermaMenu()

		menu:AddOption( "Option One", MenuItemSelected )
		menu:AddOption( "Option 2", MenuItemSelected )

		local submenu = menu:AddSubMenu( "Option Free" )
		submenu:AddOption( "Submenu 1", MenuItemSelected )
		submenu:AddOption( "Submenu 2", MenuItemSelected )

		menu:AddOption( "Option For", MenuItemSelected )

		menu:Open()
	end

	PropertySheet:AddSheet( ClassName, ctrl, nil, true, true )

end

vgui.Register("ax.dmenu", PANEL, "DScrollPanel")

PANEL = {}

Derma_Install_Convar_Functions( PANEL )

AccessorFunc( PANEL, "m_bDoSort", "SortItems", FORCE_BOOL )

local ARROW_MAT = Material( "parallax/icons/chevron-down.png" )
local COMBO_DISABLED_COLOR = Color(100, 100, 100, 100)
function PANEL:Init()

	-- Create button
	self.DropButton = vgui.Create( "DPanel", self )
	self.DropButton.Paint = function( panel, w, h )
		ax.render.DrawMaterial(0, 0, 0, w, h, color_white, ARROW_MAT)
	end
	self.DropButton:SetMouseInputEnabled( false )
	self.DropButton.ComboBox = self

	-- Setup internals
	self:SetTall( 22 )
	self:Clear()

	self:SetContentAlignment( 4 )
	self:SetTextInset( 8, 0 )
	self:SetIsMenu( true )
	self:SetSortItems( true )
	self:SetFont( "ax.regular" )
	self.UpdateColours = function( p )
		if ( !p:IsEnabled() ) then
			return p:SetTextColor( ax.theme:GetGlass().textMuted )
		end

		p:SetTextColor( ax.theme:GetGlass().text )
	end

end

function PANEL:Clear()

	self:SetText( "" )
	self.Choices = {}
	self.Data = {}
	self.ChoiceIcons = {}
	self.Spacers = {}
	self.selected = nil

	self:CloseMenu()

end

function PANEL:GetOptionText( index )

	return self.Choices[ index ]

end

function PANEL:GetOptionData( index )

	return self.Data[ index ]

end

function PANEL:GetOptionTextByData( data )

	for id, dat in pairs( self.Data ) do
		if ( dat == data ) then
			return self:GetOptionText( id )
		end
	end

	-- Try interpreting it as a number
	for id, dat in pairs( self.Data ) do
		if ( dat == tonumber( data ) ) then
			return self:GetOptionText( id )
		end
	end

	-- In case we fail
	return data

end

function PANEL:PerformLayout( w, h )

	self.DropButton:SetSize( 15, 15 )
	self.DropButton:AlignRight( 4 )
	self.DropButton:CenterVertical()

	-- Make sure the text color is updated
	DButton.PerformLayout( self, w, h )

end

function PANEL:ChooseOption( value, index )

	self:CloseMenu()
	self:SetText( ax.localization:GetPhrase(value) )

	-- This should really be the here, but it is too late now and convar
	-- changes are handled differently by different child elements
	-- self:ConVarChanged( self.Data[ index ] )

	self.selected = index
	self:OnSelect( index, value, self.Data[ index ] )

end

function PANEL:ChooseOptionID( index )

	local value = self:GetOptionText( index )
	self:ChooseOption( value, index )

end

function PANEL:GetSelectedID()

	return self.selected

end

function PANEL:GetSelected()

	if ( !self.selected ) then return end

	return self:GetOptionText( self.selected ), self:GetOptionData( self.selected )

end

function PANEL:OnSelect( index, value, data )

	-- For override

end

function PANEL:OnMenuOpened( menu )

	-- For override

end

function PANEL:AddSpacer()

	self.Spacers[ #self.Choices ] = true

end

function PANEL:AddChoice( value, data, select, icon )

	local index = table.insert( self.Choices, value )

	if ( data ) then
		self.Data[ index ] = data
	end

	if ( icon ) then
		self.ChoiceIcons[ index ] = icon
	end

	if ( select ) then

		self:ChooseOption( value, index )

	end

	return index

end

function PANEL:RemoveChoice( index )

	if ( !isnumber( index ) ) then return end

	local text = table.remove( self.Choices, index )
	local data = table.remove( self.Data, index )
	return text, data

end

function PANEL:IsMenuOpen()

	return IsValid( self.Menu ) && self.Menu:IsVisible()

end

function PANEL:OpenMenu( pControlOpener )

	if ( pControlOpener && pControlOpener == self.TextEntry ) then
		return
	end

	-- Don't do anything if there aren't any options..
	if ( self.Choices[1] == nil ) then return end

	-- If the menu still exists and hasn't been deleted
	-- then just close it and don't open a new one.
	self:CloseMenu()

	-- If we have a modal parent at some level, we gotta parent to
	-- that or our menu items are not gonna be selectable
	local parent = self
	while ( IsValid( parent ) && !parent:IsModal() ) do
		parent = parent:GetParent()
	end
	if ( !IsValid( parent ) ) then parent = self end

	CloseDermaMenus()
	self.Menu = vgui.Create( "ax.dmenu", parent )

	if ( self:GetSortItems() ) then
		local sorted = {}
		for k, v in ipairs( self.Choices ) do
			local val = tostring( v )
			if ( string.len( val ) > 1 && !tonumber( val ) && val:StartsWith( "#" ) ) then val = language.GetPhrase( val:sub( 2 ) ) end
			sorted[#sorted + 1] = { id = k, data = v, label = val }
		end

		for k, v in SortedPairsByMemberValue( sorted, "label" ) do
			local option = self.Menu:AddOption( v.data, function() self:ChooseOption( v.data, v.id ) end )

			if ( self.ChoiceIcons[ v.id ] ) then
				option:SetIcon( self.ChoiceIcons[ v.id ] )
			end

			if ( self.Spacers[ v.id ] ) then
				self.Menu:AddSpacer()
			end
		end
	else
		for k, v in ipairs( self.Choices ) do
			local option = self.Menu:AddOption( v, function() self:ChooseOption( v, k ) end )
			if ( self.ChoiceIcons[ k ] ) then
				option:SetIcon( self.ChoiceIcons[ k ] )
			end

			if ( self.Spacers[ k ] ) then
				self.Menu:AddSpacer()
			end
		end
	end

	local x, y = self:LocalToScreen( 0, self:GetTall() )

	self.Menu:SetMinimumWidth( self:GetWide() )
	self.Menu:Open( x, y, false, self )

	self:OnMenuOpened( self.Menu )

end

function PANEL:CloseMenu()

	if ( IsValid( self.Menu ) ) then
		self.Menu:Remove()
	end

	self.Menu = nil

end

-- This really should use a convar change hook
function PANEL:CheckConVarChanges()

	if ( !self.m_strConVar ) then return end

	local strValue = GetConVarString( self.m_strConVar )
	if ( self.m_strConVarValue == strValue ) then return end

	self.m_strConVarValue = strValue

	self:SetValue( self:GetOptionTextByData( self.m_strConVarValue ) )

end

function PANEL:Think()

	self:CheckConVarChanges()

end

function PANEL:SetValue( strValue )

	self:SetText( ax.localization:GetPhrase(strValue) )

end

function PANEL:DoClick()

	if ( self:IsMenuOpen() ) then
		return self:CloseMenu()
	end

	self:OpenMenu()

end

function PANEL:Paint(width, height)
	local glass = ax.theme:GetGlass()
	ax.theme:DrawGlassPanel(0, 0, width, height, {
		radius = math.max(4, math.min(8, height * 0.35)),
		blur = 0.7,
		flags = ax.render.SHAPE_IOS,
		fill = glass.input,
		border = glass.inputBorder
	})
end

vgui.Register("ax.combobox", PANEL, "DButton")
