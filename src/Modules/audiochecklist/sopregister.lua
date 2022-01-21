--- Holds all created standard operating procedures.
-- The created SOPs must be added in this static module. This prevents from being dependent on the load order of the Lua files.
-- The currently added SOPs can be received at any time. A callback can be added to get notified about SOPs which are added subsequently.
-- @module sopRegister
-- @author Patrick Lang
-- @copyright 2022 Patrick Lang
local sopRegister = {}

local utils = require "audiochecklist.utils"

local standardOperatingProcecudes = {}
local addedCallbacks = {}

--- Adds a standard operating procedure to the list of SOPs
-- @tparam standardOperatingProcedure sop The standard operating procedure to add
function sopRegister.addSOP(sop)
    utils.verifyNotNil("sop", sop)

    utils.logInfo("SopExecutor", "Registered SOP '" .. sop:getName() .. "'")

    table.insert(standardOperatingProcecudes, sop)

    for _, callback in ipairs(addedCallbacks) do
        callback(sop)
    end
end

--- Gets all registered standard operating procedures
-- @treturn tab An array which contains all standard operating procedures
function sopRegister.getAllSOPs()
    return standardOperatingProcecudes
end

--- Adds a callback which is exeucted if a SOP is added to the register.
-- The added SOP is passed as a parameter to the callback.
-- @tparam func callback The callback to add.
-- @usage sopRegister.addAddedCallback(function(sop) end)
function sopRegister.addAddedCallback(callback)
    utils.verifyType("callback", callback, "function")
    table.insert(addedCallbacks, callback)
end

return sopRegister
