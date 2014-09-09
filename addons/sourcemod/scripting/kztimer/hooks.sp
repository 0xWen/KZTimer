// - PlayerSpawn -
public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client != 0)
	{	
		if (!g_bRoundEnd)
		{	
			g_fStartCommandUsed_LastTime[client] = GetEngineTime();
			g_js_bPlayerJumped[client] = false;
			g_bSlowDownCheck[client] = false;
			g_SpecTarget[client] = -1;	
			g_bOnGround[client] = true;
			g_MouseAbsCount[client] = 0;
			g_SpeedRefreshCount[client] = 0;
			
			//remove weapons
			if (g_bCleanWeapons && (GetClientTeam(client) > 1))
				StripWeapons(client);
				
			//godmode
			if (g_bgodmode || IsFakeClient(client))
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			else
				SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
				
			//NoBlock
			if(g_bNoBlock || IsFakeClient(client))
				SetEntData(client, FindSendPropOffs("CBaseEntity", "m_CollisionGroup"), 2, 4, true);
			else
				SetEntData(client, FindSendPropOffs("CBaseEntity", "m_CollisionGroup"), 5, 4, true);
								
			//botmimic2		
			if(g_hBotMimicsRecord[client] != INVALID_HANDLE && IsFakeClient(client))
			{
				g_BotMimicTick[client] = 0;
				g_CurrentAdditionalTeleportIndex[client] = 0;
			}	
			
			if (IsFakeClient(client))	
			{
				if (client==g_InfoBot)
					CS_SetClientClanTag(client, ""); 	
				else
					CS_SetClientClanTag(client, "LOCALHOST"); 	
				return Plugin_Continue;
			}
			
			//fps Check
			if (g_bfpsCheck)
				QueryClientConVar(client, "fps_max", ConVarQueryFinished:FPSCheck, client);		
			
			//change player skin
			if (g_bPlayerSkinChange && (GetClientTeam(client) > 1))
			{
				SetEntPropString(client, Prop_Send, "m_szArmsModel", g_sArmModel);
				SetEntityModel(client,  g_sPlayerModel);
			}		
			
			//1st spawn?
			if (g_bFirstTeamJoin[client])		
			{
				CreateTimer(1.5, StartMsgTimer, client,TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(15.0, WelcomeMsgTimer, client,TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(70.0, HelpMsgTimer, client,TIMER_FLAG_NO_MAPCHANGE);	
				CreateTimer(355.0, SteamGroupTimer, client,TIMER_FLAG_NO_MAPCHANGE);			
				g_bFirstTeamJoin[client] = false;
			}

			//1st spawn & t/ct
			if (g_bFirstSpawn[client] && (GetClientTeam(client) > 1))		
			{
				StartRecording(client);
				CreateTimer(1.5, CenterMsgTimer, client,TIMER_FLAG_NO_MAPCHANGE);		
				g_bFirstSpawn[client] = false;
			}
			
			//get start pos for challenge
			GetClientAbsOrigin(client, g_fSpawnPosition[client]);
			
			//restore position (before spec or last session) && Climbers Menu
			if ((GetClientTeam(client) > 1))
			{
				if (g_bRestoreC[client])
				{			
					g_bPositionRestored[client] = true;
					TeleportEntity(client, g_fPlayerCordsRestore[client],g_fPlayerAnglesRestore[client],NULL_VECTOR);
					g_bRestoreC[client]  = false;
				}
				else
					if (g_bRespawnPosition[client])
					{
						TeleportEntity(client, g_fPlayerCordsRestore[client],g_fPlayerAnglesRestore[client],NULL_VECTOR);
						g_bRespawnPosition[client] = false;
					}		
					else
						if (g_bAutoTimer)
							CL_OnStartTimerPress(client);
						else
						{
							g_bTimeractivated[client] = false;	
							g_fStartTime[client] = -1.0;
							g_fCurrentRunTime[client] = -1.0;	
						}			
				CreateTimer(0.0, ClimbersMenuTimer, client,TIMER_FLAG_NO_MAPCHANGE);
			}
	
			
			//hide radar
			CreateTimer(0.0, HideRadar, client,TIMER_FLAG_NO_MAPCHANGE);
			
			//set clantag
			CreateTimer(1.5, SetClanTag, client,TIMER_FLAG_NO_MAPCHANGE);	
					
			//set speclist
			Format(g_szPlayerPanelText[client], 512, "");		
			
			if (g_bClimbersMenuwasOpen[client] && (GetClientTeam(client) > 1))
			{
				g_bClimbersMenuwasOpen[client] = false;
				ClimbersMenu(client);
			}

			//get speed & origin
			g_fLastSpeed[client] = GetSpeed(client);
			GetClientAbsOrigin(client, g_fLastPosition[client]);						
		}
		else
			CreateTimer(0.1, MoveTypeNoneTimer, client,TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bConnectMsg)
	{
		decl String:szName[64];
		new String:disconnectReason[64];
		new clientid = GetEventInt(event,"userid");
		new client = GetClientOfUserId(clientid);
		if (!IsValidClient(client) || IsFakeClient(client))
			return Plugin_Handled;
		GetEventString(event, "name", szName, sizeof(szName));
		GetEventString(event, "reason", disconnectReason, sizeof(disconnectReason));  
		for (new i = 1; i <= MaxClients; i++)
			if (IsValidClient(i) && i != client && !IsFakeClient(i))
				PrintToChat(i, "%t", "Disconnected1",WHITE, MOSSGREEN, szName, WHITE, disconnectReason);	
		return Plugin_Handled;
	}
	else
		return Plugin_Continue;
}

public Action:Say_Hook(client, const String:command[], argc)
{
	//Call Admin - Own Reason
	if (g_bClientOwnReason[client])
	{
		StopClimbersMenu(client);
		g_bClientOwnReason[client] = false;
		return Plugin_Continue;
	}
	
	//Chat trigger?
	g_bSayHook[client]=true;
	if (IsValidClient(client))
	{		
		decl String:sText[1024];
		GetCmdArgString(sText, sizeof(sText));
		StripQuotes(sText);
		new team = GetClientTeam(client);		
		TrimString(sText); 

		//empty message
		if(StrEqual(sText, " ") || StrEqual(sText, ""))
		{
			g_bSayHook[client]=false;
			return Plugin_Handled;		
		}

		//lowercase
		if((sText[0] == '/') || (sText[0] == '!'))
		{
			if(IsCharUpper(sText[1]))
			{
				for(new i = 0; i <= strlen(sText); ++i)
						sText[i] = CharToLower(sText[i]);
				g_bSayHook[client]=false;
				FakeClientCommand(client, "say %s", sText);
				return Plugin_Handled;
			}
		}
		
		//blocked commands
		for(new i; i < sizeof(BlockedChatText); i++)
		{
			if (StrEqual(BlockedChatText[i],sText,true))
			{
				g_bSayHook[client]=false;
				return Plugin_Handled;			
			}
		}	
		
		//chat trigger?
		if((IsChatTrigger() && sText[0] == '/') || (sText[0] == '@' && (GetUserFlagBits(client) & ADMFLAG_ROOT ||  GetUserFlagBits(client) & ADMFLAG_GENERIC)))
		{
			g_bSayHook[client]=false;
			return Plugin_Continue;
		}
		
		////////////////
		//say stuff
		//
		//SPEC
		if (team==1)
		{
			PrintSpecMessageAll(client);
			g_bSayHook[client]=false;
			return Plugin_Handled;
		}
		else
		{
			decl String:szChatRank[64];
			if (g_bColoredChatRanks)
				Format(szChatRank, 64, "%s",g_pr_chat_coloredrank[client]);
			else
				Format(szChatRank, 64, "%s",g_pr_rankname[client]);
			
			
			if (g_bCountry && (g_bPointSystem || ((StrEqual(g_pr_rankname[client], "ADMIN", false)) && g_bAdminClantag) || ((StrEqual(g_pr_rankname[client], "VIP", false)) && g_bVipClantag)))
			{						
				if (StrEqual(sText,""))
				{
					g_bSayHook[client]=false;
					return Plugin_Handled;
				}
				decl String:szName[32];
				GetClientName(client,szName,32);
				if (IsPlayerAlive(client))
					CPrintToChatAllEx(client,"{green}%s{default} [{grey}%s{default}] {teamcolor}%s{default}: %s",g_szCountryCode[client],szChatRank,szName,sText);			
				else
					CPrintToChatAllEx(client,"{green}%s{default} [{grey}%s{default}] {teamcolor}*DEAD* %s{default}: %s",g_szCountryCode[client],szChatRank,szName,sText);
				g_bSayHook[client]=false;				
				return Plugin_Handled;
			}
			else
			{
				if (g_bPointSystem || ((StrEqual(g_pr_rankname[client], "ADMIN", false)) && g_bAdminClantag) || ((StrEqual(g_pr_rankname[client], "VIP", false)) && g_bVipClantag))
				{
					if (StrEqual(sText,""))
					{
						g_bSayHook[client]=false;
						return Plugin_Handled;
					}
					decl String:szName[32];
					GetClientName(client,szName,32);
					if (IsPlayerAlive(client))
						CPrintToChatAllEx(client,"[{grey}%s{default}] {teamcolor}%s{default}: %s",szChatRank,szName,sText);	
					else
						CPrintToChatAllEx(client,"[{grey}%s{default}] {teamcolor}*DEAD* %s{default}: %s",szChatRank,szName,sText);			
					return Plugin_Handled;							
				}
				else
					if (g_bCountry)
					{
						if (StrEqual(sText,""))
						{
							g_bSayHook[client]=false;
							return Plugin_Handled;
						}
						decl String:szName[32];
						GetClientName(client,szName,32);
						if (IsPlayerAlive(client))
							CPrintToChatAllEx(client,"[{green}%s{default}] {teamcolor}%s{default}: %s",g_szCountryCode[client],szName,sText);	
						else
							CPrintToChatAllEx(client,"[{green}%s{default}] {teamcolor}*DEAD* %s{default}: %s",g_szCountryCode[client],szName,sText);		
						g_bSayHook[client]=false;
						return Plugin_Handled;							
					}								
			}
		}	
	}
	g_bSayHook[client]=false;
	return Plugin_Continue;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client) || IsFakeClient(client))
		return Plugin_Continue;
	new team = GetEventInt(event, "team");
	if(team == 1)
	{
		if (!g_bFirstSpawn[client])
		{
			GetClientAbsOrigin(client,g_fPlayerCordsRestore[client]);
			GetClientEyeAngles(client, g_fPlayerAnglesRestore[client]);
			g_bRespawnPosition[client] = true;
		}
		if (g_bTimeractivated[client] == true)
		{	
			g_fStartPauseTime[client] = GetEngineTime();
			if (g_fPauseTime[client] > 0.0)
				g_fStartPauseTime[client] = g_fStartPauseTime[client] - g_fPauseTime[client];	
		}
		g_bSpectate[client] = true;
		PrintToChat(client, "%t", "SpecInfo",MOSSGREEN,WHITE,GREEN,WHITE);
		if (g_bPause[client])
			g_bPauseWasActivated[client]=true;
		g_bPause[client]=false;
	}
	return Plugin_Continue;
}

public OnMapVoteStarted()
{
   	for(new client = 1; client <= MAXPLAYERS; client++)
	{
		g_bMenuOpen[client] = true;
		if (g_bClimbersMenuOpen[client])
			g_bClimbersMenuwasOpen[client]=true;
		else
			g_bClimbersMenuwasOpen[client]=false;		
		g_bClimbersMenuOpen[client] = false;
	}
}

public Action:Hook_SetTransmit(entity, client) 
{ 
    if (client != entity && (0 < entity <= MaxClients) && IsValidClient(client)) 
	{
		if (g_bChallenge[client] && !g_bHide[client] && entity != g_SpecTarget[client])
		{
			decl String:szSteamId[32];
			GetClientAuthString(entity, szSteamId, 32);	
			if (!StrEqual(szSteamId, g_szChallenge_OpponentID[client], false))
				return Plugin_Handled;
		}
		else
			if (g_bHide[client] && entity != g_SpecTarget[client])
				return Plugin_Handled; 
			else
				if (entity == g_InfoBot && entity != g_SpecTarget[client])
					return Plugin_Handled;
	}	
    return Plugin_Continue; 
}  

// - PlayerDeath -
public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event,"userid");
	if (IsValidClient(client))
	{
		if (!IsFakeClient(client))
		{			
			if(g_hRecording[client] != INVALID_HANDLE)
				StopRecording(client);			
			CreateTimer(2.0, RemoveRagdoll, client);
		}
		else 
			if(g_hBotMimicsRecord[client] != INVALID_HANDLE)
			{
				g_BotMimicTick[client] = 0;
				g_CurrentAdditionalTeleportIndex[client] = 0;
				if(GetClientTeam(client) >= CS_TEAM_T)
					CreateTimer(1.0, RespawnBot, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
	}
	return Plugin_Continue;
}
					
public Action:CS_OnTerminateRound(&Float:delay, &CSRoundEndReason:reason)
{
	if (g_bRoundEnd)
		return Plugin_Continue;
	new timeleft;
	GetMapTimeLeft(timeleft);
	if (timeleft>= -1)
		return Plugin_Handled;
	g_bRoundEnd=true;
	return Plugin_Continue;
}  

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bRoundEnd=true;
	return Plugin_Continue;
}

// OnRoundRestart
public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	FindNHookWalls();
	HookTrigger();
	g_bRoundEnd=false;
	db_selectMapButtons();
	OnPluginPauseChange(false);
	return Plugin_Continue; 
}

public Action:Event_OnRoundStart2(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iEnt;
	for(new i = 0; i < sizeof(EntityList); i++)
	{
		while((iEnt = FindEntityByClassname(iEnt, EntityList[i])) != -1)
		{
			AcceptEntityInput(iEnt, "Disable");
			AcceptEntityInput(iEnt, "Kill");
		}
	}
	return Plugin_Continue;
}

// PlayerHurt 
public Action:Event_OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bgodmode && g_Autohealing_Hp > 0)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new remainingHeatlh = GetEventInt(event, "health");
		if (remainingHeatlh>0)
		{
			if ((remainingHeatlh+g_Autohealing_Hp) > 100)
				SetEntData(client, FindSendPropOffs("CBasePlayer", "m_iHealth"), 100);
			else
				SetEntData(client, FindSendPropOffs("CBasePlayer", "m_iHealth"), remainingHeatlh+g_Autohealing_Hp);
		}
	}
	return Plugin_Continue; 
}

// PlayerDamage (if godmode 0)
public Action:Hook_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (g_bgodmode)
		return Plugin_Handled;
	return Plugin_Continue;
}

//hide enemies from radar
public Hook_Radar(client)
{
	SetEntPropEnt(client, Prop_Send, "m_bSpotted", 0); 
}
//fpscheck
public FPSCheck(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (IsValidClient(client) && !IsFakeClient(client) && !g_bKickStatus[client])
	{
		new fps_max = StringToInt(cvarValue);        
		if (fps_max < 100 || fps_max > 300 || fps_max<=0)
		{
			CreateTimer(10.0, KickPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
			PrintToChat(client, "%t", "KickMsg", DARKRED,WHITE,RED,WHITE,fps_max);
			g_bKickStatus[client]=true;
		}
	}
}

//Credits: TnTSCS
//https://forums.alliedmods.net/showthread.php?t=233966
public Action:OnLogAction(Handle:source, Identity:ident, client, target, const String:message[])
{	
    if ((1 > target > MaxClients))
        return Plugin_Continue;
    if (IsValidClient(target) && IsPlayerAlive(target) && g_bTimeractivated[target] && !IsFakeClient(target))
	{
		new String:logtag[PLATFORM_MAX_PATH];
		if (ident == Identity_Plugin)
			GetPluginFilename(source, logtag, sizeof(logtag));
		else
			Format(logtag, sizeof(logtag), "OTHER");
		if ((strcmp("playercommands.smx", logtag, false) == 0) ||(strcmp("slap.smx", logtag, false) == 0))
			Client_Stop(target, 0);
	}   
    return Plugin_Continue;
}  

// OnPlayerRunCmd
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	new Float:speed, Float:origin[3],Float:ang[3];
	if (g_bRoundEnd || !IsValidClient(client))
		return Plugin_Continue;	
	
	//client information
	g_CurrentButton[client] = buttons;
	GetClientAbsOrigin(client, origin);
	GetClientEyeAngles(client, ang);			
	speed = GetSpeed(client);	
	
	//Set ground frames
	if (g_js_bPlayerJumped[client] == false && GetEntityFlags(client) & FL_ONGROUND && ((buttons & IN_MOVERIGHT) || (buttons & IN_MOVELEFT) || (buttons & IN_BACK) || (buttons & IN_FORWARD)))
		g_js_GroundFrames[client]++;

	if (g_js_GroundFrames[client] > 10 && g_bOnBhopPlattform[client])
		g_bOnBhopPlattform[client] = false;
		
	//some methods..	
	if(IsPlayerAlive(client))	
	{	
		MenuRefresh(client);
		g_SpeedRefreshCount[client]++;
		if (g_SpeedRefreshCount[client] >= 8)
		{
			g_SpeedRefreshCount[client] = 0;
			g_fSpeed[client] = GetSpeed(client);
		}
		
		//undo check
		if(!g_bAllowCpOnBhopPlattforms && (g_bUndo[client] || g_bUndoTimer[client]))
		{
			buttons &= ~IN_JUMP;
			buttons &= ~IN_DUCK;
			if ((GetEntityFlags(client) & FL_ONGROUND) && g_bUndo[client])
			{
				CreateTimer(0.5, ResetUndo, client, TIMER_FLAG_NO_MAPCHANGE);
				g_bUndo[client]	= false;
			}
		}
			
		//replay bots
		PlayReplay(client, buttons, subtype, seed, impulse, weapon, angles, vel);
		RecordReplay(client, buttons, subtype, seed, impulse, weapon, angles, vel);
		//movement modifications
		if (!g_bProMode && !IsFakeClient(client))	
			SpeedCap(client);	
		else
		{
			ProMode_Slowdown(client);
			ProMode_SpeeCap(client);
		}
		AutoBhopFunction(client, buttons);
		Prestrafe(client,mouse[0], buttons);

		//jumpstats/timer
		ButtonPressCheck(client, buttons, origin, speed);
		TeleportCheck(client, origin);
		NoClipCheck(client);
		WaterCheck(client);
		BoosterCheck(client);
		WjJumpPreCheck(client,buttons);
		CalcJumpMaxSpeed(client, speed);
		CalcJumpHeight(client);
		CalcJumpSync(client, speed, ang[1], buttons);
		CalcLastJumpHeight(client, buttons, origin);		
		//anticheat
		BhopHackAntiCheat(client, buttons);
		StrafeHackAntiCheat(client, ang, buttons);
		//ljblock
		if (g_js_bPlayerJumped[client] == false && GetEntityFlags(client) & FL_ONGROUND && ((buttons & IN_JUMP)))
		{
			decl Float:temp[3], Float: pos[3];
			GetClientAbsOrigin(client,pos);
			g_bLJBlockValidJumpoff[client]=false;
			if(g_bLJBlock[client])
			{
				g_bLJBlockValidJumpoff[client]=true;
				g_bLjStarDest[client]=false;
				GetEdgeOrigin(client, origin, temp);
				g_fEdgeDist[client] = GetVectorDistance(temp, origin);
				if(!IsCoordInBlockPoint(pos,g_fOriginBlock[client],false))				
					if(IsCoordInBlockPoint(pos,g_fDestBlock[client],false))
					{
						g_bLjStarDest[client]=true;
					}
					else
						g_bLJBlockValidJumpoff[client]=false;
			}
		}
		if(g_bLJBlock[client])
		{
			TE_SendBlockPoint(client, g_fDestBlock[client][0], g_fDestBlock[client][1], g_Beam[0]);
			TE_SendBlockPoint(client, g_fOriginBlock[client][0], g_fOriginBlock[client][1], g_Beam[0]);
		}		
	}
		
	
	// postthink jumpstats (landing)	
	if(GetEntityFlags(client) & FL_ONGROUND && !g_js_bInvalidGround[client] && !g_bLastInvalidGround[client] && g_js_bPlayerJumped[client] == true && weapon != -1 && IsValidEntity(weapon) && GetEntProp(client, Prop_Data, "m_nWaterLevel") < 1)
	{		
		GetGroundOrigin(client, g_js_fJump_Landing_Pos[client]);
		g_fAirTime[client] = GetEngineTime() - g_fAirTime[client];
		if (g_bJumpStats && !g_bKickStatus[client])
			Postthink(client);
	}	
				
	//reset/save current values
	if (GetEntityFlags(client) & FL_ONGROUND)
		g_fLastPositionOnGround[client] = origin;
	if (GetEntityFlags(client) & FL_ONGROUND)
		g_bLastInvalidGround[client] = g_js_bInvalidGround[client];		
	if (!(GetEntityFlags(client) & FL_ONGROUND) && g_js_bPlayerJumped[client] == false)
		g_js_GroundFrames[client] = 0;			
	g_fLastAngles[client] = ang;
	g_fLastSpeed[client] = speed;
	g_fLastPosition[client] = origin;
	g_LastButton[client] = buttons;
	return Plugin_Continue;
}

public Action:Event_OnJump(Handle:Event, const String:Name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Event, "userid"));	
	new Float:time = GetEngineTime();	
	//noclip check
	new Float:last = time - g_fLastTimeNoClipUsed[client];
	if (last < 4.0)
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Float:{0.0,0.0,-100.0});
	
	g_fLastJump[client] = time;
	new bool:touchwall = WallCheck(client);	
	g_fAirTime[client] = GetEngineTime();
	if (g_bJumpStats && !touchwall)
		Prethink(client, Float:{0.0,0.0,0.0},0.0);
}
			
public OnEntityCreated(client, const String:classname[]) 
{ 
	if (IsValidClient(client))
	{	
		if(StrEqual(classname, "player"))   
			SDKHook(client, SDKHook_StartTouch, OnTouch);
	}
}

public Hook_PostThinkPost(entity)
{
	SetEntProp(entity, Prop_Send, "m_bInBuyZone", 0);
} 

public OnTouch(client, other)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		new String:classname[32];
		if (IsValidEdict(other))
			GetEntityClassname(other, classname, 32);		
		if (StrEqual(classname,"func_movelinear"))
		{
			g_js_bFuncMoveLinear[client] = true;
			return;
		}
		if (!(GetEntityFlags(client) & FL_ONGROUND) || other != 0)
			ResetJump(client);	
	}
}  

public Teleport_OnStartTouch(const String:output[], caller, client, Float:delay)
{
	if (IsValidClient(client))
	{
		if (!g_bAllowCpOnBhopPlattforms && (GetEntityFlags(client) & FL_ONGROUND))
			g_bOnBhopPlattform[client]=true;
		g_bValidTeleport[client]=true;
	}
}  

public Teleport_OnEndTouch(const String:output[], caller, client, Float:delay)
{
	if (IsValidClient(client) && g_bOnBhopPlattform[client])
		g_bOnBhopPlattform[client] = false;	
}  

//Credits: Macrodox by Inami
//https://forums.alliedmods.net/showthread.php?p=1678026
public Action:Event_OnJumpMacroDox(Handle:Event, const String:Name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Event, "userid"));	
	if(IsValidClient(client) && !IsFakeClient(client) && !g_bAutoBhop2)
	{	
		g_fafAvgJumps[client] = ( g_fafAvgJumps[client] * 9.0 + float(g_aiJumps[client]) ) / 10.0;	
		decl Float:vec_vel[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec_vel);
		vec_vel[2] = 0.0;
		new Float:speed = GetVectorLength(vec_vel);
		g_fafAvgSpeed[client] = (g_fafAvgSpeed[client] * 9.0 + speed) / 10.0;
		
		g_aaiLastJumps[client][g_NumberJumpsAbove[client]] = g_aiJumps[client];
		g_NumberJumpsAbove[client]++;
		if (g_NumberJumpsAbove[client] == 30)
		{
			g_NumberJumpsAbove[client] = 0;
		}
		
		//pattern jumps 
		if (g_fafAvgJumps[client] > 15.0)
		{
			if ((g_aiPatternhits[client] > 0) && (g_aiJumps[client] == g_aiPattern[client]))
			{
				g_aiPatternhits[client]++;
				if (g_aiPatternhits[client] > 15)
				{
					if (g_bAntiCheat && !g_bFlagged[client])
					{					
						//new String:banstats[256];
						//GetClientStatsLog(client, banstats, sizeof(banstats));		
						//decl String:sPath[512];
						//BuildPath(Path_SM, sPath, sizeof(sPath), "%s", ANTICHEAT_LOG_PATH);
						//LogToFile(sPath, "%s pattern jumps", banstats);		
						g_bFlagged[client] = true;
					}
				}
			}
			else if ((g_aiPatternhits[client] > 0) && (g_aiJumps[client] != g_aiPattern[client]))
			{
				g_aiPatternhits[client] -= 2;
			}
			else
			{
				g_aiPattern[client] = g_aiJumps[client];
				g_aiPatternhits[client] = 2;
			}
		}
		
		//hyperscroll
		if(g_fafAvgJumps[client] > 14.0)
		{
			//check if more than 8 of the last 30 jumps were above 12
			g_NumberJumpsAbove[client] = 0;
			
			for (new i = 0; i < 29; i++)	//count
			{
				if((g_aaiLastJumps[client][i]) > (14 - 1))	//threshhold for # jump commands
				{
					g_NumberJumpsAbove[client]++;
				}
			}
			if((g_NumberJumpsAbove[client] > (14 - 1)) && (g_fafAvgPerfJumps[client] >= 0.4))	//if more than #
			{
				//glitchy
				if (g_bAntiCheat && !g_bFlagged[client])
				{
					/*if (!g_bHyperscrollWarning[client])
					{
						CreateTimer(10.0, HyperscrollWarningTimer, client,TIMER_FLAG_NO_MAPCHANGE);
						if (g_bAutoBan)
							PrintToChat(client, "%t", "Hyperscroll", MOSSGREEN,WHITE,DARKRED);
					}
					else
					{
						new String:banstats[256];
						GetClientStatsLog(client, banstats, sizeof(banstats));		
						decl String:sPath[512];
						BuildPath(Path_SM, sPath, sizeof(sPath), "%s", ANTICHEAT_LOG_PATH);
						if (g_bAutoBan)
							LogToFile(sPath, "%s reason: hyperscroll (autoban)", banstats);	
						else
							LogToFile(sPath, "%s reason: hyperscroll", banstats);	
						g_bFlagged[client] = true;	
						if (g_bAutoBan)	
							PerformBan(client,"hyperscroll");
					}*/
				}
			}
		}
		else if(g_aiJumps[client] > 1)
		{
			g_aiAutojumps[client] = 0;
		}

		g_aiJumps[client] = 0;
		new Float:tempvec[3];
		tempvec = g_favLastPos[client];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", g_favLastPos[client]);
		
		new Float:len = GetVectorDistance(g_favLastPos[client], tempvec, true);
		if (len < 30.0)
		{   
			g_aiIgnoreCount[client] = 2;
		}
		//bhop hack
		if (g_fafAvgPerfJumps[client] >= 0.9)
		{
			if (g_bAntiCheat && !g_bFlagged[client])
			{
				new String:banstats[256];
				GetClientStatsLog(client, banstats, sizeof(banstats));		
				decl String:sPath[512];
				BuildPath(Path_SM, sPath, sizeof(sPath), "%s", ANTICHEAT_LOG_PATH);
				if (g_bAutoBan)
					LogToFile(sPath, "%s reason: bhop hack (autoban)", banstats);	
				else
					LogToFile(sPath, "%s reason: bhop hack", banstats);	
				g_bFlagged[client] = true;
				if (g_bAutoBan)	
					PerformBan(client,"a bhop hack");
			}
		}
	}
}

//Credits: Timer by zipcore
//https://github.com/Zipcore/Timer/
FindNHookWalls()
{
	SDKHook(0,SDKHook_Touch,Touch_Wall);
	new ent = -1;
	while((ent = FindEntityByClassname(ent,"func_breakable")) != -1)

	SDKHook(ent,SDKHook_Touch,Touch_Wall);

	ent = -1;
	while((ent = FindEntityByClassname(ent,"func_illusionary")) != -1)

	SDKHook(ent,SDKHook_Touch,Touch_Wall);

	ent = -1;
	while((ent = FindEntityByClassname(ent,"func_wall")) != -1)
	SDKHook(ent,SDKHook_Touch,Touch_Wall);
}

//Credits: Timer by zipcore
//https://github.com/Zipcore/Timer/
public Action:Touch_Wall(ent,client)
{
	if(IsValidClient(client))
	{
		if(!(GetEntityFlags(client)&FL_ONGROUND)  && g_js_bPlayerJumped[client])
		{
			new Float:origin[3], Float:temp[3];
			GetGroundOrigin(client, origin);
			GetClientAbsOrigin(client, temp);
			if(temp[2] - origin[2] <= 0.2)
			{
				ResetJump(client);
			}
		}
	}
	return Plugin_Continue;
}
//Credits: Timer by zipcore
//https://github.com/Zipcore/Timer/
HookTrigger()
{
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "trigger_push")) != -1)
		SDKHook(ent,SDKHook_Touch,Push_Touch);
}

//Credits: Timer by zipcore
//https://github.com/Zipcore/Timer/
public Action:Push_Touch(ent,client)
{
	if(IsValidClient(client) && g_js_bPlayerJumped[client])
	{
		ResetJump(client);
	}
	return Plugin_Continue;
}

// Credits: Team Limit Bypass by Zephyrus
//https://forums.alliedmods.net/showthread.php?t=219812
public Action:Event_JoinTeamFailed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;
	new EJoinTeamReason:m_eReason = EJoinTeamReason:GetEventInt(event, "reason");
	new m_iTs = GetTeamClientCount(CS_TEAM_T);
	new m_iCTs = GetTeamClientCount(CS_TEAM_CT);
	switch(m_eReason)
	{
		case k_OneTeamChange:
		{
			return Plugin_Continue;
		}

		case k_TeamsFull:
		{
			if(m_iCTs == g_CTSpawns && m_iTs == g_TSpawns)
				return Plugin_Continue;
		}
		case k_TTeamFull:
		{
			if(m_iTs == g_TSpawns)
				return Plugin_Continue;
		}
		case k_CTTeamFull:
		{
			if(m_iCTs == g_CTSpawns)
				return Plugin_Continue;
		}
		default:
		{
			return Plugin_Continue;
		}
	}
	ChangeClientTeam(client, g_SelectedTeam[client]);

	return Plugin_Handled;
}