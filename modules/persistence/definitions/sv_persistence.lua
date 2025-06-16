----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 --- Made by a transgender queen
 -- Slay queen Riggs
 -- Stay Powerfull against the Patiarchy by a man (Alex Grist) stealing code
 -- #OverwatchFramework #CodeStealingMatters

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

local savedEntities = {}

--- Saves all persistent entities and their custom data.
function MODULE:SaveEntities()
    ax.log:Send("Saving persistent entities...")

    savedEntities = {}

    -- Iterate through all possible persistent entity classes and mark them
    -- as persistent. This is done to ensure that all entities are marked
    -- correctly before saving.
    for class, methods in pairs(self.PersistentEntities) do
        for _, ent in ipairs(ents.FindByClass(class)) do
            if ( !IsValid(ent) ) then continue end

            ent:SetRelay("persistent", true)
        end
    end

    -- Now we can iterate through all entities and save their data.
    -- Not sure if this is a fast way to do this, but it works.
    -- If it becomes a problem, we can always optimize it later.
    for _, ent in ents.Iterator() do
        if ( !IsValid(ent) or ent:IsPlayer() ) then continue end

        local class = ent:GetClass()
        local relay = ent:GetRelay("persistent")
        if ( relay != true ) then continue end

        local methods = self.PersistentEntities[class]
        local data = methods and methods.Save and methods.Save(ent) or {}

        table.insert(savedEntities, {
            class = class,
            pos = ent:GetPos(),
            ang = ent:GetAngles(),
            mdl = ent:GetModel(),
            data = data
        })
    end

    ax.log:Send("Saved " .. #savedEntities .. " persistent entities.")
    ax.data:Set("persistent_entities", savedEntities)
end

--- Loads all previously saved persistent entities.
function MODULE:LoadEntities()
    ax.log:Send("Loading persistent entities...")

    for k, v in pairs(savedEntities) do
        for _, ent in ipairs(ents.FindByClass(v.class)) do
            if ( ent:GetRelay("persistent") != true ) then continue end

            SafeRemoveEntity(ent)
        end
    end

    savedEntities = ax.data:Get("persistent_entities", {})

    for _, entData in ipairs(savedEntities) do
        local class = entData.class
        local ent = ents.Create(class)
        if ( !IsValid(ent) ) then continue end

        ent:SetPos(entData.pos)
        ent:SetAngles(entData.ang)

        local mdl = Model(entData.mdl)
        ent:SetModel(mdl)

        ent:Spawn()
        ent:Activate()

        local handler = self.PersistentEntities[class]
        if ( handler and handler.Load and entData.data ) then
            handler.Load(ent, entData.data)
        end

        ent:SetRelay("persistent", true)
    end

    ax.log:Send("Loaded " .. #savedEntities .. " persistent entities.")
end

concommand.Add("ax_persistence_save", function(client, cmd, arguments)
    if ( IsValid(client) and !client:IsAdmin() ) then
        client:Notify("You do not have permission to use this command!")
        return
    end

    MODULE:SaveEntities()
    ax.log:Send(ax.log:Format(client) .. " manually saved all persistent entities.")
    client:Notify("Saved all persistent entities.")
end)

concommand.Add("ax_persistence_load", function(client, cmd, arguments)
    if ( IsValid(client) and !client:IsAdmin() ) then
        client:Notify("You do not have permission to use this command!")
        return
    end

    MODULE:LoadEntities()
    ax.log:Send(ax.log:Format(client) .. " manually loaded all persistent entities.")
    client:Notify("Loaded all persistent entities.")
end)

concommand.Add("ax_persistence_mark", function(client, cmd, arguments)
    if ( !IsValid(client) or !client:IsAdmin() ) then
        client:Notify("You do not have permission to use this command!")
        return
    end

    local ent = client:GetEyeTrace().Entity
    if ( !IsValid(ent) ) then return end

    if ( ent:GetRelay("persistent") == true ) then
        client:Notify("This entity is already marked for persistence.")
        return
    end

    ent:SetRelay("persistent", true)
    ax.log:Send(ax.log:Format(client) .. " marked entity " .. tostring(ent) .. " as persistent.")
    client:Notify("Marked entity " .. tostring(ent) .. " as persistent.")

    MODULE:SaveEntities()
end)

concommand.Add("ax_persistence_unmark", function(client, cmd, arguments)
    if ( !IsValid(client) or !client:IsAdmin() ) then
        client:Notify("You do not have permission to use this command!")
        return
    end

    local ent = client:GetEyeTrace().Entity
    if ( !IsValid(ent) ) then return end

    if ( ent:GetRelay("persistent") != true ) then
        client:Notify("This entity is not marked for persistence.")
        return
    end

    ent:SetRelay("persistent", false)
    ax.log:Send(ax.log:Format(client) .. " unmarked entity " .. tostring(ent) .. " as persistent.")
    client:Notify("Unmarked entity " .. tostring(ent) .. " as persistent.")

    MODULE:SaveEntities()
end)