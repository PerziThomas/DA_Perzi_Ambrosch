---
title: Development of a Full-Stack Geofencing Application 
author: David Ambrosch & Thomas Perzi
...

# I. Eidesstattliche Erklärung {-}
Lorem Ipsum


# II. Acknowledgment {-}
Lorem Ipsum


# III. Abstract {-}
Lorem Ipsum


# IV. Kurzfassung {-}
Lorem Ipsum


## Use Cases
Lorem Ipsum


# User Interface & User Experience
Lorem Ipsum


## Requirements
To get an overview of all needed functionality, a basic list of use-cases was written.

- user login
- user registration? (or admin dashboard)
- view geofences
- create geofence (polygon/rectangle, circle)
  - persistence separately (first create, then 'commit')?
- edit geofence
  - if circle has to be editable as Center and radius, it can't be stored as a polygon in DB
- delete geofence
- set activation days for geofence + alarm when geofence is left in active period
- view driveboxes
  - view trips (per drivebox)
- analyse finished trips of driveboxes
- -> show entries/exits of all geofences crossed (timestamps + stay duration)
- -> show route on map?
- general settings
  - set default coordinates / zoom level of map? ...
- account

[comment]: <> (This is a list made when we started working, maybe it should be updated to include all current functionality)


## Mockup
Lorem Ipsum


## Mobile compatibility
The geofence management application would mainly be used on PCs, and sometimes on tablets. Smaller devices like smartphones could therefore be neglected.

The UI consists of a map on the left and a sidebar on the right, which starts at a width of 410px, but can be dragged to any size between 410px and 120px less than the total window width.

The drawing tools from _leaflet-draw_ were tested briefly on a touchscreen device, and all basic functionality appears to be present.\
Since geofences would mainly be drawn and edited on PC, no further attempt was made to improve the drawing experience on touchscreens.


## Specific elements
Lorem Ipsum


### Confirmation dialogs
Lorem Ipsum


### Plural(s) in UI
Lorem Ipsum


### Remove vs Delete
Lorem Ipsum


### Use of ellipsis
Lorem Ipsum


## Integration into DriveBox
Since the Geofencing app was developed to be integrated into the DriveBox application by the company, the look and feel of the User Interface had to be adapted. This mainly means three things:

- Using a light theme instead of a dark theme
- Using shadows instead of borders for cards
- Using blue (specifically the companies brand colour) for accents

![UI Mockup before adaptations for integration.](source/figures/UI_Integration_before.jpg "Screenshot"){#fig:stress_one width=90%}
\ 

![UI Mockup after adaptations for integration.](source/figures/UI_Integration_after.jpg "Screenshot"){#fig:stress_one width=90%}
\ 
