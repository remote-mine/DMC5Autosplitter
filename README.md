# DMC5Autosplitter

[LiveSplit](http://livesplit.github.io/) Autosplitter for Devil May Cry 5

## Features

- Automatically pause timer during loading screens (Game Time timing method)
- Automatically split post-mission during the glass crack

## TO-DO
- Automatically start the timer when selecting Mission Start on Prologue or Mission 01
- Improve detection of Mission 20 autosplit

## Livesplit Configuration

- Download [dmc5.asl](dmc5.asl)
- Right-click Livesplit -> Edit Layout...
- Add Control -> Scriptable Auto Splitter
- Set `Script Path` to downloaded asl
- Enable or disable `Split` feature
- For loadless, add/configure Timer to use `Timing Method: Game Time`

## Known Issues
- Beginning of Mission 02 is treated as loading until the HUD is displayed

## Contact

Please open an issue on Github if there are any problems!