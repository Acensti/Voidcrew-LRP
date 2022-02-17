/obj/machinery/computer/autopilot
	name = "autopilot console"
	desc = "A shuttle control computer the controls the autopiloting system."
	icon_screen = "shuttle"
	icon_keyboard = "tech_key"
	light_color = LIGHT_COLOR_CYAN
	/// ID of the ship to control
	var/ship_id
	///The currently selected overmap object destination of the attached shuttle
	var/obj/structure/overmap/destination
	///The linked overmap shuttle
	var/obj/structure/overmap/ship/simulated/ship

/obj/machinery/computer/autopilot/connect_to_shuttle(obj/docking_port/mobile/port, obj/docking_port/stationary/dock)
	ship = port.current_ship

/obj/machinery/computer/autopilot/proc/reload_ship()
	var/obj/docking_port/mobile/port = SSshuttle.get_containing_shuttle(src)
	if(port?.current_ship)
		ship = port.current_ship
		return TRUE

/obj/machinery/computer/autopilot/ui_interact(mob/user, datum/tgui/ui)
	if(ship.is_player_in_crew(user) || !isliving(user) || isAdminGhostAI(user))
		if(!ship && !reload_ship())
			return
		ui = SStgui.try_update_ui(user, src, ui)
		if(!ui)
			ui = new(user, src, "ShuttleConsole", name)
			ui.open()
	else
		say("ERROR: Unrecognized bio-signature detected")
		return
/obj/machinery/computer/autopilot/ui_data(mob/user)
	var/list/data = list()
	var/obj/docking_port/mobile/M = ship.shuttle
	data["docked_location"] = M ? M.get_status_text_tgui() : "Unknown"
	data["locations"] = list()
	data["locked"] = FALSE
	data["authorization_required"] = FALSE
	data["timer_str"] = ship ? ship.get_eta() : "--:--"
	data["destination"] = destination
	if(!ship?.shuttle)
		data["status"] = "Missing"
		return data

	switch(ship.state)
		if(OVERMAP_SHIP_UNDOCKING)
			data["status"] = "Undocking"
			data["locked"] = TRUE
		if(OVERMAP_SHIP_DOCKING)
			data["status"] = "Docking"
			data["locked"] = TRUE
		if(OVERMAP_SHIP_IDLE)
			data["status"] = "Idle"
		else
			if(ship.current_autopilot_target)
				data["status"] = "Flying | Autopilot active (Dest: [ship.current_autopilot_target])"
			else
				data["status"] = "Flying | Autopilot inactive"

	for(var/obj/structure/overmap/O in view(ship.sensor_range, get_turf(ship)))
		if(O == ship.loc || istype(O, /obj/structure/overmap/event) || O == ship)
			continue
		var/list/location_data = list(
			id = REF(O),
			name = O.name
		)
		data["locations"] += list(location_data)
	if(length(data["locations"]) == 1)
		for(var/location in data["locations"])
			destination = location["id"]
			data["destination"] = destination
	if(!length(data["locations"]))
		data["locked"] = TRUE
		data["status"] = "Locked"
	return data

/obj/machinery/computer/autopilot/ui_act(action, params)
	. = ..()
	if(.)
		return
	if(!allowed(usr))
		to_chat(usr, "<span class='danger'>Access denied.</span>")
		return

	switch(action)
		if("move")
			ship.current_autopilot_target = locate(params["shuttle_id"])
			if(!isturf(ship.loc))
				ship.undock()
			ship.tick_autopilot()
			return TRUE
		if("set_destination")
			var/target_destination = params["destination"]
			if(target_destination)
				destination = target_destination
				return TRUE
