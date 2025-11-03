local MODULE = MODULE

MODULE.Name = "Animations"
MODULE.Description = "Handles player animations."
MODULE.Author = "Riggs"

ax.config:Add("animationsIKEnabled", ax.type.bool, true, {
    category = "animations",
    subCategory = "general",
    description = "Enable Inverse Kinematics (IK) for player animations."
})

local LANG = {}
LANG["animationsIKEnabled"] = "Включване на обратна кинематика (IK) за анимации на играча."
ax.localization:Register("bg", LANG)
