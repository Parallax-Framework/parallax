local MODULE = MODULE

function MODULE:PostDatabaseTablesLoaded()
    ax.database:RegisterVar("ax_players", "usergroup", "user")
    ax.database:InitializeTable("ax_admin_groups", {
        name = "VARCHAR(64) PRIMARY KEY",
        inherits = "TEXT",
        privilege = "INTEGER"
    })
end

local DEFAULT_GROUPS = {
    { name = "superadmin", privilege = 100 },
    { name = "admin", privilege = 50 },
    { name = "user", privilege = 0 }
}

local DEFAULT_PERMISSIONS = {
    { name = "Parallax - Manage Users", access = "admin" },
    { name = "Parallax - Manage Groups", access = "superadmin" }
}

local savedGroups
local savedPerms

--- Saves groups and permissions using the data system.
function MODULE:SaveData()
    --ax.data:Set("admin_groups", self.Groups)
    --ax.data:Set("admin_permissions", self.Permissions)
end

--- Loads groups and permissions, or registers defaults if none exist.
function MODULE:LoadData()
    local result = ax.database:Select("ax_admin_groups")
    if ( result ) then
        for _, row in ipairs(result) do
            local group = {
                Name = row.name,
                Inherits = row.inherits,
                Privilege = row.privilege
            }

            savedGroups[row.name] = group
        end
    end

    result = ax.database:Select("ax_admin_permissions")
    if ( result ) then
        for _, row in ipairs(result) do
            local permission = {
                Name = row.name,
                MinAccess = row.minAccess,
                HasAccess = row.hasAccess
            }

            savedPerms[row.name] = permission
        end
    end

    if ( !savedGroups or !savedPerms ) then
        for _, group in ipairs(DEFAULT_GROUPS) do
            self:RegisterGroup(group.name, group.privilege)
        end

        for _, perm in ipairs(DEFAULT_PERMISSIONS) do
            self:RegisterPermission(perm.name, perm.access)
        end

        self:SaveData()
    else
        for name, group in pairs(savedGroups) do
            self:RegisterGroup(name, group.Privilege)
        end

        for name, perm in pairs(savedPerms) do
            self:RegisterPermission(name, perm.MinAccess)
        end
    end
end

function MODULE:SetUserGroup(client, groupName)
    if ( !self.Groups[groupName] ) then return end

    local oldGroup = client:GetUserGroup()

    client:SetUserGroup(groupName)
    CAMI.SignalUserGroupChanged(client, oldGroup, groupName, "Parallax")
end

function MODULE:GetUserGroup(client)
    return client:GetUserGroup()
end

function MODULE:HasPermission(client, permission, callback)
    return CAMI.PlayerHasAccess(client, permission, callback)
end

--- Adds a group via code or future UI.
function MODULE:AddGroup(name, privilege)
    if ( self.Groups[name] ) then return false end

    self:RegisterGroup(name, privilege)

    return true
end

--- Removes a group and saves.
function MODULE:RemoveGroup(name)
    if ( !self.Groups[name] ) then return false end

    self.Groups[name] = nil
    self:SaveData()

    return true
end

--- Adds a permission manually.
function MODULE:AddPermission(name, access)
    if ( self.Permissions[name] ) then return false end

    self:RegisterPermission(name, access)

    return true
end

--- Removes a permission.
function MODULE:RemovePermission(name)
    if ( !self.Permissions[name] ) then return false end

    self.Permissions[name] = nil
    self:SaveData()

    return true
end