[ONLY TICKRATE 102.4 SUPPORTED -> srcds parameter -tickrate 102.4]
I have the feeling that kz maps are a bit too easy in csgo but i don't want to change the settings of kztimer because all players are accustomed to them. 
Therefore, i created a pro edition of kztimer which makes climing in csgo a lot harder and consistent. Please give some feedback if you decide to use this "special" edition.

Differences to casual edition:
- only tickrate 102.4 supported (Why? Tickrate 64 makes bunnyhops a bit random and Tickrate 128 gives u too much speed while you are in mid-air.)
- pro edition got his own global top
- server settings which makes climbing a lot harder but also consistent
 -> sv_airaccelerate 100;sv_staminalandcost 0.0;sv_staminajumpcost 0.15;sv_stopspeed 75;sv_maxspeed 320; sv_gravity 800; sv_friction 4;sv_accelerate 5;sv_maxvelocity 2000;sv_cheats 0;sm_cvar sv_enablebunnyhopping 1
 -> if your prestrafe go over 300 units per second you will automatically reset to a speed of 250
- settings enforcer and prestrafe can't be disabled. Those features are hard-coded in the pro edition.
- removed kz_settings_enforcer, kz_fpscheck, kz_prestrafe, kz_force_jump_penalty, kz_max_prespeed_bhop_dropbhop, kz_auto_timer, kz_auto_bhop, kz_speed_cap
