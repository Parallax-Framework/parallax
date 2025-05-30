if ( !tobool(CAMI) ) then
    ax.util:PrintError("CAMI is not installed.")
    return
end

CAMI.RegisterPrivilege({
    Name = "Parallax - Toolgun",
    MinAccess = "admin"
})

CAMI.RegisterPrivilege({
    Name = "Parallax - Physgun",
    MinAccess = "admin"
})

CAMI.RegisterPrivilege({
    Name = "Parallax - Physgun Players",
    MinAccess = "admin"
})

CAMI.RegisterPrivilege({
    Name = "Parallax - Manage Flags",
    MinAccess = "admin"
})

CAMI.RegisterPrivilege({
    Name = "Parallax - Manage Config",
    MinAccess = "superadmin",
})