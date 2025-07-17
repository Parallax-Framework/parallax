--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

-- Hologram model cache and timing
local hologramCache = hologramCache or {}
local hologramModels = hologramModels or {}
local hologramEntities = hologramEntities or {}
local lastModelUpdate = lastModelUpdate or 0

--- Gets a random model from faction models with caching
-- @param factionID The faction ID
-- @return String model path or nil
local function GetRandomFactionModel(factionID)
    local factionData = ax.faction:Get(factionID)
    if ( !factionData ) then return nil end

    -- Check cache first
    if ( hologramCache[factionID] and hologramCache[factionID].models ) then
        local models = hologramCache[factionID].models
        if ( #models > 0 ) then
            return models[math.random(#models)]
        end
    end

    -- Build cache if not exists
    local models = {}

    local factionModels = factionData:GetModels()
    for i = 1, #factionModels do
        table.insert(models, factionModels[i])
    end

    -- Fallback to default citizen models if no faction models found
    if ( #models == 0 ) then
        models = {
            "models/player/group01/male_01.mdl",
            "models/player/group01/male_02.mdl",
            "models/player/group01/male_03.mdl",
            "models/player/group01/male_04.mdl",
            "models/player/group01/male_05.mdl",
            "models/player/group01/male_06.mdl",
            "models/player/group01/male_07.mdl",
            "models/player/group01/male_08.mdl",
            "models/player/group01/male_09.mdl",
            "models/player/group01/female_01.mdl",
            "models/player/group01/female_02.mdl",
            "models/player/group01/female_03.mdl",
            "models/player/group01/female_04.mdl",
            "models/player/group01/female_05.mdl",
            "models/player/group01/female_06.mdl"
        }
    end

    -- Cache the models
    hologramCache[factionID] = {
        models = models,
        lastUpdate = CurTime()
    }

    return models[math.random(#models)]
end

--- Creates a clientside model entity for hologram display
-- @param spawnID The spawn point ID
-- @param model The model path
-- @param pos The position
-- @param ang The angle
-- @return ClientsideModel entity or nil
local function CreateHologramEntity(spawnID, model, pos, ang)
    local ent = ClientsideModel(model)
    if ( !IsValid(ent) ) then return nil end

    -- Set up the entity
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:SetNoDraw(false)
    ent:SetModelScale(1)
    ent:SetColor(Color(255, 255, 255, 180))
    ent:SetRenderMode(RENDERMODE_TRANSALPHA)
    ent:SetMaterial("models/wireframe")

    -- Store spawn reference
    ent.SpawnID = spawnID
    ent.CreatedTime = CurTime()
    ent.BobOffset = math.random() * math.pi * 2

    return ent
end

--- Updates hologram models for all spawn points
local function UpdateHologramModels()
    local currentTime = CurTime()

    -- Update every 3-5 seconds
    if ( currentTime - lastModelUpdate < math.random(3, 5) ) then
        return
    end

    lastModelUpdate = currentTime

    -- Update models for each spawn point
    for id, spawn in pairs(MODULE.SpawnPoints) do
        local model = GetRandomFactionModel(spawn.faction)
        if ( model ) then
            -- Remove old entity if it exists
            if ( IsValid(hologramEntities[id]) ) then
                hologramEntities[id]:Remove()
            end

            -- Create new hologram entity
            local basePos = spawn.pos + Vector(0, 0, 5)
            local baseAng = Angle(0, 0, 0)

            local ent = CreateHologramEntity(id, model, basePos, baseAng)
            if ( IsValid(ent) ) then
                hologramEntities[id] = ent
                hologramModels[id] = {
                    model = model,
                    updateTime = currentTime,
                    bobOffset = ent.BobOffset
                }
            end
        end
    end
end

--- Updates hologram entity positions and animations
local function UpdateHologramEntities()
    local currentTime = CurTime()

    for id, ent in pairs(hologramEntities) do
        if ( !IsValid(ent) ) then
            hologramEntities[id] = nil
            continue
        end

        local spawn = MODULE.SpawnPoints[id]
        if ( !spawn ) then
            ent:Remove()
            hologramEntities[id] = nil
            continue
        end

        -- Calculate bobbing animation
        local bobHeight = math.sin(currentTime * 2 + ent.BobOffset) * 3
        local newPos = spawn.pos + Vector(0, 0, bobHeight + 5)

        -- Calculate rotation
        local newAng = Angle(0, currentTime * 30, 0)

        -- Update entity position and angle
        ent:SetPos(newPos)
        ent:SetAngles(newAng)

        -- Update color based on spawn validity
        local isValid = MODULE.spawn:IsValid(spawn)
        local color = isValid and MODULE.Config.SpawnBoxColor or MODULE.Config.InvalidSpawnColor
        ent:SetColor(Color(color.r, color.g, color.b, 180))

        -- Distance-based alpha
        local client = ax.client
        if ( IsValid(client) ) then
            local distance = client:EyePos():Distance(spawn.pos)
            local alpha = math.max(0, 1 - (distance / 1024))
            local finalColor = Color(color.r, color.g, color.b, alpha * 180)
            ent:SetColor(finalColor)

            -- Hide if too far away
            ent:SetNoDraw(distance > 1024)
        end
    end
end

--- Cleans up all hologram entities
local function CleanupHologramEntities()
    for id, ent in pairs(hologramEntities) do
        if ( IsValid(ent) ) then
            ent:Remove()
        end
    end
    hologramEntities = {}
end

--- Render spawn points if enabled
function MODULE:PostDrawOpaqueRenderables()
    if ( !ax.option:Get("spawn.showSpawns") ) then
        CleanupHologramEntities()
        return
    end

    local client = ax.client
    if ( !IsValid(client) or !CAMI.PlayerHasAccess(client, "Parallax - Manage Spawns", nil) ) then
        CleanupHologramEntities()
        return
    end

    -- Update hologram models periodically
    UpdateHologramModels()

    -- Update hologram entity positions and animations
    UpdateHologramEntities()

    local eyePos = client:EyePos()
    local maxDistance = 2048

    for id, spawn in pairs(MODULE.SpawnPoints) do
        local distance = eyePos:Distance(spawn.pos)
        if ( distance > maxDistance ) then continue end

        -- Calculate alpha based on distance
        local alpha = math.max(0, 1 - (distance / maxDistance))

        -- Check if spawn is valid
        local isValid = MODULE.spawn:IsValid(spawn)
        local color = isValid and MODULE.Config.SpawnBoxColor or MODULE.Config.InvalidSpawnColor
        color = ColorAlpha(color, alpha * 255)

        -- Draw bounding box
        local mins = Vector(-16, -16, 0)
        local maxs = Vector(16, 16, 72)

        render.DrawWireframeBox(spawn.pos, spawn.ang, mins, maxs, color, false)

        -- Draw faction info
        if ( distance < 512 ) then
            local factionData = ax.faction:Get(spawn.faction)
            local factionName = factionData and factionData:GetName() or "Unknown"

            local pos = spawn.pos + Vector(0, 0, 80)
            local ang = (eyePos - pos):Angle()
            ang:RotateAroundAxis(ang:Up(), 90)
            ang:RotateAroundAxis(ang:Forward(), 90)

            cam.IgnoreZ(true)
            cam.Start3D2D(pos, ang, 0.05)
                draw.SimpleTextOutlined("Spawn #" .. id, "ax.huge.bold", 0, 0, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, alpha * 255))
                draw.SimpleTextOutlined(factionName, "ax.massive", 0, draw.GetFontHeight("ax.huge"), color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, alpha * 255))
            cam.End3D2D()
            cam.IgnoreZ(false)
        end
    end
end

--- Clear hologram cache when spawn points are updated
function MODULE:OnSpawnPointsUpdated()
    hologramCache = {}
    hologramModels = {}
    CleanupHologramEntities()
end

--- Clear hologram cache on code reload
function MODULE:OnReloaded()
    hologramCache = {}
    hologramModels = {}
    CleanupHologramEntities()
end

--- Cleanup on shutdown
function MODULE:ShutDown()
    CleanupHologramEntities()
end

--- Handle when the option is disabled
function MODULE:OnOptionChanged(key, value)
    if ( key == "spawn.showSpawns" and !value ) then
        hologramCache = {}
        hologramModels = {}
        CleanupHologramEntities()
    end
end