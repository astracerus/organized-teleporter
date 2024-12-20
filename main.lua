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
CMD_CURR_LOC = "current_location"
CMD_CURR_TAG = "current_tag"
CMD_SET_LOC = "set_location"
CMD_SET_CURR_TAG = "set_curr_tag"
CMD_TEST = "test_input"
CMD_HELP = "help"


COMMANDS = {CMD_HELP, CMD_LIST, CMD_TEST, CMD_TAG_LIST, CMD_CREATE_TAG, CMD_DELETE_TAG, CMD_REFRESH}

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
        storage.write(current_tags)
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
        table.insert(all_locs, teleporter_inventory.getItemDetail(1).displayName)
    end
    for slot, item in pairs(source_inventory.list()) do
        table.insert(all_locs, source_inventory.getItemDetail(slot).displayName)
    end
    table.sort(all_locs)

end
function listLocations() 
    local current_tags = storage.read()
    for k,v in ipairs(current_tags[current_tag]) do
        ret_table[k] = v
    end
    return ret_table
end

function getSlotForName(name)
    if teleporter_inventory.getItemDetail(1).displayName == name then
        return ITEM_IN_TELEPORTER_INVENTORY
    end
    for slot, item in pairs(source_inventory.list()) do
        if source_inventory.getItemDetail(slot).displayName == name then
            return slot
        end
    end
    return NOT_FOUND
end

function teleportTo(dest_name)
    slot = getSlotForName(dest_name)
    if slot == ITEM_IN_TELEPORTER_INVENTORY then
        return
    end
    if slot == NOT_FOUND then
        return false, "destination not found"
    end
    source_inventory.pullItems(DESTINATION_NAME, 1) --clean out teleporter
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
        local output = "list of commands "
        for _,command in ipairs(COMMANDS) do
            output = output .. command .. ", "
        end
        output = string.sub(1, string.len(output)-2)
        cmdOutput(CMD_HELP, output)
    elseif command_to_help_with == CMD_TEST then
        cmdOutput(CMD_HELP, "test -> test to see what your input looks like to the shell(this is a development command)")
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
    for _, tag in ipairs(tagList) do
        cmdOutput(CMD_TAG_LIST, tag)
    end
end

function listLocationsCmd()
    locs = listLocations()
    for _,loc in ipairs(locs) do
        cmdOutput(CMD_LIST, loc)
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
        else
            cmdOutput(SHELL_NAME, "Invalid Command")
        end
    end
end

shellThread()

-- old main function
-- for _, data in ipairs(getWarpScrolls()) do
--     print(data[2])
-- end

-- write("(teleport)> ")
-- destination = read()
-- teleportTo(destination)