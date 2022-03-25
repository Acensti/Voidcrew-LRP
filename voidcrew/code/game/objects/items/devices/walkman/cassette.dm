/obj/item/device/cassette_tape
	name = "Debug Cassette Tape"
	desc = "You shouldn't be seeing this!"
	icon = 'voidcrew/icons/obj/walkman.dmi'
	icon_state = "cassette_flip"
	w_class = WEIGHT_CLASS_SMALL
	///icon of the cassettes front side
	var/side1_icon = "cassette_worstmap"
	var/side2_icon = "cassette_worstmap"
	///if the cassette is flipped, for playing second list of songs
	var/flipped = FALSE
	///list of songs each side has to play
	var/list/songs = list("side1" = list(),
						  "side2" = list())
	///list of each songs name in the order they appear
	var/list/song_names = list("side1" = list(),
						 	   "side2" = list())
	///the id of the cassette
	var/id = "blank"
	//the cassette_tape type datum
	var/datum/cassette/cassette_tape/tape

/obj/item/device/cassette_tape/Initialize()
	. = ..()
	tape = new tape
	id = tape.id
	var/file = file("voidcrew/code/game/objects/items/devices/walkman/configs/[id].json")
	file = file2text(file)
	var/list/data = json_decode(file)
	name = data["name"]
	desc = data["desc"]
	icon_state = data["side1_icon"]
	side1_icon = data["side1_icon"]
	side2_icon = data["side2_icon"]
	songs = data["songs"]
	song_names = data["song_names"]
	qdel(tape)

/obj/item/device/cassette_tape/attack_self(mob/user)
	..()

	icon_state = flipped ? side1_icon : side2_icon
	flipped = !flipped
	to_chat(user,"You flip [src]")

/obj/item/device/cassette_tape/attackby(obj/item/item, mob/living/user)
	if(!istype(item, /obj/item/pen))
		return ..()
	var/choice = input("What would you like to change?") in list("Cassette Name", "Cassette Description", "Cancel")
	switch(choice)
		if("Cassette Name")
			///the name we are giving the cassette
			var/newcassettename = reject_bad_text(stripped_input(user, "Write a new Cassette name:", name, name))
			if(!user.canUseTopic(src, BE_CLOSE))
				return
			if (length(newcassettename) > 20)
				to_chat(user, "<span class='warning'>That name is too long!</span>")
				return
			if(!newcassettename)
				to_chat(user, "<span class='warning'>That name is invalid.</span>")
				return
			else
				name = "[lowertext(newcassettename)]"
		if("Cassette Description")
			///the description we are giving the cassette
			var/newdesc = stripped_input(user, "Write a new description:", name, desc)
			if(!user.canUseTopic(src, BE_CLOSE))
				return
			if (length(newdesc) > 180)
				to_chat(user, "<span class='warning'>That description is too long!</span>")
				return
			if(!newdesc)
				to_chat(user, "<span class='warning'>That description is invalid.</span>")
				return
			desc = newdesc
		else
			return

/datum/cassette/cassette_tape
	var/name = "Broken Cassette"
	var/desc = "You shouldn't be seeing this! Make an issue about it"
	var/icon_state = "cassette_flip"
	var/side1_icon = "cassette_flip"
	var/side2_icon = "cassette_flip"
	var/id = "blank"
	var/list/song_names = list("side1" = list(),
							   "side2" = list())

	var/list/songs = list("side1" = list(),
						  "side2" = list())

/datum/cassette/cassette_tape/blank
	id = "blank"

/obj/item/device/cassette_tape/blank
	tape = /datum/cassette/cassette_tape/blank

/datum/cassette/cassette_tape/friday
	id = "friday"

/obj/item/device/cassette_tape/friday
	tape = /datum/cassette/cassette_tape/friday
