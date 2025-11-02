#!/bin/bash

pipe=/tmp/tmod.pipe

echo -e "[SYSTEM] Shutdown Message set to: $TMOD_SHUTDOWN_MESSAGE"
echo -e "[SYSTEM] Save Interval set to: $TMOD_AUTOSAVE_INTERVAL minutes"

# Check Config
if [[ "$TMOD_USECONFIGFILE" == "Yes" ]]; then
    if [ -e /terraria-server/customconfig.txt ]; then
        echo -e "[!!] The tModLoader server was set to load with a config file. It will be used instead of the environment variables."
    else
        echo -e "[!!] FATAL: The tModLoader server was set to launch with a config file, but it was not found. Please map the file to /terraria-server/customconfig.txt and launch the server again."
        sleep 5s
        exit 1
    fi
else
  ./prepare-config.sh
fi

# Trapped Shutdown, to cleanly shutdown
function shutdown () {
  inject "say $TMOD_SHUTDOWN_MESSAGE"
  sleep 3s
  inject "exit"
  tmuxPid=$(pgrep tmux)
  tmodPid=$(pgrep --oldest --parent $tmuxPid)
  while [ -e /proc/$tmodPid ]; do
    sleep .5
  done
  rm $pipe
}

MODDIR="/terraria-server/Mods"
mkdir -p "$MODDIR"

# -------------------
# Download Mods
# -------------------
if test -z "${TMOD_AUTODOWNLOAD}" ; then
    echo -e "[SYSTEM] No mods to download. If you wish to download mods at runtime, please set the TMOD_AUTODOWNLOAD environment variable equal to a comma separated list of Mod Workshop IDs."
    echo -e "[SYSTEM] For more information, please see the Github README."
    sleep 5s
else
    echo -e "[SYSTEM] Writing Mod IDs to install.txt..."

    echo "$TMOD_AUTODOWNLOAD" | tr "," "\n" > "$MODDIR/install.txt"
    ./manage-tModLoaderServer.sh install-mods --folder /terraria-server
    echo -e "[SYSTEM] Finished writing install.txt"
fi

# -------------------
# Enable Mods
# -------------------
enabledpath="$MODDIR/enabled.json"
modpath="/terraria-server/steamapps/workshop/content/1281930"

if test -z "${TMOD_ENABLEDMODS}" ; then
    echo -e "[SYSTEM] The TMOD_ENABLEDMODS environment variable is not set. Defaulting to the mods specified in $enabledpath"
    echo -e "[SYSTEM] To change which mods are enabled, set the TMOD_ENABLEDMODS environment variable to a comma separated list of mod Workshop IDs."
    echo -e "[SYSTEM] For more information, please see the Github README."
    sleep 5s
else
    rm -f "$enabledpath"
    touch "$enabledpath"

    echo -e "[SYSTEM] Enabling Mods specified in the TMOD_ENABLEDMODS Environment variable..."
    echo '[' >> "$enabledpath"

    echo "$TMOD_ENABLEDMODS" | tr "," "\n" | while read LINE
    do
        echo -e "[SYSTEM] Enabling $LINE..."

        modfile=$(find "$modpath/$LINE" -name '*.tmod' | sort | uniq | tail -n 1)
        modname=$(basename "${modfile%.tmod}")

        if [ -z "$modfile" ]; then
            echo -e "[!!] Mod ID $LINE not found! Has it been downloaded?"
            continue
        fi

        cp -f "$modfile" /terraria-server/Mods/

        if [ $? -ne 0 ]; then
            echo -e "[!!] Falha ao copiar o mod $modname de $modfile"
            continue
        fi

        echo "  \"$modname\"," >> "$enabledpath"
        echo -e "[SYSTEM] Enabled $modname ($LINE)"
    done

    sed -i '$ s/,$//' "$enabledpath"
    echo ']' >> "$enabledpath"
    echo -e "\n[SYSTEM] Finished loading mods."
fi



# Startup command
server="./manage-tModLoaderServer.sh docker --folder /terraria-server"

# Trap the shutdown
trap shutdown TERM INT
echo -e "tModLoader is launching with the following command:"
echo -e $server

# Check if the pipe exists already and remove it.
if [ -e "$pipe" ]; then
  rm $pipe
fi

# Create the tmux and pipe, so we can inject commands from 'docker exec [container id] inject [command]' on the host
sleep 5s
mkfifo $pipe
tmux new-session -d "$server | tee $pipe"

# Call the autosaver
/terraria-server/autosave.sh &

# Infinitely print the contents of the pipe, so the container still logs the Terraria Server.
cat $pipe &
wait ${!}
