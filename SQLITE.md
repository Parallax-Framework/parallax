# Parallax.SQLite

`Parallax.SQLite` is a utility library for managing structured SQLite tables in Garry's Mod. It allows dynamic variable registration, automatic schema creation, and safe row load/save operations.

---

## 📌 Quick Start

### Register Variables

```lua
Parallax.SQLite:RegisterVar("users", "credits", 0)
Parallax.SQLite:RegisterVar("users", "rank", "citizen")
```

---

### Initialize Table

```lua
Parallax.SQLite:InitializeTable("users")
```

---

### Load a Row

```lua
Parallax.SQLite:LoadRow("users", "steamid", "STEAM_0:1:12345", function(row)
    print("Credits:", row.credits)
end)
```

---

### Save a Row

```lua
Parallax.SQLite:SaveRow("users", {
    steamid = "STEAM_0:1:12345",
    credits = 200,
    rank = "vip"
}, "steamid")
```

---

### Create a Table Manually

```lua
Parallax.SQLite:CreateTable("bans", {
    steamid = "TEXT PRIMARY KEY",
    reason = "TEXT",
    time = "INTEGER"
})
```

---

## 🧱 API Overview

- `RegisterVar(tableName, key, default)`
- `InitializeTable(tableName, extraSchema)`
- `GetDefaultRow(tableName, override)`
- `LoadRow(tableName, key, value, callback)`
- `SaveRow(tableName, data, key)`
- `Insert(tableName, data, callback)`
- `Update(tableName, data, condition)`
- `Delete(tableName, condition)`
- `Select(tableName, columns, condition)`
- `Count(tableName, condition)`

---

## Notes

- Automatically adds missing columns with correct type.
- Works well with `users`, `characters`, `inventories`, etc.
- Use `Parallax.Util:PrintWarning` and `PrintTable` for debug info.
