/*
    Devil May Cry 5 Autosplitter and Loadless Timer
    Version: 0.5a
    Author: remote_mine
    Compatible Versions: Steam

    Thanks to Tektheist for ideas and help with testing!
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

state("DevilMayCry5", "1.10") // vergil dlc
{
    byte missionNum   : 0x07E5B2E8, 0x98;
    byte gameState    : 0x07F3DDB8, 0x8; // DevilMayCry5.exe+27B5D82
    long playerPtr    : 0x07E625D0;
    float playerHP    : 0x07E625D0, 0x7C;
    long finalBossPtr : 0x07E55C28, 0x148, 0x250, 0x18, 0x88; // DevilMayCry5.exe+1259E65
    float finalBossHP : 0x07E55C28, 0x148, 0x250, 0x18, 0x88, 0x10; // DevilMayCry5.exe+1259E65
    long danteBossPtr : 0x07E55C28, 0x148, 0x300, 0x20, 0x88;
    float danteBossHP : 0x07E55C28, 0x148, 0x300, 0x20, 0x88, 0x10;
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
        case 135524352:
            version = "1.09";
            break;
        case 139784192:
            version = "1.10";
            break;
        default:
            vars.DebugOutput("unknown version, module size " + module.ModuleMemorySize.ToString());
            break;
    }

    if (version != "1.08" && version != "1.09" && version != "1.10")
    {
        MessageBox.Show(timer.Form,
            "Warning: Could not determine DMC5 version.\nOnly Steam version 1.08, 1.09 and 1.10 is currently supported",
            "LiveSplit: Unknown Game Version",
            MessageBoxButtons.OK,
            MessageBoxIcon.Warning);
    }
}

/*
    gameState (generally correct, does not cover all cases)
    0  = loading
    2  = vergil weapon swap (increments gameState by 2 then decrements 2 when weapon HUD fades)
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
        vars.gameWasPaused = old.gameState == 9 || old.gameState == 2;
        /*
            fix unpause during mission start "loading" (until HUD displays)
            gameState seq: 0 ("loading") -> 9 (pause) -> 0 ("loading")
            fix vergil weapon swap during "loading" (until full HUD displays)

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
    if (current.missionNum == 20)
    {
        // vergil m20 has a different boss pointer
        if (version == "1.10" && current.danteBossPtr > 0 && old.danteBossHP > 0)
        {
            return current.danteBossHP == 0;
        }

        // nero m20 boss
        if (current.finalBossPtr > 0 && old.finalBossHP > 0)
        {
            return current.finalBossHP == 0;
        }
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
