/obj/machinery/cassette/adv_cassette_deck
	name = "Advanced Cassette Deck"
	desc = "A more advanced less portable Cassette Deck. Useful for recording songs from our generation, or customizing the style of your cassettes."
	icon = 'voidcrew/icons/obj/machines/adv_cassette_deck.dmi'
	icon_state = "cassette_deck"
	density = TRUE
	pass_flags = PASSTABLE
	///cassette tape used in adding songs or customizing
	var/obj/item/device/cassette_tape/tape
	///Selection used to add the jukebox as a song to a cassette
	var/datum/track/selection = null

/obj/machinery/cassette/adv_cassette_deck/wrench_act(mob/living/user, obj/item/wrench)
	..()
	default_unfasten_wrench(user, wrench, 15)
	return TRUE

/obj/machinery/cassette/adv_cassette_deck/attackby(obj/item/cassette, mob/user)
	if(!istype(cassette, /obj/item/device/cassette_tape))
		return ..()
	if(!tape)
		insert_tape(cassette)
		playsound(src,'sound/weapons/handcuffs.ogg',20,1)
		to_chat(user,"You insert \the [cassette] into \the [src]")
	else
		to_chat(user,"Remove a tape first!")

/obj/machinery/cassette/adv_cassette_deck/proc/insert_tape(obj/item/device/cassette_tape/CTape)
	if(tape || !istype(CTape))
		return
	tape = CTape
	CTape.forceMove(src)

/obj/machinery/cassette/adv_cassette_deck/proc/eject_tape(mob/user)
	if(!tape)
		return
	user.put_in_hands(tape)
	tape = null

/obj/machinery/cassette/adv_cassette_deck/ui_status(mob/user)
	if(!anchored)
		to_chat(user,"<span class='warning'>This device must be anchored by a wrench!</span>")
		return UI_CLOSE
	if(!allowed(user) && !isobserver(user))
		to_chat(user,"<span class='warning'>Error: Access Denied.</span>")
		user.playsound_local(src, 'sound/misc/compiler-failure.ogg', 25, TRUE)
		return UI_CLOSE
	return ..()

/obj/machinery/cassette/adv_cassette_deck/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "adv_cassette_deck", name)
		ui.open()

/obj/machinery/cassette/adv_cassette_deck/ui_data(mob/user)
	///all data for the tgui
	var/list/data = list()
	data["songs"] = list()
	for(var/datum/track/song in SSjukeboxes.songs)
		///all track data also for the tgui
		var/list/track_data = list(
			name = song.song_name
		)
		data["songs"] += list(track_data)
	data["track_selected"] = null
	if(selection)
		data["track_selected"] = selection.song_name
	return data

/obj/machinery/cassette/adv_cassette_deck/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("toggle")
			if(QDELETED(src))
				return
			if(!tape)
				to_chat(usr,"Error: No Cassette Inserted Please Insert a Cassette!")
				return
			if(!selection)
				to_chat(usr,"Error: No Song Selected, Please select a song")
				return
			if(tape.flipped == FALSE)
				if(length(tape.songs["side1"]) >= 7)
					to_chat(usr, "Error: Cassette full please flip or insert a new cassette")
				tape.songs["side1"] += selection.song_path
				tape.song_names["side1"] += selection.song_name
			else
				if(length(tape.songs["side2"]) >= 7)
					to_chat(usr, "Error: Cassette full please flip or insert a new cassette")
				tape.songs["side2"] += selection.song_path
				tape.song_names["side2"] += selection.song_name
		if("select_track")
			///list of available songs
			var/list/available = list()
			for(var/datum/track/song in SSjukeboxes.songs)
				available[song.song_name] = song
			///the selected song from the jukebox
			var/selected = params["track"]
			selection = available[selected]
			return TRUE
		if("eject")
			if(!tape)
				to_chat(usr,"Error: No Cassette Inserted Please Insert a Cassette!")
				return
			eject_tape(usr)
			return
		if("url")
			///the input of the videos ID
			var/url = stripped_input(usr, "Insert the ID of the video in question (characters after the =):", no_trim = TRUE)
			///the REGEX used for determining if its a valid ID or not
			var/static/regex/link_check = regex(@"^[a-zA-Z0-9_.-]{11}$")
			if(!link_check.Find(url))
				to_chat(usr, "Error: Bad ID!")
				return
			///The Finished url to add to the song list
			var/url_stuck = "https://www.youtube.com/watch?v=[url]"
			///invoking youtube-dl
			var/ytdl = CONFIG_GET(string/invoke_youtubedl)
			/// all the extra data youtube-dl gives us we are only interested in the title however
			var/list/music_extra_data = list()
			///trimming the url to prevent any missed errors
			var/url2 = trim(url_stuck)
			///scrub the url before passing it through a shell
			var/shell_scrubbed_input = shell_url_scrub(url2)
			///the command being sent to the shell after being scrubbed
			var/list/output = world.shelleo("[ytdl] --max-filesize 10m --extract-audio --geo-bypass --format \"bestaudio\[ext=mp3]/best\[ext=mp4]\[height<=360]/bestaudio\[ext=m4a]/bestaudio\[ext=aac]\" --dump-single-json --no-playlist -- \"[shell_scrubbed_input]\"")
			///any shell errors
			var/errorlevel = output[SHELLEO_ERRORLEVEL]
			///shell output
			var/stdout = output[SHELLEO_STDOUT]
			///list for all the youtube-dl data
			var/list/data
			if(!errorlevel)
				try
					data = json_decode(stdout)
				catch(var/exception/error) /// any errors are caught here
					CRASH("<span class='warning'>[error]: [stdout]</span>")
				if (data["url"])
					music_extra_data["title"] = data["title"]
			if(tape.flipped == FALSE)
				if(length(tape.songs["side1"]) >= 7)
					return
				tape.songs["side1"] += url_stuck
				tape.song_names["side1"] += data["title"]
			else
				if(length(tape.songs["side1"]) >= 7)
					return
				tape.songs["side2"] += url_stuck
				tape.song_names["side2"] += data["title"]

		if("design")
			if(!tape)
				to_chat(usr,"Error: No Cassette Inserted Please Insert a Cassette!")
				return
			///design paths for the designer used to add a sticker to cassettes
			var/list/design_path = list("cassette_flip",\
								"cassette_blue",\
								"cassette_gray",\
								"cassette_green",\
								"cassette_orange",\
								"cassette_pink_stripe",\
								"cassette_purple",\
								"cassette_rainbow",\
								"cassette_red_black",\
								"cassette_red_stripe",\
								"cassette_camo",\
								"cassette_rising_sun",\
								"cassette_ocean",\
								"cassette_aesthetic",)
			///design names for the tgui so its not ugly
			var/list/design_names = list("Blank Cassette",
							"Blue Sticker",\
							"Gray Sticker",\
							"Green Sticker",\
							"Orange Sticker",\
							"Pink Stripped Sticker",\
							"Purple Sticker",\
							"Rainbow Sticker",\
							"Red and Black Sticker",\
							"Red Stripped Sticker",\
							"Camo Sticker",\
							"Rising Sun Sticker",\
							"Ocean Sticker",\
							"Aesthetic Sticker")
			///the input list to choose which sticker to add to the cassette
			var/selection = tgui_input_list(usr, "Choose Your Sticker", "Advanced Cassette Deck", design_names)
			if(tape.flipped == FALSE)
				tape.icon_state = design_path[design_names.Find(selection)]
				tape.side1_icon = design_path[design_names.Find(selection)]
			else
				tape.icon_state = design_path[design_names.Find(selection)]
				tape.side2_icon = design_path[design_names.Find(selection)]
