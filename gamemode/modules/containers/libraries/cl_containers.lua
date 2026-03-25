--[[
	Parallax Framework
	Copyright (c) 2026 Parallax Framework Contributors

	This file is part of the Parallax Framework and is licensed under the MIT License.
	You may use, copy, modify, merge, publish, distribute, and sublicense this file
	under the terms of the LICENSE file included with this project.

	Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

local function BuildInventorySignature(inventory)
	if ( !istable(inventory) ) then
		return ""
	end

	local keys = {}
	for itemID in pairs(inventory:GetItems() or {}) do
		keys[#keys + 1] = itemID
	end

	table.sort(keys)

	return table.concat(keys, ",")
end

properties.Add("container_setpassword", {
	MenuLabel = ax.localization:GetPhrase("container.property.set_password"),
	Order = 2000,
	MenuIcon = "icon16/lock_edit.png",

	Filter = function(self, entity, client)
		client = client or LocalPlayer()
		return hook.Run("CanProperty", client, "container_setpassword", entity) == true
	end,

	Action = function(self, entity)
		Derma_StringRequest(ax.localization:GetPhrase("container.property.set_password"), ax.localization:GetPhrase("container.property.set_password.prompt"), "", function(text)
			self:MsgStart()
				net.WriteEntity(entity)
				net.WriteString(string.Trim(text or ""))
			self:MsgEnd()
		end)
	end,
})

properties.Add("container_setname", {
	MenuLabel = ax.localization:GetPhrase("container.property.set_name"),
	Order = 2001,
	MenuIcon = "icon16/tag_blue_edit.png",

	Filter = function(self, entity, client)
		client = client or LocalPlayer()
		return hook.Run("CanProperty", client, "container_setname", entity) == true
	end,

	Action = function(self, entity)
		Derma_StringRequest(ax.localization:GetPhrase("container.property.set_name"), ax.localization:GetPhrase("container.property.set_name.prompt"), entity:GetDisplayName() or "", function(text)
			self:MsgStart()
				net.WriteEntity(entity)
				net.WriteString(string.Trim(text or ""))
			self:MsgEnd()
		end)
	end,
})
