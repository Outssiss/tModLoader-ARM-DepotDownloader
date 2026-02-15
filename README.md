# Fork readme:

Fork of [otomay/tmodloader1.4](https://github.com/otomay/tmodloader1.4) replacing steamcmd for DepotDownloader.

## Why This Fork?
For some reason, the version of steamcmd used on the forked was consistenyl failing on waiting for client info. This version uses the native ARM 64 version of DepotDownloader to take care of downloading the mods.
Tested on a Raspberry PI 5
---

# tModLoader Powered By Docker

This Docker Image is designed to allow for easy configuration and setup of a modded Terraria server powered by tModLoader.

## Credits
- Original implementation: [JACOBSMILE/tmodloader1.4](https://github.com/JACOBSMILE/tmodloader1.4)
- ARM64 adaptation: [otomay/tmodloader1.4](https://github.com/otomay/tmodloader1.4)

# Container Preparation

### Data Directory
Create a directory on HOST machine to house persistent files.

```bash
# Making the Data directory
mkdir /path/to/data/directory
```

```bash
# The below line is a mapped volume for the Docker container.
-v /path/to/data/directory:/data
```

Within this directory, you will find the following file structure:
```
/data/
├─ Worlds/
│  └─ YourWorld.wld
├─ Mods/
│  ├─ downloads/        (temp download folders)
│  ├─ ModName.tmod
│  └─ enabled.json
└─ ModConfigs/
```

## Downloading Mods
Every Workshop item on Steam has a unique identifier which can be found by visiting the store page directly. For example, for the [Calamity Mod](https://steamcommunity.com/sharedfiles/filedetails/?id=2824688072), you can find the Workshop ID from the URL. In this case, **2824688072** is the ID. This Docker container is capable of downloading tModLoader mods directly from the Steam Workshop to streamline the setup process.

In the environment variables passed to the container at runtime, specify the `TMOD_AUTODOWNLOAD` variable with a value of a comma separated list of the Mod IDs you wish to download.

For example, to tell the container to download Calamity and the Calamity Mod Music, specify the following variable:
```bash
-e TMOD_AUTODOWNLOAD=2824688072,2824688266
```
**This fork uses DepotDownloader instead of SteamCMD for more reliable downloads on ARM64.**

---
## Enabling Mods
To successfully run this container, it is important to understand the difference between **downloading mods** and **enabling mods**.

**Downloading** a mod simply stores it in the Steam Workshop cache, which is stored in the `/data/mods` directory. When mapping `/data` to a HOST directory, this will allow for persistence between container restarts.

**Enabling** a mod tells the container to write the Mod's name to the `enabled.json` file, which tModLoader reads during startup. A Mod must first be downloaded with the `TMOD_AUTODOWNLOAD` variable to be eligible to be enabled.

To enable a mod on the server, specify the `TMOD_ENABLEDMODS` environment variabe with a value of a comma separated list of the Mod IDs you wish to enable. 

```bash
-e TMOD_ENABLEDMODS=2824688072,2824688266
```
---
## Mod Considerations
There is no need to repeatedly download mods each time you start the container. For this reason, once you have downloaded the mods you want to include on your server, it is safe to **remove** the `TMOD_AUTODOWNLOAD` environment variable, whilst maintaining the `TMOD_ENABLEDMODS` variable to enable them during runtime. Doing so will greatly improve the startup time of the Docker container.

If mods receive updates you wish to download, include the Mod ID again in the `TMOD_AUTODOWNLOAD` variable to download the update. The next time tModLoader starts, the mod will be updated.

Additionally, you may at any time remove a mod from the `TMOD_ENABLEDMODS` variable to disable it, though this may cause problems with a world which has modded content.

# Environment Variables
The following are all of the environment variables that are supported by the container. These handle server functionality and Terraria server configurations.

| Variable      | Default Value | Description |
| ----------- | ----------- | ----------- |
| TMOD_SHUTDOWN_MESSAGE | Server is shutting down NOW! | The message which will be sent to the in-game chat upon container shutdown.
| TMOD_AUTOSAVE_INTERVAL   | 10 | The autosave interval (in minutes) in which the World will be saved.
| TMOD_AUTODOWNLOAD | N/A | A Comma Separated list of Workshop Mod IDs to download from Steam upon container startup.
| TMOD_ENABLEDMODS | N/A | A Comma Separated list of Workshop Mod IDs to enable on the tModLoader server upon startup.
| TMOD_USECONFIGFILE | No | If you wish to use a config file to specify server settings, set this variable to "Yes". Please note, this has been deprecated.
| TMOD_MOTD | A tModLoader server powered by Docker! | The Message of the Day which prints in the chat upon joining the server.
| TMOD_PASS | docker | The password players must supply to join the server. Set this variable to "N/A" to disable requiring a password on join. (Not Recommended)
| TMOD_MAXPLAYERS | 8 | The maximum number of players which can join the server at once.
| TMOD_WORLDNAME | Docker | The name of the world file. This is seen in-game as well as will be used for the name of the .WLD file.
| TMOD_WORLDSIZE | 3 | When generating a new world (and only when generating a new world), this variable will be used to designate the size. 1 = Small, 2 = Medium, 3 = Large
| TMOD_WORLDSEED | Docker | The seed for a new world.
| TMOD_DIFFICULTY | 1 | When generating a new world (and only when generating a new world), this variable will set the difficulty of the world. 0 = Normal, 1 = Expert, 2 = Master, 3 = Journey.
| TMOD_SECURE | 0 | Adds additional cheat protection.
| TMOD_LANGUAGE | en-US | Sets the language for the server. Available options are: `en-US` (English), `de-DE` (German), `it-IT` (Italian), `fr-FR` (French), `es-ES` (Spanish), `ru-RU` (Russian), `zh-Hans` (Chinese), `pt-BR` (Portuguese), `pl-PL` (Polish).
| TMOD_NPCSTREAM | 60 | Reduces enemy skipping, but increases bandwidth usage. The lower the number, the less skipping will happeb, but more data is sent. 0 is off.
| TMOD_UPNP | 0 | Automatically forwards ports with uPNP (untested, and may not work in all cases depending on network configuration)
| TMOD_PORT | 7777 | Set the port for the tModLoader server to run on within the container.

The following are environment variables which control Journey Mode settings. For all of these settings, 
* 0 = Locked for everyone 
* 1 = Only Changeable by Host
* 2 = Can be changed by everyone. 

Refer to the [Terraria Server Wiki](https://terraria.fandom.com/wiki/Server) for more information. The default setting for all of these is 0 when not explicitly set.

* TMOD_JOURNEY_SETFROZEN
* TMOD_JOURNEY_SETDAWN
* TMOD_JOURNEY_SETNOON
* TMOD_JOURNEY_SETDUSK
* TMOD_JOURNEY_SETMIDNIGHT
* TMOD_JOURNEY_GODMODE
* TMOD_JOURNEY_WIND_STRENGTH
* TMOD_JOURNEY_RAIN_STRENGTH
* TMOD_JOURNEY_TIME_SPEED
* TMOD_JOURNEY_RAIN_FROZEN
* TMOD_JOURNEY_WIND_FROZEN
* TMOD_JOURNEY_PLACEMENT_RANGE
* TMOD_JOURNEY_SET_DIFFICULTY
* TMOD_JOURNEY_BIOME_SPREAD
* TMOD_JOURNEY_SPAWN_RATE

# Running the Container

## Docker Command

```bash
# Build the image
docker build --platform linux/arm64 -t tmodloader-arm64 .

# Execute the container
docker run -p 7777:7777 --name tmodloader --rm \
  -v /path/to/data:/data \
  -e TMOD_SHUTDOWN_MESSAGE='Goodbye!' \
  -e TMOD_AUTOSAVE_INTERVAL='15' \
  -e TMOD_AUTODOWNLOAD='2824688072,2824688266' \
  -e TMOD_ENABLEDMODS='2824688072,2824688266' \
  -e TMOD_MOTD='Welcome to my tModLoader Server!' \
  -e TMOD_PASS='secret' \
  -e TMOD_MAXPLAYERS='16' \
  -e TMOD_WORLDNAME='Earth' \
  -e TMOD_WORLDSIZE='2' \
  -e TMOD_WORLDSEED='not the bees!' \
  -e TMOD_DIFFICULTY='3' \
  tmodloader-arm64
```

## Updating DepotDownloader
This Dockerfile uses a specific version of DepotDownloader. To update to a newer version:
```dockerfile
# In Dockerfile, change this line:
ARG DEPOTDOWNLOADER_VERSION=DepotDownloader_3.4.0

# To the latest version from: https://github.com/SteamRE/DepotDownloader/releases
```

Or build with a custom version:
```bash
docker build --build-arg DEPOTDOWNLOADER_VERSION=DepotDownloader_3.5.0 -t tmodloader-arm64 .
```


# Interacting with the Server

To send commands to the server once it has started, use the following command on your Host machine. The below example will send "Hello World" to the game chat.

```bash
docker exec tmodloader inject "say Hello World!"
```
You can alernatively use the UID of the container in place of `tmodloader` if you did not name your configuration.

_Credit to [ldericher](https://github.com/ldericher/tmodloader-docker) for this method of command injection to tModLoader's console._

# Notes
I do not own tModLoader or Terraria. This Docker Image was created for players to easily host a game server with Docker, and is not intended to infringe on any Copyright, Trademark or Intellectual Property.



