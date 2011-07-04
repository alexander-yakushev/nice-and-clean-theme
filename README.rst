Install
=======
Install this awesome theme as normal. Place the nice-and-clean-theme directory
in your themes directory, such as ~/.config/awesome/themes, and update your 
rc.lua file::

    beautiful.init("path/to/themes/nice-and-clean-theme/theme.lua")

Widgets are done with native awesome wiboxes. They may not work with
your awesome version (my version is 3.4.5). Weather widget is done
using conkyForecast script (not included in this package).

Note: RAM usage and CPU usage widgets are not updated automatically
because I update them from my statusbar Vicious widgets (to consume
less resources). To make them independent you should rewrite their
body so they parse files /proc/cpuinfo, /proc/meminfo and temperature
themselves.

Calendar and todo is done using
https://awesome.naquadah.org/wiki/Orglendar_widget . You can scroll
the calendar to switch months.

About
=====
Inspired by https://awesome.naquadah.org/wiki/Nice_and_Clean_Theme .
