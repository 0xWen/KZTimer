// timer.sp

public Action:RefreshAdminMenu(Handle:timer, any:client)
{
	if (IsValidEntity(client) && !IsFakeClient(client))
		KzAdminMenu(client);
}

public Action:DBUpdateTimer(Handle:timer, any:client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))	
		db_updateStat(client);	
}

public Action:RefreshPoints(Handle:timer, any:client)
{
	db_updateStat(client);	
}

public Action:HyperscrollWarningTimer(Handle:timer, any:client)
{
	g_bHyperscrollWarning[client] = true;
}

public Action:MoveTypeNoneTimer(Handle:timer, any:client)
{
	SetEntityMoveType(client, MOVETYPE_NONE);
}

public Action:BhopCheck(Handle:timer, any:client)
{
	if (!g_bBhop[client])
		g_LeetJumpDominating[client] = 0;
}

public Action:CheckRemainingTime(Handle:timer)
{
	new Handle:hTmp;	
	hTmp = FindConVar("mp_timelimit");
	new iTimeLimit = GetConVarInt(hTmp);			
	if (hTmp != INVALID_HANDLE)
		CloseHandle(hTmp);	
	if (g_bMapEnd && iTimeLimit > 0)
	{
		new timeleft;
		GetMapTimeLeft(timeleft);		
		switch(timeleft)
		{
			case 1800: PrintToChatAll("[%cMAP%c] 30 minutes remaining",LIGHTRED,WHITE);
			case 1200: PrintToChatAll("[%cMAP%c] 20 minutes remaining",LIGHTRED,WHITE);
			case 600: PrintToChatAll("[%cMAP%c] 10 minutes remaining",LIGHTRED,WHITE);
			case 300: PrintToChatAll("[%cMAP%c] 5 minutes remaining",LIGHTRED,WHITE);
			case 120: PrintToChatAll("[%cMAP%c] 2 minutes remaining",LIGHTRED,WHITE);
			case 60: PrintToChatAll("[%cMAP%c] 60 seconds remaining",LIGHTRED,WHITE); 
			case 30: PrintToChatAll("[%cMAP%c] 30 seconds remaining",LIGHTRED,WHITE);
			case 15: PrintToChatAll("[%cMAP%c] 15 seconds remaining",LIGHTRED,WHITE);			
			case -1: PrintToChatAll("[%cMAP%c] 3..",LIGHTRED,WHITE);
			case -2: PrintToChatAll("[%cMAP%c] 2..",LIGHTRED,WHITE);
			case -3:
			{
				if (!g_bRoundEnd)
				{
					g_bRoundEnd=true;			
					ServerCommand("mp_ignore_round_win_conditions 0");
					PrintToChatAll("[%cMAP%c] 1..",LIGHTRED,WHITE);
					CreateTimer(1.0, TerminateRoundTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
} 

public Action:MainTimer2(Handle:timer)
{
	if (g_bRoundEnd)
		return Plugin_Continue;

	new agent=0;
	for (new i = 1; i <= MaxClients; i++)
	{	
		if (!IsValidEntity(i) || !IsClientInGame(i))
			continue;
		//nextmap & localtime bots
		if (g_iBot != i && g_iBot2 != i && IsFakeClient(i))
		{
			if (agent==0)
			{		
				decl String:szBuffer[64];
				decl String:sNextMap[128];
				if(g_bMapChooser && EndOfMapVoteEnabled() && !HasEndOfMapVoteFinished())
					Format(sNextMap, sizeof(sNextMap), "Pending Vote");
				else
				{
					GetNextMap(sNextMap, sizeof(sNextMap));
					new String:mapPieces[6][128];
					new lastPiece = ExplodeString(sNextMap, "/", mapPieces, sizeof(mapPieces), sizeof(mapPieces[])); 
					Format(sNextMap, sizeof(sNextMap), "%s", mapPieces[lastPiece-1]); 			
				}	
				
				new timeleft;
				GetMapTimeLeft(timeleft);
				new Float:ftime = float(timeleft);
				FormatTimeFloat(i,ftime,4);
				
				
				new Handle:hTmp;	
				hTmp = FindConVar("mp_timelimit");
				new iTimeLimit = GetConVarInt(hTmp);			
				if (hTmp != INVALID_HANDLE)
					CloseHandle(hTmp);	
				if (g_bMapEnd && iTimeLimit > 0)
					Format(szBuffer, sizeof(szBuffer), "Nextmap: %s (in %s)",sNextMap, g_szTime[i]);
				else
					Format(szBuffer, sizeof(szBuffer), "Nextmap: Pending Vote (no time limit)");
				CS_SetClientName(i, szBuffer);	
			}
			if (agent==1)
			{
				decl String:szTime[64];
				decl String:szTime24[64];
				decl String:szHours[64];
				FormatTime(szTime, sizeof(szTime), "%I:%M:%S", GetTime());
				
				//am/pm check
				FormatTime(szTime24, sizeof(szTime24), "%H:%M:%S", GetTime());
				SplitString(szTime24,":",szHours,64);
				new hours;
				hours = StringToInt(szHours);

				if (hours > 12)
					Format(szTime, sizeof(szTime), "%s pm", szTime);
				else
					Format(szTime, sizeof(szTime), "%s am", szTime);
				decl String:szBuffer2[64];
				Format(szBuffer2, sizeof(szBuffer2), "Local Time: %s", szTime);		
				CS_SetClientName(i, szBuffer2);	
			}
			agent++;
		}
		
		//Scoreboard			
		if (!g_bPause[i]) 
		{
			new Float:fltime = GetEngineTime() - g_fStartTime[i] - g_fPauseTime[i] + 1.0;
			if (IsPlayerAlive(i) && g_bTimeractivated[i])
			{
				new time = RoundToZero(fltime);
				Client_SetScore(i,time); 
				Client_SetAssists(i,g_OverallCp[i]);		
				Client_SetDeaths(i,g_OverallTp[i]);								
			}
			else
			{		
				Client_SetScore(i,0);
				Client_SetDeaths(i,0);
				Client_SetAssists(i,0);
			}
			if (!IsFakeClient(i) && !g_pr_Calculating[i])
				CreateTimer(0.0, SetClanTag, i,TIMER_FLAG_NO_MAPCHANGE);		
		}
		
		//Last Cords & Angles
		if (IsPlayerAlive(i) && (GetEntityFlags(i) & FL_ONGROUND)) 
		{
			GetClientAbsOrigin(i,g_fPlayerCordsLastPosition[i]);
			GetClientEyeAngles(i,g_fPlayerAnglesLastPosition[i]);
			g_fPlayerLastTime[i] = g_fRunTime[i];
		}
	}
	
	//clean weapons on ground
	new maxEntities = GetMaxEntities();
	decl String:classx[20];
	if (g_bCleanWeapons)
	{
		for (new j = MaxClients + 1; j < maxEntities; j++)
		{
			if (IsValidEdict(j) && (GetEntDataEnt2(j, ownerOffset) == -1))
			{
				GetEdictClassname(j, classx, sizeof(classx));
				if ((StrContains(classx, "weapon_") != -1) || (StrContains(classx, "item_") != -1))
				{
					AcceptEntityInput(j, "Kill");
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:SpawnButtons(Handle:timer)
{
	db_selectMapButtons();
}

public Action:OnDeathTimer(Handle:Timer, any:client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		new team = GetClientTeam(client);
		if ( team != 1)
		{	
			if (g_bClimbersMenuOpen[client])
				g_bClimbersMenuOpen2[client] = true;
			
			//kill timer
			if (g_bTimeractivated[client] && (GetClientTeam(client) > 1)  && !g_bSpectate[client])
			{
				g_bTimeractivated[client] = false;
				g_fStartTime[client] = -1.0;
				g_fRunTime[client] = -1.0;
			}		
		}
	}
}

public Action:KickPlayer(Handle:Timer, any:client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		decl String:szReason[64];
		Format(szReason, 64, "Please set your fps_max between 100 and 300");
		KickClient(client, "%s", szReason);
	}
}


//challenge start countdown
public Action:Timer_Countdown(Handle:timer, any:client)
{
	if (IsClientConnected(client) && g_bChallenge[client] && !IsFakeClient(client))
	{
		PrintToChat(client,"[%cKZ%c] %c%i",RED,WHITE,YELLOW,g_CountdownTime[client]);
		g_CountdownTime[client]--;
		if(g_CountdownTime[client] <= 0) 
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
			PrintToChat(client, "%t", "ChallengeStarted1",RED,WHITE,YELLOW);
			PrintToChat(client, "%t", "ChallengeStarted2",RED,WHITE,YELLOW);
			PrintToChat(client, "%t", "ChallengeStarted3",RED,WHITE,YELLOW);
			PrintToChat(client, "%t", "ChallengeStarted4",RED,WHITE,YELLOW);
			KillTimer(timer);
			return Plugin_Handled;
		}
	}
	else
		KillTimer(timer);
	return Plugin_Continue;
}

public Action:TpReplayTimer(Handle:timer, any:client)
{
	if (client && IsClientConnected(client) && !IsFakeClient(client))
		SaveRecording(client,1);
}

public Action:ProReplayTimer(Handle:timer, any:client)
{
	if (client && IsClientConnected(client) && !IsFakeClient(client))
		SaveRecording(client,0);
}

public Action:CheckAgents(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsFakeClient(client) && client != g_iBot && client != g_iBot2)
	{
		Format(g_pr_rankname[client], 16, "BOT");
		SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
		SetEntProp(client, Prop_Send, "m_iPrimaryAddon", 0);
		SetEntProp(client, Prop_Send, "m_iSecondaryAddon", 0); 		
		decl String:szName[32];	
		GetClientName(client, szName, 32);
		decl String:szBuffer[64];
		Format(szBuffer, sizeof(szBuffer), "Free Agent %s", szName);		
		CS_SetClientName(client, szBuffer);				
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 99);  
		TeleportEntity(client, Float:{-9999.0,-9999.0,-9999.0},NULL_VECTOR, Float:{0.0,0.0,-100.0});
		g_bValidAgent[client]=true;
	}
}


public Action:CheckChallenge(Handle:timer, any:client)
{
	new bool:oppenent=false;
	decl String:szSteamId[32];
	decl String:szName[32];
	decl String:szNameTarget[32];
	if (g_bChallenge[client] && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && i != client)
			{	
				GetClientAuthString(i, szSteamId, 32);		
				if (StrEqual(szSteamId,g_szCOpponentID[client]))
				{
					oppenent=true;		
					if (g_bChallengeAbort[i] && g_bChallengeAbort[client])
					{
						GetClientName(i,szNameTarget,32);
						GetClientName(client,szName,32);
						g_bChallenge[client]=false;
						g_bChallenge[i]=false;
						SetEntityRenderColor(client, 255,255,255,255);
						SetEntityRenderColor(i, 255,255,255,255);
						PrintToChat(client, "%t", "ChallengeAborted",RED,WHITE,GREEN,szNameTarget,WHITE);
						PrintToChat(i, "%t", "ChallengeAborted",RED,WHITE,szName,WHITE);
						SetEntityMoveType(client, MOVETYPE_WALK);
						SetEntityMoveType(i, MOVETYPE_WALK);
					}				
				}
			}
		}
		if (!oppenent)
		{				
			SetEntityRenderColor(client, 255,255,255,255);
			g_bChallenge[client]=false;
			
			//db challenge entry
			db_insertPlayerChallenge(client);
			
			//new points
			g_pr_multiplier[client]+=g_CBet[client];
			g_challenge_win_ratio[client]++;
			g_challenge_points_ratio[client]+= (g_pr_points_finished*g_CBet[client]);			
			

			
			//db opponent
			db_selectRankedPlayer(g_szCOpponentID[client], g_CBet[client]);
			
			//chat msgs
			if (IsClientInGame(client))
				PrintToChat(client, "%t", "ChallengeWon",RED,WHITE,YELLOW,WHITE);

			//db client
			g_pr_showmsg[client]=true;
			CalculatePlayerRank(client);
			
			KillTimer(timer);
			return Plugin_Handled;
		}
	}
	else
		KillTimer(timer);
	return Plugin_Continue;
}

public Action:KickBotsTimer(Handle:timer)
{	
	ServerCommand("bot_quota 0"); 
}

public Action:LoadReplaysTimer(Handle:timer)
{
	if (g_bReplayBot)
		LoadReplays();
}

public Action:SetClanTag(Handle:timer, any:client)
{
	if (client > MaxClients || client < 1 || !IsValidEntity(client) || !IsClientInGame(client) || IsFakeClient(client) || g_pr_Calculating[client])
		return;

	if (!g_bCountry && !g_bPointSystem && !g_bAdminClantag && !g_bVipClantag)
	{
		CS_SetClientClanTag(client, ""); 	
		return;
	}
	
	decl String:old_pr_rankname[32];  
	decl String:tag[32];  
	new bool:oldrank;
	
	if (!StrEqual(g_pr_rankname[client], "", false))
	{
		oldrank=true;
		Format(old_pr_rankname, 32, "%s", g_pr_rankname[client]); 
	}		
	SetPlayerRank(client);
		
	if (g_bCountry)
	{
		Format(tag, 32, "%s | %s",g_szCountryCode[client],g_pr_rankname[client]);	
		CS_SetClientClanTag(client, tag); 	
	}
	else
	{
		if (g_bPointSystem || ((StrEqual(g_pr_rankname[client], "ADMIN", false)) && g_bAdminClantag) || ((StrEqual(g_pr_rankname[client], "VIP", false)) && g_bVipClantag))
			CS_SetClientClanTag(client, g_pr_rankname[client]); 	
	}
	
	//new rank
	if (oldrank && g_bPointSystem)
		if (!StrEqual(g_pr_rankname[client], old_pr_rankname, false) && IsClientInGame(client))
		{
			if (g_bColoredChatRanks)
				CPrintToChat(client,"%t","SkillGroup", MOSSGREEN, WHITE, GRAY,GRAY, g_pr_chat_coloredrank[client]);
			else
				PrintToChat(client,"%t","SkillGroup", MOSSGREEN, WHITE, GRAY,RED, g_pr_rankname[client]);
		}
}

public Action:SettingsEnforcerTimer(Handle:timer)
{
	if (g_bEnforcer)		
		ServerCommand("kz_prespeed_cap 380.0;sv_staminalandcost 0;sv_maxspeed 320; sv_staminajumpcost 0; sv_gravity 800; sv_airaccelerate 100; sv_friction 4.8;sv_accelerate 6.5;sv_maxvelocity 2000;sv_cheats 0"); 	
	return Plugin_Continue;
}

public Action:TerminateRoundTimer(Handle:timer)
{
	PrintToChatAll("[%cMAP%c] 0..",LIGHTRED,WHITE);
	CS_TerminateRound(1.0, CSRoundEnd_CTWin, true);
}


public Action:MainTimer(Handle:timer)
{
	if (g_bRoundEnd)
		return Plugin_Continue;
	for (new client = 1; client <= MaxClients; client++)
	{		
		if (IsValidEntity(client) && IsClientInGame(client))
		{			
			if(IsPlayerAlive(client))
				AliveMainTimer(client);
			else
				DeadMainTimer(client);					
		}
	}	
	return Plugin_Continue;		
}

public Action:WelcomeMsgTimer(Handle:timer, any:client)
{
	if (IsClientInGame(client) && !IsFakeClient(client) && !StrEqual(g_sWelcomeMsg,""))
		CPrintToChat(client, "%s", g_sWelcomeMsg);
}

public Action:OverlayTimer(Handle:timer, any:client)
{
	g_bOverlay[client]=false;
}

public Action:HelpMsgTimer(Handle:timer, any:client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
		PrintToChat(client, "%t", "HelpMsg", MOSSGREEN,WHITE,GREEN,WHITE);
}

public Action:SteamGroupTimer(Handle:timer, any:client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
		PrintToChat(client, "%t", "SteamGroup", MOSSGREEN,WHITE);
}

public Action:GetTakeOffSpeedTimer(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		decl Float:fVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
		fVelocity[2] = 0.0;
		g_fTakeOffSpeed[client] = SquareRoot(Pow(fVelocity[0], 2.0) + Pow(fVelocity[1], 2.0) + Pow(fVelocity[2], 2.0));
	}
}

public Action:StartMsgTimer(Handle:timer, any:client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (g_bAntiCheat)
			PrintToChat(client, "%t", "AntiCheatEnabled", MOSSGREEN,WHITE,LIMEGREEN);
		if (g_bEnforcer)
			PrintToChat(client, "%t", "SettingsEnforcerEnabled", MOSSGREEN,WHITE,LIMEGREEN);
		else
			PrintToChat(client, "%t", "SettingsEnforcerDisabled", MOSSGREEN,WHITE,GRAY);	
			
		PrintMapRecords(client);	
	}
}

public Action:CenterMsgTimer(Handle:timer, any:client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (g_bRestoreCMsg[client])
		{
			CreateTimer(3.5, OverlayTimer, client,TIMER_FLAG_NO_MAPCHANGE);
			g_bOverlay[client]=true;
			PrintHintText(client,"%t", "PositionRestored");
		}
		
		if (!g_bAutoTimer && IsPlayerAlive(client) && !g_bRestoreCMsg[client])
		{
			CreateTimer(3.5, OverlayTimer, client,TIMER_FLAG_NO_MAPCHANGE);
			g_bOverlay[client]=true;
			PrintHintText(client,"%t", "TimerStartReminder");
		}
		g_bRestoreCMsg[client]=false;
	}
}

public Action:ClimbersMenuTimer(Handle:timer, any:client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (g_bAllowCheckpoints)
			if(StrEqual(g_szMapTag[0],"kz") || StrEqual(g_szMapTag[0],"xc") || StrEqual(g_szMapTag[0],"bhop") || StrEqual(g_szMapTag[0],"bkz"))
				Client_Kzmenu(client,0);
	}
}

public Action:RemoveRagdoll(Handle:timer, any:victim)
{
    if (IsValidEntity(victim) && !IsPlayerAlive(victim))
    {
        new player_ragdoll = GetEntDataEnt2(victim, g_i_ragdolls);
        if (player_ragdoll != -1)
            RemoveEdict(player_ragdoll);
    }
}

public Action:HideRadar(Handle:timer, any:client)
{
	if (IsValidEntity(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		SetEntPropEnt(client, Prop_Send, "m_bSpotted", 0);
		SetEntProp(client, Prop_Send, "m_iHideHUD", HIDE_RADAR);	
	}
}

public Action:OpenMapTimes(Handle:timer, any:client)
{
	if (IsValidEntity(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		decl String:szSteamId[32];
		GetClientAuthString(client, szSteamId, 32);		
		db_viewRecord(client, szSteamId, g_szMapName);
	}
}