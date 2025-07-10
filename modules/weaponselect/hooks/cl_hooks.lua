--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

if ( CLIENT ) then
    -- Animation variables
    MODULE.currentIndex = MODULE.currentIndex or 1
    MODULE.targetIndex = MODULE.targetIndex or MODULE.currentIndex
    MODULE.alpha = MODULE.alpha or 0
    MODULE.targetAlpha = MODULE.targetAlpha or 0
    MODULE.fadeTime = MODULE.fadeTime or 0
    MODULE.animTime = MODULE.animTime or 0
    MODULE.slideOffset = MODULE.slideOffset or 0
    MODULE.targetSlideOffset = MODULE.targetSlideOffset or 0
    MODULE.weaponIcons = MODULE.weaponIcons or {}
    MODULE.weaponDescriptions = MODULE.weaponDescriptions or {}
    MODULE.glowAlpha = MODULE.glowAlpha or 0
    MODULE.pulseTime = MODULE.pulseTime or 0
    MODULE.slideDirection = MODULE.slideDirection or 0
    MODULE.scaleAnimation = MODULE.scaleAnimation or {}
    MODULE.bounceAnimation = MODULE.bounceAnimation or {}

    -- Visual settings for modern flat design
    local ITEM_HEIGHT = ScreenScaleH(20)
    local ITEM_SPACING = ScreenScaleH(4)
    local ICON_SIZE = ScreenScaleH(16)
    local MARGIN = ScreenScaleH(8)

    -- Disable default weapon selection
    function MODULE:HUDShouldDraw(name)
        if ( name == "CHudWeaponSelection" ) then
            return false
        end
    end

    -- Initialize scale animations for weapons
    function MODULE:InitializeScaleAnimations(weaponCount)
        self.scaleAnimation = {}
        self.bounceAnimation = {}
        for i = 1, weaponCount do
            self.scaleAnimation[i] = 1
            self.bounceAnimation[i] = 0
        end
    end

    -- Update weapon descriptions
    function MODULE:UpdateWeaponDescriptions()
        local client = ax.client
        if ( !IsValid(client) ) then return end

        local weapons = client:GetWeapons()
        self.weaponDescriptions = {}

        for i, weapon in ipairs(weapons) do
            if ( IsValid(weapon) ) then
                local desc = ""
                if ( weapon.Instructions and weapon.Instructions != "" ) then
                    desc = weapon.Instructions
                elseif ( weapon.Description and weapon.Description != "" ) then
                    desc = weapon.Description
                else
                    desc = "No description available"
                end
                self.weaponDescriptions[i] = desc
            end
        end
    end

    -- Get weapon display name
    function MODULE:GetWeaponName(weapon)
        if ( !IsValid(weapon) ) then return "Unknown" end

        if ( weapon.GetPrintName ) then
            return weapon:GetPrintName()
        end

        local name = language.GetPhrase(weapon:GetClass())
        if ( name and name != weapon:GetClass() ) then
            return name
        end

        return weapon:GetClass()
    end

    -- Main HUD painting function
    function MODULE:HUDPaint()
        if ( !ax.option:Get("weaponselect.enabled", true) ) then return end

        local client = ax.client
        if ( !IsValid(client) or !client:Alive() ) then
            self.alpha = 0
            self.targetAlpha = 0
            return
        end

        local weapons = client:GetWeapons()
        if ( !weapons or #weapons == 0 ) then return end

        local frameTime = FrameTime()
        local currentTime = CurTime()
        local animSpeed = ax.option:Get("weaponselect.animspeed", 8)

        -- Update animations with custom easing
        local easingFunc = MODULE.Animation and MODULE.Animation:GetCurrentEasing() or function(t) return t end

        -- Calculate eased progress for different animation components
        local alphaProgress = math.Clamp(frameTime * animSpeed, 0, 1)
        local slideProgress = math.Clamp(frameTime * animSpeed * 2, 0, 1)
        local glowProgress = math.Clamp(frameTime * animSpeed * 3, 0, 1)

        self.alpha = Lerp(easingFunc(alphaProgress), self.alpha, self.targetAlpha)
        self.targetIndex = Lerp(frameTime * animSpeed * 1.5, self.targetIndex, self.currentIndex)
        self.slideOffset = Lerp(easingFunc(slideProgress), self.slideOffset, self.targetSlideOffset)
        self.glowAlpha = Lerp(easingFunc(glowProgress), self.glowAlpha, self.targetAlpha * 0.3)

        -- Update pulse animation
        self.pulseTime = self.pulseTime + frameTime * 4
        local pulseValue = math.sin(self.pulseTime) / 2 + 0.5

        -- Update scale animations with easing
        for i = 1, #weapons do
            local targetScale = (i == self.currentIndex) and 1.1 or 1
            local targetBounce = (i == self.currentIndex) and math.sin(currentTime * 8) * 2 or 0

            local scaleProgress = math.Clamp(frameTime * animSpeed * 2, 0, 1)
            local bounceProgress = math.Clamp(frameTime * animSpeed * 3, 0, 1)

            self.scaleAnimation[i] = Lerp(easingFunc(scaleProgress), self.scaleAnimation[i] or 1, targetScale)
            self.bounceAnimation[i] = Lerp(easingFunc(bounceProgress), self.bounceAnimation[i] or 0, targetBounce)
        end

        -- Auto-fade
        if ( self.fadeTime > 0 and self.fadeTime < currentTime ) then
            self.targetAlpha = 0
        end

        -- Don't render if not visible
        if ( self.alpha < 0.01 ) then return end

        -- Get dynamic panel settings
        local panelWidth = math.max(300, ax.option:Get("weaponselect.size.width", 320))
        local panelHeight = math.max(200, ax.option:Get("weaponselect.size.height", 480))
        local posX = ax.option:Get("weaponselect.position.x", 0.05)
        local posY = ax.option:Get("weaponselect.position.y", 0.5)
        local blurEnabled = ax.option:Get("weaponselect.blur.enabled", true)
        local blurIntensity = ax.option:Get("weaponselect.blur.intensity", 5)

        -- Calculate panel position
        local scrW, scrH = ScrW(), ScrH()
        local panelX = scrW * posX + self.slideOffset
        local panelY = (scrH - panelHeight) * posY

        -- Modern flat background with strong blur
        if ( blurEnabled ) then
            -- Create a simple blur effect using render targets
            local blurAmount = math.Clamp(self.alpha / 255 * blurIntensity, 0, blurIntensity)
            if ( blurAmount > 0 ) then
                ax.util:DrawBlurRect(panelX, panelY, panelWidth, panelHeight, blurAmount, nil, self.alpha * 0.8)
            end
        end

        local THEME = MODULE:GetThemeColors()

        -- Clean flat background panel
        surface.SetDrawColor(THEME.background.r, THEME.background.g, THEME.background.b, self.alpha * 0.85)
        surface.DrawRect(panelX, panelY, panelWidth, panelHeight)

        -- Subtle accent line at top
        surface.SetDrawColor(THEME.accent.r, THEME.accent.g, THEME.accent.b, self.alpha * 0.7)
        surface.DrawRect(panelX, panelY, panelWidth, 2)

        -- Clean title with framework font
        surface.SetTextColor(THEME.text.r, THEME.text.g, THEME.text.b, self.alpha)
        surface.SetFont("ax.large.bold")
        local titleText = "WEAPONS"
        local titleW, _ = surface.GetTextSize(titleText)
        surface.SetTextPos(panelX + (panelWidth - titleW) / 2, panelY + 16)
        surface.DrawText(titleText)

        -- Draw weapons
        local startY = panelY + 80
        local visibleItems = math.floor((panelHeight - 120) / (ITEM_HEIGHT + ITEM_SPACING))
        local startIndex = math.max(1, math.floor(self.targetIndex - visibleItems / 2))
        local endIndex = math.min(#weapons, startIndex + visibleItems - 1)

        for i = startIndex, endIndex do
            local weapon = weapons[i]
            if ( !IsValid(weapon) ) then continue end

            local itemY = startY + (i - startIndex) * (ITEM_HEIGHT + ITEM_SPACING)
            local itemX = panelX + MARGIN
            local itemW = panelWidth - MARGIN * 2
            local itemH = ITEM_HEIGHT

            -- Apply bounce animation
            local bounceOffset = self.bounceAnimation[i] or 0
            itemY = itemY + bounceOffset

            -- Scale animation
            local scale = self.scaleAnimation[i] or 1
            local scaledW = itemW * scale
            local scaledH = itemH * scale
            local scaleOffsetX = (scaledW - itemW) / 2
            local scaleOffsetY = (scaledH - itemH) / 2

            -- Item background - flat design
            local isSelected = (i == self.currentIndex)
            local itemBgColor = isSelected and THEME.selected or THEME.item

            -- Apply alpha
            itemBgColor = ColorAlpha(itemBgColor, self.alpha * 0.8)

            -- Selection pulse effect
            if ( isSelected ) then
                local pulseAlpha = self.alpha * (0.6 + pulseValue * 0.2)
                itemBgColor = ColorAlpha(THEME.selected, pulseAlpha)
            end

            -- Flat item background
            surface.SetDrawColor(itemBgColor.r, itemBgColor.g, itemBgColor.b, itemBgColor.a)
            surface.DrawRect(itemX - scaleOffsetX, itemY - scaleOffsetY, scaledW, scaledH)

            -- Selection indicator - flat accent line
            if ( isSelected ) then
                local indicatorColor = ColorAlpha(THEME.accent, self.alpha * 0.9)
                surface.SetDrawColor(indicatorColor.r, indicatorColor.g, indicatorColor.b, indicatorColor.a)
                surface.DrawRect(itemX - scaleOffsetX, itemY - scaleOffsetY, 3, scaledH)
            end

            -- Weapon icon
            local iconX = itemX + 8
            local iconY = itemY + (itemH - ICON_SIZE) / 2

            local iconMaterial = MODULE.WeaponIcons:GetIcon(weapon)
            if ( iconMaterial ) then
                surface.SetMaterial(iconMaterial)
                surface.SetDrawColor(255, 255, 255, self.alpha)
                surface.DrawTexturedRect(iconX, iconY, ICON_SIZE, ICON_SIZE)
            end

            -- Weapon name
            local nameX = iconX + ICON_SIZE + 8
            local nameY = itemY + 8
            local nameColor = ColorAlpha(THEME.text, self.alpha)
            local weaponName = self:GetWeaponName(weapon)
            surface.SetTextColor(nameColor.r, nameColor.g, nameColor.b, nameColor.a)
            surface.SetFont("ax.small")
            surface.SetTextPos(nameX, nameY)
            surface.DrawText(weaponName)

            -- Weapon description (shortened)
            local showDescriptions = ax.option:Get("weaponselect.descriptions.enabled", true)
            if ( showDescriptions ) then
                local descY = nameY + 20
                local descColor = ColorAlpha(THEME.textDim, self.alpha * 0.8)
                local desc = self.weaponDescriptions[i] or ""
                if ( string.len(desc) > 35 ) then
                    desc = string.sub(desc, 1, 35) .. "..."
                end
                surface.SetTextColor(descColor.r, descColor.g, descColor.b, descColor.a)
                surface.SetFont("ax.tiny")
                surface.SetTextPos(nameX, descY)
                surface.DrawText(desc)
            end

            -- Selection number
            local numberColor = ColorAlpha(THEME.accent, self.alpha * 0.8)
            surface.SetTextColor(numberColor.r, numberColor.g, numberColor.b, numberColor.a)
            surface.SetFont("ax.small")
            local numberText = tostring(i)
            local numberW, numberH = surface.GetTextSize(numberText)
            surface.SetTextPos(itemX + itemW - numberW - 8, itemY + (scaledH - numberH) / 2)
            surface.DrawText(numberText)
        end

        -- Usage hints
        local hintY = panelY + panelHeight - 40
        local hintColor = ColorAlpha(THEME.textDim, self.alpha * 0.7)

        surface.SetTextColor(hintColor.r, hintColor.g, hintColor.b, hintColor.a)
        surface.SetFont("ax.tiny")

        local hint1 = "Mouse Wheel / Arrow Keys: Navigate"
        local hint1W, _ = surface.GetTextSize(hint1)
        surface.SetTextPos(panelX + (panelWidth - hint1W) / 2, hintY)
        surface.DrawText(hint1)

        local hint2 = "Click / Enter: Select"
        local hint2W, _ = surface.GetTextSize(hint2)
        surface.SetTextPos(panelX + (panelWidth - hint2W) / 2, hintY + 15)
        surface.DrawText(hint2)

        -- Update and draw particle effects
        if ( MODULE.Particles ) then
            MODULE.Particles:Update(frameTime)
            MODULE.Particles:Draw()
        end
    end

    -- Show weapon selection
    function MODULE:ShowWeaponSelection()
        if ( !ax.option:Get("weaponselect.enabled", true) ) then return end

        local client = ax.client
        if ( !IsValid(client) or !client:Alive() ) then return end

        local weapons = client:GetWeapons()
        if ( !weapons or #weapons == 0 ) then return end

        -- Only initialize if not already shown
        local wasVisible = self.alpha > 0 or self.targetAlpha > 0

        if ( !wasVisible ) then
            -- Initialize animations only when first opening
            self:InitializeScaleAnimations(#weapons)
            self:UpdateWeaponDescriptions()

            -- Show with slide animation
            self.targetSlideOffset = 0
            self.slideOffset = -100
            self.animTime = CurTime()

            -- Play opening sound using the module's sound system
            if ( MODULE.Sounds ) then
                MODULE.Sounds:PlaySwitch()
            end
        end

        -- Always update these when showing
        self.targetAlpha = 255
        self.fadeTime = CurTime() + ax.option:Get("weaponselect.fadetime", 5)
    end

    -- Refresh weapon selection without opening animation
    function MODULE:RefreshWeaponSelection()
        if ( !ax.option:Get("weaponselect.enabled", true) ) then return end

        local client = ax.client
        if ( !IsValid(client) or !client:Alive() ) then return end

        local weapons = client:GetWeapons()
        if ( !weapons or #weapons == 0 ) then return end

        -- Update descriptions and reset fade time without animations
        self:UpdateWeaponDescriptions()
        self.targetAlpha = 255
        self.fadeTime = CurTime() + ax.option:Get("weaponselect.fadetime", 5)
    end

    -- Hide weapon selection
    function MODULE:HideWeaponSelection()
        self.targetAlpha = 0
        self.targetSlideOffset = -100
        self.fadeTime = 0
    end

    -- Handle weapon change
    function MODULE:OnWeaponChanged(newIndex)
        if ( newIndex == self.currentIndex ) then return end

        local oldIndex = self.currentIndex
        self.currentIndex = newIndex

        -- Slide direction for animation
        self.slideDirection = (newIndex > oldIndex) and 1 or -1

        -- Update target slide offset for smooth transition
        self.targetSlideOffset = 0

        -- Play sound using the module's sound system
        if ( MODULE.Sounds ) then
            MODULE.Sounds:PlaySelection()
        end

        -- Create particle effect if enabled
        if ( MODULE.Particles and ax.option:Get("weaponselect.particles.enabled", true) ) then
            local scrW, scrH = ScrW(), ScrH()
            local panelWidth = ax.option:Get("weaponselect.size.width", 400)
            local posX = ax.option:Get("weaponselect.position.x", 0.05)
            local centerX = scrW * posX + panelWidth / 2
            local centerY = scrH / 2

            local THEME = MODULE:GetThemeColors()
            MODULE.Particles:CreateSelectionEffect(centerX, centerY, THEME.accent)
        end
    end

    -- Select current weapon
    function MODULE:SelectCurrentWeapon()
        local client = ax.client
        if ( !IsValid(client) ) then return end

        local weapons = client:GetWeapons()
        if ( !weapons or #weapons == 0 ) then return end

        local weapon = weapons[self.currentIndex]
        if ( IsValid(weapon) ) then
            input.SelectWeapon(weapon)
            self:HideWeaponSelection()

            -- Play sound using the module's sound system
            if ( MODULE.Sounds ) then
                MODULE.Sounds:PlaySelect()
            end
        end
    end

    -- Player bind press handling
    function MODULE:PlayerBindPress(client, bind, pressed)
        if ( !pressed or !ax.option:Get("weaponselect.enabled", true) ) then return end

        bind = bind:lower()

        -- Don't interfere with vehicle controls
        if ( client:InVehicle() ) then return end

        -- Handle weapon selection binds
        if ( bind:find("invprev") ) then
            -- If menu isn't visible, show it; otherwise just refresh
            if ( self.alpha <= 0 and self.targetAlpha <= 0 ) then
                self:ShowWeaponSelection()
            else
                self:RefreshWeaponSelection()
            end

            local weapons = client:GetWeapons()
            if ( weapons and #weapons > 0 ) then
                local newIndex = self.currentIndex - 1
                if ( newIndex < 1 ) then newIndex = #weapons end
                self:OnWeaponChanged(newIndex)
            end

            return true
        elseif ( bind:find("invnext") ) then
            -- If menu isn't visible, show it; otherwise just refresh
            if ( self.alpha <= 0 and self.targetAlpha <= 0 ) then
                self:ShowWeaponSelection()
            else
                self:RefreshWeaponSelection()
            end

            local weapons = client:GetWeapons()
            if ( weapons and #weapons > 0 ) then
                local newIndex = self.currentIndex + 1
                if ( newIndex > #weapons ) then newIndex = 1 end
                self:OnWeaponChanged(newIndex)
            end

            return true
        elseif ( bind:find("slot") ) then
            local slot = tonumber(bind:match("slot(%d)"))
            if ( slot ) then
                -- Always show for slot selection since it's direct
                self:ShowWeaponSelection()

                local weapons = client:GetWeapons()
                if ( weapons and weapons[slot] ) then
                    self:OnWeaponChanged(slot)
                end
            end

            return true
        elseif ( bind:find("attack") and self.targetAlpha > 0 ) then
            self:SelectCurrentWeapon()
            return true
        end
    end

    -- Hide on scoreboard
    function MODULE:ScoreboardShow()
        self:HideWeaponSelection()
    end

    -- Hide when player dies
    function MODULE:Think()
        local client = ax.client
        if ( !IsValid(client) or !client:Alive() ) then
            self:HideWeaponSelection()
        end
    end
end
