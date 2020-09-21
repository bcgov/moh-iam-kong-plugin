local helpers = require "spec.helpers"
local cjson   = require "cjson"

local jwt_decoder = require "kong.plugins.jwt.jwt_parser"
local jwt_encoder = jwt_decoder.encode

local PLUGIN_NAME = "myplugin"

-- These tokens were generated on https://jwt.io/
-- You can read them by pasting the token (without "Bearer") there
STANDARD_JWT = 'Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJwdG1aOTAxOXFaZU5xdS1kWmQ5YlBBdnlRVm1KMGgtblNDS0djN1J6SXAwIn0.eyJleHAiOjE2MDA0NDc1NDYsImlhdCI6MTYwMDQ0NzI0NiwianRpIjoiZDY4ZGQwNzgtZTFlOS00NTIyLTkwMzgtYzMxMTM0MTMxNmQ0IiwiaXNzIjoiaHR0cHM6Ly9jb21tb24tbG9nb24tZGV2LmhsdGguZ292LmJjLmNhL2F1dGgvcmVhbG1zL21vaF9hcHBsaWNhdGlvbnMiLCJhdWQiOiJhY2NvdW50Iiwic3ViIjoiMWRhMTdiMjEtZmNiMi00MTc5LWI1OTAtZGJiYzhiMTRhYzQzIiwidHlwIjoiQmVhcmVyIiwiYXpwIjoia29uZ3Rlc3QiLCJzZXNzaW9uX3N0YXRlIjoiZGI0NWYwZGEtY2Q4ZS00ZDU4LWE3ZGItYzEyYWNjMmVlZTNhIiwiYWNyIjoiMSIsInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJvZmZsaW5lX2FjY2VzcyIsInVtYV9hdXRob3JpemF0aW9uIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnsiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsIm1hbmFnZS1hY2NvdW50LWxpbmtzIiwidmlldy1wcm9maWxlIl19fSwic2NvcGUiOiJwcm9maWxlIGVtYWlsIiwiY2xpZW50SG9zdCI6IjE0Mi4zNC4xNDcuNCIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiY2xpZW50SWQiOiJrb25ndGVzdCIsInByZWZlcnJlZF91c2VybmFtZSI6InNlcnZpY2UtYWNjb3VudC1rb25ndGVzdCIsImNsaWVudEFkZHJlc3MiOiIxNDIuMzQuMTQ3LjQifQ.P9j4rcKrGcuArNRZXte8n_tSxLh9JhqlYE7m5GNjs7R7mCcbtmXjSymurJUkD_5sOUu3E1sYKvui7oIgGJUD3PN4qNSGxLRjMl6-Lg97VAnR2o6w5y8jrKyrtvB7uXh_nbm52A0pxnD6-QSs2iH8CEzMwDbshVYCm-LAu0MvTU4A3EmBSzITPN7wIxnDk9_VqvW48TmweKtHALqoVFbyZnCtQq71QpxjwyzXkbP_OVAYbcdkN91L4WQx418oL6gpo1FMea24-UYl71DqBaNns-0JTbZ0XBWays6gUgDJbatbXZs4ehC62U3TjNlNVsrcz275tZB-S0anBgn7M-sJ3Q'
BAD_AUD_JWT = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6InB0bVo5MDE5cVplTnF1LWRaZDliUEF2eVFWbUowaC1uU0NLR2M3UnpJcDAifQ.eyJleHAiOjE2MDA0NDc1NDYsImlhdCI6MTYwMDQ0NzI0NiwianRpIjoiZDY4ZGQwNzgtZTFlOS00NTIyLTkwMzgtYzMxMTM0MTMxNmQ0IiwiaXNzIjoiaHR0cHM6Ly9jb21tb24tbG9nb24tZGV2LmhsdGguZ292LmJjLmNhL2F1dGgvcmVhbG1zL21vaF9hcHBsaWNhdGlvbnMiLCJhdWQiOiJiYWRfYXVkIiwic3ViIjoiMWRhMTdiMjEtZmNiMi00MTc5LWI1OTAtZGJiYzhiMTRhYzQzIiwidHlwIjoiQmVhcmVyIiwiYXpwIjoia29uZ3Rlc3QiLCJzZXNzaW9uX3N0YXRlIjoiZGI0NWYwZGEtY2Q4ZS00ZDU4LWE3ZGItYzEyYWNjMmVlZTNhIiwiYWNyIjoiMSIsInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJvZmZsaW5lX2FjY2VzcyIsInVtYV9hdXRob3JpemF0aW9uIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnsiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsIm1hbmFnZS1hY2NvdW50LWxpbmtzIiwidmlldy1wcm9maWxlIl19fSwic2NvcGUiOiJwcm9maWxlIGVtYWlsIiwiY2xpZW50SG9zdCI6IjE0Mi4zNC4xNDcuNCIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiY2xpZW50SWQiOiJrb25ndGVzdCIsInByZWZlcnJlZF91c2VybmFtZSI6InNlcnZpY2UtYWNjb3VudC1rb25ndGVzdCIsImNsaWVudEFkZHJlc3MiOiIxNDIuMzQuMTQ3LjQifQ.uM_1CGX_nDdP2nOFHfCACqo7P_KWrcOsCDOVR53lyDk'
MULTIPLE_AUD_JWT = 'Bearer eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJwdG1aOTAxOXFaZU5xdS1kWmQ5YlBBdnlRVm1KMGgtblNDS0djN1J6SXAwIn0.eyJleHAiOjE2MDA0NzQwMDYsImlhdCI6MTYwMDQ3MzcwNiwianRpIjoiMTI5NTQxNjItNDI4Ny00ZjVjLTljMjYtYTc4ZmJmMjMwNzI0IiwiaXNzIjoiaHR0cHM6Ly9jb21tb24tbG9nb24tZGV2LmhsdGguZ292LmJjLmNhL2F1dGgvcmVhbG1zL21vaF9hcHBsaWNhdGlvbnMiLCJhdWQiOlsiaGltb20iLCJhY2NvdW50Il0sInN1YiI6IjFkYTE3YjIxLWZjYjItNDE3OS1iNTkwLWRiYmM4YjE0YWM0MyIsInR5cCI6IkJlYXJlciIsImF6cCI6Imtvbmd0ZXN0Iiwic2Vzc2lvbl9zdGF0ZSI6ImZiOGIxYTJlLTQ0MTgtNDFhZC1hNmZjLTFhODJiMjI5YjNkYyIsImFjciI6IjEiLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsib2ZmbGluZV9hY2Nlc3MiLCJ1bWFfYXV0aG9yaXphdGlvbiJdfSwicmVzb3VyY2VfYWNjZXNzIjp7ImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY291bnQiLCJtYW5hZ2UtYWNjb3VudC1saW5rcyIsInZpZXctcHJvZmlsZSJdfX0sInNjb3BlIjoicHJvZmlsZSBlbWFpbCIsImNsaWVudEhvc3QiOiIxNDIuMzQuMTQ3LjQiLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImNsaWVudElkIjoia29uZ3Rlc3QiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJzZXJ2aWNlLWFjY291bnQta29uZ3Rlc3QiLCJjbGllbnRBZGRyZXNzIjoiMTQyLjM0LjE0Ny40In0.WFhiQ0_k-euTukHn3-qZlwttzxZKH8IAkzw4HAY3j7E3xxsY-7bvr4K8MBWdyOSGrMv7hyEjQKP6lljMBrFJ1vGFek47dl_scd4YG6VRe65TfCT4dA4xTWB20n3YL6rDJ1MiFV-B2NKWXqt9Mpw3XnUl8VI4l_nlvdAMv7QsqA1vVlXUSUskPxIOKsM1tWs2gDVOBnht-VZgGSA5VySSwRalGeBG_NkdKkzjtd-FOIU3ZexiiEr-gCHKEJPUvR-_k9-6cy9JPwBCcXCSWN5ekdFTN0qG-R_loCZqPdFQXNV5Z4Qsru7RZgU6i1IVn5D4gHJdA9wLtcAC_p-D8mGWog'
MISSING_AUD_JWT = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6InB0bVo5MDE5cVplTnF1LWRaZDliUEF2eVFWbUowaC1uU0NLR2M3UnpJcDAifQ.eyJleHAiOjE2MDA0NzUzNzIsImlhdCI6MTYwMDQ3NTA3MiwianRpIjoiOGJjYmE1OTUtMjZmMy00MTIxLWE4MzktYzRkZWU1OTQ1ODY2IiwiaXNzIjoiaHR0cHM6Ly9jb21tb24tbG9nb24tZGV2LmhsdGguZ292LmJjLmNhL2F1dGgvcmVhbG1zL21vaF9hcHBsaWNhdGlvbnMiLCJzdWIiOiIxZGExN2IyMS1mY2IyLTQxNzktYjU5MC1kYmJjOGIxNGFjNDMiLCJ0eXAiOiJCZWFyZXIiLCJhenAiOiJrb25ndGVzdCIsInNlc3Npb25fc3RhdGUiOiIxYjliZDY2OC00ODEwLTRkYTUtOGUwZC1kNTlhZmJhNTliNTMiLCJhY3IiOiIxIiwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbIm9mZmxpbmVfYWNjZXNzIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJhY2NvdW50Ijp7InJvbGVzIjpbIm1hbmFnZS1hY2NvdW50IiwibWFuYWdlLWFjY291bnQtbGlua3MiLCJ2aWV3LXByb2ZpbGUiXX19LCJzY29wZSI6InByb2ZpbGUgZW1haWwiLCJjbGllbnRIb3N0IjoiMTQyLjM0LjE0Ny40IiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJjbGllbnRJZCI6Imtvbmd0ZXN0IiwicHJlZmVycmVkX3VzZXJuYW1lIjoic2VydmljZS1hY2NvdW50LWtvbmd0ZXN0IiwiY2xpZW50QWRkcmVzcyI6IjE0Mi4zNC4xNDcuNCJ9.X4y6afnR2eUHvq9BIdyGiaOGM74oHXZnbMyKGMaNrOA'

for _, strategy in helpers.each_strategy() do
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()

      local bp = helpers.get_db_utils(strategy, nil, { PLUGIN_NAME })

      -- Inject a test route. No need to create a service, there is a default
      -- service which will echo the request.
      local route1 = bp.routes:insert({
        hosts = { "test1.com" },
      })
      -- add the plugin to test to the route we created
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route1.id },
        config = {},
      }

      -- start kong
      assert(helpers.start_kong({
        -- set the strategy
        database   = strategy,
        -- use the custom test template to create a local mock server
        nginx_conf = "spec/fixtures/custom_nginx.template",
        -- make sure our plugin gets loaded
        plugins = "bundled," .. PLUGIN_NAME,
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)

        -- TODO so this works but I think it's a pain to put the whole payload in there?
        -- local testit = jwt_encoder(
        --   {
        --     somevalue = "test", 
        --     realm_access = { 
        --       roles = { "offline_access", "uma_auth" }
        --     }
        --   }, 
        --   'somekey', 
        --   'HS256', 
        --   { alg = "RS256", typ = "JWT", kid = "ptmZ9019qZeNqu-dZd9bPAvyQVmJ0h-nSCKGc7RzIp0"}
        -- )
        -- print(testit)

    describe("authorization", function()

      it("requires JWT", function()
        local r = client:get("/request", {
          headers = {
            host = "test1.com"
          }
        })

        local body = assert.res_status(400, r)
        assert.same({error = "invalid_request", error_description = "Missing JWT"}, cjson.decode(body))
      end)

      it("given bad audience expects 403", function()
          local r = client:get("/request", {
            headers = {
              host = "test1.com",
              Authorization = BAD_AUD_JWT
            }
          })

          local body = assert.res_status(403, r)
          assert.same({error = "invalid_token", error_description = "Wrong audience"}, cjson.decode(body))
      end)

      it("given multiple audiences including valid expects 200", function()
          local r = client:get("/request", {
            headers = {
              host = "test1.com",
              Authorization = MULTIPLE_AUD_JWT
            }
          })

          local body = assert.res_status(200, r)
      end)

      it("requires audience", function()
          local r = client:get("/request", {
            headers = {
              host = "test1.com",
              Authorization = MISSING_AUD_JWT
            }
          })

          local body = assert.res_status(400, r)
          assert.same({error = "invalid_request", error_description = "Missing audience"}, cjson.decode(body))
      end)
    
    end)

  end)
end
