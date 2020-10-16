local PLUGIN_NAME = "mohhnipoc"


-- helper function to validate data against a schema
local validate do
  local validate_entity = require("spec.helpers").validate_plugin_config_schema
  local plugin_schema = require("kong.plugins."..PLUGIN_NAME..".schema")

  function validate(data)
    return validate_entity(data, plugin_schema)
  end
end


describe(PLUGIN_NAME .. ": (schema)", function()


  it("accepts distinct request_header and response_header", function()
    local ok, err = validate({
        X_Intermediary = "My-X_Intermediary-Header",
      })
    assert.is_nil(err)
    assert.is_truthy(ok)
  end)

end)
