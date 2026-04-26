local MODULE = MODULE

MODULE.name = "3D Text"
MODULE.author = "Chessnut & KarmaLN"
MODULE.description = "Adds text that can be placed on the map."

-- List of available text panels
MODULE.list = MODULE.list or {}

function MODULE:InitPostEntity()
	self.list = ax.data:Get("3dtext", {})

	-- Formats table to sequential to support legacy panels.
	self.list = table.ClearKeys(self.list)
end

if (SERVER) then
	util.AddNetworkString("ixTextList")
	util.AddNetworkString("ixTextAdd")
	util.AddNetworkString("ixTextRemove")

	function MODULE:PlayerInitialSpawn(client)
		timer.Simple(1, function()
			if (IsValid(client)) then
				local json = util.TableToJSON(self.list)
				local compressed = util.Compress(json)
				local length = compressed:len()

				net.Start("ixTextList")
					net.WriteUInt(length, 32)
					net.WriteData(compressed, length)
				net.Send(client)
			end
		end)
	end

	-- Adds a text to the list, sends it to the players, and saves data.
	function MODULE:AddText(position, angles, text, scale)
		local index = #self.list + 1
		scale = math.Clamp((scale or 1) * 0.1, 0.001, 5)

		self.list[index] = {position, angles, text, scale}

		net.Start("ixTextAdd")
			net.WriteUInt(index, 32)
			net.WriteVector(position)
			net.WriteAngle(angles)
			net.WriteString(text)
			net.WriteFloat(scale)
		net.Broadcast()

		self:SaveText()
		return index
	end

	-- Removes a text that are within the radius of a position.
	function MODULE:RemoveText(position, radius)
		radius = radius or 100

		local textDeleted = {}

		for k, v in ipairs(self.list) do
			if (v[1]:Distance(position) <= radius) then
				textDeleted[#textDeleted + 1] = k
			end
		end

		if (#textDeleted > 0) then
			-- Invert index table to delete from highest -> lowest
			textDeleted = table.Reverse(textDeleted)

			for _, v in ipairs(textDeleted) do
				table.remove(self.list, v)

				net.Start("ixTextRemove")
					net.WriteUInt(v, 32)
				net.Broadcast()
			end

			self:SaveText()
		end

		return #textDeleted
	end

	function MODULE:RemoveTextByID(id)
		local info = self.list[id]

		if (!info) then
			return false
		end

		net.Start("ixTextRemove")
			net.WriteUInt(id, 32)
		net.Broadcast()

		table.remove(self.list, id)
		return true
	end

	-- Called when the plugin needs to save information.
	function MODULE:SaveText()
        ax.data:Set("3dtext", self.list)
	end
else
    function MODULE:LoadFonts(font, genericFont)
        surface.CreateFont("ax3D2DFont", {
            font = font,
            size = 128,
            extended = true,
            weight = 100
        })
    end

	function MODULE:GenerateMarkup(text)
		local object = ax.markup.Parse("<font=ax3D2DFont>"..text:gsub("\\n", "\n"))

		object.onDrawText = function(surfaceText, font, x, y, color, alignX, alignY, alpha)
			-- shadow
			surface.SetTextPos(x + 1, y + 1)
			surface.SetTextColor(0, 0, 0, alpha)
			surface.SetFont(font)
			surface.DrawText(surfaceText)

			surface.SetTextPos(x, y)
			surface.SetTextColor(color.r or 255, color.g or 255, color.b or 255, alpha)
			surface.SetFont(font)
			surface.DrawText(surfaceText)
		end

		return object
	end

	-- Receives new text objects that need to be drawn.
	net.Receive("ixTextAdd", function()
		local index = net.ReadUInt(32)
		local position = net.ReadVector()
		local angles = net.ReadAngle()
		local text = net.ReadString()
		local scale = net.ReadFloat()

		if (text != "") then
			MODULE.list[index] = {
				position,
				angles,
				MODULE:GenerateMarkup(text),
				scale
			}
		end
	end)

	net.Receive("ixTextRemove", function()
		local index = net.ReadUInt(32)

		table.remove(MODULE.list, index)
	end)

	-- Receives a full update on ALL texts.
	net.Receive("ixTextList", function()
		local length = net.ReadUInt(32)
		local data = net.ReadData(length)
		local uncompressed = util.Decompress(data)

		if (!uncompressed) then
			ErrorNoHalt("[Parallax] Unable to decompress text data!\n")
			return
		end

		MODULE.list = util.JSONToTable(uncompressed)

		-- Will be saved, but refresh just to make sure.
		for k, v in ipairs(MODULE.list) do
			local object = ax.markup.Parse("<font=ax3D2DFont>"..v[3]:gsub("\\n", "\n"))

			object.onDrawText = function(text, font, x, y, color, alignX, alignY, alpha)
				draw.TextShadow({
					pos = {x, y},
					color = ColorAlpha(color, alpha),
					text = text,
					xalign = 0,
					yalign = alignY,
					font = font
				}, 1, alpha)
			end

			v[3] = object
		end
	end)

	function MODULE:StartChat()
		self.preview = nil
	end

	function MODULE:FinishChat()
		self.preview = nil
	end

    local function GetChatCommand()
        local ctx = ax.chat and ax.chat.context
        if (ctx and ctx.commandData) then
            return string.lower(ctx.commandData.name or "")
        end
    end
    
    local function GetChatArguments()
        local ctx = ax.chat and ax.chat.context
        if (not ctx or not ctx.commandArgs) then return {} end

        local parts = string.Explode(" ", ctx.commandArgs)

        local scale = tonumber(parts[#parts])
        if (scale) then
            table.remove(parts, #parts)
        end

        local text = string.Trim(table.concat(parts, " "))

        if (text == "") then return {} end

        return {text, scale}
    end

	function MODULE:PostDrawTranslucentRenderables(bDrawingDepth, bDrawingSkybox)
        if (bDrawingDepth or bDrawingSkybox) then return end

        local command = GetChatCommand()

        -- =========================
        -- PREVIEW: /textadd
        -- =========================
        if (command == "textadd") then
            local args = GetChatArguments()

            local text = tostring(args[1] or "")
            local scale = math.Clamp((tonumber(args[2]) or 1) * 0.1, 0.001, 5)

            local trace = LocalPlayer():GetEyeTraceNoCursor()
            local position = trace.HitPos
            local angles = trace.HitNormal:Angle()

            angles:RotateAroundAxis(angles:Up(), 90)
            angles:RotateAroundAxis(angles:Forward(), 90)

            local markup
            pcall(function()
                markup = self:GenerateMarkup(text)
            end)

            if (markup) then
                cam.Start3D2D(position, angles, scale)
                    markup:draw(0, 0, 1, 1, 255)
                cam.End3D2D()
            end
        end

        -- =========================
        -- NORMAL RENDER
        -- =========================
        local position = LocalPlayer():GetPos()

        for _, text in ipairs(self.list) do
            local distance = text[1]:DistToSqr(position)

            if (distance > 1048576) then continue end

            cam.Start3D2D(text[1], text[2], text[4] or 0.1)
                local alpha = (1 - ((distance - 65536) / 768432)) * 255
                text[3]:draw(0, 0, 1, 1, alpha)
            cam.End3D2D()
        end
    end
end

ax.command:Add("TextAdd", {
	description = "@cmdTextAdd",
	adminOnly = true,
    arguments = {
        { name = "text", type = ax.type.string },
        { name = "scale", type = ax.type.number, optional = true }
    },
	OnRun = function(self, client, text, scale)
        local scale = scale or 1
		local trace = client:GetEyeTrace()
		local position = trace.HitPos
		local angles = trace.HitNormal:Angle()
		angles:RotateAroundAxis(angles:Up(), 90)
		angles:RotateAroundAxis(angles:Forward(), 90)

		local index = MODULE:AddText(position + angles:Up() * 0.1, angles, text, scale)

		undo.Create("ix3dText")
			undo.SetPlayer(client)
			undo.AddFunction(function()
				if (MODULE:RemoveTextByID(index)) then
					ax.util:Print(client:GetName() .. " has removed their last 3D text.", Color(0, 255, 0))
				end
			end)
		undo.Finish()

		return "Text Added"
	end
})

ax.command:Add("TextRemove", {
	description = "@cmdTextRemove",
	adminOnly = true,    
    arguments = {
        { name = "radius", type = ax.type.number }
    },
	OnRun = function(self, client, radius)
		local trace = client:GetEyeTrace()
		local position = trace.HitPos + trace.HitNormal * 2
		local amount = MODULE:RemoveText(position, radius)

		return "Text Removed!", amount
	end
})
