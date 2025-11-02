# Builder is ubuntu-based because we need i386 libs
FROM ghcr.io/sonroyaalmerol/steamcmd-arm64:root AS builder

# The TMOD Version. Ensure that you follow the correct format. Version releases can be found at https://github.com/tModLoader/tModLoader/releases if you're lost.
ARG TMOD_VERSION=v2025.09.3.0

# Sends update messages to the console before launch.
ENV UPDATE_NOTICE="true"

# The shutdown message is broadcast to the game chat when the container was stopped from the host.
ENV TMOD_SHUTDOWN_MESSAGE="Server is shutting down NOW!"

# The autosave feature will save the world periodically. The interval is in minutes.
ENV TMOD_AUTOSAVE_INTERVAL="10"

# Mods which should be downloaded from Steam upon starting the server.
# Example format: 2824688072,2824688266,2835214226
ENV TMOD_AUTODOWNLOAD=""

# The mods we want to enable on the server on startup. Any omitted mods will not be loaded.
# Example format: 2824688072,2824688266,2835214226
ENV TMOD_ENABLEDMODS=""

# If you want to specify your own config, set the following to "Yes".
ENV TMOD_USECONFIGFILE="No"

#--------- CONFIG SECTION --------- #
# The following environment variables will configure common settings for the tModLoader server.

# motd
ENV TMOD_MOTD="A tModLoader server powered by Docker!"
# password
ENV TMOD_PASS="docker"
# maxplayers
ENV TMOD_MAXPLAYERS="8"
# worldname
ENV TMOD_WORLDNAME="Docker"
# autocreate
ENV TMOD_WORLDSIZE="3"
# seed
ENV TMOD_WORLDSEED="Docker"
# difficulty
ENV TMOD_DIFFICULTY="1"
# secure
ENV TMOD_SECURE="0"
# language
ENV TMOD_LANGUAGE="en-US"
# npcstream
ENV TMOD_NPCSTREAM="60"
# upnp
ENV TMOD_UPNP="0"
# priority
ENV TMOD_PRIORITY="1"
# port
ENV TMOD_PORT="7777"

# JOURNEY MODE POWER PERMISSIONS

# journeypermission_time_setfrozen
ENV TMOD_JOURNEY_SETFROZEN="0"
# journeypermission_time_setdawn
ENV TMOD_JOURNEY_SETDAWN="0"
# journeypermission_time_setnoon
ENV TMOD_JOURNEY_SETNOON="0"
# journeypermission_time_setdusk
ENV TMOD_JOURNEY_SETDUSK="0"
# journeypermission_time_setmidnight
ENV TMOD_JOURNEY_SETMIDNIGHT="0"
# journeypermission_godmode
ENV TMOD_JOURNEY_GODMODE="0"
# journeypermission_wind_setstrength
ENV TMOD_JOURNEY_WIND_STRENGTH="0"
# journeypermission_rain_setstrength
ENV TMOD_JOURNEY_RAIN_STRENGTH="0"
# journeypermission_time_setspeed
ENV TMOD_JOURNEY_TIME_SPEED="0"
# journeypermission_rain_setfrozen
ENV TMOD_JOURNEY_RAIN_FROZEN="0"
# journeypermission_wind_setfrozen
ENV TMOD_JOURNEY_WIND_FROZEN="0"
# journeypermission_increaseplacementrange
ENV TMOD_JOURNEY_PLACEMENT_RANGE="0"
# journeypermission_setdifficulty
ENV TMOD_JOURNEY_SET_DIFFICULTY="0"
# journeypermission_biomespread_setfrozen
ENV TMOD_JOURNEY_BIOME_SPREAD="0"
# journeypermission_setspawnrate
ENV TMOD_JOURNEY_SPAWN_RATE="0"

# [!!!] The section for using a config file has been deprecated in favor of the environment variable approach.
# Loading a configuration file expects a proper Terraria config file to be mapped to /root/terraria-server/serverconfig.txt
# Set this to "Yes" if you would rather use a config file instead of the above settings.
# ENV TMOD_USECONFIGFILE="No"

RUN mv /home/steam/steamcmd/steamcmd.sh /home/steam/steamcmd/steamcmd && \
    chmod +x /home/steam/steamcmd/steamcmd

ENV PATH="/home/steam/steamcmd:${PATH}"

RUN apt-get update \
    && apt-get install -y wget unzip tmux bash libsdl2-2.0-0 ca-certificates libicu-dev \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /data
RUN mkdir /data/tModLoader
RUN mkdir /data/tModLoader/Worlds
RUN mkdir /data/tModLoader/Mods
RUN mkdir /data/steamMods

EXPOSE 7777

WORKDIR /terraria-server

RUN wget https://github.com/tModLoader/tModLoader/releases/download/${TMOD_VERSION}/tModLoader.zip
RUN unzip -o tModLoader.zip \
    && rm tModLoader.zip

COPY DotNetInstall.sh ./LaunchUtils
COPY entrypoint.sh .
COPY inject.sh /usr/local/bin/inject
COPY autosave.sh .
COPY prepare-config.sh .

RUN chmod 755 ./LaunchUtils/DotNetInstall.sh \
    && chmod 755 ./LaunchUtils/ScriptCaller.sh \
    && chmod 755 ./entrypoint.sh \
    && chmod 755 ./autosave.sh \
    && chmod 755 /usr/local/bin/inject \
    && chmod 755 ./prepare-config.sh \
    && chmod 755 ./start-tModLoaderServer.sh

RUN ./LaunchUtils/DotNetInstall.sh

RUN chown -R steam:steam /terraria-server /data

USER steam
# github runners has problems with it
#RUN steamcmd +login anonymous +quit
ENTRYPOINT ["./entrypoint.sh"]
