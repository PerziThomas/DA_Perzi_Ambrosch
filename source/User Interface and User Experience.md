# User Interface and User Experience
The frontend should be an easily usable web-interface for managing geofences. It should also have a slick and smart user interface that can be integrated into the existing _DriveBox_-application.


## Requirements
To get an overview of all needed functionality, a basic list of needed functionalities was compiled before starting work on the app:

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

[TODO: use case diagram of updated features/use cases]
[hier wahrscheinlich verweis, use case diagram ganz am Anfang von DA]


## Mockup
Lorem Ipsum


## Mobile compatibility
The geofence management application would mainly be used on PCs, and sometimes on tablets. Smaller devices like smartphones could therefore be neglected.

The UI consists of a map on the left and a sidebar on the right, which starts at a width of 410px, but can be dragged to any size between 410px and 120px less than the total window width.

The drawing tools from _leaflet-draw_ were tested briefly on a touchscreen device, and all basic functionality appears to be present.\
Since geofences would mainly be drawn and edited on PC, no further attempt was made to improve the drawing experience on touchscreens.


## Specific design decisions
In order to improve the usability of the app and to bring it closer to a finished product which could be used in reality, numerous different aspects of User Experience Design were taken into consideration, some of which will be described in the following chapter.


### Confirmation dialogs
A confirmation dialogs is usually used when a significant action is performed. It informs the user of the action to be taken and requires them to confirm the same action a second time.\
The dialog purposely adds difficulty to performing certain actions in order to avoid triggers that happen by accident or because the user did not understand the consequences of the action. (see [@confirmationDialogs])

Standard confirmation dialogs are used in the app whenever any item is deleted, and when geofence geometry is edited. Additionally, all pop-ups that require the user to enter data, for example when creating or renaming geofences, function as confirm dialogs by offering both _confirm_ and _cancel_ options.


#### Confirm vs. Undo
An alternative to confirm dialogs are _Undo notifications_, where the action in question is not interrupted, but the user is given the option to revert any changes made afterwards, usually for a limited time.

This approach is especially useful for frequent or lightweight actions, since it does not disrupt the workflow as much. However, for actions that are irreversible, require substantial amounts of time or resources to be undone, or initiate complex changes, a confirmation dialog should be used. (see [@confirmationDialogs])

Since it was not planned to make any of the actions in the web-interface reversible, it was neither possible nor necessary to implement an _Undo_ function, and only confirmation dialogs were used.


#### Headline texts
Each confirmation dialog contains a headline, the function of which is to inform the user about the action and its consequences. Speaking from personal previous experience with different software, additional confirmation steps are often quickly "learnt" by the user, and are then performed without carefully reading the information presented in the user interface. Therefore, it is important to catch the attention of the user by using short and unambiguous texts. This is achieved in two ways: [@confirmationDialogs]

- First, by avoiding generic texts and using verbs specific to the action. The user should be able to read the dialog without any additional context.\
_Example: "Delete geofence?" instead of "Are you sure?"_

- Second, by leaving out unnecessary sentence openings or endings.\
_Example: "Delete geofence?" instead of "Do you want to delete this geofence?"_

Any additional information to the headline was deemed unnecessary, as there are no actions in the app that are complex or abstract enough to require a detailed explanation. This way, the headline is also stronger because there are less other elements in the dialog that the user could focus on.


#### Button texts
The principles for headlines also apply to the buttons in the dialog. Specifically, their meaning should be clear without additional context or significant thinking. To achieve this, descriptive verbs are used instead of generic options.\
_Example: "Delete" and "Cancel" instead of "Yes" and "No"_ 


### Use of plural forms
In software, when a label refers to a variable number of items, usually greater than or equal to one, the plural form of the item is often written statically with an "s" in brackets to account for all possibilities, e.g. _geofence(s)_.\
This is usually only a minor inconvenience for the user, but can be fixed with equally minimal effort, by using the singular form if the number of items equals one, and using the plural form otherwise. [@UIPlurals]

Additionally, in the app, when the geofence bulk delete function (chapter _Bulk operations_ [TODO: link/number]) is used with only one item (geofence) selected, the confirmation dialog is displayed like it would be for a conventional, single delete operation, including the name of the geofence instead of the number of geofences to be deleted.


### Word choice for deletion
The _New York State User Experience Toolkit_ defines the difference between the words as follows:\
"Remove and Delete are defined quite similarly, but the main difference between them is that delete means erase (i.e. rendered nonexistent or nonrecoverable), while remove denotes take away and set aside (but kept in existence)." (Source: [@NYStateUXToolkit])

Since all deletion actions in the app are destructive without an undo-option, as described in chapter _Confirm vs. Undo_ [TODO: link/number], "Delete" is used in all cases, for geofences as well as metadata entries.


### Word choice for creation
Like with deletion, there are also different words that can be used to describe a creation process.

All buttons that enable the user to create a geofence on the map, by placing points or via route finding, are labelled with "Draw". Once the drawing process is finished, "Create" indicates the actual creation of the geofence with the drawn geometry.

The action for creating a geofence from a preset is marked as "Generate", to indicate that it is not created from scratch, but as a copy of an already existing preset geofence.

In the geofence metadata dialog, the action to create a new entry is called "Add", because since metadata is a simple list of strings, no new item is **created**, and the text input itself is **added** to the list as an item.


### Use of ellipsis
Lorem Ipsum


## Multi-language support
Lorem


## Integration into DriveBox
Since the Geofencing app was developed to be integrated into the DriveBox application by the company, the look and feel of the User Interface had to be adapted. This mainly meant three things:

- Using a light theme instead of a dark theme
- Using shadows instead of borders for cards
- Using the colour blue for accents

The specific shade of blue to be used was derived from the _Drivebox_ application logo, but this was altered in some places to increase readability of the user interface.

![UI Mockup before adaptations for integration.](source/figures/UI_Integration_before.jpg "Screenshot"){#fig:stress_one width=90%}
\ 

![UI Mockup after adaptations for integration.](source/figures/UI_Integration_after.jpg "Screenshot"){#fig:stress_one width=90%}
\ 