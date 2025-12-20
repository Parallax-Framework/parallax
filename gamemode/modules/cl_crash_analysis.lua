--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.name = "Crash Analysis"
MODULE.description = "Analyzes server responsiveness to detect crashes."
MODULE.author = "Riggs"

-- Constants for timing and limits
local CRASH_ANALYSIS_INTERVAL = 0.05
local CRASH_THINK_INTERVAL = 0.66
local MAX_CRASH_ATTEMPTS = 15

-- Helper function to update server frame time snapshot
local function updateServerFrameSnapshot()
    local a, b = engine.ServerFrameTime()
    lastServerData1 = a
    lastServerData2 = b
end

-- Helper function for crash analysis
local function analyzeServerCrash()
    nextCrashAnalysis = CurTime() + CRASH_ANALYSIS_INTERVAL

    local a, b = engine.ServerFrameTime()
    if ( crashAnalysisAttempts <= MAX_CRASH_ATTEMPTS ) then
        if ( a != lastServerData1 or b != lastServerData2 ) then
            nextCrashAnalysis = nil
            crashAnalysisAttempts = 0
            return
        end

        crashAnalysisAttempts = crashAnalysisAttempts + 1

        if ( crashAnalysisAttempts == MAX_CRASH_ATTEMPTS ) then
            nextCrashAnalysis = nil
            crashAnalysisAttempts = 0
            AX_SERVER_DOWN = true

            hook.Run("OnServerCrashDetected")
        end
    else
        nextCrashAnalysis = nil
        crashAnalysisAttempts = 0
    end

    updateServerFrameSnapshot()
end

-- Helper function for crash think
local function processCrashThink()
    nextCrashThink = CurTime() + CRASH_THINK_INTERVAL

    local a, b = engine.ServerFrameTime()
    if ( a == lastServerData1 and b == lastServerData2 ) then
        nextCrashAnalysis = CurTime()
    else
        AX_SERVER_DOWN = false
        nextCrashAnalysis = nil
    end

    updateServerFrameSnapshot()
end

-- Main Think hook logic
function MODULE:Think()
    if ( !AX_SERVER_DOWN and nextCrashAnalysis and nextCrashAnalysis < CurTime() ) then
        analyzeServerCrash()
    end

    if ( nextCrashThink < CurTime() ) then
        processCrashThink()
    end
end

function MODULE:OnServerCrashDetected()
    Derma_Message(
        "The server appears to be unresponsive. This may indicate a crash or freeze.\n\n" ..
        "You can attempt to reconnect or wait for the server to recover.",
        "Server Unresponsive",
        "Reconnect", function()
            RunConsoleCommand("retry")
        end,
        "Wait", function()
            -- Do nothing, just wait
        end
    )
end
