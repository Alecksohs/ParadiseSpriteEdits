/datum/component/machinery_appliance
	var/require_twohands = FALSE

/datum/component/machine_appliance/Initialize()
    if(!istype(parent, /obj/machinery))
        return COMPONENT_INCOMPATIBLE

/datum/component/machine_appliance/RegisterWithParent()
    RegisterSignal(parent, COMSIG_TOOL_ATTACK, PROC_REF(on_tool_act))

/datum/component/machine_appliance/proc/on_tool_act(obj/machinery/source, obj/item/tool, mob/living/user)
    if(tool.tool_behaviour != TOOL_WRENCH)
        return

    . = COMPONENT_CANCEL_TOOLACT
    if(!tool.use_tool(parent, user, 0, volume = tool.tool_volume))
        return
    new /obj/item/machinery_appliance_holder(source.loc, parent)
