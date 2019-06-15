/*
    Devil May Cry 5 Autosplitter and Loadless Timer
    Version: 0.5a
    Author: remote_mine
    Compatible Versions: Steam

    Thanks to Tektheist for ideas and help with testing!
*/

state("DevilMayCry5") {}

startup
{
    // Log Output switch for DebugView (enables/disables debug messages)
    bool DebugEnabled = true;
    Action<string> DebugOutput = (text) => {
        if (DebugEnabled)
        {
            print("LiveSplit Debug [DMC5 ASL] " + text);
        }
    };
    vars.DebugOutput = DebugOutput;

    vars.scanMissionNum = new SigScanTarget(360, "A8 60 49 F1 F8 CA 29 90 38 79 EE 0B C1 C1 B2 D3");
    vars.scanGameState  = new SigScanTarget(-84, "00 FF FF FF 88 BF 4D 44 01 00 00 00 C8 BF 4D 44");
    vars.scanPlayer     = new SigScanTarget(6, "80 3F 26 83 93 78 ?? ?? ?? ?? 00 00 00 00 60 AC");
    vars.scanFinalBoss  = new SigScanTarget(8, "60 F4 ?? 27 00 00 00 00 ?? ?? ?? ?? 00 00 00 00 30 B0");

    vars.isLoading = false;
    vars.gameWasPaused = false;
    vars.playerLoadedCurrent = false;
    vars.playerLoadedOld = false;
}

init
{
    var module = modules.First();
    var scanner = new SignatureScanner(game, module.BaseAddress, module.ModuleMemorySize);

    IntPtr missionNumBase = scanner.Scan(vars.scanMissionNum);
    IntPtr gameStateBase  = scanner.Scan(vars.scanGameState);
    IntPtr playerBase     = scanner.Scan(vars.scanPlayer);
    IntPtr finalBossBase  = scanner.Scan(vars.scanFinalBoss);

    vars.DebugOutput("missionNum base: " + missionNumBase.ToString("X"));
    vars.DebugOutput("gameState base: " + gameStateBase.ToString("X"));
    vars.DebugOutput("player base: " + playerBase.ToString("X"));
    vars.DebugOutput("finalBoss base: " + finalBossBase.ToString("X"));

    if (missionNumBase == IntPtr.Zero || gameStateBase == IntPtr.Zero
      || playerBase == IntPtr.Zero || finalBossBase == IntPtr.Zero)
    {
        vars.DebugOutput("Sigscan did not find all addresses - game not fully loaded or unsupported version");
        // ugly solution to wait and retry
        Thread.Sleep(2000);
        throw new Exception();
    }

    Func<IntPtr, int[], DeepPointer> GetDeepPointer = (IntPtr basePtr, int[] offsets) => 
    {
        return new DeepPointer((int)((long)basePtr - (long)module.BaseAddress), offsets);
    };

    vars.missionNum   = new MemoryWatcher<int>(GetDeepPointer(missionNumBase, new[]{0x88}));
    vars.gameState    = new MemoryWatcher<int>(GetDeepPointer(gameStateBase, new[]{0x8}));
    vars.playerPtr    = new MemoryWatcher<int>(GetDeepPointer(playerBase, new[]{0x18}));
    vars.playerHP     = new MemoryWatcher<float>(GetDeepPointer(playerBase, new[]{0x18, 0x7C}));
    vars.finalBossPtr = new MemoryWatcher<int>(GetDeepPointer(finalBossBase, new[]{0x140, 0x250, 0x28, 0x88}));
    vars.finalBossHP  = new MemoryWatcher<float>(GetDeepPointer(finalBossBase, new[]{0x140, 0x250, 0x28, 0x88, 0x10}));

    vars.watchers = new MemoryWatcherList() {
        vars.missionNum,
        vars.gameState,
        vars.playerPtr,
        vars.playerHP,
        vars.finalBossPtr,
        vars.finalBossHP
    };
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
    vars.watchers.UpdateAll(game);

    // if (vars.missionNum.Current != vars.missionNum.Old)
        // vars.DebugOutput("missionNum: " + vars.missionNum.Current);

    // if (vars.gameState.Current != vars.gameState.Old)
        // vars.DebugOutput("gameState: " + vars.gameState.Current);

    // if (vars.playerPtr.Current != vars.playerPtr.Old || vars.playerHP.Current != vars.playerHP.Old)
        // vars.DebugOutput("playerPtr: " + vars.playerPtr.Current.ToString("X") + ", playerHP: " + vars.playerHP.Current);

    // if (vars.finalBossPtr.Current != vars.finalBossPtr.Old || vars.finalBossHP.Current != vars.finalBossHP.Old)
        // vars.DebugOutput("finalBossPtr: " + vars.finalBossPtr.Current.ToString("X") + ", finalBossHP: " + vars.finalBossHP.Current);

    vars.playerLoadedOld = vars.playerLoadedCurrent;
    vars.playerLoadedCurrent = vars.playerPtr.Current > 0 && vars.playerHP.Current != -1000;

    if (vars.gameState.Current != vars.gameState.Old)
    {
        vars.gameWasPaused = vars.gameState.Old == 9;
        /*
            fix unpause during mission start "loading" (until HUD displays)
            gameState seq: 0 ("loading") -> 9 (pause) -> 0 ("loading")

            fix M07/M13 character select load screen not pausing timer
        */
        vars.isLoading = vars.gameState.Current == 0 && (!vars.gameWasPaused || !vars.playerLoadedCurrent);
    }

    if (vars.playerLoadedCurrent != vars.playerLoadedOld)
    {
        // ignore M06 as player data is loaded early
        if (vars.playerLoadedCurrent && vars.missionNum.Current != 6)
        {
            vars.isLoading = false;
        }
        else if (vars.gameState.Current == 0 && vars.gameWasPaused)
        {
            // real loading after pausing (checkpoint/retry/quit mission)
            vars.isLoading = true;
        }
    }
}

start
{
    if (vars.missionNum.Current == 0 || vars.missionNum.Current == 1)
    {
        return vars.playerLoadedCurrent != vars.playerLoadedOld && vars.playerLoadedCurrent;
    }
}

split
{
    if (vars.missionNum.Current == 20 && vars.finalBossPtr.Current > 0 && vars.finalBossHP.Old > 0)
    {
        return vars.finalBossHP.Current == 0;
    }

    if (vars.missionNum.Current != vars.missionNum.Old)
    {
        return vars.missionNum.Current == vars.missionNum.Old + 1;
    }
}

isLoading
{
    return vars.isLoading;
}
