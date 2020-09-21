MOH IAM Kong plugin
===================

This repository contains a plugin that does some JWT validation. It was implemented to demonstrate how Kong could be used to meet the validation requirements of HNI applications. It's based off of the [Kong plugin template](https://github.com/Kong/kong-plugin), which is designed to work with the
[`kong-pongo`](https://github.com/Kong/kong-pongo) and
[`kong-vagrant`](https://github.com/Kong/kong-vagrant) development environments.

## Plugin development

You can create a local development environment by following the instructions in the [`kong-vagrant`](https://github.com/Kong/kong-vagrant) repo. I won't repeat the instructions here, but I'll clarify a few steps:

1. If you've been using Docker on Windows, you will need to disable Hyper-V before using Vagrant.
2. On the step to checkout the `kong-plugin`, checkout this repo, not the base template.
3. After checking out the Kong repo, `cd` into the repo and switch to a specific branch: `git checkout release/2.1.3`.
4. When running Vagrant, set the version with `KONG_VERSION=2.1.3 vagrant up`.

## Using the plugin

The [`kong-vagrant`](https://github.com/Kong/kong-vagrant) repo also contains instructions for enabling the plugin. After enabling the plugin, you will need to add an Authorization header with a JWT to make requests to the mock endpoint.

```bash
curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" http://localhost:8000/
```

To get an access token, I configured a client on our Keycloak dev server, but because this plugin only validates the `aud` claim at the moment, you use any token -- you could build one yourself at https://jwt.io.

If you want to use Keycloak, you need a confidential client with service accounts enabled. Then you can get the token from the token endpoint. An example script that does this is at [`run.sh`](run.sh).

## Developing the plugin

It's mentioned in the [`kong-vagrant`](https://github.com/Kong/kong-vagrant) guide, but I'll say it again here: run all commands from the /kong directory. So to start Kong, run `/kong/bin/kong start`. The kong at `/usr/local/bin/kong` is the one that comes with the Vagrant box, not the one you checked-out.

If you followed the guide, you should have this directory structure on your host machine (Windows):

```
-some_dir
  |-kong-vagrant
     |-kong
     |-kong-plugin
```

The `kong` and `kong-plugin` directory are synced between the host and Vagrant box, so you can open plugin files in Windows and edit them. To get Kong to reload the plugin, just stop and start kong.

## Troubleshooting

### Error message: "plugin is in use but not enabled"

In addition to the troubleshooting information available on the Vagrant page, I encountered this error when trying to restart Kong after making a change to the plugin:

```bash
vagrant@ubuntu1604:/kong$ bin/kong start
Error: ./kong/cmd/start.lua:64: nginx: [warn] load balancing method redefined in /kong/servroot/nginx-kong.conf:56
nginx: [error] init_by_lua error: ./kong/init.lua:464: myplugin plugin is in use but not enabled
stack traceback:
        [C]: in function 'assert'
        ./kong/init.lua:464: in function 'init'
        init_by_lua:3: in main chunk
```

I think I fixed this error simply by setting the KONG_PLUGINS environment variable, which for some reason was reset:

```bash
vagrant@ubuntu1604:/kong$ export KONG_PLUGINS=bundled,myplugin
```

### Why not Pongo?

[Pongo on Windows](https://github.com/Kong/kong-pongo#pongo-on-windows) is offerred as an alternative to Vagrant for plugin development. It is Docker-based and requires a newer build of Windows 10 than our CGI laptops currently have installed.