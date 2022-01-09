describe("Utils", function()
    local utils
    local findDataRef
    local dataRefLookup
    local dataRefValues
    local dataRefCounter

    local function setIntegerDataRefValue(dataRefName, value)
        dataRefCounter = dataRefCounter + 1
        dataRefLookup[dataRefName] = dataRefCounter
        dataRefValues["Integer" .. tostring(dataRefCounter)] = value
    end

    local function setFloatDataRefValue(dataRefName, value)
        dataRefCounter = dataRefCounter + 1
        dataRefLookup[dataRefName] = dataRefCounter
        dataRefValues["Float" .. tostring(dataRefCounter)] = value
    end

    local function setIntegerArrayDataRefValue(dataRefName, value)
        dataRefCounter = dataRefCounter + 1
        dataRefLookup[dataRefName] = dataRefCounter
        dataRefValues["IntegerArray" .. tostring(dataRefCounter)] = value
    end

    local function setFloatArrayDataRefValue(dataRefName, value)
        dataRefCounter = dataRefCounter + 1
        dataRefLookup[dataRefName] = dataRefCounter
        dataRefValues["FloatArray" .. tostring(dataRefCounter)] = value
    end

    setup(function()
        stub.new(_G, "logMsg")

        _G.XPLMFindDataRef = function(dataRefName)
            return dataRefLookup[dataRefName]
        end

        _G.XPLMGetDatai = function(dataRef)
            return dataRefValues["Integer" .. tostring(dataRef)]
        end

        _G.XPLMGetDataf = function(dataRef)
            return dataRefValues["Float" .. tostring(dataRef)]
        end

        _G.XPLMGetDatavi = function(dataRef, startIndex, count)
            return dataRefValues["IntegerArray" .. tostring(dataRef)]
        end

        _G.XPLMGetDatavf = function(dataRef, startIndex, count)
            return dataRefValues["FloatArray" .. tostring(dataRef)]
        end

        utils = require "audiochecklist.utils"
    end)

    teardown(function()
        utils = nil
        _G.XPLMFindDataRef = nil
        _G.XPLMGetDatai = nil
        _G.XPLMGetDataf = nil
        _G.XPLMGetDatavi = nil
        _G.XPLMGetDatavf = nil
        _G.logMsg:revert()
    end)

    before_each(function()
        dataRefLookup = {}
        dataRefValues = {}
        dataRefCounter = 0
    end)

    after_each(function()
        dataRefLookup = nil
        dataRefValues = nil
        dataRefCounter = 0
    end)

    it("should not write a debug message if debug logging is disabled", function()
        utils.logDebug("Test", "My debug message")
        assert.stub(_G.logMsg).was_not_called()
    end)

    it("should write a debug message if debug logging is enabled", function()
        finally(function()
            utils.disableDebugLogging()
        end)

        utils.enableDebugLogging()
        utils.logDebug("Test", "My debug message")
        assert.stub(_G.logMsg).was.called_with("AudioChecklist.Test [DEBUG]: My debug message")
    end)

    it("should write an information log message", function()
        utils.logInfo("Test", "My information message")
        assert.stub(_G.logMsg).was.called_with("AudioChecklist.Test [INFO]: My information message")
    end)

    it("should write an error log message", function()
        utils.logError("Test", "My error message")
        assert.stub(_G.logMsg).was.called_with("AudioChecklist.Test [ERROR]: My error message")
    end)

    it("should verify a type", function()
        utils.verifyType("A boolean", false, "boolean")
        utils.verifyType("A string", "", "string")
        utils.verifyType("A number", 0, "number")
        utils.verifyType("A table", {}, "table")
        utils.verifyType("A function", function() end, "function")

        assert.has_error(function() utils.verifyType("Not a boolean", 0, "boolean") end, "Not a boolean must be a boolean")
        assert.has_error(function() utils.verifyType("Not a string", 0, "string") end, "Not a string must be a string")
        assert.has_error(function() utils.verifyType("Not a number", "", "number") end, "Not a number must be a number")
        assert.has_error(function() utils.verifyType("Not a table", "", "table") end, "Not a table must be a table")
        assert.has_error(function() utils.verifyType("Not a function", "", "function") end, "Not a function must be a function")
    end)

    it("should verify a nil value", function()
        utils.verifyNotNil("A boolean", false)
        utils.verifyNotNil("A string", "")
        utils.verifyNotNil("A number", 0)
        utils.verifyNotNil("A table", {})
        utils.verifyNotNil("A function", function() end)

        assert.has_error(function() utils.verifyNotNil("A nil value", nil) end, "A nil value must not be nil")
    end)

    it("should throw an error if verification parameters are invalid", function()
        assert.has_error(function() utils.verifyType(nil, "", "string") end, "valueName must be a string")
        assert.has_error(function() utils.verifyType(0, "", "string") end, "valueName must be a string")
        assert.has_error(function() utils.verifyType("", "", nil) end, "expectedType must be a string")
        assert.has_error(function() utils.verifyType("", "", 0) end, "expectedType must be a string")

        assert.has_error(function() utils.verifyNotNil(nil, "") end, "valueName must be a string")
        assert.has_error(function() utils.verifyNotNil(0, "") end, "valueName must be a string")
    end)

    it("should check whether a file exists", function()
        assert.is_true(utils.fileExists("files/On.wav"))
        assert.is_false(utils.fileExists("files/NotExistingFile.txt"))
    end)

    it("should throw an error if the file path is invalid", function()
        assert.has_error(function() utils.fileExists(nil) end, "filePath must be a string")
        assert.has_error(function() utils.fileExists(0) end, "filePath must be a string")
    end)

    it("should check if an array contains a given value", function()
        assert.is_true(utils.arrayContains({1, 2, 3}, 3))
        assert.is_false(utils.arrayContains({1, 2, 3}, 4))

        assert.is_true(utils.arrayContains({"1", "2", "3"}, "3"))
        assert.is_false(utils.arrayContains({"1", "2", "3"}, "4"))

        assert.is_true(utils.arrayContains({1, "2", nil, 4}, 4))
        assert.is_false(utils.arrayContains({1, "2", nil, 4}, nil))

        assert.is_true(utils.arrayContains({ Key1 = 1, Key2 = 2, Key3 = 3}, 3))
        assert.is_false(utils.arrayContains({ Key1 = 1, Key2 = 2, Key3 = 3}, 4))
    end)

    it("should check if all values of an array meet a given condition", function()
        assert.is_true(utils.checkArrayValuesAll({1, 2, 3}, function(v) return v < 4 end))
        assert.is_false(utils.checkArrayValuesAll({1, 2, 3}, function(v) return v < 3 end))

        assert.is_true(utils.checkArrayValuesAll({"Hello", "World"}, function(v) return string.find(v, "o") ~= nil end))
        assert.is_false(utils.checkArrayValuesAll({"Hello", "World"}, function(v) return string.find(v, "H") ~= nil end))

        assert.is_true(utils.checkArrayValuesAll({ First = "Hello", Second = "World"}, function(v) return string.find(v, "o") ~= nil end))
        assert.is_false(utils.checkArrayValuesAll({ First = "Hello", Second = "World"}, function(v) return string.find(v, "H") ~= nil end))
    end)

    it("should check if any value of an array meets a given condition", function()
        assert.is_true(utils.checkArrayValuesAny({1, 2, 3}, function(v) return v < 2 end))
        assert.is_false(utils.checkArrayValuesAny({1, 2, 3}, function(v) return v < 1 end))

        assert.is_true(utils.checkArrayValuesAny({"Hello", "World"}, function(v) return string.find(v, "H") ~= nil end))
        assert.is_false(utils.checkArrayValuesAny({"Hello", "World"}, function(v) return string.find(v, "x") ~= nil end))

        assert.is_true(utils.checkArrayValuesAny({ First = "Hello", Second = "World"}, function(v) return string.find(v, "H") ~= nil end))
        assert.is_false(utils.checkArrayValuesAny({ First = "Hello", Second = "World"}, function(v) return string.find(v, "x") ~= nil end))
    end)

    it("should throw an error if array parameters are invalid", function()
        assert.has_error(function() utils.arrayContains(nil, 0) end, "array must be a table")
        assert.has_error(function() utils.arrayContains("", 0) end, "array must be a table")

        assert.has_error(function() utils.checkArrayValuesAll(nil, function() end) end, "array must be a table")
        assert.has_error(function() utils.checkArrayValuesAll("", function() end) end, "array must be a table")
        assert.has_error(function() utils.checkArrayValuesAll({}, nil) end, "verifyFunction must be a function")
        assert.has_error(function() utils.checkArrayValuesAll({}, "") end, "verifyFunction must be a function")

        assert.has_error(function() utils.checkArrayValuesAny(nil, function() end) end, "array must be a table")
        assert.has_error(function() utils.checkArrayValuesAny("", function() end) end, "array must be a table")
        assert.has_error(function() utils.checkArrayValuesAny({}, nil) end, "verifyFunction must be a function")
        assert.has_error(function() utils.checkArrayValuesAny({}, "") end, "verifyFunction must be a function")
    end)

    it("should read a DataRef as integer", function()
        setIntegerDataRefValue("MyIntValue", 42)
        assert.are.equal(42, utils.readDataRefInteger("MyIntValue"))
    end)

    it("should return nil if an integer DataRef does not exist", function()
        assert.is_nil(utils.readDataRefInteger("NotExistingDataRef"))
    end)

    it("should throw an error if an integer DataRef name is invalid", function()
        assert.has_error(function() utils.readDataRefInteger(nil) end, "dataRefName must be a string")
        assert.has_error(function() utils.readDataRefInteger(0) end, "dataRefName must be a string")
    end)

    it("should read a DataRef as float", function()
        setFloatDataRefValue("MyFloatValue", 3.1415)
        assert.are.equal(3.1415, utils.readDataRefFloat("MyFloatValue"))
    end)

    it("should return nil if a float DataRef does not exist", function()
        assert.is_nil(utils.readDataRefFloat("NotExistingDataRef"))
    end)

    it("should throw an error if a float DataRef name is invalid", function()
        assert.has_error(function() utils.readDataRefFloat(nil) end, "dataRefName must be a string")
        assert.has_error(function() utils.readDataRefFloat(0) end, "dataRefName must be a string")
    end)

    it("should check all items in an integer DataRef array", function()
        setIntegerArrayDataRefValue("MyIntegerArray", {1, 2, 3})

        local s = spy.on(_G, "XPLMGetDatavi")

        assert.is_true(utils.checkArrayValuesAllInteger("MyIntegerArray", 0, 3, function(v) return v < 4 end))
        assert.is_false(utils.checkArrayValuesAllInteger("MyIntegerArray", 0, 3, function(v) return v < 3 end))

        assert.spy(s).was.called_with(dataRefLookup["MyIntegerArray"], 0, 3)
    end)

    it("should check any item in an integer DataRef array", function()
        setIntegerArrayDataRefValue("MyIntegerArray", {1, 2, 3})

        local s = spy.on(_G, "XPLMGetDatavi")

        assert.is_true(utils.checkArrayValuesAnyInteger("MyIntegerArray", 0, 3, function(v) return v < 2 end))
        assert.is_false(utils.checkArrayValuesAnyInteger("MyIntegerArray", 0, 3, function(v) return v < 1 end))

        assert.spy(s).was.called_with(dataRefLookup["MyIntegerArray"], 0, 3)
    end)

    it("should return nil if an integer DataRef array does not exist", function()
        assert.is_nil(utils.checkArrayValuesAllInteger("NotExistingDataRef", 0, 3, function(v) return v < 4 end))
        assert.is_nil(utils.checkArrayValuesAnyInteger("NotExistingDataRef", 0, 3, function(v) return v < 4 end))
    end)

    it("should throw an error if any parameter for the integer array check is invalid", function()
        assert.has_error(function() utils.checkArrayValuesAllInteger(nil, 0, 0, function() end) end, "dataRefName must be a string")
        assert.has_error(function() utils.checkArrayValuesAllInteger(0, 0, 0, function() end) end, "dataRefName must be a string")
        assert.has_error(function() utils.checkArrayValuesAllInteger("", nil, 0, function() end) end, "startIndex must be a number")
        assert.has_error(function() utils.checkArrayValuesAllInteger("", "", 0, function() end) end, "startIndex must be a number")
        assert.has_error(function() utils.checkArrayValuesAllInteger("", 0, nil, function() end) end, "count must be a number")
        assert.has_error(function() utils.checkArrayValuesAllInteger("", 0, "", function() end) end, "count must be a number")
        assert.has_error(function() utils.checkArrayValuesAllInteger("", 0, 0, nil) end, "verifyFunction must be a function")
        assert.has_error(function() utils.checkArrayValuesAllInteger("", 0, 0, true) end, "verifyFunction must be a function")

        assert.has_error(function() utils.checkArrayValuesAnyInteger(nil, 0, 0, function() end) end, "dataRefName must be a string")
        assert.has_error(function() utils.checkArrayValuesAnyInteger(0, 0, 0, function() end) end, "dataRefName must be a string")
        assert.has_error(function() utils.checkArrayValuesAnyInteger("", nil, 0, function() end) end, "startIndex must be a number")
        assert.has_error(function() utils.checkArrayValuesAnyInteger("", "", 0, function() end) end, "startIndex must be a number")
        assert.has_error(function() utils.checkArrayValuesAnyInteger("", 0, nil, function() end) end, "count must be a number")
        assert.has_error(function() utils.checkArrayValuesAnyInteger("", 0, "", function() end) end, "count must be a number")
        assert.has_error(function() utils.checkArrayValuesAnyInteger("", 0, 0, nil) end, "verifyFunction must be a function")
        assert.has_error(function() utils.checkArrayValuesAnyInteger("", 0, 0, true) end, "verifyFunction must be a function")
    end)

    it("should check all items in a float DataRef array", function()
        setFloatArrayDataRefValue("MyFloatArray", {1, 2, 3})

        local s = spy.on(_G, "XPLMGetDatavf")

        assert.is_true(utils.checkArrayValuesAllFloat("MyFloatArray", 0, 3, function(v) return v < 4 end))
        assert.is_false(utils.checkArrayValuesAllFloat("MyFloatArray", 0, 3, function(v) return v < 3 end))

        assert.spy(s).was.called_with(dataRefLookup["MyFloatArray"], 0, 3)
    end)

    it("should check any item in a float DataRef array", function()
        setFloatArrayDataRefValue("MyFloatArray", {1, 2, 3})

        local s = spy.on(_G, "XPLMGetDatavf")

        assert.is_true(utils.checkArrayValuesAnyFloat("MyFloatArray", 0, 3, function(v) return v < 2 end))
        assert.is_false(utils.checkArrayValuesAnyFloat("MyFloatArray", 0, 3, function(v) return v < 1 end))

        assert.spy(s).was.called_with(dataRefLookup["MyFloatArray"], 0, 3)
    end)

    it("should return nil if a float DataRef array does not exist", function()
        assert.is_nil(utils.checkArrayValuesAllFloat("NotExistingDataRef", 0, 3, function(v) return v < 4 end))
        assert.is_nil(utils.checkArrayValuesAnyFloat("NotExistingDataRef", 0, 3, function(v) return v < 4 end))
    end)

    it("should throw an error if any parameter for the float array check is invalid", function()
        assert.has_error(function() utils.checkArrayValuesAllFloat(nil, 0, 0, function() end) end, "dataRefName must be a string")
        assert.has_error(function() utils.checkArrayValuesAllFloat(0, 0, 0, function() end) end, "dataRefName must be a string")
        assert.has_error(function() utils.checkArrayValuesAllFloat("", nil, 0, function() end) end, "startIndex must be a number")
        assert.has_error(function() utils.checkArrayValuesAllFloat("", "", 0, function() end) end, "startIndex must be a number")
        assert.has_error(function() utils.checkArrayValuesAllFloat("", 0, nil, function() end) end, "count must be a number")
        assert.has_error(function() utils.checkArrayValuesAllFloat("", 0, "", function() end) end, "count must be a number")
        assert.has_error(function() utils.checkArrayValuesAllFloat("", 0, 0, nil) end, "verifyFunction must be a function")
        assert.has_error(function() utils.checkArrayValuesAllFloat("", 0, 0, true) end, "verifyFunction must be a function")

        assert.has_error(function() utils.checkArrayValuesAnyFloat(nil, 0, 0, function() end) end, "dataRefName must be a string")
        assert.has_error(function() utils.checkArrayValuesAnyFloat(0, 0, 0, function() end) end, "dataRefName must be a string")
        assert.has_error(function() utils.checkArrayValuesAnyFloat("", nil, 0, function() end) end, "startIndex must be a number")
        assert.has_error(function() utils.checkArrayValuesAnyFloat("", "", 0, function() end) end, "startIndex must be a number")
        assert.has_error(function() utils.checkArrayValuesAnyFloat("", 0, nil, function() end) end, "count must be a number")
        assert.has_error(function() utils.checkArrayValuesAnyFloat("", 0, "", function() end) end, "count must be a number")
        assert.has_error(function() utils.checkArrayValuesAnyFloat("", 0, 0, nil) end, "verifyFunction must be a function")
        assert.has_error(function() utils.checkArrayValuesAnyFloat("", 0, 0, true) end, "verifyFunction must be a function")
    end)
end)
