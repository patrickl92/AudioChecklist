describe("Preferences", function()
    local preferences
    local utils

    setup(function()
        preferences = require "audiochecklist.preferences"
        utils = require "audiochecklist.utils"

        stub.new(utils, "logDebug")
        stub.new(utils, "logInfo")
    end)

    teardown(function()
        utils.logDebug:revert()
        utils.logInfo:revert()

        preferences = nil
        utils = nil
    end)

    after_each(function()
        preferences.clear()
    end)

    it("should escape a string", function()
        assert.are.equal("no_escape", preferences.escapeString("no_escape"))
        assert.are.equal("no escape", preferences.escapeString("no escape"))
        assert.are.equal("es__cape_d", preferences.escapeString("es==cape=d"))
        assert.are.equal("es__caped", preferences.escapeString("es\n\ncaped"))
        assert.are.equal("es__cape_d", preferences.escapeString("es=\ncape=d"))
    end)

    it("should set and get a preference", function()
        preferences.set("A", "B")
        assert.are.equal("B", preferences.get("A"))
    end)

    it("should set and get a preference with default value", function()
        preferences.set("A", "B")
        assert.are.equal("B", preferences.get("A", "C"))
    end)

    it("should override existing preferences", function()
        preferences.set("A", "B")
        preferences.set("A", "C")
        assert.are.equal("C", preferences.get("A"))
    end)

    it("should remove a preference if a nil value is set", function()
        preferences.set("A", "B")
        preferences.set("A", nil)
        assert.is_nil(preferences.get("A"))
    end)

    it("should throw an error if a wrong key is given for setting a preference", function()
        assert.has_error(function() preferences.set(nil, "A") end, "key must be a string")
        assert.has_error(function() preferences.set(0, "A") end, "key must be a string")
        assert.has_error(function() preferences.set("A=", "A") end, "key must not contain a '='")
        assert.has_error(function() preferences.set("=A", "A") end, "key must not contain a '='")
        assert.has_error(function() preferences.set("A=B", "A") end, "key must not contain a '='")
        assert.has_error(function() preferences.set("A\n", "A") end, "key must not contain a '\\n'")
        assert.has_error(function() preferences.set("\nA", "A") end, "key must not contain a '\\n'")
        assert.has_error(function() preferences.set("A\nB", "A") end, "key must not contain a '\\n'")
    end)

    it("should throw an error if a wrong value is given for setting a preference", function()
        assert.has_error(function() preferences.set("A", 0) end, "value must be a string")
        assert.has_error(function() preferences.set("A", "B\n") end, "value must not contain a '\\n'")
        assert.has_error(function() preferences.set("A", "\nB") end, "value must not contain a '\\n'")
        assert.has_error(function() preferences.set("A", "B\nC") end, "value must not contain a '\\n'")
    end)

    it("should return nil if no default value is given for a preference which does not exist", function()
        assert.is_nil(preferences.get("A"))
    end)

    it("should return the default value if the preference does not exist", function()
        assert.are.equal("C", preferences.get("A", "C"))
    end)

    it("should throw an error if a wrong default value is given for getting a preference", function()
        assert.has_error(function() preferences.get("A", 0) end, "defaultValue must be a string")
    end)

    it("should remove a preference", function()
        preferences.set("A", "B")
        preferences.set("B", "C")
        preferences.remove("A")
        assert.is_nil(preferences.get("A"))
        assert.are.equal("C", preferences.get("B"))
    end)

    it("should not throw an error if a preference is removed which does not exist", function()
        preferences.remove("NotExistingKey")
    end)

    it("should throw an error if a wrong key is given for removing a preference", function()
        assert.has_error(function() preferences.remove(nil, "A") end, "key must be a string")
        assert.has_error(function() preferences.remove(0, "A") end, "key must be a string")
    end)

    it("should remove all preference", function()
        preferences.set("A", "B")
        preferences.set("B", "C")
        preferences.clear()
        assert.is_nil(preferences.get("A"))
        assert.is_nil(preferences.get("B"))
    end)

    it("should save and load all preferences", function()
        finally(function()
            local success, msg = os.remove("files/roundtripTest.prefs")
            assert.is_true(success, "Deleting file failed: " .. (msg or ""))
        end)

        preferences.set("Key 1", "Foo bar")
        preferences.set("Key 2", "Lorem ipsum dolor sit amet, consectetur adipisici elit, sed eiusmod tempor incidunt ut labore et dolore magna aliqua.")

        preferences.save("files/roundtripTest.prefs")
        preferences.clear()
        preferences.load("files/roundtripTest.prefs")

        assert.are.equal("Foo bar", preferences.get("Key 1"))
        assert.are.equal("Lorem ipsum dolor sit amet, consectetur adipisici elit, sed eiusmod tempor incidunt ut labore et dolore magna aliqua.", preferences.get("Key 2"))
    end)

    it("should load all preferences", function()
        preferences.load("files/preferencesToLoad.prefs")

        assert.are.equal("The first value", preferences.get("The first key"))
        assert.are.equal("Lorem ipsum dolor sit amet, consectetur adipisici elit, sed eiusmod tempor incidunt ut labore et dolore magna aliqua.", preferences.get("Another key"))
        assert.are.equal("Bar", preferences.get("Foo"))
    end)

    it("should overwrite existing preferences when loading other preferences", function()
        preferences.set("Key1", "Value1")
        preferences.set("Foo", "initial")
        preferences.load("files/preferencesToLoad.prefs")

        assert.are.equal("The first value", preferences.get("The first key"))
        assert.are.equal("Lorem ipsum dolor sit amet, consectetur adipisici elit, sed eiusmod tempor incidunt ut labore et dolore magna aliqua.", preferences.get("Another key"))
        assert.are.equal("Bar", preferences.get("Foo"))
        assert.are.equal("Value1", preferences.get("Key1"))
    end)

    it("should throw an error if the file path is invalid", function()
        assert.has_error(function() preferences.load(nil) end, "filePath must be a string")
        assert.has_error(function() preferences.load(0) end, "filePath must be a string")
        assert.has_error(function() preferences.save(nil) end, "filePath must be a string")
        assert.has_error(function() preferences.save(0) end, "filePath must be a string")
    end)
end)
