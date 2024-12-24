# Organized Teleporter
This is a system built for ATM9 to organize all of your teleportation locations

## Setup
1. Create a teleport scroll. To do this, take an archmage's spellbook from Ars, and create a spell with form of touch and effect of blink. Then take a some spell parchment and apply that spell to it using a scribe's table. 
2. Create your teleport pad. A valid teleport pad consists of teleport rune (use the scroll from step 1 on an ars nouveau rune), an adjacent inventory, and a wired modem adjacent to that inventory. You will also need a source jar as well as a source generation setup, as each teleport uses up 1% of a source jar.
3. Create your source inventory. A valid source inventory consists of an Refined Storage setup containing ONLY stabilized warps scrolls that can actively be used as a destination (see step 9 on how to name destinations).You will then need to add RS bridge from Advanced Peripherals, and add it  to the controller. Place a wired modem on the RS bridge.
4. Setup your computer. It requires an advanced monitor (default setup is 4 wide by 3 tall) and nbtStorage from advance peripherals to be at least connected to the wired network if not adjacent. This computer will need to be accessible, as the shell for the program has functionality the UI doesn't. Make sure it has a wired modem attached.
5. Connect all of the wired modems via networking wire, and activate each modem. Note down the peripheral name teleport pad inventory. 
6. Download the main lua file. Use the import program. This is done by dragging the main.lua file onto the terminal. After that, use the ```move main.lua startup.lua``` to leave it in the appropriate place.
7. Edit the config section of the file so that the program knows the name of the teleporter inventory. It's under the comment ```--Config```. 
8. Restart the computer, or manually run the startup script.
9. Get ars nouveau stabilized warp scrolls with destinations, and rename them in an anvil to what you want the scroll's location to correspond to. Note that all strings are trimmed, so don't add spaces before any actual characters or after all of the actual characters. Spaces in between are fine. Then put them all into the source RS system.
10. Finally go to the shell, and use the command ```refresh_locations```
11. You should be good to go to start using the system


## Shell Primer
The shell is a little bit unusual, owing to how it handles spaces and tab completion. It works by entering a command, and then prompting you for the fields necessary to complete that command. For example, tagging a location currently works like this

```
(teleport)> tag_location
-----------------------------------------
(tag to add location to)> Ad Astra
(location to tag)> Venus
Location Venus added to tag Ad Astra
-----------------------------------------
```
The shell will automatically trim whitespace off of the ends of all inputs.  Tab completion should be present for most commands, but will be case sensitive. The actual inputs should ignore case whenever possible. 

## Pitfalls/Known Bugs
1. Occasionally, it will be impossible to set a specific destination. If you run ```set_destination``` in the shell, it will error with the reason NO_VALID_FINGERPRINT. For some as yet unknown reason, ```refresh_locations``` fixes it. Cause unknown.
2. Once during testing, the monitor decided to fritz out. Only after breaking and replacing the monitor, as well as running a command, fixed it. Cause unknown. 
