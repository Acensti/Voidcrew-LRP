/**
 * ##get_all_humans
 *
 * Returns a list of all the living humans on the ship
 */
/obj/docking_port/mobile/proc/get_all_humans()
	var/list/humans_to_add = list()
	var/list/all_turfs = return_ordered_turfs(x, y, z, dir)
	for (var/turf/turf as anything in all_turfs)
		var/mob/living/carbon/human/human_to_add = locate() in turf.contents
		if (isnull(human_to_add))
			continue
		if (human_to_add.stat == DEAD)
			continue
		humans_to_add.Add(human_to_add)
	return humans_to_add

/**
 * Scuttle the ship
 *
 * Delete all of the areas, and delete any cryopods
 */
/obj/docking_port/mobile/proc/mothball()
	if(length(get_all_humans()) > 0)
		return
	var/obj/docking_port/stationary/current_dock = get_docked()

	var/underlying_area_type = SHUTTLE_DEFAULT_UNDERLYING_AREA
	if(current_dock && current_dock.area_type)
		underlying_area_type = current_dock.area_type

	var/list/old_turfs = return_ordered_turfs(x, y, z, dir)

	var/area/underlying_area = GLOB.areas_by_type[underlying_area_type]
	if(!underlying_area)
		underlying_area = new underlying_area_type(null)

	for(var/i in 1 to old_turfs.len)
		var/turf/oldT = old_turfs[i]
		if(!oldT || !istype(oldT.loc, area_type))
			continue
		var/obj/machinery/cryopod/pod = locate() in oldT.contents
		if (!isnull(pod))
			qdel(pod) // we don't want anyone respawning now do we
		var/area/old_area = oldT.loc
		underlying_area.contents += oldT
		oldT.change_area(old_area, underlying_area)

	message_admins("\[SHUTTLE]: [current_ship?.name] has been turned into a ruin!")
	log_admin("\[SHUTTLE]: [current_ship?.name] has been turned into a ruin!")

	qdel(src, force=TRUE)
