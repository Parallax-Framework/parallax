--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Utility helpers used across the Parallax framework (printing, file handling, text utilities, etc.).
-- @module ax.util

--- Versioning utilities.
-- @section version_utilities

--- Get the Parallax version string (e.g. "0.3.42").
-- Prefers `ax.version` if available, else attempts to read `version.json`.
-- @return string|nil Version string or nil when unavailable
function ax.util:GetVersion()
    if ( istable(ax.version) and ax.version.data and ax.version.data.version ) then
        return tostring(ax.version.data.version)
    end

    local data = ax.version:ReadVersionFile()
    if ( istable(data) and data.version ) then
        return tostring(data.version)
    end

    return "0.0.0"
end

--- Get the Parallax commit count (number).
-- @return number|nil Commit count or nil when unavailable
function ax.util:GetCommitCount()
    if ( istable(ax.version) and ax.version.commitCount ) then
        return tonumber(ax.version.commitCount) or nil
    end

    local data = ax.version:ReadVersionFile()
    if ( istable(data) and data.commitCount ) then
        return tonumber(data.commitCount) or nil
    end

    return 0
end

--- Get the Parallax commit hash (short).
-- @return string|nil Commit hash or nil when unavailable
function ax.util:GetCommitHash()
    if ( istable(ax.version) and ax.version.data and ax.version.data.commitHash ) then
        return tostring(ax.version.data.commitHash)
    end

    local data = ax.version:ReadVersionFile()
    if ( istable(data) and data.commitHash ) then
        return tostring(data.commitHash)
    end

    return ""
end

--- Get the Parallax branch name.
-- @return string|nil Branch name or nil when unavailable
function ax.util:GetBranch()
    if ( istable(ax.version) and ax.version.data and ax.version.data.branch ) then
        return tostring(ax.version.data.branch)
    end

    local data = ax.version:ReadVersionFile()
    if ( istable(data) and data.branch ) then
        return tostring(data.branch)
    end

    return "unknown"
end
