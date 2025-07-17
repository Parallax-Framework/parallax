--[[
    Example usage of the enhanced Parallax Database System
    This file demonstrates how to use the new SQLite and MySQL wrappers.
]]

-- Example: Player data management
local function ExamplePlayerDataManagement()
    -- Initialize database (will use MySQL if available, otherwise SQLite)
    local config = {
        host = "localhost",
        username = "root", 
        password = "password",
        database = "gmod_server",
        port = 3306
    }
    
    ax.database:Initialize(config)
    
    -- Register default values for player data
    ax.database:RegisterVar("players", "name", "")
    ax.database:RegisterVar("players", "score", 0)
    ax.database:RegisterVar("players", "playtime", 0)
    ax.database:RegisterVar("players", "last_seen", 0)
    ax.database:RegisterVar("players", "settings", "{}")
    
    -- Create/update player table
    ax.database:InitializeTable("players", {
        steamid = "VARCHAR(32) PRIMARY KEY",
        name = "TEXT",
        score = "INT DEFAULT 0",
        playtime = "INT DEFAULT 0", 
        last_seen = "INT DEFAULT 0",
        settings = "TEXT DEFAULT '{}'"
    })
end

-- Example: Loading player data with automatic default creation
local function LoadPlayerData(player, callback)
    ax.database:LoadRow("players", "steamid", player:SteamID(), function(row)
        -- Row will be created with defaults if it doesn't exist
        
        -- Update player name if it changed
        if row.name != player:Name() then
            row.name = player:Name()
            ax.database:SaveRow("players", row, "steamid")
        end
        
        -- Parse settings JSON
        local settings = {}
        if row.settings and row.settings != "{}" then
            settings = util.JSONToTable(row.settings) or {}
        end
        
        row.settings = settings
        
        if callback then
            callback(row)
        end
    end)
end

-- Example: Saving player data
local function SavePlayerData(player, data)
    data.last_seen = os.time()
    
    -- Convert settings table to JSON
    if istable(data.settings) then
        data.settings = util.TableToJSON(data.settings)
    end
    
    ax.database:SaveRow("players", data, "steamid", function()
        print("Player data saved for", player:Name())
    end)
end

-- Example: Transaction usage for multiple operations
local function TransferScore(fromPlayer, toPlayer, amount)
    -- Load both players' data
    LoadPlayerData(fromPlayer, function(fromData)
        LoadPlayerData(toPlayer, function(toData)
            -- Check if transfer is possible
            if fromData.score < amount then
                print("Insufficient score for transfer")
                return
            end
            
            -- Use transaction for atomic transfer
            ax.database:BeginTransaction(function(success)
                if not success then
                    print("Failed to start transaction")
                    return
                end
                
                -- Update scores
                fromData.score = fromData.score - amount
                toData.score = toData.score + amount
                
                -- Save both updates
                ax.database:Update("players", {score = fromData.score}, "steamid = '" .. fromPlayer:SteamID() .. "'", function()
                    ax.database:Update("players", {score = toData.score}, "steamid = '" .. toPlayer:SteamID() .. "'", function()
                        -- Commit transaction
                        ax.database:CommitTransaction(function(committed)
                            if committed then
                                print("Score transfer completed successfully")
                            else
                                print("Failed to commit transaction")
                            end
                        end)
                    end)
                end)
            end)
        end)
    end)
end

-- Example: Bulk operations with transaction
local function ResetAllScores()
    ax.database:ExecuteTransaction({
        "UPDATE players SET score = 0",
        "INSERT INTO score_resets (timestamp) VALUES (" .. os.time() .. ")"
    }, function(success)
        if success then
            print("All scores reset successfully")
        else
            print("Failed to reset scores")
        end
    end)
end

-- Example: Leaderboard query
local function GetTopPlayers(limit, callback)
    local query = "SELECT name, score FROM players ORDER BY score DESC"
    if limit then
        query = query .. " LIMIT " .. limit
    end
    
    ax.database:Query(query, function(result)
        if callback then
            callback(result)
        end
    end, function(error)
        print("Failed to get leaderboard:", error)
        if callback then
            callback({})
        end
    end)
end

-- Example: Advanced query with conditions
local function GetActivePlayers(daysAgo, callback)
    local cutoff = os.time() - (daysAgo * 86400)
    
    ax.database:Select("players", {"steamid", "name", "score"}, "last_seen > " .. cutoff, function(result)
        print("Found", #result, "active players")
        if callback then
            callback(result)
        end
    end)
end

-- Example: Database health check
local function DatabaseHealthCheck()
    print("=== Database Health Check ===")
    
    -- Check connection
    if ax.database:IsConnected() then
        print("✓ Database is connected")
    else
        print("✗ Database is not connected")
        return
    end
    
    -- Print backend info
    ax.database:PrintBackend()
    ax.database:PrintStatus()
    
    -- Count players
    ax.database:Count("players", nil, function(count)
        print("Total players:", count)
    end)
    
    -- Check table existence
    ax.database:TableExists("players", function(exists)
        if exists then
            print("✓ Players table exists")
        else
            print("✗ Players table missing")
        end
    end)
    
    -- Test query
    ax.database:SafeQuery("SELECT COUNT(*) as count FROM players", function(result)
        print("✓ Test query successful")
    end, function(error)
        print("✗ Test query failed:", error)
    end)
end

-- Example: Graceful shutdown
local function ShutdownDatabase()
    print("Shutting down database...")
    ax.database:Shutdown()
end

-- Hook examples
hook.Add("PlayerInitialSpawn", "LoadPlayerData", function(player)
    LoadPlayerData(player, function(data)
        player.DatabaseData = data
        print("Loaded data for", player:Name())
    end)
end)

hook.Add("PlayerDisconnected", "SavePlayerData", function(player)
    if player.DatabaseData then
        SavePlayerData(player, player.DatabaseData)
    end
end)

hook.Add("DatabaseConnected", "OnDatabaseConnected", function()
    print("Database connected successfully!")
    DatabaseHealthCheck()
end)

hook.Add("DatabaseConnectionFailed", "OnDatabaseFailed", function(error)
    print("Database connection failed:", error)
end)

hook.Add("DatabaseFallback", "OnDatabaseFallback", function(reason)
    print("Database fell back to SQLite:", reason)
end)

-- Console commands for testing
concommand.Add("db_health", DatabaseHealthCheck, nil, "Check database health")
concommand.Add("db_status", function() ax.database:PrintStatus() end, nil, "Print database status")
concommand.Add("db_backend", function() ax.database:PrintBackend() end, nil, "Print database backend")

-- Example initialization
ExamplePlayerDataManagement()
