/*
    Devil May Cry 5 Autosplitter and Loadless Timer
    Version: 0.2
    Author: remote_mine
    Compatible Versions: Steam

    Thanks to Tektheist for ideas and help with testing!
*/

state("DevilMayCry5", "1.07")
{
    byte missionNumber : 0x07A9A2E0, 0x88;
    byte gameState : 0x07B53A58, 0x8;

    int playerLoaded : 0x07A6E5C8, 0x140, 0x1F8, 0x200, 0x80, 0x20;

    int finalBossPointer : 0x07A72E58, 0x140, 0x250, 0x28, 0x88;
    float finalBossHP : 0x07A72E58, 0x140, 0x250, 0x28, 0x88, 0x10;
}

startup
{
    vars.isLoading = false;
    vars.gameWasPaused = false;
}

init
{
    var module = modules.First();
    switch (module.ModuleMemorySize)
    {
        case 502349824:
            version = "1.07";
            break;
    }

    if (version != "1.07")
    {
        MessageBox.Show(timer.Form,
            "Warning: Could not determine DMC5 version.\nOnly Steam version 1.07 is currently supported",
            "LiveSplit: Unknown Game Version",
            MessageBoxButtons.OK,
            MessageBoxIcon.Warning);
    }
}

update
{
    /*
        gameState is 0 for most loading (plus a few edge cases)
        gameState is 9 for pause menu screen

        This fixes in-mission intro "loading" (gameState is 0 until HUD shows)
        Special case to check for pause menu during pre-HUD "loading"
    */
    if (current.gameState != old.gameState)
    {
        vars.gameWasPaused = old.gameState == 9;
        vars.isLoading = (current.gameState == 0 && !vars.gameWasPaused);
    }

    if (current.playerLoaded != old.playerLoaded)
    {
        if (current.playerLoaded > 0)
        {
            vars.isLoading = false;
        }
        else if (current.gameState == 0 && vars.gameWasPaused)
        {
            // load screen after pausing (checkpoint/retry/quit mission)
            vars.isLoading = true;
        }
    }
}

start
{
    if (current.missionNumber == 0 || current.missionNumber == 1)
    {
        return current.playerLoaded != old.playerLoaded && current.playerLoaded > 0;
    }
}

split
{
    if (current.missionNumber == 20 && current.finalBossPointer > 0 && old.finalBossHP > 0)
    {
        return current.finalBossHP == 0;
    }

    if (current.missionNumber != old.missionNumber)
    {
        return current.missionNumber == old.missionNumber + 1;
    }
}

isLoading
{
    return vars.isLoading;
}
