function GM:PlayerStartVoice(client)
    if ( IsValid(g_VoicePanelList) ) then
        g_VoicePanelList:Remove()
    end

    ax.net:Start("client.voice.start", client)
end

function GM:PlayerEndVoice(client)
    if ( IsValid(g_VoicePanelList) ) then
        g_VoicePanelList:Remove()
    end

    ax.net:Start("client.voice.end", client)
end

function GM:ShouldRenderMainMenu()
    local client = ax.client
    if ( !IsValid(client) ) then return false end

    return IsValid(ax.gui.splash) or IsValid(ax.gui.mainmenu)
end

function GM:GetMainMenuMusic()
    return ax.config:Get("mainmenu.music", "music/hl2_song20_submix0.mp3")
end

local currentStation = nil
local panels = {
    "mainmenu",
    "splash"
}
function GM:ShouldPlayMainMenuMusic()
    if ( !ax.config:Get("mainmenu.music", true) ) then return false end

    local client = ax.client
    if ( !IsValid(client) ) then return false end

    local exists = false
    for _, v in ipairs(panels) do
        if ( IsValid(ax.gui[v]) ) then
            exists = true
            break
        end
    end

    if ( !exists ) then
        return false
    end

    return true
end

local function PlayTrack()
    local music = hook.Run("GetMainMenuMusic")
    if ( !music or music == "" ) then
        return
    end

    local shouldPlay = hook.Run("ShouldPlayMainMenuMusic")
    if ( !IsValid(currentStation) and shouldPlay ) then
        sound.PlayFile("sound/" .. music, "noblock", function(station, errorID, errorName)
            if ( IsValid(station) ) then
                station:SetVolume(ax.option:Get("mainmenu.music.volume", 75) / 100)
                station:EnableLooping(ax.option:Get("mainmenu.music.loop", true))

                currentStation = station
            else
                ax.util:PrintError("Failed to play main menu music: " .. errorName)
            end
        end)
    elseif ( IsValid(currentStation) and shouldPlay ) then
        local volume = ax.option:Get("mainmenu.music.volume", 75) / 100
        if ( currentStation:GetVolume() != volume ) then
            currentStation:SetVolume(volume)
        end
    end
end

local nextThink = 0
function GM:Think()
    if ( nextThink > CurTime() ) then return end
    nextThink = CurTime() + 0.1

    if ( IsValid(currentStation) ) then
        if ( currentStation:GetVolume() <= 0 ) then
            currentStation:Stop()
            currentStation = nil
        else
            local shouldPlay = hook.Run("ShouldPlayMainMenuMusic")
            local from, to = currentStation:GetVolume(), shouldPlay and (ax.option:Get("mainmenu.music.volume", 75) / 100) or 0
            local output = math.Approach(from, to, FrameTime() * 8)
            currentStation:SetVolume(output)
        end
    end

    PlayTrack()
end

function GM:ScoreboardShow()
    if ( hook.Run("ShouldRenderMainMenu") ) then
        return false
    end

    if ( !IsValid(ax.gui.tab) ) then
        vgui.Create("ax.tab")
    else
        ax.gui.tab:Remove()
    end

    return false
end

function GM:ScoreboardHide()
    return false
end

function GM:Initialize()
    hook.Run("LoadFonts")

    ax.module:LoadFolder("parallax/modules")
    ax.item:LoadFolder("parallax/gamemode/items")
    ax.schema:Initialize()
end

local _reloaded = false
function GM:OnReloaded()
    if ( _reloaded ) then return end
    _reloaded = true

    if ( IsValid(currentStation) ) then
        currentStation:Stop()
        currentStation = nil
    end

    hook.Run("LoadFonts")

    ax.module:LoadFolder("parallax/modules")
    ax.item:LoadFolder("parallax/gamemode/items")
    ax.schema:Initialize()
    ax.option:Load()
end

function GM:InitPostEntity()
    ax.client = LocalPlayer()
    ax.option:Load()

    if ( !IsValid(ax.gui.chatbox) ) then
        vgui.Create("ax.chatbox")
    end

    ax.net:Start("client.ready")
end

function GM:OnCloseCaptionEmit()
    return true
end

local eyeTraceHullMin = Vector(-2, -2, -2)
local eyeTraceHullMax = Vector(2, 2, 2)
function GM:CalcView(client, pos, angles, fov)
    if ( hook.Run("ShouldRenderMainMenu") ) then
        local mainmenuPos = ax.config:Get("mainmenu.pos", vector_origin)
        local mainmenuAng = ax.config:Get("mainmenu.ang", angle_zero)
        local mainmenuFov = ax.config:Get("mainmenu.fov", 90)

        return {
            origin = mainmenuPos,
            angles = mainmenuAng,
            fov = mainmenuFov,
            drawviewer = true
        }
    end

    local ragdoll = ax.client:GetDataVariable("ragdoll", nil)
    if ( IsValid(ragdoll) ) then
        local eyePos
        local eyeAng

        if ( ragdoll:LookupAttachment("eyes") ) then
            local attachment = ragdoll:GetAttachment(ragdoll:LookupAttachment("eyes"))
            if ( attachment ) then
                eyePos = attachment.Pos
                eyeAng = attachment.Ang
            end
        else
            local bone = ragdoll:LookupBone("ValveBiped.Bip01_Head1")
            if ( !bone ) then return end

            eyePos, eyeAng = ragdoll:GetBonePosition(bone)
        end

        if ( !eyePos or !eyeAng ) then return end

        local traceHull = util.TraceHull({
            start = eyePos,
            endpos = eyePos + eyeAng:Forward() * 2,
            filter = ragdoll,
            mask = MASK_PLAYERSOLID,
            mins = eyeTraceHullMin,
            maxs = eyeTraceHullMax
        })

        return {
            origin = traceHull.HitPos,
            angles = eyeAng,
            fov = fov,
            drawviewer = true
        }
    end
end

local LOWERED_POS = Vector(0, 0, 0)
local LOWERED_ANGLES = Angle(10, 10, 0)
local LOWERED_LERP = {pos = Vector(0, 0, 0), angles = Angle(0, 0, 0)}
function GM:CalcViewModelView(weapon, viewModel, oldPos, oldAng, pos, ang)
    local client = ax.client
    if ( !IsValid(client) ) then return end

    local targetPos = LOWERED_POS
    local targetAngles = LOWERED_ANGLES
    if ( IsValid(weapon) and weapon:IsWeapon() ) then
        if ( weapon.LoweredPos ) then
            targetPos = weapon.LoweredPos
        end

        if ( weapon.LoweredAngles ) then
            targetAngles = weapon.LoweredAngles
        end
    end

    if ( IsValid(weapon) and !client:IsWeaponRaised() ) then
        LOWERED_LERP.pos = Lerp(FrameTime() * 4, LOWERED_LERP.pos, targetPos)
        LOWERED_LERP.angles = LerpAngle(FrameTime() * 4, LOWERED_LERP.angles, targetAngles)
    else
        LOWERED_LERP.pos = Lerp(FrameTime() * 4, LOWERED_LERP.pos, vector_origin)
        LOWERED_LERP.angles = LerpAngle(FrameTime() * 4, LOWERED_LERP.angles, angle_zero)
    end

    pos = pos + LOWERED_LERP.pos
    ang = ang + LOWERED_LERP.angles

    return self.BaseClass:CalcViewModelView(weapon, viewModel, oldPos, oldAng, pos, ang)
end

local vignette = ax.util:GetMaterial("parallax/overlay_vignette.png", "noclamp smooth")
local vignetteColor = Color(0, 0, 0, 255)
function GM:HUDPaintBackground()
    if ( tobool(hook.Run("ShouldDrawVignette")) ) then
        local client = ax.client
        if ( !IsValid(client) ) then return end

        local scrW, scrH = ScrW(), ScrH()
        local trace = util.TraceLine({
            start = client:GetShootPos(),
            endpos = client:GetShootPos() + client:GetAimVector() * 96,
            filter = client,
            mask = MASK_SHOT
        })

        if ( trace.Hit and trace.HitPos:DistToSqr(client:GetShootPos()) < 96 ^ 2 ) then
            vignetteColor.a = Lerp(FrameTime(), vignetteColor.a, 255)
        else
            vignetteColor.a = Lerp(FrameTime(), vignetteColor.a, 100)
        end

        if ( hook.Run("ShouldDrawDefaultVignette") != false ) then
            surface.SetDrawColor(vignetteColor)
            surface.SetMaterial(vignette)
            surface.DrawRect(0, 0, scrW, scrH, vignetteColor)
        end

        hook.Run("DrawVignette", 1 - (vignetteColor.a / 255))
    end
end

function GM:DrawVignette(fraction)
end

local padding = 16
local backgroundColor = Color(10, 10, 10, 220)

function GM:HUDPaint()
    local client = ax.client
    if ( !IsValid(client) ) then return end

    local shouldDraw = hook.Run("PreHUDPaint")
    if ( shouldDraw == false ) then return end

    local x, y = 24, 24
    local scrW, scrH = ScrW(), ScrH()
    shouldDraw = hook.Run("ShouldDrawDebugHUD")
    if ( shouldDraw != false ) then
        local green = ax.config:Get("color.framework")
        local width = math.max(ax.util:GetTextWidth("parallax.developer", "Pos: " .. tostring(client:GetPos())), ax.util:GetTextWidth("parallax.developer", "Ang: " .. tostring(client:EyeAngles())))
        local height = 16 * 6

        local character = client:GetCharacter()
        if ( character ) then
            height = height + 16 * 6
        end

        ax.util:DrawBlurRect(x - padding, y - padding, width + padding * 2, height + padding * 2)

        surface.SetDrawColor(backgroundColor)
        surface.DrawRect(x - padding, y - padding, width + padding * 2, height + padding * 2)

        draw.SimpleText("[DEVELOPER HUD]", "parallax.developer", x, y, green, TEXT_ALIGN_LEFT)

        draw.SimpleText("Pos: " .. tostring(client:GetPos()), "parallax.developer", x, y + 16 * 1, green, TEXT_ALIGN_LEFT)
        draw.SimpleText("Ang: " .. tostring(client:EyeAngles()), "parallax.developer", x, y + 16 * 2, green, TEXT_ALIGN_LEFT)
        draw.SimpleText("Health: " .. client:Health(), "parallax.developer", x, y + 16 * 3, green, TEXT_ALIGN_LEFT)
        draw.SimpleText("Ping: " .. client:Ping(), "parallax.developer", x, y + 16 * 4, green, TEXT_ALIGN_LEFT)

        local fps = math.floor(1 / FrameTime())
        draw.SimpleText("FPS: " .. fps, "parallax.developer", x, y + 16 * 5, green, TEXT_ALIGN_LEFT)

        if ( character ) then
            local name = character:GetName()
            local charModel = character:GetModel()
            local inventories = ax.inventory:GetByCharacterID(character:GetID()) or {}
            for k, v in pairs(inventories) do
                inventories[k] = tostring(v)
            end
            local inventoryText = "Inventories: " .. table.concat(inventories, ", ")

            draw.SimpleText("[CHARACTER INFO]", "parallax.developer", x, y + 16 * 7, green, TEXT_ALIGN_LEFT)
            draw.SimpleText("Character: " .. tostring(character), "parallax.developer", x, y + 16 * 8, green, TEXT_ALIGN_LEFT)
            draw.SimpleText("Name: " .. name, "parallax.developer", x, y + 16 * 9, green, TEXT_ALIGN_LEFT)
            draw.SimpleText("Model: " .. charModel, "parallax.developer", x, y + 16 * 10, green, TEXT_ALIGN_LEFT)
            draw.SimpleText(inventoryText, "parallax.developer", x, y + 16 * 11, green, TEXT_ALIGN_LEFT)
        end
    end

    shouldDraw = hook.Run("ShouldDrawPreviewHUD")
    if ( shouldDraw != false ) then
        local orange = ax.color:Get("orange")
        local red = ax.color:Get("red")

        ax.util:DrawBlurRect(x - padding, y - padding, 410 + padding * 2, 45 + padding * 2)

        surface.SetDrawColor(backgroundColor)
        surface.DrawRect(x - padding, y - padding, 410 + padding * 2, 45 + padding * 2)

        draw.SimpleText("[PREVIEW MODE]", "parallax.developer", x, y, orange, TEXT_ALIGN_LEFT)
        draw.SimpleText("Warning! Anything you witness is subject to change.", "parallax.developer", x, y + 16, red, TEXT_ALIGN_LEFT)
        draw.SimpleText("This is not the final product.", "parallax.developer", x, y + 16 * 2, red, TEXT_ALIGN_LEFT)
    end

    shouldDraw = hook.Run("ShouldDrawCrosshair")
    if ( shouldDraw != false ) then
        x, y = ScrW() / 2, ScrH() / 2
        local size = 3

        if ( ax.module:Get("thirdperson") and ax.option:Get("thirdperson", false) ) then
            local trace = util.TraceLine({
                start = client:GetShootPos(),
                endpos = client:GetShootPos() + client:GetAimVector() * 8192,
                filter = client,
                mask = MASK_SHOT
            })

            local screen = trace.HitPos:ToScreen()
            x, y = screen.x, screen.y
        end

        -- TODO: Add crosshair
    end

    shouldDraw = hook.Run("ShouldDrawAmmoBox")
    if ( shouldDraw != nil and shouldDraw != false ) then
        local activeWeapon = client:GetActiveWeapon()
        if ( !IsValid(activeWeapon) ) then return end

        local ammo = client:GetAmmoCount(activeWeapon:GetPrimaryAmmoType())
        local clip = activeWeapon:Clip1()
        local ammoText = clip .. " / " .. ammo

        draw.SimpleTextOutlined(ammoText, "parallax.bold", scrW - 16, scrH - 16, ax.color:Get("white"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 1, ax.color:Get("black"))
    end

    hook.Run("PostHUDPaint")
end

function GM:PostDrawTranslucentRenderables(bDrawingDepth, bDrawingSkybox)
    if ( !ax.config:Get("debug.developer") ) then return end
    if ( !ax.client:IsDeveloper() ) then return end

    local client = ax.client
    if ( !IsValid(client) ) then return end

    local trace = client:GetEyeTrace()
    if ( !trace.Hit or !IsValid(trace.Entity) ) then return end

    local entity = trace.Entity
    local pos = entity:GetPos()
    local ang = entity:GetAngles()
    local center = entity:LocalToWorld(entity:OBBCenter())
    local model = entity:GetModel() or "N/A"
    local class = entity:GetClass() or "N/A"

    local text = string.format("Entity: %s\nClass: %s\nModel: %s\nPosition: %s\nAngles: %s",
        tostring(entity), class, model, tostring(pos), tostring(ang))
    local markedUp = markup.Parse("<font=parallax.developer>" .. text .. "</font>")
    if ( !markedUp ) then return end

    local textWidth, textHeight = markedUp:Size()
    local x = -ScrW() * 0.5 + (ScrW() - textWidth) * 0.5
    local y = -ScrH() * 0.5 + (ScrH() - textHeight) * 0.5

    local distance = pos:Distance(client:GetPos())
    if ( distance > 1024 ) then
        return
    end

    local scale = math.Clamp(0 + (distance / 1024), 0.1, 1)

    -- Draw a background for the text
    cam.IgnoreZ(true)
    cam.Start3D2D(center, Angle(0, client:EyeAngles().y - 90, 90), scale)
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(x - padding, y - padding, textWidth + padding, textHeight + padding)

        -- Draw the text
        markedUp:Draw(x - padding / 2, y - padding / 2)
    cam.End3D2D()
    cam.IgnoreZ(false)
end

local elements = {
    ["CHUDQuickInfo"] = true,
    ["CHudAmmo"] = true,
    ["CHudBattery"] = true,
    ["CHudChat"] = true,
    ["CHudCrosshair"] = true,
    ["CHudDamageIndicator"] = true,
    ["CHudGeiger"] = true,
    ["CHudHealth"] = true,
    ["CHudHistoryResource"] = true,
    ["CHudPoisonDamageIndicator"] = true,
    ["CHudSecondaryAmmo"] = true,
    ["CHudSquadStatus"] = true,
    ["CHudSuitPower"] = true,
    ["CHudTrain"] = true,
    ["CHudVehicle"] = true
}

function GM:HUDShouldDraw(name)
    if ( elements[name] ) then
        return false
    end

    return true
end

function GM:LoadFonts()
    local scale4 = ScreenScaleH(6)
    local scale6 = ScreenScaleH(8)
    local scale8 = ScreenScaleH(10)
    local scale10 = ScreenScaleH(12)
    local scale12 = ScreenScaleH(16)
    local scale16 = ScreenScaleH(20)
    local scale20 = ScreenScaleH(24)
    local scale32 = ScreenScaleH(32)

    surface.CreateFont("parallax.tiny", {
        font = "GorDIN Regular",
        size = scale4,
        weight = 500,
        antialias = true
    })

    surface.CreateFont("parallax.tiny.bold", {
        font = "GorDIN Bold",
        size = scale4,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("parallax.small", {
        font = "GorDIN Regular",
        size = scale6,
        weight = 500,
        antialias = true
    })

    surface.CreateFont("parallax.small.bold", {
        font = "GorDIN Bold",
        size = scale6,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("parallax.small.italic", {
        font = "GorDIN Regular",
        size = scale6,
        weight = 500,
        italic = true,
        antialias = true
    })

    surface.CreateFont("parallax.small.italic.bold", {
        font = "GorDIN Bold",
        size = scale6,
        weight = 700,
        italic = true,
        antialias = true
    })

    surface.CreateFont("parallax", {
        font = "GorDIN Regular",
        size = scale8,
        weight = 500,
        antialias = true
    })

    surface.CreateFont("parallax.bold", {
        font = "GorDIN Bold",
        size = scale8,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("parallax.italic", {
        font = "GorDIN Regular",
        size = ScreenScale(8),
        weight = 500,
        italic = true,
        antialias = true
    })

    surface.CreateFont("parallax.italic.bold", {
        font = "GorDIN Bold",
        size = scale8,
        weight = 700,
        italic = true,
        antialias = true
    })

    surface.CreateFont("parallax.large", {
        font = "GorDIN Regular",
        size = ScreenScale(10),
        weight = 500,
        antialias = true
    })

    surface.CreateFont("parallax.large.bold", {
        font = "GorDIN Bold",
        size = scale10,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("parallax.large.italic", {
        font = "GorDIN Regular",
        size = ScreenScale(10),
        weight = 500,
        italic = true,
        antialias = true
    })

    surface.CreateFont("parallax.large.italic.bold", {
        font = "GorDIN Bold",
        size = scale10,
        weight = 700,
        italic = true,
        antialias = true
    })

    surface.CreateFont("parallax.huge", {
        font = "GorDIN Regular",
        size = scale12,
        weight = 500,
        antialias = true
    })

    surface.CreateFont("parallax.huge.bold", {
        font = "GorDIN Bold",
        size = scale12,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("parallax.huge.italic", {
        font = "GorDIN",
        size = scale12,
        weight = 500,
        italic = true,
        antialias = true
    })

    surface.CreateFont("parallax.huge.italic.bold", {
        font = "GorDIN Bold",
        size = scale12,
        weight = 700,
        italic = true,
        antialias = true
    })

    surface.CreateFont("parallax.button.large", {
        font = "GorDIN SemiBold",
        size = scale20,
        weight = 600,
        antialias = true
    })

    surface.CreateFont("parallax.button.large.hover", {
        font = "GorDIN Bold",
        size = scale20,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("parallax.button", {
        font = "GorDIN SemiBold",
        size = scale16,
        weight = 600,
        antialias = true
    })

    surface.CreateFont("parallax.button.hover", {
        font = "GorDIN Bold",
        size = scale16,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("parallax.button.small", {
        font = "GorDIN SemiBold",
        size = scale12,
        weight = 600,
        antialias = true
    })

    surface.CreateFont("parallax.button.small.hover", {
        font = "GorDIN Bold",
        size = scale12,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("parallax.button.tiny", {
        font = "GorDIN SemiBold",
        size = scale10,
        weight = 600,
        antialias = true
    })

    surface.CreateFont("parallax.button.tiny.hover", {
        font = "GorDIN Bold",
        size = scale10,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("parallax.title", {
        font = "GorDIN Bold",
        size = scale32,
        weight = 700,
        antialias = true,
    })

    surface.CreateFont("parallax.subtitle", {
        font = "GorDIN SemiBold",
        size = scale16,
        weight = 600,
        antialias = true,
    })

    surface.CreateFont("parallax.developer", {
        font = "Courier New",
        size = 16,
        weight = 500,
        antialias = true
    })

    surface.CreateFont("parallax.chat", {
        font = "GorDIN Regular",
        size = ScreenScale(8) * ax.option:Get("chat.size.font", 1),
        weight = 500,
        antialias = true
    })

    hook.Run("PostLoadFonts")
end

function GM:OnPauseMenuShow()
    if ( IsValid(ax.gui.tab) ) then
        ax.gui.tab:Close()
        return false
    end

    if ( IsValid(ax.gui.chatbox) and ax.gui.chatbox:GetAlpha() == 255 ) then
        ax.gui.chatbox:SetVisible(false)
        return false
    end

    if ( !IsValid(ax.gui.mainmenu) ) then
        vgui.Create("ax.mainmenu")
    else
        if ( ax.client:GetCharacter() ) then
            ax.gui.mainmenu:Remove()
            return
        end
    end

    return false
end

function GM:PreHUDPaint()
end

function GM:PostHUDPaint()
end

function GM:ShouldDrawCrosshair()
    if ( IsValid(ax.gui.mainmenu) ) then return false end
    if ( IsValid(ax.gui.tab) ) then return false end

    return true
end

function GM:ShouldDrawAmmoBox()
    if ( IsValid(ax.gui.mainmenu) ) then return false end
    if ( IsValid(ax.gui.tab) ) then return false end

    local client = ax.client
    local activeWeapon = client:GetActiveWeapon()
    if ( !IsValid(activeWeapon) ) then return false end

    local clip = activeWeapon:Clip1()
    local ammo = client:GetAmmoCount(activeWeapon:GetPrimaryAmmoType())
    if ( clip <= 0 and ammo <= 0 ) then return false end

    local viewEntity = client:GetViewEntity()
    if ( IsValid(viewEntity) and viewEntity != client ) then
        return false
    end

    return true
end

function GM:ShouldDrawDebugHUD()
    if ( !ax.config:Get("debug.developer") ) then return false end
    if ( IsValid(ax.gui.mainmenu) ) then return false end
    if ( IsValid(ax.gui.tab) ) then return false end

    return ax.client:IsDeveloper()
end

function GM:ShouldDrawPreviewHUD()
    if ( !ax.config:Get("debug.preview") ) then return false end
    if ( IsValid(ax.gui.mainmenu) ) then return false end
    if ( IsValid(ax.gui.tab) ) then return false end

    return !hook.Run("ShouldDrawDebugHUD")
end

function GM:ShouldDrawVignette()
    if ( IsValid(ax.gui.mainmenu) ) then return false end
    if ( !ax.option:Get("vignette", true) ) then return false end

    return true
end

function GM:ShouldDrawDefaultVignette()
    if ( !IsValid(vignette) ) then
        return false
    end
end

function GM:ShouldShowInventory()
    return true
end

function GM:GetCharacterName(client, target)
    -- TODO: Empty hook, implement this in the future
end

function GM:PopulateTabButtons(buttons)
    if ( CAMI.PlayerHasAccess(ax.client, "Parallax - Manage Config", nil) ) then
        buttons["tab.config"] = {
            Populate = function(this, container)
                container:Add("ax.tab.config")
            end
        }
    end

    buttons["tab.help"] = {
        Populate = function(this, container)
            container:Add("ax.tab.help")
        end
    }

    if ( hook.Run("ShouldShowInventory") != false ) then
        buttons["tab.inventory"] = {
            Populate = function(this, container)
                container:Add("ax.tab.inventory")
            end
        }
    end

    buttons["tab.inventory"] = {
        Populate = function(this, container)
            container:Add("ax.tab.inventory")
        end
    }

    buttons["tab.scoreboard"] = {
        Populate = function(this, container)
            container:Add("ax.tab.scoreboard")
        end
    }

    buttons["tab.settings"] = {
        Populate = function(this, container)
            container:Add("ax.tab.settings")
        end
    }
end

function GM:PopulateHelpCategories(categories)
    categories["test"] = function(container)
        local filler = container:Add("DPanel")
        filler:Dock(FILL)
    end
    categories["flags"] = function(container)
        local scroller = container:Add("ax.scroller.vertical")
        scroller:Dock(FILL)
        scroller:GetVBar():SetWide(0)
        scroller.Paint = nil

        for k, v in SortedPairs(ax.flag.stored) do
            local char = ax.client:GetCharacter()
            if ( !char ) then return end

            local hasFlag = char:HasFlag(k)

            local button = scroller:Add("ax.button.small")
            button:Dock(TOP)
            button:SetText("")
            button:SetBackgroundAlphaHovered(1)
            button:SetBackgroundAlphaUnHovered(0.5)
            button:SetBackgroundColor(hasFlag and ax.color:Get("success") or ax.color:Get("error"))

            local key = button:Add("ax.text")
            key:Dock(LEFT)
            key:DockMargin(ScreenScale(8), 0, 0, 0)
            key:SetFont("parallax.button.hover")
            key:SetText(k)

            local seperator = button:Add("ax.text")
            seperator:Dock(LEFT)
            seperator:SetFont("parallax.button")
            seperator:SetText(" - ")

            local description = button:Add("ax.text")
            description:Dock(LEFT)
            description:SetFont("parallax.button")
            description:SetText(v.description)

            local function Think(this)
                this:SetTextColor(button:GetTextColor())
            end

            key.Think = Think
            seperator.Think = Think
            description.Think = Think
        end
    end
end

function GM:GetChatboxSize()
    local width = ScrW() * 0.4
    local height = ScrH() * 0.35

    return width, height
end

function GM:GetChatboxPos()
    local _, height = self:GetChatboxSize()
    local x = ScrW() * 0.0125
    local y = ScrH() * 0.025
    y = ScrH() - height - y

    return x, y
end

function GM:ChatboxOnTextChanged(text)
    ax.net:Start("client.chatbox.text.changed", text)

    -- Notify the command system about the text change
    local command = ax.command:Get(ax.gui.chatbox:GetChatType())
    if ( command and command.OnChatTextChanged ) then
        command:OnTextChanged(text)
    end

    -- Notify the chat system about the text change
    local chat = ax.chat:Get(ax.gui.chatbox:GetChatType())
    if ( chat and chat.OnChatTextChanged ) then
        chat:OnTextChanged(text)
    end
end

function GM:ChatboxOnChatTypeChanged(newType, oldType)
    ax.net:Start("client.chatbox.type.changed", newType, oldType)

    -- Notify the command system about the chat type change
    local command = ax.command:Get(newType)
    if ( command and command.OnChatTypeChanged ) then
        command:OnChatTypeChanged(newType, oldType)
    end

    -- Notify the chat system about the chat type change
    local chat = ax.chat:Get(newType)
    if ( chat and chat.OnChatTypeChanged ) then
        chat:OnChatTypeChanged(newType, oldType)
    end
end

function GM:PlayerBindPress(client, bind, pressed)
    bind = bind:lower()

    if ( bind:find("messagemode") and pressed ) then
        ax.gui.chatbox:SetVisible(true)

        for _, pnl in ipairs(ax.chat.messages) do
            if ( IsValid(pnl) ) then
                pnl.alpha = 1
            end
        end

        return true
    end
end

function GM:StartChat()
end

function GM:FinishChat()
end

function GM:ForceDermaSkin()
    return "Parallax"
end

function GM:OnScreenSizeChanged(oldWidth, oldHeight, newWidth, newHeight)
    for k, v in ipairs(ax.gui) do
        if ( IsValid(v) and ispanel(v) ) then
            local className = v:GetClassName()
            v:Remove()

            -- Attempt to recreate the GUI element
            if ( className == "ax.mainmenu" ) then
                vgui.Create("ax.mainmenu")
            elseif ( className == "ax.tab" ) then
                vgui.Create("ax.tab")
            end
        end
    end

    hook.Run("LoadFonts")
end