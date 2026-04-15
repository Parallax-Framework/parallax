--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Thin wrapper around the `reqwest` binary module by William Venner.
-- The wrapper is only created if the appropriate binary module is installed:
-- `lua/bin/gmsv_reqwest_*.dll` on the server, `lua/bin/gmcl_reqwest_*.dll` on the client.
-- If the module is missing the wrapper is not registered and `ax.reqwest` will be nil.
-- @module ax.reqwest
-- @see https://github.com/WilliamVenner/gmsv_reqwest

local function GetModuleSuffix()
    if ( system.IsWindows() ) then
        return jit.arch == "x86-64" and "win64" or "win32"
    elseif ( system.IsLinux() ) then
        return jit.arch == "x86-64" and "linux64" or "linux"
    elseif ( system.IsOSX() ) then
        return "osx64"
    end

    return "win32"
end

local function IsReqwestInstalled()
    local prefix = SERVER and "gmsv_reqwest_" or "gmcl_reqwest_"
    local path = "lua/bin/" .. prefix .. GetModuleSuffix() .. ".dll"
    return file.Exists(path, "GAME")
end

if ( !IsReqwestInstalled() ) then
    return
end

local bLoaded, loadErr = pcall(require, "reqwest")
if ( !bLoaded or !isfunction(reqwest) ) then
    ax.util:PrintWarning("[ax.reqwest] Failed to load reqwest binary module: " .. tostring(loadErr) .. "\n")
    return
end

ax.reqwest = ax.reqwest or {}

--- Dispatches a raw request table to the underlying `reqwest` function.
-- The table accepts every field supported by Garry's Mod's `HTTP()` plus the extras
-- introduced by reqwest (`timeout`, `type`, client certificates, etc.).
-- @realm shared
-- @param data table Request table.
-- @return boolean True if the request was queued successfully.
function ax.reqwest:Request(data)
    if ( !istable(data) ) then
        ax.util:PrintError("[ax.reqwest] Request data must be a table")
        return false
    end

    if ( !isstring(data.url) or data.url == "" ) then
        ax.util:PrintError("[ax.reqwest] Request is missing a url")
        return false
    end

    data.method = data.method or "GET"

    return reqwest(data)
end

--- Performs a GET request.
-- @realm shared
-- @string url Target URL.
-- @func[opt] onSuccess Callback receiving (code, body, headers).
-- @func[opt] onFailure Callback receiving (error).
-- @tab[opt] headers Extra headers.
-- @return boolean
function ax.reqwest:Get(url, onSuccess, onFailure, headers)
    return self:Request({
        method = "GET",
        url = url,
        headers = headers,
        success = onSuccess,
        failed = onFailure,
    })
end

--- Performs a POST request with urlencoded parameters.
-- @realm shared
-- @string url Target URL.
-- @tab[opt] parameters Key/value table sent as form parameters.
-- @func[opt] onSuccess Callback receiving (code, body, headers).
-- @func[opt] onFailure Callback receiving (error).
-- @tab[opt] headers Extra headers.
-- @return boolean
function ax.reqwest:Post(url, parameters, onSuccess, onFailure, headers)
    return self:Request({
        method = "POST",
        url = url,
        parameters = parameters,
        headers = headers,
        success = onSuccess,
        failed = onFailure,
    })
end

--- Performs a request with a raw body (typically JSON).
-- @realm shared
-- @string method HTTP method (POST, PUT, PATCH, DELETE, ...).
-- @string url Target URL.
-- @string body Raw request body.
-- @string[opt="application/json"] contentType Value for the Content-Type header.
-- @func[opt] onSuccess Callback receiving (code, body, headers).
-- @func[opt] onFailure Callback receiving (error).
-- @tab[opt] headers Extra headers.
-- @return boolean
function ax.reqwest:Send(method, url, body, contentType, onSuccess, onFailure, headers)
    return self:Request({
        method = method,
        url = url,
        body = body,
        type = contentType or "application/json",
        headers = headers,
        success = onSuccess,
        failed = onFailure,
    })
end

--- Convenience helper for posting JSON-encoded payloads.
-- @realm shared
-- @string url Target URL.
-- @param payload Any value that `util.TableToJSON` can encode, or a pre-encoded string.
-- @func[opt] onSuccess Callback receiving (code, decodedBody, headers).
-- @func[opt] onFailure Callback receiving (error).
-- @tab[opt] headers Extra headers.
-- @return boolean
function ax.reqwest:PostJSON(url, payload, onSuccess, onFailure, headers)
    local body = isstring(payload) and payload or util.TableToJSON(payload or {})

    return self:Send("POST", url, body, "application/json", function(code, responseBody, responseHeaders)
        if ( !isfunction(onSuccess) ) then return end

        local decoded = isstring(responseBody) and util.JSONToTable(responseBody) or nil
        onSuccess(code, decoded or responseBody, responseHeaders)
    end, onFailure, headers)
end
