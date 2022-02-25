--- Provides common functions used in different code files.
-- @module utils
-- @author Patrick Lang
-- @copyright 2022 Patrick Lang
local utils = {}

local socket = require "socket"

local dataRefLookup = {}
local missingDataRefLogged = {}
local debugLoggingEnabled = false

--- Writes a log message into the X-Plane log file.
-- @tparam string source The source of the log message.
-- @tparam string severity The severity of the log message.
-- @tparam string message The log message.
local function logMessage(source, severity, message)
    utils.verifyType("source", source, "string")
    utils.verifyType("severity", severity, "string")
    utils.verifyType("message", message, "string")

    logMsg(tostring(utils.getTime()) .. " AudioChecklist." .. source .. " [" .. severity .. "]: " .. message)
end

--- Gets a XPlane DataRef reference
-- @tparam string dataRefName The name of the DataRef.
-- @return The XPlane reference to that DataRef or nil, if the DataRef does not exist.
local function getDataRef(dataRefName)
    local dataRef = dataRefLookup[dataRefName]
    if not dataRef then
        dataRef = XPLMFindDataRef(dataRefName)
        dataRefLookup[dataRefName] = dataRef
    end

    if not dataRef and not missingDataRefLogged[dataRefName] then
        missingDataRefLogged[dataRefName] = true
        utils.logError("Utils", "DataRef '" .. dataRefName .. "' not found")
    end

    return dataRef
end

--- Enables the logging of debug messages.
function utils.enableDebugLogging()
    debugLoggingEnabled = true
end

--- Disables the logging of debug messages.
function utils.disableDebugLogging()
    debugLoggingEnabled = false
end

--- Writes a debug log message into the X-Plane log file.
-- The message is only written if debug logging is enabled.
-- @tparam string source The source of the log message.
-- @tparam string message The log message.
function utils.logDebug(source, message)
    if debugLoggingEnabled then
        logMessage(source, "DEBUG", message)
    end
end

--- Writes an information log message into the X-Plane log file.
-- @tparam string source The source of the log message.
-- @tparam string message The log message.
function utils.logInfo(source, message)
    logMessage(source, "INFO", message)
end

--- Writes an error log message into the X-Plane log file.
-- @tparam string source The source of the log message.
-- @tparam string message The log message.
function utils.logError(source, message)
    logMessage(source, "ERROR", message)
end

--- Verifies that a value is of the expected type.
-- An error is thrown if the type of the value does not match the expected type.
-- @tparam string valueName The name of the value. Used for the error message.
-- @param value The value to check.
-- @tparam string expectedType The expected type of the value.
function utils.verifyType(valueName, value, expectedType)
    if type(valueName) ~= "string" then error("valueName must be a string") end
    if type(expectedType) ~= "string" then error("expectedType must be a string") end

    if type(value) ~= expectedType then
        error(valueName .. " must be a " .. expectedType)
    end
end

--- Verifies that a value is not nil.
-- @tparam string valueName The name of the value. Used for the error message.
-- @param value The value to check.
function utils.verifyNotNil(valueName, value)
    if type(valueName) ~= "string" then error("valueName must be a string") end

    if value == nil then
        error(valueName .. " must not be nil")
    end
end

--- Gets the current time.
-- The function uses the <code>gettime()</code> function of LuaSocket, which provides the current time with milliseconds resolution.
-- @treturn number The current time.
function utils.getTime()
	return socket.gettime()
end

--- Checks whether a file exists
-- @tparam string filePath The path to the file
-- @treturn bool <code>True</code> if the file exists and can be read, otherwise <code>false</code>.
function utils.fileExists(filePath)
    utils.verifyType("filePath", filePath, "string")

    local file = io.open(filePath, "r")
    if not file then
        return false
    end

    file:close()
    return true
end

--- Checks whether an array contains a specific value
-- @tparam tab array The array
-- @param value The value to check
-- @treturn bool <code>True</code> if the array contains the value, otherwise <code>false</code>.
function utils.arrayContains(array, value)
    return utils.checkArrayValuesAny(array, function(v) return value == v end)
end

--- Checks whether all items of an array meet a given condition.
-- @tparam tab array The array.
-- @tparam func verifyFunction The function which will receive each item of the array and returns whether the item meets its condition (<code>true</code> or <code>false</code>).
-- @treturn bool True if the verification function returns <code>true</code> for all items, otherwise false.
-- @usage utils.checkArrayValuesAll({1, 2, 3}, function(v) return v < 4 end) -- returns true
-- @usage utils.checkArrayValuesAll({1, 2, 3}, function(v) return v < 3 end) -- returns false
function utils.checkArrayValuesAll(array, verifyFunction)
    utils.verifyType("array", array, "table")
    utils.verifyType("verifyFunction", verifyFunction, "function")

    for _, value in pairs(array) do
        if verifyFunction(value) ~= true then
            return false
        end
    end

    return true
end

--- Checks whether any item of an array meets a given condition.
-- @tparam tab array The array.
-- @tparam func verifyFunction The function which will receive each item of the array and returns whether the item meets its condition (<code>true</code> or <code>false</code>)..
-- @treturn bool <code>True</code> if the verification function returns <code>true</code> for any item, otherwise <code>false</code>.
-- @usage utils.checkArrayValuesAny({1, 2, 3}, function(v) return v < 2 end) -- returns true
-- @usage utils.checkArrayValuesAny({1, 2, 3}, function(v) return v < 1 end) -- returns false
function utils.checkArrayValuesAny(array, verifyFunction)
    utils.verifyType("array", array, "table")
    utils.verifyType("verifyFunction", verifyFunction, "function")

    for _, value in pairs(array) do
        if verifyFunction(value) == true then
            return true
        end
    end

    return false
end

--- Reads an integer DataRef from X-Plane.
-- Reading DataRef values is a relatively slow operation and should only be done if necessary.
-- @tparam string dataRefName The name of the DataRef.
-- @tparam ?number defaultValue The default value to return if the DataRef was not found.
-- @treturn ?number The value of the DataRef or the default value, if the DataRef was not found.
function utils.readDataRefInteger(dataRefName, defaultValue)
    utils.verifyType("dataRefName", dataRefName, "string")

    if defaultValue ~= nil then
        utils.verifyType("defaultValue", defaultValue, "number")
    end

    local dataRef = getDataRef(dataRefName)
    if not dataRef then
        return defaultValue
    end

    return XPLMGetDatai(dataRef)
end

--- Reads a float DataRef from X-Plane.
-- Reading DataRef values is a relatively slow operation and should only be done if necessary.
-- @tparam string dataRefName The name of the DataRef.
-- @tparam ?number defaultValue The default value to return if the DataRef was not found.
-- @treturn ?number The value of the DataRef or the default value, if the DataRef was not found.
function utils.readDataRefFloat(dataRefName, defaultValue)
    utils.verifyType("dataRefName", dataRefName, "string")

    if defaultValue ~= nil then
        utils.verifyType("defaultValue", defaultValue, "number")
    end

    local dataRef = getDataRef(dataRefName)
    if not dataRef then
        return defaultValue
    end

    return XPLMGetDataf(dataRef)
end

--- Checks whether the items within a range of an integer DataRef array meet a given condition.
-- Reading DataRef values is a relatively slow operation and should only be done if necessary.
-- @tparam string dataRefName The name of the DataRef.
-- @tparam number startIndex The start index of the range to check.
-- @tparam number count The count of items to check.
-- @tparam func verifyFunction The function which will receive each item and returns whether the item meets its condition (<code>true</code> or <code>false</code>)..
-- @treturn bool <code>True</code> if the verification function returns <code>true</code> for all items within the range, otherwise <code>false</code>. If the DataRef was not found, then <code>false</code> is returned.
-- @usage utils.checkArrayValuesAllInteger("sim/flightmodel/engine/ENGN_running", 0, 2, function(v) return v == 1 end) -- Checks if engines 1 and 2 are running
function utils.checkArrayValuesAllInteger(dataRefName, startIndex, count, verifyFunction)
    utils.verifyType("dataRefName", dataRefName, "string")
    utils.verifyType("startIndex", startIndex, "number")
    utils.verifyType("count", count, "number")
    utils.verifyType("verifyFunction", verifyFunction, "function")

    local dataRef = getDataRef(dataRefName)
    if not dataRef then
        return false
    end

    return utils.checkArrayValuesAll(XPLMGetDatavi(dataRef, startIndex, count), verifyFunction)
end

--- Checks whether any item within a range of an integer DataRef array meets a given condition.
-- Reading DataRef values is a relatively slow operation and should only be done if necessary.
-- @tparam string dataRefName The name of the DataRef.
-- @tparam number startIndex The start index of the range to check.
-- @tparam number count The count of items to check.
-- @tparam func verifyFunction The function which will receive each item and returns whether the item meets its condition (<code>true</code> or <code>false</code>)..
-- @treturn bool <code>True</code> if the verification function returns <code>true</code> for any item within the range, otherwise <code>false</code>. If the DataRef was not found, then <code>false</code> is returned.
-- @usage utils.checkArrayValuesAnyInteger("sim/flightmodel/engine/ENGN_running", 0, 2, function(v) return v == 1 end) -- Checks if any engine is running
function utils.checkArrayValuesAnyInteger(dataRefName, startIndex, count, verifyFunction)
    utils.verifyType("dataRefName", dataRefName, "string")
    utils.verifyType("startIndex", startIndex, "number")
    utils.verifyType("count", count, "number")
    utils.verifyType("verifyFunction", verifyFunction, "function")

    local dataRef = getDataRef(dataRefName)
    if not dataRef then
        return false
    end

    return utils.checkArrayValuesAny(XPLMGetDatavi(dataRef, startIndex, count), verifyFunction)
end

--- Checks whether the items within a range of a float DataRef array meet a given condition.
-- Reading DataRef values is a relatively slow operation and should only be done if necessary.
-- @tparam string dataRefName The name of the DataRef.
-- @tparam number startIndex The start index of the range to check.
-- @tparam number count The count of items to check.
-- @tparam func verifyFunction The function which will receive each item and returns whether the item meets its condition (<code>true</code> or <code>false</code>)..
-- @treturn bool <code>True</code> if the verification function returns <code>true</code> for all items within the range, otherwise <code>false</code>. If the DataRef was not found, then <code>false</code> is returned.
-- @usage utils.checkArayValuesAllFloat("laminar/B738/flap_indicator", 0, 2, function(v) return v == 0 end) -- Checks if all flaps are up
function utils.checkArrayValuesAllFloat(dataRefName, startIndex, count, verifyFunction)
    utils.verifyType("dataRefName", dataRefName, "string")
    utils.verifyType("startIndex", startIndex, "number")
    utils.verifyType("count", count, "number")
    utils.verifyType("verifyFunction", verifyFunction, "function")

    local dataRef = getDataRef(dataRefName)
    if not dataRef then
        return false
    end

    return utils.checkArrayValuesAll(XPLMGetDatavf(dataRef, startIndex, count), verifyFunction)
end

--- Checks whether any item within a range of a float DataRef array meets a given condition.
-- Reading DataRef values is a relatively slow operation and should only be done if necessary.
-- @tparam string dataRefName The name of the DataRef.
-- @tparam number startIndex The start index of the range to check.
-- @tparam number count The count of items to check.
-- @tparam func verifyFunction The function which will receive each item and returns whether the item meets its condition (<code>true</code> or <code>false</code>)..
-- @treturn bool <code>True</code> if the verification function returns <code>true</code> for any item within the range, otherwise <code>false</code>. If the DataRef was not found, then <code>false</code> is returned.
-- @usage utils.checkArrayValuesAnyFloat("sim/cockpit2/engine/actuators/throttle_ratio", 0, 2, function(v) return v >= 0.5 end) -- Checks if any thrust lever is advanced 50% or more
function utils.checkArrayValuesAnyFloat(dataRefName, startIndex, count, verifyFunction)
    utils.verifyType("dataRefName", dataRefName, "string")
    utils.verifyType("startIndex", startIndex, "number")
    utils.verifyType("count", count, "number")
    utils.verifyType("verifyFunction", verifyFunction, "function")

    local dataRef = getDataRef(dataRefName)
    if not dataRef then
        return false
    end

    return utils.checkArrayValuesAny(XPLMGetDatavf(dataRef, startIndex, count), verifyFunction)
end

return utils