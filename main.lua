--[[
MIT License

Copyright (c) 2024 astracerus

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

--Config 
TP_INVENTORY_NAME = "ars_nouveau:repository_0"
teleporter_inventory = peripheral.wrap(TP_INVENTORY_NAME)
source = peripheral.find('rsBridge')
SHELL_NAME="teleport"

--Globals
monitor = peripheral.find("monitor")
storage = peripheral.find("nbtStorage")
completion = require "cc.completion"

-- monitor globals
VIEWING_LOCATIONS = true
VIEWING_TAGS = false
viewing_current = VIEWING_LOCATIONS
ENTRIES_PER_SCREEN = 8
curr_display_pagination_idx = 1

buttons = {} 

--COMMAND LIST
CMD_LIST = "list_locations"
CMD_REFRESH = "refresh_locations"
CMD_TAG_LIST = "tag_list"
CMD_CREATE_TAG = "tag_create"
CMD_DELETE_TAG = "tag_delete"
CMD_TAG_LOC = "tag_location"
CMD_UNTAG_LOC = "untag_location"
CMD_CURR_DEST = "current_destination"
CMD_CURR_TAG = "current_tag"
CMD_SET_DEST = "set_destination"
CMD_CLEAR_DEST = "clear_destination"
CMD_SET_CURR_TAG = "set_curr_tag"
CMD_TEST = "test_input"
CMD_HELP = "help"


COMMANDS = {CMD_HELP, CMD_LIST, CMD_TEST, CMD_TAG_LIST, CMD_CREATE_TAG, CMD_DELETE_TAG, CMD_REFRESH, CMD_TAG_LOC, CMD_UNTAG_LOC, CMD_SET_CURR_TAG, CMD_CURR_TAG, CMD_CURR_DEST,CMD_SET_DEST, CMD_CLEAR_DEST}
HELP_COMMANDS = {'all'}
for _,command in ipairs(COMMANDS) do
    table.insert(HELP_COMMANDS, command)
end
--Constants
ALL_TAG = "All"
ITEM_IN_TELEPORTER_INVENTORY = 0
NOT_FOUND = -1


--Bootstrapping Functions
function getCurrentLoc()
    if teleporter_inventory.getItemDetail(1) == nil then
        return nil
    end 
    return teleporter_inventory.getItemDetail(1).displayName
end

function stubOutAllTag()
    local current_tags = storage.read()
    if current_tags[ALL_TAG] == nil then
        current_tags[ALL_TAG] = {}
        storage.writeTable(current_tags)
    end
end


--Global variables
current_tag = ALL_TAG
current_loc = getCurrentLoc()
stubOutAllTag()

--Core logic functions
function createTag(tag_to_create)
    if string.lower(tag_to_create) == string.lower(ALL_TAG) then
        return false, "special tag, can't create/destroy"
    end
    local current_tags = storage.read()
    for k,v in pairs(current_tags) do
        if string.lower(k) == tag_to_create then
            return false, "tag already exists"
        end
    end
    current_tags[tag_to_create] = {}
    local success, err_msg = storage.writeTable(current_tags)
    return success, err_msg
end

function deleteTag(tag_to_delete)
    if string.lower(tag_to_create) == string.lower(ALL_TAG) then
        return false, "special tag, can't create/destroy"
    end
    local current_tags = storage.read()
    for k,v in pairs(current_tags) do
        if string.lower(k) == string.lower(tag_to_delete) then
            current_tags[tag_to_delete] = nil
            local success, err_msg = storage.writeTable(current_tags)
            return success, err_msg
        end
    end
    return false, "tag doesn't exist"
end

function listTags()
    local current_tags = storage.read()
    local ret_list = {}
    for k,v in pairs(current_tags) do
        table.insert(ret_list, k)
    end
    table.sort(ret_list)
    return ret_list
end

function refreshLocations() 
    local all_locs = {}
    if teleporter_inventory.getItemDetail(1) ~= nil then
        all_locs[teleporter_inventory.getItemDetail(1).displayName] = 1
    end
    items, err_msg = source.listItems()
    if err_msg ~= nil then
        return false, err_msg
    end
    for _, item in ipairs(items) do
        scroll_name = string.sub(item.displayName, 2, string.len(item.displayName)-1)
        if all_locs[displayName] == scroll_name then
            return false, "Duplicate scroll name detected during inventory search"
        end
        all_locs[scroll_name] = item.fingerprint
    end
    table.sort(all_locs)
    local current_tags = storage.read()
    current_tags[ALL_TAG] = all_locs
    return storage.writeTable(current_tags)
end

function listLocations() 
    local current_tags = storage.read()
    local ret_table = {} 
    for k,v in pairs(current_tags[current_tag]) do
        table.insert(ret_table, k)
    end
    table.sort(ret_table)
    return ret_table
end

function listAllLocations()
    local current_tags = storage.read()
    local ret_table = {}
    for k,v in pairs(current_tags[ALL_TAG]) do
        table.insert(ret_table, k)
    end
    table.sort(ret_table)
    return ret_table
end

function tagLocation(tag, location)
    local current_tags = storage.read()
    local actual_tag = nil
    for value, _ in pairs(current_tags) do
        if string.lower(value) == string.lower(tag) then
            actual_tag = value
            break
        end
    end
    if actual_tag == nil then return false, "tag doesn't exist" end
    for key, _ in pairs(current_tags[ALL_TAG]) do
        if string.lower(key) == string.lower(location) then
            -- check to see if location already in tag
            if current_tags[actual_tag][key] ~= nil then
                return false, "location already in tag"
            end
            current_tags[actual_tag][key] = 1
            return storage.writeTable(current_tags)
        end
    end
    return false, "location doesn't exist"
end

function untagLocation(tag, location)
    local current_tags = storage.read()
    local actual_tag = nil
    for value, _ in pairs(current_tags) do
        if string.lower(value) == string.lower(tag) then
            actual_tag = value
            break
        end
    end
    if actual_tag == nil then return false, "tag doesn't exist" end
    for key, value in pairs(current_tags[actual_tag]) do
        if string.lower(key) == string.lower(location) then
            current_tags[actual_tag][key] = nil
            return storage.writeTable(current_tags)
        end
    end
    return false, "location doesn't exist in tag"
end

function setCurrentTag(tag)
    local current_tags = storage.read()
    for value, _  in pairs(current_tags) do
        if string.lower(value) == string.lower(tag) then
            current_tag = value
            return true, nil 
        end
    end
    return false, "tag doesn't exist"
end

function currentTag() 
    return current_tag
end

function currentDestination()
    if teleporter_inventory.getItemDetail(1) == nil then
        return nil
    else
        return teleporter_inventory.getItemDetail(1).displayName
    end
end

function clearDestination()
    if teleporter_inventory.getItemDetail(1) == nil then
        return true, nil 
    end
    transfered_items, err_msg = source.importItemFromPeripheral({name = "ars_nouveau:stable_warp_scroll"}, TP_INVENTORY_NAME)
    if err_msg ~= nil then
        return false, err_msg
    end
    current_loc = getCurrentLoc()
    if transfered_items == 1 then
        return true, nil
    else 
        return false, err_msg
    end
end 

function getActualName(dest_name)
    local current_tags = storage.read()
    for name, _ in pairs(current_tags[ALL_TAG]) do
        if string.lower(name) == string.lower(dest_name) then
            return name
        end
    end
    return nil 
end

function setDestination(dest_name)
    
    if dest_name == nil then
        return false, "Destination doesn't exist"
    end
    if teleporter_inventory.getItemDetail(1) ~= nil and teleporter_inventory.getItemDetail(1).displayName == dest_name then
        return true, nil
    end
    local cleared_destination, err_msg = clearDestination()
    if not cleared_destination then
        return false, "unable to clear out destination, reason -> " .. err_msg
    end 
    local current_tags = storage.read()
    count, err_msg = source.exportItemToPeripheral({fingerprint = current_tags[ALL_TAG][dest_name], count = 1}, TP_INVENTORY_NAME)
    current_loc = getCurrentLoc()
    if count == 1 then
        return true, nil
    else
        return false, err_msg
    end
end

--Monitor Functions
--idea, have button class with 3 states -> currently selected, enabled, disabled
--define it with (x,y) start, length, text inside, and onTouch callback

ACTIVE_COLOR = colors.green
ENABLED_COLOR = colors.lightGray
DISABLED_COLOR = colors.gray

function resetMonitor()
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
end

--this was initially implemented with the thought that the touchpoint term redirects would interfere with the shell
--which I now believe was in error, but I'm not reimplementing it with touchpoint

local Button = {
    x = 1,
    y = 1,
    length = 1,
    text = "",
    color = ENABLED_COLOR,
    onClick = function(self) end,
    inArea = function(self,x,y)
        return self.y == y and (x < self.x + self.length and x >= self.x)
    end,
    draw = function(self)
        monitor.setBackgroundColor(self.color)
        monitor.setCursorPos(self.x, self.y)
        --get the text length right
        display_text = ""
        if string.len(self.text) > self.length then
            display_text = string.sub(self.text, 1, self.length)
        elseif string.len(self.text) == self.length then
            display_text = self.text
        else 
            display_text = self.text
            while string.len(display_text) < self.length do
                display_text = " " .. display_text .. " "
            end
            if string.len(display_text) > self.length then
                display_text = string.sub(display_text, 1, string.len(display_text) - 1)
            end
        end
        monitor.write(display_text) 
    end
}

function Button:new(o)
    o = o or {} -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
end

function drawUI()
    local width, height = monitor.getSize()
    local topline = ""
    local entries = {}
    local entry_on_click = function(self) end
    local view_other_text = ""
    local view_other_mode = VIEWING_LOCATIONS
    buttons = {}
    total_entries = 0
    current_entry = ""
    if viewing_current == VIEWING_LOCATIONS then
        if current_tag == ALL_TAG then
            topline = "Locations"
        else 
            topline = "Locations Tagged " .. current_tag
        end
        local locations = listLocations()
        total_entries = #locations
        entries = {unpack(locations, curr_display_pagination_idx, curr_display_pagination_idx + ENTRIES_PER_SCREEN - 1)}
        entry_on_click = function(self) setDestination(self.text) end
        view_other_text = "View Tags"
        view_other_mode = VIEWING_TAGS
        current_entry = current_loc
    else
        topline = "Tags"
        local tags = listTags()
        total_entries = #tags
        entries = {unpack(tags, curr_display_pagination_idx, curr_display_pagination_idx + ENTRIES_PER_SCREEN - 1)}
        entry_on_click = function(self) setCurrentTag(self.text) end
        view_other_text = "View Locations"
        view_other_mode = VIEWING_LOCATIONS
        current_entry = current_tag
    end

    --setup buttons
    for i=1,ENTRIES_PER_SCREEN do
        if entries[i] ~= nil then
            local button_color = colors.black
            if current_entry == entries[i] then 
                button_color = ACTIVE_COLOR
            else
                button_color = ENABLED_COLOR
            end
            local button = Button:new({x=1, y=2*i+1,length=width, text=entries[i], color=button_color,  onClick=entry_on_click})
            table.insert(buttons, button)
        end
    end
    local arrow_key_y = (2 * ENTRIES_PER_SCREEN) + 3
    if curr_display_pagination_idx ~= 1 then --if the left button should be enabled
        local left_arrow_button = Button:new({x=1, y=arrow_key_y, length=1, text="<", color=ENABLED_COLOR, onClick=function(self) curr_display_pagination_idx = curr_display_pagination_idx - ENTRIES_PER_SCREEN end})
        table.insert(buttons, left_arrow_button)
    else
        local left_arrow_button = Button:new({x=1, y=arrow_key_y, length=1, text="<", color=DISABLED_COLOR, onClick=function(self) end})
        table.insert(buttons, left_arrow_button)
    end

    if curr_display_pagination_idx * ENTRIES_PER_SCREEN < total_entries then
        local right_arrow_button = Button:new({x=width, y=arrow_key_y, length=1, text=">", color=ENABLED_COLOR, onClick=function(self) curr_display_pagination_idx = curr_display_pagination_idx + ENTRIES_PER_SCREEN end})
        table.insert(buttons, right_arrow_button)
    else
        local right_arrow_button = Button:new({x=width, y=arrow_key_y, length=1, text=">", color=DISABLED_COLOR, onClick=function(self) end})
        table.insert(buttons, right_arrow_button)
    end

    local view_other_button = Button:new({x=3, y=arrow_key_y, length=width-4, text=view_other_text, color=ENABLED_COLOR, onClick=function(self) 
        viewing_current = view_other_mode 
        curr_display_pagination_idx = 1
        end})
    table.insert(buttons, view_other_button)
    --draw screen
    resetMonitor()
    monitor.setCursorPos(width/2 - string.len(topline)/2, 1)
    monitor.write(topline)
    for _,button in ipairs(buttons) do
        button:draw()
    end
end



function monitorThread()
    drawUI()
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        --do Event Processing
        for _, button in ipairs(buttons) do
            if button:inArea(x, y) then
                button:onClick()
            end
        end
        --redraw UI
        drawUI()
    end
end

-- Shell Helper functions
function shellPrompt()
    write(string.format("(%s)> ", SHELL_NAME))
end

function cmdOutput(cmd_name, output) 
    print(string.format("%s", output))
end

function getTrimmedString(input)
    --trim user input
    local start_idx = 1
    for i=1,string.len(input) do
        testChar = string.sub(input, i, i)
        if string.match(testChar, "%s") == nil then
            start_idx = i
            break
        end
    end

    local final_idx = string.len(input)
    for i=string.len(input),1,-1 do 
        testChar = string.sub(input, i, i)
        if string.match(testChar, "%s") == nil then
            final_idx = i
            break
        end
    end  

    return string.sub(input, start_idx, final_idx)
end

function cmdInput(cmd_name, request_string, completion_function)
    write(string.format("(%s)> ", request_string))
    local user_input = read(nil, nil, completion_function)
    

    local trimmed_user_input = getTrimmedString(user_input)
    if string.match(trimmed_user_input, "^%s+$") then
        print("User input must contain non whitespace characters")
        trimmed_user_input = cmdInput(cmd_name, request_string, completion_function)
    end
    return trimmed_user_input
end

function writeDividingLine()
    width, height = term.getSize()
    for i=1,width do
        term.write("-")
    end
end

--Shell Functions
function helpCmd()
    local command_to_help_with = string.lower(cmdInput(CMD_HELP, "command to help with (all if unsure)", function(text) return completion.choice(text, HELP_COMMANDS) end))
    if command_to_help_with == "all" then
        local output = "list of commands -> "
        for _,command in pairs(COMMANDS) do
            output = output .. command .. ", "
        end
        output = string.sub(output, 1, string.len(output)-2)
        cmdOutput(CMD_HELP, output)
    elseif command_to_help_with == CMD_TEST then
        cmdOutput(CMD_HELP, "test -> test to see what your input looks like to the shell(this is a development command)")
    elseif string.lower(cmd) == CMD_CREATE_TAG then
        cmdOutput(CMD_HELP, "create a tag")
    elseif string.lower(cmd) == CMD_DELETE_TAG then 
        cmdOutput(CMD_HELP, "delete a tag")
    elseif string.lower(cmd) == CMD_TAG_LIST then
        cmdOutput(CMD_HELP, "list current tags")
    elseif string.lower(cmd) == CMD_LIST then
        cmdOutput(CMD_HELP, "list all locations under the current tag")
    elseif string.lower(cmd) == CMD_REFRESH then
        cmdOutput(CMD_HELP, "refresh -> refresh the locations under the " .. ALL_TAG .. " tag")
    elseif string.lower(cmd) == CMD_TAG_LOC then
        cmdOutput(CMD_HELP, "add a location to a tag")
    elseif string.lower(cmd) == CMD_UNTAG_LOC then
        cmdOutput(CMD_HELP, "remove a location from a tag")
    elseif string.lower(cmd) == CMD_SET_CURR_TAG then
        cmdOutput(CMD_HELP, "set the current tag for autocomplete and listing purposes")
    elseif string.lower(cmd) == CMD_CURR_TAG then
        cmdOutput(CMD_HELP, "get the current tag for autocomplete and listing purposes")
    elseif string.lower(cmd) == CMD_CURR_DEST then
        cmdOutput(CMD_HELP, "get the current destination you are teleporting to ")
    elseif string.lower(cmd) == CMD_CLEAR_DEST then
        cmdOutput(CMD_HELP, "clear the current destination you are teleporting to ")
    elseif string.lower(cmd) == CMD_SET_DEST then
        cmdOutput(CMD_HELP, "set the current destination you are teleporting to")
    else
        cmdOutput(SHELL_NAME, "Invalid Command")
    end
end

function createTagCmd()
    local tag = cmdInput(CMD_CREATE_TAG, "tag to create")
    local success, err_msg = createTag(tag)
    if success then
        cmdOutput(CMD_CREATE_TAG, "Tag " .. tag .. " created successfully")
    else
        cmdOutput(CMD_CREATE_TAG, "Tag creation failed, reason -> " .. err_msg)
    end
end

function deleteTagCmd()
    local tag = cmdInput(CMD_DELETE_TAG, "tag to delete", function(text) return completion.choice(text, listTags()) end)
    local success, err_msg = deleteTag(tag)
    if success then
        cmdOutput(CMD_DELETE_TAG, "Tag " .. tag .. " deleteted successfully")
    else
        cmdOutput(CMD_DELETE_TAG, "Tag deletion failed, reason -> " .. err_msg)
    end
end

function listTagsCmd()
    local tagList = listTags()
    for _, tag in pairs(tagList) do
        cmdOutput(CMD_TAG_LIST, tag)
    end
end

function listLocationsCmd()
    locs = listLocations()
    for _,loc in pairs(locs) do
        cmdOutput(CMD_LIST, loc)
    end
end

function refreshLocationsCmd()
    success, err_msg = refreshLocations()
    if success then 
        cmdOutput(CMD_REFRESH, "Locations refreshed successfully")
    else
        cmdOutput(CMD_REFRESH, "Failed to refresh locations, reason -> " .. err_msg)
    end
end

function tagLocationCmd()
    local tag = cmdInput(CMD_TAG_LOC, "tag to add location to", function(text) return completion.choice(text, listTags()) end)
    local location = cmdInput(CMD_TAG_LOC, "location to tag", function(text) return completion.choice(text, listAllLocations()) end)
    local success, err_msg = tagLocation(tag, location)
    if success then
        cmdOutput(CMD_TAG_LOC, "Location " .. location .. " added to tag " .. tag)
    else
        cmdOutput(CMD_TAG_LOC, "Failed to tag location, reason -> " .. err_msg)
    end
end

function untagLocationCmd()
    local tag = cmdInput(CMD_UNTAG_LOC, "tag to remove location from", function(text) return completion.choice(text, listTags()) end)
    local location = cmdInput(CMD_UNTAG_LOC, "location to untag", function(text) return completion.choice(text, listAllLocations()) end)
    local success, err_msg = untagLocation(tag, location)
    if success then
        cmdOutput(CMD_UNTAG_LOC, "Location " .. location .. " removed from tag " .. tag)
    else
        cmdOutput(CMD_UNTAG_LOC, "Failed to untag location, reason -> " .. err_msg)
    end
end

function setCurrentTagCmd()
    local tag = cmdInput(CMD_SET_CURR_TAG, "tag to switch to", function(text) return completion.choice(text, listTags()) end)
    local success, err_msg = setCurrentTag(tag)
    if success then
        cmdOutput(CMD_SET_CURR_TAG, "Tag set to " .. tag)
    else
        cmdOutput(CMD_SET_CURR_TAG, "Failed to set current tag, reason -> " .. err_msg)
    end
end

function currentTagCmd()
    cmdOutput(CMD_CURR_TAG, "Current tag is " .. current_tag)
end

function currentDestinationCmd()
    local current_destination = currentDestination()
    if current_destination == nil then
        cmdOutput(CMD_CURR_DEST, "No Destination Set")
    else
        cmdOutput(CMD_CURR_DEST, "Destination set to " .. current_destination)
    end
end

function clearDestinationCmd()
    local cleared_destination = clearDestination()
    if cleared_destination then 
        cmdOutput(CMD_CLEAR_DEST, "Destination cleared successfully")
    else
        cmdOutput(CMD_CLEAR_DEST, "Failed to clear destination; check source inventory for overfill")
    end
end

function setDestinationCmd()
    local dest_name = cmdInput(CMD_SET_DEST, "destination to tp to", function(text) return completion.choice(text, listLocations()) end)
    dest_name = getActualName(dest_name) --performance optimization to remove it out of the path of the UI, which will have the correctly typed name
    local success, err_msg = setDestination(dest_name)
    if success then
        cmdOutput(CMD_SET_DEST, "Set teleporter destination to " .. dest_name .. " successfully")
    else
        cmdOutput(CMD_SET_DEST, "Failed to set teleport destination, reason -> " .. err_msg)
    end
end
    

function shellThread()
    while true do
        shellPrompt()
        local cmd = getTrimmedString(read(nil, nil, function(text) return completion.choice(text, COMMANDS) end))
        writeDividingLine()
        if string.lower(cmd) == CMD_TEST then
            user_input = cmdInput(CMD_TEST, "test characters", nil)
            cmdOutput(CMD_TEST, string.format("[%s]",user_input))
        elseif string.lower(cmd) == CMD_HELP then
            helpCmd()
        elseif string.lower(cmd) == CMD_CREATE_TAG then
            createTagCmd()
        elseif string.lower(cmd) == CMD_DELETE_TAG then 
            deleteTagCmd()
        elseif string.lower(cmd) == CMD_TAG_LIST then
            listTagsCmd()
        elseif string.lower(cmd) == CMD_LIST then
            listLocationsCmd()
        elseif string.lower(cmd) == CMD_REFRESH then
            refreshLocationsCmd()
        elseif string.lower(cmd) == CMD_TAG_LOC then
            tagLocationCmd()
        elseif string.lower(cmd) == CMD_UNTAG_LOC then
            untagLocationCmd()
        elseif string.lower(cmd) == CMD_SET_CURR_TAG then
            setCurrentTagCmd()
        elseif string.lower(cmd) == CMD_CURR_TAG then
            currentTagCmd()
        elseif string.lower(cmd) == CMD_CURR_DEST then
            currentDestinationCmd()
        elseif string.lower(cmd) == CMD_CLEAR_DEST then
            clearDestinationCmd()
        elseif string.lower(cmd) == CMD_SET_DEST then
            setDestinationCmd()
        else
            cmdOutput(SHELL_NAME, "Invalid Command")
        end
        writeDividingLine()
        --fully reset the monitor each time a command is run
        curr_display_pagination_idx = 1
        drawUI()
    end
end


--actually kick off the two threads
parallel.waitForAll(shellThread, monitorThread)