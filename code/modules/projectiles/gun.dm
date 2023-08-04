//Parent gun type. Guns are weapons that can be aimed at mobs and act over a distance
/obj/item/gun
	name = "gun"
	desc = "It's a gun. It's pretty terrible, though."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "giskard_old"
	item_state = "gun"
	item_state_slots = list(
		slot_l_hand_str = "lefthand",
		slot_r_hand_str = "righthand",
		slot_back_str   = "back",
		slot_s_store_str= "onsuit",
		)
	flags = CONDUCT
	slot_flags = SLOT_BELT|SLOT_HOLSTER
	matter = list(MATERIAL_STEEL = 6)
	w_class = ITEM_SIZE_NORMAL
	throwforce = 5
	throw_speed = 4
	throw_range = 5
	force = WEAPON_FORCE_WEAK
	origin_tech = list(TECH_COMBAT = 1)
	attack_verb = list("struck", "hit", "bashed")
	zoomdevicename = "scope"
	hud_actions = list()
	max_upgrades = 5

	hitsound = "swing_hit"

	var/auto_eject = FALSE			//if the magazine should automatically eject itself when empty.
	var/auto_eject_sound = 'sound/weapons/smg_empty_alarm.ogg' //The sound that places when a mag is dropped

	var/damage_multiplier = 1 //Multiplies damage of projectiles fired from this gun
	var/penetration_multiplier = 1 //Multiplies armor penetration of projectiles fired from this gun
	var/pierce_multiplier = 0 //ADDITIVE wall penetration to projectiles fired from this gun
	var/extra_damage_mult_scoped = 0 //Adds even more damage mulitplier, when scopped so snipers can sniper
	var/proj_agony_multiplier = 1
	var/burst = 1
	var/fire_delay = 6 	//delay after shooting before the gun can be used again
	var/burst_delay = 2	//delay between shots, if firing in bursts
	var/move_delay = 1
	var/fire_sound = 'sound/weapons/Gunshot.ogg'
	var/modded_sound = FALSE
	var/fire_stacks = 0 //Should we apply fire stacks on hit?

	var/fire_sound_text = "gunshot"
	var/rigged = FALSE
	var/excelsior = FALSE

	var/datum/recoil/recoil // Reference to the recoil datum in datum/recoil.dm
	var/list/init_recoil = list(0, 0, 0) // For updating weapon mods

	var/braced = FALSE //for gun_brace proc.
	var/braceable = 1 //can the gun be used for gun_brace proc, modifies recoil. If the gun has foregrip mod installed, it's not braceable. Bipod mod increases value by 1.

	var/list/gun_parts = list(/obj/item/part/gun = 1 ,/obj/item/stack/material/steel = 4)

	var/muzzle_flash = 3
	var/dual_wielding
	var/can_dual = FALSE // Controls whether guns can be dual-wielded (firing two at once).
	var/active_zoom_factor = 1 //Index of currently selected zoom factor
	var/list/zoom_factors = list()//How much to scope in when using weapon,
	var/list/initial_zoom_factors = list()
	var/psigun = 0
/*

NOTE: For the sake of standardizing guns and extra vision range, here's a general guideline for zooming factor.
		  Do keep in mind that a normal player's view is seven tiles of vision in each direction.

						Minimum value is 0.2 which gives 1 extra tile of vision.
				From there, increases are mostly linear, with the following shared exceptions:
									0.3 and 0.4 = 2 extra tiles
									0.6 and 0.7 = 4 extra tiles
			0.9 gives 6 extra tiles, from there jumps straight to 8 extra tiles at both 1 and 1.1
						1.3 and 1.4 = 10 extra tiles (Character no longer seen on screen)
									1.6 and 1.7 = 12 extra tiles
					Largest zooming factor being 2, increases tile vision by 16 extra tiles.


For the sake of consistency, I suggest always rounding up on even values when applicable. - Seb (ThePainkiller)

*/

	var/suppress_delay_warning = FALSE

	var/safety = TRUE//is safety will be toggled on spawn() or not
	var/restrict_safety = FALSE //To restrict the users ability to toggle the safety
	var/dna_compare_samples = FALSE //If DNA-lock installed
	var/dna_lock_sample = "not_set" //real_name from mob who installed DNA-lock
	var/dna_user_sample = "not_set" //Current user's real_name

	var/can_fire_next = 1

	var/sel_mode = 1 //index of the currently selected mode
	var/list/firemodes = list()
	var/list/init_firemodes = list()

	var/init_offset = 0

	var/mouthshoot = FALSE //To stop people from suiciding twice... >.>
	var/scoped_offset_reduction = 3
	var/list/gun_tags = list() //Attributes of the gun, used to see if an upgrade can be applied to this weapon.
	/*	SILENCER HANDLING */
	var/silenced = FALSE
	var/fire_sound_silenced = 'sound/weapons/Gunshot_silenced.wav' //Firing sound used when silenced

	var/icon_contained = TRUE
	var/static/list/item_icons_cache = list()
	var/wielded_item_state = null

	var/projectile_color //Set by a firemode. Sets the fired projectiles color

	var/twohanded = FALSE //If TRUE, gun can only be fired when wileded
	var/recentwield = 0 // to prevent spammage
	var/proj_step_multiplier = 1
	var/list/proj_damage_adjust = list() //What additional damage do we give to the bullet. Type(string) -> Amount(int), damage is divided for pellets

	var/eject_animatio = FALSE //Only currenly in bolt guns. Check boltgun.dm for more information on this
	var/fire_animatio = FALSE //Only used in revolvers atm, animation for each shot being fired

	var/darkness_view = 0
	var/vision_flags = 0
	var/see_invisible_gun = -1

	var/pumpshotgun_sound = 'sound/weapons/shotgunpump.ogg'

	var/folding_stock = FALSE //Can we fold are stock?
	var/folded = TRUE //IS are stock folded? - and that is yes we start folded
	var/currently_firing = FALSE

	var/wield_delay = 0 // Gun wielding delay , generally in seconds.
	var/wield_delay_factor = 0 // A factor that characterizes weapon size , this makes it require more vig to insta-wield this weapon or less , values below 0 reduce the vig needed and above 1 increase it

	//Gun numbers and stuf
	var/serial_type = "INDEX" // Index will be used for detective scanners, if there is a serial type , the gun will add a number onto its final , if none , it won;'t show on examine
	var/serial_shown = TRUE

	var/overcharge_timer //Holds ref to the timer used for overcharging
	var/overcharge_timer_step = 1 SECOND
	var/overcharge_rate = 1 //Base overcharge additive rate for the gun
	var/overcharge_level = 0 //What our current overcharge level is. Peaks at overcharge_max
	var/overcharge_max = 10

/obj/item/gun/wield(mob/user)
	if(!wield_delay)
		..()
		return
	var/calculated_delay = wield_delay
	if(ishuman(user))
		calculated_delay = wield_delay - (wield_delay * (user.stats.getStat(STAT_VIG) / (100 * wield_delay_factor))) // wield delay - wield_delay * user vigilance / 100 * wield_factor
	if (calculated_delay > 0 && do_after(user, calculated_delay, immobile = FALSE))
		..()
	else if (calculated_delay <= 0)
		..()

/obj/item/gun/proc/loadAmmoBestGuess()
	return

/obj/item/gun/Initialize()
	if(!recoil && islist(init_recoil))
		recoil = getRecoil(arglist(init_recoil))
	else if(!islist(init_recoil))
		recoil = getRecoil()
	else if(!istype(recoil, /datum/recoil))
		error("Invalid type [recoil.type] found in .recoil during /obj Initialize()")
	initial_zoom_factors = zoom_factors.Copy()
	. = ..()
	initialize_firemodes()
	initialize_scope()
	//Properly initialize the default firing mode
	if (firemodes.len)
		set_firemode(sel_mode)

	if(!restrict_safety)
		verbs += /obj/item/gun/proc/toggle_safety_verb//addint it to all guns

		var/obj/screen/item_action/action = new /obj/screen/item_action/top_bar/gun/safety
		action.owner = src
		hud_actions += action

	if(icon_contained)
		if(!item_icons_cache[type])
			item_icons_cache[type] = list(
				slot_l_hand_str = icon,
				slot_r_hand_str = icon,
				slot_back_str = icon,
				slot_s_store_str = icon,
			)
		item_icons = item_icons_cache[type]
	if(!wielded_item_state) // If the gun has no wielded item state then use this generic one.
		wielded_item_state = "_doble" //Someone mispelled double but they did it so consistently it's staying this way.
	//generate_guntags()
	var/obj/screen/item_action/action = new /obj/screen/item_action/top_bar/weapon_info
	action.owner = src
	hud_actions += action
	refresh_upgrades()

	if(serial_type)
		serial_type += "-[generate_gun_serial(pick(3,4,5,6,7,8))]"

/obj/item/gun/pickup()
	..()
	refresh_upgrades() //Run it again, just in case
	update_icon()

/obj/item/gun/Destroy()
	for(var/i in firemodes)
		if(!islist(i))
			qdel(i)
	firemodes = null
	return ..()

/obj/item/gun/examine(mob/user)
	..()
	if(folding_stock)
		to_chat(user, "<span class='info'>\The [src]'s stock can be folded by clicking on it while holding Ctrl + Shift.</span>")

	if(serial_type && serial_shown)
		to_chat(user, SPAN_WARNING("There is a serial number on this gun, it reads [serial_type]."))

/obj/item/gun/proc/set_item_state(state, hands = FALSE, back = FALSE, onsuit = FALSE)
	var/wield_state = null
	if(wielded_item_state)
		wield_state = wielded_item_state
	if(!(hands || back || onsuit))
		hands = back = onsuit = TRUE
	if(hands)//Ok this is a bit hacky. But basically if the gun is weilded, we want to use the wielded icon state over the other one.
		if(wield_state && wielded)//Because most of the time the "normal" icon state is held in one hand. This could be expanded to be less hacky in the future.
			item_state_slots[slot_l_hand_str] = "lefthand"  + wield_state
			item_state_slots[slot_r_hand_str] = "righthand" + wield_state
		else
			item_state_slots[slot_l_hand_str] = "lefthand"  + state
			item_state_slots[slot_r_hand_str] = "righthand" + state
	state = initial(state)
	if(back)
		item_state_slots[slot_back_str]   = "back"      + state
	if(onsuit)
		item_state_slots[slot_s_store_str]= "onsuit"    + state


/obj/item/gun/update_icon()
	if(wielded_item_state)
		if(icon_contained)//If it has it own icon file then we want to pull from that.
			if(wielded)
				item_state_slots[slot_l_hand_str] = "lefthand"  + wielded_item_state
				item_state_slots[slot_r_hand_str] = "righthand" + wielded_item_state
			else
				item_state_slots[slot_l_hand_str] = "lefthand"
				item_state_slots[slot_r_hand_str] = "righthand"
		else//Otherwise we can just pull from the generic left and right hand icons.
			if(wielded)
				item_state_slots[slot_l_hand_str] = wielded_item_state
				item_state_slots[slot_r_hand_str] = wielded_item_state
			else
				item_state_slots[slot_l_hand_str] = initial(item_state)
				item_state_slots[slot_r_hand_str] = initial(item_state)


//Checks whether a given mob can use the gun
//Any checks that shouldn't result in handle_click_empty() being called if they fail should go here.
//Otherwise, if you want handle_click_empty() to be called, check in consume_next_projectile() and return null there.
/obj/item/gun/proc/special_check(var/mob/user)

	if(!isliving(user))
		return FALSE
	if(!user.IsAdvancedToolUser())
		return FALSE

	var/mob/living/M = user
	if(HULK in M.mutations)
		to_chat(user, SPAN_DANGER("Your fingers are much too large for the trigger guard!"))
		return FALSE
	if(!restrict_safety)
		if(safety)
			to_chat(user, SPAN_DANGER("The safety is on!"))
			handle_click_empty(user)
			return FALSE
	if(restrict_safety) //if we are restructed to be only saft then we also check
		if(safety) //Danger zone dosnt force safety so we check again
			to_chat(user, SPAN_DANGER("The safety is on!"))
			handle_click_empty(user)
			return FALSE

	if(twohanded)
		if(!wielded)
			if (world.time >= recentwield + 1 SECONDS)
				to_chat(user, SPAN_DANGER("\The [src] is too heavy to shoot in one hand!"))
				recentwield = world.time
			return FALSE

	if(!dna_check(M))
		to_chat(user, SPAN_DANGER("\The [src]'s biometric scanner prevents you from firing!"))
		handle_click_empty(user)
		return FALSE

	if((CLUMSY in M.mutations) && prob(15))
		var/obj/P = consume_next_projectile()
		if(P)
			if(process_projectile(P, user, user, pick(BP_L_LEG, BP_R_LEG)))
				handle_post_fire(user, user)
				user.visible_message(
					SPAN_DANGER("\The [user] fumbles with \the [src] and shoot themselves in the foot!"),
					SPAN_DANGER("You fumble with \the [src] and accidentally shoot yourself in the foot with it!")
					)
				currently_firing = FALSE
		else
			handle_click_empty(user)
		return FALSE

	if(rigged)
		var/obj/P = consume_next_projectile()
		if(P)
			if(process_projectile(P, user, user, BP_HEAD))
				handle_post_fire(user, user)
				user.visible_message(
					SPAN_DANGER("As \the [user] pulls the trigger on \the [src], a bullet somehow fires backwards out of it1"),
					SPAN_DANGER("Your \the [src] fires backwards, shooting you in the face!")
					)
				currently_firing = FALSE
			if(rigged > TRUE)
				explosion(get_turf(src), 1, 2, 3, 3)
				qdel(src)
			return FALSE

	if(excelsior)
		if(!is_excelsior(M) && prob(60 - min(user.stat_check(STAT_COG), 59)))
			var/obj/P = consume_next_projectile()
			if(P)
				if(process_projectile(P, user, user, BP_HEAD))
					handle_post_fire(user, user)
					currently_firing = FALSE
					user.visible_message(
						SPAN_DANGER("As \the [user] pulls the trigger on \the [src], a bullet fires backwards out of it!"),
						SPAN_DANGER("Your \the [src] fires backwards, shooting you in the face!")
						)

				if(prob(60 - user.stat_check(STAT_COG)))
					explosion(get_turf(src), 1, 2, 3, 3)
					qdel(src)
			return FALSE

	return TRUE

/obj/item/gun/emp_act(severity)
	for(var/obj/O in contents)
		O.emp_act(severity)

/obj/item/gun/afterattack(atom/A, mob/living/user, adjacent, params)
	if(adjacent) return //A is adjacent, is the user, or is on the user's person

	var/obj/item/gun/off_hand   //DUAL WIELDING
	if(ishuman(user) && user.a_intent == "harm")
		var/mob/living/carbon/human/H = user

		if(H.r_hand == src && istype(H.l_hand, /obj/item/gun))
			off_hand = H.l_hand
			dual_wielding = TRUE

		else if(H.l_hand == src && istype(H.r_hand, /obj/item/gun))
			off_hand = H.r_hand
			dual_wielding = TRUE
		else
			dual_wielding = FALSE

		if(!can_dual)
			dual_wielding = FALSE
		else if(off_hand && off_hand.can_hit(user))
			spawn(1)
			off_hand.Fire(A,user,params)
	else
		dual_wielding = FALSE

	Fire(A,user,params) //Otherwise, fire normally.

/obj/item/gun/attack(atom/A, mob/living/user, def_zone)
	if (A == user && user.targeted_organ == BP_MOUTH && !mouthshoot)
		handle_suicide(user)
	else if(user.a_intent == I_HURT) //point blank shooting
		Fire(A, user, pointblank=1)
	else
		return ..() //Pistolwhippin'

/obj/item/gun/attackby(obj/item/I, mob/living/user, params)
	//Detectable crime >:T
	if(istype(I, /obj/item/device/bullet_scanner))
		if(serial_type)
			to_chat(user, "<span class='info'>Projectile Serial Calibration: [serial_type].</span>")
			return
		else
			to_chat(user, "<span class='info'>Projectile Serial Calibration: ERROR.</span>")


	if(!istool(I) || user.a_intent != I_HURT)
		return FALSE

	//UNDETECTABLE CRIIIIMEEEE!!!!!!!
	if(I.get_tool_quality(QUALITY_HAMMERING) && serial_type)
		user.visible_message(SPAN_NOTICE("[user] begins chiseling \the [name]'s serial numbers away."), SPAN_NOTICE("You begin removing the serial numbers from \the [name]."))
		if(I.use_tool(user, src, WORKTIME_SLOW, QUALITY_HAMMERING, FAILCHANCE_EASY, required_stat = STAT_MEC))
			user.visible_message(SPAN_DANGER("[user] removes \the [name]'s serial numbers."), SPAN_NOTICE("You successfully remove the serial numbers from \the [name]."))
			serial_type = "INDEX"
			serial_type += "-[generate_gun_serial(pick(3,4,5,6,7,8))]"
			serial_shown = FALSE
			return FALSE

	if(I.get_tool_quality(QUALITY_WIRE_CUTTING))
		if(psigun)
			to_chat(user, SPAN_NOTICE("You can't dismantle [src] as it has no gun parts! How strange..."))
			return FALSE
		if(!gun_parts)
			to_chat(user, SPAN_NOTICE("You can't dismantle [src], it is far too complicated!"))
			return FALSE


		user.visible_message(SPAN_NOTICE("[user] begins breaking apart [src]."), SPAN_WARNING("You begin breaking apart [src] for gun parts."))
		if(I.use_tool(user, src, WORKTIME_SLOW, QUALITY_WIRE_CUTTING, FAILCHANCE_EASY, required_stat = STAT_MEC))
			user.visible_message(SPAN_NOTICE("[user] breaks [src] apart for gun parts!"), SPAN_NOTICE("You break [src] apart for gun parts."))
			for(var/target_item in gun_parts)
				var/amount = gun_parts[target_item]
				while(amount)
					if(ispath(target_item, /obj/item/part/gun/frame))
						var/obj/item/part/gun/frame/F = new target_item(get_turf(src))
						F.serial_type = serial_type
					else
						new target_item(get_turf(src))
					amount--
			qdel(src)

/obj/item/gun/proc/dna_check(user)
	if(dna_compare_samples)
		dna_user_sample = usr.real_name
		if(dna_lock_sample != dna_user_sample)
			return FALSE
	return TRUE

/obj/item/gun/proc/ready_to_shoot()
	can_fire_next = TRUE


/obj/item/gun/proc/Fire(atom/target, mob/living/user, clickparams, pointblank=0, reflex=0, extra_proj_damagemult = 0, extra_proj_penmult = 0, extra_proj_wallbangmult = 0, extra_proj_stepdelaymult = 0, multiply_projectile_agony = 0, multiply_pve_damage = 0)
	if(!user || !target) return

	if(!can_fire_next || currently_firing)
		if (!suppress_delay_warning && world.time % 3) //to prevent spam
			to_chat(user, SPAN_WARNING("\The [src] is not ready to fire again!"))
		return

	if(user)
		add_fingerprint(user)

	if(!special_check(user))
		return

	currently_firing = TRUE

	var/shoot_time = (burst - 1)* burst_delay
	user.setClickCooldown(shoot_time) //no clicking on things while shooting
	can_fire_next = FALSE
	addtimer(CALLBACK(src, /obj/item/gun/proc/ready_to_shoot), fire_delay)

	if(muzzle_flash)
		set_light(muzzle_flash)

	//actually attempt to shoot
	var/turf/targloc = get_turf(target) //cache this in case target gets deleted during shooting, e.g. if it was a securitron that got destroyed.
	for(var/i in 1 to burst)
		var/obj/projectile = consume_next_projectile(user)
		if(!projectile)
			handle_click_empty(user)
			break

		if(extra_proj_damagemult)
			projectile.multiply_projectile_damage(extra_proj_damagemult)

		projectile.multiply_projectile_damage(damage_multiplier)

		if(extra_proj_penmult)
			projectile.multiply_projectile_penetration(extra_proj_penmult)

		projectile.multiply_projectile_penetration(penetration_multiplier + user.stats.getStat(STAT_VIG) * 0.02)

		if(extra_proj_wallbangmult)
			projectile.multiply_pierce_penetration(extra_proj_wallbangmult)

		projectile.multiply_pierce_penetration(pierce_multiplier)

		if(extra_proj_stepdelaymult)
			projectile.multiply_projectile_step_delay(extra_proj_stepdelaymult)

		projectile.multiply_projectile_step_delay(proj_step_multiplier)

		if(multiply_projectile_agony)
			projectile.multiply_projectile_agony(multiply_projectile_agony)

		projectile.multiply_projectile_agony(proj_agony_multiplier)

		if(multiply_pve_damage)
			projectile.multiply_pve_damage(multiply_pve_damage)

		if(fire_stacks)
			projectile.add_fire_stacks(fire_stacks)

		if(muzzle_flash)
			set_light(muzzle_flash)

		if(istype(projectile, /obj/item/projectile))
			var/obj/item/projectile/P = projectile
			P.adjust_damages(proj_damage_adjust)
			P.serial_type_index_bullet = serial_type

		if(pointblank)
			process_point_blank(projectile, user, target)
		if(projectile_color)
			projectile.icon = get_proj_icon_by_color(projectile, projectile_color)
			if(istype(projectile, /obj/item/projectile))
				var/obj/item/projectile/P = projectile
				P.proj_color = projectile_color
		if(process_projectile(projectile, user, target, user.targeted_organ, clickparams))
			handle_post_fire(user, target, pointblank, reflex, projectile)
			update_icon()

		if(fire_animatio) //Are bullet amination check
			if(silenced)
				flick("fire_s", src)
			else
				flick("fire", src)

		if(i < burst)
			sleep(burst_delay)

		if(!(target && target.loc))
			target = targloc
			pointblank = 0

	//update timing
	user.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
	user.set_move_cooldown(move_delay)
	if(!twohanded && user.stats.getPerk(PERK_GUNSLINGER))
		addtimer(CALLBACK(src, /obj/item/gun/proc/ready_to_shoot), min(0, (fire_delay - fire_delay * 0.33)))

	if((CLUMSY in user.mutations) && prob(40)) //Clumsy handling
		var/obj/P = consume_next_projectile()
		if(P)
			if(process_projectile(P, user, user, pick(BP_L_LEG, BP_R_LEG)))
				handle_post_fire(user, user)
				user.visible_message(
					SPAN_DANGER("\The [user] shoots themselves in the foot with \the [src]!"),
					SPAN_DANGER("You shoot yourself in the foot with \the [src]!")
					)
				user.drop_item()
		else
			handle_click_empty(user)
		return FALSE

	currently_firing = FALSE

	spawn(5) //gives us time to light up the area as we shoot

	if(muzzle_flash)
		set_light(0)

//obtains the next projectile to fire
/obj/item/gun/proc/consume_next_projectile()
	return null

//used by aiming code
/obj/item/gun/proc/can_hit(atom/target as mob, var/mob/living/user as mob)
	if(!special_check(user))
		return 2
	//just assume we can shoot through glass and stuff. No big deal, the player can just choose to not target someone
	//on the other side of a window if it makes a difference. Or if they run behind a window, too bad.
	return check_trajectory(target, user)

//called if there was no projectile to shoot
/obj/item/gun/proc/handle_click_empty(mob/user)
	if (user)
		user.visible_message("*click click*", SPAN_DANGER("*click*"))
	else
		src.visible_message("*click click*")
	playsound(src.loc, 'sound/weapons/guns/misc/trigger_fail.ogg', 100, 0) // Better sound! No variance please.
	update_firemode() //Stops automatic weapons spamming this shit endlessly

//called after successfully firing
/obj/item/gun/proc/handle_post_fire(mob/living/user, atom/target, pointblank=0, reflex=0, obj/item/projectile/P)
	LEGACY_SEND_SIGNAL(src, COMSIG_GUN_POST_FIRE, target, pointblank, reflex)
	//The sound we play
	if(silenced)
		//Silenced shots have a lower range and volume
		playsound(user, fire_sound_silenced, 15, 1, -3)
	else
		playsound(user, fire_sound, 60, 1)

		if(reflex)
			user.visible_message(
				"<span class='reflex_shoot'><b>\The [user] fires \the [src][pointblank ? " point blank at \the [target]":""] by reflex!</b></span>",
				"<span class='reflex_shoot'>You fire \the [src] by reflex!</span>",
				"You hear a [fire_sound_text]!"
			)
		else
			user.visible_message(
				SPAN_WARNING("\The [user] fires \the [src][pointblank ? " point blank at \the [target]":""]!"),
				SPAN_WARNING("You fire \the [src]!"),
				"You hear a [fire_sound_text]!"
				)

		if(muzzle_flash)
			set_light(muzzle_flash)

	kickback(user, P)
	user.handle_recoil(src)
	update_icon()

/obj/item/gun/proc/kickback(mob/living/user, obj/item/projectile/P)
	var/base_recoil = recoil.getRating(RECOIL_BASE)
	var/brace_recoil = 0
	var/unwielded_recoil = 0

	if(!braced)
		brace_recoil = recoil.getRating(RECOIL_TWOHAND)
	else if(braceable > 1)
		base_recoil /= 4 // With a bipod, you can negate most of your recoil

	if(!wielded)
		unwielded_recoil = recoil.getRating(RECOIL_ONEHAND)

	if(unwielded_recoil)
		switch(recoil.getRating(RECOIL_ONEHAND_LEVEL))
			if(0.6 to 0.8)
				if(prob(25)) // Don't need to tell them every single time
					to_chat(user, SPAN_WARNING("Your aim wavers slightly."))
			if(0.8 to 1)
				if(prob(50))
					to_chat(user, SPAN_WARNING("Your aim wavers as you fire \the [src] with just one hand."))
			if(1 to 1.5)
				to_chat(user, SPAN_WARNING("You have trouble keeping \the [src] on target with just one hand."))
			if(1.5 to INFINITY)
				to_chat(user, SPAN_WARNING("You struggle to keep \the [src] on target with just one hand!"))

	else if(brace_recoil)
		switch(recoil.getRating(RECOIL_BRACE_LEVEL))
			if(0.6 to 0.8)
				if(prob(25))
					to_chat(user, SPAN_WARNING("Your aim wavers slightly."))
			if(0.8 to 1)
				if(prob(50))
					to_chat(user, SPAN_WARNING("Your aim wavers as you fire \the [src] while carrying it."))
			if(1 to 1.2)
				to_chat(user, SPAN_WARNING("You have trouble keeping \the [src] on target while carrying it!"))
			if(1.2 to INFINITY)
				to_chat(user, SPAN_WARNING("You struggle to keep \the [src] on target while carrying it!"))

	user.handle_recoil(src, (base_recoil + brace_recoil + unwielded_recoil) * P.recoil)

/obj/item/gun/proc/process_point_blank(var/obj/item/projectile/P, mob/user, atom/target)
	if(!istype(P))
		return //default behaviour only applies to true projectiles

	if(dual_wielding)
		return //dual wielding deal too much damage as it is, so no point blank for it

	//default point blank multiplier
	var/damage_mult = 1.1

	//determine multiplier due to the target being grabbed
	if(ismob(target))
		var/mob/M = target
		if(M.grabbed_by.len)
			var/grabstate = 0
			for(var/obj/item/grab/G in M.grabbed_by)
				grabstate = max(grabstate, G.state)
			if(grabstate >= GRAB_NECK)
				damage_mult = 1.75
			else if(grabstate >= GRAB_AGGRESSIVE)
				damage_mult = 1.3
		P.multiply_projectile_damage(damage_mult)


//does the actual launching of the projectile
/obj/item/gun/proc/process_projectile(var/obj/item/projectile/P, mob/living/user, atom/target, var/target_zone, var/params=null)
	if(!istype(P))
		return FALSE //default behaviour only applies to true projectiles

	if(params)
		P.set_clickpoint(params)
	var/offset = user.calculate_offset(init_offset)
/*
	var/remainder = offset % 4
	offset /= 4
	offset = round(offset)
	offset = roll(offset,9) - offset * 5
	switch(remainder)
		if(1)
			offset += roll(1,3) - 2
		if(2)
			offset += roll(1,5) - 3
		if(3)
			offset += roll(1,7) - 4
*/
	offset = round(offset)

	offset = roll(2, offset) - (offset + 1)

	return !P.launch_from_gun(target, user, src, target_zone, angle_offset = offset)

//Support proc for calculate_offset
/obj/item/gun/proc/init_offset_with_brace()
	var/offset = init_offset
	if(braced)
		offset -= braceable * 3 // Bipod doubles effect
	return offset

//Suicide handling.
/obj/item/gun/proc/handle_suicide(mob/living/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/M = user

	mouthshoot = TRUE
	M.visible_message(SPAN_DANGER("[user] points their gun at their head, ready to pull the trigger..."))
	if(!do_after(user, 40, progress=0))
		M.visible_message(SPAN_NOTICE("[user] decided life was worth living"))
		mouthshoot = FALSE
		return

	if(safety)
		handle_click_empty(user)
		mouthshoot = FALSE
		return

	var/obj/item/projectile/in_chamber = consume_next_projectile()
	if (istype(in_chamber))
		user.visible_message(SPAN_WARNING("[user] pulls the trigger."))
		if(silenced)
			playsound(user, fire_sound, 10, 1)
		else
			playsound(user, fire_sound, 60, 1)
		if(istype(in_chamber, /obj/item/projectile/plasma/lastertag))
			user.show_message(SPAN_WARNING("You feel rather silly, trying to commit suicide with a toy."))
			mouthshoot = FALSE
			return

		in_chamber.on_hit(M)
		if (!in_chamber.is_halloss())
			log_and_message_admins("[key_name(user)] commited suicide using \a [src]")
			for(var/damage_type in in_chamber.damage_types)
				var/damage = in_chamber.damage_types[damage_type]*2.5
				user.apply_damage(damage, damage_type, BP_HEAD, used_weapon = "Point blank shot in the head with \a [in_chamber]", sharp=1)
			user.death()
		else
			to_chat(user, SPAN_NOTICE("Ow..."))
			user.adjustHalLoss(110)
		qdel(in_chamber)
		mouthshoot = FALSE
		return
	else
		handle_click_empty(user)
		mouthshoot = FALSE
		return

/obj/item/gun/proc/gun_brace(mob/living/user, atom/target)
	if(braceable && !user.is_busy)
		var/atom/original_loc = user.loc
		var/brace_direction = get_dir(user, target)
		user.is_busy = TRUE
		user.facing_dir = null
		to_chat(user, SPAN_NOTICE("You brace your [src] on \the [target]."))
		braced = TRUE
		while(user.loc == original_loc && user.dir == brace_direction)
			sleep(2)
		to_chat(user, SPAN_NOTICE("You stop bracing your gun."))
		braced = FALSE
		user.is_busy = FALSE
	else
		if(user.is_busy)
			to_chat(user, SPAN_NOTICE("You are already bracing your gun!"))
		else
			to_chat(user, SPAN_WARNING("You can\'t properly place your gun on \the [target] because of its foregrip!"))

/obj/item/gun/proc/toggle_scope(mob/living/user, switchzoom = FALSE)
	//looking through a scope limits your periphereal vision
	//still, increase the view size by a tiny amount so that sniping isn't too restricted to NSEW
	if(!zoom_factors)
		zoom = FALSE
		return
	var/tozoom = zoom_factors[active_zoom_factor]
	var/zoom_offset = round(world.view * tozoom)
	var/view_size = round(world.view + tozoom)

	zoom(zoom_offset, view_size, switchzoom)
	check_safety_cursor(user)
	update_hud_actions()

/obj/item/gun/proc/switch_zoom(mob/living/user)
	if(!zoom_factors)
		return null
	if(zoom_factors.len <= 1)
		return null
//	update_firemode(FALSE) //Disable the old firing mode before we switch away from it
	active_zoom_factor++
	if(active_zoom_factor > zoom_factors.len)
		active_zoom_factor = 1
	refresh_upgrades()
	toggle_scope(user, TRUE)

/obj/item/gun/examine(mob/user)
	..()
	if(firemodes.len > 1)
		var/datum/firemode/current_mode = firemodes[sel_mode]
		to_chat(user, SPAN_NOTICE("The fire selector is set to [current_mode.name]."))

	if(safety)
		to_chat(user, SPAN_NOTICE("The safety is on."))
	else
		to_chat(user, SPAN_NOTICE("The safety is off."))

	if(can_dual == TRUE)
		to_chat(user, SPAN_NOTICE("This gun can be duel-wielded effectively, if you're skilled enough."))

	if(twohanded)
		to_chat(user, SPAN_NOTICE("This gun would need to be wielded in both hands."))
		return

	if(recoil.getRating(RECOIL_TWOHAND) > 0.4)
		to_chat(user, SPAN_WARNING("This gun needs to be braced against something to be used effectively."))
	else if(recoil.getRating(RECOIL_ONEHAND) > 0.6)
		to_chat(user, SPAN_WARNING("This gun needs to be wielded in both hands to be used most effectively."))

/obj/item/gun/proc/initialize_firemodes()
	QDEL_LIST(firemodes)

	for(var/i in 1 to init_firemodes.len)
		var/list/L = init_firemodes[i]
		add_firemode(L)

	var/obj/screen/item_action/action = locate(/obj/screen/item_action/top_bar/gun/fire_mode) in hud_actions
	if(firemodes.len > 1)
		if(!action)
			action = new /obj/screen/item_action/top_bar/gun/fire_mode
			action.owner = src
			hud_actions += action
	else
		qdel(action)
		hud_actions -= action

/obj/item/gun/proc/initialize_scope()
	var/obj/screen/item_action/action = locate(/obj/screen/item_action/top_bar/gun/scope) in hud_actions
	if(zoom_factors.len >= 1)
		if(!action)
			action = new /obj/screen/item_action/top_bar/gun/scope
			action.owner = src
			hud_actions += action
			if(ismob(loc))
				var/mob/user = loc
				user.client?.screen += action
	else
		if(ismob(loc))
			var/mob/user = loc
			user.client?.screen -= action
		hud_actions -= action
		qdel(action)

/obj/item/gun/proc/add_firemode(var/list/firemode)
	//If this var is set, it means spawn a specific subclass of firemode
	if (firemode["mode_type"])
		var/newtype = firemode["mode_type"]
		firemodes.Add(new newtype(src, firemode))
	else
		firemodes.Add(new /datum/firemode(src, firemode))

/obj/item/gun/proc/switch_firemodes()
	if(firemodes.len <= 1)
		return null
	update_firemode(FALSE) //Disable the old firing mode before we switch away from it
	sel_mode++
	if(sel_mode > firemodes.len)
		sel_mode = 1
	return set_firemode(sel_mode)

/obj/item/gun/proc/switch_firemodes_reverse()
	if(firemodes.len <= 1)
		return null
	update_firemode(FALSE) //Disable the old firing mode before we switch away from it
	sel_mode--
	if(sel_mode < 1)
		sel_mode = firemodes.len
	return set_firemode(sel_mode)

/// Set firemode , but without a refresh_upgrades at the start
/obj/item/gun/proc/very_unsafe_set_firemode(index)
	if(index > firemodes.len)
		index = 1
	var/datum/firemode/new_mode = firemodes[sel_mode]
	new_mode.apply_to(src)
	new_mode.update()
	update_hud_actions()
	return new_mode

/obj/item/gun/proc/set_firemode(var/index)
	refresh_upgrades()
	if(index > firemodes.len)
		index = 1
	var/datum/firemode/new_mode = firemodes[sel_mode]
	new_mode.update()
	update_hud_actions()
	return new_mode

/obj/item/gun/attack_self(mob/user)
	if(zoom)
		toggle_scope(user)
		return

	toggle_firemode(user)

/obj/item/gun/proc/toggle_firemode(mob/living/user, forward = TRUE)
	if(currently_firing) // CHEATERS!
		return
	var/datum/firemode/new_mode = switch_firemodes()
	if(new_mode)
		playsound(src.loc, 'sound/weapons/guns/interact/selector.ogg', 100, 1)
		to_chat(user, SPAN_NOTICE("\The [src] is now set to [new_mode.name]."))

/obj/item/gun/proc/toggle_safety(mob/living/user)
	if(restrict_safety || src != user.get_active_hand())
		return

	safety = !safety
	playsound(user, 'sound/weapons/selector.ogg', 50, 1)
	to_chat(user, SPAN_NOTICE("You toggle the safety [safety ? "on":"off"]."))
	//Update firemode when safeties are toggled
	update_firemode()
	update_hud_actions()
	check_safety_cursor(user)

/obj/item/gun/proc/check_safety_cursor(mob/living/user)
	if(safety)
		user.remove_cursor()
	else
		user.update_cursor(src)

/obj/item/gun/proc/get_total_damage_adjust()
	var/val = 0
	for(var/i in proj_damage_adjust)
		val += proj_damage_adjust[i]
	return val

//Finds the current firemode and calls update on it. This is called from a few places:
//When firemode is changed
//When safety is toggled
//When gun is picked up
//When gun is readied
/obj/item/gun/proc/update_firemode(var/force_state = null)
	if (sel_mode && firemodes && firemodes.len)
		var/datum/firemode/new_mode = firemodes[sel_mode]
		new_mode.update(force_state)

/obj/item/gun/AltClick(mob/user)
	if(user.incapacitated())
		to_chat(user, SPAN_WARNING("You can't do that right now!"))
		return
	toggle_safety(user)

/obj/item/gun/CtrlShiftClick(mob/user)
	. = ..()

	var/able = can_interact(user)

	if(able == 1)
		return

	if(able == 2)
		to_chat(user, SPAN_NOTICE("You cannot [folded ? "unfold" : "fold"] the stock while \the [src] is in a container."))
		return

	fold(span_chat = TRUE)

/obj/item/gun/can_interact(mob/user)
	if((!ishuman(user) && (loc != user)) || user.stat || user.restrained())
		return 1
	if(istype(loc, /obj/item/storage))
		return 2
	return 0

/obj/item/gun/proc/fold(user, span_chat)
	if(folding_stock)
		if(!folded)
			if(span_chat)
				to_chat(usr, SPAN_NOTICE("You unfold the stock on \the [src]."))
			folded = TRUE
		else
			if(span_chat)
				to_chat(usr, SPAN_NOTICE("You fold the stock on \the [src]."))
			folded = FALSE
	refresh_upgrades() //First we grab our upgrades to not do anything silly
	update_icon() //Likely has alt icons for being folded or not so we refresh our icon

//Updating firing modes at appropriate times
/obj/item/gun/pickup(mob/user)
	.=..()
	update_firemode()

/obj/item/gun/dropped(mob/user)
	// I really fucking hate this but this is how this is going to work.
	var/mob/living/carbon/human/H = user
	if (istype(H) && H.using_scope)
		toggle_scope(H)
	update_firemode(FALSE)
	.=..()

/obj/item/gun/swapped_from()
	.=..()
	update_firemode(FALSE)

/obj/item/gun/swapped_to()
	.=..()
	update_firemode()

/obj/item/gun/proc/toggle_safety_verb()
	set name = "Toggle gun's safety"
	set category = "Object"
	set src in view(1)

	toggle_safety(usr)

/obj/item/gun/nano_ui_data(mob/user)
	var/list/data = list()
	data["damage_multiplier"] = damage_multiplier
	data["pierce_multiplier"] = pierce_multiplier
	data["penetration_multiplier"] = penetration_multiplier
	data["proj_agony_multiplier"] = proj_agony_multiplier

	data["fire_delay"] = fire_delay //time between shots, in ms
	data["burst"] = burst //How many shots are fired per click
	data["burst_delay"] = burst_delay //time between shot in burst mode, in ms

	data["force"] = force
	data["force_max"] = initial(force)*10
	data["armor_penetration"] = armor_penetration
	data["muzzle_flash"] = muzzle_flash

	var/total_recoil = 0
	var/list/recoilList = recoil.getFancyList()
	if(recoilList.len)
		var/list/recoil_vals = list()
		for(var/i in recoilList)
			if(recoilList[i])
				recoil_vals += list(list(
					"name" = i,
					"value" = recoilList[i]
					))
				total_recoil += recoilList[i]
		data["recoil_info"] = recoil_vals

	data["total_recoil"] = total_recoil
	data["extra_volume"] = extra_bulk

	data["upgrades_max"] = max_upgrades

	data += ui_data_projectile(get_dud_projectile())

	if(firemodes.len)
		var/list/firemodes_info = list()
		for(var/i = 1 to firemodes.len)
			data["firemode_count"] += 1
			var/datum/firemode/F = firemodes[i]
			var/list/firemode_info = list(
				"index" = i,
				"current" = (i == sel_mode),
				"name" = F.name,
				"desc" = F.desc,
				"burst" = F.settings["burst"],
				"fire_delay" = F.settings["fire_delay"],
				"move_delay" = F.settings["move_delay"],
				)
			if(F.settings["projectile_type"])
				var/proj_path = F.settings["projectile_type"]
				var/list/proj_data = ui_data_projectile(new proj_path)
				firemode_info += proj_data
			firemodes_info += list(firemode_info)
		data["firemode_info"] = firemodes_info

	if(item_upgrades.len)
		data["attachments"] = list()
		for(var/atom/A in item_upgrades)
			data["attachments"] += list(list("name" = A.name, "icon" = SSassets.transport.get_asset_url(A)))

	return data

/obj/item/gun/Topic(href, href_list, var/datum/nano_topic_state/state)
	if(..(href, href_list, state))
		return 1

	if(href_list["firemode"])
		sel_mode = text2num(href_list["firemode"])
		set_firemode(sel_mode)
		return 1

//Returns a projectile that's not for active usage.
/obj/item/gun/proc/get_dud_projectile()
	return null

/obj/item/gun/proc/ui_data_projectile(var/obj/item/projectile/P)
	if(!P)
		return list()
	var/list/data = list()
	data["projectile_name"] = P.name
	data["projectile_damage"] = (P.get_total_damage() * damage_multiplier) + get_total_damage_adjust()
	data["projectile_damage_pve"] = (P.get_total_damage() * damage_multiplier) + get_total_damage_adjust() + (P.agony * proj_agony_multiplier)
	data["projectile_AP"] = P.armor_penetration * penetration_multiplier
	data["projectile_pain"] = P.agony * proj_agony_multiplier
	data["projectile_recoil"] = P.recoil
	qdel(P)
	return data

/obj/item/gun/refresh_upgrades()
	//First of all, let's reset any var that could possibly be altered by an upgrade
	damage_multiplier = initial(damage_multiplier)
	penetration_multiplier = initial(penetration_multiplier)
	pierce_multiplier = initial(pierce_multiplier)
	proj_step_multiplier = initial(proj_step_multiplier)
	proj_agony_multiplier = initial(proj_agony_multiplier)
	extra_damage_mult_scoped = initial(extra_damage_mult_scoped)
	scoped_offset_reduction  = initial(scoped_offset_reduction)
	fire_delay = initial(fire_delay)
	move_delay = initial(move_delay)
	muzzle_flash = initial(muzzle_flash)
	silenced = initial(silenced)
	restrict_safety = initial(restrict_safety)
	init_offset = initial(init_offset)
	proj_damage_adjust = list()
	if(modded_sound)
		modded_sound = FALSE
		fire_sound = initial(fire_sound)
	restrict_safety = initial(restrict_safety)
	dna_compare_samples = initial(dna_compare_samples)
	rigged = initial(rigged)
	zoom_factors = initial_zoom_factors.Copy()
	darkness_view = initial(darkness_view)
	vision_flags = initial(vision_flags)
	see_invisible_gun = initial(see_invisible_gun)
	force = initial(force)
	armor_penetration = initial(armor_penetration)
	sharp = initial(sharp)
	attack_verb = list()
	auto_eject = initial(auto_eject) //SoJ edit
	initialize_scope()
	initialize_firemodes()
	//Let's refresh our name and prefixes
	// FIXME: This sadly sometimes resets the gun from <prefixes><gun_name> to just the gun's name when storing it on a container.
	name = initial(name)
	max_upgrades = initial(max_upgrades)
	color = initial(color)
	prefixes = list()
	item_flags = initial(item_flags)
	extra_bulk = initial(extra_bulk)

	recoil = getRecoil(init_recoil[1], init_recoil[2], init_recoil[3])

	braced = initial(braced)

	//This is so we get are folding recoil mod
	if(folding_stock)// TODO: make this somehow modular - (it prob will be a massive line if var/stock_name_of_change
		if(!folded) //Exstended! This means are stock is out
			extra_bulk += 12 //Simular to 12 screwdrivers, your getting a lot out of this tho
			//Not modular *yet* as it dosnt need to be for what is basiclly just 10% more damage and 50% less recoil
			damage_multiplier += 0.1 //10% more damage
			proj_step_multiplier  -= 0.4 //40% more sped on the bullet
			penetration_multiplier += 0.2 //Makes the gun have more AP when shooting
			extra_damage_mult_scoped += 0.2 //Gives 20% more damage when its scoped. Makes folding stock snipers more viable
			recoil = getRecoil((init_recoil[1] * 0.5), (init_recoil[2] * 0.1), (init_recoil[3] * 0.8))


	//Now lets have each upgrade reapply its modifications
	LEGACY_SEND_SIGNAL(src, COMSIG_ADDVAL, src)
	LEGACY_SEND_SIGNAL(src, COMSIG_APPVAL, src)

	if(firemodes.len)
		very_unsafe_set_firemode(sel_mode) // Reset the firemode so it gets the new changes

	for (var/prefix in prefixes)
		name = "[prefix] [name]"

	update_icon()
	//then update any UIs with the new stats
	SSnano.update_uis(src)

/obj/item/gun/zoom(tileoffset, viewsize)
	..()
	if(zoom)
		refresh_upgrades() //Lets not allow some silly stacking exploits
		init_offset -= scoped_offset_reduction
		damage_multiplier += extra_damage_mult_scoped
	else
		refresh_upgrades()

/* //Eris has this but it, unsurpringly, has issues, just gonna comment it out for now incase I use the code for something else later.
/obj/item/gun/proc/generate_guntags()
	if(recoil.getRating(RECOIL_BASE) < recoil.getRating(RECOIL_TWOHAND))
		gun_tags |= GUN_GRIP
	if(!zoom_factor && !(slot_flags & SLOT_HOLSTER))
	if(zoom_factors.len < 1 && !(slot_flags & SLOT_HOLSTER))
		gun_tags |= GUN_SCOPE
	if(!sharp)
		gun_tags |= SLOT_BAYONET
*/
