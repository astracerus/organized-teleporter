# Organized Teleporter
This is a system built for ATM9 to organize all of your teleportation locations

## Setup
1. Create a teleport scroll. To do this, take an archmage's spellbook from Ars, and create a spell with form of touch and effect of blink. Then take a some spell parchment and apply that spell to it using a scribe's table. 
2. Create your teleport pad. A valid teleport pad consists of teleport rune (use the scroll from step 1 on an ars nouveau rune), an adjacent inventory, and a wired modem adjacent to that inventory. You will also need a source jar as well as a source generation setup to regenerate source, as each teleport uses up 1% of a source jar.
3. Create your source inventory. A valid source inventory consists of what Minecraft considers an inventory -> for example, occultism mass storage and sophisticated storage will work, but AE2 and RS will not, at least out of the box. This code is MIT licensed, so feel free to fork it. It also requires an adjacent wired modem.
4. Setup your computer. It requires an advanced monitor and nbtStorage from advance peripherals to be at least connected to the wired network if not adjacent. This computer will need to be accessible, as the shell for the program has functionality the UI doesn't. 
5. Connect all of the elements of your network, and make sure to activate every wired modem. Note down the peripheral names of the source inventory, and the teleport pad inventory. 
6. Download the main lua file. If you have the HTTP API enabled in your server's CC:Tweaked settings, you can use ```pastebin put startup.lua ctysPxVz```. Otherwise, use the import program. This is done by dragging the main.lua file onto
the terminal. After that, use the ```move main.lua startup.lua``` to leave it in the appropriate place.
7. Edit the config section of the file so that the program knows which inventory is the source inventory and which is the teleporter inventory. It's under the comment ```--Config```. 
8. Restart the computer, or manually run the startup script.
9. Get ars nouveau stabilized warp scrolls with destinations, and rename them in an anvil. Note that all strings are trimmed, so don't add spaces before any actual characters or after all of the actual characters. Spaces in between are fine. Then put them all into the source inventory.
10. Finally go to the shell, and use the command refresh_locations
11. You should be good to go to start using the system


## Shell Primer
The shell is a little bit unusual, owing to how it handles spaces and tab completion. It works by entering a command, and then prompting you for the fields necessary to complete that command. For example, tagging a location currently works like this

```
(teleport)> tag_location
------------------------------------------
(tag to add location to)> Ad Astra
(location to tag)> Venus
Location Venus added to tag Ad Astra
-----------------------------------------
```
The shell will automatically trim whitespace off of the ends of all inputs.  Tab completion should be present for most commands, but will be case sensitive. The actual inputs should ignore case whenever possible. 
