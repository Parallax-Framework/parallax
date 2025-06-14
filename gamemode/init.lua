DeriveGamemode("sandbox")

ax = ax or {util = {}, meta = {}, config = {}}

AddCSLuaFile("cl_init.lua")

AddCSLuaFile("core/types.lua")
include("core/types.lua")

AddCSLuaFile("core/util.lua")
include("core/util.lua")

include("core/sqlite.lua")
include("core/sqloo.lua")
include("core/database.lua")

AddCSLuaFile("core/boot.lua")
include("core/boot.lua")

for k, v in ipairs(engine.GetAddons()) do
    if ( v.downloaded and v.mounted ) then
        resource.AddWorkshop(v.wsid)
    end
end

resource.AddWorkshop("3479969076")

resource.AddFile("resource/fonts/gordin-black.ttf")
resource.AddFile("resource/fonts/gordin-bold.ttf")
resource.AddFile("resource/fonts/gordin-light.ttf")
resource.AddFile("resource/fonts/gordin-regular.ttf")
resource.AddFile("resource/fonts/gordin-semibold.ttf")