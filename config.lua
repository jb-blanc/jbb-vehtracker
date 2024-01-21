Config = Config or {}
Config.UseTarget = GetConvar('UseTarget', 'false') == 'true' -- Use qb-target interactions (don't change this, go to your server.cfg and add `setr UseTarget true` to use this and just that from true to false or the other way around)

Config.Settings = {
    refreshTime = 10000, --refresh blips for users every 10 seconds
    minChan = 1,
    maxChan = 100
}

Config.Items = {
    ['veh_tracker_emitter'] = {
        name = 'veh_tracker_emitter',
        label = 'Tracker emitter',
        weight = 20,
        type = 'item',
        image = 'tunerchip.png',
        unique = false,
        useable = true,
        shouldClose = true,
        combinable = nil,
        description = 'A tracking device to put on the closest vehicle.'
    },
    ['veh_tracker_receiver'] = {
        name = 'veh_tracker_receiver',
        label = 'Tracker receiver',
        weight = 50,
        type = 'item',
        image = 'radioscanner.png',
        unique = true,
        useable = true,
        shouldClose = true,
        combinable = nil,
        description = 'Tracking device getting vehicles position when tracked.'
    },
    ['veh_tracker_scanner'] = {
        name = 'veh_tracker_scanner',
        label = 'Tracker scanner',
        weight = 50,
        type = 'item',
        image = 'electronickit.png',
        unique = true,
        useable = true,
        shouldClose = true,
        combinable = nil,
        description = 'You can scan the vehicle to search for tracking device.'
    },
}

Config.Actions = {
    ["put_tracker"] = {
        name = "installing_tracker",
        description = "Installing tracker on vehicle",
        duration = 5000,
        animation = {
            anim_dict = "gestures@m@sitting@generic@casual",
            anim_name = "gesture_hand_left",
            attached_bone = 36029,
            prop_model = 'w_am_hackdevice_m32',
            prop_coord = vector3(0.05, 0.05, 0),
            prop_rotaton = vector3(-110, 20, 0)
        }
    },
    ["remove_tracker"] = {
        name = "removing_tracker",
        description = "Removing tracker from vehicle",
        duration = 5000,
        animation = {
            anim_dict = "gestures@m@sitting@generic@casual",
            anim_name = "gesture_hand_left",
            attached_bone = 36029,
            prop_model = 'w_am_hackdevice_m32',
            prop_coord = vector3(0.05, 0.05, 0),
            prop_rotaton = vector3(-110, 20, 0)
        }
    },
    ["scan_tracker"] = {
        name = "scanning_tracker",
        description = "Scanning vehicle for tracker",
        duration = 5000,
        animation = {
            anim_dict = "gestures@m@sitting@generic@casual",
            anim_name = "gesture_hand_left",
            attached_bone = 36029,
            prop_model = 'w_am_hackdevice_m32',
            prop_coord = vector3(0.05, 0.05, 0),
            prop_rotaton = vector3(-110, 20, 0)
        }
    }
}
