SUBSYSTEM_DEF(overmap)
	name = "Overmap"
	wait = 10
	init_order = INIT_ORDER_OVERMAP
	flags = SS_KEEP_TIMING|SS_NO_TICK_CHECK
	runlevels = RUNLEVEL_SETUP | RUNLEVEL_GAME

	//The type of star this system will have
	var/startype
	///Defines which generator to use for the overmap
	var/generator_type = OVERMAP_GENERATOR_RANDOM

	///List of all overmap objects.
	var/list/overmap_objects
	///List of all simulated ships
	var/list/simulated_ships
	///List of all events
	var/list/events

	///Map of tiles at each radius (represented by index) around the sun
	var/list/list/radius_tiles

	///The main station or ship
	var/obj/structure/overmap/main

	///Width/height of the overmap "zlevel"
	var/size = 25
	///Should events be processed
	var/events_enabled = TRUE

	///Cooldown on dynamically loading encounters
	var/encounter_cooldown = 0

/**
  * Creates an overmap object for shuttles, triggers initialization procs for ships
  */
/datum/controller/subsystem/overmap/Initialize(start_timeofday)
	overmap_objects = list()
	simulated_ships = list()
	events = list()

	generator_type = CONFIG_GET(string/overmap_generator_type)
	if (!generator_type)
		generator_type = OVERMAP_GENERATOR_RANDOM

	if (generator_type == OVERMAP_GENERATOR_SOLAR)
		var/obj/structure/overmap/star/center
		startype = pick(SMALLSTAR,TWOSTAR,MEDSTAR,BIGSTAR)
		if(startype == SMALLSTAR)
			center = new(locate(size / 2, size / 2, 1))
		if(startype == TWOSTAR)
			var/obj/structure/overmap/star/big/binary/S
			S = new(locate(size / 2, size / 2, 1))
			center = S
		if(startype == MEDSTAR)
			var/obj/structure/overmap/star/medium/S
			S = new(locate(size / 2, size / 2, 1))
			center = S
		if(startype == BIGSTAR)
			var/obj/structure/overmap/star/big/S
			S = new(locate(size / 2, size / 2, 1))
			center = S
		var/list/unsorted_turfs = get_areatype_turfs(/area/overmap)
		// SSovermap.size - 2 = area of the overmap w/o borders
		radius_tiles = list()
		for(var/i in 1 to (size - 2) / 2)
			radius_tiles += list(list()) // gift-wrapped list for you <3
			for(var/turf/T in unsorted_turfs)
				var/dist = round(sqrt((T.x - center.x) ** 2 + (T.y - center.y) ** 2))
				if (dist != i)
					continue
				radius_tiles[i] += T
				unsorted_turfs -= T

	create_map()

	return ..()

/datum/controller/subsystem/overmap/fire()
	if(events_enabled)
		for(var/obj/structure/overmap/event/E as anything in events)
			if(E?.affect_multiple_times && E?.close_overmap_objects)
				E.apply_effect()

/**
  * Creates an overmap ship object for the provided mobile docking port if one does not already exist.
  * * Shuttle: The docking port to create an overmap object for
  */
/datum/controller/subsystem/overmap/proc/setup_shuttle_ship(obj/docking_port/mobile/shuttle, datum/map_template/shuttle/source_template)
	var/docked_object = get_overmap_object_by_location(shuttle)
	var/obj/structure/overmap/ship/simulated/new_ship
	if(docked_object)
		new_ship = new(docked_object, shuttle, source_template)
		new_ship.state = OVERMAP_SHIP_IDLE
	else if(is_reserved_level(shuttle))
		new_ship = new(get_unused_overmap_square(), shuttle, source_template)
		new_ship.state = OVERMAP_SHIP_FLYING
	else if(is_centcom_level(shuttle))
		new_ship = new(null, shuttle, source_template)
	else
		CRASH("Shuttle created in unknown location, unable to create overmap ship!")

	shuttle.current_ship = new_ship

/**
  * The proc that creates all the objects on the overmap, split into seperate procs for redundancy.
  */
/datum/controller/subsystem/overmap/proc/create_map()
	if (generator_type == OVERMAP_GENERATOR_SOLAR)
		spawn_events_in_orbits()
		spawn_ruin_levels_in_orbits()
	else
		spawn_events()
		spawn_ruin_levels()

	spawn_initial_ships()

/**
  * VERY Simple random generation for overmap events, spawns the event in a random turf and sometimes spreads it out similar to ores
  */
/datum/controller/subsystem/overmap/proc/spawn_events()
	var/max_clusters = CONFIG_GET(number/max_overmap_event_clusters)
	for(var/i=1, i<=max_clusters, i++)
		spawn_event_cluster(pick(subtypesof(/obj/structure/overmap/event)), get_unused_overmap_square())

/datum/controller/subsystem/overmap/proc/spawn_events_in_orbits()
	var/list/orbits = list()
	for(var/i in 2 to LAZYLEN(radius_tiles)) // At least two away to prevent overlap
		orbits += "[i]"

	var/max_clusters = CONFIG_GET(number/max_overmap_event_clusters)
	for(var/i in 1 to max_clusters)
		if(CONFIG_GET(number/max_overmap_events) <= LAZYLEN(events))
			return
		if(LAZYLEN(orbits == 0) || !orbits)
			break // Can't fit any more in
		var/event_type = pickweight(GLOB.overmap_event_pick_list)
		var/selected_orbit = text2num(pick(orbits))

		var/turf/T = get_unused_overmap_square_in_radius(selected_orbit)
		if(!T || !istype(T))
			orbits -= "[selected_orbit]" // This orbit is full, move onto the next
			continue

		var/obj/structure/overmap/event/E = new event_type(T)
		for(var/turf/U as anything in radius_tiles[selected_orbit])
			if(locate(/obj/structure/overmap) in U)
				continue
			if(!prob(E.spread_chance))
				continue
			new event_type(U)

/**
  * See [/datum/controller/subsystem/overmap/proc/spawn_events], spawns "veins" (like ores) of events
  */
/datum/controller/subsystem/overmap/proc/spawn_event_cluster(obj/structure/overmap/event/type, turf/location, chance)
	if(CONFIG_GET(number/max_overmap_events) <= LAZYLEN(events))
		return
	var/obj/structure/overmap/event/E = new type(location)
	if(!chance)
		chance = E.spread_chance
	for(var/dir in GLOB.cardinals)
		if(prob(chance))
			var/turf/T = get_step(E, dir)
			if(!istype(get_area(T), /area/overmap))
				continue
			if(locate(/obj/structure/overmap/event) in T)
				continue
			spawn_event_cluster(type, T, chance / 2)

/datum/controller/subsystem/overmap/proc/spawn_initial_ships()
#ifndef UNIT_TESTS
	var/datum/map_template/shuttle/selected_template = SSmapping.maplist[pick(SSmapping.maplist)]
	INIT_ANNOUNCE("Loading [selected_template.name]...")
	SSshuttle.load_template(selected_template)
	if(SSdbcore.Connect())
		var/datum/DBQuery/query_round_map_name = SSdbcore.NewQuery({"
			UPDATE [format_table_name("round")] SET map_name = :map_name WHERE id = :round_id
		"}, list("map_name" = selected_template.name, "round_id" = GLOB.round_id))
		query_round_map_name.Execute()
		qdel(query_round_map_name)
#endif

/**
  * Creates an overmap object for each ruin level, making them accessible.
  */
/datum/controller/subsystem/overmap/proc/spawn_ruin_levels()
	for(var/i in 1 to CONFIG_GET(number/max_overmap_dynamic_events))
		new /obj/structure/overmap/dynamic(get_unused_overmap_square())

/datum/controller/subsystem/overmap/proc/spawn_ruin_levels_in_orbits()
	for(var/i in 1 to CONFIG_GET(number/max_overmap_dynamic_events))
		new /obj/structure/overmap/dynamic(get_unused_overmap_square_in_radius())

/**
  * Reserves a square dynamic encounter area, and spawns a ruin in it if one is supplied.
  * * on_planet - If the encounter should be on a generated planet. Required, as it will be otherwise inaccessible.
  * * target - The ruin to spawn, if any
  * * ruin_type - The ruin to spawn. Don't pass this argument if you want it to randomly select based on planet type.
  */
/datum/controller/subsystem/overmap/proc/spawn_dynamic_encounter(planet_type, ruin = TRUE, ignore_cooldown = FALSE, datum/map_template/ruin/ruin_type)
	var/list/ruin_list
	var/datum/map_generator/mapgen
	var/area/target_area
	var/turf/surface = /turf/open/space
	var/datum/weather_controller/weather_controller_type
	if(planet_type)
		switch(planet_type)
			if(DYNAMIC_WORLD_LAVA)
				ruin_list = SSmapping.lava_ruins_templates
				mapgen = new /datum/map_generator/cave_generator/lavaland
				target_area = /area/overmap_encounter/planetoid/lava
				surface = /turf/open/floor/plating/asteroid/basalt/lava_land_surface
				weather_controller_type = /datum/weather_controller/lavaland
			if(DYNAMIC_WORLD_ICE)
				ruin_list = SSmapping.ice_ruins_templates
				mapgen = new /datum/map_generator/cave_generator/icemoon
				target_area = /area/overmap_encounter/planetoid/ice
				surface = /turf/open/floor/plating/asteroid/snow/icemoon
				weather_controller_type = /datum/weather_controller/snow_planet
			if(DYNAMIC_WORLD_SAND)
				ruin_list = SSmapping.sand_ruins_templates
				mapgen = new /datum/map_generator/cave_generator/whitesands
				target_area = /area/overmap_encounter/planetoid/sand
				surface = /turf/open/floor/plating/asteroid/whitesands
				weather_controller_type = /datum/weather_controller/desert
			if(DYNAMIC_WORLD_JUNGLE)
				ruin_list = SSmapping.jungle_ruins_templates
				mapgen = new /datum/map_generator/jungle_generator
				target_area = /area/overmap_encounter/planetoid/jungle
				surface = /turf/open/floor/plating/dirt/jungle
				weather_controller_type = /datum/weather_controller/lush
			if(DYNAMIC_WORLD_BEACH)
				ruin_list = SSmapping.beach_ruins_templates
				mapgen = new /datum/map_generator/beach_generator
				target_area = /area/overmap_encounter/planetoid/beach
				surface = /turf/open/floor/plating/beach/sand/lit
				weather_controller_type = /datum/weather_controller/lush
			if(DYNAMIC_WORLD_ASTEROID)
				ruin_list = null
				mapgen = new /datum/map_generator/cave_generator/asteroid
			if(DYNAMIC_WORLD_ROCKPLANET)
				ruin_list = SSmapping.rock_ruins_templates
				mapgen = new /datum/map_generator/cave_generator/rockplanet
				target_area = /area/overmap_encounter/planetoid/rockplanet
				surface = /turf/open/floor/plating/asteroid
				weather_controller_type = /datum/weather_controller/chlorine //let's go??
			if(DYNAMIC_WORLD_REEBE)
				ruin_list = SSmapping.yellow_ruins_templates
				mapgen = new /datum/map_generator/cave_generator/reebe
				target_area = /area/overmap_encounter/planetoid/reebe
				surface = /turf/open/chasm/reebe_void
			if(DYNAMIC_WORLD_SPACERUIN)
				ruin_list = SSmapping.space_ruins_templates

	if(ruin && ruin_list && !ruin_type)
		ruin_type = ruin_list[pick(ruin_list)]
		if(ispath(ruin_type))
			ruin_type = new ruin_type

	var/height = QUADRANT_MAP_SIZE
	var/width = QUADRANT_MAP_SIZE

	var/encounter_name = "Dynamic Overmap Encounter"
	var/datum/map_zone/mapzone = SSmapping.create_map_zone(encounter_name)
	var/datum/virtual_level/vlevel = SSmapping.create_virtual_level(encounter_name, list(ZTRAIT_MINING = TRUE), mapzone, width, height, ALLOCATION_QUADRANT, QUADRANT_MAP_SIZE)

	vlevel.reserve_margin(QUADRANT_SIZE_BORDER)

	if(mapgen) /// If we have a map generator, don't ChangeTurf's in fill_in. Just to ChangeTurf them once again.
		surface = null
	vlevel.fill_in(surface, target_area)

	if(ruin_type)
		var/turf/ruin_turf = locate(rand(
			vlevel.low_x+6 + vlevel.reserved_margin,
			vlevel.high_x-ruin_type.width-6 - vlevel.reserved_margin),
			vlevel.high_y-ruin_type.height-6 - vlevel.reserved_margin,
			vlevel.z_value
			)
		ruin_type.load(ruin_turf)

	if(mapgen)
		mapgen.generate_terrain(vlevel.get_unreserved_block())

	if(weather_controller_type)
		new weather_controller_type(mapzone)

	// locates the first dock in the bottom left, accounting for padding and the border
	var/turf/primary_docking_turf = locate(
		vlevel.low_x+RESERVE_DOCK_DEFAULT_PADDING+1 + vlevel.reserved_margin,
		vlevel.low_y+RESERVE_DOCK_DEFAULT_PADDING+1 + vlevel.reserved_margin,
		vlevel.z_value
		)
	// now we need to offset to account for the first dock
	var/turf/secondary_docking_turf = locate(
		primary_docking_turf.x+RESERVE_DOCK_MAX_SIZE_LONG+RESERVE_DOCK_DEFAULT_PADDING,
		primary_docking_turf.y,
		primary_docking_turf.z
		)

	//This check exists because docking ports don't like to be deleted.
	var/obj/docking_port/stationary/primary_dock = new(primary_docking_turf)
	primary_dock.dir = NORTH
	primary_dock.name = "\improper Uncharted Space"
	primary_dock.height = RESERVE_DOCK_MAX_SIZE_SHORT
	primary_dock.width = RESERVE_DOCK_MAX_SIZE_LONG
	primary_dock.dheight = 0
	primary_dock.dwidth = 0

	var/obj/docking_port/stationary/secondary_dock = new(secondary_docking_turf)
	secondary_dock.dir = NORTH
	secondary_dock.name = "\improper Uncharted Space"
	secondary_dock.height = RESERVE_DOCK_MAX_SIZE_SHORT
	secondary_dock.width = RESERVE_DOCK_MAX_SIZE_LONG
	secondary_dock.dheight = 0
	secondary_dock.dwidth = 0

	return list(mapzone, primary_dock, secondary_dock)

/**
  * Returns a random, usually empty turf in the overmap
  * * thing_to_not_have - The thing you don't want to be in the found tile, for example, an overmap event [/obj/structure/overmap/event].
  * * tries - How many attempts it will try before giving up finding an unused tile.
  */
/datum/controller/subsystem/overmap/proc/get_unused_overmap_square(thing_to_not_have = /obj/structure/overmap, tries = MAX_OVERMAP_PLACEMENT_ATTEMPTS, force = FALSE)
	for(var/i in 1 to tries)
		. = pick(pick(get_areatype_turfs(/area/overmap)))
		if(locate(thing_to_not_have) in .)
			continue
		return

	if(!force)
		. = null

/**
  * Returns a random turf in a radius from the star, or a random empty turf if OVERMAP_GENERATOR_RANDOM is the active generator.
  * * thing_to_not_have - The thing you don't want to be in the found tile, for example, an overmap event [/obj/structure/overmap/event].
  * * tries - How many attempts it will try before giving up finding an unused tile..
  * * radius - The distance from the star to search for an empty tile.
  */
/datum/controller/subsystem/overmap/proc/get_unused_overmap_square_in_radius(radius, thing_to_not_have = /obj/structure/overmap, tries = MAX_OVERMAP_PLACEMENT_ATTEMPTS, force = FALSE)
	if(!radius)
		radius = rand(2, LAZYLEN(radius_tiles))

	for(var/i in 1 to tries)
		. = pick(radius_tiles[radius])
		if(locate(thing_to_not_have) in .)
			continue
		return

	if(!force)
		. = null

/datum/controller/subsystem/overmap/proc/get_nearest_unused_square_in_radius(adjacent, radius, max_range, thing_to_not_have = /obj/structure/overmap)
	var/turf/target = adjacent
	var/ret_dist = INFINITY
	for(var/turf/T as anything in radius_tiles[radius])
		if (locate(thing_to_not_have) in T)
			continue
		var/dist = round(sqrt((T.x - target.x) ** 2 + (T.y - target.y) ** 2))
		if (dist < max_range && dist < ret_dist)
			. = T
			ret_dist = dist

/**
  * Gets the parent overmap object (e.g. the planet the atom is on) for a given atom.
  * * source - The object you want to get the corresponding parent overmap object for.
  */
/datum/controller/subsystem/overmap/proc/get_overmap_object_by_location(atom/source)
	for(var/O in overmap_objects)
		if(istype(O, /obj/structure/overmap/dynamic))
			var/obj/structure/overmap/dynamic/D = O
			if(D.mapzone?.is_in_bounds(source))
				return D

/datum/controller/subsystem/overmap/Recover()
	if(istype(SSovermap.events))
		events = SSovermap.events
	if(istype(SSovermap.radius_tiles))
		radius_tiles = SSovermap.radius_tiles
