# vwincolorswitch
Scheduled color switcher for Windows

These scripts will allow you to set up scheduled tasks to switch the system 
color mode between "light" and "dark" depending on the time of day.

Specifically, around sunrise, the color mode will switch to "light," and
around sunset, the color mode will switch to "dark."

There are also some scripts to immediately switch to light or dark.


## How to get everything started:
- Find your latitude and longitude on the planet (search for 
  "how to find longitude and latitude" online)
- Run the install.cmd script with the latitude and longitude 
  For example:
 
        install 37.6945519 -122.0857432

  The install.cmd script will perform the following:
  - Call out to https://api.sunrise-sunset.org to get the local times for
    sunrise and sunset based on the latitude and longitude.
  - Save a copy of the data (under `%LOCALAPPDATA%/vwincolorswitch/`) for future use.
  - Set up scheduled tasks to switch the system theme to "dark" upon sunset
    and to "light" upon sunrise.
  - Set up scheduled task to periodically switch theme to light and dark variants 
    depending on the time.
  - Set up scheduled task to periodically update the sunrise and sunset times
    since for most locations they change throughout the year.


## To manually switch themes, some scripts are available:

- To switch to light theme:

        light [<True|False>]

- To switch to dark theme:

        dark [<True|False>]

* The task bar and Explorer windows are kinda buggy and won't update correctly
  immediately. To force Explorer to restart in order to pick up the new
  values, provide a "True" as the parameter. Since restarting Explorer can be
  disruptive, the parameter is optional and defaults to False.

## Cached sunrise/sunset times

To avoid hitting the Web endpoint too often, the sunrise and sunset times will be cached in a JSON file with a date of when the data was acquired. Every few days, the Web endpoint will be called to get an updated set of times since these times vary throughout the calendar year.
