--[[
    Parallax Framework
    Copyright (c) 2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.config:Add("container.save", ax.type.bool, true, {
	description = "config.container.save.help",
	category = "gameplay",
	subCategory = "containers",
})

ax.config:Add("container.default.open_time", ax.type.number, 0.7, {
	description = "config.container.default.open_time.help",
	min = 0,
	max = 50,
	decimals = 1,
	category = "gameplay",
	subCategory = "containers",
})

ax.config:Add("container.default.max_weight", ax.type.number, 16, {
	description = "config.container.default.max_weight.help",
	min = 1,
	max = 500,
	decimals = 1,
	category = "gameplay",
	subCategory = "containers",
})

ax.config:Add("container.password.attempt_limit", ax.type.number, 10, {
	description = "config.container.password.attempt_limit.help",
	min = 1,
	max = 100,
	decimals = 0,
	category = "gameplay",
	subCategory = "containers",
})

ax.config:Add("container.password.retry_delay", ax.type.number, 1, {
	description = "config.container.password.retry_delay.help",
	min = 0,
	max = 10,
	decimals = 1,
	category = "gameplay",
	subCategory = "containers",
})
