You created an XCOM 2 Mod Project!

===================================================================================
STEAM DESC      https://steamcommunity.com/sharedfiles/filedetails/?id=2350811065
===================================================================================
[h1]What is this?[/h1]

This mod was a fun little idea. When you kill an Andromedon style unit and it reboots into the robot form, it has a chance to be on a different team.

[h1]Whoa .. How?[/h1]
Well nicely enough, the base game switch includes an event that I hook into. The original switch spawns a new unit [i]hard set[/i] to the ADVENT team.
I basically hook into that and repeat it but for a [i]random result/team[/i].

[h1]Configs[/h1]
Options are in the [b]XComRustyRandomReboot.ini[/b]
You can decide if an XCOM Andromedon is forced into an XCOM Robot. Default ON.

You can decide the percentage chance for the team to spawn on, including 'team dead'.
The default is setup for:[list]
[*]25% Dead Outright, no Robot phase, turns into a high-cover statue
[*]25% Normal behaviour, ie Robot on ADVENT team
[*]10% Each of the other teams, XCOM, LOST, CIVS, FACTION1 and FACTION2
[/list]

Yes, this means you could have andromedon shells working for lost, 'hive', 'raiders', 'scp' or the resistance!!

I also have an option for andromedons and shells to get a mini-bulwark that provides cover but no no additional armour. This just seems logical to me. Default ON.

[h1]Compatibility/Known Issues[/h1][olist]
[*]Should work with any Andromedon Unit including [url=https://steamcommunity.com/sharedfiles/filedetails/?id=1126623381] ABA:WOTC Primes [/url] and [url=https://steamcommunity.com/sharedfiles/filedetails/?id=1968720910] AHW:Advanced Dreadnaughts [/url]
Will also work for [i]any[/i] unit that calls the 'AndromedonToRobot' event if they are added to the config. TBH I don't know of any more other than base game and the two mods mentioned above.
Should have no issues with RPGO, CI, LWotC or Playable Aliens.
[*]There is a minor [b]visual glitch[/b] as the unit swaps out. I did my best to minimise it, but the visualizer/action system is a bit past my knowledge scope. I was happy to get it working as well as it is.
[*]There is a minor [b]visual glitch[/b] if an Andromedon becomes a 'statue' on a 2nd floor or higher building and you destroy the floor, they remain floating.
[*]Might have issues if an Andromedon becomes a 'dead statue' on a tile that you need to have access to (for example to set X4 or hack an objective), upto you to plan ahead.
[*]The reboot roll is done at random and will change if [i]savescumming[/i]. Upto you if this is an issue.
[/olist]

[h1]Credits and Thanks[/h1]
Many thanks to [b]AngelOfIron[/b] on the discord for the idea
Many thanks to [b]Iridar[/b], [b]MrNiceUK[/b] and [b]Xymanek/Astral Descend[/b] in particular for helping me to understand enough of the visual system to make this work.
Really wouldn't be able to do my mods without all the help and support of the XCOM2 Modders discord!

~ Enjoy [b]!![/b] and please [url=https://www.buymeacoffee.com/RustyDios] buy me a Cuppa Tea[/url]

===========================================================

andro ability;	SwitchToRobot	calls;
EventManager.TriggerEvent('AndromedonToRobot', RobotGameState, RobotGameState, NewGameState);

(also the robot has RobotReboot)

original idea:
make andro robots spawn in different ways.. on different teams... 
roll 100 ... <10 = change team to xcom, 11-75 'do nothing/kill unit', >75 = reboot to advent/normal behaviour

from AngelOfIron on discord

ABA Primes and AHW Dreadnaughts call the same event hook I use "AndromedonToRobot" :)
