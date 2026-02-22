local MODULE = MODULE

MODULE.name = "Animation Helper"
MODULE.author = "BLOODYCOP"
MODULE.description = "Includes a little pop-up menu for you to select different animation sets to apply to your model."

if ( type(CAMI) == "table" ) then
    CAMI.RegisterPrivilege({
        Name = "Parallax - Animation Helper",
        Description = "Allows users to change their animation set.",
        MinAccess = "admin"
    })
end

function MODULE:ApplyModel(strModel, strAnimClass)
    if ( strAnimClass == "null" ) then
        ax.animations.translations[strModel] = nil
        return true
    end

    if ( !ax.animations.stored[strAnimClass] ) then
        return false
    end

    if ( !util.IsValidModel(strModel) ) then
        return false
    end

    ax.animations:SetModelClass(strModel, strAnimClass)
    return true
end

MODULE.MODELS = {}

function MODULE:InitPostEntity()
    self.MODELS = ax.data:Get("anim_helper_models", {}, { scope = "schema", human = true })

    for strModel, strAnimClass in pairs(self.MODELS) do
        if ( !util.IsValidModel(strModel) ) then
            ax.util:PrintWarning("Invalid model in anim_helper_models data, removing from file\t" .. strModel)
            self.MODELS[strModel] = nil
        else
            self:ApplyModel(strModel, strAnimClass)
        end
    end
end

if ( CLIENT ) then
    ax.net:Hook("ax.animhelper.sync", function(strModel, strAnimClass)
        MODULE:ApplyModel(strModel, strAnimClass)
    end)

    concommand.Add("ax_animhelper", function()
        if ( !CAMI.PlayerHasAccess(ax.client, "Parallax - Animation Helper", nil) ) then
            ax.client:Notify("You do not have permission to use this command.")
            return
        end

        local vDermaMenu = DermaMenu()
        
        for k, _ in pairs(ax.animations.stored) do
            vDermaMenu:AddOption(k, function()
                ax.net:Start("ax.animhelper", k)
            end)
        end

        vDermaMenu:AddOption("null", function()
            ax.net:Start("ax.animhelper", "null")
        end)

        vDermaMenu:Open()
    end)
else
    ax.net:Hook("ax.animhelper", function(client, strAnim)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Animation Helper", nil) ) then
            client:Notify("You do not have permission to use this command. cheeky one you are")
            return
        end

        local mAnims = ax.module.stored.animations

        local strModel = client:GetModel()
        if ( !util.IsValidModel(strModel) ) then
            client:Notify("Invalid model.")
            return
        end

        if ( strAnim == "null" ) then
            MODULE.MODELS[strModel] = nil
            ax.data:Set("anim_helper_models", MODULE.MODELS, { scope = "schema", human = true })

            ax.net:Start(nil, "ax.animhelper.sync", strModel, strAnim)
            ax.animations.translations[strModel] = nil

            if ( mAnims ) then
                mAnims:UpdateClientAnimations(client)
            end
            
            return
        end
        
        local bSuccess = MODULE:ApplyModel(strModel, strAnim)
        if ( !bSuccess ) then
            client:Notify("Failed to apply animation set.")
        end

        ax.net:Start(nil, "ax.animhelper.sync", strModel, strAnim)

        MODULE.MODELS[strModel] = strAnim
        ax.data:Set("anim_helper_models", MODULE.MODELS, { scope = "schema", human = true })

        
        if ( mAnims ) then
            mAnims:UpdateClientAnimations(client)
        end
    end)
end
