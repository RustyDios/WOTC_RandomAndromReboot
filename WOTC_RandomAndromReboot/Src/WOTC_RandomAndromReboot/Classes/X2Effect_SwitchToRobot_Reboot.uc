//---------------------------------------------------------------------------------------
//  FILE:   X2Effect_RandomAndrom.uc                                    
//
//	CREATED BY RustyDios
//           
//	File created	24/12/20	20:30
//	LAST UPDATED    24/03/21	01:00
//  
//	USES AN EVENT HOOK TO CHANGE THE TEAM THE ROBOT HALF SPAWNS ON, INCLUDING TEAM_DEAD
//
//---------------------------------------------------------------------------------------
class X2Effect_SwitchToRobot_Reboot extends X2Effect_SpawnUnit config (RustyRandomReboot);

var config bool bEnableRandomAndromLog;
var config bool bIgnoreIfOnXCOMTeam, bXCOMtoXCOMAlways;

var config int iRebootToDEAD, iRebootToXCOM, iRebootToLOST, iRebootToCIVS, iRebootToFAC1, iRebootToFAC2;//, iRebootToNORM;
var config int iAPonCovert; 

var int iRandoAndro, KillAmount;
var bool bForceDead;

// var bool bClearTileBlockedByTargetUnitFlag; //from parent

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit RobotUnitState;

	RobotUnitState = XComGameState_Unit(kNewTargetState);
	//`assert(TargetUnitState != none);

	iRandoAndro = `SYNC_RAND(100); //`SYNC_RAND_STATIC(100);

    `LOG("FOUND UNIT :: "$RobotUnitState.GetMyTemplateName() @RobotUnitState.GetName(eNameType_FullNick) , default.bEnableRandomAndromLog ,'RandomAndromedonReboot');
	`LOG("CHECK TEAM :: IS ON TEAM :: " $GetTeamString(RobotUnitState.GetTeam() ), default.bEnableRandomAndromLog ,'RandomAndromedonReboot');
	`LOG("THRESHOLDS :: 0 ::DEAD::XCOM::LOST::CIVS::FAC1::FAC2::ADVENT", default.bEnableRandomAndromLog ,'RandomAndromedonReboot');
	`LOG("THRESHOLDS :: 0 ::" @default.iRebootToDEAD @"::" @default.iRebootToXCOM @"::" @default.iRebootToLOST @"::" @default.iRebootToCIVS @"::" @default.iRebootToFAC1 @"::" @default.iRebootToFAC2 @":: 100", default.bEnableRandomAndromLog ,'RandomAndromedonReboot');
    
	//IGNORE for XCOM ... THIS ENSURES ANDROMEDONS IN PLAYABLE ALIENS or ADVENT DOUBLE AGENTS BEHAVE AS NORMAL or MIND CONTROL TO ADVENT HACKABLE ROBOT
    if(RobotUnitState.GetTeam() == eTeam_XCom && default.bIgnoreIfOnXCOMTeam && !bForceDead)
    {
		`LOG("ABORTED    :: RANDOM ANDROMEDON REBOOT, IGNORE MOD IF ON XCOM TEAM ACTIVE" , default.bEnableRandomAndromLog ,'RandomAndromedonReboot');
        return;
    }

	//figure out what we should be doing
	if (iRandoAndro <= default.iRebootToDEAD || bForceDead)
	{
		`LOG("CONFIRMED  :: RANDOM ANDROMEDON REBOOT ROLL RESULT :: DEAD ::" @iRandoAndro @" < DEAD TARGET OF" @default.iRebootToDEAD, default.bEnableRandomAndromLog ,'RandomAndromedonReboot');

		////////////////////////////insert death logic here////////////////////////////
		/*
		event TakeDamage( XComGameState NewGameState, const int DamageAmount, const int MitigationAmount, const int ShredAmount, optional EffectAppliedData EffectData, 
						optional Object CauseOfDeath, optional StateObjectReference DamageSource, optional bool bExplosiveDamage = false, optional array<name> DamageTypes,
						optional bool bForceBleedOut = false, optional bool bAllowBleedout = true, optional bool bIgnoreShields = false, optional array<DamageModifierInfo> SpecialDamageMessages)
		*/

		//its not pretty... but it works... :)
		KillAmount = RobotUnitState.GetCurrentStat(eStat_HP) + RobotUnitState.GetCurrentStat(eStat_ShieldHP) +50; //plus 50 damage should ensure overkill
		RobotUnitState.TakeDamage(NewGameState, KillAmount,0,0,ApplyEffectParameters,RobotUnitState,ApplyEffectParameters.TargetStateObjectRef,false,,false,false,true );
		
		`LOG("DEAD ROLL  :: DAMAGE ::" @KillAmount-50, default.bEnableRandomAndromLog ,'RandomAndromedonReboot');
		`LOG("DEAD ROLL  :: FORCED ::" @bForceDead, default.bEnableRandomAndromLog ,'RandomAndromedonReboot');

		//this triggers an ability that activates full-cover for the unit and spawns a templar pillar on the spot, ala bulwark
		`XEVENTMGR.TriggerEvent('AndromedonToRobot_Statue', RobotUnitState, RobotUnitState, NewGameState);
		
		//update the andromedon shell to block unit movement on death, not needed stop putting it back in
		//`XWORLD.SetTileBlockedByUnitFlagAtLocation(RobotUnitState, RobotUnitState.TileLocation);
		//`XWORLD.DebugRebuildTileData(RobotUnitState.TileLocation);

		//DO NOT clear tile as the unit is staying here to block movement
		bClearTileBlockedByTargetUnitFlag = false;
				
		`LOG("FINALISED  :: RANDOM ANDROMEDON REBOOT ROLL RESULT :: FINALISED ", default.bEnableRandomAndromLog ,'RandomAndromedonReboot');
		return;
    }
	else if (iRandoAndro > default.iRebootToDEAD || (RobotUnitState.GetTeam() == eTeam_XCom && default.bXCOMtoXCOMAlways) )
	{
		////////////////////////////insert team swap logic here////////////////////////////
		// clear the tile so the new unit can spawn in the same place
		bClearTileBlockedByTargetUnitFlag = true;	//`XWORLD.ClearTileBlockedByUnitFlag(RobotUnitState);

		TriggerSpawnEvent(ApplyEffectParameters, RobotUnitState, NewGameState, NewEffectState);

		`LOG("FINALISED  :: RANDOM ANDROMEDON REBOOT ROLL RESULT :: FINALISED ", default.bEnableRandomAndromLog ,'RandomAndromedonReboot');
        return;
    }
	else //if (iRandoAndro = ?? ) //anything that doesn't confirm to the above logic
	{
		//failing everything else return for safety
		`LOG("SKIPPED    :: RANDOM ANDROMEDON REBOOT ROLL RESULT :: SKIPPED ::" @iRandoAndro, default.bEnableRandomAndromLog ,'RandomAndromedonReboot');
        return;
    }
}

function OnSpawnComplete(const out EffectAppliedData ApplyEffectParameters, StateObjectReference NewUnitRef, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit DeadUnitGameState, RobotGameState;
	//local XGUnit			 XGDeadUnitState;

	//find the old unit
	DeadUnitGameState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( DeadUnitGameState == none )
	{
		DeadUnitGameState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID, eReturnType_Reference));
	}

	/*if (iRandoAndro > default.iRebootToDEAD)
	{
		//find and hide the old unit visually
		XGDeadUnitState = XGUnit(DeadUnitGameState.GetVisualizer());
		XGDeadUnitState.m_bForceHidden = true;
		XGDeadUnitState.GetPawn().SetVisible(false);
	}*/

	// Remove the OLD Andromedon Shell unit from play
	`XEVENTMGR.TriggerEvent('UnitRemovedFromPlay', DeadUnitGameState, DeadUnitGameState, NewGameState);

	// The Robot needs to be messaged to reboot
	RobotGameState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(NewUnitRef.ObjectID));

	`XEVENTMGR.TriggerEvent('AndromedonToRobot_Reboot', RobotGameState, DeadUnitGameState, NewGameState);

	//give out some team specific bonuses, like xcom action points
	AwardTeamSpecificBonuses(RobotGameState);

}

function AddSpawnVisualizationsToTracks(XComGameStateContext Context, XComGameState_Unit SpawnedUnit, out VisualizationActionMetadata SpawnedUnitTrack,
										XComGameState_Unit EffectTargetUnit, optional out VisualizationActionMetadata EffectTargetUnitTrack)
{
	//removed and sent to the ability visualization function
	//local X2Action_AndromedonRobotSpawn RobotSpawn;

	// The Spawned unit should appear and play its change animation
	//RobotSpawn = X2Action_AndromedonRobotSpawn(class'X2Action_AndromedonRobotSpawn'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, true, none));
	//RobotSpawn.AndromedonUnit = XGUnit(`XCOMHISTORY.GetVisualizer(EffectTargetUnit.ObjectID) );
}

function ETeam GetTeam(const out EffectAppliedData ApplyEffectParameters)
{
	local XComGameState_Unit	RobotUnitState;
	local ETeam					RandomTeam;

	RobotUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	//figure out what team we want a new unit to be on
		//if (iRandoAndro <= default.iRebootToDead)
		//{
		//	//Insert death logic ... moved to OnApplyEffect
		//}
	if ( (iRandoAndro > default.iRebootToDEAD && iRandoAndro <= default.iRebootToXCOM) || (RobotUnitState.GetTeam() == eTeam_XCom && default.bXCOMtoXCOMAlways))
	{
		RandomTeam = eTeam_XCom;
		`LOG("CONFIRMED  :: RANDOM ANDROMEDON REBOOT ROLL RESULT :: XCOM ::" @iRandoAndro @" :: BETWEEN " @default.iRebootToDEAD @" && " @default.iRebootToXCOM @" :: ALWAYS XCOM TO XCOM :: " @default.bXCOMtoXCOMAlways , default.bEnableRandomAndromLog ,'RandomAndromedonReboot');
	}
	else if (iRandoAndro > default.iRebootToXCOM && iRandoAndro <= default.iRebootToLOST)
	{
		RandomTeam = eTeam_TheLost;		
		`LOG("CONFIRMED  :: RANDOM ANDROMEDON REBOOT ROLL RESULT :: LOST ::" @iRandoAndro @" :: BETWEEN " @default.iRebootToXCOM @" && " @default.iRebootToLOST , default.bEnableRandomAndromLog ,'RandomAndromedonReboot');
	}
	else if (iRandoAndro > default.iRebootToLOST && iRandoAndro <= default.iRebootToCIVS)
	{
		RandomTeam = eTeam_Resistance;
		`LOG("CONFIRMED  :: RANDOM ANDROMEDON REBOOT ROLL RESULT :: CIVS ::" @iRandoAndro @" :: BETWEEN " @default.iRebootToLOST @" && " @default.iRebootToCIVS , default.bEnableRandomAndromLog ,'RandomAndromedonReboot');
	}
	else if (iRandoAndro > default.iRebootToCIVS && iRandoAndro <= default.iRebootToFAC1)
	{
		RandomTeam = eTeam_One;
		`LOG("CONFIRMED  :: RANDOM ANDROMEDON REBOOT ROLL RESULT :: FAC1 ::" @iRandoAndro @" :: BETWEEN " @default.iRebootToCIVS @" && " @default.iRebootToFAC1  , default.bEnableRandomAndromLog ,'RandomAndromedonReboot');
	}
	else if (iRandoAndro > default.iRebootToFAC1 && iRandoAndro <= default.iRebootToFAC2)
	{
		RandomTeam = eTeam_Two;
		`LOG("CONFIRMED  :: RANDOM ANDROMEDON REBOOT ROLL RESULT :: FAC2 ::" @iRandoAndro @" :: BETWEEN " @default.iRebootToFAC1 @" && " @default.iRebootToFAC2  , default.bEnableRandomAndromLog ,'RandomAndromedonReboot');
	}
	else //if (iRandoAndro > default.iRebootToFAC2 && iRandoAndro <= default.iRebootToNORM) //anything that doesn't confirm to the above logic
	{
		RandomTeam = eTeam_Alien;
		`LOG("CONFIRMED  :: RANDOM ANDROMEDON REBOOT ROLL RESULT :: NORM ::" @iRandoAndro @" > HIGHEST CONFIG"  , default.bEnableRandomAndromLog ,'RandomAndromedonReboot');
	}

	//return the allocated team from the random roll
	return RandomTeam; 
}

function name GetUnitToSpawnName(const out EffectAppliedData ApplyEffectParameters)
{
	local XComGameState_Unit TargetUnit;

	//we want to spawn a clone of the unit, this will ensure we use the right robot, regardless of source, as we are cloning the 'already spawned correct robot'
	TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	return TargetUnit.GetMyTemplateName(); //UnitToSpawnName;
}

function AwardTeamSpecificBonuses(XComGameState_Unit RobotGameState)
{
	local ETeam NewTeam;
	local int i;

	NewTeam = RobotGameState.GetTeam();

	switch( NewTeam )
	{
		case eTeam_XCom:
			//RobotGameState.bHasBeenHacked = true;

			//SORT OUT EXTRA ACTION POINTS
			RobotGameState.StunnedActionPoints = 0;
			RobotGameState.ActionPoints.Length = 0;
			for( i = 0; i < default.iAPonCovert; ++i )
			{
				RobotGameState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
			}
			`LOG("TEAM BONUS :: XCOM :: " @default.iAPonCovert $"AP ADDED", default.bEnableRandomAndromLog ,'RandomAndromedonReboot');
			break;
		case eTeam_Alien:
		case eTeam_TheLost:
		case eTeam_Neutral:
		case eTeam_Resistance:
		case eTeam_One:
		case eTeam_Two:
			`LOG("TEAM BONUS :: ELSE :: NO BONUS", default.bEnableRandomAndromLog ,'RandomAndromedonReboot');
			break;
		default:
			`LOG("ERROR      :: UNKNOWN TEAM PASSED TO BONUS :: " @GetTeamString(NewTeam), default.bEnableRandomAndromLog ,'RandomAndromedonReboot');
			break;	//`assert(false);
	}
}

//mainly for easy log statements
static function String GetTeamString(ETeam TeamToConvert)
{
	switch( TeamToConvert )
	{
		case eTeam_None:		return "NONE, RULER or CHOSEN";
		case eTeam_All:			return "ALL";
        case eTeam_XCom:		return "XCOM";
        case eTeam_Alien:		return "ADVENT";
        case eTeam_TheLost:		return "LOST";
        case eTeam_Neutral:		return "CIVS";
        case eTeam_Resistance:  return "RESISTANCE";
        case eTeam_One:         return "FACTION ONE";
        case eTeam_Two:         return "FACTION TWO";
        default:        		return "UNKNOWN :: ENUM " $TeamToConvert ;
            break;
	}
}

///////////////////////////////////////
//these were default properties in the parent class, but here I actually set them directly depending on what is needed ... left here as reminder later
defaultproperties
{
	//UnitToSpawnName="AndromedonRobot"
	//bClearTileBlockedByTargetUnitFlag=true
}
