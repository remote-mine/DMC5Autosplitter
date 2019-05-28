# DMC5Autosplitter

[LiveSplit](http://livesplit.github.io/) Autosplitter for Devil May Cry 5

## Features

- Automatically start the timer when selecting Mission Start on Prologue or Mission 01
- Automatically pause timer during loading screens (Game Time timing method)
- Automatically split post-mission during the glass crack
- Automatically split on defeating Mission 20 boss

## Livesplit Configuration

- Download [dmc5.asl](dmc5.asl)
- Right-click Livesplit -> Edit Layout...
- Add Control -> Scriptable Auto Splitter
- Set `Script Path` to downloaded asl
- Enable or disable `Split` feature
- For loadless, add/configure Timer to use `Timing Method: Game Time`

Example Livesplit Layout: [dmc5_ll_splits.lsl](dmc5_ll_splits.lsl)

## TO-DO

- Automatically split for sealed fights
- Detect loading for in-mission cutscenes

## Known Issues

- Inconsistent auto-start behavior
- Checkpoint/Retry/Quit Mission loading timer pause is delayed

## Contact

Please open an issue on Github if there are any problems!
