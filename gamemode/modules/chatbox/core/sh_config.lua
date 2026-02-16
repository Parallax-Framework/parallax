--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.config:Add("chatbox.max_message_length", ax.type.number, 512, {
    description = "Maximum number of characters accepted for a single chat message.",
    category = "chat",
    subCategory = "basic",
    min = 16,
    max = 4096,
    decimals = 0
})

ax.config:Add("chatbox.history_size", ax.type.number, 128, {
    description = "Maximum number of local chat input history entries stored clientside.",
    category = "chat",
    subCategory = "basic",
    min = 8,
    max = 512,
    decimals = 0
})

ax.config:Add("chatbox.chat_type_history", ax.type.number, 16, {
    description = "Maximum number of chat type transitions kept in history.",
    category = "chat",
    subCategory = "basic",
    min = 4,
    max = 64,
    decimals = 0
})

ax.config:Add("chatbox.looc_prefix", ax.type.string, ".//", {
    description = "Shortcut prefix for local OOC chat.",
    category = "chat",
    subCategory = "basic"
})

ax.config:Add("chatbox.recommendations.debounce", ax.type.number, 0.15, {
    description = "Debounce delay (seconds) before recalculating command/voice recommendations.",
    category = "chat",
    subCategory = "basic",
    min = 0,
    max = 1,
    decimals = 2
})

ax.config:Add("chatbox.recommendations.animation_duration", ax.type.number, 0.2, {
    description = "Duration (seconds) for recommendation list fade animations.",
    category = "chat",
    subCategory = "basic",
    min = 0,
    max = 1,
    decimals = 2
})

ax.config:Add("chatbox.recommendations.command_limit", ax.type.number, 20, {
    description = "Maximum number of command recommendations displayed.",
    category = "chat",
    subCategory = "basic",
    min = 1,
    max = 64,
    decimals = 0
})

ax.config:Add("chatbox.recommendations.voice_limit", ax.type.number, 20, {
    description = "Maximum number of voice recommendations displayed.",
    category = "chat",
    subCategory = "basic",
    min = 1,
    max = 64,
    decimals = 0
})

ax.config:Add("chatbox.recommendations.wrap_cycle", ax.type.bool, true, {
    description = "Whether tab cycling should wrap from the last recommendation back to the first.",
    category = "chat",
    subCategory = "basic"
})
