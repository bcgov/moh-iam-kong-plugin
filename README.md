MOH IAM Kong plugin
===================

This repository contains a plugin that does some JWT validation. It was implemented to demonstrate how Kong could be used to meet the validation requirements of HNI applications. It's based off of the [Kong plugin template](https://github.com/Kong/kong-plugin), which is designed to work with the
[`kong-pongo`](https://github.com/Kong/kong-pongo) and
[`kong-vagrant`](https://github.com/Kong/kong-vagrant) development environments.

Why not an existing plugin? An existing plugin will be used for basic JWT validation, that is checking the expiry and validating the signature, but we want to validate additional claims such as `azp`, `aud`, and `scope` with a regex. Rather than trying (and probably failing) to find a third-party plugin that validates claims _exactly_ the way we want, it's easier to write a plugin ourselves.

## Using the plugin

The [`kong-vagrant`](https://github.com/Kong/kong-vagrant) repo also contains instructions for enabling the plugin. After enabling the plugin, you will need to add an Authorization header with a JWT to make requests to the mock endpoint.

```bash
curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" http://localhost:8000/
```

To get an access token, I configured a client on our Keycloak dev server, but because this plugin only validates the `aud` claim at the moment, you use any token -- you could build one yourself at https://jwt.io.

If you want to use Keycloak, you need a confidential client with service accounts enabled. Then you can get the token from the token endpoint. An example script that does this is at [`run.sh`](run.sh).

### Features

These features are implemented for demonstration purposes. They would need to be extended and modified for a real project.

* The plugin validates the `aud` claim. It returns a 403 if `aud` does not equal `account`.
* The plugin sets the `X-Intermediary` header. The value is configurable, it defaults to `bchealth.api.gov.bc.ca`.
* The plugin ensures that the JWT is present and paresable.

## Plugin development

You can create a local development environment by following the instructions in the [`kong-vagrant`](https://github.com/Kong/kong-vagrant) repo. I won't repeat the instructions here, and you should definitely go read them! I will however clarify a few steps:

1. If you've been using Docker on Windows, you will need to disable Hyper-V before using Vagrant.
2. On the step to checkout the `kong-plugin`, checkout this repo, not the base template.
3. Rename the plugin directory to `kong-plugin`: `mv moh-iam-kong-plugin kong-plugin`.
4. After checking out the Kong repo, `cd` into the repo and switch to a specific branch: `git checkout 2.1.3`.
5. When running Vagrant, set the version with `KONG_VERSION=2.1.3 vagrant up`.

It's mentioned in the [`kong-vagrant`](https://github.com/Kong/kong-vagrant) guide, but I'll say it again here: run all commands from the /kong directory. So to start Kong, run `/kong/bin/kong start`. The Kong at `/usr/local/bin/kong` is the one that comes with the Vagrant box, not the one you checked-out.

If you followed the guide, you should have this directory structure on your host machine (Windows):

```
-some_dir
  |-kong-vagrant
     |-kong
     |-kong-plugin
```

The `kong` and `kong-plugin` directory are synced between the host and Vagrant box, so you can open plugin files in Windows and edit them. To get Kong to reload the plugin, just stop and start Kong.


## Tip

When running the tests (instructions are in the [`kong-vagrant`](https://github.com/Kong/kong-vagrant) repo), it runs the tests using both Cassandra and Postgres, which means every test runs twice. You can specify just one database with `export KONG_TEST_DATABASE=postgres`.

Remember enviroment variables won't survive restarts (e.g. `vagrant up`), but you can put them in your `.bash_profile`. You'll probably want to add `export KONG_PLUGINS=bundled,mohhnipoc` (again, instructions are in the [`kong-vagrant`](https://github.com/Kong/kong-vagrant) repo).

## Troubleshooting

### Error message: "plugin is in use but not enabled"

In addition to the troubleshooting information available on the Vagrant page, I encountered this error when trying to restart Kong after making a change to the plugin:

```bash
vagrant@ubuntu1604:/kong$ bin/kong start
Error: ./kong/cmd/start.lua:64: nginx: [warn] load balancing method redefined in /kong/servroot/nginx-kong.conf:56
nginx: [error] init_by_lua error: ./kong/init.lua:464: mohhnipoc plugin is in use but not enabled
stack traceback:
        [C]: in function 'assert'
        ./kong/init.lua:464: in function 'init'
        init_by_lua:3: in main chunk
```

I think I fixed this error simply by setting the KONG_PLUGINS environment variable, which for some reason was reset:

```bash
vagrant@ubuntu1604:/kong$ export KONG_PLUGINS=bundled,mohhnipoc
```

### curl: (60) server certificate verification failed

During `make dev` you may encounter this error:

curl: (60) server certificate verification failed. CAfile: /etc/ssl/certs/ca-certificates.crt CRLfile: none
More details here: http://curl.haxx.se/docs/sslcerts.html

This is probably due to the CGI certificates. You should be able to get around it by connecting to RNAS.

### Could not satisfy dependency compat53 (or similar errors)

If you get dependency errors from `make dev` like this one:

```
Error: Could not satisfy dependency compat53 >= 0.3: No results matching query were found for Lua 5.1.
Makefile:116: recipe for target 'dependencies' failed
make: *** [dependencies] Error 1
```

First, simply try the command again.

If you're still getting errors, try `sudo rm -rf ~/.cache/luarocks` and try again.

Try again and again. You might be getting resolvable connection timeouts on some downloads. See if you're making progress before moving on.

If you're still getting errors, make sure when you ran the first `vagrant up` you specified the Kong version as described above.

If you're *still* getting errors, try starting over with the latest version of Kong.

### Why not Pongo?

[Pongo on Windows](https://github.com/Kong/kong-pongo#pongo-on-windows) is offered as an alternative to Vagrant for plugin development. It is Docker-based and requires a newer build of Windows 10 than our CGI laptops currently have installed.

## References

* [Kong plugin template](https://github.com/Kong/kong-plugin)
* [`kong-vagrant`](https://github.com/Kong/kong-vagrant)
