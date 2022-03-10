/datum/biome/wasteland
	open_turf_types = list(/turf/open/floor/plating/wasteland/lit = 1)
	flora_spawn_list = list(
		/obj/structure/flora/rock/asteroid = 30,
		/obj/structure/flora/tree/dead/tall = 10,
		/obj/structure/flora/tree/dead_pine = 4,
		/obj/structure/flora/tree/dead_african = 1,
		/obj/structure/flora/rock = 10,
		/obj/structure/flora/cactus = 10
	)
	flora_spawn_chance = 5
	feature_spawn_list = list(
		/obj/item/bodypart/r_arm/robot = 40,
		/obj/item/assembly/prox_sensor = 40,
		/obj/effect/mine/explosive = 8,
		/obj/structure/geyser/random = 4,
		/obj/item/shard = 30,
		/obj/item/stack/cable_coil/cut = 30,
		/obj/item/stack/rods = 30,
		/obj/structure/elite_tumor = 1
	)
	feature_spawn_chance = 3
	mob_spawn_chance = 15
	mob_spawn_list = list(
		/mob/living/simple_animal/hostile/asteroid/whitesands/ranged/hunter = 10,
		/mob/living/simple_animal/hostile/asteroid/whitesands/ranged/gunslinger = 7,
		/mob/living/simple_animal/hostile/asteroid/whitesands = 15,
		/mob/living/simple_animal/hostile/hivebot/rapid/wasteland = 5,
		/mob/living/simple_animal/hostile/poison/giant_spider/wasteland = 5,
		/mob/living/simple_animal/hostile/poison/giant_spider/tarantula/wasteland = 1,
		/obj/structure/spawner/ice_moon/demonic_portal/blobspore = 1,
		/obj/structure/spawner/ice_moon/demonic_portal/hivebot = 1
	)

/datum/biome/wasteland/plains
	open_turf_types = list(/turf/open/floor/plating/dust/lit = 1)
	flora_spawn_list = list(/obj/structure/flora/deadgrass/tall = 50, /obj/structure/flora/deadgrass/tall/dense = 5, /obj/structure/flora/rock = 1)
	flora_spawn_chance = 45
	mob_spawn_chance = 25

/datum/biome/wasteland/forest
	open_turf_types = list(/turf/open/floor/plating/dirt/dry/lit = 1)
	flora_spawn_list = list(
		/obj/structure/flora/tree/dead/tall = 35,
		/obj/structure/flora/branches = 10,
		/obj/structure/flora/deadgrass = 80,
		/obj/structure/elite_tumor = 1,
		/obj/structure/flora/tree/dead_pine = 15,
		/obj/structure/flora/tree/dead_african = 4
	)
	flora_spawn_chance = 25

/datum/biome/nuclear
	open_turf_types = list(/turf/open/floor/plating/asteroid/sand/lit = 5, /turf/open/floor/plating/asteroid/sand/dark/lit = 1)
	feature_spawn_chance = 1
	feature_spawn_list = list(
		/obj/structure/radioactive = 1,
		/obj/structure/radioactive/stack = 1,
		/obj/structure/radioactive/waste = 1,
		/obj/item/stack/ore/slag = 1,
		/obj/structure/flora/cactus = 5
	)
	flora_spawn_chance = 1
	flora_spawn_list = list(/obj/structure/flora/rock = 30, /obj/effect/decal/cleanable/greenglow/glowy = 30, /obj/structure/elite_tumor = 1)
	mob_spawn_chance = 20
	mob_spawn_list = list(
		/mob/living/simple_animal/hostile/asteroid/whitesands/ranged/hunter = 10,
		/mob/living/simple_animal/hostile/asteroid/whitesands/ranged/gunslinger = 7,
		/mob/living/simple_animal/hostile/asteroid/whitesands = 15,
		/mob/living/simple_animal/hostile/hivebot/rapid/wasteland = 5,
		/mob/living/simple_animal/hostile/poison/giant_spider/wasteland = 5,
		/mob/living/simple_animal/hostile/poison/giant_spider/tarantula/wasteland = 1
	)

/datum/biome/ruins
	open_turf_types = list(/turf/open/floor/plating/dust/lit = 45, /turf/open/floor/plating/rust = 1)
	feature_spawn_chance = 5
	feature_spawn_list = list(
		/obj/structure/barrel/flaming = 3,
		/obj/structure/barrel = 5,
		/obj/structure/reagent_dispensers/fueltank = 3,
		/obj/item/shard = 6,
		/obj/item/stack/cable_coil/cut = 6,
		/obj/effect/mine/explosive = 1,
		/obj/item/reagent_containers/food/snacks/canned/beans = 1,
		/obj/structure/mecha_wreckage/ripley = 3,
		/obj/structure/mecha_wreckage/ripley/firefighter = 1,
		/obj/structure/mecha_wreckage/ripley/mkii = 1
	)
	flora_spawn_chance = 1
	flora_spawn_list = list(
		/obj/structure/girder = 1
	)
	mob_spawn_chance = 1
	mob_spawn_list = list(
		/mob/living/simple_animal/hostile/asteroid/hivelord/legion/wasteland = 15,
		/mob/living/simple_animal/hostile/asteroid/hivelord/legion/crystal/wasteland = 1,
		/mob/living/simple_animal/hostile/asteroid/basilisk/watcher/forgotten/wasteland = 1
	)

/datum/biome/cave/wasteland
	open_turf_types = list(/turf/open/floor/plating/dirt/dry = 1, /turf/open/floor/plating/dust = 1)
	closed_turf_types = list(/turf/closed/mineral/random/high_chance/wasteland = 1)
	mob_spawn_chance = 1
	mob_spawn_list = list(
		/mob/living/simple_animal/hostile/asteroid/fugu/wasteland = 1,
		/mob/living/simple_animal/hostile/bear/cave = 1,
		/mob/living/simple_animal/hostile/asteroid/wolf/wasteland/random = 1
	)
	flora_spawn_chance = 10
	flora_spawn_list = list(
		/obj/structure/flora/rock = 5,
		/obj/structure/flora/ash/leaf_shroom = 4,
		/obj/structure/flora/ash/cap_shroom = 4,
		/obj/structure/flora/ash/stem_shroom = 4,
		/obj/structure/flora/ash/cacti = 2,
		/obj/structure/flora/ash/tall_shroom = 4,
		/obj/structure/flora/ash/whitesands/puce = 1
	)
	feature_spawn_chance = 1
	feature_spawn_list = list(
		/obj/structure/spawner/cave = 20,
		/obj/structure/closet/crate/grave = 40,
		/obj/structure/closet/crate/grave/lead_researcher = 20,
		/obj/item/pickaxe/rusted = 40,
		/obj/item/pickaxe/diamond = 1,
		/obj/item/shovel/serrated = 30,
		/obj/structure/radioactive = 30,
		/obj/structure/radioactive/stack = 50,
		/obj/structure/radioactive/waste = 50,
		/obj/item/stack/ore/slag = 60
	)

/datum/biome/cave/rubble
	open_turf_types = list(/turf/open/floor/plating/rubble = 1, /turf/open/floor/plating/tunnel = 6)
	closed_turf_types = list(/turf/closed/wall/r_wall/rust = 1, /turf/closed/wall/rust = 4,/turf/closed/mineral/random/high_chance/wasteland = 10)
	feature_spawn_list = list(
		/obj/effect/spawner/lootdrop/maintenance = 10,
		/obj/item/stack/rods = 5,
		/obj/structure/closet/crate/secure/loot = 1,
		/obj/structure/spawner/cave = 2,
		/obj/structure/barrel/flaming = 2,
		/obj/structure/reagent_dispensers/fueltank = 2,
		/obj/structure/girder = 2,
		/obj/item/shard = 2,
		/obj/item/stack/cable_coil/cut = 2,
		/obj/effect/mine/explosive = 2,
		/obj/item/ammo_casing/caseless/arrow/bone = 2,
		/obj/item/healthanalyzer = 2,
		/obj/item/storage/firstaid = 2
	)
	feature_spawn_chance = 5
	flora_spawn_list = list(/obj/structure/flora/rock = 1)
	flora_spawn_chance = 1
	mob_spawn_chance = 5
	mob_spawn_list = list(
		/mob/living/simple_animal/hostile/poison/giant_spider/tarantula/wasteland = 1,
		/mob/living/simple_animal/hostile/asteroid/goliath/beast/wasteland = 5,
		/mob/living/simple_animal/hostile/asteroid/goliath/beast/ancient/wasteland = 2
	)

/datum/biome/cave/mossy_stone
	open_turf_types = list(/turf/open/floor/plating/mossy_stone = 5, /turf/open/floor/plating/dirt/dry = 1)
	feature_spawn_list = list(
		/obj/effect/decal/cleanable/greenglow = 30,
		/obj/machinery/portable_atmospherics/canister/toxins = 15,
		/obj/machinery/portable_atmospherics/canister/miasma = 15,
		/obj/machinery/portable_atmospherics/canister/carbon_dioxide = 15,
		/obj/structure/barrel/flaming = 20,
		/obj/structure/geyser/random = 1,
		/obj/structure/spawner/cave = 5
	)
	feature_spawn_chance = 5
	flora_spawn_list = list(
		/obj/structure/flora/glowshroom = 20,
	)
	flora_spawn_chance = 30
	mob_spawn_chance = 5
	mob_spawn_list = list(
		/mob/living/simple_animal/hostile/blob/blobbernaut/independent/wasteland = 1,
		/mob/living/simple_animal/hostile/asteroid/basilisk/watcher/magmawing/wasteland = 4,
		/mob/living/simple_animal/hostile/asteroid/goldgrub = 3,
		/mob/living/simple_animal/hostile/asteroid/hivelord/legion/wasteland = 3
	)
