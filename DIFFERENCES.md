# Framework Differences: Parallax vs Helix vs Nutscript vs Clockwork

This document outlines the key differences between the **Parallax Framework** and other old and outdated popular Garry's Mod roleplay frameworks: **Helix**, **Nutscript**, and **Clockwork**.

---

## Overview

| Framework | Status | Primary Focus | Base Architecture |
|-----------|--------|---------------|-------------------|
| **Parallax** | Active Development | Modern, Modular, Performance | Built from scratch |
| **Helix** | Active | Simplicity, Documentation | Derived from Nutscript |
| **Nutscript** | Active | Lightweight, Flexibility | Independent development |
| **Clockwork** | Legacy/Discontinued | Feature-rich, Complex | Original framework |

---

## Core Architecture Differences

### **Parallax**
- **Modular Design**: Clean separation between framework core and schema content
- **Schema Isolation**: Complete independence between framework and content
- **Modern Structure**: Built with current Lua and GMod standards
- **Performance First**: Optimized for efficiency and scalability

### **Helix**
- **Nutscript Evolution**: Improved version of Nutscript with better documentation
- **Character-Centric**: Strong focus on character objects and management
- **Grid Inventory**: Width/height-based inventory system
- **Documentation Heavy**: Extensive documentation and examples

### **Nutscript**
- **Lightweight Core**: Minimal base with plugin-based extensions
- **Simple Structure**: Straightforward file organization
- **Plugin Focused**: Heavy reliance on plugins for functionality
- **Community Driven**: Open development model

### **Clockwork**
- **Monolithic Design**: Large, feature-complete base framework
- **Complex Systems**: Built-in systems for most roleplay needs
- **Legacy Code**: Older codebase with accumulated complexity
- **Datastream**: Custom networking system

---

## Database & Data Management

### **Parallax**
```lua
-- Modern database abstraction
ax.sqlite:RegisterVar("users", "credits", 0)
ax.sqlite:InitializeTable("users")
ax.sqlite:LoadRow("users", "steamid", player:SteamID(), callback)
```
- **Dual Support**: SQLite (development) and MySQL (production)
- **Type Safety**: Built-in validation and type checking
- **Auto Migration**: Automatic schema updates

### **Helix**
```lua
-- Character-based data storage
local character = client:GetCharacter()
character:SetData("money", 1000)
local money = character:GetData("money", 0)
```
- **Character Objects**: Data tied to character instances
- **MySQL Focus**: Primarily MySQL-based
- **Manual Queries**: More direct database interaction

### **Nutscript**
```lua
-- Simple data system
nut.data.set("myData", value)
local value = nut.data.get("myData")
```
- **File-Based**: Often uses file storage
- **Simple API**: Basic get/set operations
- **Plugin Extended**: Advanced features through plugins

### **Clockwork**
```lua
-- Clockwork data system
Clockwork.player:SetData(player, "money", 1000)
local money = Clockwork.player:GetData(player, "money", 0)
```
- **Player-Based**: Data attached to player objects
- **Complex Queries**: Built-in query system
- **Datastream**: Custom networking for data sync

---

## Networking & Security

### **Parallax**
```lua
-- Encrypted networking with ax.relay
ax.relay:SetGlobal("server_time", os.time())
player:SetRelay("credits", 1000)
local credits = player:GetRelay("credits", 0)
```
- **Encrypted Communication**: Built-in encryption
- **Three Scopes**: Global, per-player, per-entity
- **Compressed Payloads**: Optimized bandwidth usage
- **Exploit Protection**: Server-side validation

### **Helix**
```lua
-- Net library usage
net.Start("MyMessage")
net.WriteString("Hello")
net.Send(client)
```
- **Standard Net Library**: Uses GMod's net library
- **Manual Validation**: Developer-implemented security
- **Netstream Support**: Optional third-party library

### **Nutscript**
```lua
-- Netstream integration
netstream.Start(client, "MyMessage", data)
```
- **Netstream Based**: Built-in netstream usage
- **Simple API**: Easy-to-use networking
- **Basic Security**: Minimal built-in protection

### **Clockwork**
```lua
-- Datastream system
Clockwork.datastream:Start(receiver, "MessageName", {1, 2, 3})
```
- **Custom Datastream**: Proprietary networking
- **Complex System**: Feature-rich but complex
- **Built-in Security**: Integrated validation

---

## Item & Inventory Systems

### **Parallax**
```lua
-- Weight-based inventory
local item = ax.item:Instance()
item:SetName("Soda")
item:SetWeight(1)
item:Register()

-- Inventory management
local inventory = character:GetInventory()
inventory:AddItem("soda", 1)
```
- **Weight-Based**: Realistic weight system instead of slots
- **Drag-and-Drop**: Visual inventory interface
- **Automatic Stacking**: Smart item organization
- **Size Considerations**: Items have physical dimensions

### **Helix**
```lua
-- Grid-based inventory
ITEM.name = "Soda"
ITEM.width = 1
ITEM.height = 1
ITEM.model = Model("models/food/soda.mdl")

-- Item functions
ITEM.functions.Use = {
    OnRun = function(item)
        -- Use logic
    end
}
```
- **Grid System**: Width/height-based inventory
- **Function Tables**: Organized item interactions
- **Icon Camera**: Built-in icon generation
- **Category System**: Item organization

### **Nutscript**
```lua
-- Simple item system
ITEM.name = "Soda"
ITEM.desc = "A refreshing drink"

function ITEM:onUse(client)
    -- Use logic
end
```
- **Slot-Based**: Traditional inventory slots
- **Simple Structure**: Basic item definitions
- **Hook-Based**: Function hooks for interactions
- **Plugin Extended**: Advanced features via plugins

### **Clockwork**
```lua
-- Complex item system
local ITEM = Clockwork.item:New()
ITEM.name = "Soda"
ITEM.cost = 5
ITEM.weight = 0.5

function ITEM:OnUse(player, entity)
    -- Use logic
end
```
- **Weight System**: Traditional weight-based
- **Complex Hooks**: Multiple interaction hooks
- **Entity Support**: Items can be world entities
- **Business System**: Built-in economy

---

## User Interface & Menus

### **Parallax**
- **Gamepad-Inspired**: Modern, controller-style interface
- **Responsive Design**: Adapts to different screen sizes
- **Custom UI System**: Built-in UI framework
- **Themeable**: Fully customizable appearance
- **Immersive Menus**: Contextual, roleplay-friendly

### **Helix**
- **Derma-Based**: Uses GMod's default UI system
- **Comprehensive Menus**: Feature-complete interface
- **Character Focus**: Character-centric design
- **Extensive Fonts**: Pre-defined font system
- **Documentation**: Well-documented UI components

### **Nutscript**
- **Minimal UI**: Basic interface components
- **Plugin-Based**: UI extended through plugins
- **Simple Design**: Clean, straightforward appearance
- **Community Themes**: User-created themes available

### **Clockwork**
- **Feature-Rich**: Comprehensive built-in menus
- **Complex Interface**: Many options and settings
- **Integrated Systems**: All features accessible through UI
- **Customizable**: Extensive customization options

---

## Performance & Optimization

### **Parallax**
- **Built for Performance**: Optimized from the ground up
- **Efficient Memory Usage**: Minimal garbage collection
- **Scalable Architecture**: Handles large player counts
- **Optimized Queries**: Efficient database operations
- **Compressed Networking**: Reduced bandwidth usage

### **Helix**
- **Improved from Clockwork**: Better performance than predecessor
- **Character Objects**: Efficient character management
- **Optimized Inventory**: Grid-based system improvements
- **Documentation Focus**: Performance guidelines included

### **Nutscript**
- **Lightweight Core**: Minimal base footprint
- **Plugin Impact**: Performance depends on plugins used
- **Simple Systems**: Less complex = better performance
- **Community Optimized**: User-driven improvements

### **Clockwork**
- **Heavy Framework**: Large feature set impacts performance
- **Complex Systems**: Multiple interconnected systems
- **Legacy Code**: Older optimizations and patterns
- **Feature Complete**: Everything built-in but resource-intensive

---

## Development Experience

### **Parallax**
```lua
-- Modern, clean API
function ax.util:PrintMessage(client, message)
    -- Implementation
end

-- Comprehensive documentation
--- Sends a message to the player
-- @realm shared
-- @param client Player The target player
-- @param message string The message to send
function ax.util:SendMessage(client, message)
    -- Implementation
end
```
- **K&R Style Guide**: Consistent formatting standards
- **LDoc Documentation**: Comprehensive API documentation
- **Type Safety**: Built-in validation systems
- **Error Handling**: Robust error management
- **Hot-Swappable**: Update without full restarts

### **Helix**
```lua
-- Character-focused development
local character = client:GetCharacter()
character:SetData("key", value)

-- Extensive documentation
ix.util.Include("meta/sh_character.lua")
```
- **Character Objects**: Clear data organization
- **Extensive Examples**: Many code examples
- **Helper Functions**: Utility functions provided
- **Migration Guide**: Clockwork conversion help

### **Nutscript**
```lua
-- Simple, plugin-based
function PLUGIN:PlayerSpawn(client)
    -- Hook implementation
end

-- Lightweight approach
nut.util.player.notify(client, "Message")
```
- **Simple API**: Easy to learn and use
- **Plugin System**: Modular development
- **Community Support**: Active community
- **Flexible Structure**: Adaptable to needs

### **Clockwork**
```lua
-- Complex but feature-rich
function Schema:PlayerSpawn(player)
    -- Schema hook
end

-- Comprehensive systems
Clockwork.player:SetData(player, "key", value)
```
- **Feature Complete**: Everything built-in
- **Complex API**: Steep learning curve
- **Legacy Support**: Established patterns
- **Extensive Systems**: Built-in solutions

---

## Schema & Plugin Development

### **Parallax**
```lua
-- Schema boot file
SCHEMA.Name = "My Schema"
SCHEMA.Description = "Custom roleplay schema"
SCHEMA.Author = "Developer"

-- Faction creation
local FACTION = ax.faction:Instance()
FACTION:SetName("Citizen")
FACTION:SetColor(Color(100, 150, 200))
FACTION:Register()
```
- **Schema Isolation**: Complete separation from framework
- **Modern Structure**: Clean, organized file layout
- **Instance-Based**: Object-oriented approach
- **Hot-Swappable**: Update without framework changes

### **Helix**
```lua
-- Schema setup
Schema.name = "My Schema"
Schema.author = "Developer"
Schema.description = "Custom schema"

-- Faction creation
FACTION.name = "Citizen"
FACTION.color = Color(100, 150, 200)
FACTION.models = {"models/player/group01/male_01.mdl"}
FACTION_CITIZEN = FACTION.index
```
- **Schema Files**: Organized in schema folder
- **Character Focus**: Character-centric development
- **Documentation**: Extensive guides and examples
- **Conversion Support**: Clockwork migration help

### **Nutscript**
```lua
-- Plugin structure
PLUGIN.name = "My Plugin"
PLUGIN.author = "Developer"
PLUGIN.desc = "Custom plugin"

-- Simple faction
FACTION.name = "Citizen"
FACTION.desc = "Regular citizens"
FACTION.color = Color(100, 150, 200)
```
- **Plugin-Based**: Everything is a plugin
- **Simple Structure**: Minimal requirements
- **Flexible**: Highly customizable
- **Community**: Active plugin community

### **Clockwork**
```lua
-- Schema structure
Schema.name = "My Schema"
Schema.author = "Developer"

-- Complex faction system
local FACTION = Clockwork.faction:New("Citizen")
FACTION.whitelist = false
FACTION.models = {
    male = {"models/player/group01/male_01.mdl"},
    female = {"models/player/group01/female_01.mdl"}
}
FACTION_CITIZEN = FACTION:Register()
```
- **Comprehensive**: Built-in systems for everything
- **Complex Structure**: Many files and systems
- **Feature Rich**: Extensive customization options
- **Legacy**: Established patterns and practices

---

## Migration Considerations

### **From Clockwork to Parallax**
- **Database**: Convert player data to character-based system
- **Items**: Restructure from weight to weight-based system
- **Networking**: Replace datastream with ax.relay
- **UI**: Rebuild interface with new UI system
- **Factions**: Convert to instance-based system

### **From Helix to Parallax**
- **Characters**: Similar character system, easier migration
- **Inventory**: Convert from grid to weight-based
- **Networking**: Replace most player related net messages with ax.relay
- **Database**: Migrate to ax.sqlite/ax.sqloo system
- **UI**: Rebuild with new UI framework

### **From Nutscript to Parallax**
- **Plugins**: Convert plugins to modules
- **Data**: Migrate from file-based to database
- **Networking**: Replace netstream player related messages with ax.relay
- **Items**: Restructure item system
- **UI**: Rebuild interface components

---

## Community & Support

### **Parallax**
- **Active Development**: Regular updates and improvements
- **Discord Community**: Active support community
- **Documentation**: Comprehensive guides and API docs
- **GitHub**: Open development on GitHub
- **Performance Focus**: Optimized for production use

### **Helix**
- **Stable**: Mature, well-tested framework
- **Documentation**: Extensive documentation and examples
- **Community**: Large, active community
- **Support**: Good community support
- **Nutscript Legacy**: Benefits from Nutscript experience

### **Nutscript**
- **Lightweight**: Minimal, focused approach
- **Community**: Inactive but existing community
- **Simple**: Easy to learn and use
- **Flexible**: Highly customizable
- **Open Source**: Community-driven development

### **Clockwork**
- **Legacy**: No longer actively developed
- **Feature Complete**: Comprehensive feature set
- **Community**: Existing community and resources
- **Documentation**: Extensive documentation available
- **Complex**: Steep learning curve for new developers

---

## Conclusion

**Parallax** represents a modern approach to Garry's Mod roleplay frameworks, focusing on:
- **Performance**: Built for efficiency and scalability
- **Security**: Encrypted networking and validation
- **Developer Experience**: Clean APIs and comprehensive documentation
- **Modularity**: Flexible, extensible architecture
- **Modern Standards**: Current Lua and GMod best practices

Choose **Parallax** if you want a modern, high-performance framework with strong security and developer-friendly features.

Choose **Helix** for extensive documentation and community support.

Choose **Nutscript** for simplicity and flexibility.

**Clockwork** remains an option for those needing its specific features, though it's no longer actively developed.