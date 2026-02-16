# Examples

Practical code examples for common Parallax Framework tasks.

## Table of Contents
- [Example 1: Creating a Custom Faction](#example-1-creating-a-custom-faction)
- [Example 2: Creating a Food Item](#example-2-creating-a-food-item)
- [Example 3: Adding Chat Commands](#example-3-adding-chat-commands)
- [Example 4: Extending Character Data](#example-4-extending-character-data)
- [Example 5: Creating a Module](#example-5-creating-a-module)
- [Example 6: Schema-Specific Hooks](#example-6-schema-specific-hooks)

---

## Example 1: Creating a Custom Faction

```lua
-- schema/factions/sh_medical.lua
FACTION.name = "Medical Staff"
FACTION.description = "Trained medical personnel providing care to citizens."
FACTION.color = Color(0, 255, 0)
FACTION.image = ax.util:GetMaterial("parallax/hl2rp/banners/medical.png")

FACTION.models = {
    "models/humans/group01/male_06.mdl",
    "models/humans/group01/female_06.mdl",
}

-- Precache models for performance
for i = 1, #FACTION.models do
    util.PrecacheModel(FACTION.models[i])
    ax.animations:SetModelClass(FACTION.models[i], "citizen_male")
end

-- Custom validation
function FACTION:CanBecome(client)
    local char = client:GetCharacter()
    
    -- Must have medical training flag
    if !char:HasFlag("medical_training") then
        return false, "You must complete medical training first"
    end
    
    -- Must be citizen
    if char:GetFaction() != FACTION_CITIZEN then
        return false, "Only citizens can become medical staff"
    end
    
    return true
end

FACTION_MEDICAL = FACTION.index
```

---

## Example 2: Creating a Food Item

```lua
-- schema/items/base/sh_food.lua
ITEM.name = "Food Base"
ITEM.description = "Base class for food items"
ITEM.category = "Food"
ITEM.weight = 0.5
ITEM.isBase = true

function ITEM:CanUse(client)
    return client:Alive()
end

function ITEM:Consume(client)
    -- Override in derived items
    return true
end

-- Derived food item
-- schema/items/food/sh_bread.lua
ITEM.name = "Bread"
ITEM.description = "A loaf of fresh bread."
ITEM.model = "models/props/food/bread.mdl"
ITEM.weight = 0.3
ITEM.category = "Food"
ITEM.base = "food"

-- Nutrition data
ITEM.nutrition = 25  -- HP restored

function ITEM:Consume(client)
    local hp = client:Health()
    local newHp = math.min(hp + self.nutrition, 100)
    
    client:SetHealth(newHp)
    client:Notify("You ate the bread and restored " .. (newHp - hp) .. " HP")
    
    return true  -- Consume the item
end

-- Add eat action
ITEM:AddAction("eat", {
    name = "Eat",
    icon = "icon16/cake.png",
    order = 1,
    CanUse = function(this, client)
        return client:Alive() and client:Health() < 100
    end,
    OnRun = function(action, item, client)
        local success = item:Consume(client)
        if success then
            -- Remove item
            return true
        end
        return false
    end
})
```

---

## Example 3: Adding Chat Commands

```lua
-- schema/core/sh_commands.lua
ax.command:Add("me", {
    description = "Perform an action (roleplay emote)",
    arguments = {
        {
            name = "action",
            type = ax.type.text,
            required = true
        }
    },
    OnRun = function(this, client, action)
        local char = client:GetCharacter()
        local name = char:GetName()
        local message = "** " .. name .. " " .. action
        
        -- Send to nearby players
        for _, ply in ipairs(player.GetAll()) do
            if client:GetPos():Distance(ply:GetPos()) < 300 then
                ply:ChatPrint(message)
            end
        end
        
        return true
    end
})

ax.command:Add("pm", {
    alias = {"privatemessage", "whisper", "w"},
    description = "Send a private message to a player",
    arguments = {
        {
            name = "target",
            type = ax.type.player,
            required = true
        },
        {
            name = "message",
            type = ax.type.text,
            required = true
        }
    },
    OnRun = function(this, client, target, message)
        if !IsValid(target) then
            client:Notify("Player not found")
            return false
        end
        
        local senderName = client:GetCharacter():GetName()
        local receiverName = target:GetCharacter():GetName()
        
        client:ChatPrint("[PM] To " .. receiverName .. ": " .. message)
        target:ChatPrint("[PM] From " .. senderName .. ": " .. message)
        
        return true
    end
})

ax.command:Add("ooc", {
    alias = {"outofcharacter"},
    description = "Send an out-of-character message",
    arguments = {
        {
            name = "message",
            type = ax.type.text,
            required = true
        }
    },
    OnRun = function(this, client, message)
        local name = client:Nick()
        local msg = "(OOC) " .. name .. ": " .. message
        
        for _, ply in ipairs(player.GetAll()) do
            ply:ChatPrint(msg)
        end
        
        return true
    end
})
```

---

## Example 4: Extending Character Data

```lua
-- schema/meta/sh_character.lua
function ax.character.meta:IsArrested()
    return self:GetVar("arrested", false)
end

function ax.character.meta:SetArrested(arrested)
    self:SetVar("arrested", arrested)
end

function ax.character.meta:GetWarrant()
    return self:GetVar("warrant", nil)
end

function ax.character.meta:SetWarrant(issuer, reason)
    self:SetVar("warrant", {
        issuer = issuer:GetCharacter():GetName(),
        reason = reason,
        time = os.time()
    })
end

-- schema/core/sh_character.lua
ax.character:RegisterVar("arrested", {
    default = false,
    fieldType = ax.type.bool
})

ax.character:RegisterVar("warrant", {
    fieldType = ax.type.data
})

-- Usage
local char = client:GetCharacter()
if char:IsArrested() then
    client:Notify("You are under arrest!")
end

-- Set warrant
char:SetWarrant(officer, "Possession of contraband")

-- Check warrant
local warrant = char:GetWarrant()
if warrant then
    print("Warrant issued by:", warrant.issuer)
    print("Reason:", warrant.reason)
    print("Time:", os.date("%Y-%m-%d %H:%M:%S", warrant.time))
end
```

---

## Example 5: Creating a Module

```lua
-- modules/medic_system/boot.lua
MODULE = MODULE or {}
MODULE.name = "Medic System"
MODULE.description = "Advanced medical treatment system"
MODULE.author = "YourName"

function MODULE:Initialize()
    -- Register heal command
    ax.command:Add("heal", {
        description = "Heal a player",
        arguments = {
            {
                name = "target",
                type = ax.type.player,
                required = true
            },
            {
                name = "amount",
                type = ax.type.number,
                default = 25,
                min = 1,
                max = 100
            }
        },
        OnRun = function(this, client, target, amount)
            local char = client:GetCharacter()
            
            -- Check if medic
            if char:GetFaction() != FACTION_MEDICAL then
                client:Notify("Only medical staff can heal!")
                return false
            end
            
            -- Check if target is alive
            if !target:Alive() then
                client:Notify("Target is not alive!")
                return false
            end
            
            -- Heal target
            local hp = target:Health()
            local newHp = math.min(hp + amount, target:GetMaxHealth())
            target:SetHealth(newHp)
            
            -- Notify
            client:Notify("You healed " .. target:Nick() .. " for " .. (newHp - hp) .. " HP")
            target:Notify("You were healed by " .. char:GetName() .. " for " .. (newHp - hp) .. " HP")
            
            return true
        end
    })
    
    ax.util:PrintSuccess("Module '" .. MODULE.name .. "' loaded!")
end

return MODULE
```

---

## Example 6: Schema-Specific Hooks

```lua
-- schema/hooks/sh_hooks.lua
-- Modify combine camera sounds
function SCHEMA:EntityEmitSound(data)
    local ent = data.Entity
    if !IsValid(ent) then return end
    
    if ent:GetClass() == "npc_combine_camera" then
        -- Reduce camera sound volume
        data.SoundLevel = 60
        return true
    end
    
    -- Reduce NPC sounds
    if ent:IsNPC() then
        data.SoundLevel = data.SoundLevel - 15
        return true
    end
end

-- Custom door detection
local combineDoorModels = {
    ["models/props_combine/combine_door01.mdl"] = true,
    ["models/combine_gate_vehicle.mdl"] = true,
    ["models/combine_gate_citizen.mdl"] = true,
}

function SCHEMA:IsEntityDoor(entity, class)
    return class == "prop_dynamic" and combineDoorModels[string.lower(entity:GetModel())]
end

-- Custom player spawn logic
function SCHEMA:PlayerSpawn(client)
    local char = client:GetCharacter()
    
    if char:IsCombine() then
        -- Combine spawn logic
        client:SetModel(char:GetModel())
        client:SetMaxHealth(150)
        client:SetHealth(150)
        client:SetArmor(50)
    else
        -- Citizen spawn logic
        client:SetModel(char:GetModel())
        client:SetMaxHealth(100)
        client:SetHealth(100)
        client:SetArmor(0)
    end
end

-- Player death hook
function SCHEMA:PostPlayerDeath(client, inflictor, attacker)
    local char = client:GetCharacter()
    
    if char then
        -- Drop items on death
        local inv = ax.inventory:Get(char:GetInventoryID())
        if inv then
            for itemID, item in pairs(inv.items) do
                ax.item:Transfer(item, inv, 0)
            end
        end
        
        -- Create death marker
        local pos = client:GetPos()
        ax.net:StartPVS(pos, "death_marker", client:SteamID64(), pos, os.time())
    end
end

-- Player pickup item hook
function SCHEMA:PlayerCanPickupItem(client, item)
    local char = client:GetCharacter()
    
    -- Prevent citizens from picking up weapons
    if item.category == "Weapons" and char:GetFaction() == FACTION_CITIZEN then
        client:Notify("You cannot pick up weapons!")
        return false
    end
    
    return true
end
```

---

## Additional Examples

### Creating a Custom Inventory

```lua
-- Create a storage container inventory
ax.inventory:Create({maxWeight = 100}, function(inventory)
    print("Created storage inventory:", inventory.id)
    
    -- Spawn a container entity
    local container = ents.Create("prop_physics")
    container:SetModel("models/props_junk/wood_crate001a.mdl")
    container:SetPos(Vector(0, 0, 0))
    container:Spawn()
    container:SetNWInt("InventoryID", inventory.id)
    
    -- Add storage action
    container:SetUseType(SIMPLE_USE)
    function container:Use(activator, caller)
        if activator:IsPlayer() then
            ax.net:Start(activator, "open_storage", inventory.id)
        end
    end
end)
```

### Item Transfer Between Players

```lua
-- Transfer item from player A to player B
ax.command:Add("give", {
    description = "Give an item to another player",
    arguments = {
        {
            name = "target",
            type = ax.type.player,
            required = true
        },
        {
            name = "item",
            type = ax.type.text,
            required = true
        }
    },
    OnRun = function(this, client, target, itemName)
        local char = client:GetCharacter()
        local targetChar = target:GetCharacter()
        
        -- Find item in player's inventory
        local playerInv = ax.inventory:Get(char:GetInventoryID())
        local targetInv = ax.inventory:Get(targetChar:GetInventoryID())
        
        -- Search for item
        local itemToGive = nil
        for itemID, item in pairs(playerInv.items) do
            if string.lower(item.name) == string.lower(itemName) then
                itemToGive = item
                break
            end
        end
        
        if !itemToGive then
            client:Notify("You don't have that item!")
            return false
        end
        
        -- Transfer item
        local success, reason = ax.item:Transfer(itemToGive, playerInv, targetInv, function(success)
            if success then
                client:Notify("You gave " .. itemToGive.name .. " to " .. target:Nick())
                target:Notify("You received " .. itemToGive.name .. " from " .. client:Nick())
            else
                client:Notify("Failed to give item: " .. reason)
            end
        end)
        
        return success, reason
    end
})
```

### Custom Character Creation

```lua
ax.command:Add("charcreate", {
    description = "Create a new character",
    arguments = {
        {
            name = "name",
            type = ax.type.string,
            required = true
        },
        {
            name = "description",
            type = ax.type.text,
            required = true
        },
        {
            name = "gender",
            type = ax.type.string,
            choices = {
                male = true,
                female = true
            }
        }
    },
    OnRun = function(this, client, name, description, gender)
        -- Validate name
        if string.len(name) < 2 or string.len(name) > 32 then
            client:Notify("Name must be between 2 and 32 characters!")
            return false
        end
        
        -- Validate description
        if string.len(description) < 16 then
            client:Notify("Description must be at least 16 characters!")
            return false
        end
        
        -- Create character
        ax.character:Create(client, {
            name = name,
            description = description,
            faction = FACTION_CITIZEN,
            gender = gender or "male"
        }, function(character)
            if character then
                client:Notify("Character created successfully!")
                client:SpawnCharacter(character)
            else
                client:Notify("Failed to create character!")
            end
        end)
        
        return true
    end
})
```

---

**Continue to:** [Best Practices](07-BEST_PRACTICES.md)