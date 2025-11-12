
# Database Setup Manual (Server Owners)

This manual explains how to configure Parallax to use an external MySQL database for persistent data storage. By default, Parallax uses SQLite (built into Garry's Mod) which requires no configuration and works out of the box. However, you may want to use MySQL if you need to:

* Connect your database to a website or external tools
* Share one database across multiple servers
* Have more robust backup and management capabilities
* Access your data from external applications

---

## Default behavior (SQLite)

If you don't create a `database.yml` file, Parallax will automatically use SQLite. This is the recommended option for most server owners, especially those running a single server or testing locally. SQLite stores all data in a local file and requires zero configuration.

**You only need to follow this guide if you specifically want to use MySQL.**

---

## Prerequisites

Before you begin, you'll need:

1. **A MySQL server** - Either provided by your hosting company, or self-hosted
2. **Database credentials** - Hostname, username, password, database name, and port
3. **An empty database** - Create a new database specifically for Parallax (e.g., `parallax_db`)
4. **MySQLOO library** - Binary files installed on your server (see below)

---

## Step 1: Installing MySQLOO

Parallax uses the [MySQLOO](https://github.com/FredyH/MySQLOO) library to connect to MySQL databases. You must install this library before Parallax can connect to MySQL.

### Windows servers

1. Download the latest MySQLOO release from [GitHub](https://github.com/FredyH/MySQLOO/releases)
2. Extract `gmsv_mysqloo_win32.dll` or `gmsv_mysqloo_win64.dll` (depending on your server architecture)
3. Place the file in `garrysmod/lua/bin/`
   * If the `bin` folder doesn't exist, create it

### Linux servers (most common for dedicated hosting)

1. Download the latest MySQLOO release from [GitHub](https://github.com/FredyH/MySQLOO/releases)
2. Extract `gmsv_mysqloo_linux.dll` or `gmsv_mysqloo_linux64.dll` (depending on your server architecture)
3. Place the file in `garrysmod/lua/bin/`
   * If the `bin` folder doesn't exist, create it

### Important notes

* **Older MySQLOO versions** required a separate `libmysql.dll` file in your server's root directory. Newer versions (9.0+) no longer require this.
* **32-bit vs 64-bit:** Make sure you download the correct architecture for your server. This depends on the version of Garry's Mod you are running, not your operating system.
* **Restart required:** You must restart your server after installing MySQLOO.

---

## Step 2: Creating the database

Before configuring Parallax, you need to create an empty MySQL database. This step varies depending on your hosting provider:

### Using a control panel (cPanel, Plesk, etc.)

1. Log into your hosting control panel
2. Navigate to the MySQL/Database section
3. Create a new database (e.g., `parallax_db`)
4. Create a new MySQL user (or use an existing one)
5. Grant the user **full permissions** on the database you just created
6. Note down the hostname, username, password, database name, and port

### Using command line

If you have SSH access, you can create the database manually:

```sql
CREATE DATABASE parallax_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'parallax_user'@'localhost' IDENTIFIED BY 'your_password_here';
GRANT ALL PRIVILEGES ON parallax_db.* TO 'parallax_user'@'localhost';
FLUSH PRIVILEGES;
```

### Important notes

* **Empty database required:** Parallax will automatically create all necessary tables. Do not import any SQL files or create tables manually.
* **Character set:** UTF-8 (utf8mb4) is recommended for proper character support.
* **Permissions:** The MySQL user must have full permissions (CREATE, ALTER, INSERT, UPDATE, DELETE, SELECT) on the database.

---

## Step 3: Creating the configuration file

Now you need to tell Parallax to use MySQL instead of SQLite. This requires creating a `database.yml` file in your **schema's root directory** (not the framework directory).

### File location

Place `database.yml` in your schema's gamemode folder:

```
garrysmod/
  gamemodes/
    your_schema/
      database.yml  <-- CREATE THIS FILE HERE
      gamemode/
        init.lua
        cl_init.lua
        schema/
          ...
```

**Example:** If your schema is called `hl2rp`, the file should be at:
```
garrysmod/gamemodes/hl2rp/database.yml
```

### Configuration format

Create a new file called `database.yml` with the following structure:

```yaml
database:
  adapter: "mysqloo"
  hostname: "your.database.host"
  username: "your_username"
  password: "your_password"
  database: "your_database_name"
  port: 3306
```

### Field explanations

* **adapter:** Must be `"mysqloo"` to enable MySQL (use quotes)
* **hostname:** Your database server address
  * Can be a domain name (e.g., `db.example.com`)
  * Can be an IP address (e.g., `123.45.67.89`)
  * For local databases, use `localhost` or `127.0.0.1`
* **username:** Your MySQL username
* **password:** Your MySQL password
* **database:** The name of the database you created in Step 2
* **port:** MySQL port number (default is `3306` unless your host specifies otherwise)

### Example configuration

Here's a realistic example (with fake credentials):

```yaml
database:
  adapter: "mysqloo"
  hostname: "db.glnodes.com"
  username: "u47_ABC123xyz"
  password: "MySecureP@ssw0rd!2025"
  database: "s47_parallax"
  port: 50000
```

### Important formatting rules

⚠️ **YAML is very picky about formatting!**

* **Indentation:** Use exactly **2 spaces** for indentation (not tabs!)
* **No extra spaces:** Don't add spaces before `database:`
* **Consistent spacing:** All fields under `database:` must have exactly 2 spaces before them
* **Quotes:** Always use quotes around string values (especially passwords with special characters)
* **Colons:** Must have a space after the colon (e.g., `adapter: "mysqloo"`, not `adapter:"mysqloo"`)

**Incorrect (will fail):**
```yaml
database:
    adapter: "mysqloo"  <-- 4 spaces (wrong!)
  hostname: db.example.com  <-- missing quotes
username: "test"  <-- no indentation
```

**Correct:**
```yaml
database:
  adapter: "mysqloo"
  hostname: "db.example.com"
  username: "test"
  password: "password"
  database: "parallax_db"
  port: 3306
```

---

## Step 4: Starting your server

After creating the `database.yml` file:

1. **Save the file** and ensure it's in the correct location
2. **Restart your server** completely (don't use `changelevel` or hot-reload)
3. **Check the console** for connection messages:
   * ✅ Success: `[PARALLAX] [SUCCESS] Connected to MySQL database.`
   * ❌ Failure: `[PARALLAX] [ERROR] Failed to connect to MySQL database.`

### First startup

On the first startup with MySQL, Parallax will:

1. Connect to the database
2. Create all necessary tables (`ax_players`, `ax_characters`, `ax_inventories`, `ax_items`, `ax_schema`)
3. Set up the dynamic schema system
4. Run the `OnDatabaseTablesCreated` hook

This process should complete within a few seconds. Once complete, your server is ready to accept players!

---

## Troubleshooting

### Connection failed / timeout errors

**Problem:** Console shows connection timeout or "can't connect to MySQL server"

**Solutions:**
* Verify your hostname and port are correct
* Check if your MySQL server allows remote connections
* Ensure your server's IP is whitelisted in your MySQL host's firewall
* For local databases, try `127.0.0.1` instead of `localhost`

### Unknown column errors

**Problem:** Console shows "Unknown column 'name' in 'INSERT INTO'" or similar

**Solutions:**
* This indicates a timing issue with schema updates
* Make sure you're using the latest version of Parallax
* Try running `ax_database_destroy` (CAUTION: deletes all data!) then restart
* Check that MySQLOO is properly installed

### Authentication errors

**Problem:** "Access denied for user" errors

**Solutions:**
* Double-check your username and password in `database.yml`
* Ensure the MySQL user has permissions on the specified database
* If using special characters in your password, ensure they're properly quoted
* Verify the user is allowed to connect from your server's IP

### Module not found / MySQLOO not loaded

**Problem:** "Module not found (mysqloo)" error

**Solutions:**
* Verify `gmsv_mysqloo_*.dll` is in `garrysmod/lua/bin/`
* Ensure you downloaded the correct architecture (32-bit vs 64-bit)
* Make sure the file has proper permissions (especially on Linux)
* Restart your server completely after installing

### YAML parsing errors

**Problem:** Configuration file fails to load or values are wrong

**Solutions:**
* Check indentation - must be exactly 2 spaces, no tabs
* Ensure all string values are in quotes
* Verify there's a space after each colon
* Use a [YAML validator](https://www.yamllint.com/) to check syntax
* Make sure the file is named exactly `database.yml` (not `.txt`)

---

## Advanced topics

### Switching from SQLite to MySQL

If you've been running your server with SQLite and want to switch to MySQL:

1. **Backup your SQLite data** (located in `garrysmod/data/`)
2. Create the `database.yml` file
3. Restart your server
4. Parallax will create fresh tables in MySQL
5. **Note:** You'll need to manually migrate data - there is no automatic migration tool yet.

### Using multiple servers with one database

You can safely run multiple Parallax servers connected to the same MySQL database. Players will be able to switch between servers while keeping their characters and inventories.

**Requirements:**
* All servers must be running the same schema
* All servers must have the same factions, classes, and items
* Character/inventory IDs are globally unique

### Database backups

It's highly recommended to set up automatic backups of your MySQL database:

* Use your hosting provider's backup tools
* Set up `mysqldump` cron jobs
* Store backups in a secure, off-server location
* Test restoration procedures regularly

---

## Console commands

Parallax provides several console commands for database management:

* `ax_database_create` - Manually create tables (requires superadmin)
* `ax_database_wipe` - Delete all data from tables (requires superadmin)
* `ax_database_destroy` - Drop all tables completely (requires superadmin)

⚠️ **Warning:** The wipe and destroy commands are destructive and cannot be undone! Always backup first.

---

## Need help?

If you're still having issues:

1. Check the server console for detailed error messages
2. Enable developer mode: `developer 1` in console
3. Look for `[PARALLAX] [DEBUG]` messages
4. Join the Parallax community Discord for support
5. Include your full error message and console logs when asking for help

---

## Summary

1. ✅ Install MySQLOO binary files in `garrysmod/lua/bin/`
2. ✅ Create an empty MySQL database
3. ✅ Create `database.yml` in your schema's root directory
4. ✅ Use proper YAML formatting (2 spaces, quotes, etc.)
5. ✅ Restart your server and check for connection success
6. ✅ Monitor the first startup to ensure tables are created

Once configured, Parallax will automatically handle all database operations, including creating tables, updating schemas, and storing player/character data.
