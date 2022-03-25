#define LINKIFY_READY(string, value) "<a href='byond://?src=[REF(src)];ready=[value]'>[string]</a>"

/mob/dead/new_player
	var/ready = 0
	var/spawning = 0//Referenced when you want to delete the new_player later on in the code.

	flags_1 = NONE

	invisibility = INVISIBILITY_ABSTRACT

	density = FALSE
	stat = DEAD
	hud_possible = list()

	var/mob/living/new_character	//for instant transfer once the round is set up

	//Used to make sure someone doesn't get spammed with messages if they're ineligible for roles
	var/ineligible_for_roles = FALSE

/mob/dead/new_player/Initialize()
	if(client && SSticker.state == GAME_STATE_STARTUP)
		var/atom/movable/screen/splash/S = new(client, TRUE, TRUE)
		S.Fade(TRUE)

	if(length(GLOB.newplayer_start))
		forceMove(pick(GLOB.newplayer_start))
	else
		forceMove(locate(1,1,1))

	ComponentInitialize()

	. = ..()

	GLOB.new_player_list += src

/mob/dead/new_player/Destroy()
	GLOB.new_player_list -= src

	return ..()

/mob/dead/new_player/prepare_huds()
	return

/**
  * This proc generates the panel that opens to all newly joining players, allowing them to join, observe, view polls, view the current crew manifest, and open the character customization menu.
  */
/mob/dead/new_player/proc/new_player_panel()
	if (client?.interviewee)
		return

	var/datum/asset/asset_datum = get_asset_datum(/datum/asset/simple/lobby)
	asset_datum.send(client)
	var/list/output = list("<center><p><a href='byond://?src=[REF(src)];show_preferences=1'>Setup Character</a></p>")

	if(SSticker.current_state <= GAME_STATE_PREGAME)
		switch(ready)
			if(PLAYER_NOT_READY)
				output += "<p>\[ <b>Not Ready</b> | [LINKIFY_READY("Observe", PLAYER_READY_TO_OBSERVE)] \]</p>"
			if(PLAYER_READY_TO_PLAY)
				output += "<p>\[ [LINKIFY_READY("Not Ready", PLAYER_NOT_READY)] | [LINKIFY_READY("Observe", PLAYER_READY_TO_OBSERVE)] \]</p>"
			if(PLAYER_READY_TO_OBSERVE)
				output += "<p>\[ [LINKIFY_READY("Not Ready", PLAYER_NOT_READY)] | <b> Observe </b> \]</p>"
	else
		output += "<p><a href='byond://?src=[REF(src)];manifest=1'>View the Crew Manifest</a></p>"
		output += "<p><a href='byond://?src=[REF(src)];late_join=1'>Join Game!</a></p>"
		output += "<p>[LINKIFY_READY("Observe", PLAYER_READY_TO_OBSERVE)]</p>"

	if(!IsGuestKey(src.key))
		output += playerpolls()

	output += "</center>"

	var/datum/browser/popup = new(src, "playersetup", "<div align='center'>New Player Options</div>", 250, 265)
	popup.set_window_options("can_close=0")
	popup.set_content(output.Join())
	popup.open(FALSE)

/mob/dead/new_player/proc/playerpolls()
	var/list/output = list()
	if (SSdbcore.Connect())
		var/isadmin = FALSE
		if(client?.holder)
			isadmin = TRUE
		var/datum/DBQuery/query_get_new_polls = SSdbcore.NewQuery({"
			SELECT id FROM [format_table_name("poll_question")]
			WHERE (adminonly = 0 OR :isadmin = 1)
			AND Now() BETWEEN starttime AND endtime
			AND deleted = 0
			AND id NOT IN (
				SELECT pollid FROM [format_table_name("poll_vote")]
				WHERE ckey = :ckey
				AND deleted = 0
			)
			AND id NOT IN (
				SELECT pollid FROM [format_table_name("poll_textreply")]
				WHERE ckey = :ckey
				AND deleted = 0
			)
		"}, list("isadmin" = isadmin, "ckey" = ckey))
		var/rs = REF(src)
		if(!query_get_new_polls.Execute())
			qdel(query_get_new_polls)
			return "Failed to get player polls!"
		if(query_get_new_polls.NextRow())
			output += "<p><b><a href='byond://?src=[rs];showpoll=1'>Show Player Polls</A> (NEW!)</b></p>"
		else
			output += "<p><a href='byond://?src=[rs];showpoll=1'>Show Player Polls</A></p>"
		qdel(query_get_new_polls)
		if(QDELETED(src))
			return
		return output

/mob/dead/new_player/Topic(href, href_list[])
	if(src != usr)
		return 0

	if(!client)
		return 0

	if(client.interviewee)
		return FALSE

	//Determines Relevent Population Cap
	var/relevant_cap
	var/hpc = CONFIG_GET(number/hard_popcap)
	var/epc = CONFIG_GET(number/extreme_popcap)
	if(hpc && epc)
		relevant_cap = min(hpc, epc)
	else
		relevant_cap = max(hpc, epc)

	if(href_list["show_preferences"])
		client.prefs.ShowChoices(src)
		return 1

	if(href_list["ready"])
		var/tready = text2num(href_list["ready"])
		//Avoid updating ready if we're after PREGAME (they should use latejoin instead)
		//This is likely not an actual issue but I don't have time to prove that this
		//no longer is required
		if(SSticker.current_state <= GAME_STATE_PREGAME)
			ready = tready
		//if it's post initialisation and they're trying to observe we do the needful
		if(!SSticker.current_state < GAME_STATE_PREGAME && tready == PLAYER_READY_TO_OBSERVE)
			ready = tready
			make_me_an_observer()
			return

	if(href_list["refresh"])
		src << browse(null, "window=playersetup") //closes the player setup window
		new_player_panel()

	if(href_list["late_join"])
		if(!SSticker?.IsRoundInProgress())
			to_chat(usr, "<span class='boldwarning'>The round is either not ready, or has already finished...</span>")
			return

		if(href_list["late_join"] == "override")
			LateChoices()
			return

		if(SSticker.queued_players.len || (relevant_cap && living_player_count() >= relevant_cap && !(ckey(key) in GLOB.admin_datums)))
			to_chat(usr, "<span class='danger'>[CONFIG_GET(string/hard_popcap_message)]</span>")

			var/queue_position = SSticker.queued_players.Find(usr)
			if(queue_position == 1)
				to_chat(usr, "<span class='notice'>You are next in line to join the game. You will be notified when a slot opens up.</span>")
			else if(queue_position)
				to_chat(usr, "<span class='notice'>There are [queue_position-1] players in front of you in the queue to join the game.</span>")
			else
				SSticker.queued_players += usr
				to_chat(usr, "<span class='notice'>You have been added to the queue to join the game. Your position in queue is [SSticker.queued_players.len].</span>")
			return
		LateChoices()

	if(href_list["manifest"])
		ViewManifest()

	if(!ready && href_list["preference"])
		if(client)
			client.prefs.process_link(src, href_list)
	else if(!href_list["late_join"])
		new_player_panel()

	if(href_list["showpoll"])
		handle_player_polling()
		return

	if(href_list["viewpoll"])
		var/datum/poll_question/poll = locate(href_list["viewpoll"]) in GLOB.polls
		poll_player(poll)

	if(href_list["votepollref"])
		var/datum/poll_question/poll = locate(href_list["votepollref"]) in GLOB.polls
		vote_on_poll_handler(poll, href_list)

//When you cop out of the round (NB: this HAS A SLEEP FOR PLAYER INPUT IN IT)
/mob/dead/new_player/proc/make_me_an_observer()
	if(QDELETED(src) || !src.client)
		ready = PLAYER_NOT_READY
		return FALSE

	var/this_is_like_playing_right = alert(src,"Are you sure you wish to observe? You will not be able to play this round!","Player Setup","Yes","No")

	if(QDELETED(src) || !src.client || this_is_like_playing_right != "Yes")
		ready = PLAYER_NOT_READY
		src << browse(null, "window=playersetup") //closes the player setup window
		new_player_panel()
		return FALSE

	var/mob/dead/observer/observer = new()
	spawning = TRUE

	observer.started_as_observer = TRUE
	close_spawn_windows()
	var/obj/effect/landmark/observer_start/O = locate(/obj/effect/landmark/observer_start) in GLOB.landmarks_list
	to_chat(src, "<span class='notice'>Now teleporting.</span>")
	if (O)
		observer.forceMove(O.loc)
	observer.key = key
	observer.client = client
	observer.set_ghost_appearance()
	if(observer.client && observer.client.prefs)
		observer.real_name = observer.client.prefs.real_name
		observer.name = observer.real_name
		observer.client.init_verbs()
	observer.update_icon()
	observer.stop_sound_channel(CHANNEL_LOBBYMUSIC)
	deadchat_broadcast(" has observed.", "<b>[observer.real_name]</b>", follow_target = observer, turf_target = get_turf(observer), message_type = DEADCHAT_DEATHRATTLE)
	QDEL_NULL(mind)
	qdel(src)
	return TRUE

/proc/get_job_unavailable_error_message(retval, jobtitle)
	switch(retval)
		if(JOB_AVAILABLE)
			return "[jobtitle] is available."
		if(JOB_UNAVAILABLE_GENERIC)
			return "[jobtitle] is unavailable."
		if(JOB_UNAVAILABLE_BANNED)
			return "You are currently banned from [jobtitle]."
		if(JOB_UNAVAILABLE_PLAYTIME)
			return "You do not have enough relevant playtime for [jobtitle]."
		if(JOB_UNAVAILABLE_ACCOUNTAGE)
			return "Your account is not old enough for [jobtitle]."
		if(JOB_UNAVAILABLE_SLOTFULL)
			return "[jobtitle] is already filled to capacity."
	return "Error: Unknown job availability."

/mob/dead/new_player/proc/IsJobUnavailable(datum/job/job, obj/structure/overmap/ship/simulated/ship, latejoin = FALSE)
	if(!job)
		return JOB_UNAVAILABLE_GENERIC
	if(!(ship?.job_slots[job] > 0))
		return JOB_UNAVAILABLE_SLOTFULL
	if(is_banned_from(ckey, job.title))
		return JOB_UNAVAILABLE_BANNED
	if(QDELETED(src))
		return JOB_UNAVAILABLE_GENERIC
	if(!job.player_old_enough(client))
		return JOB_UNAVAILABLE_ACCOUNTAGE
	if(job.required_playtime_remaining(client))
		return JOB_UNAVAILABLE_PLAYTIME
	if(latejoin && !job.special_check_latejoin(client))
		return JOB_UNAVAILABLE_GENERIC
	return JOB_AVAILABLE

/mob/dead/new_player/proc/AttemptLateSpawn(datum/job/job, obj/structure/overmap/ship/simulated/ship)
	. = TRUE
	if (isnull(ship) || isnull(ship.shuttle))
		stack_trace("Tried to spawn ([ckey]) into a null ship! Please report this on Github.")
		return FALSE
	var/error = IsJobUnavailable(job, ship)
	if(error != JOB_AVAILABLE)
		alert(src, get_job_unavailable_error_message(error, job))
		return FALSE

	if(SSticker.late_join_disabled)
		alert(src, "An administrator has disabled late join spawning.")
		return FALSE

	//Removes a job slot
	ship.job_slots[job]--

	//Remove the player from the join queue if he was in one and reset the timer
	SSticker.queued_players -= src
	SSticker.queue_delay = 4

	SSjob.AssignRole(src, job, 1)

	var/mob/living/character = create_character(TRUE)	//creates the human and transfers vars and mind
	var/equip = job.EquipRank(character)
	if(isliving(equip))	//Borgs get borged in the equip, so we need to make sure we handle the new mob.
		character = equip

	if(job && !job.override_latejoin_spawn(character))
		SSjob.SendToLateJoin(character, destination = pick(ship.shuttle.spawn_points))
		var/atom/movable/screen/splash/Spl = new(character.client, TRUE)
		Spl.Fade(TRUE)
		character.playsound_local(get_turf(character), 'sound/voice/ApproachingTG.ogg', 25)

		character.update_parallax_teleport()

	SSticker.minds += character.mind
	character.client.init_verbs() // init verbs for the late join
	var/mob/living/carbon/human/humanc
	if(ishuman(character))
		humanc = character	//Let's retypecast the var to be human,

	if(humanc)	//These procs all expect humans
		ship.manifest_inject(humanc, client, job)
		GLOB.data_core.manifest_inject(humanc, client)
		AnnounceArrival(humanc, job.title, ship)
		NotifyFaction(humanc, ship)
		AddEmploymentContract(humanc)

		if(GLOB.highlander)
			to_chat(humanc, "<span class='userdanger'><i>THERE CAN BE ONLY ONE!!!</i></span>")
			humanc.make_scottish()
		if(GLOB.summon_guns_triggered)
			give_guns(humanc)
		if(GLOB.summon_magic_triggered)
			give_magic(humanc)
		if(GLOB.curse_of_madness_triggered)
			give_madness(humanc, GLOB.curse_of_madness_triggered)

	GLOB.joined_player_list += character.ckey

	if(humanc && CONFIG_GET(flag/roundstart_traits))
		SSquirks.AssignQuirks(humanc, humanc.client, TRUE)

	log_manifest(character.mind.key, character.mind, character, TRUE)
	log_shuttle("[character.mind.key] / [character.mind.name] has joined [ship.display_name] as [job.title]")

	if(length(ship.job_slots) > 1 && ship.job_slots[1] == job) // if it's the "captain" equivalent job of the ship. checks to make sure it's not a one-job ship
		minor_announce("[job.title] [character.real_name] on deck!", zlevel = ship.shuttle.virtual_z())

/mob/dead/new_player/proc/AddEmploymentContract(mob/living/carbon/human/employee)
	//TODO:  figure out a way to exclude wizards/nukeops/demons from this.
	for(var/C in GLOB.employmentCabinets)
		var/obj/structure/filingcabinet/employment/employmentCabinet = C
		if(!employmentCabinet.virgin)
			employmentCabinet.addFile(employee)

/mob/dead/new_player/proc/LateChoices()

	var/balance = usr.client.get_metabalance()
	var/list/shuttle_choices = list("Purchase ship..." = "Purchase") //Dummy for purchase option

	for(var/obj/structure/overmap/ship/simulated/S as anything in SSovermap.simulated_ships)
		if(isnull(S.shuttle))
			continue
		if((length(S.shuttle.spawn_points) < 1) || !S.join_allowed)
			continue
		shuttle_choices["[isnull(S.password) ? "" : "(L) "]" + S.display_name + " ([S.source_template.short_name ? S.source_template.short_name : "Unknown-class"])"] = S //Try to get the class name

	var/obj/structure/overmap/ship/simulated/selected_ship = shuttle_choices[tgui_input_list(src, "Select ship to spawn on.", "Welcome, [client?.prefs.real_name || "User"].", shuttle_choices)]
	if(!selected_ship)
		return

	if(selected_ship == "Purchase")
		if (!GLOB.ship_buying)
			alert(src, "Buying ships is disabled!")
			return LateChoices()
		var/datum/map_template/shuttle/template = SSmapping.ship_purchase_list[tgui_input_list(src, "Please select ship to purchase!", "Welcome, [client.prefs.real_name].", SSmapping.ship_purchase_list)]
		if(!template)
			return LateChoices()
		if(SSdbcore.IsConnected() && balance < template.cost)
			alert(src, "You have insufficient metabalance to cover this purchase! (Price: [template.cost] | Balance: [balance])")
			return LateChoices()
		if(template.limit)
			var/count = 0
			for(var/obj/structure/overmap/ship/simulated/X in SSovermap.simulated_ships)
				if(X.source_template == template)
					count++
					if(template.limit <= count)
						alert(src, "The ship limit of [template.limit] has been reached this round.")
						return
		//Password creation
		var/password = ""
		var/total_cost = template.cost
		if (!template.disable_passwords)
			var/password_cost = template.get_password_cost()
			// Prompt for password purchasing
			var/password_choice = tgui_alert(src, "Enable password protection for [password_cost] voidcoins", "Password Protection", list("Yes", "No"))
			if(password_choice == null)
				return LateChoices()
			if(password_choice == "Yes")
				total_cost += password_cost
				if(SSdbcore.IsConnected() && balance < total_cost)
					alert(src, "You have insufficient metabalance to cover this purchase! (Price: [total_cost] | Balance: [balance])")
					return LateChoices()
				password = stripped_input(src, "Enter your new ship password.", "New Password")
				if(!password || !length(password))
					return LateChoices()
				if(length(password) > 50)
					to_chat(src, "The given password is too long. Password unchanged.")
					return LateChoices()

		close_spawn_windows()
		to_chat(usr, "<span class='danger'>Your [template.name] is being prepared. Please be patient!</span>")
		var/obj/docking_port/mobile/target = SSshuttle.load_template(template)
		if(!istype(target))
			to_chat(usr, "<span class='danger'>There was an error loading the ship (You have not been charged). Please contact admins!</span>")
			new_player_panel()
			return
		//Withdraw coins for the purchase
		usr.client.inc_metabalance(-total_cost, TRUE, "buying [template.name]")
		SSblackbox.record_feedback("tally", "ship_purchased", 1, template.name) //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
		if(!AttemptLateSpawn(target.current_ship.job_slots[1], target.current_ship)) //Try to spawn as the first listed job in the job slots (usually captain)
			to_chat(usr, "<span class='danger'>Ship spawned, but you were unable to be spawned. You can likely try to spawn in the ship through joining normally, but if not, please contact an admin.</span>")
			new_player_panel()
		//Password assignment
		if (password != "")
			target.current_ship.password = password
			log_shuttle("[key_name(usr)] has password locked their ship ([target.current_ship.display_name]) with the password: [target.current_ship.password]")
		return

	//password checking
	if(!isnull(selected_ship.password))
		var/attempt = stripped_input(src, "Enter the ship's password!", "Enter Password")
		if (attempt != selected_ship.password)
			to_chat(src, "Incorrect password!")
			return LateChoices() //Send them back to shuttle selection

	if(selected_ship.memo)
		var/memo_accept = tgui_alert(src, "Current ship memo: [selected_ship.memo]", "[selected_ship.name] Memo", list("OK", "Cancel"))
		if(memo_accept == "Cancel")
			return LateChoices() //Send them back to shuttle selection

	var/list/job_choices = list()
	for(var/datum/job/job as anything in selected_ship.job_slots)
		if(selected_ship.job_slots[job] < 1)
			continue
		job_choices["[job.title] ([selected_ship.job_slots[job]] positions)"] = job

	if(!length(job_choices))
		to_chat(usr, "<span class='danger'>There are no jobs available on this ship!</span>")
		return LateChoices() //Send them back to shuttle selection

	var/datum/job/selected_job = job_choices[tgui_input_list(src, "Select job.", "Welcome, [client.prefs.real_name].", job_choices)]
	if(!selected_job)
		return LateChoices() //Send them back to shuttle selection

	if(!SSticker?.IsRoundInProgress())
		to_chat(usr, "<span class='danger'>The round is either not ready, or has already finished...</span>")
		return

	if(!GLOB.enter_allowed)
		to_chat(usr, "<span class='notice'>There is an administrative lock on entering the game!</span>")
		return

	var/relevant_cap
	var/hpc = CONFIG_GET(number/hard_popcap)
	var/epc = CONFIG_GET(number/extreme_popcap)
	if(hpc && epc)
		relevant_cap = min(hpc, epc)
	else
		relevant_cap = max(hpc, epc)

	if(SSticker.queued_players.len && !(ckey(key) in GLOB.admin_datums))
		if((living_player_count() >= relevant_cap) || (src != SSticker.queued_players[1]))
			to_chat(usr, "<span class='warning'>Server is full.</span>")
			return

	AttemptLateSpawn(selected_job, selected_ship)

/mob/dead/new_player/proc/create_character(transfer_after)
	spawning = 1
	close_spawn_windows()

	var/mob/living/carbon/human/H = new(loc)

	var/frn = CONFIG_GET(flag/force_random_names)
	var/admin_anon_names = SSticker.anonymousnames
	if(!frn)
		frn = is_banned_from(ckey, "Appearance")
		if(QDELETED(src))
			return
	if(frn)
		client.prefs.random_character()
		client.prefs.real_name = client.prefs.pref_species.random_name(gender,1)

	if(admin_anon_names)//overrides random name because it achieves the same effect and is an admin enabled event tool
		client.prefs.random_character()
		client.prefs.real_name = anonymous_name(src)

	var/is_antag
	if(mind in GLOB.pre_setup_antags)
		is_antag = TRUE

	client.prefs.copy_to(H, antagonist = is_antag)
	H.dna.update_dna_identity()
	if(mind)
		if(transfer_after)
			mind.late_joiner = TRUE
		mind.active = 0					//we wish to transfer the key manually
		mind.transfer_to(H)					//won't transfer key since the mind is not active

	H.name = real_name
	client.init_verbs()
	. = H
	new_character = .
	if(transfer_after)
		transfer_character()

/mob/dead/new_player/proc/transfer_character()
	. = new_character
	if(.)
		new_character.key = key		//Manually transfer the key to log them in,
		new_character.stop_sound_channel(CHANNEL_LOBBYMUSIC)
		new_character = null
		qdel(src)

/mob/dead/new_player/proc/ViewManifest()
	if(!client)
		return
	if(world.time < client.crew_manifest_delay)
		return
	client.crew_manifest_delay = world.time + (1 SECONDS)

	if(!GLOB.crew_manifest_tgui)
		GLOB.crew_manifest_tgui = new /datum/crew_manifest(src)

	GLOB.crew_manifest_tgui.ui_interact(src)

/mob/dead/new_player/Move()
	return 0


/mob/dead/new_player/proc/close_spawn_windows()

	src << browse(null, "window=playersetup") //closes the player setup window
	src << browse(null, "window=preferences") //closes job selection
	src << browse(null, "window=mob_occupation")
	src << browse(null, "window=latechoices") //closes late job selection

// Used to make sure that a player has a valid job preference setup, used to knock players out of eligibility for anything if their prefs don't make sense.
// A "valid job preference setup" in this situation means at least having one job set to low, or not having "return to lobby" enabled
// Prevents "antag rolling" by setting antag prefs on, all jobs to never, and "return to lobby if preferences not availible"
// Doing so would previously allow you to roll for antag, then send you back to lobby if you didn't get an antag role
// This also does some admin notification and logging as well, as well as some extra logic to make sure things don't go wrong
/mob/dead/new_player/proc/check_preferences()
	if(!client)
		return FALSE //Not sure how this would get run without the mob having a client, but let's just be safe.
	if(client.prefs.joblessrole != RETURNTOLOBBY)
		return TRUE
	// If they have antags enabled, they're potentially doing this on purpose instead of by accident. Notify admins if so.
	var/has_antags = FALSE
	if(client.prefs.be_special.len > 0)
		has_antags = TRUE
	if(client.prefs.job_preferences.len == 0)
		if(!ineligible_for_roles)
			to_chat(src, "<span class='danger'>You have no jobs enabled, along with return to lobby if job is unavailable. This makes you ineligible for any round start role, please update your job preferences.</span>")
		ineligible_for_roles = TRUE
		ready = PLAYER_NOT_READY
		if(has_antags)
			log_admin("[src.ckey] just got booted back to lobby with no jobs, but antags enabled.")
			message_admins("[src.ckey] just got booted back to lobby with no jobs enabled, but antag rolling enabled. Likely antag rolling abuse.")

		return FALSE //This is the only case someone should actually be completely blocked from antag rolling as well
	return TRUE

/**
  * Prepares a client for the interview system, and provides them with a new interview
  *
  * This proc will both prepare the user by removing all verbs from them, as well as
  * giving them the interview form and forcing it to appear.
  */
/mob/dead/new_player/proc/register_for_interview()
	// First we detain them by removing all the verbs they have on client
	for (var/v in client.verbs)
		var/procpath/verb_path = v
		if (!(verb_path in GLOB.stat_panel_verbs))
			remove_verb(client, verb_path)

	// Then remove those on their mob as well
	for (var/v in verbs)
		var/procpath/verb_path = v
		if (!(verb_path in GLOB.stat_panel_verbs))
			remove_verb(src, verb_path)

	// Then we create the interview form and show it to the client
	var/datum/interview/I = GLOB.interviews.interview_for_client(client)
	if (I)
		I.ui_interact(src)

	// Add verb for re-opening the interview panel, and re-init the verbs for the stat panel
	add_verb(src, /mob/dead/new_player/proc/open_interview)
