/obj/tgvehicle/clowncar
	name = "Clown Car"
	desc = "How someone could fit in there is beyond me."
	icon_state = "clowncar"
	max_integrity = 200
	armor = list(
		melee = 70,
		bullet = 40,
		laser = 40,
		bomb = 30,
		fire = 80,
		acid = 80)
	max_occupants = 50
	car_traits = CAN_KIDNAP
	key_type = /obj/item/bikehorn
	///Sound file(s) to play when we drive around
	var/engine_sound = 'sound/effects/cars/carrev.ogg'
	///Set this to the length of the engine sound.
	var/engine_sound_length = 2 SECONDS
	///Time it takes to break out of the car.
	var/escape_time = 6 SECONDS
	///Cooldown time inbetween [/obj/vehicle/sealed/car/clowncar/proc/roll_the_dice()] usages
	var/dice_cooldown_time = 150
	///How many times kidnappers in the clown car said thanks
	var/thankscount = 0
	///Current status of the cannon, alternates between CLOWN_CANNON_INACTIVE, CLOWN_CANNON_BUSY and CLOWN_CANNON_READY
	var/cannonmode = CLOWN_CANNON_INACTIVE
	///Does the driver require the clown role to drive it
	var/enforce_clown_role = TRUE
	var/driver_user
	var/brakes = FALSE // Prevents movement
	var/last_emag_button_use = 0
	var/enter_delay = 20

/datum/component/riding/vehicle/clowncar
	vehicle_move_delay = 0.6
	override_allow_spacemove = TRUE
	ride_check_flags = RIDER_NEEDS_LEGS | UNBUCKLE_DISABLED_RIDER
/datum/component/riding/vehicle/clowncar/RegisterWithParent()
	. = ..()
/obj/tgvehicle/clowncar/Initialize(mapload)
	. = ..()
	make_ridable()

/obj/tgvehicle/clowncar/Move(newloc, dir)
	if(!COOLDOWN_FINISHED(src, cooldown_vehicle_move))
		return FALSE
	COOLDOWN_START(src, cooldown_vehicle_move, 0.6)

	if(COOLDOWN_FINISHED(src, enginesound_cooldown))
		COOLDOWN_START(src, enginesound_cooldown, engine_sound_length)
		playsound(get_turf(src), engine_sound, 100, TRUE)
	. = ..()

/obj/tgvehicle/clowncar/proc/make_ridable()
	AddElement(/datum/element/ridable, /datum/component/riding/vehicle/clowncar)

/obj/tgvehicle/clowncar/generate_actions()
	. = ..()
	initialize_controller_action_type(/datum/action/vehicle/dump_kidnapped_mobs, VEHICLE_CONTROL_DRIVE)
	initialize_controller_action_type(/datum/action/vehicle/clowncar/climb_out, VEHICLE_CONTROL_DRIVE)
	initialize_controller_action_type(/datum/action/vehicle/clowncar/honk, VEHICLE_CONTROL_DRIVE)
	initialize_controller_action_type(/datum/action/vehicle/headlights, VEHICLE_CONTROL_DRIVE)
	initialize_controller_action_type(/datum/action/vehicle/thank, VEHICLE_CONTROL_KIDNAPPED)

/obj/tgvehicle/clowncar/auto_assign_occupant_flags(mob/M) //override for each type that needs it. Default is assign driver if drivers is not at max.
	if(driver_amount() < max_drivers)
		var/mob/living/carbon/human/potential_occupant = M
		if(max_drivers == 1)
			driver_user = potential_occupant

		if(potential_occupant.job == "Clown" || !enforce_clown_role) // This could cause issues if the clown renames their job. Oh well.
			add_control_flags(M, VEHICLE_CONTROL_DRIVE)
		else
			playsound(src, 'sound/machines/deniedbeep.ogg', 50, FALSE, 3)
			add_control_flags(M, VEHICLE_CONTROL_KIDNAPPED)
		return
	if(car_traits & CAN_KIDNAP)
		add_control_flags(M,VEHICLE_CONTROL_KIDNAPPED)
		return
/obj/tgvehicle/clowncar/Bump(atom/bumped_atom)
	. = ..()
	if(isliving(bumped_atom)) // Are they a living being?
		if(ismegafauna(bumped_atom))
			return //no..
		var/mob/hittarget_living = bumped_atom

		if(iscarbon(hittarget_living)) // Human?
			var/mob/living/carbon/carbonperson = hittarget_living
			carbonperson.Paralyse(4 SECONDS)

		mob_forced_enter(hittarget_living)
		playsound(src, pick('sound/effects/cars/clowncar_ram1.ogg', 'sound/effects/cars/clowncar_ram2.ogg', 'sound/effects/cars/clowncar_ram3.ogg'), 75)
		hittarget_living.visible_message("<span class='warning'> [src] rams into [hittarget_living], sucking [hittarget_living.p_their()] up!")
		return
	if(istype(bumped_atom,/obj/machinery/door/))
		var/obj/machinery/door/bumped_door = bumped_atom
		if(density && !emagged)
			if(allowed(driver_user))
				return
	visible_message("<span class='warning'>[src] rams into [bumped_atom] and crashes!</span>")
	playsound(src, pick('sound/effects/cars//clowncar_crash1.ogg', 'sound/effects/cars//clowncar_crash2.ogg'), 75)
	playsound(src, 'sound/effects/cars//clowncar_crashpins.ogg', 75)
	dump_mobs(TRUE)

/obj/tgvehicle/clowncar/proc/increment_thanks_counter()
	thankscount++
	if(thankscount < 100)
		return
	to_chat(driver_user, "<span class='warning'>Congrats! For spreading so much joy, you have been rewarded 10 Play Coins!</span>")
	to_chat(driver_user, "<span class='warning'>Your 10 Play Coins have immediately been redeemed for the Uber Funny DLC®. A panel with 6 buttons has revealed itself!</span>")
	purchase_dlc()
	// TODO, unlock EMAG features on 100 thanks!
/obj/tgvehicle/clowncar/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	. = ..()
	if(prob(33))
		visible_message("<span class='warning'>[src] spews out a ton of space lube!</span>")
		var/datum/effect_system/foam_spread/foam = new()
		var/datum/reagents/foamreagent = new /datum/reagents(25)
		foamreagent.add_reagent(/datum/reagent/lube, 25)
		foam.set_up(40, loc, foamreagent)
		foam.start()

/obj/tgvehicle/clowncar/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	if(!istype(I, /obj/item/food/grown/banana))
		return
	var/obj/item/food/grown/banana/banana = I

	obj_integrity += min(banana.seed.potency, max_integrity-obj_integrity)
	to_chat(user, "<span class='warning'>You use the [banana] to repair [src]!</span>")
	qdel(banana)

/obj/tgvehicle/clowncar/proc/dump_mobs(randomstep = TRUE)
	for(var/i in occupants)
		mob_exit(i, randomstep = randomstep)
		if(iscarbon(i))
			var/mob/living/carb = i
			carb.KnockDown(40)

/obj/tgvehicle/clowncar/MouseDrop_T(mob/living/M, mob/living/user)
	. = ..()
	if(M == user)
		mob_try_enter(M)


/obj/tgvehicle/clowncar/proc/mob_try_enter(mob/rider)
	if(!istype(rider))
		return FALSE
	if (do_after(rider, enter_delay, src))
		mob_enter(rider)
		return TRUE
	return FALSE

/obj/tgvehicle/clowncar/proc/mob_enter(mob/M, silent = FALSE)
	if(!istype(M))
		return FALSE
	if(!silent)
		M.visible_message("<span class='notice'>[M] climbs into \the [src]!</span>")
	M.forceMove(src)
	add_occupant(M)
	return TRUE

/obj/tgvehicle/clowncar/proc/check_crossed(datum/source, atom/movable/crossed)
	SIGNAL_HANDLER
	if(!has_gravity())
		return
	if(!iscarbon(crossed))
		return
	var/mob/living/carbon/target_pancake = crossed
	if(target_pancake.body_position != LYING_DOWN)
		return
	if(HAS_TRAIT(target_pancake, TRAIT_KNOCKEDOUT))
		return
	target_pancake.visible_message("<span class='warning'>[src] runs over [target_pancake], flattening [target_pancake.p_them()] like a pancake!</span>")
	target_pancake.AddElement(/datum/element/squish, 5 SECONDS)
	target_pancake.apply_effect(2 SECONDS, PARALYZE)
	playsound(target_pancake, 'sound/effects/cars/cartoon_splat.ogg', 75)
	//log_combat(src, crossed, "ran over")

/obj/tgvehicle/clowncar/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(emagged)
		return FALSE
	emagged = TRUE
	to_chat(user, "<span class='warning'>You scramble [src]'s child safety lock, and a panel with six colorful buttons appears!</span>")
	purchase_dlc()
	return TRUE

/obj/tgvehicle/clowncar/proc/purchase_dlc()
	initialize_controller_action_type(/datum/action/vehicle/roll_the_dice, VEHICLE_CONTROL_DRIVE)
	initialize_controller_action_type(/datum/action/vehicle/cannon, VEHICLE_CONTROL_DRIVE)

/obj/tgvehicle/clowncar/obj_destruction(damage_flag)
	playsound(src, 'sound/misc/sadtrombone.ogg', 100)
	STOP_PROCESSING(SSobj,src)
	return ..()

/**
 * Plays a random funky effect
 * Only available while car is emagged
 * Possible effects:
 * * Spawn bananapeel
 * * Spawn random reagent foam
 * * Make the clown car look like a singulo temporarily
 * * Spawn Laughing chem gas
 * * Drop oil
 * * Fart and make everyone nearby laugh
 */

//clown car cooldowns

/obj/tgvehicle/clowncar/proc/roll_the_dice(mob/user)
	if(last_emag_button_use + dice_cooldown_time > world.time)
		to_chat(user, "<span class=notice'>The button panel is currently recharging.</span>")
		return
	last_emag_button_use = world.time
	switch(rand(1,6))
		if(1)
			visible_message("<span class='warning'>[user] presses one of the colorful buttons on [src], and a special banana peel drops out of it.</span>")
			new /obj/item/grown/bananapeel/specialpeel(loc)
		if(2)
			visible_message("<span class='warning'>[user] presses one of the colorful buttons on [src], and unknown chemicals flood out of it.</span>")
			var/datum/reagents/randomchems = new/datum/reagents(300)
			randomchems.my_atom = src
			randomchems.add_reagent(get_random_reagent_id(), 100)
			var/datum/effect_system/foam_spread/foam = new()
			foam.set_up(200, src, randomchems)
			foam.start()
		if(3)
			visible_message("<span class='warning'>[user] presses one of the colorful buttons on [src], and the clown car turns on its singularity disguise system.</span>")
			icon = 'icons/obj/singularity.dmi'
			icon_state = "singularity_s1"
			addtimer(CALLBACK(src, PROC_REF(reset_icon)), 10 SECONDS)
		if(4)
			visible_message("<span class='warning'>[user] presses one of the colorful buttons on [src], and the clown car spews out a cloud of confetti all over the place.</span>")
			confettisize(src, 50, 8)
		if(5)
			visible_message("<span class='warning'>[user] presses one of the colorful buttons on [src], and the clown car starts dropping a lubricant trail.</span>")
			RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(cover_in_oil))
			addtimer(CALLBACK(src, PROC_REF(stop_dropping_oil)), 3 SECONDS)
		if(6)
			visible_message("<span class='warning'>[user] presses one of the colorful buttons on [src], and the clown car lets out a comedic toot.</span>")
			playsound(src, 'sound/effects/cars//clowncar_fart.ogg', 100)
			for(var/mob/living/L in orange(loc, 6))
				L.emote("laugh")
			for(var/mob/living/L as anything in occupants)
				L.emote("laugh")

///resets the icon and iconstate of the clowncar after it was set to singulo states
/obj/tgvehicle/clowncar/proc/reset_icon()
	icon = initial(icon)
	icon_state = initial(icon_state)

///Deploys oil when the clowncar moves in oil deploy mode
/obj/tgvehicle/clowncar/proc/cover_in_oil()
	SIGNAL_HANDLER
	var/turf/simulated/T = get_turf(src)
	T.MakeSlippery(TURF_WET_LUBE)

///Stops dropping oil after the time has run up
/obj/tgvehicle/clowncar/proc/stop_dropping_oil()
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)

///Toggles the on and off state of the clown cannon that shoots random kidnapped people
/obj/tgvehicle/clowncar/proc/toggle_cannon(mob/user)
	if(cannonmode == CLOWN_CANNON_BUSY)
		to_chat(user, "<span class='notice'>Please wait for the vehicle to finish its current action first.</span>")
		return
	if(cannonmode) //canon active, deactivate
		flick("clowncar_fromfire", src)
		icon_state = "clowncar"
		addtimer(CALLBACK(src, PROC_REF(deactivate_cannon)), 2 SECONDS)
		playsound(src, 'sound/effects/cars//clowncar_cannonmode2.ogg', 75)
		visible_message("<span class='warning'>[src] starts going back into mobile mode.</span>")
	else
		brakes = FALSE //anchor and activate canon
		flick("clowncar_tofire", src)
		icon_state = "clowncar_fire"
		visible_message("<span class='warning'>[src] opens up and reveals a large cannon.</span>")
		addtimer(CALLBACK(src, PROC_REF(activate_cannon)), 2 SECONDS)
		playsound(src, 'sound/effects/cars//clowncar_cannonmode1.ogg', 75)
	cannonmode = CLOWN_CANNON_BUSY

///Finalizes canon activation
/obj/tgvehicle/clowncar/proc/activate_cannon()
	var/mouse_pointer = 'icons/effects/mouse_pointers/weapon_pointer.dmi'
	cannonmode = CLOWN_CANNON_READY
	for(var/mob/living/driver as anything in return_controllers_with_flag(VEHICLE_CONTROL_DRIVE))
		if(driver.client.mouse_pointer_icon == initial(driver.client.mouse_pointer_icon))
			driver.client.mouse_pointer_icon = mouse_pointer

///Finalizes canon deactivation
/obj/tgvehicle/clowncar/proc/deactivate_cannon()
	brakes = TRUE
	cannonmode = CLOWN_CANNON_INACTIVE
	for(var/mob/living/driver as anything in return_controllers_with_flag(VEHICLE_CONTROL_DRIVE))
		driver.client.mouse_pointer_icon = initial(driver.client.mouse_pointer_icon)

///Fires the cannon where the user clicks
/obj/tgvehicle/clowncar/proc/fire_cannon_at(mob/user, atom/target, list/modifiers)
	SIGNAL_HANDLER
	if(cannonmode != CLOWN_CANNON_READY || !length(return_controllers_with_flag(VEHICLE_CONTROL_KIDNAPPED)))
		return
	//The driver can still examine things and interact with his inventory.
	if(modifiers[SHIFT_CLICK] || (ismovable(target) && !isturf(target.loc)))
		return
	var/mob/living/unlucky_sod = pick(return_controllers_with_flag(VEHICLE_CONTROL_KIDNAPPED))
	mob_exit(unlucky_sod, silent = TRUE)
	flick("clowncar_recoil", src)
	playsound(src, pick('sound/effects/cars//carcannon1.ogg', 'sound/effects/cars//carcannon2.ogg', 'sound/effects/cars//carcannon3.ogg'), 75)
	unlucky_sod.throw_at(target, 10, 2)
	//log_combat(user, unlucky_sod, "fired", src, "towards [target]") //this doesn't catch if the mob hits something between the car and the target
	return COMSIG_MOB_CANCEL_CLICKON

/obj/tgvehicle/clowncar/relaymove(mob/living/user, direction)
	if(brakes)
		return FALSE
	return ..()
