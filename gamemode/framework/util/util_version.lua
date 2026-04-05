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

--- Returns the Parallax framework version string (e.g. `"0.3.42"`).
-- Performs a two-tier lookup:
-- 1. If `ax.version` is a table and `ax.version.data.version` is set (the live in-memory version populated at framework startup), that value is returned immediately.
-- 2. Otherwise, `ax.version:ReadVersionFile()` is called to read `version.json` from disk and extract the `version` field.
-- Falls back to `"0.0.0"` when neither source yields a value, so this function always returns a string — never nil.
-- @realm shared
-- @return string The version string, or `"0.0.0"` as a safe fallback.
-- @usage local v = ax.util:GetVersion()  -- e.g. "0.3.42"
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

--- Returns the total commit count for this Parallax build.
-- Performs the same two-tier lookup as `GetVersion`: live `ax.version` data first, then `ReadVersionFile()` as a fallback. The value is coerced to a number via `tonumber`. Falls back to `0` when unavailable, so this function always returns a number. The commit count is useful for comparing build recency without parsing the version string.
-- @realm shared
-- @return number The commit count, or `0` as a safe fallback.
-- @usage local count = ax.util:GetCommitCount()  -- e.g. 142
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

--- Returns the short Git commit hash for this Parallax build.
-- Performs the same two-tier lookup as `GetVersion`: live `ax.version` data first, then `ReadVersionFile()` as a fallback. Falls back to an empty string `""` when unavailable, so this function always returns a string.
-- The hash is useful for identifying the exact source revision when reporting bugs or comparing server builds.
-- @realm shared
-- @return string The short commit hash (e.g. `"a3f2c1d"`), or `""` if version data is not available.
-- @usage local hash = ax.util:GetCommitHash()  -- e.g. "a3f2c1d"
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

--- Returns the Git branch name this Parallax build was made from.
-- Performs the same two-tier lookup as `GetVersion`: live `ax.version` data first, then `ReadVersionFile()` as a fallback. Falls back to `"unknown"` when unavailable, so this function always returns a string. Useful for distinguishing between `"main"`, `"staging"`, or feature branches when diagnosing issues across different server deployments.
-- @realm shared
-- @return string The branch name (e.g. `"main"`, `"staging"`), or `"unknown"` if version data is not available.
-- @usage local branch = ax.util:GetBranch()  -- e.g. "main"
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
