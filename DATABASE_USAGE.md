# Enhanced Database System Usage Guide

## Overview

The Parallax Framework database system has been completely rewritten to provide robust SQLite and MySQL wrappers with enhanced features, better error handling, and improved connection management.

## Features

### Enhanced SQLite Wrapper (`ax.sqlite`)
- **Transaction Support**: Begin, commit, and rollback transactions
- **Better Error Handling**: Comprehensive error messages and validation
- **Table Management**: Check if tables/columns exist, get table information
- **Data Type Conversion**: Automatic JSON conversion for complex data types
- **Improved Query Safety**: Parameter validation and SQL injection prevention

### Enhanced MySQL Wrapper (`ax.sqloo`)
- **Connection Management**: Automatic reconnection with retry logic
- **Keepalive System**: Prevents connection timeouts with periodic pings
- **Query Queuing**: Queues queries when disconnected and processes them when reconnected
- **Transaction Support**: Full ACID transaction support
- **Async Operations**: All operations are asynchronous with proper callback handling
- **Connection Pooling**: Improved connection lifecycle management

### Unified Database Interface (`ax.database`)
- **Automatic Fallback**: Falls back to SQLite if MySQL is unavailable
- **Feature Parity**: Both backends support the same API
- **Enhanced Proxying**: Additional methods proxied to backends
- **Status Monitoring**: Real-time connection status monitoring

## Basic Usage

### Initialization

```lua
-- Initialize with MySQL (will fallback to SQLite if MySQL fails)
ax.database:Initialize({
    host = "localhost",
    username = "root",
    password = "password",
    database = "gmod_server",
    port = 3306
})

-- Initialize with SQLite only
ax.database:Initialize()
```

### Basic Operations

```lua
-- Insert a record
ax.database:Insert("players", {
    steamid = "STEAM_0:0:123456",
    name = "John Doe",
    score = 100
})

-- Select records
ax.database:Select("players", {"name", "score"}, "score > 50", function(result)
    for i, row in ipairs(result) do
        print(row.name, row.score)
    end
end)

-- Update records
ax.database:Update("players", {score = 150}, "steamid = 'STEAM_0:0:123456'")

-- Delete records
ax.database:Delete("players", "last_played < " .. (os.time() - 86400))

-- Count records
ax.database:Count("players", "score > 100", function(count)
    print("Players with score > 100:", count)
end)
```

### Advanced Features

#### Transactions
```lua
-- Execute multiple queries in a transaction
local queries = {
    "INSERT INTO players (steamid, name) VALUES ('STEAM_0:0:123456', 'John')",
    "UPDATE players SET score = score + 10 WHERE steamid = 'STEAM_0:0:123456'",
    "INSERT INTO player_logs (steamid, action) VALUES ('STEAM_0:0:123456', 'score_update')"
}

ax.database:ExecuteTransaction(queries, function(success)
    if success then
        print("Transaction completed successfully")
    else
        print("Transaction failed and was rolled back")
    end
end)
```

#### Manual Transaction Control
```lua
ax.database:BeginTransaction()

ax.database:Insert("players", playerData, function()
    ax.database:Update("stats", statsData, "player_id = " .. playerId, function()
        ax.database:CommitTransaction()
        print("Transaction committed")
    end)
end)
```

#### Table Management
```lua
-- Check if table exists
ax.database:TableExists("players", function(exists)
    if not exists then
        -- Create table
        ax.database:InitializeTable("players", {
            steamid = "VARCHAR(32) PRIMARY KEY",
            name = "TEXT",
            score = "INT DEFAULT 0"
        })
    end
end)

-- Check if column exists
ax.database:ColumnExists("players", "email", function(exists)
    if not exists then
        -- Add column
        ax.database:AddColumn("players", "email", "TEXT", "")
    end
end)
```

#### Default Row Handling
```lua
-- Register default values
ax.database:RegisterVar("players", "name", "")
ax.database:RegisterVar("players", "score", 0)
ax.database:RegisterVar("players", "last_played", 0)

-- Load or create player record
ax.database:LoadRow("players", "steamid", player:SteamID(), function(row)
    print("Player name:", row.name)
    print("Player score:", row.score)
    
    -- Modify and save
    row.name = player:Name()
    row.last_played = os.time()
    
    ax.database:SaveRow("players", row, "steamid")
end)
```

### Error Handling

```lua
ax.database:SafeQuery("SELECT * FROM players", function(result)
    -- Success callback
    print("Query successful, got", #result, "results")
end, function(error)
    -- Error callback
    print("Query failed:", error)
end)
```

### Connection Management

```lua
-- Check connection status
if ax.database:IsConnected() then
    print("Database is connected")
end

-- Print detailed status
ax.database:PrintStatus()

-- Get backend information
ax.database:PrintBackend()

-- Manual reconnection (MySQL only)
if ax.database:GetBackend() == ax.sqloo then
    ax.database:GetBackend():Reconnect()
end
```

## Best Practices

1. **Always use callbacks** for asynchronous operations (especially with MySQL)
2. **Validate input parameters** before database operations
3. **Use transactions** for multiple related operations
4. **Handle connection failures** gracefully with error callbacks
5. **Use the unified interface** (`ax.database`) rather than direct backend calls
6. **Register default values** for all table columns
7. **Use proper data types** in table schemas

## Migration from Old System

The new system is backward compatible, but consider these improvements:

- Replace direct `ax.sqlite` or `ax.sqloo` calls with `ax.database` calls
- Add error handling callbacks to all operations
- Use the new transaction methods for multi-query operations
- Take advantage of the new table management methods
- Update table schemas to use proper data types

## Troubleshooting

### Common Issues

1. **MySQL connection fails**: Check MySQLOO installation and configuration
2. **Queries not executing**: Ensure database is connected before operations
3. **Data not persisting**: Check transaction commit/rollback logic
4. **Performance issues**: Use transactions for bulk operations

### Debug Tools

```lua
-- Print current backend and status
ax.database:PrintBackend()
ax.database:PrintStatus()

-- Check connection
print("Connected:", ax.database:IsConnected())

-- Get backend object for direct debugging
local backend = ax.database:GetBackend()
```
