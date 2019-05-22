state("DevilMayCry5", "1.07")
{
    byte missionNumber : 0x07A9A2E0, 0x88;
    byte isLoading : 0x07B53A58, 0x8; // 0 for loading. some cutscenes, black screens and pre-mission stuff have a zero value as well
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
            "Error: only supported version of DMC5 is 1.07",
            "Warning",
            MessageBoxButtons.OK,
            MessageBoxIcon.Warning);
    }
}

split
{
    return current.missionNumber == old.missionNumber + 1;
}

isLoading
{
    return current.isLoading == 0;
}
