# vwincolorswitch
A set of scripts used to change and schedule changes theme color for Windows.

Some background:

  > Windows distinguishes **theme** from **color** settings. Specifically, a theme composes of background and things _including_ the color. Changing the color setting will not change the theme. Changing a theme _may_ change the color setting.
  >
  > Some (not all) themes include switching colors between light and dark depending on the time.
  > These scripts are useful if you use a theme that **does not** already update the color setting automatically and you want that feature.

These scripts will allow you to set up scheduled tasks to switch the **system 
color mode** between "light" and "dark" depending on the time of day.

Specifically, around sunrise, the color mode will switch to "light," and
around sunset, the color mode will switch to "dark."

There are also some scripts to immediately switch to light or dark for situations when you just want to switch colors outside their scheduled times.


## How to get everything started:
- Find your latitude and longitude on the planet (search for 
  "how to find longitude and latitude" online) or ask your favorite AI.
- Run the `install.cmd` script with the latitude and longitude 
  For example:
 
        install.cmd 37.6945519 -122.0857432

  The install.cmd script will perform the following:
  - Call out to https://api.sunrise-sunset.org to get the local times for
    sunrise and sunset based on the latitude and longitude.
  - Save a copy of the data (under `%LOCALAPPDATA%\vwincolorswitch`) for future use.
  - Set up scheduled tasks:
    - to switch the system theme to "dark" upon sunset
    and to "light" upon sunrise.
    - **periodically** check the time and switch theme to light and dark variants depending on the time.
    - **periodically** update the sunrise and sunset times cache since for most locations they change throughout the year.


## To manually switch themes, some scripts are available:

- To switch to light theme:

        light [<True|False>]

- To switch to dark theme:

        dark [<True|False>]

* **NOTE**: The task bar and Explorer windows are kinda buggy and won't always update correctly
  immediately. (They may "catch up" after a while.) To force Explorer to restart in order to pick up the new values, provide a `True` as the parameter. 
  
  However, since restarting Explorer _can be disruptive_, the parameter is optional and defaults to `False`.

## Cached sunrise/sunset times

To avoid hitting the Web endpoint too often, the sunrise and sunset times will be cached in a JSON file with a date of when the data was acquired. Every few days, the Web endpoint will be called to get an updated set of times since these times vary throughout the calendar year.

## Tinkering (Advanced Topics)

### Log Files

If you want to debug unexpected behavior, these log files are available under `%LOCALAPPDATA%\vwincolorswitch`:

- `SetScheduledTasks.txt` -- the log of checking for sunrise/sunset and scheduling (and rescheduling as needed) tasks.
- `SetThemeLight.txt` -- the log of the script (called by other scripts) to set the theme color.
- `SetThemeNow.txt` -- the log of the script to checking for sunrise/sunset and set the theme color appropriately.
- `sun_times.json` -- the cached information used by the scripts. It includes the sunrise and sunset local times. A sample of the file:

  ```
  {
    "sunset":  "2026-01-31T17:32:26.0000000-08:00",
    "timestamp":  "2026-01-30T21:22:24.6617829-08:00",
    "sunrise":  "2026-01-31T07:11:10.0000000-08:00",
    "longitude":  "-122.0857432",
    "latitude":  "37.6945519",
    "static": false
  }
  ```

  - `sunrise` and `sunset` -- local times when the colors will switch to light and dark settings, respectively. The values are in ISO-8601 date-time-with-offset format.
  - `timestamp` -- the date/time when this JSON file was last updated.
  - `longitude` and `latitude` -- the location at which the sunrise and sunset times are applicable.
  - `static` -- whether the sunrise and sunset times will be periodically updated automatically throughout the year. If `false` (default), then the times will be periodically updated automatically.

### Disabling sunrise/sunset time updates

If you want to just use a set sunrise and sunset time permanently (or choose to **control these manually**):

- Modify `sun_times.json` to add/set the `static` property to `true`:
  ```
  {
    ...
    "sunrise":  "2026-01-31T07:00:00.0000000-08:00",
    "sunset":  "2026-01-31T18:00:00.0000000-08:00",
    ...
    "static": true
  }
  ```
- Edit the `sunrise` and `sunset` times to when you want to change colors to light and dark, respectively. Note that these values are in ISO-8601 date-time-with-UTC-offset format.

In the example above, the scripts will change color to light at 07:00 PST and to dark at 18:00 PST.

#### Daylight-Savings
During daylight savings times where they are applicable (America/Los_Angeles in this example), the times will be _effectively_ 08:00 PDT and 19:00 PDT, respectively (because the values are still be 8 hours behind UTC), _unless_ the times are updated to reflect the correct PDT times (i.e. change the UTC offset to `-07:00`).

Therefore, if you plan to manage the start/end times manually and are in an area where daylight-savings time is in effect, then you should modify these times twice annually when switching from standard to daylight times and vice versa.

💡 An alternative is to find a pair of times that you can work with all year long across the two standards.

## Reset

  If things get to a stuck state, here's how to reset everything:
  * Delete everything under `%LOCALAPPDATA%\vwincolorswitch`.
  * Run `install.cmd` with your longitude and latitude.

