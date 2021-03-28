//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_WOTC_RandomAndromReboot.uc                                    
//
//	CREATED BY RustyDios
//           
//	File created	24/12/20	20:30
//	LAST UPDATED    21/03/21	13:30
//  
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_WOTC_RandomAndromReboot extends X2DownloadableContentInfo config (RustyRandomReboot);

var config array<name> AndroTemplates, RobotTemplates;
var config bool bAndromedonShellGetsBulwarkToo;

static event OnLoadedSavedGame(){}

static event InstallNewCampaign(XComGameState StartState){}

//************************
//	OPTC Code
//************************

static event OnPostTemplatesCreated()
{
	AddRandomRebootToRobots();
	AddAndromedonBulwark();
}

static function AddRandomRebootToRobots()
{
	local X2CharacterTemplate			Template;
	local X2CharacterTemplateManager	AllCharacters;

	local int r;

	//KAREN !! list of all character templates
	AllCharacters = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	//for each item on the list
	for (r = 0; r <= default.RobotTemplates.Length ; ++r )
	{
		//find the template
		Template = AllCharacters.FindCharacterTemplate(default.RobotTemplates[r]);

		//ensure the template exists
		if (Template != none)
		{
			//add the abilities
			Template.Abilities.AddItem('SwitchToRobot_Reboot');
			Template.Abilities.AddItem('RobotReboot_Reboot');
			Template.Abilities.AddItem('RebootCoverStatue');
			Template.Abilities.AddItem('AndromedonEvacDeath');

			//output patch to log
			`LOG("Template Patched With Random Reboot :: " @Template.DataName , class'X2Effect_SwitchToRobot_Reboot'.default.bEnableRandomAndromLog,'RandomAndromedonReboot');
		}

	}//end for loop
}

static function AddAndromedonBulwark()
{
	local X2CharacterTemplate			Template;
	local X2CharacterTemplateManager	AllCharacters;

	local int a, r;

	//KAREN !! list of all character templates
	AllCharacters = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	//for each item on the list
	for (a = 0; a <= default.AndroTemplates.Length ; ++a )
	{
		//find the template
		Template = AllCharacters.FindCharacterTemplate(default.AndroTemplates[a]);

		//ensure the template exists
		if (Template != none )
		{
			//add the abilities
			Template.Abilities.AddItem('AndromedonBulwark');

			//output patch to log
			`LOG("Template Patched With Andromedon Bulwark :: " @Template.DataName , class'X2Effect_SwitchToRobot_Reboot'.default.bEnableRandomAndromLog,'RandomAndromedonReboot');
		}

	}//end for loop

	if (default.bAndromedonShellGetsBulwarkToo)
	{
		//for each item on the list
		for (r = 0; r <= default.RobotTemplates.Length ; ++r )
		{
			//find the template
			Template = AllCharacters.FindCharacterTemplate(default.RobotTemplates[r]);

			//ensure the template exists
			if (Template != none )
			{
				//add the abilities
				Template.Abilities.AddItem('AndromedonBulwark');

				//output patch to log
				`LOG("Template Patched With Andromedon Bulwark :: " @Template.DataName , class'X2Effect_SwitchToRobot_Reboot'.default.bEnableRandomAndromLog,'RandomAndromedonReboot');
			}

		}//end for loop
	}
}
