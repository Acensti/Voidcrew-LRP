/datum/revamped_biome/jungle
	open_turf_types = list(/turf/open/floor/plating/grass/jungle/lit = 1)
	flora_spawn_list = list(
		/obj/structure/flora/grass/jungle = 1,
		/obj/structure/flora/grass/jungle/b = 1,
		/obj/structure/flora/tree/jungle = 1,
		/obj/structure/flora/rock/jungle = 1,
		/obj/structure/flora/junglebush = 1,
		/obj/structure/flora/junglebush/b = 1,
		/obj/structure/flora/junglebush/c = 1,
		/obj/structure/flora/junglebush/large = 1
	)
	flora_spawn_chance = 20
	mob_spawn_chance = 0.05
	mob_spawn_list = list(/mob/living/simple_animal/hostile/gorilla = 1)

/datum/revamped_biome/jungle/dense
	flora_spawn_chance = 30
	open_turf_types = list(/turf/open/floor/plating/grass/jungle = 1, /turf/open/floor/plating/dirt/jungle/wasteland = 1)

/datum/revamped_biome/jungle/plains
	open_turf_types = list(/turf/open/floor/plating/grass/jungle/lit = 1)
	// flora_spawn_chance = 10
	mob_spawn_chance = 1
	mob_spawn_list = list(/mob/living/carbon/monkey = 0.7)

/datum/revamped_biome/mudlands
	open_turf_types = list(/turf/open/floor/plating/dirt/jungle/dark/lit = 1)
	flora_spawn_list = list(/obj/structure/flora/grass/jungle = 1, /obj/structure/flora/grass/jungle/b = 1, /obj/structure/flora/rock/jungle = 1)
	flora_spawn_chance = 3
	mob_spawn_chance = 0.05
	mob_spawn_list = list(/mob/living/simple_animal/hostile/poison/giant_spider/tarantula = 1)

/datum/revamped_biome/wasteland
	open_turf_types = list(/turf/open/floor/plating/dirt/jungle/wasteland/lit = 1)

/datum/revamped_biome/water
	open_turf_types = list(/turf/open/water/jungle/lit = 1)
	mob_spawn_chance = 1
	mob_spawn_list = list(/mob/living/simple_animal/hostile/carp = 1)

/datum/revamped_biome/cave/jungle
	open_turf_types = list(/turf/open/floor/plating/dirt/jungle = 10, /turf/open/floor/plating/dirt/jungle/dark = 10)
	flora_spawn_chance = 5
	flora_spawn_list = list(
		/obj/structure/flora/rock/jungle = 1,
		/obj/structure/flora/rock/pile = 1,
		/obj/structure/flora/rock = 1,
		/obj/structure/flora/ash/space = 1,
		/obj/structure/flora/ash/leaf_shroom = 1,
		/obj/structure/flora/ash/cap_shroom = 1,
		/obj/structure/flora/ash/stem_shroom = 0.5,
		/obj/structure/flora/ash/whitesands/puce = 0.5

	)
	mob_spawn_chance = 1
	mob_spawn_list = list(/mob/living/simple_animal/hostile/asteroid/wolf/random = 1, /mob/living/simple_animal/hostile/retaliate/bat = 1, /mob/living/simple_animal/hostile/retaliate/poison/snake)
	feature_spawn_chance = 1
	feature_spawn_list = list(/obj/item/pickaxe/rusted = 1, /obj/structure/closet/crate/grave/lead_researcher = 0.3, /obj/structure/closet/crate/grave = 0.5, /obj/item/shovel = 1, /obj/structure/closet/crate/secure/loot = 0.1)

/datum/revamped_biome/cave/jungle/dirt
	open_turf_types = list(/turf/open/floor/plating/dirt/jungle/wasteland = 1)
	flora_spawn_list = list(
		/obj/structure/flora/junglebush = 1,
		/obj/structure/flora/junglebush/b = 1,
		/obj/structure/flora/junglebush/c = 1,
		/obj/structure/flora/junglebush/large = 1,
		/obj/structure/flora/rock/pile/largejungle = 1,
		/obj/structure/flora/grass/jungle = 1,
		/obj/structure/flora/grass/jungle/b = 1,
	)

/datum/revamped_biome/cave/lush
	open_turf_types = list(/turf/open/floor/plating/grass/jungle = 1)
	flora_spawn_chance = 25
	flora_spawn_list = list(
		/obj/structure/flora/tree/jungle/small = 1,
		/obj/structure/flora/ausbushes/brflowers = 1,
		/obj/structure/flora/ausbushes/fernybush = 1,
		/obj/structure/flora/ausbushes/fullgrass = 1,
		/obj/structure/flora/ausbushes/genericbush = 1,
		/obj/structure/flora/ausbushes/grassybush = 1,
		/obj/structure/flora/ausbushes/lavendergrass = 1,
		/obj/structure/flora/ausbushes/lavendergrass = 1,
		/obj/structure/flora/ausbushes/leafybush = 1,
		/obj/structure/flora/ausbushes/palebush = 1,
		/obj/structure/flora/ausbushes/pointybush = 1,
		/obj/structure/flora/ausbushes/ppflowers = 1,
		/obj/structure/flora/ausbushes/reedbush = 1,
		/obj/structure/flora/ausbushes/sparsegrass = 1,
		/obj/structure/flora/ausbushes/stalkybush = 1,
		/obj/structure/flora/ausbushes/stalkybush = 1,
		/obj/structure/flora/ausbushes/sunnybush = 1,
		/obj/structure/flora/ausbushes/ywflowers = 1,
		/obj/structure/spacevine = 1,
		/obj/structure/flora/rock/jungle = 1,
		/obj/structure/flora/ash/space/voidmelon = 1
	)
	mob_spawn_chance = 1
	mob_spawn_list = list(/mob/living/simple_animal/hostile/poison/bees/toxin = 0.8, /mob/living/simple_animal/hostile/mushroom = 1, /mob/living/simple_animal/slime/pet = 0.7)

/datum/revamped_biome/cave/lush/bright
	open_turf_types = list(/turf/open/floor/plating/grass/jungle/lit = 12, /turf/open/water/jungle/lit = 1)
	flora_spawn_chance = 40
	mob_spawn_chance = 1
	mob_spawn_list = list(/mob/living/simple_animal/slime/random = 1, /mob/living/simple_animal/hostile/lightgeist = 1)
	feature_spawn_chance = 0.1
	feature_spawn_list = list(/obj/item/rod_of_asclepius = 1)

// /datum/revamped_biome/cave/scorching

// /datum/revamped_biome/cave/plasma

// /datum/revamped_biome/cave/spooky

// /datum/revamped_biome/cave/cult


