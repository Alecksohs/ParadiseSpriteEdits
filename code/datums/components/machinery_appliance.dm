// this is connected to appliance.dm and is noobcode

/datum/component/machinery_appliance
	var/require_twohands = FALSE

/datum/component/machinery_appliance/Initialize(heavy = TRUE)
	if(!istype(parent, /obj/machinery))
		return COMPONENT_INCOMPATIBLE
	require_twohands = heavy

/datum/component/machinery_appliance/RegisterWithParent()
    RegisterSignal(parent, COMSIG_TOOL_ATTACK, PROC_REF(on_tool_act))

/datum/component/machinery_appliance/proc/on_tool_act(obj/machinery/source, obj/item/tool, mob/living/user)
	if(tool.tool_behaviour != TOOL_WRENCH)
		return
	. = COMPONENT_CANCEL_TOOLACT
	if(!tool.use_tool(parent, user, 2, volume = tool.tool_volume))
		return
	STOP_PROCESSING(SSobj, source)
	new /obj/item/machinery_appliance_holder(source.loc, parent, require_twohands)
