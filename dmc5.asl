/*
    Devil May Cry 5 Autosplitter and Loadless Timer
    Version: 0.4a
    Author: remote_mine
    Compatible Versions: Steam

    Thanks to Tektheist for ideas and help with testing!
*/

state("DevilMayCry5", "1.08")
{
    byte missionNum   : 0x07A9B7D8, 0x88;
    byte gameState    : 0x07B54F38, 0x8;
    int playerPtr     : 0x07A72B08, 0x18;
    float playerHP    : 0x07A72B08, 0x18, 0x7C;
    int finalBossPtr  : 0x07A74330, 0x140, 0x250, 0x28, 0x88;
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
        default:
            vars.DebugOutput("unknown version, module size " + module.ModuleMemorySize.ToString());
            break;
    }

    if (version != "1.08")
    {
        MessageBox.Show(timer.Form,
            "Warning: Could not determine DMC5 version.\nOnly Steam version 1.08 is currently supported",
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
    31 = customization
*/
update
{
    vars.playerLoadedOld = vars.playerLoadedCurrent;
    vars.playerLoadedCurrent = current.playerPtr > 0 && current.playerHP != -1000;

    if (current.gameState != old.gameState)
    {
        vars.gameWasPaused = old.gameState == 9;
        /*
            fix unpause during mission start "loading" (until HUD displays)
            gameState seq: 0 ("loading") -> 9 (pause) -> 0 ("loading")

            fix M07/M13 character select load screen not pausing timer
        */
        vars.isLoading = current.gameState == 0 && (!vars.gameWasPaused || !vars.playerLoadedCurrent);
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
