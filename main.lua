--Config 
DESTINATION_NAME = "ars_nouveau:repository_0"
teleporter_inventory = peripheral.wrap(DESTINATION_NAME)
SOURCE_NAME = "sophisticatedstorage:chest_0"
source_inventory = peripheral.wrap(SOURCE_NAME)
SHELL_NAME="teleport"


--Globals
storage = peripheral.find("nbtStorage")
completion = require "cc.completion"

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

function stubOutAllTag() --necessary for performance optimization
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
    for slot, item in pairs(source_inventory.list()) do
        if all_locs[source_inventory.getItemDetail(slot).displayName] ~= nil then
            return false, "Duplicates detected across both inventories"
        else
            all_locs[source_inventory.getItemDetail(slot).displayName] = 1
        end
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
        return true
    end
    transfered_items = source_inventory.pullItems(DESTINATION_NAME, 1)
    return transfered_items == 1
end 



function getSlotForName(name)
    if teleporter_inventory.getItemDetail(1) ~= nil and teleporter_inventory.getItemDetail(1).displayName == name then
        return ITEM_IN_TELEPORTER_INVENTORY
    end
    for slot, item in pairs(source_inventory.list()) do
        if source_inventory.getItemDetail(slot).displayName == name then
            return slot
        end
    end
    return NOT_FOUND
end

function setDestination(dest_name)
    local slot = getSlotForName(dest_name)
    if slot == ITEM_IN_TELEPORTER_INVENTORY then
        return
    end
    if slot == NOT_FOUND then
        return false, "destination not found"
    end
    local cleared_destination = clearDestination()
    if not cleared_destination then
        return false, "unable to clean out destination"
    end 
    source_inventory.pushItems(DESTINATION_NAME, slot, 1, 1)
    current_loc = getCurrentLoc()
    return true, nil
end

-- Shell Helper functions
function shellPrompt()
    write(string.format("(%s)> ", SHELL_NAME))
end

function cmdOutput(cmd_name, output) 
    print(string.format("[%s] %s",cmd_name, output))
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
    write(string.format("(%s)(%s)> ",cmd_name, request_string))
    local user_input = read(nil, nil, completion_function)
    

    local trimmed_user_input = getTrimmedString(user_input)
    if string.match(trimmed_user_input, "^%s+$") then
        print("User input must contain non whitespace characters")
        trimmed_user_input = cmdInput(cmd_name, request_string, completion_function)
    end
    return trimmed_user_input
end

--Shell Functions
function helpCmd()
    local command_to_help_with = string.lower(cmdInput(CMD_HELP, "command to help with (all if unsure)", function(text) return completion.choice(text, COMMANDS) end))
    if command_to_help_with == "all" then
        local output = "list of commands -> "
        for _,command in pairs(COMMANDS) do
            output = output .. command .. ", "
        end
        output = string.sub(1, string.len(output)-2)
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
    local destination_name = cmdInput(CMD_SET_DEST, "destination to tp to", function(text) return completion.choice(text, listLocations()) end)
    local success, err_msg = setDestination(destination_name)
    if success then
        cmdOutput(CMD_SET_DEST, "Set teleporter destination to " .. destination_name .. " successfully")
    else
        cmdOutput(CMD_SET_DEST, "Failed to set teleport destination, reason -> " .. err_msg)
    end
end
    

function shellThread()
    while true do
        shellPrompt()
        local cmd = getTrimmedString(read(nil, nil, function(text) return completion.choice(text, COMMANDS) end))
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
    end
end

shellThread()

-- old main function
-- for _, data in pairs(getWarpScrolls()) do
--     print(data[2])
-- end

-- write("(teleport)> ")
-- destination = read()
-- teleportTo(destination)