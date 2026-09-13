local mod = get_mod("myhavoc")

local mod_data = {
    name         = mod:localize("mod_name"),
    description  = mod:localize("mod_description"),
    is_togglable = true,
}

-- setting_id 与 <setting_id>_description 会自动走 mod:localize()
mod_data.options = {
    widgets = {
        {
            setting_id = "auto_send_after_mission",
            type = "checkbox",
            default_value = true,
        },
        {
            setting_id = "auto_send_only_if_changed",
            type = "checkbox",
            default_value = true,
        },
        {
            setting_id = "group_open_view_after_create",
            type = "checkbox",
            default_value = true,
        },
        {
            setting_id = "debug_mode",
            type = "checkbox",
            default_value = false,
        },
    },
}

return mod_data
