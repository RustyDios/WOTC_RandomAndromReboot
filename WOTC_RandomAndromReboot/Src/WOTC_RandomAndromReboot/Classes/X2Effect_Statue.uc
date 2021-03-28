//---------------------------------------------------------------------------------------
//  FILE:   X2Effect_RandomAndrom.uc                                    
//
//	CREATED BY RustyDios
//           
//	File created	24/12/20	20:30
//	LAST UPDATED    04/01/21	00:15
//
//	clone of X2Effect_Pillar but with some changes for permanent duration ... 
//
//---------------------------------------------------------------------------------------
class X2Effect_Statue extends X2Effect_SpawnDestructible;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit RobotUnitState;
	local XComGameState_Destructible DestructibleState;

	RobotUnitState = XComGameState_Unit(kNewTargetState);

	//SpawnDynamicGameStateDestructible( string DestructibleArchetype, vector SpawnLocation, eTeam Team, optional XComGameState NewGameState )
	DestructibleState = class'XComDestructibleActor'.static.SpawnDynamicGameStateDestructible( DestructibleArchetype, 
							`XWORLD.GetPositionFromTileCoordinates(RobotUnitState.TileLocation), eTeam_Neutral, NewGameState );

	DestructibleState.OnlyAllowTargetWithEnemiesInTheBlastRadius = false;
	DestructibleState.bTargetableBySpawnedTeamOnly = bTargetableBySpawnedTeamOnly;

	NewEffectState.CreatedObjectReference = DestructibleState.GetReference();
	NewEffectState.ApplyEffectParameters.ItemStateObjectRef = DestructibleState.GetReference();
}

function int GetStartingNumTurns(const out EffectAppliedData ApplyEffectParameters)
{
	// if this effect is specified for an infinite duration, return 1
	if( bInfiniteDuration )
	{
		return 1;
	}

	return super.GetStartingNumTurns(ApplyEffectParameters);
}

DefaultProperties
{
	EffectName = "Statue"
	DuplicateResponse = eDupe_Allow
	bDestroyOnRemoval = false
}