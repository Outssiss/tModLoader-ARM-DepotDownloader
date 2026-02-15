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

DOWNLOADDIR="/data/Mods/downloads"
MODDIR="/data/Mods"
mkdir -p "$DOWNLOADDIR"
mkdir -p "$MODDIR"

# -------------------
# Download Mods
# -------------------
REGISTRY_FILE="$MODDIR/mod_registry.json" #Maps mod id with name

# Initialize registry if it doesn't exist
if [ ! -f "$REGISTRY_FILE" ]; then
   echo '{}' > "$REGISTRY_FILE"
fi

if test -z "${TMOD_AUTODOWNLOAD}" ; then
   echo -e "[SYSTEM] No mods to download."
   sleep 5s
else
   echo -e "[SYSTEM] Downloading mods with DepotDownloader..."
   IFS=',' read -ra MODS <<< "$TMOD_AUTODOWNLOAD"
   for mod_id in "${MODS[@]}"; do
      echo -e "[SYSTEM] Downloading mod $mod_id..."
      depotdownloader -app 1281930 -pubfile "$mod_id" -dir "$DOWNLOADDIR/$mod_id" -validate -max-downloads 4
      
      latest_version=$(find "$DOWNLOADDIR/$mod_id" -maxdepth 1 -type d -name "20*" | sort -V | tail -n 1)
      if [ -n "$latest_version" ]; then
         find "$DOWNLOADDIR/$mod_id" -maxdepth 1 -type d -name "20*" ! -path "$latest_version" -exec rm -rf {} +
         
         tmodfile=$(find "$latest_version" -type f -name "*.tmod" | head -n 1)
         if [ -n "$tmodfile" ]; then
            modname=$(basename "${tmodfile%.tmod}")
            mv -f "$tmodfile" "$MODDIR/"
            
            jq --arg id "$mod_id" --arg name "$modname" '. + {($id): $name}' "$REGISTRY_FILE" > "$REGISTRY_FILE.tmp" && mv "$REGISTRY_FILE.tmp" "$REGISTRY_FILE"
            
            echo -e "[SYSTEM] Registered $mod_id -> $modname"
            rm -rf "$DOWNLOADDIR/$mod_id"
         fi
      fi
   done
   echo -e "[SYSTEM] Finished downloading mods."
fi

# -------------------
# Enable Mods
# -------------------
enabledpath="$MODDIR/enabled.json"

if test -z "${TMOD_ENABLEDMODS}" ; then
   echo -e "[SYSTEM] The TMOD_ENABLEDMODS environment variable is not set."
   sleep 5s
else
   rm -f "$enabledpath"
   echo '[' > "$enabledpath"
   
   echo -e "[SYSTEM] Enabling Mods..."
   first=true
   IFS=',' read -ra MODS <<< "$TMOD_ENABLEDMODS"
   for mod_id in "${MODS[@]}"; do

       modname=$(jq -r --arg id "$mod_id" '.[$id] // empty' "$REGISTRY_FILE")
       
       if [ -z "$modname" ]; then
           echo -e "[!!] Mod ID $mod_id not found in registry!"
           continue
       fi
       
       if [ "$first" = false ]; then
           echo "," >> "$enabledpath"
       fi
       echo -n "  \"$modname\"" >> "$enabledpath"
       first=false
       
       echo -e "[SYSTEM] Enabled $modname ($mod_id)"
   done
   
   echo '' >> "$enabledpath"
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

# Create the tmux and pipe
sleep 5s
mkfifo $pipe
tmux new-session -d "$server | tee $pipe"

# Call the autosaver
/terraria-server/autosave.sh &

# Infinitely print the contents of the pipe
cat $pipe &
wait ${!}