-- If you're not sure your plugin is executing, uncomment the line below and restart Kong
-- then it will throw an error which indicates the plugin is being loaded at least.

--assert(ngx.get_phase() == "timer", "The world is coming to an end!")

---------------------------------------------------------------------------------------------
-- In the code below, just remove the opening brackets; `[[` to enable a specific handler
--
-- The handlers are based on the OpenResty handlers, see the OpenResty docs for details
-- on when exactly they are invoked and what limitations each handler has.
---------------------------------------------------------------------------------------------

local jwt_decoder = require "kong.plugins.jwt.jwt_parser"

local plugin = {
  PRIORITY = 1000, -- set the plugin priority, which determines plugin execution order
  VERSION = "0.1",
}



-- do initialization here, any module level code runs in the 'init_by_lua_block',
-- before worker processes are forked. So anything you add here will run once,
-- but be available in all workers.



---[[ handles more initialization, but AFTER the worker process has been forked/created.
-- It runs in the 'init_worker_by_lua_block'
function plugin:init_worker()

  -- your custom code here
  kong.log.debug("saying hi from the 'init_worker' handler")

end --]]



--[[ runs in the ssl_certificate_by_lua_block handler
function plugin:certificate(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'certificate' handler")

end --]]



--[[ runs in the 'rewrite_by_lua_block'
-- IMPORTANT: during the `rewrite` phase neither `route`, `service`, nor `consumer`
-- will have been identified, hence this handler will only be executed if the plugin is
-- configured as a global plugin!
function plugin:rewrite(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'rewrite' handler")

end --]]

-- copied from https://stackoverflow.com/a/27028488/201891
local function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

-- partial copy of https://github.com/gbbirkisson/kong-plugin-jwt-keycloak/blob/master/src/handler.lua
local function retrieve_token(conf)

    local authorization_header = kong.request.get_header("authorization")
    if authorization_header then
        local iterator, iter_err = ngx.re.gmatch(authorization_header, "\\s*[Bb]earer\\s+(.+)")
        if not iterator then
            return nil, iter_err
        end

        local m, err = iterator()
        if err then
            return nil, err
        end

        if m and #m > 0 then
            return m[1]
        end
    end
end

-- partial copy of https://github.com/gbbirkisson/kong-plugin-jwt-keycloak/blob/master/src/handler.lua
local function do_authentication(conf)
    -- Retrieve token
    local token, err = retrieve_token(conf)
    if err then
        kong.log.err(err)
        return kong.response.exit(500, { message = "An unexpected error occurred" })
    end

    local token_type = type(token)
    if token_type ~= "string" then
        if token_type == "nil" then
            return false, { status = 400, errors = {error = "invalid_request", error_description = "Missing JWT"} }
        elseif token_type == "table" then
            return false, { status = 401, message = "Multiple tokens provided" }
        else
            return false, { status = 401, message = "Unrecognizable token" }
        end
    end

    -- Decode token
    local jwt, err = jwt_decoder:new(token)
    if err then
        return false, { status = 401, message = "Bad token; " .. tostring(err) }
    end

    kong.log(dump(jwt))

    local audienceError = { status = 403, errors = {error = "invalid_token", error_description = "Wrong audience"} }
    local audience = jwt.claims.aud
    if (type(audience) == "string") then
        if (audience ~= "account") then
            return false, audienceError
        end
    elseif (type(audience) == "table") then
        local audiencePresent = false
        for index, value in ipairs(audience) do
            if value == "account" then
                audiencePresent = true
            end
        end
        if not audiencePresent then
            return false, audienceError
        end
    else
        return false, { status = 400, errors = {error = "invalid_request", error_description = "Missing audience"} }
    end

    return true

end

---[[ runs in the 'access_by_lua_block'
function plugin:access(plugin_conf)

  -- your custom code here
  kong.log.inspect(plugin_conf)   -- check the logs for a pretty-printed config!
  kong.log("LOG REQUEST: ", kong.request.get_raw_body())
  if (string.find(kong.request.get_raw_body(), "tyler")) then
      return kong.response.exit(403, { message = "Tyler is not allowed to use this" })
  end
  ngx.req.set_header(plugin_conf.request_header, "this is on a request")

  local ok, err = do_authentication(plugin_conf)
  if not ok then
      return kong.response.exit(err.status, err.errors or { message = err.message })
  end

end --]]

---[[ runs in the 'header_filter_by_lua_block'
function plugin:header_filter(plugin_conf)

  -- your custom code here, for example;
  ngx.header[plugin_conf.response_header] = "this is on the response"

end --]]


--[[ runs in the 'body_filter_by_lua_block'
function plugin:body_filter(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'body_filter' handler")

end --]]


--[[ runs in the 'log_by_lua_block'
function plugin:log(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'log' handler")

end --]]


-- return our plugin object
return plugin
