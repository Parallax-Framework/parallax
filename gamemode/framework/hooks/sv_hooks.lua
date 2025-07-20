--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

gameevent.Listen("OnRequestFullUpdate")
hook.Add("OnRequestFullUpdate", "ax.OnRequestFullUpdate", function(data)
    if ( !istable(data) or !isnumber(data.userid) ) then return end

    local client = Player(data.userid)
    if ( !IsValid(client) ) then return end

    local clientTable = client:GetTable()
    if ( clientTable.axReady ) then return end

    clientTable.axReady = true

    timer.Simple(0, function()
        if ( !IsValid(client) ) then return end

        hook.Run("PlayerReady", client)
    end)
end)

function GM:PlayerReady(client)

end