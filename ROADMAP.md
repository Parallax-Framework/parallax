# Parallax Framework Technical Roadmap

This roadmap outlines the development priorities and technical implementation details for the Parallax framework. It is organized by subsystem and uses completion checkboxes to track progress.

## Core Framework

### Store & Configuration System

- [x] **Store factory pattern** - `ax.util:CreateStore()` with `ax.config` and `ax.option` implementations
- [x] **JSON persistence** - `ax.util:WriteJSON` and `ax.util:ReadJSON` for store serialization
- [x] **Networked configuration sync** - Server-to-client config broadcasting via `ax.config.init` and `ax.config.set`
- [x] **Per-player option caching** - Client-to-server option syncing with `SERVER_CACHE` storage
- [ ] **Store validation hooks** - Pre/post-set callbacks for complex validation logic
- [ ] **Configuration migration system** - Version-aware config upgrades and backwards compatibility
- [ ] **Store performance optimization** - Lazy loading and batch network operations

### Module System

- [x] **Auto-loading structure** - `ax.util:IncludeDirectory` for `libraries/`, `meta/`, `core/`, `hooks/`, `networking/`, `interface/`
- [x] **Module boot pattern** - `MODULE` table with `Initialize()` callbacks in `boot.lua`
- [x] **Nested directory inclusion** - Recursive loading with exclusion filters
- [ ] **Module dependency resolution** - Dependency tree validation and load ordering
- [ ] **Hot-reloading system** - Runtime module replacement without server restart
- [ ] **Module API versioning** - Compatibility checking between framework and modules
- [ ] **Module security isolation** - Sandbox environment for untrusted modules

### Utilities & Helpers

- [x] **Realm detection** - `ax.util:DetectFileRealm` with `cl_`, `sv_`, `sh_` prefixes
- [x] **Safe function calls** - `ax.util:SafeCall` with error handling and debug output
- [x] **Debug logging** - `ax.util:PrintDebug` with `developer` ConVar gating
- [ ] **Performance profiling** - Built-in timing and memory usage tracking for subsystems
- [ ] **Assertion framework** - Development-time validation with detailed error reporting
- [ ] **Benchmark utilities** - Automated performance testing for critical code paths

## Database & Persistence

### MySQL Integration

- [x] **Schema management** - Dynamic table creation and column addition via `ax.database:AddToSchema`
- [x] **Connection handling** - `ax.database:Initialize` with reconnection logic
- [x] **Core tables** - `ax_players`, `ax_characters`, `ax_inventories`, `ax_items`, `ax_schema`
- [ ] **Connection pooling** - Multiple database connections for improved throughput
- [ ] **Query optimization** - Prepared statements and query batching
- [ ] **Migration system** - Versioned database schema upgrades
- [ ] **Backup integration** - Automated backup scheduling and restoration utilities

### Data Persistence

- [x] **Item persistence** - Database storage for inventory items with JSON data serialization
- [x] **Character data storage** - Player character information with extensible schema
- [ ] **World state persistence** - Entity positions, door states, and environmental data
- [ ] **Transaction support** - ACID compliance for critical operations like transfers
- [ ] **Data archiving** - Long-term storage and cleanup of inactive player data
- [ ] **Audit logging** - Track all database modifications for debugging and security

## Networking & Synchronization

### Network Message System

- [x] **Auto-registration** - `util.AddNetworkString` calls in store `_setupNetworking`
- [x] **Type-safe serialization** - `net.WriteType` and `net.ReadType` for dynamic data
- [x] **Broadcast targeting** - Selective recipient lists for inventory and config updates
- [ ] **Message compression** - Automatic compression for large data payloads
- [ ] **Rate limiting** - Per-client throttling to prevent network flooding
- [ ] **Message acknowledgment** - Reliable delivery confirmation for critical updates
- [ ] **Network diagnostics** - Real-time monitoring of message frequency and size

### Synchronization Patterns

- [x] **Config synchronization** - Server-authoritative configuration with client caching
- [x] **Option synchronization** - Client preference storage with server validation
- [x] **Inventory synchronization** - Real-time inventory updates via `ax.inventory.sync`
- [ ] **Delta synchronization** - Only send changed data to reduce bandwidth usage
- [ ] **Conflict resolution** - Handle simultaneous modifications gracefully
- [ ] **Offline synchronization** - Queue changes when clients temporarily disconnect
- [ ] **Synchronization priorities** - Critical vs. cosmetic update ordering

## Inventory System

### Core Inventory Mechanics

- [x] **Weight-based system** - `maxWeight` limits with `ax.inventory:GetWeight()` calculations
- [x] **Item metadata** - JSON-serialized `data` field for per-item customization
- [x] **Database integration** - Persistent storage via `ax_inventories` and `ax_items` tables
- [ ] **Item stacking logic** - Configurable stacking rules with `maxStack` and `shouldStack` properties
- [ ] **Encumbrance states** - Movement penalties based on weight ratios and equipment
- [ ] **Container nesting** - Items that contain other inventories (bags, boxes, etc.)
- [ ] **Inventory templates** - Predefined layouts for different character classes or factions

### Advanced Inventory Features

- [ ] **Transfer validation** - Server-side verification of item movements and trades
- [ ] **Inventory locking** - Prevent modifications during transactions or combat
- [ ] **Capacity optimization** - Weight-based storage management
- [ ] **Search and filtering** - Real-time inventory content search with category filters
- [ ] **Bulk operations** - Multi-item selection for mass transfers and actions
- [ ] **Inventory snapshots** - Save/restore inventory states for testing and debugging

## Items & Actions

### Item Framework

- [x] **Instance pattern** - `ax.item:Instance()` for item definition templates
- [x] **Registration system** - `ITEM:Register()` with automatic storage in `ax.item.stored`
- [x] **Action system** - `ITEM:AddAction()` with conditional `CanUse` functions
- [x] **Weight and categories** - `ITEM:SetWeight()` and `ITEM:SetCategory()` properties
- [ ] **Item inheritance** - Base item classes with property and method inheritance
- [ ] **Dynamic item generation** - Runtime item creation with procedural properties
- [ ] **Item lifecycle hooks** - `OnCreated`, `OnDestroyed`, `OnTransfer` callbacks
- [ ] **Item rarity system** - Configurable rarity tiers with visual and mechanical effects

### Item Interactions

- [x] **Use actions** - `OnUse` callbacks with player context and item removal control
- [x] **Drop handling** - `OnDrop` callbacks for state cleanup and validation
- [ ] **Combine system** - Item fusion recipes with result validation
- [ ] **Degradation mechanics** - Item wear and repair system with condition tracking
- [ ] **Attachment system** - Item modifications and upgrade paths
- [ ] **Context menus** - Dynamic right-click actions based on item state and player context

## User Interface

### Core UI Components

- [x] **Transition system** - `ax.transition` with slide animations and easing functions
- [x] **Button framework** - `ax.button.core`, `ax.button`, `ax.button.flat` with hover states
- [x] **Frame management** - `ax.frame` with dragging, resizing, and focus handling
- [x] **Scrollable lists** - `ax.scroller.vertical` and `ax.scroller.horizontal` with momentum scrolling
- [ ] **Modal dialogs** - Standardized confirmation, input, and progress dialogs
- [ ] **Notification system** - Toast messages with queuing and animation
- [ ] **Tooltip framework** - Context-sensitive help text with delay and positioning
- [ ] **Theme system** - Configurable color schemes and visual styles

### Advanced UI Features

- [x] **Animation framework** - Motion tweening with easing curves via `:Motion()`
- [ ] **Virtual scrolling** - Efficient rendering of large lists with viewport culling
- [ ] **Accessibility support** - Screen reader compatibility and keyboard navigation
- [ ] **UI state management** - Persistent panel positions and user preferences
- [ ] **Component library** - Reusable UI building blocks with consistent styling
- [ ] **Drag and drop** - VGUI drag system with drop target validation

### Inventory UI

- [x] **Basic inventory panel** - `ax.inventory` VGUI component with item display
- [ ] **Weight-based layout** - Visual item placement with weight-aware positioning
- [ ] **Drag-and-drop transfers** - Intuitive item movement between inventories
- [ ] **Item tooltips** - Detailed item information on hover with stat comparisons
- [ ] **Quick actions** - Context menus with use, drop, and combine options
- [ ] **Search functionality** - Real-time filtering with fuzzy matching
- [ ] **Sorting options** - Multiple sort criteria with user preferences
- [ ] **Container visualization** - Nested inventory display for bags and containers

## Animation & Effects

### Character Animation

- [ ] **Animation state machine** - Gesture and sequence management with blending
- [ ] **Item use animations** - Context-appropriate animations for different item types
- [ ] **Carry poses** - Weight-based posture changes and movement modifications
- [ ] **Interaction gestures** - Contextual animations for world object interactions
- [ ] **Combat animations** - Weapon-specific attack, reload, and holster sequences
- [ ] **Emote system** - Player-triggered animations with chat integration

### Visual Effects

- [ ] **Particle integration** - Item pickup, use, and drop effects
- [ ] **Screen effects** - Fullscreen overlays for status conditions (hunger, damage)
- [ ] **3D item display** - Rotating item models in UI with proper lighting
- [ ] **Inventory icons** - Automatic icon generation from item models
- [ ] **Status indicators** - Visual feedback for encumbrance, health, and needs
- [ ] **Transition effects** - Smooth UI state changes with visual continuity

## Framework Internals

### Performance Optimization

- [ ] **Entity pooling** - Reusable entity instances to reduce allocation overhead
- [ ] **Network optimization** - Message batching and compression for inventory updates
- [ ] **Memory management** - Garbage collection hints and reference counting
- [ ] **Cache optimization** - LRU caches for frequently accessed data (items, configs)
- [ ] **Database query optimization** - Query batching and prepared statement caching
- [ ] **Render optimization** - UI panel pooling and draw call reduction

### Error Handling & Debugging

- [x] **Safe execution** - `ax.util:SafeCall` wrapper with error reporting
- [x] **Debug output** - Conditional logging based on `developer` ConVar
- [ ] **Stack trace capture** - Detailed error reporting with call history
- [ ] **Performance metrics** - Real-time monitoring of framework subsystem performance
- [ ] **Memory leak detection** - Automatic detection of unreleased references
- [ ] **Network debugging** - Packet inspection and bandwidth usage analysis

### Security & Validation

- [ ] **Input sanitization** - All user inputs validated and escaped
- [ ] **Permission system** - Role-based access control for administrative functions
- [ ] **Anti-exploitation** - Rate limiting and validation for all network messages
- [ ] **Audit logging** - Security-relevant events logged for investigation
- [ ] **Code signing** - Integrity verification for critical framework files
- [ ] **SQL injection prevention** - Parameterized queries and input validation

## Testing & Quality Assurance

### Unit Testing

- [ ] **Store testing** - Automated tests for configuration and option systems
- [ ] **Inventory testing** - Weight calculations, transfers, and persistence validation
- [ ] **Network testing** - Message serialization and synchronization verification
- [ ] **Database testing** - Schema migration and data integrity validation
- [ ] **UI testing** - Automated interaction testing for critical workflows
- [ ] **Performance testing** - Benchmarks for inventory operations and network sync

### Integration Testing

- [ ] **Multi-client testing** - Simultaneous player interactions and race conditions
- [ ] **Load testing** - High player count scenarios with inventory synchronization
- [ ] **Database failover testing** - Graceful handling of connection failures
- [ ] **Module compatibility testing** - Validation of third-party module integration
- [ ] **Schema migration testing** - Database upgrade paths and rollback procedures
- [ ] **Memory leak testing** - Long-running server stability validation

### Quality Assurance

- [ ] **Code review process** - Structured peer review with security focus
- [ ] **Documentation standards** - LDoc-style documentation for all public APIs
- [ ] **Style guide enforcement** - Automated linting with `.glualint.json` rules
- [ ] **Performance profiling** - Regular performance analysis and optimization
- [ ] **Security auditing** - Regular security reviews and penetration testing
- [ ] **User acceptance testing** - Community feedback integration and iteration

## Long-Term Goals

### Framework Evolution

- [ ] **Modular architecture** - Plugin system for extending core functionality
- [ ] **Cross-gamemode compatibility** - Framework usage beyond roleplay contexts
- [ ] **Advanced networking** - Custom networking layer with improved reliability
- [ ] **Real-time collaboration** - Multi-server synchronization for persistent worlds
- [ ] **Cloud integration** - Remote storage and backup solutions
- [ ] **API ecosystem** - RESTful APIs for external tool integration

### Developer Experience

- [ ] **Visual editors** - GUI tools for creating items, factions, and configurations
- [ ] **Development console** - In-game debugging and testing utilities
- [ ] **Live reload** - Hot-swapping of code and assets during development
- [ ] **Documentation portal** - Comprehensive guides and API references
- [ ] **Community marketplace** - Sharing platform for modules and schemas
- [ ] **Analytics integration** - Usage metrics and performance monitoring

### Performance & Scalability

- [ ] **Horizontal scaling** - Multi-server inventory synchronization
- [ ] **Caching layers** - Redis integration for high-performance data access
- [ ] **CDN integration** - Asset delivery optimization for content-heavy servers
- [ ] **Database sharding** - Distribute data across multiple database instances
- [ ] **Load balancing** - Dynamic server selection based on player count and performance
- [ ] **Edge computing** - Regional servers for reduced latency

---

_Last updated: August 2025_
