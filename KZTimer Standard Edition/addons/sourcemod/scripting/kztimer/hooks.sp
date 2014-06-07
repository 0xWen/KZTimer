// - PlayerSpawn -
public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client != 0)
	{	
		if (!g_bRoundEnd)
		{	
			g_fStartCommandUsed_LastTime[client] = GetEngineTime();
			g_bPlayerJumped[client] = false;
			g_SpecTarget[client] = -1;	
			
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
				g_iBotMimicTick[client] = 0;
				g_iCurrentAdditionalTeleportIndex[client] = 0;
			}	
			
			if (IsFakeClient(client))	
			{
				CS_SetClientClanTag(client, "LOCALHOST"); 
				return;
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
			if (g_bFirstSpawn[client])		
			{
				CreateTimer(1.5, StartMsgTimer, client,TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(15.0, WelcomeMsgTimer, client,TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(70.0, HelpMsgTimer, client,TIMER_FLAG_NO_MAPCHANGE);	
				CreateTimer(500.0, SteamGroupTimer, client,TIMER_FLAG_NO_MAPCHANGE);			
				g_bFirstSpawn[client] = false;
			}

			//1st spawn & t/ct
			if (g_bFirstSpawn2[client] && (GetClientTeam(client) > 1))		
			{
				StartRecording(client);
				CreateTimer(1.5, CenterMsgTimer, client,TIMER_FLAG_NO_MAPCHANGE);		
				g_bFirstSpawn2[client] = false;
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
				
				CreateTimer(0.0, ClimbersMenuTimer, client,TIMER_FLAG_NO_MAPCHANGE);
			}
			
			//hide radar
			CreateTimer(0.0, HideRadar, client,TIMER_FLAG_NO_MAPCHANGE);
			
			//set clantag
			CreateTimer(1.5, SetClanTag, client,TIMER_FLAG_NO_MAPCHANGE);	
			
			//set speclist
			Format(g_szPlayerPanelText[client], 512, "");		

			if (g_bClimbersMenuOpen2[client] && (GetClientTeam(client) > 1))
			{
				g_bClimbersMenuOpen2[client] = false;
				ClimbersMenu(client);
			}

			//get speed & origin
			g_fLastSpeed[client] = GetSpeed(client);
			GetClientAbsOrigin(client, g_fLastPosition[client]);						
		}
	}
}

public Action:Event_OnPlayerTeamPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetEventBroadcast(event, true);
	return Plugin_Continue;
} 

public Action:Say_Hook(client, args)
{
	g_bSayHook[client]=true;
	if (client > 0 && IsClientInGame(client))
	{		
		decl String:sText[1024];
		GetCmdArgString(sText, sizeof(sText));
		StripQuotes(sText);
		new team = GetClientTeam(client);		
		TrimString(sText); 

		if(StrEqual(sText, " ") || StrEqual(sText, ""))
		{
			g_bSayHook[client]=false;
			return Plugin_Handled;		
		}
		decl String:sPath[PLATFORM_MAX_PATH];
		decl String:line[64]
		BuildPath(Path_SM, sPath, sizeof(sPath), "%s", EXCEPTION_LIST_PATH);
		new Handle:fileHandle=OpenFile(sPath,"r");		
		
		//fix chat text
		while(!IsEndOfFile(fileHandle)&&ReadFileLine(fileHandle,line,sizeof(line)))
		{
			TrimString(line);
			if (StrEqual(line,sText,false))
			{
				StopClimbersMenu(client);
				break;
			}
		}
		CloseHandle(fileHandle);
		
		for(new i; i < sizeof(BlockedChatText); i++)
		{
			if (StrEqual(BlockedChatText[i],sText,true))
			{
				g_bSayHook[client]=false;
				return Plugin_Handled;			
			}
		}	
		
		if (StrEqual("timeleft",sText,true))
		{
			new timeleft;
			GetMapTimeLeft(timeleft);
			new Float:ftime = float(timeleft);
			FormatTimeFloat(client,ftime,4);
			PrintToChat(client,"[%cKZ%c] Timeleft: %s",MOSSGREEN,WHITE, g_szTime[client]);
			g_bSayHook[client]=false;
			return Plugin_Handled;
		}	
		
		if (StrEqual("nextmap",sText,true))
		{
			decl String:NextMap[64];
			GetNextMap(NextMap, sizeof(NextMap));
			PrintToChat(client,"[%cKZ%c] Nextmap: %s",MOSSGREEN,WHITE, NextMap);
			g_bSayHook[client]=false;
			return Plugin_Handled;
		}
		
		
		//SPEC
		if (team==1)
		{
			PrintSpecMessageAll(client);
			g_bSayHook[client]=false;
			return Plugin_Handled;
		}
		else
		{
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
				{
					if (team==CS_TEAM_T)
					{
						CPrintToChatAll("%c%s%c [%c%s%c] {orange}%s%c: %s",GREEN,g_szCountryCode[client],WHITE,GRAY,g_pr_rankname[client],WHITE,szName,WHITE,sText);
						PrintToConsole(client," %s [%s] %s: %s",g_szCountryCode[client],g_pr_rankname[client],szName,sText);
					}
					else
						CPrintToChatAll("%c%s%c [%c%s%c] {blue}%s%c: %s",GREEN,g_szCountryCode[client],WHITE,GRAY,g_pr_rankname[client],WHITE,szName,WHITE,sText);
				
				}
				else
				{
					if (team==CS_TEAM_T)
					{
						CPrintToChatAll("%c%s%c [%c%s%c] {orange}*DEAD* %s%c: %s",GREEN,g_szCountryCode[client],WHITE,GRAY,g_pr_rankname[client],WHITE,szName,WHITE,sText);
						PrintToConsole(client," %s [%s] *DEAD* %s: %s",g_szCountryCode[client],g_pr_rankname[client],szName,sText);
					}
					else
						CPrintToChatAll("%c%s%c [%c%s%c] {blue}*DEAD* %s%c: %s",GREEN,g_szCountryCode[client],WHITE,GRAY,g_pr_rankname[client],WHITE,szName,WHITE,sText);		
											
				}
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
					{
						if (team==CS_TEAM_T)
						{
							CPrintToChatAll("[%c%s%c] {orange}%s%c: %s",GRAY,g_pr_rankname[client],WHITE,szName,WHITE,sText);
							PrintToConsole(client,"^[%s] %s: %s",g_pr_rankname[client],szName,sText);
						}
						else
							CPrintToChatAll("[%c%s%c] {blue}%s%c: %s",GRAY,g_pr_rankname[client],WHITE,szName,WHITE,sText);
					}
					else
					{
						if (team==CS_TEAM_T)
						{
							CPrintToChatAll("[%c%s%c] {orange}*DEAD* %s%c: %s",GRAY,g_pr_rankname[client],WHITE,szName,WHITE,sText);
							PrintToConsole(client," [%s] *DEAD* %s: %s",g_pr_rankname[client],szName,sText);
						}
						else
							CPrintToChatAll("[%c%s%c] {blue}*DEAD* %s%c: %s",GRAY,g_pr_rankname[client],WHITE,szName,WHITE,sText);			
					}			
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
						{
							if (team==CS_TEAM_T)
							{
								CPrintToChatAll("[%c%s%c] {orange}%s%c: %s",GREEN,g_szCountryCode[client],WHITE,szName,WHITE,sText);
								PrintToConsole(client," [%s] %s: %s",g_szCountryCode[client],szName,sText);
							}
							else
								CPrintToChatAll("[%c%s%c] {blue}%s%c: %s",GREEN,g_szCountryCode[client],WHITE,szName,WHITE,sText);
						}
						else
						{
							if (team==CS_TEAM_T)
							{
								CPrintToChatAll("[%c%s%c] {orange}*DEAD* %s%c: %s",GREEN,g_szCountryCode[client],WHITE,szName,WHITE,sText);
								PrintToConsole(client," [%s] *DEAD* %s: %s",g_szCountryCode[client],szName,sText);
							}
							else
								CPrintToChatAll("[%c%s%c] {blue}*DEAD* %s%c: %s",GREEN,g_szCountryCode[client],WHITE,szName,WHITE,sText);			
						}			
						g_bSayHook[client]=false;
						return Plugin_Handled;							
					}			
			
			}
		}	
	}
	g_bSayHook[client]=false;
	return Plugin_Continue;
}

public Action:Event_OnPlayerTeamPost(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return;
	new team = GetEventInt(event, "team");
	if(team == 1)
	{
		if (!g_bFirstSpawn2[client])
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
	
	//team join msg
	new String:strTeamName[32];
	if (team==1)
		Format(strTeamName, 32, "Spectators");
	else
		if (team==2)
			Format(strTeamName, 32, "Terrorist force");	
		else
			Format(strTeamName, 32, "Counter-terrorist force");	
	if (client != 0 && !IsFakeClient(client))
	{
		for (new i = 1; i <= MaxClients; i++)
			if (IsClientConnected(i) && IsClientInGame(i) && i != client)
				PrintToChat(i, "%t", "TeamJoin",client,strTeamName);
	}
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
    if (client != entity && (0 < entity <= MaxClients) && IsClientInGame(client)) 
	{
		if (g_bChallenge[client])
		{
			decl String:szSteamId[32];
			GetClientAuthString(entity, szSteamId, 32);	
			if (!StrEqual(szSteamId, g_szCOpponentID[client], false))
				return Plugin_Handled;
		}
		else
			if (g_bHide[client] && entity != g_SpecTarget[client])
				return Plugin_Handled; 
	}	
    return Plugin_Continue; 
}  

// - PlayerDeath -
public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));	
	if(!client)
		return;
	if (!IsFakeClient(client))
	{
		if(g_hRecording[client] != INVALID_HANDLE)
			StopRecording(client);
		CreateTimer(0.5, OnDeathTimer, client,TIMER_FLAG_NO_MAPCHANGE);
	}
	else 
	if(g_hBotMimicsRecord[client] != INVALID_HANDLE)
	{
		g_iBotMimicTick[client] = 0;
		g_iCurrentAdditionalTeleportIndex[client] = 0;
		if(GetClientTeam(client) >= CS_TEAM_T)
			CreateTimer(1.0, Timer_DelayedRespawn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}
					
public Action:CS_OnTerminateRound(&Float:delay, &CSRoundEndReason:reason)
{
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
	SetEntPropEnt(client, Prop_Send, "m_bSpotted", 0); 

//fpscheck
public FPSCheck(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (IsClientConnected(client) && !IsFakeClient(client) && !g_bKickStatus[client])
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

//thx to TnTSCS (player slap stops timer)
//https://forums.alliedmods.net/showthread.php?t=233966
public Action:OnLogAction(Handle:source, Identity:ident, client, target, const String:message[])
{	
    if ((1 > target > MaxClients))
        return Plugin_Continue;
    if (IsValidEntity(target) && IsClientInGame(target) && IsPlayerAlive(target) && g_bTimeractivated[target] && !IsFakeClient(target))
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
	if (g_bRoundEnd || 1 > client > MaxClients || !IsClientInGame(client))
		return Plugin_Continue;	
	
	//client information
	g_CurrentButton[client] = buttons;
	GetClientAbsOrigin(client, origin);
	GetClientEyeAngles(client, ang);			
	speed = GetSpeed(client);	
	
	//Set ground frames
	if (g_bPlayerJumped[client] == false && GetEntityFlags(client) & FL_ONGROUND && ((buttons & IN_MOVERIGHT) || (buttons & IN_MOVELEFT) || (buttons & IN_BACK) || (buttons & IN_FORWARD)))
		g_ground_frames[client]++;
					
	//some methods..	
	if(IsValidEntity(client) && IsClientInGame(client) && IsPlayerAlive(client))	
	{		
		MenuRefresh(client);
		//replay bots
		PlayReplay(client, buttons, subtype, seed, impulse, weapon, angles, vel);
		RecordReplay(client, buttons, subtype, seed, impulse, weapon, angles, vel);
		//movement modifications
		AutoBhopFunction(client, buttons);
		Prestrafe(client,mouse[0], buttons);
		SpeedCap(client);	
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
		if (g_bPlayerJumped[client] == false && GetEntityFlags(client) & FL_ONGROUND && ((buttons & IN_JUMP)))
		{
			decl Float:temp[3], Float: pos[3];
			GetClientAbsOrigin(client,pos);
			g_bLJBlockValidJumpoff[client]=false;
			if(g_bLJBlock[client])
			{
				g_bLJBlockValidJumpoff[client]=true;
				g_bLjStarDest[client]=false;
				GetEdgeOrigin(client, origin, temp);
				g_EdgeDist[client] = GetVectorDistance(temp, origin);
				if(!IsCoordInBlockPoint(pos,g_OriginBlock[client],false))				
					if(IsCoordInBlockPoint(pos,g_DestBlock[client],false))
					{
						g_bLjStarDest[client]=true;
					}
					else
						g_bLJBlockValidJumpoff[client]=false;
			}
		}
		if(g_bLJBlock[client])
		{
			TE_SendBlockPoint(client, g_DestBlock[client][0], g_DestBlock[client][1], g_Beam[0]);
			TE_SendBlockPoint(client, g_OriginBlock[client][0], g_OriginBlock[client][1], g_Beam[0]);
		}		
	}
	
	// postthink jumpstats (landing)	
	if(GetEntityFlags(client) & FL_ONGROUND && !g_bInvalidGround[client] && !g_bLastInvalidGround[client] && g_bPlayerJumped[client] == true && weapon != -1 && IsValidEntity(weapon) && GetEntProp(client, Prop_Data, "m_nWaterLevel") < 1)
	{		
		GetGroundOrigin(client, g_fJump_Final[client]);
		if (g_bJumpStats && !g_bKickStatus[client])
			Postthink(client);
	}	
				
	//reset/save current values
	if (GetEntityFlags(client) & FL_ONGROUND)
		g_bLastInvalidGround[client] = g_bInvalidGround[client];		
	if (!(GetEntityFlags(client) & FL_ONGROUND) && g_bPlayerJumped[client] == false)
		g_ground_frames[client] = 0;			
	g_fLastAngles[client] = ang;
	g_fLastSpeed[client] = speed;
	g_fLastPosition[client] = origin;
	g_LastButton[client] = buttons;
	return Plugin_Continue;
}


public Action:Event_OnJump(Handle:Event, const String:Name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Event, "userid"));	
	new Float:time = GetGameTime();
	g_fLastJump[client] = time;
	new bool:touchwall = WallCheck(client);	
	if (g_bJumpStats && !touchwall)
		Prethink(client, Float:{0.0,0.0,0.0},0.0);
}
			
public OnEntityCreated(iEntity, const String:classname[]) 
{ 
	if (1 <= iEntity <= MaxClients && IsClientInGame(iEntity))
	{	
		if(StrEqual(classname, "player"))   
			SDKHook(iEntity, SDKHook_StartTouch, OnTouch);
	}
}

public OnTouch(client, other)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
		if ((1 <= client <= MaxClients) && other != 0)
			if (g_bPlayerJumped[client])
				ResetJump(client);
}  

public Teleport_OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	if (1 <= activator <= MaxClients && IsClientInGame(activator))
		g_bValidTeleport[activator]=true;
}  

//https://forums.alliedmods.net/showthread.php?p=1678026 by Inami
public Action:Event_OnJumpMacroDox(Handle:Event, const String:Name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Event, "userid"));	
	if(IsClientInGame(client) && !IsFakeClient(client) && !g_bAutoBhop2)
	{	
		afAvgJumps[client] = ( afAvgJumps[client] * 9.0 + float(aiJumps[client]) ) / 10.0;	
		decl Float:vec_vel[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec_vel);
		vec_vel[2] = 0.0;
		new Float:speed = GetVectorLength(vec_vel);
		afAvgSpeed[client] = (afAvgSpeed[client] * 9.0 + speed) / 10.0;
		
		aaiLastJumps[client][aiLastPos[client]] = aiJumps[client];
		aiLastPos[client]++;
		if (aiLastPos[client] == 30)
		{
			aiLastPos[client] = 0;
		}
		
		if (afAvgJumps[client] > 15.0)
		{
			if ((aiPatternhits[client] > 0) && (aiJumps[client] == aiPattern[client]))
			{
				aiPatternhits[client]++;
				if (aiPatternhits[client] > 15)
				{
					if (g_bAntiCheat && !bFlagged[client])
					{
						//new String:banstats[256];
						//GetClientStatsLog(client, banstats, sizeof(banstats));		
						//decl String:sPath[512];
						//BuildPath(Path_SM, sPath, sizeof(sPath), "%s", ANTICHEAT_LOG_PATH);
						//LogToFile(sPath, "%s pattern jumps", banstats);		
						bFlagged[client] = true;
					}
				}
			}
			else if ((aiPatternhits[client] > 0) && (aiJumps[client] != aiPattern[client]))
			{
				aiPatternhits[client] -= 2;
			}
			else
			{
				aiPattern[client] = aiJumps[client];
				aiPatternhits[client] = 2;
			}
		}
		
		if(afAvgJumps[client] > 14.0)
		{
			//check if more than 8 of the last 30 jumps were above 12
			iNumberJumpsAbove[client] = 0;
			
			for (new i = 0; i < 29; i++)	//count
			{
				if((aaiLastJumps[client][i]) > (14 - 1))	//threshhold for # jump commands
				{
					iNumberJumpsAbove[client]++;
				}
			}
			if((iNumberJumpsAbove[client] > (14 - 1)) && (afAvgPerfJumps[client] >= 0.4))	//if more than #
			{
				//glitchy
				if (g_bAntiCheat && !bFlagged[client])
				{
					/*if (!g_bHyperscrollWarning[client])
					{
						CreateTimer(10.0, HyperscrollWarningTimer, client,TIMER_FLAG_NO_MAPCHANGE);
						if (g_bAutoBan)
							PrintToChat(client, "%t", "Hyperscroll", MOSSGREEN,WHITE,DARKRED);
					}
					else
					{
						if (g_BGlobalDBConnected && g_bGlobalDB)
						{
							decl String:szName[64];
							GetClientName(client,szName,64);
							db_InsertBan(g_szSteamID[client], szName);
						}
						new String:banstats[256];
						GetClientStatsLog(client, banstats, sizeof(banstats));		
						decl String:sPath[512];
						BuildPath(Path_SM, sPath, sizeof(sPath), "%s", ANTICHEAT_LOG_PATH);
						if (g_bAutoBan)
							LogToFile(sPath, "%s reason: hyperscroll (autoban)", banstats);	
						else
							LogToFile(sPath, "%s reason: hyperscroll", banstats);	
						bFlagged[client] = true;	
						if (g_bAutoBan)	
							PerformBan(client,"hyperscroll");
					}*/
				}
			}
		}
		else if(aiJumps[client] > 1)
		{
			aiAutojumps[client] = 0;
		}

		aiJumps[client] = 0;
		new Float:tempvec[3];
		tempvec = avLastPos[client];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", avLastPos[client]);
		
		new Float:len = GetVectorDistance(avLastPos[client], tempvec, true);
		if (len < 30.0)
		{   
			aiIgnoreCount[client] = 2;
		}
		
		if (afAvgPerfJumps[client] >= 0.9)
		{
			if (g_bAntiCheat && !bFlagged[client])
			{
				if (g_BGlobalDBConnected && g_bGlobalDB)
				{
					decl String:szName[64];
					GetClientName(client,szName,64);
					db_InsertBan(g_szSteamID[client], szName);
				}
				new String:banstats[256];
				GetClientStatsLog(client, banstats, sizeof(banstats));		
				decl String:sPath[512];
				BuildPath(Path_SM, sPath, sizeof(sPath), "%s", ANTICHEAT_LOG_PATH);
				if (g_bAutoBan)
					LogToFile(sPath, "%s reason: bhop hack (autoban)", banstats);	
				else
					LogToFile(sPath, "%s reason: bhop hack", banstats);	
				bFlagged[client] = true;
				if (g_bAutoBan)	
					PerformBan(client,"a bhop hack");
			}
		}
	}
}