--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Network strings for admin system
util.AddNetworkString("ax.admin.logs.request")
util.AddNetworkString("ax.admin.logs.response")
util.AddNetworkString("ax.admin.group.update")
util.AddNetworkString("ax.admin.ban.update")

local MODULE = MODULE

-- Handle admin logs request
net.Receive("ax.admin.logs.request", function(len, client)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - View Logs", nil) ) then
        return
    end

    local count = net.ReadUInt(8)
    local filter = net.ReadTable()

    local logs = MODULE:GetLogs(filter)
    local startIndex = math.max(1, #logs - count + 1)
    local sendLogs = {}

    for i = startIndex, #logs do
        table.insert(sendLogs, logs[i])
    end

    net.Start("ax.admin.logs.response")
        net.WriteTable(sendLogs)
    net.Send(client)
end)