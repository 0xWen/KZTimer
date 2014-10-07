// Credits: LJStats by justshoot, Zipcore
public Function_BlockJump(client)
{
	decl Float:pos[3], Float:origin[3];
	GetAimOrigin(client, pos);
	TraceClientGroundOrigin(client, origin, 100.0);
	new bool:funclinear;
	//get aim target
	new String:classname[32];
	new target = TraceClientViewEntity(client);
	if (IsValidEdict(target))
		GetEntityClassname(target, classname, 32);	
	if (StrEqual(classname,"func_movelinear"))
		funclinear=true;
	
	if((FloatAbs(pos[2] - origin[2]) <= 0.002) || (funclinear && FloatAbs(pos[2] - origin[2]) <= 0.6))
	{
		GetBoxFromPoint(origin, g_fOriginBlock[client]);
		GetBoxFromPoint(pos, g_fDestBlock[client]);
		CalculateBlockGap(client, origin, pos);
		g_fBlockHeight[client] = pos[2];
	}
	else
	{
		g_bLJBlock[client] = false;
		PrintToChat(client, "%t", "LJblock1",MOSSGREEN,WHITE,RED);	
	}
}

// Credits: LJStats by justshoot, Zipcore
stock TE_SendBlockPoint(client, const Float:pos1[3], const Float:pos2[3], model)
{
	new Float:buffer[4][3];
	buffer[2] = pos1;
	buffer[3] = pos2;
	buffer[0] = buffer[2];
	buffer[0][1] = buffer[3][1];
	buffer[1] = buffer[3];
	buffer[1][1] = buffer[2][1];
	decl randco[4];
	randco[0] = GetRandomInt(0, 255);
	randco[1] = GetRandomInt(0, 255);
	randco[2] = GetRandomInt(0, 255);
	randco[3] = GetRandomInt(125, 255);
	TE_SetupBeamPoints(buffer[3], buffer[0], model, 0, 0, 0, 0.13, 2.0, 2.0, 10, 0.0, randco, 0);
	TE_SendToClient(client);
	TE_SetupBeamPoints(buffer[0], buffer[2], model, 0, 0, 0, 0.13, 2.0, 2.0, 10, 0.0, randco, 0);
	TE_SendToClient(client);
	TE_SetupBeamPoints(buffer[2], buffer[1], model, 0, 0, 0, 0.13, 2.0, 2.0, 10, 0.0, randco, 0);
	TE_SendToClient(client);
	TE_SetupBeamPoints(buffer[1], buffer[3], model, 0, 0, 0, 0.13, 2.0, 2.0, 10, 0.0, randco, 0);
	TE_SendToClient(client);
}

// Credits: LJStats by justshoot, Zipcore
GetEdgeOrigin(client, Float:ground[3], Float:result[3])
{
	result[0] = FloatDiv(g_fEdgeVector[client][0]*ground[0] + g_fEdgeVector[client][1]*g_fEdgePoint[client][0], g_fEdgeVector[client][0]+g_fEdgeVector[client][1]);
	result[1] = FloatDiv(g_fEdgeVector[client][1]*ground[1] - g_fEdgeVector[client][0]*g_fEdgePoint[client][1], g_fEdgeVector[client][1]-g_fEdgeVector[client][0]);
	result[2] = ground[2];
}

// Credits: LJStats by justshoot, Zipcore
stock TraceWallOrigin(Float:fOrigin[3], Float:vAngles[3], Float:result[3])
{
	new Handle:trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace)) 
	{
		TR_GetEndPosition(result, trace);
		CloseHandle(trace);
		return 1;
	}
	CloseHandle(trace);
	return 0;
}

// Credits: LJStats by justshoot, Zipcore
stock TraceGroundOrigin(Float:fOrigin[3], Float:result[3])
{
	new Float:vAngles[3] = {90.0, 0.0, 0.0};
	new Handle:trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if(TR_DidHit(trace)) 
	{
		TR_GetEndPosition(result, trace);
		CloseHandle(trace);
		return 1;
	}
	CloseHandle(trace);
	return 0;
}

// Credits: LJStats by justshoot, Zipcore
stock GetBeamEndOrigin(Float:fOrigin[3], Float:vAngles[3], Float:distance, Float:result[3])
{
	decl Float:AngleVector[3];
	GetAngleVectors(vAngles, AngleVector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(AngleVector, AngleVector);
	ScaleVector(AngleVector, distance);	
	AddVectors(fOrigin, AngleVector, result);
}

// Credits: LJStats by justshoot, Zipcore
stock GetBeamHitOrigin(Float:fOrigin[3], Float:vAngles[3], Float:result[3])
{
    new Handle:trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
    if(TR_DidHit(trace)) 
    {
        TR_GetEndPosition(result, trace);
        CloseHandle(trace);
    }
}

// Credits: LJStats by justshoot, Zipcore
stock GetAimOrigin(client, Float:hOrigin[3]) 
{
    new Float:vAngles[3], Float:fOrigin[3];
    GetClientEyePosition(client,fOrigin);
    GetClientEyeAngles(client, vAngles);

    new Handle:trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

    if(TR_DidHit(trace)) 
    {
        TR_GetEndPosition(hOrigin, trace);
        CloseHandle(trace);
        return 1;
    }

    CloseHandle(trace);
    return 0;
}

// Credits: LJStats by justshoot, Zipcore
stock GetBoxFromPoint(Float:origin[3], Float:result[2][3])
{
	decl Float:temp[3];
	temp = origin;
	temp[2] += 1.0;
	new Float:ang[4][3];
	ang[1][1] = 90.0;
	ang[2][1] = 180.0;
	ang[3][1] = -90.0;
	new bool:edgefound[4];
	new Float:dist[4];
	decl Float:tempdist[4], Float:position[3], Float:ground[3], Float:Last[4], Float:Edge[4][3];
	for(new i = 0; i < 4; i++)
	{
		TraceWallOrigin(temp, ang[i], Edge[i]);
		tempdist[i] = GetVectorDistance(temp, Edge[i]);
		Last[i] = origin[2];
		while(dist[i] < tempdist[i])
		{
			if(edgefound[i])
				break;
			GetBeamEndOrigin(temp, ang[i], dist[i], position);
			TraceGroundOrigin(position, ground);
			if((Last[i] != ground[2])&&(Last[i] > ground[2]))
			{
				Edge[i] = ground;
				edgefound[i] = true;
			}
			Last[i] = ground[2];
			dist[i] += 10.0;
		}
		if(!edgefound[i])
		{
			TraceGroundOrigin(Edge[i], Edge[i]);
			edgefound[i] = true;
		}
		else
		{
			ground = Edge[i];
			ground[2] = origin[2];
			MakeVectorFromPoints(ground, origin, position);
			GetVectorAngles(position, ang[i]);
			ground[2] -= 1.0;
			GetBeamHitOrigin(ground, ang[i], Edge[i]);
		}
		Edge[i][2] = origin[2];
	}
	if(edgefound[0]&&edgefound[1]&&edgefound[2]&&edgefound[3])
	{
		result[0][2] = origin[2];
		result[1][2] = origin[2];
		result[0][0] = Edge[0][0];
		result[0][1] = Edge[1][1];
		result[1][0] = Edge[2][0];
		result[1][1] = Edge[3][1];
	}
}

// Credits: LJStats by justshoot, Zipcore
CalculateBlockGap(client, Float:origin[3], Float:target[3])
{
	new Float:distance = GetVectorDistance(origin, target);
	new Float:rad = DegToRad(15.0);
	new Float:newdistance = FloatDiv(distance, Cosine(rad));
	decl Float:eye[3], Float:eyeangle[2][3];
	new Float:temp = 0.0;
	GetClientEyePosition(client, eye);
	GetClientEyeAngles(client, eyeangle[0]);
	eyeangle[0][0] = 0.0;
	eyeangle[1] = eyeangle[0];
	eyeangle[0][1] += 10.0;
	eyeangle[1][1] -= 10.0;
	decl Float:position[3], Float:ground[3], Float:Last[2], Float:Edge[2][3];
	new bool:edgefound[2];
	while(temp < newdistance)
	{
		temp += 10.0;
		for(new i = 0; i < 2 ; i++)
		{
			if(edgefound[i])
				continue;
			GetBeamEndOrigin(eye, eyeangle[i], temp, position);
			TraceGroundOrigin(position, ground);
			if(temp == 10.0)
			{
				Last[i] = ground[2];
			}
			else
			{
				if((Last[i] != ground[2])&&(Last[i] > ground[2]))
				{
					Edge[i] = ground;
					edgefound[i] = true;
				}
				Last[i] = ground[2];
			}
		}
	}
	decl Float:temp2[2][3];
	if(edgefound[0] && edgefound[1])
	{
		for(new i = 0; i < 2 ; i++)
		{
			temp2[i] = Edge[i];
			temp2[i][2] = origin[2] - 1.0;
			if(eyeangle[i][1] > 0)
			{
				eyeangle[i][1] -= 180.0;
			}
			else
			{
				eyeangle[i][1] += 180.0;
			}
			GetBeamHitOrigin(temp2[i], eyeangle[i], Edge[i]);
		}
	}
	else
	{
		g_bLJBlock[client] = false;
		PrintToChat(client, "%t", "LJblock2",MOSSGREEN,WHITE,RED);	
		return;
	}



	g_fEdgePoint[client] = Edge[0];	
	MakeVectorFromPoints(Edge[0], Edge[1], position);
	g_fEdgeVector[client] = position;
	NormalizeVector(g_fEdgeVector[client], g_fEdgeVector[client]);
	CorrectEdgePoint(client);
	GetVectorAngles(position, position);
	position[1] += 90.0;
	GetBeamHitOrigin(Edge[0], position, Edge[1]);
	distance = GetVectorDistance(Edge[0], Edge[1]);
	g_BlockDist[client] = RoundToNearest(distance);


	new Float:surface = GetVectorDistance(g_fDestBlock[client][0],g_fDestBlock[client][1]);
	surface *= surface;
	if (surface > 1000000)
	{
		PrintToChat(client, "%t", "LJblock3",MOSSGREEN,WHITE,RED);	
		return;
	}	
	
	
	if(!IsCoordInBlockPoint(Edge[1],g_fDestBlock[client],true))	
	{	
		g_bLJBlock[client] = false;
		PrintToChat(client, "%t", "LJblock4",MOSSGREEN,WHITE,RED);	
		return;		
	}
	TE_SetupBeamPoints(Edge[0], Edge[1], g_Beam[0], 0, 0, 0, 1.0, 1.0, 1.0, 10, 0.0, {0,255,255,155}, 0);
	TE_SendToClient(client);	
	
	if(g_BlockDist[client] > 225 && g_BlockDist[client] <= 300)
	{
		PrintToChat(client, "%t", "LJblock5", MOSSGREEN,WHITE, LIMEGREEN,GREEN, g_BlockDist[client],LIMEGREEN);
		g_bLJBlock[client] = true;
	}
	else
	{
		if (g_BlockDist[client] < 225)
			PrintToChat(client, "%t", "LJblock6", MOSSGREEN,WHITE, RED,DARKRED,g_BlockDist[client],RED);
		else
			if (g_BlockDist[client] > 300)
				PrintToChat(client, "%t", "LJblock7", MOSSGREEN,WHITE, RED,DARKRED,g_BlockDist[client],RED);
	}
}

// Credits: LJStats by justshoot, Zipcore
stock bool:IsCoordInBlockPoint(const Float:origin[3], const Float:pos[2][3], bool:ignorez)
{
	new bool:bX, bool:bY, bool:bZ;
	decl Float:temp[2][3];
	temp[0] = pos[0];
	temp[1] = pos[1];
	temp[0][0] += 16.0;
	temp[0][1] += 16.0;
	temp[1][0] -= 16.0;
	temp[1][1] -= 16.0;
	if (ignorez)
		bZ=true;	
	
	if(temp[0][0] > temp[1][0])
	{
		if(temp[0][0] >= origin[0] >= temp[1][0])
		{
			bX = true;
		}
	}
	else
	{
		if(temp[1][0] >= origin[0] >= temp[0][0])
		{
			bX = true;
		}
	}
	if(temp[0][1] > temp[1][1])
	{
		if(temp[0][1] >= origin[1] >= temp[1][1])
		{
			bY = true;
		}
	}
	else
	{
		if(temp[1][1] >= origin[1] >= temp[0][1])
		{
			bY = true;
		}
	}
	if(temp[0][2] + 0.002 >= origin[2] >= temp[0][2])
	{
		bZ = true;
	}
	
	if(bX&&bY&&bZ)
	{
		return true;
	}
	else
	{
		return false;
	}
}

// Credits: LJStats by justshoot, Zipcore
CorrectEdgePoint(client)
{
	decl Float:vec[3];
	vec[0] = 0.0 - g_fEdgeVector[client][1];
	vec[1] = g_fEdgeVector[client][0];
	vec[2] = 0.0;
	ScaleVector(vec, 16.0);
	AddVectors(g_fEdgePoint[client], vec, g_fEdgePoint[client]);
}

public Prethink (client, Float:pos[3], Float:vel)
{		
	new weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (!client || !IsPlayerAlive(client) || g_bNoClipUsed[client] || weapon == -1 || GetEntProp(client, Prop_Data, "m_nWaterLevel") > 0)
	{	
		g_bNoClipUsed[client] = false;
		return;
	}
	//booster or moving plattform?
	new Float:flVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", flVelocity);
	if (flVelocity[0] != 0.0 || flVelocity[1] != 0.0 || flVelocity[2] != 0.0)
		g_js_bInvalidGround[client] = true;
	else
		g_js_bInvalidGround[client] = false;		
			
	//reset vars
	g_js_Good_Sync_Frames[client] = 0.0;
	g_js_Sync_Frames[client] = 0.0;
	for( new i = 0; i < MAX_STRAFES; i++ )
	{
		g_js_Strafe_Good_Sync[client][i] = 0.0;
		g_js_Strafe_Frames[client][i] = 0.0;
		g_js_Strafe_Gained[client][i] = 0.0;
		g_js_Strafe_Lost[client][i] = 0.0;
		g_js_Strafe_Max_Speed[client][i] = 0.0;
	}	
	
	g_js_fJumpOff_Time[client] = GetEngineTime();
	g_js_fMax_Speed[client] = 0.0;
	g_js_StrafeCount[client] = 0;
	g_js_bDropJump[client] = false;
	g_js_bPlayerJumped[client] = true;
	g_js_Strafing_AW[client] = false;
	g_js_Strafing_SD[client] = false;
	g_js_bFuncMoveLinear[client] = false;
	g_js_fMax_Height[client] = -99999.0;				
	g_js_fLast_Jump_Time[client] = GetEngineTime();

	decl Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);		
	g_js_fPreStrafe[client] = SquareRoot(Pow(fVelocity[0], 2.0) + Pow(fVelocity[1], 2.0) + Pow(fVelocity[2], 2.0));	
	g_js_fTakeOff_Speed[client] = -1.0;
	CreateTimer(0.015, GetTakeOffSpeedTimer, client,TIMER_FLAG_NO_MAPCHANGE);
	GetGroundOrigin(client, g_js_fJump_JumpOff_Pos[client]);	
	if (g_js_fJump_JumpOff_PosLastHeight[client] != -1.012345)
	{	
		new Float: fGroundDiff = g_js_fJump_JumpOff_Pos[client][2] - g_js_fJump_JumpOff_PosLastHeight[client];
		if (fGroundDiff > -0.1 && fGroundDiff < 0.1)
			fGroundDiff = 0.0;		
		if(fGroundDiff <= -1.5)
		{
			g_js_bDropJump[client] = true;
			g_js_fDropped_Units[client] = FloatAbs(fGroundDiff);
		}		
	}
	
	if (g_js_GroundFrames[client]<11)
		g_js_bBhop[client] = true;
	else
		g_js_bBhop[client] = false;
	
	
	//last InitialLastHeight
	g_js_fJump_JumpOff_PosLastHeight[client] = g_js_fJump_JumpOff_Pos[client][2];
}

public Postthink(client)
{	
	if (!IsValidClient(client))
		return;
	
	new ground_frames = g_js_GroundFrames[client];
	new strafes = g_js_StrafeCount[client];
	g_js_GroundFrames[client] = 0;	
	g_js_fMax_Speed_Final[client] = g_js_fMax_Speed[client];
	decl String:szName[128];	
	GetClientName(client, szName, 128);		
	
	//get landing position & calc distance
	g_js_fJump_DistanceX[client] = g_js_fJump_Landing_Pos[client][0] - g_js_fJump_JumpOff_Pos[client][0];
	if(g_js_fJump_DistanceX[client] < 0)
		g_js_fJump_DistanceX[client] = -g_js_fJump_DistanceX[client];
	g_js_fJump_DistanceZ[client] = g_js_fJump_Landing_Pos[client][1] - g_js_fJump_JumpOff_Pos[client][1];
	if(g_js_fJump_DistanceZ[client] < 0)
		g_js_fJump_DistanceZ[client] = -g_js_fJump_DistanceZ[client];
	g_js_fJump_Distance[client] = SquareRoot(Pow(g_js_fJump_DistanceX[client], 2.0) + Pow(g_js_fJump_DistanceZ[client], 2.0));	
	
	g_js_fJump_Distance[client] = g_js_fJump_Distance[client] + 32;
	
	//ground diff
	new Float: fGroundDiff = g_js_fJump_Landing_Pos[client][2] - g_js_fJump_JumpOff_Pos[client][2];
	new Float: fJump_Height;

	if (fGroundDiff > -0.1 && fGroundDiff < 0.1)
		fGroundDiff = 0.0;
	//workaround
	if (g_js_bFuncMoveLinear[client] && fGroundDiff < 0.6 && fGroundDiff > -0.6)
		fGroundDiff = 0.0;

	//ground diff 2
	new Float: groundpos[3];
	GetClientAbsOrigin(client, groundpos);
	new Float: fGroundDiff2 = groundpos[2] - g_fLastPositionOnGround[client][2];
		
	//GetHeight
	if (FloatAbs(g_js_fJump_JumpOff_Pos[client][2]) > FloatAbs(g_js_fMax_Height[client]))
		fJump_Height =  FloatAbs(g_js_fJump_JumpOff_Pos[client][2]) - FloatAbs(g_js_fMax_Height[client]);
	else
		fJump_Height =  FloatAbs(g_js_fMax_Height[client]) - FloatAbs(g_js_fJump_JumpOff_Pos[client][2]);
	g_flastHeight[client] = fJump_Height;
	
	//sync/strafes
	new sync = RoundToNearest(g_js_Good_Sync_Frames[client] / g_js_Sync_Frames[client] * 100.0);
	g_js_Strafes_Final[client] = strafes;
	g_js_Sync_Final[client] = sync;
	
	//Calc & format strafe sync for chat output
	new String:szStrafeSync[255];
	new String:szStrafeSync2[255];
	new strafe_sync;
	if (g_bStrafeSync[client] && strafes > 1)
	{
		for (new i = 0; i < strafes; i++)
		{
			if (i==0)
				Format(szStrafeSync, 255, "[%cKZ%c] %cSync:",MOSSGREEN,WHITE,GRAY);
			if (g_js_Strafe_Frames[client][i] == 0.0 || g_js_Strafe_Good_Sync[client][i] == 0.0) 
				strafe_sync = 0;
			else
				strafe_sync = RoundToNearest(g_js_Strafe_Good_Sync[client][i] / g_js_Strafe_Frames[client][i] * 100.0);
			if (i==0)	
				Format(szStrafeSync2, 255, " %c%i.%c %i%c",GRAY, (i+1),LIMEGREEN,strafe_sync,PERCENT);
			else
				Format(szStrafeSync2, 255, "%c - %i.%c %i%c",GRAY, (i+1),LIMEGREEN,strafe_sync,PERCENT);
			StrCat(szStrafeSync, sizeof(szStrafeSync), szStrafeSync2);
			if ((i+1) == strafes)
			{
				Format(szStrafeSync2, 255, " %c[%c%i%c%c]",GRAY,PURPLE, sync,PERCENT,GRAY);
				StrCat(szStrafeSync, sizeof(szStrafeSync), szStrafeSync2);
			}
		}	
	}
	else
		Format(szStrafeSync,255, "");
		
	new String:szStrafeStats[1024];
	new String:szGained[16];
	new String:szLost[16];
	
	//Format StrafeStats Console
	if(strafes > 1)
	{
		Format(szStrafeStats,1024, " #. Sync        Gained      Lost        MaxSpeed\n");
		for( new i = 0; i < strafes; i++ )
		{
			new sync2 = RoundToNearest(g_js_Strafe_Good_Sync[client][i] / g_js_Strafe_Frames[client][i] * 100.0);
			if (sync2 < 0)
				sync2 = 0;
			if (g_js_Strafe_Gained[client][i] < 10.0)
				Format(szGained,16, "%.3f ", g_js_Strafe_Gained[client][i]);
			else
				Format(szGained,16, "%.3f", g_js_Strafe_Gained[client][i]);
			if (g_js_Strafe_Lost[client][i] < 10.0)
				Format(szLost,16, "%.3f ", g_js_Strafe_Lost[client][i]);
			else
				Format(szLost,16, "%.3f", g_js_Strafe_Lost[client][i]);				
			Format(szStrafeStats,1024, "%s%2i. %3i%s        %s      %s      %3.3f\n",\
			szStrafeStats,\
			i + 1,\
			sync2,\
			PERCENT,\
			szGained,\
			szLost,\
			g_js_Strafe_Max_Speed[client][i]);
		}
	}
	else
		Format(szStrafeStats,1024, "");

	//t00-b4d
	if(g_js_fJump_Distance[client] < 200.0)
	{
		//multibhop count proforma
		if (g_js_Last_Ground_Frames[client] < 11 && ground_frames < 11 && fGroundDiff == 0.0  && fJump_Height <= 67.0 && !g_js_bDropJump[client])
			g_js_MultiBhop_Count[client]++;
		else
			g_js_MultiBhop_Count[client]=1;
		if (fGroundDiff==0.0)
			Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>%.1f units</font>", g_js_fJump_Distance[client]);
		else
			Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>vertical</font>");
		PostThinkPost(client, ground_frames);
		return;
	}
	
	//change BotName (szName) for jumpstats output
	if (client == g_ProBot)
		Format(szName,sizeof(szName), "%s (Pro Replay)", g_szReplayName);		
	if (client == g_TpBot)
		Format(szName,sizeof(szName), "%s (TP Replay)", g_szReplayNameTp);	
		
	//vertical jump
	if (fGroundDiff2 > 1.82 || fGroundDiff2 < -1.82 || fGroundDiff != 0.0)
	{	
		Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>vertical</font>");
		PostThinkPost(client, ground_frames);
		return;
	}
	//invalid jump
	if (g_fAirTime[client] > 0.83)
	{
		Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>invalid</font>");
		PostThinkPost(client, ground_frames);
		return;		
	}	
	
	new bool: ValidJump=false;
	//Chat Output
	//LongJump
	if (ground_frames > 11 && fGroundDiff == 0.0 && fJump_Height <= 67.0 && g_js_fJump_Distance[client] < 300.0 && g_js_fMax_Speed_Final[client] > 200.0) 
	{	
		//strafe hack block (aimware is pretty smart :/) (1/2)
		if (g_bPreStrafe || g_bProMode)
		{
			if ((g_Server_Tickrate == 64 && strafes < 4 && g_js_fJump_Distance[client] > 265.0) || (g_Server_Tickrate == 102 && strafes < 4 && g_js_fJump_Distance[client] > 270.0) || (g_Server_Tickrate == 128 && strafes < 4 && g_js_fJump_Distance[client] > 275.0)) 
			{
				Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>invalid</font>");
				PostThinkPost(client, ground_frames);
				return;
			}				
		}
		else
		{
			if ((g_Server_Tickrate == 64 && strafes < 4 && g_js_fJump_Distance[client] > 250.0) || (g_Server_Tickrate == 102 && strafes < 4 && g_js_fJump_Distance[client] > 255.0) || (g_Server_Tickrate == 128 && strafes < 4 && g_js_fJump_Distance[client] > 260.0)) 
			{
				Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>invalid</font>");
				PostThinkPost(client, ground_frames);
				return;
			}
		}
		if (strafes > 20)
		{
			Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>invalid</font>");
			PostThinkPost(client, ground_frames);
			return;
		}			
		///
		//block invalid bot distances (has something to do with the ground-detection of the replay bot) WORKAROUND
		if (IsFakeClient(client) && g_js_fJump_Distance[client] > (g_dist_leet_lj * 1.02))
		{
			Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>invalid</font>");
			PostThinkPost(client, ground_frames);
			return;
		}
		
		//prestrafe on/off
		decl String:szVr[16];
		new bool: prestrafe;
		if (!g_bPreStrafe && !g_bProMode)	
		{
			g_js_fPreStrafe[client] = g_js_fTakeOff_Speed[client];
			Format(szVr, 16, "TakeOff");
			prestrafe = false;
		}
		else
		{
			prestrafe = true;
			Format(szVr, 16, "Pre");		
		}
		//strafe hack block (aimware is pretty smart :/) (2/2)
		if (g_js_fPreStrafe[client] > 278.0 || g_js_fPreStrafe[client] < 200.0)
		{
			if (g_js_fPreStrafe[client] < 200.0)
				Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>%.1f units</font>", g_js_fJump_Distance[client]);
			PostThinkPost(client, ground_frames);
			return;
		}			
		//
		new bool:ljblock=false;	
		decl String:sBlockDist[32];	
		Format(sBlockDist, 32, "");	
		decl String:sBlockDistCon[32];	
		Format(sBlockDistCon, 32, "");	
		if(g_bLJBlock[client] && g_BlockDist[client] > 225 && g_js_fJump_Distance[client] >= float(g_BlockDist[client]))
		{
			if (g_bLJBlockValidJumpoff[client])
			{
				if (g_bLjStarDest[client])
				{
					if (IsCoordInBlockPoint(g_js_fJump_Landing_Pos[client],g_fOriginBlock[client],true))
					{
						Format(sBlockDist, 32, "%t", "LjBlock", GRAY,YELLOW,g_BlockDist[client],GRAY);	
						Format(sBlockDistCon, 32, " [%i block]", g_BlockDist[client]);	
						ljblock=true;
					}
				}
				else
				{
					if (IsCoordInBlockPoint(g_js_fJump_Landing_Pos[client],g_fDestBlock[client],true))
					{
						Format(sBlockDist, 32, "%t", "LjBlock", GRAY,YELLOW,g_BlockDist[client],GRAY);	
						Format(sBlockDistCon, 32, " [%i block]", g_BlockDist[client]);	
						ljblock=true;			
					}
				}
			}
		}
		
		Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>%.1f units</font>", g_js_fJump_Distance[client]);
		//good?
		if (g_js_fJump_Distance[client] >= g_dist_good_lj && g_js_fJump_Distance[client] < g_dist_pro_lj)	
		{		
			ValidJump=true;
			Format(g_js_szLastJumpDistance[client], 256, "<font color='#676060'><b>%.1f units</b></font>", g_js_fJump_Distance[client]);
			CreateTimer(0.1, BhopCheck, client,TIMER_FLAG_NO_MAPCHANGE);
			if (prestrafe)
				PrintToChat(client, "%t", "ClientLongJump1", MOSSGREEN,WHITE,GRAY, g_js_fJump_Distance[client],LIMEGREEN,strafes,GRAY, LIMEGREEN, g_js_fPreStrafe[client], GRAY,LIMEGREEN,g_js_fMax_Speed_Final[client],GRAY,LIMEGREEN, fJump_Height,GRAY,LIMEGREEN, sync,PERCENT,GRAY,sBlockDist);			
			else
				PrintToChat(client, "%t", "ClientLongJump2",MOSSGREEN,WHITE,GRAY, g_js_fJump_Distance[client],LIMEGREEN,strafes,GRAY, LIMEGREEN, g_js_fPreStrafe[client], GRAY,LIMEGREEN,g_js_fMax_Speed_Final[client],GRAY,LIMEGREEN, fJump_Height,GRAY,LIMEGREEN, sync,PERCENT,GRAY,sBlockDist);			
				
			PrintToConsole(client, "        ");
			PrintToConsole(client, "[KZ] %s jumped %0.4f units with a LongJump [%i Strafes | %.3f %s | %.0f Max | Height %.1f | %i%c Sync]%s",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], szVr,g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT,sBlockDistCon);
			PrintToConsole(client, "%s", szStrafeStats);
			}
		else
			//pro?
			if (g_js_fJump_Distance[client] >= g_dist_pro_lj && g_js_fJump_Distance[client] < g_dist_leet_lj)	
			{
				ValidJump=true;
				Format(g_js_szLastJumpDistance[client], 256, "<font color='#21982a'><b>%.2f units</b></font>", g_js_fJump_Distance[client]);
				CreateTimer(0.1, BhopCheck, client,TIMER_FLAG_NO_MAPCHANGE);
				//chat & sound client		
				PrintToConsole(client, "        ");
				PrintToConsole(client, "[KZ] %s jumped %0.4f units with a LongJump [%i Strafes | %.3f %s | %.0f Max | Height %.1f | %i%c Sync]%s",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client],szVr, g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT,sBlockDistCon);
				PrintToConsole(client, "%s", szStrafeStats);	
				if (prestrafe)
					PrintToChat(client, "%t", "ClientLongJump3",MOSSGREEN,WHITE,GREEN,GRAY,GREEN,g_js_fJump_Distance[client],GRAY,LIMEGREEN,strafes,GRAY,LIMEGREEN,g_js_fPreStrafe[client],GRAY,LIMEGREEN,g_js_fMax_Speed_Final[client],GRAY,LIMEGREEN, fJump_Height,GRAY,LIMEGREEN, sync,PERCENT,GRAY,sBlockDist);
				else
					PrintToChat(client, "%t", "ClientLongJump4",MOSSGREEN,WHITE,GREEN,GRAY,GREEN,g_js_fJump_Distance[client],GRAY,LIMEGREEN,strafes,GRAY,LIMEGREEN,g_js_fPreStrafe[client],GRAY,LIMEGREEN,g_js_fMax_Speed_Final[client],GRAY,LIMEGREEN, fJump_Height,GRAY,LIMEGREEN, sync,PERCENT,GRAY,sBlockDist);
					
				decl String:buffer[255];
				Format(buffer, sizeof(buffer), "play %s", PROJUMP_RELATIVE_SOUND_PATH); 			
				if (g_bEnableQuakeSounds[client])
					ClientCommand(client, buffer); 						
				PlayQuakeSound_Spec(client,buffer);		
				//chat all
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i))
					{						
						if (g_bColorChat[i] && i != client)
							PrintToChat(i, "%t", "Jumpstats_LjAll",MOSSGREEN,WHITE,GREEN,szName, MOSSGREEN,GREEN, g_js_fJump_Distance[client],MOSSGREEN,GREEN,sBlockDist);
					}
				}	
				
			}	
			//leet?
			else		
			{			
				if (g_js_fJump_Distance[client] >= g_dist_leet_lj && g_js_fMax_Speed_Final[client] > 275.0)	
				{
					// strafe hack protection					
					if (strafes == 0)
					{
						Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>invalid</font>");
						PostThinkPost(client, ground_frames);
						return;
					}
					ValidJump=true;
					Format(g_js_szLastJumpDistance[client], 256, "<font color='#9a0909'><b>%.2f units</b></font>", g_js_fJump_Distance[client]);
					g_js_LeetJump_Count[client]++;
					//client		
					PrintToConsole(client, "        ");
					PrintToConsole(client, "[KZ] %s jumped %0.4f units with a LongJump [%i Strafes | %.3f %s | %.3f Max | Height %.1f | %i%c Sync]%s",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client],szVr, g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT,sBlockDistCon);
					PrintToConsole(client, "%s", szStrafeStats);		
					if (prestrafe)					
						PrintToChat(client, "%t", "ClientLongJump3",MOSSGREEN,WHITE,DARKRED,GRAY,DARKRED,g_js_fJump_Distance[client],GRAY,LIMEGREEN,strafes,GRAY,LIMEGREEN,g_js_fPreStrafe[client],GRAY,LIMEGREEN, g_js_fMax_Speed_Final[client],GRAY,LIMEGREEN, fJump_Height,GRAY,LIMEGREEN, sync,PERCENT,GRAY,sBlockDist);
					else
						PrintToChat(client, "%t", "ClientLongJump4",MOSSGREEN,WHITE,DARKRED,GRAY,DARKRED,g_js_fJump_Distance[client],GRAY,LIMEGREEN,strafes,GRAY,LIMEGREEN,g_js_fPreStrafe[client],GRAY,LIMEGREEN, g_js_fMax_Speed_Final[client],GRAY,LIMEGREEN, fJump_Height,GRAY,LIMEGREEN, sync,PERCENT,GRAY,sBlockDist);			
					if (g_js_LeetJump_Count[client]==3)
						PrintToChat(client, "%t", "Jumpstats_OnRampage",MOSSGREEN,WHITE,YELLOW,szName);
					else
						if (g_js_LeetJump_Count[client]==5)
							PrintToChat(client, "%t", "Jumpstats_IsDominating",MOSSGREEN,WHITE,YELLOW,szName);
					
					//all
					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsValidClient(i))
						{						
							if (g_bColorChat[i] && i != client)
							{
								PrintToChat(i, "%t", "Jumpstats_LjAll",MOSSGREEN,WHITE,DARKRED,szName, RED,DARKRED, g_js_fJump_Distance[client],RED,DARKRED,sBlockDist);
								if (g_js_LeetJump_Count[client]==3)
									PrintToChat(i, "%t", "Jumpstats_OnRampage",MOSSGREEN,WHITE,YELLOW,szName);
								else
									if (g_js_LeetJump_Count[client]==5)
										PrintToChat(i, "%t", "Jumpstats_IsDominating",MOSSGREEN,WHITE,YELLOW,szName);
							}
						}
					}
					PlayLeetJumpSound(client);
					if (g_js_LeetJump_Count[client] != 3 && g_js_LeetJump_Count[client] != 5)
					{
						decl String:buffer[255];
						Format(buffer, sizeof(buffer), "play %s", LEETJUMP_RELATIVE_SOUND_PATH); 	
						PlayQuakeSound_Spec(client,buffer);
					}
				}
				else
					CreateTimer(0.1, BhopCheck, client,TIMER_FLAG_NO_MAPCHANGE);
					
			}
	
		//strafe sync chat
		if (g_bStrafeSync[client] && g_js_fJump_Distance[client] >= g_dist_good_lj)
			PrintToChat(client,"%s", szStrafeSync);		
				
		//new best
		if (((g_js_fPersonal_Lj_Record[client] < g_js_fJump_Distance[client]) || (ljblock && g_js_Personal_LjBlock_Record[client] < g_BlockDist[client]) || (ljblock && g_js_Personal_LjBlock_Record[client] == g_BlockDist[client] && g_js_fPersonal_LjBlockRecord_Dist[client] < g_js_fJump_Distance[client])) && !IsFakeClient(client))
		{		
			if (ValidJump)
			{
				if (g_js_fPersonal_Lj_Record[client] > 0.0 && g_js_fPersonal_Lj_Record[client] < g_js_fJump_Distance[client])
					PrintToChat(client, "%t", "Jumpstats_BeatLjBest",MOSSGREEN,WHITE,YELLOW, g_js_fJump_Distance[client]);
				if (ljblock && g_js_Personal_LjBlock_Record[client] > 0 && ((g_js_Personal_LjBlock_Record[client] < g_BlockDist[client]) || (g_js_Personal_LjBlock_Record[client] == g_BlockDist[client] && g_js_fPersonal_LjBlockRecord_Dist[client] < g_js_fJump_Distance[client])))
					PrintToChat(client, "%t", "Jumpstats_BeatLjBlockBest",MOSSGREEN,WHITE,YELLOW, g_BlockDist[client],g_js_fJump_Distance[client]);
				if (g_js_fPersonal_Lj_Record[client] < g_js_fJump_Distance[client])
				{	
					g_js_fPersonal_Lj_Record[client] = g_js_fJump_Distance[client];
					db_updateLjRecord(client);
				}
				if (g_js_Personal_LjBlock_Record[client] < g_BlockDist[client] && ljblock || (ljblock && g_js_Personal_LjBlock_Record[client] == g_BlockDist[client] && g_js_fPersonal_LjBlockRecord_Dist[client] < g_js_fJump_Distance[client]))
				{
					g_js_Personal_LjBlock_Record[client] = g_BlockDist[client];
					g_js_fPersonal_LjBlockRecord_Dist[client] = g_js_fJump_Distance[client];
					db_updateLjBlockRecord(client);
				}
			}			
		}
	}
	//Multi Bhop
	if (g_js_Last_Ground_Frames[client] < 11 && ground_frames < 11 && fGroundDiff == 0.0  && fJump_Height <= 67.0 && !g_js_bDropJump[client])
	{		
	
		g_js_MultiBhop_Count[client]++;	
		//strafe hack block (aimware is pretty smart :/)
		if (((g_js_MultiBhop_Count[client] == 1 && g_js_fPreStrafe[client] > 350.0) || strafes > 20) || (g_fBhopSpeedCap == 380.0 && g_js_fJump_Distance[client] > 380.0))
		{
			PostThinkPost(client, ground_frames);
			return;		
		}

		//block invalid bot distances (has something to do with the ground-detection of the replay bot) WORKAROUND
		if (IsFakeClient(client) && g_js_fJump_Distance[client] > (g_dist_leet_multibhop * 1.025))
		{
			PostThinkPost(client, ground_frames);
			return;
		}
			
		
		//format bhop count
		decl String:szBhopCount[255];
		Format(szBhopCount, sizeof(szBhopCount), "%i", g_js_MultiBhop_Count[client]);
		if (g_js_MultiBhop_Count[client] > 8)
			Format(szBhopCount, sizeof(szBhopCount), "> 8");
		
		Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>%.1f units</font>", g_js_fJump_Distance[client]);
		//good?	
		if (g_js_fJump_Distance[client] >= g_dist_good_multibhop && g_js_fJump_Distance[client] < g_dist_pro_multibhop)	
		{
			ValidJump=true;
			Format(g_js_szLastJumpDistance[client], 256, "<font color='#676060'><b>%.1f units</b></font>", g_js_fJump_Distance[client]);
			g_js_LeetJump_Count[client]=0;
			PrintToChat(client, "%t", "ClientMultiBhop1",MOSSGREEN,WHITE, GRAY, g_js_fJump_Distance[client],LIMEGREEN, strafes, GRAY, LIMEGREEN, g_js_fPreStrafe[client], GRAY, LIMEGREEN, sync,PERCENT,GRAY);	
			PrintToConsole(client, "        ");
			PrintToConsole(client, "[KZ] %s jumped %0.4f units with a MultiBhop [%i Strafes | %3.f Pre | %3.f Max | Height %.1f | %s Bhops | %i%c Sync]",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], fJump_Height,szBhopCount,sync,PERCENT);				
			PrintToConsole(client, "%s", szStrafeStats);
		}	
		else
			//pro?
			if (g_js_fJump_Distance[client] >= g_dist_pro_multibhop && g_js_fJump_Distance[client] < g_dist_leet_multibhop)
			{	
				ValidJump=true;
				Format(g_js_szLastJumpDistance[client], 256, "<font color='#21982a'><b>%.2f units</b></font>", g_js_fJump_Distance[client]);
				g_js_LeetJump_Count[client]=0;
				//Client
				PrintToConsole(client, "        ");
				PrintToConsole(client, "[KZ] %s jumped %0.4f units with a MultiBhop [%i Strafes | %.3f Pre | %.3f Max |  Height %.1f | %s Bhops | %i%c Sync]",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], fJump_Height,szBhopCount,sync,PERCENT);				
				PrintToConsole(client, "%s", szStrafeStats);					
				PrintToChat(client, "%t", "ClientMultiBhop2",MOSSGREEN,WHITE,GREEN,GRAY,GREEN,g_js_fJump_Distance[client],GRAY,LIMEGREEN,strafes,GRAY,LIMEGREEN,g_js_fPreStrafe[client],GRAY,LIMEGREEN,g_js_fMax_Speed_Final[client],GRAY,LIMEGREEN, fJump_Height,GRAY, LIMEGREEN,szBhopCount,GRAY,LIMEGREEN, sync,PERCENT,GRAY);
				
				decl String:buffer[255];
				Format(buffer, sizeof(buffer), "play %s", PROJUMP_RELATIVE_SOUND_PATH); 
				if (g_bEnableQuakeSounds[client])
					ClientCommand(client, buffer); 
				PlayQuakeSound_Spec(client,buffer);				
				//all
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i))
					{
						if (g_bColorChat[i] && i != client)					
							PrintToChat(i, "%t", "Jumpstats_MultiBhopAll",MOSSGREEN,WHITE,GREEN,szName, MOSSGREEN,GREEN, g_js_fJump_Distance[client],MOSSGREEN,GREEN);
					}
				}
			}
			//leet?
			else
			if (g_js_fJump_Distance[client] >= g_dist_leet_multibhop)	
			{
				// strafe hack protection					
				if (strafes == 0 || g_js_fPreStrafe[client] < 270.0)
				{
					PostThinkPost(client, ground_frames);
					return;
				}
				ValidJump=true;
				Format(g_js_szLastJumpDistance[client], 256, "<font color='#9a0909'><b>%.2f units</b></font>", g_js_fJump_Distance[client]);
				g_js_LeetJump_Count[client]++;
				//Client
				PrintToConsole(client, "        ");
				PrintToConsole(client, "[KZ] %s jumped %0.4f units with a MultiBhop [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %s Bhops | %i%c Sync]",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client], fJump_Height,szBhopCount,sync,PERCENT);
				PrintToConsole(client, "%s", szStrafeStats);
				PrintToChat(client, "%t", "ClientMultiBhop2",MOSSGREEN,WHITE,DARKRED,GRAY,DARKRED,g_js_fJump_Distance[client],GRAY,LIMEGREEN,strafes,GRAY,LIMEGREEN,g_js_fPreStrafe[client],GRAY,LIMEGREEN,g_js_fMax_Speed_Final[client],GRAY,LIMEGREEN, fJump_Height,GRAY, LIMEGREEN,szBhopCount,GRAY,LIMEGREEN, sync,PERCENT,GRAY);
				if (g_js_LeetJump_Count[client]==3)
					PrintToChat(client, "%t", "Jumpstats_OnRampage",MOSSGREEN,WHITE,YELLOW,szName);
				else
				if (g_js_LeetJump_Count[client]==5)
					PrintToChat(client, "%t", "Jumpstats_IsDominating",MOSSGREEN,WHITE,YELLOW,szName);						
			
				//all
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i))
					{
						if (g_bColorChat[i] && i != client)
						{
							PrintToChat(i, "%t", "Jumpstats_MultiBhopAll",MOSSGREEN,WHITE,DARKRED,szName, RED,DARKRED, g_js_fJump_Distance[client],RED,DARKRED);
							if (g_js_LeetJump_Count[client]==3)
									PrintToChat(i, "%t", "Jumpstats_OnRampage",MOSSGREEN,WHITE,YELLOW,szName);
								else
								if (g_js_LeetJump_Count[client]==5)
									PrintToChat(i, "%t", "Jumpstats_IsDominating",MOSSGREEN,WHITE,YELLOW,szName);
						}
					}
				}
				PlayLeetJumpSound(client);	
				if (g_js_LeetJump_Count[client] != 3 && g_js_LeetJump_Count[client] != 5)
				{
					decl String:buffer[255];
					Format(buffer, sizeof(buffer), "play %s", LEETJUMP_RELATIVE_SOUND_PATH); 	
					PlayQuakeSound_Spec(client,buffer);
				}
			}	
			else
				g_js_LeetJump_Count[client]=0;
		
		//strafe sync chat
		if (g_bStrafeSync[client] && g_js_fJump_Distance[client] >= g_dist_good_multibhop)
			PrintToChat(client,"%s", szStrafeSync);		
		
		//new best
		if (g_js_fPersonal_MultiBhop_Record[client] < g_js_fJump_Distance[client] &&  !IsFakeClient(client) && ValidJump)
		{
			if (g_js_fPersonal_MultiBhop_Record[client] > 0.0)
				PrintToChat(client, "%t", "Jumpstats_BeatMultiBhopBest",MOSSGREEN,WHITE,YELLOW, g_js_fJump_Distance[client]);
			g_js_fPersonal_MultiBhop_Record[client] = g_js_fJump_Distance[client];
			db_updateMultiBhopRecord(client);
		}
	}
	else
		g_js_MultiBhop_Count[client] = 1;	

	//dropbhop
	if (ground_frames < 11 && g_js_Last_Ground_Frames[client] > 11 && g_bLastButtonJump[client] && fGroundDiff == 0.0 && fJump_Height <= 67.0 && g_js_bDropJump[client])
	{		
		if (g_js_fDropped_Units[client] > 132.0)
		{
			if (g_js_fDropped_Units[client] < 300.0)
				PrintToChat(client, "%t", "DropBhop1",MOSSGREEN,WHITE,RED,g_js_fDropped_Units[client],WHITE,GREEN,WHITE,GRAY,WHITE);
		}
		else
		{
			if (g_js_fPreStrafe[client] > g_fMaxBhopPreSpeed)
				PrintToChat(client, "%t", "DropBhop2",MOSSGREEN,WHITE,RED,g_js_fPreStrafe[client],WHITE,GREEN,g_fMaxBhopPreSpeed,WHITE,GRAY,WHITE);
			else
			{
				
				//block invalid bot distances (has something to do with the ground-detection of the replay bot) WORKAROUND
				if ((IsFakeClient(client) && g_js_fJump_Distance[client] > (g_dist_leet_dropbhop * 1.05)) || strafes > 20)
				{
					Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>invalid</font>");
					PostThinkPost(client, ground_frames);
					return;
				}
				
				Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>%.1f units</font>", g_js_fJump_Distance[client]);
				//good
				if (g_js_fJump_Distance[client] >= g_dist_good_dropbhop && g_js_fJump_Distance[client] < g_dist_pro_dropbhop)	
				{
					ValidJump = true;
					Format(g_js_szLastJumpDistance[client], 256, "<font color='#676060'><b>%.1f units</b></font>", g_js_fJump_Distance[client]);
					g_js_LeetJump_Count[client]=0;	
					PrintToChat(client, "%t", "ClientDropBhop1",MOSSGREEN,WHITE, GRAY,g_js_fJump_Distance[client],LIMEGREEN, strafes, GRAY, LIMEGREEN, g_js_fPreStrafe[client], GRAY, LIMEGREEN,fJump_Height,GRAY, LIMEGREEN,sync,PERCENT,GRAY);	
					PrintToConsole(client, "        ");
					PrintToConsole(client, "[KZ] %s jumped %0.4f units with a DropBhop [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);						
					PrintToConsole(client, "%s", szStrafeStats);
				}	
				else
					//pro
					if (g_js_fJump_Distance[client] >= g_dist_pro_dropbhop && g_js_fJump_Distance[client] < g_dist_leet_dropbhop)
					{		
						ValidJump = true;
						g_js_LeetJump_Count[client]=0;
						Format(g_js_szLastJumpDistance[client], 256, "<font color='#21982a'><b>%.2f units</b></font>", g_js_fJump_Distance[client]);
						PrintToConsole(client, "        ");
						PrintToChat(client, "%t", "ClientDropBhop2",MOSSGREEN,WHITE,GREEN,GRAY,GREEN,g_js_fJump_Distance[client],GRAY,LIMEGREEN,strafes,GRAY,LIMEGREEN,g_js_fPreStrafe[client],GRAY,LIMEGREEN, g_js_fMax_Speed_Final[client],GRAY,LIMEGREEN, fJump_Height,GRAY, LIMEGREEN,sync,PERCENT,GRAY);	
						PrintToConsole(client, "[KZ] %s jumped %0.4f units with a DropBhop [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);						
						PrintToConsole(client, "%s", szStrafeStats);
						decl String:buffer[255];
						Format(buffer, sizeof(buffer), "play %s", PROJUMP_RELATIVE_SOUND_PATH); 
						if (g_bEnableQuakeSounds[client])
							ClientCommand(client, buffer); 
						PlayQuakeSound_Spec(client,buffer);	
						//all
						for (new i = 1; i <= MaxClients; i++)
						{
							if (IsValidClient(i))
							{
								if (g_bColorChat[i]==true && i != client)
									PrintToChat(i, "%t", "Jumpstats_DropBhopAll",MOSSGREEN,WHITE,GREEN,szName, MOSSGREEN,GREEN, g_js_fJump_Distance[client],MOSSGREEN,GREEN);
							}
						}
					}
					//leet
					else
						if (g_js_fJump_Distance[client] >= g_dist_leet_dropbhop  && g_js_fMax_Speed_Final[client] > 330.0)	
						{				
							// strafe hack protection					
							if (strafes == 0 || g_js_fPreStrafe[client] < 270.0)
							{
								Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>invalid</font>");
								PostThinkPost(client, ground_frames);
								return;
							}
							ValidJump = true;
							Format(g_js_szLastJumpDistance[client], 256, "<font color='#9a0909'><b>%.2f units</b></font>", g_js_fJump_Distance[client]);		
							g_js_LeetJump_Count[client]++;
							//Client
							PrintToConsole(client, "        ");
							PrintToChat(client, "%t", "ClientDropBhop2",MOSSGREEN,WHITE,DARKRED,GRAY,DARKRED,g_js_fJump_Distance[client],GRAY,LIMEGREEN,strafes,GRAY,LIMEGREEN,g_js_fPreStrafe[client],GRAY,LIMEGREEN, g_js_fMax_Speed_Final[client],GRAY,LIMEGREEN,fJump_Height,GRAY, LIMEGREEN, sync,PERCENT,GRAY);	
							PrintToConsole(client, "[KZ] %s jumped %0.4f units with a DropBhop [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
							PrintToConsole(client, "%s", szStrafeStats);
							if (g_js_LeetJump_Count[client]==3)
								PrintToChat(client, "%t", "Jumpstats_OnRampage",MOSSGREEN,WHITE,YELLOW,szName);
							else
								if (g_js_LeetJump_Count[client]==5)
									PrintToChat(client, "%t", "Jumpstats_IsDominating",MOSSGREEN,WHITE,YELLOW,szName);
									
							//all
							for (new i = 1; i <= MaxClients; i++)
							{
								if (IsValidClient(i))
								{
									if (g_bColorChat[i]==true && i != client)
									{
										PrintToChat(i, "%t", "Jumpstats_DropBhopAll",MOSSGREEN,WHITE,DARKRED,szName, RED,DARKRED, g_js_fJump_Distance[client], RED,DARKRED);
										if (g_js_LeetJump_Count[client]==3)
												PrintToChat(i, "%t", "Jumpstats_OnRampage",MOSSGREEN,WHITE,YELLOW,szName);
										else
											if (g_js_LeetJump_Count[client]==5)
												PrintToChat(i, "%t", "Jumpstats_IsDominating",MOSSGREEN,WHITE,YELLOW,szName);
									}
								}	
							}
							PlayLeetJumpSound(client);	
							if (g_js_LeetJump_Count[client] != 3 && g_js_LeetJump_Count[client] != 5)
							{
								decl String:buffer[255];
								Format(buffer, sizeof(buffer), "play %s", LEETJUMP_RELATIVE_SOUND_PATH); 	
								PlayQuakeSound_Spec(client,buffer);
							}
						}		
						else
							g_js_LeetJump_Count[client]=0;
				
				//strafesync chat
				if (g_bStrafeSync[client] && g_js_fJump_Distance[client] >= g_dist_good_dropbhop)
					PrintToChat(client,"%s", szStrafeSync);	
				
				//new best
				if (g_js_fPersonal_DropBhop_Record[client] < g_js_fJump_Distance[client]  &&  !IsFakeClient(client) && ValidJump)
				{
					if (g_js_fPersonal_DropBhop_Record[client] > 0.0)
						PrintToChat(client, "%t", "Jumpstats_BeatDropBhopBest",MOSSGREEN,WHITE,YELLOW, g_js_fJump_Distance[client]);
					g_js_fPersonal_DropBhop_Record[client] = g_js_fJump_Distance[client];
					db_updateDropBhopRecord(client);
				}				
			}
		}
	}
	// WeirdJump
	if (ground_frames < 11 && !g_bLastButtonJump[client] && fGroundDiff == 0.0 && fJump_Height <= 67.0 && g_js_bDropJump[client])
	{						
			if (g_js_fDropped_Units[client] > 132.0)
			{
				if (g_js_fDropped_Units[client] < 300.0)
					PrintToChat(client, "%t", "Wj1",MOSSGREEN,WHITE,RED,g_js_fDropped_Units[client],WHITE,GREEN,WHITE,GRAY,WHITE);
			}
			else
			{
				if (g_js_fPreStrafe[client] > 300)
					PrintToChat(client, "%t", "Wj2",MOSSGREEN,WHITE,RED,g_js_fPreStrafe[client],WHITE,GREEN,WHITE,GRAY,WHITE);
				else
				{
					//block invalid bot distances (has something to do with the ground-detection of the replay bot) WORKAROUND
					if ((IsFakeClient(client) && g_js_fJump_Distance[client] > (g_dist_leet_weird * 1.05)) || strafes > 20)
					{
						Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>invalid</font>");
						PostThinkPost(client, ground_frames);
						return;
					}					
						

					Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>%.1f units</font>", g_js_fJump_Distance[client]);
					//good?
					if (g_js_fJump_Distance[client] >= g_dist_good_weird && g_js_fJump_Distance[client] < g_dist_pro_weird)	
					{
						ValidJump = true;
						Format(g_js_szLastJumpDistance[client], 256, "<font color='#676060'><b>%.1f units</b></font>", g_js_fJump_Distance[client]);
						g_js_LeetJump_Count[client]=0;
						PrintToChat(client, "%t", "ClientWeirdJump1",MOSSGREEN,WHITE, GRAY,g_js_fJump_Distance[client],LIMEGREEN, strafes, GRAY, LIMEGREEN, g_js_fPreStrafe[client], GRAY, LIMEGREEN,fJump_Height,GRAY, LIMEGREEN, sync,PERCENT,GRAY);	
						PrintToConsole(client, "        ");
						PrintToConsole(client, "[KZ] %s jumped %0.4f units with a WeirdJump [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);						
						PrintToConsole(client, "%s", szStrafeStats);	
					}	
					//pro?
					else
						if (g_js_fJump_Distance[client] >= g_dist_pro_weird && g_js_fJump_Distance[client] < g_dist_leet_weird)
						{
							ValidJump = true;
							Format(g_js_szLastJumpDistance[client], 256, "<font color='#21982a'><b>%.2f units</b></font>", g_js_fJump_Distance[client]);
							g_js_LeetJump_Count[client]=0;
							//Client
							PrintToConsole(client, "        ");
							PrintToChat(client, "%t", "ClientWeirdJump2",MOSSGREEN,WHITE,GREEN,GRAY,GREEN,g_js_fJump_Distance[client],GRAY,LIMEGREEN,strafes,GRAY,LIMEGREEN,g_js_fPreStrafe[client],GRAY,LIMEGREEN, g_js_fMax_Speed_Final[client],GRAY,LIMEGREEN,fJump_Height,GRAY, LIMEGREEN, sync,PERCENT,GRAY);
							PrintToConsole(client, "[KZ] %s jumped %0.4f units with a WeirdJump [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);						
							PrintToConsole(client, "%s", szStrafeStats);
							decl String:buffer[255];
							Format(buffer, sizeof(buffer), "play %s", PROJUMP_RELATIVE_SOUND_PATH); 
							if (g_bEnableQuakeSounds[client])
								ClientCommand(client, buffer); 
							PlayQuakeSound_Spec(client,buffer);	
							//all
							for (new i = 1; i <= MaxClients; i++)
							{
								if (IsValidClient(i))
								{
									if (g_bColorChat[i]==true && i != client)
										PrintToChat(i, "%t", "Jumpstats_WeirdAll",MOSSGREEN,WHITE,GREEN,szName, MOSSGREEN,GREEN, g_js_fJump_Distance[client],MOSSGREEN,GREEN);
								}
							}
						}
						//leet?
						else
							if (g_js_fJump_Distance[client] >= g_dist_leet_weird)	
							{
								// strafe hack protection					
								if (strafes == 0 || g_js_fPreStrafe[client] < 255.0)
								{
									Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>invalid</font>");
									PostThinkPost(client, ground_frames);
									return;
								}
								ValidJump = true;
								Format(g_js_szLastJumpDistance[client], 256, "<font color='#9a0909'><b>%.2f units</b></font>", g_js_fJump_Distance[client]);
								g_js_LeetJump_Count[client]++;
								//Client
								PrintToConsole(client, "        ");
								PrintToChat(client, "%t", "ClientWeirdJump2",MOSSGREEN,WHITE,DARKRED,GRAY,DARKRED,g_js_fJump_Distance[client],GRAY,LIMEGREEN,strafes,GRAY,LIMEGREEN,g_js_fPreStrafe[client],GRAY,LIMEGREEN, g_js_fMax_Speed_Final[client],GRAY,LIMEGREEN,fJump_Height,GRAY, LIMEGREEN, sync,PERCENT,GRAY);
								PrintToConsole(client, "[KZ] %s jumped %0.4f units with a WeirdJump [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);
								PrintToConsole(client, "%s", szStrafeStats);
								if (g_js_LeetJump_Count[client]==3)
									PrintToChat(client, "%t", "Jumpstats_OnRampage",MOSSGREEN,WHITE,YELLOW,szName);
								else
									if (g_js_LeetJump_Count[client]==5)
										PrintToChat(client, "%t", "Jumpstats_IsDominating",MOSSGREEN,WHITE,YELLOW,szName);
													
								//all
								for (new i = 1; i <= MaxClients; i++)
								{
									if (IsValidClient(i))
									{
										if (g_bColorChat[i]==true && i != client)
										{
											PrintToChat(i, "%t", "Jumpstats_WeirdAll",MOSSGREEN,WHITE,DARKRED,szName, RED,DARKRED, g_js_fJump_Distance[client],RED,DARKRED);
											if (g_js_LeetJump_Count[client]==3)
													PrintToChat(i, "%t", "Jumpstats_OnRampage",MOSSGREEN,WHITE,YELLOW,szName);
												else
												if (g_js_LeetJump_Count[client]==5)
													PrintToChat(i, "%t", "Jumpstats_IsDominating",MOSSGREEN,WHITE,YELLOW,szName);
										}
									}
								}
								PlayLeetJumpSound(client);
								if (g_js_LeetJump_Count[client] != 3 && g_js_LeetJump_Count[client] != 5)
								{
									decl String:buffer[255];
									Format(buffer, sizeof(buffer), "play %s", LEETJUMP_RELATIVE_SOUND_PATH); 	
									PlayQuakeSound_Spec(client,buffer);
								}								
							}		
							else
								g_js_LeetJump_Count[client]=0;		
					
					//strafesync chat
					if (g_bStrafeSync[client]  && g_js_fJump_Distance[client] >= g_dist_good_weird)
						PrintToChat(client,"%s", szStrafeSync);	
						
					//new best
					if (g_js_fPersonal_Wj_Record[client] < g_js_fJump_Distance[client]  &&  !IsFakeClient(client) && ValidJump)
					{
						if (g_js_fPersonal_Wj_Record[client] > 0.0)
							PrintToChat(client, "%t", "Jumpstats_BeatWjBest",MOSSGREEN,WHITE,YELLOW, g_js_fJump_Distance[client]);
						g_js_fPersonal_Wj_Record[client] = g_js_fJump_Distance[client];
						db_updateWjRecord(client);
					}
				}
			}
	}
	//BunnyHop
	if (ground_frames < 11 && g_js_Last_Ground_Frames[client] > 10 && fGroundDiff == 0.0 && fJump_Height <= 67.0 && !g_js_bDropJump[client] && g_js_fPreStrafe[client] > 200.0)
	{
			//block invalid bot distances (has something to do with the ground-detection of the replay bot) WORKAROUND
			if (((IsFakeClient(client) && g_js_fJump_Distance[client] > (g_dist_leet_bhop * 1.025)) || g_js_fJump_Distance[client] > 400.0) || strafes > 20)
			{
				Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>invalid</font>");
				PostThinkPost(client, ground_frames);
				return;
			}
			
			if (g_js_fPreStrafe[client]> g_fMaxBhopPreSpeed)
					PrintToChat(client, "%t", "Bhop1",MOSSGREEN,WHITE,RED,g_js_fPreStrafe[client],WHITE,GREEN,g_fMaxBhopPreSpeed,WHITE,GRAY,WHITE);
			else
			{	
				Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>%.1f units</font>", g_js_fJump_Distance[client]);
				//good?
				if (g_js_fJump_Distance[client] >= g_dist_good_bhop && g_js_fJump_Distance[client] < g_dist_pro_bhop)	
				{
					ValidJump=true;
					Format(g_js_szLastJumpDistance[client], 256, "<font color='#676060'><b>%.1f units</b></font>", g_js_fJump_Distance[client]);
					g_js_LeetJump_Count[client]=0;
					PrintToChat(client, "%t", "ClientBunnyhop1",MOSSGREEN,WHITE,GRAY, g_js_fJump_Distance[client],LIMEGREEN, strafes, GRAY, LIMEGREEN, g_js_fPreStrafe[client], GRAY, LIMEGREEN, fJump_Height,GRAY, LIMEGREEN, sync,PERCENT,GRAY);	
					PrintToConsole(client, "        ");
					PrintToConsole(client, "[KZ] %s jumped %0.4f units with a Bhop [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height,sync,PERCENT);						
					PrintToConsole(client, "%s", szStrafeStats);
				}	
				else
					//pro?
					if (g_js_fJump_Distance[client] >= g_dist_pro_bhop && g_js_fJump_Distance[client] < g_dist_leet_bhop)
					{
						ValidJump=true;
						Format(g_js_szLastJumpDistance[client], 256, "<font color='#21982a'><b>%.2f units</b></font>", g_js_fJump_Distance[client]);
						g_js_LeetJump_Count[client]=0;
						PrintToConsole(client, "        ");
						PrintToChat(client, "%t", "ClientBunnyhop2",MOSSGREEN,WHITE,GREEN,GRAY,GREEN,g_js_fJump_Distance[client],GRAY,LIMEGREEN,strafes,GRAY,LIMEGREEN,g_js_fPreStrafe[client],GRAY,LIMEGREEN, g_js_fMax_Speed_Final[client],GRAY,LIMEGREEN, fJump_Height,GRAY, LIMEGREEN, sync,PERCENT,GRAY);
						PrintToConsole(client, "[KZ] %s jumped %0.4f units with a Bhop [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height, sync,PERCENT);						
						PrintToConsole(client, "%s", szStrafeStats);
						decl String:buffer[255];
						Format(buffer, sizeof(buffer), "play %s", PROJUMP_RELATIVE_SOUND_PATH); 
						if (g_bEnableQuakeSounds[client])
							ClientCommand(client, buffer); 
						PlayQuakeSound_Spec(client,buffer);	
						//all
						for (new i = 1; i <= MaxClients; i++)
						{
							if (IsValidClient(i))
							{
								if (g_bColorChat[i]==true && i != client)
									PrintToChat(i, "%t", "Jumpstats_BhopAll",MOSSGREEN,WHITE,GREEN,szName, MOSSGREEN,GREEN, g_js_fJump_Distance[client],MOSSGREEN,GREEN);
							}
						}
					}
					else
					{
						//leet?
						if (g_js_fJump_Distance[client] >= g_dist_leet_bhop && g_js_fMax_Speed_Final[client] > 330.0)	
						{
							ValidJump=true;
							// strafe hack protection					
							if (strafes == 0 || g_js_fPreStrafe[client] < 270.0)
							{
								Format(g_js_szLastJumpDistance[client], 256, "<font color='#948d8d'>invalid</font>");
								PostThinkPost(client, ground_frames);
								return;
							}
							Format(g_js_szLastJumpDistance[client], 256, "<font color='#9a0909'><b>%.2f units</b></font>", g_js_fJump_Distance[client]);
							g_js_LeetJump_Count[client]++;
							//Client
							PrintToConsole(client, "        ");
							PrintToChat(client, "%t", "ClientBunnyhop2",MOSSGREEN,WHITE,DARKRED,GRAY,DARKRED,g_js_fJump_Distance[client],GRAY,LIMEGREEN,strafes,GRAY,LIMEGREEN,g_js_fPreStrafe[client],GRAY,LIMEGREEN, g_js_fMax_Speed_Final[client],GRAY,LIMEGREEN, fJump_Height,GRAY, LIMEGREEN, sync,PERCENT,GRAY);
							PrintToConsole(client, "[KZ] %s jumped %0.4f units with a Bhop [%i Strafes | %.3f Pre | %.3f Max | Height %.1f | %i%c Sync]",szName, g_js_fJump_Distance[client],strafes, g_js_fPreStrafe[client], g_js_fMax_Speed_Final[client],fJump_Height, sync,PERCENT);
							PrintToConsole(client, "%s", szStrafeStats);
							if (g_js_LeetJump_Count[client]==3)
								PrintToChat(client, "%t", "Jumpstats_OnRampage",MOSSGREEN,WHITE,YELLOW,szName);
							else
							if (g_js_LeetJump_Count[client]==5)
										PrintToChat(client, "%t", "Jumpstats_IsDominating",MOSSGREEN,WHITE,YELLOW,szName);
											
							//all
							for (new i = 1; i <= MaxClients; i++)
							{
								if (IsValidClient(i))
								{
									if (g_bColorChat[i]==true && i != client)
									{
										PrintToChat(i, "%t", "Jumpstats_BhopAll",MOSSGREEN,WHITE,DARKRED,szName, RED,DARKRED, g_js_fJump_Distance[client],RED,DARKRED);
										if (g_js_LeetJump_Count[client]==3)
											PrintToChat(i, "%t", "Jumpstats_OnRampage",MOSSGREEN,WHITE,YELLOW,szName);
										else
											if (g_js_LeetJump_Count[client]==5)
												PrintToChat(i, "%t", "Jumpstats_IsDominating",MOSSGREEN,WHITE,YELLOW,szName);
									}
								}
							}
							PlayLeetJumpSound(client);
							if (g_js_LeetJump_Count[client] != 3 && g_js_LeetJump_Count[client] != 5)
							{
								decl String:buffer[255];
								Format(buffer, sizeof(buffer), "play %s", LEETJUMP_RELATIVE_SOUND_PATH); 	
								PlayQuakeSound_Spec(client,buffer);
							}						
						}		
						else
						{
							g_js_LeetJump_Count[client]=0;
						}
					}
							
				//strafe sync chat
				if (g_bStrafeSync[client] && g_js_fJump_Distance[client] >= g_dist_good_bhop)
						PrintToChat(client,"%s", szStrafeSync);		
				
				//new best
				if (g_js_fPersonal_Bhop_Record[client] < g_js_fJump_Distance[client]  &&  !IsFakeClient(client) && ValidJump)
				{
					if (g_js_fPersonal_Bhop_Record[client] > 0.0)
						PrintToChat(client, "%t", "Jumpstats_BeatBhopBest",MOSSGREEN,WHITE,YELLOW, g_js_fJump_Distance[client]);
					g_js_fPersonal_Bhop_Record[client] = g_js_fJump_Distance[client];
					db_updateBhopRecord(client);
				}
			}
	}
	if (!ValidJump)
		g_js_LeetJump_Count[client]=0;
	PostThinkPost(client, ground_frames);					
}

public PostThinkPost(client, ground_frames)
{
	g_js_bPlayerJumped[client] = false;
	g_js_Last_Ground_Frames[client] = ground_frames;		
}