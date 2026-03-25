--[[
	Parallax Framework
	Copyright (c) 2026 Parallax Framework Contributors

	This file is part of the Parallax Framework and is licensed under the MIT License.
	You may use, copy, modify, merge, publish, distribute, and sublicense this file
	under the terms of the LICENSE file included with this project.

	Attribution is required. If you use or modify this file, you must retain this notice.
]]

local function PlayContainerSequence(entity, sequenceName)
	if ( !IsValid(entity) ) then
		return false
	end

	local sequence = entity:LookupSequence(sequenceName)
	if ( !isnumber(sequence) or sequence < 0 ) then
		return false
	end

	entity:ResetSequence(sequence)
	entity:SetCycle(0)

	return true
end

ax.container:Register("models/props_junk/wood_crate001a.mdl", {
	name = "Crate",
	description = "A wooden crate suited for general item storage.",
	inventory = {
		maxWeight = 16,
	},
	color = Color(185, 146, 101),
})

ax.container:Register("models/props_c17/lockers001a.mdl", {
	name = "Locker",
	description = "A tall locker with enough room for personal belongings.",
	inventory = {
		maxWeight = 15,
	},
	color = Color(132, 156, 188),
})

ax.container:Register("models/props_wasteland/controlroom_storagecloset001a.mdl", {
	name = "Metal Cabinet",
	description = "A sturdy metal cabinet with multiple shelves.",
	inventory = {
		maxWeight = 20,
	},
	color = Color(165, 170, 178),
})

ax.container:Register("models/props_wasteland/controlroom_storagecloset001b.mdl", {
	name = "Metal Cabinet",
	description = "A sturdy metal cabinet with multiple shelves.",
	inventory = {
		maxWeight = 20,
	},
	color = Color(165, 170, 178),
})

ax.container:Register("models/props_wasteland/controlroom_filecabinet001a.mdl", {
	name = "File Cabinet",
	description = "A wide filing cabinet for documents and small tools.",
	inventory = {
		maxWeight = 15,
	},
	color = Color(168, 168, 168),
})

ax.container:Register("models/props_wasteland/controlroom_filecabinet002a.mdl", {
	name = "File Cabinet",
	description = "A tall filing cabinet with several drawers.",
	inventory = {
		maxWeight = 18,
	},
	color = Color(168, 168, 168),
})

ax.container:Register("models/props_lab/filecabinet02.mdl", {
	name = "File Cabinet",
	description = "A laboratory file cabinet for organized storage.",
	inventory = {
		maxWeight = 15,
	},
	color = Color(176, 176, 176),
})

ax.container:Register("models/props_c17/furniturefridge001a.mdl", {
	name = "Refrigerator",
	description = "A compact refrigerator for chilled storage.",
	inventory = {
		maxWeight = 6,
	},
	color = Color(179, 208, 220),
})

ax.container:Register("models/props_wasteland/kitchen_fridge001a.mdl", {
	name = "Large Refrigerator",
	description = "A large refrigerator with plenty of cold storage space.",
	inventory = {
		maxWeight = 20,
	},
	color = Color(179, 208, 220),
})

ax.container:Register("models/props_junk/trashbin01a.mdl", {
	name = "Trash Bin",
	description = "A small bin for disposable odds and ends.",
	inventory = {
		maxWeight = 4,
	},
	color = Color(119, 146, 111),
})

ax.container:Register("models/props_junk/trashdumpster01a.mdl", {
	name = "Dumpster",
	description = "A large dumpster capable of holding bulky junk.",
	inventory = {
		maxWeight = 18,
	},
	color = Color(103, 132, 98),
})

ax.container:Register("models/items/ammocrate_smg1.mdl", {
	name = "Ammo Crate",
	description = "A military ammo crate with a hinged lid.",
	inventory = {
		maxWeight = 15,
	},
	color = Color(168, 138, 92),
	OnOpen = function(entity)
		PlayContainerSequence(entity, "Close")

		timer.Simple(2, function()
			if ( !IsValid(entity) ) then return end

			if ( !PlayContainerSequence(entity, "Open") ) then
				PlayContainerSequence(entity, "OpenIdle")
			end
		end)
	end,
})

ax.container:Register("models/props_forest/footlocker01_closed.mdl", {
	name = "Footlocker",
	description = "A compact footlocker for personal effects.",
	inventory = {
		maxWeight = 15,
	},
	color = Color(138, 134, 112),
})

ax.container:Register("models/items/item_item_crate.mdl", {
	name = "Item Crate",
	description = "A reinforced crate designed for assorted equipment.",
	inventory = {
		maxWeight = 15,
	},
	color = Color(184, 147, 99),
})

ax.container:Register("models/props_c17/cashregister01a.mdl", {
	name = "Cash Register",
	description = "A cash register with limited internal storage.",
	inventory = {
		maxWeight = 2,
	},
	color = Color(106, 183, 114),
})
