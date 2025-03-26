#!/bin/bash
#
## CONFIGURATION ##############################################################
# Brightness will be lowered to this value.
min_brightness=10
# If your video driver works with xbacklight, set -time and -steps for fading
# to $min_brightness here. Setting steps to 1 disables fading.
fade_time=400
fade_steps=20
###############################################################################
## Constants ##################################################################
# Only change these if you know what you're doing
# This is meant to change later in the script, but we can default to 'none'
dimMode="none"
# This is a parameter for xsecurelock
xsecurelockWaitTime=14600
###############################################################################

get_brightness() {
  xbacklight -get
}

set_brightness() {
  xbacklight -steps 1 -set "${1}"
}

fade_brightness() {
  xbacklight -time $fade_time -steps $fade_steps -set "${1}"
}

# Main loop for detection logic, try to set the mode to xbacklight if possible
#  but fall back to alternative methods as implemented
for displayAdapter in "/sys/class/drm/"card[0-9]"-"*; do
  adapterStatus=$(cat "$displayAdapter"/enabled)
  echo "Adapter ${displayAdapter}: ${adapterStatus}"
  # Check if every adapters upports xrandr backlight extensions
  if [ "${adapterStatus}" == "enabled" ]; then
    if xbacklight -get; then
      # We can just set this for every enabled adapter and break later if we
      #  detect one that doesn't support the extension
      dimMode="xbacklight"
    else
      # Detect if xsecurelock dimmer exists
      if [ -d /usr/lib/xsecurelock ]; then
        # If the above path exists, we can make a fallback dimmer that doesn't
        #  rely on intel_backlight
        dimMode="xsecurelock"
        xsl_bin="/usr/lib/xsecurelock"
        fallback_dimmer="${xsl_bin}/until_nonidle ${xsl_bin}/dimmer"
      else
        # No dimmer if there is no available alternative
        dimMode="none"
      fi
      break
    fi
  fi
done

echo "Dimmer set to mode: ${dimMode}"

if [ "${dimMode}" = "xbacklight" ]; then
  # We enter here if all of the adapters that are enabled support xrandr
  #  backlight extensions
  # Trap early-exits
  trap 'exit 0' TERM INT
  # Ignore this linter error, as we actually want the value to expand now,
  #  or the backlight will not return to the original value on early-exit
  # shellcheck disable=2064
  trap "set_brightness $(get_brightness); kill %%" EXIT
  fade_brightness ${min_brightness}
elif [ "${dimMode}" = "xsecurelock" ]; then
  # We enter here if one or more of the adapters that are enabled do not
  #  support xrandr backlight extensions
  # Set some parameters for the xsl dimmer
  export XSECURELOCK_DIM_TIME_MS="${fade_time}"
  export XSECURELOCK_WAIT_TIME_MS="${xsecurelockWaitTime}"
  ${fallback_dimmer}
elif [ "${dimMode}" = "none" ]; then
  # We don't do anything if there is no dimmer set
  :
fi

sleep 2147483647 &
wait
