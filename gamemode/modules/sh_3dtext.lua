local MODULE = MODULE

MODULE.name = "3D Text"
MODULE.author = "Chessnut & KarmaLN"
MODULE.description = "Adds text that can be placed on the map."

MODULE.list = MODULE.list or {}

function MODULE:InitPostEntity()
    self.list = ax.data:Get("3dtext", {}, {
        scope = "map"
    })

    -- Formats table to sequential to support legacy panels.
    self.list = table.ClearKeys(self.list)
end

if ( SERVER ) then
    function MODULE:PlayerReady(client)
        local json = util.TableToJSON(self.list)
        local compressed = util.Compress(json)

        ax.net:Start(client, "text.list", {
            data = compressed
        })
    end

    function MODULE:AddText(position, angles, text, scale)
        local index = #self.list + 1
        scale = math.Clamp((scale or 1) * 0.1, 0.001, 5)

        self.list[index] = {position, angles, text, scale}

        ax.net:Start(nil, "text.add", {
            index = index,
            position = position,
            angles = angles,
            text = text,
            scale = scale
        })

        self:SaveText()
        return index
    end

    function MODULE:RemoveText(position, radius)
        radius = radius or 100

        local textDeleted = {}

        for k, v in ipairs(self.list) do
            if ( v[1]:Distance(position) <= radius ) then
                textDeleted[#textDeleted + 1] = k
            end
        end

        if ( #textDeleted > 0 ) then
            -- Invert index table to delete from highest -> lowest
            textDeleted = table.Reverse(textDeleted)

            for _, v in ipairs(textDeleted) do
                table.remove(self.list, v)
                ax.net:Start(nil, "text.remove", {
                    index = v
                })
            end

            self:SaveText()
        end

        return #textDeleted
    end

    function MODULE:RemoveTextByID(id)
        local info = self.list[id]

        if ( !info ) then return false end

        ax.net:Start(nil, "text.remove", {
            index = id
        })

        table.remove(self.list, id)
        self:SaveText()

        return true
    end

    function MODULE:SaveText()
        ax.data:Set("3dtext", self.list, {
            scope = "map"
        })
    end
else
    function MODULE:LoadFonts(font)
        surface.CreateFont("ax3D2DFont", {
            font = font,
            size = 128,
            extended = true,
            weight = 100
        })
    end

    function MODULE:GenerateMarkup(text)
        local object = ax.markup.Parse("<font=ax3D2DFont>" .. text:gsub("\\n", "\n"))

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

    ax.net:Hook("text.add", function(payload)
        if ( payload.text != "" ) then
            MODULE.list[payload.index] = {
                payload.position,
                payload.angles,
                MODULE:GenerateMarkup(payload.text),
                payload.scale
            }
        end
    end)

    ax.net:Hook("text.remove", function(payload)
        table.remove(MODULE.list, payload.index)
    end)

    ax.net:Hook("text.list", function(payload)
        local uncompressed = util.Decompress(payload.data)
        if ( !uncompressed ) then
            ax.util:printError("Unable to decompress text data!\n")
            return
        end

        MODULE.list = util.JSONToTable(uncompressed)

        for _, v in ipairs(MODULE.list) do
            v[3] = MODULE:GenerateMarkup(v[3])
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
        if ( ctx and ctx.commandData ) then
            return string.lower(ctx.commandData.name or "")
        end
    end

    local function GetChatArguments()
        local ctx = ax.chat and ax.chat.context
        if ( !ctx or !ctx.commandArgs ) then return {} end

        local parts = string.Explode(" ", ctx.commandArgs)

        local scale = tonumber(parts[#parts])
        if ( scale ) then
            table.remove(parts, #parts)
        end

        local text = string.Trim(table.concat(parts, " "))

        if ( text == "" ) then return {} end

        return {text, scale}
    end

    local RENDER_DIST_SQ = 1048576  -- 1024 units
    local FADE_START_SQ  = 65536    -- 256 units
    local FADE_RANGE     = 768432

    function MODULE:PostDrawTranslucentRenderables(bDrawingDepth, bDrawingSkybox)
        if ( bDrawingDepth or bDrawingSkybox ) then return end

        local command = GetChatCommand()

        -- preview: /textadd
        if ( ax.util:FindString(command, "textadd") ) then
            local args = GetChatArguments()

            local text = tostring(args[1] or "")
            local scale = math.Clamp((tonumber(args[2]) or 1) * 0.1, 0.001, 5)

            local trace = ax.client:GetEyeTraceNoCursor()
            local position = trace.HitPos
            local angles = trace.HitNormal:Angle()

            angles:RotateAroundAxis(angles:Up(), 90)
            angles:RotateAroundAxis(angles:Forward(), 90)

            local markup
            local ok, result = pcall(self.GenerateMarkup, self, text)
            if ( ok ) then
                markup = result
            end

            if ( markup ) then
                cam.Start3D2D(position, angles, scale)
                    markup:draw(0, 0, 1, 1, 255)
                cam.End3D2D()
            end
        end

        local position = ax.client:GetPos()
        for _, text in ipairs(self.list) do
            local distance = text[1]:DistToSqr(position)
            if ( distance > RENDER_DIST_SQ ) then continue end

            cam.Start3D2D(text[1], text[2], text[4] or 0.1)
                local alpha = math.Clamp((1 - ((distance - FADE_START_SQ) / FADE_RANGE)) * 255, 0, 255)
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
        local trace = client:GetEyeTrace()

        if ( !trace.Hit ) then return "You must be looking at a surface." end

        scale = scale or 1
        local position = trace.HitPos
        local angles = trace.HitNormal:Angle()
        angles:RotateAroundAxis(angles:Up(), 90)
        angles:RotateAroundAxis(angles:Forward(), 90)

        local index = MODULE:AddText(position + angles:Up() * 0.1, angles, text, scale)

        -- TODO: Add a client option to disable undo support for this module, as this can be annoying.
        undo.Create("ax.text.3d")
            undo.SetPlayer(client)
            undo.AddFunction(function()
                if ( MODULE:RemoveTextByID(index) ) then
                    ax.util:Print(client:GetName() .. " undid 3D text placement #" .. index .. ".", Color(0, 255, 0))
                end
            end)
        undo.Finish()

        return "Text added (ID: " .. index .. ")."
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

        if ( amount == 0 ) then return "No text found within " .. radius .. " units." end

        return "Removed " .. amount .. " text panel" .. (amount == 1 and "" or "s") .. "."
    end
})
