--- Provides functions to save and load preferences.
-- Preferences are stored as a key-value-pair. The key and the value must be a string.
--
-- The preferences can be saved to a file and loaded again. Each entry is written into a separate line. The line separator is '\n'.
-- Key and value are separated by a '='. When loading a file, every character before the first '=' character is considered as part of the key.
-- All characters between the first '=' and the end of the line are considered as part of the value.
-- Therefore, keys must not contain a '=' character and values must not contain a '\n' character.
-- @module preferences
-- @author Patrick Lang
-- @copyright 2022 Patrick Lang
local preferences = {}

local utils = require "audiochecklist.utils"

local entries = {}

--- Creates a valid preference key based on the provided string.
-- Replaces all '=' characters with an underscore.
-- @tparam string str The string to convert.
-- @treturn string The escaped preference key.
function preferences.escapeString(str)
    utils.verifyType("str", str, "string")

    -- Replace all spaces and '=' with '_'
	return string.gsub(str, "[=\n]", "_")
end

--- Sets a preference value.
-- Providing a nil value removes the preference with the given key.
-- @tparam string key The key of the value.
-- @tparam ?string value The preference value.
-- @raise An error is thrown if the key contains a '=' or '\n', or the value contains a '\n'.
function preferences.set(key, value)
    utils.verifyType("key", key, "string")
    if string.find(key, "=") then error("key must not contain a '='") end
    if string.find(key, "\n") then error("key must not contain a '\\n'") end

    if value ~= nil then
        utils.verifyType("value", value, "string")
        if string.find(value, "\n") then error("value must not contain a '\\n'") end

        utils.logDebug("Preferences", "Setting preference '" .. key .. "'='" .. value .. "'")
        entries[key] = value
    else
        preferences.remove(key)
    end
end

--- Gets a preference value.
-- @tparam string key The key of the value.
-- @tparam ?string defaultValue The default value to use if there is no preference with this key. Can be <code>nil</code>.
-- @treturn string The value for the preference key, or the default value, if there is no preference with this key.
function preferences.get(key, defaultValue)
    utils.verifyType("key", key, "string")
    if defaultValue ~= nil then utils.verifyType("defaultValue", defaultValue, "string") end

    utils.logDebug("Preferences", "Reading preference '" .. key .. "'")

    local value = entries[key]

    if value ~= nil then
        return value
    end

    return defaultValue
end

--- Removes a preference value.
-- @tparam string key The key of the value to remove.
function preferences.remove(key)
    utils.verifyType("key", key, "string")

    utils.logDebug("Preferences", "Removing preference '" .. key .. "'")
    entries[key] = nil
end

--- Removes all preferences.
function preferences.clear()
    utils.logDebug("Preferences", "Removing all preferences")

    for key, _ in pairs(entries) do
        preferences.remove(key)
    end
end

--- Saves the preferences to the specified file.
--  If the file could not be opened for writing, then the preferences are not saved.
-- @tparam string filePath The path to the target file.
-- @treturn bool <code>True</code> if the preferences has been saved, otherwise <code>false</code>.
function preferences.save(filePath)
    utils.verifyType("filePath", filePath, "string")

    local content = ""

    for key, value in pairs(entries) do
        utils.logInfo("Preferences", "Saving preference '" .. key .. "'='" .. value .. "'")
        content = content .. key .. "=" .. value .. "\n"
    end

    local fileHandle = io.open(filePath, "w")
    if not fileHandle then
        -- File could not be created
        utils.logError("Preferences", "Could not open file '" .. filePath .. "' for writing")
        return false
    end

    fileHandle:write(content)
    fileHandle:close()

    return true
end

--- Loads the preferences from the specified file.
-- If the file does not exist, then no preferences are loaded.
-- The actual preferences are not reset before loading the file. Already existing preferences are overwritten.
-- @tparam string filePath The path to the file which contains the preferences.
-- @treturn bool <code>True</code> if the preferences has been loaded, otherwise <code>false</code>.
function preferences.load(filePath)
    utils.verifyType("filePath", filePath, "string")

    local fileHandle = io.open(filePath, "r")
    if not fileHandle then
        -- File could not be read
        utils.logError("Preferences", "Could not open file '" .. filePath .. "' for reading")
        return false
    end

    for line in fileHandle:lines() do
        local key = nil
        local value = nil

        local delimiterIndex = string.find(line, "=")
        if delimiterIndex and delimiterIndex > 1 and delimiterIndex < string.len(line) then
            local key = string.sub(line, 1, delimiterIndex - 1)
            local value = string.sub(line, delimiterIndex + 1)

            utils.logInfo("Preferences", "Loading preference '" .. key .. "'='" .. value .. "'")

            entries[key] = value
        end
    end

    fileHandle:close()

    return true
end

return preferences
