--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.name = "Third Person"
MODULE.description = "Adds third-person camera functionality to the gamemode."
MODULE.author = "Riggs"

ax.config:Add("thirdperson", ax.type.bool, true, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Enable third-person camera functionality in the gamemode.",
    bNoNetworking = true
})

ax.option:Add("thirdperson", ax.type.bool, false, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Toggle third-person camera.",
    bNoNetworking = true
})

ax.option:Add("thirdperson.x", ax.type.number, 25, {
    category = "camera",
    subCategory = "thirdperson",
    description = "X offset for third-person camera.",
    bNoNetworking = true,
    min = -100,
    max = 100,
    decimals = 0
})

ax.option:Add("thirdperson.y", ax.type.number, 0, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Y offset for third-person camera.",
    bNoNetworking = true,
    min = -100,
    max = 100,
    decimals = 0
})

ax.option:Add("thirdperson.z", ax.type.number, -50, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Z offset for third-person camera.",
    bNoNetworking = true,
    min = -100,
    max = 100,
    decimals = 0
})

ax.option:Add("thirdperson.follow.head", ax.type.bool, true, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Make the third-person camera follow the player's model head movements.",
    bNoNetworking = true
})

ax.option:Add("thirdperson.follow.angles", ax.type.bool, true, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Make the third-person camera follow the player's aim direction instead of view angles.",
    bNoNetworking = true
})

ax.option:Add("thirdperson.follow.fov", ax.type.bool, true, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Make the third-person camera FOV calculated based on the distance from the trace end point to the player.",
    bNoNetworking = true
})

ax.option:Add("thirdperson.desired.lerp.pos", ax.type.number, 5, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Interpolation speed for the third-person camera desired position. Lower values will be more smooth but also more slower to respond. Set to 0 to disable interpolation.",
    bNoNetworking = true,
    min = 0,
    max = 20,
    decimals = 0
})

ax.option:Add("thirdperson.desired.lerp.angle", ax.type.number, 5, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Interpolation speed for the third-person camera desired angle. Lower values will be more smooth but also more slower to respond. Set to 0 to disable interpolation.",
    bNoNetworking = true,
    min = 0,
    max = 20,
    decimals = 0
})

ax.option:Add("thirdperson.desired.lerp.fov", ax.type.number, 5, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Interpolation speed for the third-person camera desired FOV. Lower values will be more smooth but also more slower to respond. Set to 0 to disable interpolation.",
    bNoNetworking = true,
    min = 0,
    max = 20,
    decimals = 0
})

ax.localization:Register("en", {
    ["category.camera"] = "Camera",
    ["subcategory.thirdperson"] = "Third Person",
    ["config.thirdperson"] = "Enable Third Person",
    ["config.thirdperson.help"] = "Wether or not the server allows third-person camera functionality.",
    ["option.thirdperson"] = "Enable Third Person",
    ["option.thirdperson.help"] = "Toggle third-person camera mode.",
    ["option.thirdperson.x"] = "X Offset",
    ["option.thirdperson.x.help"] = "X offset for third-person camera.",
    ["option.thirdperson.y"] = "Y Offset",
    ["option.thirdperson.y.help"] = "Y offset for third-person camera.",
    ["option.thirdperson.z"] = "Z Offset",
    ["option.thirdperson.z.help"] = "Z offset for third-person camera.",
    ["option.thirdperson.follow.head"] = "Follow Head",
    ["option.thirdperson.follow.head.help"] = "Make the third-person camera follow the player's model head movements.",
    ["option.thirdperson.follow.angles"] = "Follow Angles",
    ["option.thirdperson.follow.angles.help"] = "Make the third-person camera follow the player's aim direction instead of view angles.",
    ["option.thirdperson.follow.fov"] = "Follow Field of View",
    ["option.thirdperson.follow.fov.help"] = "Make the third-person camera FOV calculated based on the distance from the trace end point to the player.",
    ["option.thirdperson.desired.lerp.pos"] = "Desired Position Interpolation Speed",
    ["option.thirdperson.desired.lerp.pos.help"] = "Interpolation speed for the third-person camera desired position. Lower values will be more smooth but also more slower to respond. Set to 0 to disable interpolation.",
    ["option.thirdperson.desired.lerp.angle"] = "Desired Angle Interpolation Speed",
    ["option.thirdperson.desired.lerp.angle.help"] = "Interpolation speed for the third-person camera desired angle. Lower values will be more smooth but also more slower to respond. Set to 0 to disable interpolation.",
    ["option.thirdperson.desired.lerp.fov"] = "Desired FOV Interpolation Speed",
    ["option.thirdperson.desired.lerp.fov.help"] = "Interpolation speed for the third-person camera desired FOV. Lower values will be more smooth but also more slower to respond. Set to 0 to disable interpolation."
})

ax.localization:Register("de", {
    ["category.camera"] = "Kamera",
    ["subcategory.thirdperson"] = "Dritte Person",
    ["config.thirdperson"] = "Dritte Person aktivieren",
    ["config.thirdperson.help"] = "Ob der Server die Dritt-Person-Kamerafunktionalität erlaubt.",
    ["option.thirdperson"] = "Dritte Person aktivieren",
    ["option.thirdperson.help"] = "Dritte-Person-Kameramodus umschalten.",
    ["option.thirdperson.x"] = "X-Versatz",
    ["option.thirdperson.x.help"] = "X-Versatz für die Dritt-Person-Kamera.",
    ["option.thirdperson.y"] = "Y-Versatz",
    ["option.thirdperson.y.help"] = "Y-Versatz für die Dritt-Person-Kamera.",
    ["option.thirdperson.z"] = "Z-Versatz",
    ["option.thirdperson.z.help"] = "Z-Versatz für die Dritt-Person-Kamera.",
    ["option.thirdperson.follow.head"] = "Kopf folgen",
    ["option.thirdperson.follow.head.help"] = "Die Dritt-Person-Kamera soll den Kopfbewegungen des Spielermodells folgen.",
    ["option.thirdperson.follow.angles"] = "Winkel folgen",
    ["option.thirdperson.follow.angles.help"] = "Die Dritt-Person-Kamera soll der Zielrichtung des Spielers anstelle der Blickwinkel folgen.",
    ["option.thirdperson.follow.fov"] = "Sichtfeld folgen",
    ["option.thirdperson.follow.fov.help"] = "Das FOV der Dritt-Person-Kamera wird basierend auf dem Abstand vom Endpunkt der Spur zum Spieler berechnet.",
    ["option.thirdperson.desired.lerp.pos"] = "Gewünschte Positions-Interpolation Geschwindigkeit",
    ["option.thirdperson.desired.lerp.pos.help"] = "Interpolationsgeschwindigkeit für die gewünschte Position der Dritt-Person-Kamera. Niedrigere Werte sind glatter, reagieren aber auch langsamer. Auf 0 setzen, um die Interpolation zu deaktivieren.",
    ["option.thirdperson.desired.lerp.angle"] = "Gewünschte Winkel-Interpolation Geschwindigkeit",
    ["option.thirdperson.desired.lerp.angle.help"] = "Interpolationsgeschwindigkeit für den gewünschten Winkel der Dritt-Person-Kamera. Niedrigere Werte sind glatter, reagieren aber auch langsamer. Auf 0 setzen, um die Interpolation zu deaktivieren.",
    ["option.thirdperson.desired.lerp.fov"] = "Gewünschte FOV-Interpolation Geschwindigkeit",
    ["option.thirdperson.desired.lerp.fov.help"] = "Interpolationsgeschwindigkeit für das gewünschte FOV der Dritt-Person-Kamera. Niedrigere Werte sind glatter, reagieren aber auch langsamer. Auf 0 setzen, um die Interpolation zu deaktivieren."
})

ax.localization:Register("ru", {
    ["category.camera"] = "Камера",
    ["subcategory.thirdperson"] = "Третье Лицо",
    ["config.thirdperson"] = "Включить Третье лицо",
    ["config.thirdperson.help"] = "Wether or not the server allows third-person camera functionality.",
    ["option.thirdperson"] = "Включить Третье лицо",
    ["option.thirdperson.help"] = "Toggle third-person camera mode.",
    ["option.thirdperson.x"] = "X Смещение",
    ["option.thirdperson.x.help"] = "X Смещение для камеры Третье лица.",
    ["option.thirdperson.y"] = "Y Смещение",
    ["option.thirdperson.y.help"] = "Y Смещение для камеры Третье лица.",
    ["option.thirdperson.z"] = "Z Смещение",
    ["option.thirdperson.z.help"] = "Z Смещение для камеры Третье лица.",
    ["option.thirdperson.follow.head"] = "Следовать за головой",
    ["option.thirdperson.follow.head.help"] = "Делает так, чтобы камера от третьего лица следовала за движениями головы модели игрока.",
    ["option.thirdperson.follow.angles"] = "Следовать за углами",
    ["option.thirdperson.follow.angles.help"] = "Делает так, чтобы камера от третьего лица следить за направлением прицеливания игрока, а не за углами обзора.",
    ["option.thirdperson.follow.fov"] = "Следовать за полем зрения",
    ["option.thirdperson.follow.fov.help"] = "Делает так, чтобы камера  от третьего лица следить за направлением на основе расстояния от конечной точки трассы до игрока.",
    ["option.thirdperson.desired.lerp.pos"] = "Требуемая скорость интерполяции положения",
    ["option.thirdperson.desired.lerp.pos.help"] = "Скорость интерполяции для желаемого положения камеры от третьего лица. При меньших значениях скорость интерполяции будет более плавной, но и реакция будет медленнее. Установите значение 0, чтобы отключить интерполяцию.",
    ["option.thirdperson.desired.lerp.angle"] = "Требуемая скорость интерполяции угла",
    ["option.thirdperson.desired.lerp.angle.help"] = "Скорость интерполяции для желаемого ракурса камеры от третьего лица. При меньших значениях скорость интерполяции будет более плавной, но и реакция будет медленнее. Установите значение 0, чтобы отключить интерполяцию.",
    ["option.thirdperson.desired.lerp.fov"] = "Требуемая скорость интерполяции поля зрения",
    ["option.thirdperson.desired.lerp.fov.help"] = "Скорость интерполяции для желаемого угла обзора камеры от третьего лица. При меньших значениях скорость интерполяции будет более плавной, но и реакция будет медленнее. Установите значение 0, чтобы отключить интерполяцию."
})

ax.localization:Register("es", {
    ["category.camera"] = "Cámara",
    ["subcategory.thirdperson"] = "Tercera Persona",
    ["config.thirdperson"] = "Habilitar Tercera Persona",
    ["config.thirdperson.help"] = "Si el servidor permite o no la funcionalidad de cámara en tercera persona.",
    ["option.thirdperson"] = "Habilitar Tercera Persona",
    ["option.thirdperson.help"] = "Alternar el modo de cámara en tercera persona.",
    ["option.thirdperson.x"] = "Desplazamiento X",
    ["option.thirdperson.x.help"] = "Desplazamiento X para la cámara en tercera persona.",
    ["option.thirdperson.y"] = "Desplazamiento Y",
    ["option.thirdperson.y.help"] = "Desplazamiento Y para la cámara en tercera persona.",
    ["option.thirdperson.z"] = "Desplazamiento Z",
    ["option.thirdperson.z.help"] = "Desplazamiento Z para la cámara en tercera persona.",
    ["option.thirdperson.follow.head"] = "Seguir Cabeza",
    ["option.thirdperson.follow.head.help"] = "Hacer que la cámara en tercera persona siga los movimientos de la cabeza del modelo del jugador.",
    ["option.thirdperson.follow.angles"] = "Seguir Ángulos",
    ["option.thirdperson.follow.angles.help"] = "Hacer que la cámara en tercera persona siga la dirección de la mira del jugador en lugar de los ángulos de vista.",
    ["option.thirdperson.follow.fov"] = "Seguir Campo de Visión",
    ["option.thirdperson.follow.fov.help"] = "Hacer que el FOV de la cámara en tercera persona se calcule en función de la distancia desde el punto final del rastro hasta el jugador.",
    ["option.thirdperson.desired.lerp.pos"] = "Velocidad de Interpolación de Posición Deseada",
    ["option.thirdperson.desired.lerp.pos.help"] = "Velocidad de interpolación para la posición deseada de la cámara en tercera persona. Valores más bajos serán más suaves pero también más lentos para responder. Establezca en 0 para desactivar la interpolación.",
    ["option.thirdperson.desired.lerp.angle"] = "Velocidad de Interpolación de Ángulo Deseado",
    ["option.thirdperson.desired.lerp.angle.help"] = "Velocidad de interpolación para el ángulo deseado de la cámara en tercera persona. Valores más bajos serán más suaves pero también más lentos para responder. Establezca en 0 para desactivar la interpolación.",
    ["option.thirdperson.desired.lerp.fov"] = "Velocidad de Interpolación de FOV Deseado",
    ["option.thirdperson.desired.lerp.fov.help"] = "Velocidad de interpolación para el FOV deseado de la cámara en tercera persona. Valores más bajos serán más suaves pero también más lentos para responder. Establezca en 0 para desactivar la interpolación."
})

if ( SERVER ) then return end

local FIXED_RADIUS = 6
local curPos
local curAng
local curFOV

-- LVS is gay and already used the ShouldDrawThirdPerson hook, so we have to use a different name
function MODULE:ShouldUseThirdPerson(client)
    if ( !client:Alive() or client:InVehicle() or client:GetObserverMode() != OBS_MODE_NONE or !client:Alive() or client:GetMoveType() == MOVETYPE_NOCLIP ) then return false end

    if ( !ax.config:Get("thirdperson") ) then return false end

    return ax.option:Get("thirdperson")
end

function MODULE:ShouldDrawLocalPlayer(client)
    if ( self:ShouldUseThirdPerson(client) ) then
        return true
    end
end

ax.viewstack:RegisterModifier("thirdperson", function(client, patch)
    if ( hook.Run("ShouldUseThirdPerson", client) == false ) then return end

    if ( !curPos ) then
        curPos = patch.origin
    end

    if ( !curAng ) then
        curAng = patch.angles
    end

    if ( !curFOV ) then
        curFOV = 0
    end

    -- start from the player's eye position
    local startPos = client:EyePos()
    local headBone = client:LookupBone("ValveBiped.Bip01_Head1")
    local eyeAttachment = client:LookupAttachment("eyes")
    if ( ax.option:Get("thirdperson.follow.head") ) then
        if ( headBone ) then
            local headPos, _ = client:GetBonePosition(headBone)
            if ( headPos ) then
                startPos = headPos
            end

        elseif ( eyeAttachment ) then
            local eyeData = client:GetAttachment(eyeAttachment)
            if ( eyeData and eyeData.Pos ) then
                startPos = eyeData.Pos
            end
        end
    end

    local ang = patch.angles

    -- desired camera offset relative to view angles
    local desiredPos = startPos + ang:Forward() * ax.option:Get("thirdperson.z") + ang:Right() * ax.option:Get("thirdperson.x") + ang:Up() * ax.option:Get("thirdperson.y")

    local traceCamera = util.TraceHull({
        start = startPos,
        endpos = desiredPos,
        mins = Vector(-FIXED_RADIUS, -FIXED_RADIUS, -FIXED_RADIUS),
        maxs = Vector(FIXED_RADIUS, FIXED_RADIUS, FIXED_RADIUS),
        filter = client,
        mask = MASK_SOLID
    })

    if ( traceCamera.Hit ) then
        desiredPos = traceCamera.HitPos - ang:Forward() * FIXED_RADIUS
    end

    local trace = util.TraceLine({
        start = client:GetShootPos(),
        endpos = client:GetShootPos() + client:GetAimVector() * 2048,
        filter = client,
        mask = MASK_SOLID
    })

    local desiredAng = ang
    if ( ax.option:Get("thirdperson.follow.angles") ) then
        local traceAng = (trace.HitPos - desiredPos):Angle()
        desiredAng = traceAng
    end

    local desiredFOV = 0

    local posInterpSpeed = ax.option:Get("thirdperson.desired.lerp.pos")
    local angInterpSpeed = ax.option:Get("thirdperson.desired.lerp.angle")
    local fovInterpSpeed = ax.option:Get("thirdperson.desired.lerp.fov")

    local ft = math.Clamp(FrameTime(), 0, 0.1)
    if ( posInterpSpeed > 0 ) then
        curPos = LerpVector(ft * posInterpSpeed, curPos, desiredPos)
    else
        curPos = desiredPos
    end

    if ( angInterpSpeed > 0 ) then
        curAng = LerpAngle(ft * angInterpSpeed, curAng, desiredAng)
    else
        curAng = desiredAng
    end

    if ( ax.option:Get("thirdperson.follow.fov") ) then
        local distance = trace.StartPos:Distance(trace.HitPos)
        desiredFOV = math.Remap(distance / 4, 0, 2048, 0, 75)
    end

    if ( fovInterpSpeed > 0 ) then
        curFOV = Lerp(ft * fovInterpSpeed, curFOV, desiredFOV)
    else
        curFOV = desiredFOV
    end

    return {
        origin = curPos,
        angles = curAng,
        fov = patch.fov - curFOV
    }
end, 99)

concommand.Add("ax_thirdperson_toggle", function(client, cmd, args)
    ax.option:Set("thirdperson", !ax.option:Get("thirdperson"))
end)
