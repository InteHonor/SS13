/mob/living/silicon/say(var/message, var/sanitize = 1)
	return ..(sanitize ? sanitize(message, ja_mode = TEMP) : message)

/mob/living/silicon/handle_message_mode(message_mode, message, verb, speaking, used_radios, alt_name)
	log_say("[key_name(src)] : [message]")

/mob/living/silicon/robot/handle_message_mode(message_mode, message, verb, speaking, used_radios, alt_name)
	..()
	if(message_mode)
		if(!is_component_functioning("radio"))
			src << "<span class='warning'>Your radio isn't functional at this time.</span>"
			return 0
		if(message_mode == "general")
			message_mode = null
		return radio.talk_into(src,message,message_mode,verb,speaking)

/mob/living/silicon/ai/handle_message_mode(message_mode, message, verb, speaking, used_radios, alt_name)
	..()
	if(message_mode == "department")
		return holopad_talk(message, verb, speaking)
	else if(message_mode)
		if (aiRadio.disabledAi || aiRestorePowerRoutine || stat)
			src << "<span class='danger'>System Error - Transceiver Disabled.</span>"
			return 0
		if(message_mode == "general")
			message_mode = null
		return aiRadio.talk_into(src,message,message_mode,verb,speaking)

/mob/living/silicon/pai/handle_message_mode(message_mode, message, verb, speaking, used_radios, alt_name)
	..()
	if(message_mode)
		if(message_mode == "general")
			message_mode = null
		return radio.talk_into(src,message,message_mode,verb,speaking)

/mob/living/silicon/say_quote(var/text)
	var/ending = copytext(text, length(text))

	if (ending == "?")
		return speak_query
	else if (ending == "!")
		return speak_exclamation

	return speak_statement

#define IS_AI 1
#define IS_ROBOT 2
#define IS_PAI 3

/mob/living/silicon/say_understands(var/other,var/datum/language/speaking = null)
	//These only pertain to common. Languages are handled by mob/say_understands()
	if (!speaking)
		if (istype(other, /mob/living/carbon))
			return 1
		if (istype(other, /mob/living/silicon))
			return 1
		if (istype(other, /mob/living/carbon/brain))
			return 1
	return ..()

//For holopads only. Usable by AI.
/mob/living/silicon/ai/proc/holopad_talk(var/message, verb, datum/language/speaking)

	log_say("[key_name(src)] : [message]")

	message = trim(message)

	if (!message)
		return

	var/obj/machinery/hologram/holopad/H = src.holo
	if(H && H.masters[src])//If there is a hologram and its master is the user.

		// AI can hear their own message, this formats it for them.
		if(speaking)
			src << "<i><span class='game say'>Holopad transmitted, <span class='name'>[real_name]</span> [speaking.format_message(message, verb)]</span></i>"
		else
			src << "<i><span class='game say'>Holopad transmitted, <span class='name'>[real_name]</span> [verb], <span class='message'><span class='body'>\"[message]\"</span></span></span></i>"

		//This is so pAI's and people inside lockers/boxes,etc can hear the AI Holopad, the alternative being recursion through contents.
		//This is much faster.
		var/list/listening = list()
		var/list/listening_obj = list()
		var/turf/T = get_turf(H)

		if(T)
			var/list/hear = hear(7, T)
			var/list/hearturfs = list()

			for(var/I in hear)
				if(istype(I, /mob/))
					var/mob/M = I
					listening += M
					hearturfs += M.locs[1]
					for(var/obj/O in M.contents)
						listening_obj |= O
				else if(istype(I, /obj/))
					var/obj/O = I
					hearturfs += O.locs[1]
					listening_obj |= O


			for(var/mob/M in player_list)
				if(M.stat == DEAD && M.is_preference_enabled(/datum/client_preference/ghost_ears))
					M.hear_say(message,verb,speaking,null,null, src)
					continue
				if(M.loc && (M.locs[1] in hearturfs))
					M.hear_say(message,verb,speaking,null,null, src)


	else
		src << "No holopad connected."
		return 0
	return 1

/mob/living/silicon/ai/proc/holopad_emote(var/message) //This is called when the AI uses the 'me' verb while using a holopad.

	log_emote("[key_name(src)] : [message]")

	message = trim(message)

	if (!message)
		return

	var/obj/machinery/hologram/holopad/T = src.holo
	if(T && T.masters[src])
		var/rendered = "<span class='game say'><span class='name'>[name]</span> <span class='message'>[message]</span></span>"
		src << "<i><span class='game say'>Holopad action relayed, <span class='name'>[real_name]</span> <span class='message'>[message]</span></span></i>"

		for(var/mob/M in viewers(T.loc))
			M.show_message(rendered, 2)
	else //This shouldn't occur, but better safe then sorry.
		src << "No holopad connected."
		return 0
	return 1

/mob/living/silicon/ai/emote(var/act, var/type, var/message)
	var/obj/machinery/hologram/holopad/T = src.holo
	if(T && T.masters[src]) //Is the AI using a holopad?
		src.holopad_emote(message)
	else //Emote normally, then.
		..()

#undef IS_AI
#undef IS_ROBOT
#undef IS_PAI
