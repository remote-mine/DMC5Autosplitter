/*
    Devil May Cry 5 Autosplitter and Loadless Timer
    Version: 0.5b
    Author: remote_mine
    Compatible Versions: Steam

    Thanks to Tektheist and Cosmic for ideas and help with testing!
*/

state("DevilMayCry5", "1.08")
{
    byte missionNum   : 0x07A9B7D8, 0x88;
    byte gameState    : 0x07B54F38, 0x8;
    long playerPtr    : 0x07A72B08, 0x18;
    float playerHP    : 0x07A72B08, 0x18, 0x7C;
    long finalBossPtr : 0x07A74330, 0x140, 0x250, 0x28, 0x88;
    float finalBossHP : 0x07A74330, 0x140, 0x250, 0x28, 0x88, 0x10;
}

state("DevilMayCry5", "1.09") // denuvoless
{
    byte missionNum   : 0x07A9B7D8, 0x88;
    byte gameState    : 0x07B54F38, 0x8;
    long playerPtr    : 0x07A6FAA8, 0x140, 0x1F8, 0x218, 0x40, 0x20;
    float playerHP    : 0x07A6FAA8, 0x140, 0x1F8, 0x218, 0x40, 0x20, 0x18;
    long finalBossPtr : 0x07A74330, 0x140, 0x250, 0x28, 0x88;
    float finalBossHP : 0x07A74330, 0x140, 0x250, 0x28, 0x88, 0x10;
}

startup
{
    // Log Output switch for DebugView (enables/disables debug messages)
    bool DebugEnabled = true;
    Action<string> DebugOutput = (text) => {
        if (DebugEnabled)
        {
            print("LiveSplit Debug " + text);
        }
    };
    vars.DebugOutput = DebugOutput;

    vars.isLoading = false;
    vars.gameWasPaused = false;
    vars.inMissionPauseMenu = false;
    vars.playerLoadedCurrent = false;
    vars.playerLoadedOld = false;
}

init
{
    var module = modules.First();
    switch (module.ModuleMemorySize)
    {
        case 502349824:
            version = "1.07";
            break;
        case 501411840:
            version = "1.08";
            break;
        case 135524352:
            version = "1.09";
            break;
        default:
            vars.DebugOutput("unknown version, module size " + module.ModuleMemorySize.ToString());
            break;
    }

    if (version != "1.08" && version != "1.09")
    {
        MessageBox.Show(timer.Form,
            "Warning: Could not determine DMC5 version.\nOnly Steam version 1.08 or 1.09 is currently supported",
            "LiveSplit: Unknown Game Version",
            MessageBoxButtons.OK,
            MessageBoxIcon.Warning);
    }
}

/*
    gameState (generally correct, does not cover all cases)
    0  = loading
    9  = pause menu screen + character select confirmation
    13 = during character select (M07 and M13)
    24 = when displaying date in cutscene before mission
    27 = customization (v)
    31 = customization (nero)

    in-mission pause menu values
    15 = pause menu - skill list
    20 = pause menu - tutorial
    33 = pause menu - language
    35 = pause menu - controls keyboard/mouse
    39 = pause menu - sound
    40 = pause menu - pc options
    45 = pause menu - controls (v)
    46 = pause menu - controls (nero)
    49 = pause menu - controls (dante)
    50 = pause menu - game options
*/
update
{
    vars.playerLoadedOld = vars.playerLoadedCurrent;
    vars.playerLoadedCurrent = current.playerPtr > 0 && current.playerHP != -1000;

    if (current.gameState != old.gameState)
    {
        // player pausing (gameState 9) is also loadless but only when in-mission
        vars.inMissionPauseMenu = vars.playerLoadedCurrent &&
            (
                current.gameState == 9  ||
                current.gameState == 15 ||
                current.gameState == 20 ||
                current.gameState == 33 ||
                current.gameState == 35 ||
                current.gameState == 39 ||
                current.gameState == 40 ||
                current.gameState == 45 ||
                current.gameState == 46 ||
                current.gameState == 49 ||
                current.gameState == 50
            );

        vars.gameWasPaused = old.gameState == 9;
        /*
            fix unpause during mission start "loading" (until HUD displays)
            gameState seq: 0 ("loading") -> 9 (pause) -> 0 ("loading")

            fix M07/M13 character select load screen not pausing timer
        */

        vars.isLoading = current.gameState == 0 && (!vars.gameWasPaused || !vars.playerLoadedCurrent) || vars.inMissionPauseMenu;
    }

    if (vars.playerLoadedCurrent != vars.playerLoadedOld)
    {
        // ignore M06 as player data is loaded early
        if (vars.playerLoadedCurrent && current.missionNum != 6)
        {
            vars.isLoading = false;
        }
        else if (current.gameState == 0 && vars.gameWasPaused)
        {
            // real loading after pausing (checkpoint/retry/quit mission)
            vars.isLoading = true;
        }
    }
}

start
{
    if (current.missionNum == 0 || current.missionNum == 1)
    {
        return vars.playerLoadedCurrent != vars.playerLoadedOld && vars.playerLoadedCurrent;
    }
}

split
{
    if (current.missionNum == 20 && current.finalBossPtr > 0 && old.finalBossHP > 0)
    {
        return current.finalBossHP == 0;
    }

    if (current.missionNum != old.missionNum)
    {
        return current.missionNum == old.missionNum + 1;
    }
}

isLoading
{
    return vars.isLoading;
}
