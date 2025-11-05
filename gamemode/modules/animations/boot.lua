local MODULE = MODULE

MODULE.name = "Animations"
MODULE.description = "Handles player animations."
MODULE.author = "Riggs"

ax.config:Add("animations.ik.enabled", ax.type.bool, true, {
    category = "animations",
    subCategory = "general",
    description = "animations.ik.enabled.help"
})

local LANG = {}
LANG["animations.ik.enabled"] = "Enable Inverse Kinematics (IK) for player animations."
LANG["animations.ik.enabled.help"] = "When enabled, the player's feet will adjust to uneven terrain for more realistic movement."
LANG["category.animations"] = "Animations"
ax.localization:Register("en", LANG)
