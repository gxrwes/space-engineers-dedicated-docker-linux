#!/bin/bash

# Check if /appdata/space-engineers/config/World is a folder
if [ ! -d "/appdata/space-engineers/World" ]; then
  echo "World folder does not exist, exiting"
  exit 129
fi

# Check if /appdata/space-engineers/config/World/Sandbox.sbc exists and is a file
if [ ! -f "/appdata/space-engineers/World/Sandbox.sbc" ]; then
  echo "Sandbox.sbc file does not exist, exiting."
  exit 130
fi

# Check if /appdata/space-engineers/config/SpaceEngineers-Dedicated.cfg is a file
if [ ! -f "/appdata/space-engineers/SpaceEngineersDedicated/SpaceEngineers-Dedicated.cfg" ]; then
  echo "SpaceEngineers-Dedicated.cfg file does not exist, exiting."
  exit 131
fi

# Set <LoadWorld> to the correct value
sed -E '/.*LoadWorld.*/c\  <LoadWorld>Z:\\appdata\\space-engineers\\World</LoadWorld>' \
  /appdata/space-engineers/SpaceEngineersDedicated/SpaceEngineers-Dedicated.cfg > /tmp/SpaceEngineers-Dedicated.cfg \
  && mv /tmp/SpaceEngineers-Dedicated.cfg /appdata/space-engineers/SpaceEngineersDedicated/SpaceEngineers-Dedicated.cfg

# Configure plugins section in SpaceEngineers-Dedicated.cfg
if [ "$(ls -1 /appdata/space-engineers/Plugins/*.dll 2>/dev/null | wc -l)" -gt "0" ]; then
  PLUGINS_STRING=$(ls -1 /appdata/space-engineers/Plugins/*.dll |\
    awk '{ print "<string>" $0 "</string>" }' |\
    tr -d '\n' |\
    awk '{ print "<Plugins>" $0 "</Plugins>" }')
else
  PLUGINS_STRING="<Plugins />"
fi

SED_EXPRESSION_EMPTY="s/<Plugins \/>/${PLUGINS_STRING////\\/} /g"
SED_EXPRESSION_FULL="s/<Plugins>.*<\/Plugins>/${PLUGINS_STRING////\\/} /g"

# Replace "<Plugins />" or "<Plugins>...</Plugins>" in the config file
sed -E "$SED_EXPRESSION_EMPTY" /appdata/space-engineers/SpaceEngineersDedicated/SpaceEngineers-Dedicated.cfg > /tmp/SpaceEngineers-Dedicated.cfg \
  && mv /tmp/SpaceEngineers-Dedicated.cfg /appdata/space-engineers/SpaceEngineersDedicated/SpaceEngineers-Dedicated.cfg
sed -E "$SED_EXPRESSION_FULL" /appdata/space-engineers/SpaceEngineersDedicated/SpaceEngineers-Dedicated.cfg > /tmp/SpaceEngineers-Dedicated.cfg \
  && mv /tmp/SpaceEngineers-Dedicated.cfg /appdata/space-engineers/SpaceEngineersDedicated/SpaceEngineers-Dedicated.cfg

# Run SteamCMD and update the game
runuser -l wine -c 'steamcmd +force_install_dir /appdata/space-engineers/SpaceEngineersDedicated +@sSteamCmdForcePlatformType windows +login anonymous +app_update 298740 validate +quit'

# Start the Space Engineers Dedicated Server
runuser -l wine -c '/entrypoint-space_engineers.bash'
