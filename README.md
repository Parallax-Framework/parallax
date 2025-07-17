# Parallax Framework

**Parallax** is a lightweight, modular roleplay framework for Garry's Mod designed from the ground up to provide stable, dynamic, and immersive roleplay experiences. Built with performance, organization, and developer control in mind, Parallax avoids the bloat and legacy issues of traditional frameworks while offering a solid foundation for any roleplay scenario.

Whether you're creating a Half-Life universe roleplay, military simulation, modern city roleplay, or something entirely unique, Parallax provides the tools and architecture to bring your vision to life.

---

## 🚀 Key Features

### **Modular Architecture**
- Clean separation between framework core and schema content
- Independent modules that can be easily replaced or extended
- Organized code structure with predefined conventions
- Hot-swappable systems without framework modification

### **Schema System**
- Complete isolation between framework and content
- Easy framework updates without affecting custom schemas
- Multiple schema support with independent databases
- Template schemas for quick project startup

### **Custom UI System**
- Gamepad-inspired interface design
- Fully customizable and themeable components
- Responsive design that adapts to different screen sizes
- Immersive menus that match your server's aesthetic

### **Advanced Inventory System**
- Weight-based capacity instead of arbitrary slot limits
- Realistic item management with size and weight considerations
- Drag-and-drop interface with visual feedback
- Automatic item stacking and organization

### **Secure Networking**
- [`ax.relay`](RELAY.md) provides encrypted, compressed data synchronization
- Three-scope networking: global, per-player, and per-entity
- Protection against client-side exploits and data sniffing
- Optimized bandwidth usage for better performance

### **Database Flexibility**
- Support for both SQLite (development) and MySQL (production)
- Dynamic schema creation and column management
- Automatic table initialization and migration
- Type-safe data operations with validation

### **Performance Optimized**
- Built with optimization as a core principle
- Efficient memory usage and garbage collection
- Minimal runtime overhead
- Scalable architecture for large player counts

### **Developer-Friendly**
- Comprehensive API documentation with LDoc
- Enforced K&R coding standards for consistency
- Rich debugging and logging systems
- Extensive error handling and validation

---

## 📁 Repository Structure

```
parallax/
├── .github/                    # GitHub workflows and automation
├── .vscode/                    # VS Code configuration
├── entities/                   # Custom entities and weapons
├── gamemode/                   # Core framework files
│   ├── cl_init.lua            # Client-side initialization
│   ├── init.lua               # Server-side initialization
│   ├── core/                  # Core framework systems
│   │   ├── definitions/       # System definitions
│   │   ├── hooks/            # Hook implementations
│   │   ├── libraries/        # Shared libraries
│   │   └── ui/               # User interface components
│   └── items/                # Default item definitions
├── modules/                   # Optional framework modules
│   ├── admin/                # Administration tools
│   ├── animations/           # Animation system
│   ├── doors/                # Door management
│   ├── logging/              # Logging system
│   ├── observer/             # Observer mode
│   ├── persistence/          # Data persistence
│   ├── stamina/              # Stamina system
│   ├── thirdperson/          # Third-person view
│   └── weaponselect/         # Weapon selection
├── LICENSE                   # MIT License
├── README.md                 # This file
├── ROADMAP.md               # Development roadmap
├── STYLE.md                 # Code style guide
├── SQLITE.md                # SQLite documentation
└── RELAY.md                 # Networking documentation
```

---

## 🛠️ Installation

### Prerequisites
- Garry's Mod (latest version)
- Basic understanding of Lua programming
- Text editor or IDE (VS Code recommended)

### Framework Installation

1. **Download the Framework**
   ```bash
   git clone https://github.com/Parallax-Framework/parallax.git
   ```

2. **Place in Gamemodes Directory**
   ```
   garrysmod/
   └── gamemodes/
       └── parallax/
   ```

3. **Choose or Create a Schema**
   - Download a pre-made schema like [`parallax-skeleton`](https://github.com/Parallax-Framework/parallax-skeleton)
   - Or create your own following the schema structure

4. **Schema Directory Structure**
   ```
   garrysmod/
   └── gamemodes/
       ├── parallax/                 # Framework core
       └── parallax-yourschema/      # Your schema
           ├── schema/               # Schema logic
           │   ├── boot.lua         # Schema configuration
           │   ├── factions/        # Faction definitions
           │   ├── items/           # Item definitions
           │   └── ui/              # Schema UI
           └── parallax-yourschema.txt
   ```

5. **Launch the Server**
   ```bash
   +gamemode parallax-yourschema
   ```

### Database Configuration

For development (SQLite - automatic):
```lua
-- No configuration needed, SQLite is used by default
```

For production (MySQL):
```lua
-- schema/database.lua
ax.database:Initialize({
    host = "localhost",
    username = "your_username",
    password = "your_password",
    database = "your_database",
    port = 3306
})
```

---

## 🧩 Core Systems

### Character Management
- Multi-character support per player
- Customizable character creation system
- Persistent character data storage
- Character switching and deletion

### Faction System
- Flexible faction definitions
- Permission-based access control
- Custom faction abilities and restrictions
- Dynamic faction switching

### Item System
- Weight-based inventory management
- Stackable items with merge logic
- Custom item types and behaviors
- Drag-and-drop inventory interface

### Animation System
- Support for multiple player models:
  - `citizen_male` / `citizen_female`
  - `metrocop` / `overwatch`
  - `player` (default)
- Custom animation sequences
- Model-specific animation handling

### Networking (`ax.relay`)
- Encrypted data transmission
- Compressed payloads for efficiency
- Three networking scopes:
  - **Global**: Server-wide data
  - **Per-Player**: Player-specific data
  - **Per-Entity**: Entity-specific data

### Database Abstraction
- SQLite for development environments
- MySQL for production servers
- Automatic schema migration
- Type-safe operations

---

## 🎨 Creating Your First Schema

### Basic Schema Structure

1. **Create Schema Directory**
   ```
   garrysmod/gamemodes/parallax-myschema/
   ```

2. **Schema Boot File** (`schema/boot.lua`)
   ```lua
   SCHEMA.Name = "My Custom Schema"
   SCHEMA.Description = "A custom roleplay schema"
   SCHEMA.Author = "Your Name"
   ```

3. **Gamemode Info** (`parallax-myschema.txt`)
   ```
   "parallax-myschema"
   {
       "base"              "parallax"
       "title"             "My Custom Schema"
       "author"            "Your Name"
       "menusystem"        "1"
   }
   ```

### Creating Items

Create items in `schema/items/` directory:

```lua
-- schema/items/sh_soda.lua
local ITEM = ax.item:Instance()

ITEM:SetName("Soda")
ITEM:SetDescription("A can of refreshing soda")
ITEM:SetModel(Model("models/food/soda.mdl"))
ITEM:SetWeight(1)

ITEM:Register()
```

### Creating Factions

Define factions in `schema/factions/`:

```lua
-- schema/factions/sh_citizen.lua
local FACTION = ax.faction:Instance()

FACTION:SetName("Citizen")
FACTION:SetDescription("Regular citizens of the city")
FACTION:SetColor(Color(100, 150, 200))

FACTION:SetDefaultModels({
    "models/player/group01/male_01.mdl",
    "models/player/group01/female_01.mdl"
})

FACTION:Register()
```

---

## 🔧 Configuration

### Server Configuration

Edit `schema/config.lua` to customize your schema, although most settings can be done through the in-game tab menu.

```lua
-- Basic server settings
ax.config:SetDefault("color.schema", Color(134, 192, 66)) -- Schema color
ax.config:SetDefault("mainmenu.music", "music/mainmenu.mp3") -- Main menu music file

-- Inventory settings
ax.config:SetDefault("inventory.max.weight", 50) -- Maximum weight for inventory

-- Character settings
ax.config:SetDefault("characters.maxCount", 5) -- Maximum characters per player
ax.config:SetDefault("characters.restorepos", false) -- Restore position on character switch

-- Other settings
ax.config:SetDefault("chat.ooc", false) -- Disable OOC chat
ax.config:SetDefault("currency.symbol", "€") -- Currency symbol
```

---

## 📚 API Documentation

### Core Libraries

#### `ax.util`
Utility functions for common operations:
```lua
-- Print messages with framework styling
ax.util:Print("Hello, world!")
ax.util:PrintError("Something went wrong!")
ax.util:PrintWarning("This is a warning")

-- Send chat messages
ax.util:SendChatText(player, "Welcome to the server!")
```

#### `ax.relay`
Secure networking system:
```lua
-- Set global data
ax.relay:SetGlobal("server_time", os.time())

-- Set entity data, this can be for players or other entities
ax.relay:SetRelay(player, "credits", 1000)

-- If you want, you can also use the player object directly, or the entity object
player:SetRelay("message", "Hello, Player!")

-- Get data from relay
print(player:GetRelay("credits", "default value")) -- Prints 1000 or "default value" if not set
```

#### `ax.sqlite` / `ax.sqloo`
Database abstraction layer:
```lua
-- Register table variables
ax.sqlite:RegisterVar("users", "credits", 0)
ax.sqlite:RegisterVar("users", "playtime", 0)

-- Initialize table
ax.sqlite:InitializeTable("users")

-- Load data
ax.sqlite:LoadRow("users", "steamid", player:SteamID(), function(data)
    print("Player has", data.credits, "credits")
end)
```

### Character System

```lua
-- Get character data
local character = player:GetCharacter()
local name = character:GetName()
local faction = character:GetFaction()

-- Set character data
character:SetName("John Doe")
character:SetDescription("A mysterious individual")
```

### Item System

```lua
-- Create item instance
local item = ax.item:Instance()
item:SetName("Custom Item")
item:SetWeight(5)
item:Register()
```

```lua
-- Give item to inventory
local character = player:GetCharacter()

local inventory = character:GetInventory()
inventory:AddItem("custom_item", 1)

-- Check if inventory has item
if ( inventory:HasItem("custom_item") ) then
    print("Player has the item!")
end
```

---

## 🚦 Available Schemas

### Official Schemas

- **[parallax-skeleton](https://github.com/Parallax-Framework/parallax-skeleton)**: Basic template for new schemas
- **[parallax-hl2rp](https://github.com/Parallax-Framework/parallax-hl2rp)**: Half-Life 2 roleplay schema

### Community Schemas

*Coming soon!*

---

## 🛡️ Security Features

### Data Protection
- Encrypted client-server communication
- Server-side validation for all actions
- Protection against common exploits
- Secure data storage and retrieval

### Secure Networking
- Built-in validation for player actions
- Automatic detection of impossible values
- Logging of suspicious activities
- CAMI integration for permissions

---

## 🔍 Debugging and Development

### Debug Mode
Enable debug mode for detailed logging:
```lua
ax.config:Set("debug.enabled", true)
ax.config:Set("debug.developer", true)
```

### Console Commands
- `ax_reload_schema`: Reload schema files
- `ax_debug_inventory`: Debug inventory issues
- `ax_validate_data`: Validate database integrity

### Logging System
The framework includes comprehensive logging:
```lua
-- Log different types of events
ax.log:Send(ax.color:Get("blue"), "This is a message using the blue color")
ax.log:Send(ax.color:Get("maroon"), "This is a message using the maroon color")
ax.log:Send(ax.color:Get("navy"), "This is a message using the navy color")
```

---

## 📊 Performance Optimization

### Best Practices
- Use hooks efficiently
- Minimize database queries
- Cache frequently accessed data
- Profile your code regularly

### Monitoring
- Built-in performance metrics
- Database query optimization
- Memory usage tracking
- Network traffic analysis

---

## 🤝 Contributing

We welcome contributions from the community! Here's how to get started:

### Development Setup

1. **Fork the Repository**
   ```bash
   git fork https://github.com/Parallax-Framework/parallax.git
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Follow Style Guide**
   - Read our [Style Guide](STYLE.md)
   - Use K&R formatting
   - Include LDoc documentation
   - Test thoroughly

4. **Submit Pull Request**
   - Clear description of changes
   - Include test cases
   - Follow commit message conventions

### Code Standards
- **Formatting**: K&R style with 4-space indentation
- **Documentation**: LDoc comments for all public functions
- **Testing**: Test in both singleplayer and multiplayer
- **Validation**: Use framework validation functions

---

## 🗺️ Roadmap

See our [ROADMAP.md](ROADMAP.md) for detailed development plans:

### Completed Features ✅
- Core character system
- Inventory management
- Basic UI framework
- Database abstraction
- Secure networking
- Module system

### In Progress 🚧
- Advanced UI components
- Death/respawn system
- Expanded admin tools
- Performance optimizations

### Planned Features 📋
- Plugin marketplace
- Web dashboard
- Mobile companion app
- Advanced analytics

---

## 📜 License

Parallax is released under the [MIT License](LICENSE).

### Credit Requirements
When using Parallax, you must:
- Keep license headers in original files
- Credit Parallax in your project documentation
- Not claim the framework as your own work
- Include attribution in visible locations

### Authors
- **Riggs** - Framework architecture and core systems
- **bloodycop6385** - Additional development, quality assurance, and community support

---

## 📞 Support & Community

### Getting Help
- **Documentation**: [GitHub Wiki](https://github.com/Parallax-Framework/parallax/wiki)
- **Discord**: [Community Server](https://discord.gg/yekEvSszW3)
- **Issues**: [GitHub Issues](https://github.com/Parallax-Framework/parallax/issues)

### Resources
- **Content Pack**: [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3479969076)
- **Examples**: Check schema repositories for implementation examples
- **Style Guide**: [STYLE.md](STYLE.md) for code formatting standards

### Community Guidelines
- Be respectful and helpful
- Search existing issues before creating new ones
- Provide detailed bug reports with reproduction steps
- Follow our code of conduct

---

## 🔗 Related Projects

- **[Parallax Modules](https://github.com/Parallax-Framework/parallax-modules)**: Community-contributed modules

---

## ⚡ Quick Start Checklist

- [ ] Download and install Parallax framework
- [ ] Choose or create a schema
- [ ] Configure database settings
- [ ] Set up basic server configuration
- [ ] Create your first faction
- [ ] Add some items to your schema
- [ ] Test character creation
- [ ] Launch your server
- [ ] Join the community Discord