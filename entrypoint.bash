#!/bin/bash

LOG_FILE="/appdata/space-engineers/setup.log"

echo "Starting Space Engineers server setup..." | tee -a "$LOG_FILE"

# Check if /appdata/space-engineers/config/World is a folder
if [ ! -d "/appdata/space-engineers/World" ]; then
  echo "World folder does not exist, exiting" | tee -a "$LOG_FILE"
  exit 129
else
  echo "World folder exists." | tee -a "$LOG_FILE"
fi

# Check if /appdata/space-engineers/config/World/Sandbox.sbc exists and is a file
if [ ! -f "/appdata/space-engineers/World/Sandbox.sbc" ]; then
  echo "Sandbox.sbc file does not exist, exiting." | tee -a "$LOG_FILE"
  exit 130
else
  echo "Sandbox.sbc file exists." | tee -a "$LOG_FILE"
fi

# Check if /appdata/space-engineers/config/SpaceEngineers-Dedicated.cfg is a file
if [ ! -f "/appdata/space-engineers/SpaceEngineersDedicated/SpaceEngineers-Dedicated.cfg" ]; then
  echo "SpaceEngineers-Dedicated.cfg file does not exist, exiting." | tee -a "$LOG_FILE"
  exit 131
else
  echo "SpaceEngineers-Dedicated.cfg file exists." | tee -a "$LOG_FILE"
fi

# Set <LoadWorld> to the correct value
echo "Updating <LoadWorld> path in SpaceEngineers-Dedicated.cfg..." | tee -a "$LOG_FILE"
sed -E '/.*LoadWorld.*/c\  <LoadWorld>Z:\\appdata\\space-engineers\\World</LoadWorld>' \
  /appdata/space-engineers/SpaceEngineersDedicated/SpaceEngineers-Dedicated.cfg > /tmp/SpaceEngineers-Dedicated.cfg \
  && mv /tmp/SpaceEngineers-Dedicated.cfg /appdata/space-engineers/SpaceEngineersDedicated/SpaceEngineers-Dedicated.cfg

if [ $? -eq 0 ]; then
  echo "Successfully updated <LoadWorld> in SpaceEngineers-Dedicated.cfg." | tee -a "$LOG_FILE"
else
  echo "Failed to update <LoadWorld>, exiting." | tee -a "$LOG_FILE"
  exit 132
fi

# Configure plugins section in SpaceEngineers-Dedicated.cfg
echo "Configuring plugins section..." | tee -a "$LOG_FILE"
if [ "$(ls -1 /appdata/space-engineers/Plugins/*.dll 2>/dev/null | wc -l)" -gt "0" ]; then
  PLUGINS_STRING=$(ls -1 /appdata/space-engineers/Plugins/*.dll |\
    awk '{ print "<string>" $0 "</string>" }' |\
    tr -d '\n' |\
    awk '{ print "<Plugins>" $0 "</Plugins>" }')
  echo "Plugins found and configured: $PLUGINS_STRING" | tee -a "$LOG_FILE"
else
  PLUGINS_STRING="<Plugins />"
  echo "No plugins found. Setting <Plugins />." | tee -a "$LOG_FILE"
fi

SED_EXPRESSION_EMPTY="s/<Plugins \/>/${PLUGINS_STRING////\\/} /g"
SED_EXPRESSION_FULL="s/<Plugins>.*<\/Plugins>/${PLUGINS_STRING////\\/} /g"

sed -E "$SED_EXPRESSION_EMPTY" /appdata/space-engineers/SpaceEngineersDedicated/SpaceEngineers-Dedicated.cfg > /tmp/SpaceEngineers-Dedicated.cfg \
  && mv /tmp/SpaceEngineers-Dedicated.cfg /appdata/space-engineers/SpaceEngineersDedicated/SpaceEngineers-Dedicated.cfg

if [ $? -eq 0 ]; then
  echo "Plugins section replaced successfully." | tee -a "$LOG_FILE"
else
  echo "Failed to replace <Plugins />. Exiting." | tee -a "$LOG_FILE"
  exit 133
fi

sed -E "$SED_EXPRESSION_FULL" /appdata/space-engineers/SpaceEngineersDedicated/SpaceEngineers-Dedicated.cfg > /tmp/SpaceEngineers-Dedicated.cfg \
  && mv /tmp/SpaceEngineers-Dedicated.cfg /appdata/space-engineers/SpaceEngineersDedicated/SpaceEngineers-Dedicated.cfg

if [ $? -eq 0 ]; then
  echo "Plugins section updated successfully." | tee -a "$LOG_FILE"
else
  echo "Failed to update <Plugins>. Exiting." | tee -a "$LOG_FILE"
  exit 134
fi

# Run SteamCMD and update the game
echo "Running SteamCMD to update Space Engineers..." | tee -a "$LOG_FILE"
runuser -l wine -c 'steamcmd +force_install_dir /appdata/space-engineers/SpaceEngineersDedicated +@sSteamCmdForcePlatformType windows +login anonymous +app_update 298740 validate +quit'

if [ $? -eq 0 ]; then
  echo "SteamCMD update successful." | tee -a "$LOG_FILE"
else
  echo "SteamCMD update failed. Exiting." | tee -a "$LOG_FILE"
  exit 135
fi

# Start the Space Engineers Dedicated Server
echo "Starting Space Engineers Dedicated Server..." | tee -a "$LOG_FILE"
runuser -l wine -c '/entrypoint-space_engineers.bash'

if [ $? -eq 0 ]; then
  echo "Space Engineers Dedicated Server started successfully." | tee -a "$LOG_FILE"
else
  echo "Failed to start Space Engineers Dedicated Server. Exiting." | tee -a "$LOG_FILE"
  exit 136
fi

echo "Setup completed successfully!" | tee -a "$LOG_FILE"
