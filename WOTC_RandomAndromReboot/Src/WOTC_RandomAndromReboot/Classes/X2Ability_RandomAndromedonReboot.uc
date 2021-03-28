//---------------------------------------------------------------------------------------
//  FILE:   X2Ability_RandomAndromedonReboot                                    
//
//	CREATED BY RustyDios
//           
//	File created	24/12/20	20:30
//	LAST UPDATED    24/03/21	01:00
//  
//	CREATES ABILITIES NEEDED TO TURN THE REBOOT INTO A STATUE OR CONVERT TO ANOTHER TEAM
//	Thanks to MrNiceUK for help with the visualization aspects
//
//---------------------------------------------------------------------------------------
class X2Ability_RandomAndromedonReboot extends X2Ability_Andromedon config(RustyRandomReboot);

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateSwitchToRobotAbility_Random());
	Templates.AddItem(CreateRebootAbility_Random());
	Templates.AddItem(CreateRebootCoverStatue());
	Templates.addItem(Create_AndromedonBulwark());
	Templates.addItem(Create_AndromedonEvacDeath());

	return Templates;
}

//////////////////////////////////////
//	SwitchToRobot - Reboot
// 	SO THIS IS THE ANDROMEDON HALF OF THE SWITCH, GIVEN TO THE 'OLD SHELL'
//////////////////////////////////////


static function X2AbilityTemplate CreateSwitchToRobotAbility_Random()
{
	local X2AbilityTemplate					Template;
	local X2AbilityTrigger_EventListener	EventListener;
	local X2Condition_UnitValue				UnitValue;
	local X2Effect_SetUnitValue				SetUnitValEffect;
	local X2Effect_SwitchToRobot_Reboot		SwitchToRobotEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'SwitchToRobot_Reboot');

	// setup
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_andromedon_robotbattlesuit";
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;	

	Template.bDontDisplayInAbilitySummary = true;

	// Costs ... none

	// This ability is only valid if there has not been another reboot on the unit
	UnitValue = new class'X2Condition_UnitValue';
	UnitValue.AddCheckValue('RandomReboot', 1, eCheck_LessThan);
	Template.AbilityShooterConditions.AddItem(UnitValue);

	// Triggers and Targeting
	// This ability fires when the OLD Shell Is Made
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'AndromedonToRobot';
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self_VisualizeInGameState;
	EventListener.ListenerData.Priority = 42; //This ability must get triggered after the rest of the on-death listeners (namely, after mind-control effects get removed)
	Template.AbilityTriggers.AddItem(EventListener);

	// Targets the OLD Shell Andromedon unit so it can be replaced by the NEW  shell andromedon robot;
	Template.AbilityTargetStyle = default.SelfTarget;

	// Add dead eye to guarantee the explosion occurs
	Template.AbilityToHitCalc = default.DeadEye;

	// Effect
	// The target will now be turned into a cloned robot
	SwitchToRobotEffect = new class'X2Effect_SwitchToRobot_Reboot';
	SwitchToRobotEffect.BuildPersistentEffect(1);
	Template.AddTargetEffect(SwitchToRobotEffect);

	// Once this ability is fired, set the RandomReboot Unit Value so it will not happen again
	SetUnitValEffect = new class'X2Effect_SetUnitValue';
	SetUnitValEffect.UnitName = 'RandomReboot';
	SetUnitValEffect.NewValueToSet = 1;
	SetUnitValEffect.CleanupType = eCleanup_Never;
	Template.AddTargetEffect(SetUnitValEffect);

	// Visualization
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = SwitchToRobot_BuildVisualization;
	Template.MergeVisualizationFn = SwitchToRobot_VisualizationMerge;
	Template.FrameAbilityCameraType = eCameraFraming_Never;

	return Template;
}

//mostly copied from original ability as all this visualisation stuff goes above my head
simulated function SwitchToRobot_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateContext_Ability			Context;
	local XComGameStateHistory					History;
	local VisualizationActionMetadata			EmptyTrack, SpawnedUnitTrack, DeadUnitTrack;
	local XComGameState_Unit					SpawnedUnit, DeadUnit; 
	local UnitValue								SpawnedUnitValue;
	local X2Effect_SwitchToRobot_Reboot			SwitchToRobotEffect;
	local XComGameState_Ability					AbilityState;
	local X2AbilityTemplate						AbilityTemplate;
	local X2Action_AndromedonRobotSpawn 		RobotSpawn;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	History = `XCOMHISTORY;

	DeadUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID));
		//`assert(DeadUnit != none);	//removed to stop potential CTD

	DeadUnit.GetUnitValue(class'X2Effect_SpawnUnit'.default.SpawnedUnitValueName, SpawnedUnitValue);

	// The Spawned unit should appear and play its change animation
	DeadUnitTrack = EmptyTrack;
	DeadUnitTrack.StateObject_OldState = DeadUnit;
	DeadUnitTrack.StateObject_NewState = DeadUnitTrack.StateObject_OldState;
	DeadUnitTrack.VisualizeActor = History.GetVisualizer(DeadUnit.ObjectID);

	// The Spawned unit should appear and play its change animation
	SpawnedUnitTrack = EmptyTrack;
	SpawnedUnitTrack.StateObject_OldState = History.GetGameStateForObjectID(SpawnedUnitValue.fValue, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	SpawnedUnitTrack.StateObject_NewState = SpawnedUnitTrack.StateObject_OldState;
	SpawnedUnit = XComGameState_Unit(SpawnedUnitTrack.StateObject_NewState);
		//`assert(SpawnedUnit != none);	//removed to stop potential CTD
	SpawnedUnitTrack.VisualizeActor = History.GetVisualizer(SpawnedUnit.ObjectID);

	// Only first target effect if X2Effect_SwitchToRobot
	SwitchToRobotEffect = X2Effect_SwitchToRobot_Reboot(Context.ResultContext.TargetEffectResults.Effects[0]);

	if( SwitchToRobotEffect == none )
	{
		// This can happen due to replays. In replays, when moving Context visualizations forward the Context has not been fully filled in.
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID));
		AbilityTemplate = AbilityState.GetMyTemplate();
		SwitchToRobotEffect = X2Effect_SwitchToRobot_Reboot(AbilityTemplate.AbilityTargetEffects[0]);
	}

	if( SwitchToRobotEffect == none )
	{
		`RedScreenOnce("SwitchToRobot_BuildVisualization: Missing X2Effect_SwitchToRobot_Reboot -RustyDios @gameplay");
		RobotSpawn = X2Action_AndromedonRobotSpawn(class'X2Action_AndromedonRobotSpawn'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, true, none));
		RobotSpawn.AndromedonUnit = XGUnit(`XCOMHISTORY.GetVisualizer(DeadUnit.ObjectID) );
	}
	else
	{
		//SwitchToRobotEffect.AddSpawnVisualizationsToTracks(Context, SpawnedUnit, SpawnedUnitTrack, DeadUnit, DeadUnitTrack);
		//emptied that bit of code to here so it should always run ??
		RobotSpawn = X2Action_AndromedonRobotSpawn(class'X2Action_AndromedonRobotSpawn'.static.AddToVisualizationTree(SpawnedUnitTrack, Context, true, none));
		RobotSpawn.AndromedonUnit = XGUnit(`XCOMHISTORY.GetVisualizer(DeadUnit.ObjectID) );
	}
}

//mostly copied from original ability as all this visualisation stuff goes above my head
static function SwitchToRobot_VisualizationMerge(X2Action BuildTree, out X2Action VisualizationTree)
{
	local X2Action						DeathAction;		
	local X2Action						BuildTreeStartNode, BuildTreeEndNode;	
	local XComGameStateVisualizationMgr LocalVisualizationMgr;

	LocalVisualizationMgr = `XCOMVISUALIZATIONMGR;

	//changed from class'X2Action_AndromedonDeathAction', this decides 'where' the new robot is spawned in visually
	//set to the end of the previous action, creates a small 'extra' explosion, but that is liveable tbh
	DeathAction = LocalVisualizationMgr.GetNodeOfType(VisualizationTree, class'X2Action_RebootRobot', none, BuildTree.Metadata.StateObjectRef.ObjectID);

	BuildTreeStartNode = LocalVisualizationMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertBegin');	
	BuildTreeEndNode = LocalVisualizationMgr.GetNodeOfType(BuildTree, class'X2Action_MarkerTreeInsertEnd');

	if (BuildTreeStartNode != none && BuildTreeEndNode != none && DeathAction != none)
	{
		LocalVisualizationMgr.InsertSubtree(BuildTreeStartNode, BuildTreeEndNode, DeathAction);
	}
}

///////////////////////////////////////
//	Switch Again Reboot To New Team
// 	SO THIS IS THE SHELL HALF OF THE SWITCH, GIVEN TO THE 'NEW SHELL'
//////////////////////////////////////

static function X2AbilityTemplate CreateRebootAbility_Random()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'RobotReboot_Reboot');

	// Setup
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_andromedon_robotbattlesuit";
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	// This ability fires when the OLD Andromedon Shell dies
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'AndromedonToRobot_Reboot';
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	EventListener.ListenerData.Priority = 50;
	Template.AbilityTriggers.AddItem(EventListener);

	// Targets the Andromedon unit so it can be replaced by the andromedon robot;
	Template.AbilityTargetStyle = default.SelfTarget;

	// Add dead eye to guarantee the explosion occurs
	Template.AbilityToHitCalc = default.DeadEye;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = RobotReboot_BuildVisualization;
	Template.CinescriptCameraType = "Andromedon_RobotBattlesuit";

	return Template;
}

//mostly copied from original ability as all this visualisation stuff goes above my head
simulated function RobotReboot_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateContext_Ability	Context;
	local VisualizationActionMetadata	RobotUnitTrack;
	local XComGameState_Unit			RobotUnit;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	RobotUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID));
	//`assert(RobotUnit != none);	//Removed I hate CTD asserts

	// The Spawned unit should appear and play its change animation
	RobotUnitTrack.StateObject_OldState = `XCOMHISTORY.GetGameStateForObjectID(RobotUnit.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	RobotUnitTrack.StateObject_NewState = RobotUnit;
	RobotUnitTrack.VisualizeActor = `XCOMHISTORY.GetVisualizer(RobotUnit.ObjectID);

	class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTree(RobotUnitTrack, Context);
	//class'X2Action_RebootRobot'.static.AddToVisualizationTree(RobotUnitTrack, Context);
}

///////////////////////////
//	Statue Dead
//	THIS IS A NEW ABILITY GIVEN TO THE 'NEW SHELL' TO CAUSE IT TO TURN INTO A STATUE
////////////////////////////
static function X2DataTemplate CreateRebootCoverStatue()
{
	local X2AbilityTemplate 				Template;
	local X2Effect_GenerateCover 			CoverEffect;
	local X2Effect_Statue 					PillarEffect;
	local X2AbilityTrigger_EventListener 	EventListener;
	local X2AbilityMultiTarget_Radius		RadiusMultiTarget;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'RebootCoverStatue');

	//set up
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_andromedon_wallsmash"; //"img:///UILibrary_PerkIcons.UIPerk_shieldwall";
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	
	//targeting and triggers
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Template.TargetingMethod = class'X2TargetingMethod_TopDown';

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.fTargetRadius = 0.33; // small amount so it just grabs one tile
	RadiusMultiTarget.bIgnoreBlockingCover = true; // skip the cover checks, the squad viewer will handle this once selected
	RadiusMultiTarget.bAllowDeadMultiTargetUnits = true; //yes we dead so need this to target ourself!
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	//backup can trigger by player if logging is enabled
	/*if (class'X2Effect_SwitchToRobot_Reboot'.default.bEnableRandomAndromLog)
	{
		Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
		Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_AlwaysShow;
	}*/

	// This ability fires when the NEW Andromedon Shell dies outright
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'AndromedonToRobot_Statue';
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	EventListener.ListenerData.Priority = 42; //This ability must get triggered after the rest of the on-death listeners
	Template.AbilityTriggers.AddItem(EventListener);

	//effects
	//create and update cover, this lets units take cover against the shell
	CoverEffect = new class'X2Effect_GenerateCover';
	CoverEffect.BuildPersistentEffect(1, true, false, false, eGameRule_TacticalGameStart);
	CoverEffect.CoverType = CoverForce_High;	//CoverForce_Low;
	CoverEffect.bRemoveWhenMoved = false;
	CoverEffect.bRemoveOnOtherActivation = false;
	CoverEffect.bRemoveWhenSourceDies = false;
	CoverEffect.bRemoveWhenTargetDies = false;
	CoverEffect.bPersistThroughTacticalGameEnd = true;
	//CoverEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, default.bDisplayAsPassive);	//effect is always hidden
	Template.AddShooterEffect(CoverEffect);

	//create a permanent 'pillar', this fills the old units tile so it can't be walked into
	PillarEffect = new class'X2Effect_Statue'; //new class'X2Effect_Pillar' >> new class'X2Effect_SpawnDestructible';
	PillarEffect.BuildPersistentEffect(1, true, false, false, eGameRule_TacticalGameStart);
	PillarEffect.bDestroyOnRemoval = false;	
	PillarEffect.bRemoveWhenSourceDies = false;
	PillarEffect.bRemoveWhenTargetDies = false;
	PillarEffect.bPersistThroughTacticalGameEnd = true;
	PillarEffect.DestructibleArchetype = "FX_Templar_Pillar.Pillar_Destructible";
	Template.AddTargetEffect(PillarEffect);

	//visualization and stuff
	Template.bShowActivation = false;
	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = Statue_BuildVisualization;

	return Template;
}

//mostly copied from original ability as all this visualisation stuff goes above my head
function Statue_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateContext_Ability	Context;
	local XComGameState_Destructible DestructibleState;
	local XComGameState_Unit UnitState;
	local VisualizationActionMetadata BuildTrack, UnitTrack;

	TypicalAbility_BuildVisualization(VisualizeGameState);

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Destructible', DestructibleState)
	{
		break;
	}
	//`assert(DestructibleState != none);	//removed cause I hate CTD's when it fails

	BuildTrack.StateObject_NewState = DestructibleState;
	BuildTrack.StateObject_OldState = DestructibleState;
	BuildTrack.VisualizeActor = `XCOMHISTORY.GetVisualizer(DestructibleState.ObjectID);

	class'X2Action_ShowSpawnedDestructible'.static.AddToVisualizationTree(BuildTrack, Context);

	//necromancy ! ... bring back the dead unit actor that UnitRemovedFromPlay takes away ...
	UnitState = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID));
		//`assert(RobotUnit != none);	//Removed I hate CTD asserts
	UnitTrack.StateObject_OldState = `XCOMHISTORY.GetGameStateForObjectID(UnitState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	UnitTrack.StateObject_NewState = UnitState;
	UnitTrack.VisualizeActor = `XCOMHISTORY.GetVisualizer(UnitState.ObjectID);

	class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTree(UnitTrack, Context);
	//class'X2Action_RebootRobot'.static.AddToVisualizationTree(UnitTrack, Context);
}

///////////////////////////
//	Bulwark
//	THIS IS A CLONE OF THE SPARK BULWARK WITHOUT THE ARMOR BOOST
////////////////////////////
static function X2AbilityTemplate Create_AndromedonBulwark()
{
	local X2AbilityTemplate						Template;
	local X2Effect_GenerateCover                CoverEffect;
	//local X2Effect_BonusArmor		            ArmorEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'AndromedonBulwark');
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_shieldwall"; //"img:///UILibrary_DLC3Images.UIPerk_spark_bulwark";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	CoverEffect = new class'X2Effect_GenerateCover';
	CoverEffect.CoverType = CoverForce_High;
	CoverEffect.bRemoveWhenMoved = false;
	CoverEffect.bRemoveWhenSourceDies = true;
	CoverEffect.bRemoveWhenTargetDies = true;
	CoverEffect.bRemoveOnOtherActivation = false;
	CoverEffect.BuildPersistentEffect(1, true, false, false, eGameRule_PlayerTurnBegin);
	CoverEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddTargetEffect(CoverEffect);

	//ArmorEffect = new class'X2Effect_BonusArmor';
	//ArmorEffect.BuildPersistentEffect(1, true, false, false);
	//ArmorEffect.ArmorMitigationAmount = default.BULWARK_ARMOR;
	//Template.AddTargetEffect(ArmorEffect);

	Template.bSkipFireAction = true;
	Template.bShowActivation = false;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	//Template.SetUIStatMarkup(class'XLocalizedData'.default.ArmorLabel, eStat_ArmorMitigation, ArmorEffect.ArmorMitigationAmount);

	return Template;
}

///////////////////////////
//	Shutdown Statue Dead
//	THIS IS A SUICIDE SKILL TO FIX A 'BUG'
//	THIS IS A NEW ABILITY GIVEN TO THE 'NEW SHELL' TO CAUSE IT TO TURN INTO A STATUE
////////////////////////////
static function X2AbilityTemplate Create_AndromedonEvacDeath()
{
	local X2AbilityTemplate				Template;
	local X2AbilityCost_ActionPoints	ActionPointCost;

	//local X2Condition_UnitValue 		UnitValue;

	//local X2Effect_KillUnit 			KillEffect;
	local X2Effect_SwitchToRobot_Reboot	SwitchToRobotEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'AndromedonEvacDeath');
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);	//no evac in MP!

    //setup 
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_andromedon_robotbattlesuit";
	Template.AbilitySourceName = 'eAbilitySource_Debuff';
	Template.Hostility = eHostility_Neutral;
	Template.ConcealmentRule = eConceal_Always;
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_AlwaysShow;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	//free cost but requires at least 1AP, ends turn
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	ActionPointCost.bFreeCost = false;
	Template.AbilityCosts.AddItem(ActionPointCost);

	// Kill the unit Effect
	// The target will now be turned into a cloned robot
	SwitchToRobotEffect = new class'X2Effect_SwitchToRobot_Reboot';
	SwitchToRobotEffect.BuildPersistentEffect(1);
	SwitchToRobotEffect.bForceDead = true;
	Template.AddTargetEffect(SwitchToRobotEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = SwitchToRobot_BuildVisualization;
	Template.MergeVisualizationFn = SwitchToRobot_VisualizationMerge;

	Template.bDontDisplayInAbilitySummary = true;

	Template.bSkipFireAction = false;
	Template.bShowActivation = false;

	Template.bSkipExitCoverWhenFiring = true;

	return Template;
}
