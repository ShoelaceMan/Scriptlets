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

get_brightness() {
  xbacklight -get
}

set_brightness() {
  xbacklight -steps 1 -set "${1}"
}

fade_brightness() {
  xbacklight -time $fade_time -steps $fade_steps -set "${1}"
}

for displayAdapter in "/sys/class/drm/"card[0-9]"-"*; do
  adapterStatus=$(cat "$displayAdapter"/enabled)
  if [ "${adapterStatus}" == "enabled" ]; then
    if ! [ -d "${displayAdapter}/intel_backlight" ]; then
      # Detect if xsecurelock dimmer exists
      if [ -d /usr/lib/xsecurelock ]; then
        # If the above path exists, we can make a fallback dimmer that doesn't
        #  rely on intel_backlight
        dimMode="xsecurelock"
        xsl_bin="/usr/lib/xsecurelock"
        fallback_dimmer="${xsl_bin}/dimmer"
      fi
      break
    fi
  fi
done

if [ "${dimMode}" = "xsecurelock" ]; then
  # We enter here if one or more of the adapters that are enabled do not
  #  support xrandr backlight extensions
  # Set some parameters for the xsl dimmer
  export XSECURELOCK_DIM_TIME_MS="${fade_time}"
  export XSECURELOCK_WAIT_TIME_MS=14600
  ${fallback_dimmer}
elif [ "${dimMode}" = "none" ]; then
  # We don't do anything if there is no dimmer set
  :
else
  # We enter here if all of the adapters that are enabled support xrandr
  #  backlight extensions
  # Trap early-exits
  trap 'exit 0' TERM INT
  trap "set_brightness $(get_brightness); kill %%" EXIT

  fade_brightness ${min_brightness}
fi

sleep 2147483647 &
wait
