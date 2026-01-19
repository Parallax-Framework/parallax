--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Server-side map scene management.
-- @module ax.mapscene

ax.mapscene = ax.mapscene or {}
ax.mapscene.scenes = ax.mapscene.scenes or {}
ax.mapscene.pendingPairs = ax.mapscene.pendingPairs or {}

local MAX_CHUNK = 60000

--- Build the persistence key for map scenes.
-- @return string
function ax.mapscene:GetDataKey()
    return "map_scenes"
end

--- Get the configured persistence scope.
-- @return string
function ax.mapscene:GetScope()
    local scope = ax.config:Get("map.scene.scope", "map")
    if ( scope != "map" and scope != "project" and scope != "global" ) then
        scope = "map"
    end

    return scope
end

--- Load scenes from disk.
-- @realm server
function ax.mapscene:Load()
    local data = ax.data:Get(self:GetDataKey(), nil, {
        scope = self:GetScope()
    })

    self.scenes = {}

    if ( !data ) then
        ax.util:PrintDebug("No map scene data found, starting fresh.")
        return
    end

    local list = data.scenes or data
    if ( !istable(list) ) then
        ax.util:PrintWarning("Map scene data invalid, starting fresh.")
        return
    end

    for i = 1, #list do
        local cleaned, err = self:SanitizeScene(list[i])
        if ( cleaned ) then
            self.scenes[#self.scenes + 1] = cleaned
        else
            ax.util:PrintWarning("Skipped invalid map scene: " .. tostring(err))
        end
    end

    ax.util:PrintSuccess("Loaded " .. tostring(#self.scenes) .. " map scenes.")
end

--- Save scenes to disk.
-- @realm server
function ax.mapscene:Save()
    ax.data:Set(self:GetDataKey(), {
        version = self.version or 1,
        scenes = self.scenes
    }, {
        scope = self:GetScope(),
        human = true
    })
end

--- Serialize scenes for network sync using sfs + compression.
-- @return string|nil
function ax.mapscene:SerializeScenes()
    local payload = {
        version = self.version or 1,
        scenes = self.scenes
    }

    local encoded = sfs.encode(payload)
    if ( !isstring(encoded) or encoded == "" ) then
        return nil
    end

    local compressed = util.Compress(encoded)
    if ( !isstring(compressed) or compressed == "" ) then
        return nil
    end

    local safe = util.Base64Encode(compressed)
    if ( !isstring(safe) or safe == "" ) then
        return nil
    end

    return safe
end

--- Send a scene sync to a player or broadcast.
-- @param target Player|table|nil
function ax.mapscene:Sync(target)
    local compressed = self:SerializeScenes()
    if ( !compressed ) then
        ax.util:PrintError("Failed to serialize map scenes for sync.")
        return
    end

    local length = #compressed
    if ( length <= MAX_CHUNK ) then
        ax.net:Start(target, "mapscene.sync", compressed)
        return
    end

    local token = tostring(os.time()) .. ":" .. tostring(math.random(1000, 9999))
    local total = math.ceil(length / MAX_CHUNK)

    ax.net:Start(target, "mapscene.sync.start", token, total, length)

    local index = 0
    local offset = 1
    while ( offset <= length ) do
        index = index + 1
        local chunk = string.sub(compressed, offset, offset + MAX_CHUNK - 1)
        ax.net:Start(target, "mapscene.sync.chunk", token, index, chunk)
        offset = offset + MAX_CHUNK
    end

    ax.net:Start(target, "mapscene.sync.finish", token)
end

--- Add a scene to the registry.
-- @param scene table
-- @return boolean, string|nil
function ax.mapscene:AddScene(scene)
    local maxScenes = ax.config:Get("map.scene.max", 128)
    if ( self:GetCount() >= maxScenes ) then
        return false, "Max scene count reached"
    end

    local cleaned, err = self:SanitizeScene(scene)
    if ( !cleaned ) then
        return false, err
    end

    if ( !isstring(cleaned.name) ) then
        cleaned.name = "Scene " .. tostring(self:GetCount() + 1)
    end

    self.scenes[#self.scenes + 1] = cleaned
    self:Save()
    self:Sync(nil)

    return true
end

--- Remove scenes near a position.
-- @param position Vector
-- @param radius number
-- @return number
function ax.mapscene:RemoveScenesNear(position, radius)
    if ( !self:IsValidVector(position) ) then return 0 end

    radius = tonumber(radius) or 280
    local radiusSqr = radius * radius
    local removed = 0

    for i = #self.scenes, 1, -1 do
        local scene = self.scenes[i]
        local remove = false

        if ( scene.origin:DistToSqr(position) <= radiusSqr ) then
            remove = true
        elseif ( self:IsPair(scene) and scene.origin2:DistToSqr(position) <= radiusSqr ) then
            remove = true
        end

        if ( remove ) then
            table.remove(self.scenes, i)
            removed = removed + 1
        end
    end

    if ( removed > 0 ) then
        self:Save()
        self:Sync(nil)
    end

    return removed
end

--- Export scenes to JSON for sharing.
-- @return string|nil
function ax.mapscene:ExportToJSON()
    local export = {
        version = self.version or 1,
        scenes = {}
    }

    for i = 1, #self.scenes do
        export.scenes[#export.scenes + 1] = self:PackScene(self.scenes[i])
    end

    return util.TableToJSON(export, true)
end

--- Import scenes from JSON.
-- @param json string
-- @return boolean, string|nil
function ax.mapscene:ImportFromJSON(json)
    if ( !isstring(json) or json == "" ) then
        return false, "Invalid JSON"
    end

    local ok, decoded = pcall(util.JSONToTable, json)
    if ( !ok or !istable(decoded) ) then
        return false, "Failed to parse JSON"
    end

    local list = decoded.scenes or decoded
    if ( !istable(list) ) then
        return false, "JSON does not contain scenes"
    end

    local maxScenes = ax.config:Get("map.scene.max", 128)
    local imported = {}

    for i = 1, #list do
        local scene, err = self:UnpackScene(list[i])
        if ( scene ) then
            imported[#imported + 1] = scene
            if ( #imported >= maxScenes ) then
                break
            end
        else
            ax.util:PrintWarning("Skipped invalid imported scene: " .. tostring(err))
        end
    end

    self.scenes = imported
    self:Save()
    self:Sync(nil)

    return true
end

--- Queue or complete a paired scene capture.
-- @param client Player
-- @param scene table
-- @param bPair boolean
-- @return boolean, string|nil
function ax.mapscene:HandlePairCapture(client, scene, bPair)
    if ( !bPair ) then
        return self:AddScene(scene)
    end

    local steamID = client:SteamID64()
    if ( !self.pendingPairs[steamID] ) then
        self.pendingPairs[steamID] = scene
        return true, "First scene captured, repeat to complete the pair."
    end

    local first = self.pendingPairs[steamID]
    self.pendingPairs[steamID] = nil

    first.origin2 = scene.origin
    first.angles2 = scene.angles

    return self:AddScene(first)
end

--- Send a preview target to a specific client.
-- @param client Player
-- @param identifier number|string|nil
function ax.mapscene:SendPreview(client, identifier)
    if ( !IsValid(client) ) then return end
    ax.net:Start(client, "mapscene.preview", identifier)
end

--- Add map scene origin to the PVS.
-- @param client Player
function ax.mapscene:SetupPlayerVisibility(client)
    if ( !IsValid(client) ) then return end

    local origin = client.axMapSceneOrigin
    if ( self:IsValidVector(origin) ) then
        AddOriginToPVS(origin)
    end
end
