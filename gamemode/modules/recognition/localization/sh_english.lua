ax.localization:Register("en", {
    ["tab.recognition"] = "Journal",

    -- Recognition Module
    --- Tiers
    ["recognition.tier.stranger"] = "Stranger",
    ["recognition.tier.seen"] = "Seen",
    ["recognition.tier.acquainted"] = "Acquainted",
    ["recognition.tier.known"] = "Known",
    ["recognition.tier.trusted"] = "Trusted",

    --- Relative time
    ["recognition.time.just_now"] = "just now",
    ["recognition.time.minutes_ago"] = "%d minutes ago",
    ["recognition.time.hours_ago"] = "%d hours ago",
    ["recognition.time.days_ago"] = "%d days ago",
    ["recognition.time.weeks_ago"] = "%d weeks ago",

    --- Client notifications
    ["recognition.notify.no_target"] = "No valid player in your line of sight.",
    ["recognition.notify.no_character"] = "Target player has no active character.",
    ["recognition.notify.alias_empty"] = "Alias cannot be empty.",
    ["recognition.notify.alias_too_long"] = "Alias must be 48 characters or fewer.",

    --- Server notifications
    ["recognition.notify.alias_invalid_length"] = "Alias must be between 1 and 48 characters.",
    ["recognition.notify.no_permission"] = "You do not have permission to set familiarity.",
    ["recognition.notify.char_not_loaded"] = "Character ID %d is not loaded.",
    ["recognition.notify.set_success"] = "Set familiarity for char %d toward %d to %d.",
    ["recognition.notify.too_far"] = "You are too far away to introduce yourself.",
    ["recognition.notify.invalid_target"] = "Invalid target.",
    ["recognition.notify.self_introduce"] = "You cannot introduce yourself to yourself.",

    --- Command feedback
    ["recognition.command.invalid_executor"] = "Invalid executor.",
    ["recognition.command.no_character"] = "You have no active character.",
    ["recognition.command.invalid_target"] = "Invalid target player.",
    ["recognition.command.target_no_character"] = "Target has no active character.",

    --- Journal UI
    ["recognition.journal.title"] = "Journal",
    ["recognition.journal.header.name"] = "Known Characters",
    ["recognition.journal.header.tier"] = "Tier",
    ["recognition.journal.header.last_seen"] = "Last Seen",
    ["recognition.journal.empty"] = "You have not met anyone yet.",
    ["recognition.journal.forget"] = "Forget",

    --- Introduced notification
    ["recognition.notify.introduced"] = "Someone introduced themselves as \"%s\".",

    --- Introduce dialog
    ["recognition.introduce.title"] = "Introduce",
    ["recognition.introduce.prompt"] = "Introduce yourself to %s as...",

    --- Admin view output
    ["recognition.admin.view.header"] = "[Recognition] Target: %s (%s)",
    ["recognition.admin.view.true_name"] = "  True name : %s",
    ["recognition.admin.view.toward_you"] = "  Toward you: score=%d  tier=%s  alias=%s",
    ["recognition.admin.alias_none"] = "(none)",
})
