// reader beware you're in for a spritercode - goosebumps or something


// // When we wrench the appliance, turn it into a holder object.
// /obj/machinery/appliance/wrench_act(mob/user, obj/item/I)
//     . = TRUE
//     if(!I.use_tool(src, user, 0, volume = I.tool_volume))
//         return
//     new /obj/item/machinery_appliance_holder(loc, src)
// 	to_chat(user, "<span class = 'caution'> You unfasten the [appliance.name].</span>")

// This will be renamed, it holds the appliances' info, as we are moving it.
/obj/item/machinery_appliance_holder
	name = "You shouldn't be seeing this."
	desc = "You really shouldn't be reading this, as this is a default object that should have been replaced."
	w_class = WEIGHT_CLASS_BULKY
	var/obj/machinery/appliance

/obj/item/machinery_appliance_holder/Initialize(mapload, obj/machinery/a)
	. = ..()
	//This is a heavy item!
	appliance = a
	appliance.forceMove(src)
	AddComponent(/datum/component/two_handed, require_twohands = TRUE)
	update_appearance()

/obj/item/machinery_appliance_holder/wrench_act(mob/user, obj/item/I)
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	appliance.forceMove(get_turf(src))
	to_chat(user, "<span class = 'caution'> You bolt down the [appliance.name].</span>")
	qdel(src)

/obj/item/machinery_appliance_holder/update_icon_state()
    . = ..()
    icon = appliance.icon
    icon_state = appliance.icon_state

/obj/item/machinery_appliance_holder/update_name(updates)
    . = ..()
    name = appliance.name

/obj/item/machinery_appliance_holder/update_desc(updates)
    . = ..()
    desc = appliance.desc

