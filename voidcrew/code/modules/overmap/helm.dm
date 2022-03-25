#define JUMP_STATE_OFF 0
#define JUMP_STATE_CHARGING 1
#define JUMP_STATE_IONIZING 2
#define JUMP_STATE_FIRING 3
#define JUMP_STATE_FINALIZED 4
#define JUMP_CHARGE_DELAY (20 SECONDS)
#define JUMP_CHARGEUP_TIME (3 MINUTES)

/obj/machinery/computer/helm
	name = "helm control console"
	desc = "Used to view or control the ship."
	icon_screen = "navigation"
	icon_keyboard = "tech_key"
	circuit = /obj/item/circuitboard/computer/shuttle/helm
	light_color = LIGHT_COLOR_FLARE
	clicksound = null

	/// The ship we reside on for ease of access
	var/obj/structure/overmap/ship/simulated/current_ship
	/// All users currently using this
	var/list/concurrent_users = list()
	/// Is this console view only? I.E. cant dock/etc
	var/viewer = FALSE
	/// When are we allowed to jump
	var/jump_allowed
	/// Current state of our jump
	var/jump_state = JUMP_STATE_OFF
	///if we are calibrating the jump
	var/calibrating = FALSE
	///holding jump timer ID
	var/jump_timer

/datum/config_entry/number/bluespace_jump_wait
	default = 30 MINUTES

/obj/machinery/computer/helm/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	jump_allowed = world.time + CONFIG_GET(number/bluespace_jump_wait)
	addtimer(CALLBACK(src, .proc/reload_ship), 5)

/obj/machinery/computer/helm/proc/calibrate_jump(inline = FALSE)
	if(jump_allowed < 0)
		say("Bluespace Jump Calibration offline. Please contact your system administrator.")
		return
	if(current_ship.state != OVERMAP_SHIP_FLYING)
		say("Bluespace Jump Calibration detected interference in the local area.")
		return
	if(world.time < jump_allowed)
		var/jump_wait = DisplayTimeText(jump_allowed - world.time)
		say("Bluespace Jump Calibration is currently recharging. ETA: [jump_wait].")
		return
	if(jump_state != JUMP_STATE_OFF && !inline)
		return // This exists to prefent Href exploits to call process_jump more than once by a client
	message_admins("[ADMIN_LOOKUPFLW(usr)] has initiated a bluespace jump in [ADMIN_VERBOSEJMP(src)]")
	jump_timer = addtimer(CALLBACK(src, .proc/jump_sequence, TRUE), JUMP_CHARGEUP_TIME, TIMER_STOPPABLE)
	priority_announce("Bluespace jump calibration initialized. Calibration completion in [JUMP_CHARGEUP_TIME/600] minutes.", sender_override="[current_ship.display_name] Bluespace Pylon", zlevel=virtual_z())
	calibrating = TRUE
	log_shuttle("[usr] has initiated a bluespace jump for [current_ship.name]")
	return TRUE

/obj/machinery/computer/helm/proc/cancel_jump()
	priority_announce("Bluespace Pylon spooling down. Jump calibration aborted.", sender_override="[current_ship.display_name] Bluespace Pylon", zlevel=virtual_z())
	calibrating = FALSE
	log_shuttle("[usr] has cancelled a bluespace jump aboard [current_ship.display_name]")
	deltimer(jump_timer)

/obj/machinery/computer/helm/proc/jump_sequence()
	switch(jump_state)
		if(JUMP_STATE_OFF)
			jump_state = JUMP_STATE_CHARGING
			SStgui.close_uis(src)
		if(JUMP_STATE_CHARGING)
			jump_state = JUMP_STATE_IONIZING
			priority_announce("Bluespace Jump Calibration completed. Ionizing Bluespace Pylon.", sender_override="[current_ship.display_name] Bluespace Pylon", zlevel=virtual_z())
		if(JUMP_STATE_IONIZING)
			jump_state = JUMP_STATE_FIRING
			priority_announce("Bluespace Ionization finalized; preparing to fire Bluespace Pylon.", sender_override="[current_ship.display_name] Bluespace Pylon", zlevel=virtual_z())
		if(JUMP_STATE_FIRING)
			jump_state = JUMP_STATE_FINALIZED
			priority_announce("Bluespace Pylon launched.", sender_override="[current_ship.display_name] Bluespace Pylon", sound='sound/magic/lightning_chargeup.ogg', zlevel=virtual_z())
			addtimer(CALLBACK(src, .proc/do_jump), 10 SECONDS)
			return
	addtimer(CALLBACK(src, .proc/jump_sequence, TRUE), JUMP_CHARGE_DELAY)

/obj/machinery/computer/helm/proc/do_jump()
	priority_announce("Bluespace Jump Initiated.", sender_override="[current_ship.display_name] Bluespace Pylon", sound='sound/magic/lightningbolt.ogg', zlevel=virtual_z())
	// You can't bluespace jump while docked, but maybe admeme does it? In which case without this that docking spot would just stay taken. Just a precaution
	current_ship.update_docked_bools()
	current_ship.docked = null
	current_ship.shuttle.intoTheSunset()

/obj/machinery/computer/helm/connect_to_shuttle(obj/docking_port/mobile/port, obj/docking_port/stationary/dock)
	current_ship = port.current_ship
	current_ship.most_recent_helm = src

/**
 * This proc manually rechecks that the helm computer is connected to a proper ship
 */
/obj/machinery/computer/helm/proc/reload_ship()
	var/obj/docking_port/mobile/port = SSshuttle.get_containing_shuttle(src)
	if(port?.current_ship)
		current_ship = port.current_ship
		return TRUE

/obj/machinery/computer/helm/ui_interact(mob/user, datum/tgui/ui)
	if(current_ship.is_player_in_crew(user) || isAdminGhostAI(user))
		if(jump_state != JUMP_STATE_OFF)
			say("Bluespace Jump in progress. Controls suspended.")
			return
		// Update UI
		if(!current_ship && !reload_ship())
			return
		ui = SStgui.try_update_ui(user, src, ui)
		if(!ui)
			var/user_ref = REF(user)
			var/is_living = isliving(user)
			// Ghosts shouldn't count towards concurrent users, which produces
			// an audible terminal_on click.
			if(is_living)
				concurrent_users += user_ref
			// Turn on the console
			if(length(concurrent_users) == 1 && is_living)
				playsound(src, 'sound/machines/terminal_on.ogg', 25, FALSE)
				use_power(active_power_usage)
			// Register map objects
			if(current_ship)
				user.client.register_map_obj(current_ship.cam_screen)
				user.client.register_map_obj(current_ship.cam_plane_master)
				user.client.register_map_obj(current_ship.cam_background)
				current_ship.update_screen()
			// Open UI
			ui = new(user, src, "HelmConsole", name)
			ui.open()
	else
		if(!isliving(user))
			return
		say("ERROR: Unrecognized bio-signature detected")
		return

/obj/machinery/computer/helm/ui_data(mob/user)
	. = list()
	//dock requesting stuff
	if (current_ship.requesting_ship)
		if (current_ship.loc == current_ship.requesting_ship.loc)
			.["dock_request"] = current_ship.requesting_ship
			.["dock_req_name"] = current_ship.requesting_ship.name
		else
			current_ship.requesting_ship.most_recent_helm.say("Ship has moved out of range.")
			current_ship.requesting_ship.sent_request = FALSE
			current_ship.requesting_ship = null
	else
		.["dock_request"] = null

	.["integrity"] = current_ship.integrity
	.["calibrating"] = calibrating
	.["otherInfo"] = list()
	for (var/obj/structure/overmap/object as anything in current_ship.close_overmap_objects)
		var/list/other_data = list(
			name = object.name,
			integrity = object.integrity,
			ref = REF(object)
		)
		.["otherInfo"] += list(other_data)

	var/turf/T = get_turf(current_ship)
	.["x"] = T.x
	.["y"] = T.y
	.["state"] = current_ship.state
	.["docked"] = isturf(current_ship.loc) ? FALSE : TRUE
	.["heading"] = dir2text(current_ship.get_heading()) || "None"
	.["speed"] = current_ship.get_speed()
	.["eta"] = current_ship.get_eta()
	.["est_thrust"] = current_ship.est_thrust
	.["engineInfo"] = list()
	for(var/obj/machinery/power/shuttle/engine/E in current_ship.shuttle.engine_list)
		var/list/engine_data
		if(!E.thruster_active)
			engine_data = list(
				name = E.name,
				fuel = 0,
				maxFuel = 100,
				enabled = E.enabled,
				ref = REF(E)
			)
		else
			engine_data = list(
				name = E.name,
				fuel = E.return_fuel(),
				maxFuel = E.return_fuel_cap(),
				enabled = E.enabled,
				ref = REF(E)
			)
		.["engineInfo"] += list(engine_data)

/obj/machinery/computer/helm/ui_static_data(mob/user)
	. = list()
	.["isViewer"] = viewer
	.["mapRef"] = current_ship.map_name
	.["shipInfo"] = list(
		name = current_ship.display_name,
		class = current_ship.source_template?.name,
		mass = current_ship.mass,
		sensor_range = current_ship.sensor_range
	)
	.["canFly"] = TRUE

/obj/machinery/computer/helm/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(viewer)
		return
	switch(action) // Universal topics
		if("rename_ship")
			var/new_name = params["newName"]
			var/old_name = current_ship.name
			if(!new_name)
				return
			new_name = trim(new_name)
			if (!length(new_name) || new_name == current_ship.name)
				return
			if(!reject_bad_text(new_name, MAX_CHARTER_LEN))
				say("Error: Replacement designation rejected by system.")
				return
			if(!current_ship.set_ship_name(new_name))
				say("Error: [COOLDOWN_TIMELEFT(current_ship, rename_cooldown)/10] seconds until ship designation can be changed..")
			else
				log_shuttle("[usr] changed shuttle [old_name] to [new_name]")
			update_static_data(usr, ui)
			return
		if("toggle_kos")
			if(!current_ship.set_ship_faction("KOS"))
				say("Error: [COOLDOWN_TIMELEFT(current_ship, faction_cooldown)/10] seconds until faction can be changed..")
			else
				log_shuttle("[usr] set [current_ship.display_name]'s faction to KOS")
			update_static_data(usr, ui)
			return
		if("return")
			if(!current_ship.set_ship_faction("return"))
				say("Error: [COOLDOWN_TIMELEFT(current_ship, faction_cooldown)/10] seconds until faction can be changed..")
			else
				log_shuttle("[usr] set [current_ship.display_name]'s faction back to default")
			update_static_data(usr, ui)
			return
		if("reload_ship")
			reload_ship()
			update_static_data(usr, ui)
			return
		if("reload_engines")
			current_ship.refresh_engines()
			return
		if("dock_req_success")
			current_ship.requesting_ship.most_recent_helm.say("Request accepted!")
			playsound(current_ship.requesting_ship.most_recent_helm.loc, 'sound/machines/ping.ogg', 90, 1, 0)
			if (current_ship.loc == current_ship.requesting_ship.loc)
				current_ship.duo_dock(usr, current_ship.requesting_ship)
			else // The request disappears when the ships move away so this shouldn't happen, but just in case
				current_ship.most_recent_helm.say("Requesting ship moved away. Cancelling dock.")
			current_ship.requesting_ship.sent_request = FALSE
			current_ship.requesting_ship = null
			return
		if("dock_req_failure")
			current_ship.requesting_ship.most_recent_helm.say("Request denied.")
			playsound(current_ship.requesting_ship.most_recent_helm.loc, 'sound/machines/ping.ogg', 90, 1, 0)
			current_ship.requesting_ship.sent_request = FALSE
			current_ship.requesting_ship = null
			return

	switch(current_ship.state) // Ship state-limited topics
		if(OVERMAP_SHIP_FLYING)
			switch(action)
				if("act_overmap")
					if(SSshuttle.jump_mode == BS_JUMP_INITIATED)
						to_chat(usr, "<span class='warning'>You've already escaped. Never going back to that place again!</span>")
						return
					var/obj/structure/overmap/to_act = locate(params["ship_to_act"])
					say(current_ship.overmap_object_act(usr, to_act))
					return
				if("toggle_engine")
					var/obj/machinery/power/shuttle/engine/E = locate(params["engine"])
					E.enabled = !E.enabled
					current_ship.refresh_engines()
					return
				if("change_heading")
					current_ship.current_autopilot_target = null
					current_ship.burn_engines(text2num(params["dir"]))
					return
				if("stop")
					current_ship.current_autopilot_target = null
					current_ship.burn_engines()
					return
				if("bluespace_jump")
					if(calibrating)
						cancel_jump()
						return
					else
						if(tgui_alert(usr, "Do you want to bluespace jump? Your ship and everything on it will be removed from the round.", "Jump Confirmation", list("Yes", "No")) != "Yes")
							return
						calibrate_jump()
						return
				if("dock_empty")
					say(current_ship.dock_in_empty_space(usr))
					return
		if(OVERMAP_SHIP_IDLE)
			if(action == "undock")
				current_ship.calculate_avg_fuel()
				if(current_ship.avg_fuel_amnt < 25 && tgui_alert(usr, "Ship only has ~[round(current_ship.avg_fuel_amnt)]% fuel remaining! Are you sure you want to undock?", name, list("Yes", "No")) != "Yes")
					return
				say(current_ship.undock())
				return

/obj/machinery/computer/helm/ui_close(mob/user)
	var/user_ref = REF(user)
	var/is_living = isliving(user)
	// Living creature or not, we remove you anyway.
	concurrent_users -= user_ref
	// Unregister map objects
	if(current_ship)
		user.client?.clear_map(current_ship.map_name)
	// Turn off the console
	if(length(concurrent_users) == 0 && is_living)
		playsound(src, 'sound/machines/terminal_off.ogg', 25, FALSE)
		use_power(0)

/obj/machinery/computer/helm/viewscreen
	name = "ship viewscreen"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "telescreen"
	layer = SIGN_LAYER
	density = FALSE
	viewer = TRUE

#undef JUMP_STATE_OFF
#undef JUMP_STATE_CHARGING
#undef JUMP_STATE_IONIZING
#undef JUMP_STATE_FIRING
#undef JUMP_STATE_FINALIZED
#undef JUMP_CHARGE_DELAY
#undef JUMP_CHARGEUP_TIME
