# User Interface and User Experience
\fancyfoot[L]{Ambrosch}
The frontend should be an easily usable web-interface for managing geofences. It should also have a slick and smart user interface that can be integrated into the existing _DriveBox_-application.


## Feature requirements
To get a basic overview of the needed functionality, a list was compiled before starting work on the app:

- A user is able to log in with an account.
- A user can register to create a new account.
  - Alternatively, new users can be created by an admin in a dashboard.
- The user has access to a page with account information and settings.
- The user can change some general settings, such as default coordinates or zoom level of the map.
- Geofences can be viewed in a list and are displayed on a map.
- Geofences can be created either as circles, polygons or rectangles.
  - Persistence is handled separately, by creating geofences first, then commiting them to the database.
- Geofences can be edited.
  - It is not clear yet if circles should be edited by changing center and radius, if yes, they cannot be stored as polygons.
- Geofences can be deleted.
- Certain activation days can be set for individual geofences.
  - If a Drivebox leaves a geofence while it is active, an alarm is sent.
- A list of Driveboxes can be viewed.
  - A list of recorded trips is displayed, grouped by Drivebox.
- Finished trips of Driveboxes can be analyzed.
  - Entry and exit events for geofences that occurred during the trip are shown, including timestamps and the duration spent in each geofence.
  - The route of the trip can be displayed on a map.

Some features were added later, while others were changed or became obsolete.\
An updated list of features was later written in the form of a Use-Case-Diagram, which can be seen in chapter _Use Cases_.


## Mockup
During the development process, mockups of the user interface were used to evaluate different workflows, layouts and designs before they were implemented. The software chosen for this was _Adobe XD_[@adobexdref], because of its ease of use and the possibility to create interactive mockups to simulate different flows between screens that the user can take. Some of the specific things that were evaluated with the use of mockups will be mentioned below.


### Basic layout
Early on, it was decided to split the interface into two main parts, a map view and a collapsible sidebar that contains all other info, like the list of geofences. It was originally planned to have a tab view in this sidebar with tabs for different categories, e.g. a list of geofences and a list of drive logs. This became obsolete when it became clear that the app would only be used for managing the geofences themselves.

The mockups also included concepts for how the layout would change on smartphones, which also was not needed because the management interface would only have to be used on computers and tablets.


### Drive log display
Because it was originally considered to display information on drive logs in the user interface, several concepts for the display of entry and exit events were evaluated. A compromise solution was found, which is shown in figure 4.1. This solution could fulfill all of the following design requirements:

- display entry and exit events
- display the time spent in each geofence
- works with overlapping geofences
- works when starting in geofence (exit without entry)
- works when ending in geofence (entry without exit)

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/Mockup_drive_logs.PNG}
	\caption{The final mockup for displaying drive logs}
	\label{fig4_1}
\end{figure}

Even though the feature to display drive logs was not needed, the mockup was kept in case it would be implemented at a later point.


### Bulk selection and locking
Since it would be common for users to want to change locks for several geofences at once, for example locking a group of geofences on the weekend, it was necessary to implement the option to select geofences and perform bulk operations. For this, four different options were evaluated in the mockup. These options, as well as their advantages and disadvantages, will be described below:

1. A select-all checkbox for each day of the week, allowing the user to lock or unlock all geofences for that day

  - easy to use and intuitive
  - actions can only be performed for all geofences, since there is no selection model
2. Checkboxes to select geofences, and dropdown buttons for each weekday to lock, unlock or toggle all selected geofences' locks on that day

  - more options and flexibility
  - more buttons / cluttered interface
3. Checkboxes to select geofences and a button bar with dropdown buttons to lock, unlock or toggle certain weekdays

  - more options and flexibility
  - cleaner interface
4. A fourth solution was conceptualized that would enable the user to set geofence locks not just on weekdays, but as customizable time slots

  - even more flexibility
  - hard to implement bulk operations

Option 3 was chosen for the app because of the added flexibility of the selection model, and because a button bar was needed for other features anyway. Customizable timeslots, like in option four, were not implemented in the app, but the mockup was kept in case they would be added later.


## Mobile compatibility
According to the company, the geofence management application would mainly be used on PCs, and sometimes on tablets. Smaller devices like smartphones could therefore be neglected.

The UI consists of a map on the left and a sidebar on the right, which starts at a width of 410px, but can be dragged to any size between 410px and 120px less than the total window width. Switching from a horizontal to a vertical split layout was considered, but this would have been necessary only for screens with very small widths.

The drawing tools from _leaflet-draw_ were tested briefly on a touchscreen device, and all basic functionality appears to be present. Since geofences would mainly be drawn and edited on PC, no further attempt was made to improve the drawing experience on touchscreens.


## Specific design decisions
In order to improve the usability of the app and to bring it closer to a finished product which could be used in reality, numerous different aspects of User Experience Design were taken into consideration, some of which will be described in the following chapter.


### Confirmation dialogs
A confirmation dialogs is usually used when a significant action is performed. It informs the user of the action to be taken and requires them to confirm the same action a second time. The dialog purposely adds difficulty to performing certain actions in order to avoid triggers that happen by accident or because the user did not understand the consequences of the action [@confirmationDialogs].

Standard confirmation dialogs are used in the app whenever any item is deleted, and when geofence geometry is edited. Additionally, all pop-ups that require the user to enter data, for example when creating or renaming geofences, function as confirm dialogs by offering both _confirm_ and _cancel_ options.


#### Confirm vs. Undo
An alternative to confirm dialogs are _Undo notifications_, where the action in question is not interrupted, but the user is given the option to revert any changes made afterwards, usually for a limited time.

This approach is especially useful for frequent or lightweight actions, since it does not disrupt the workflow as much. However, for actions that are irreversible, require substantial amounts of time or resources to be undone, or initiate complex changes, a confirmation dialog should be used.

Since it was not planned to make any of the actions in the web-interface reversible, it was neither possible nor necessary to implement an _Undo_ function, and only confirmation dialogs were used.


#### Headline texts
Each confirmation dialog contains a headline, the function of which is to inform the user about the action and its consequences. Speaking from personal previous experience with different software, additional confirmation steps are often quickly learnt by the user, and are then performed without carefully reading the information presented in the user interface. Therefore, it is important to catch the attention of the user by using short and unambiguous texts. This is achieved in two ways:

- First, by avoiding generic texts and using verbs specific to the action. The user should be able to read the dialog without any additional context.\
_Example: "Delete geofence?" instead of "Are you sure?"_

- Second, by leaving out unnecessary sentence openings or endings.\
_Example: "Delete geofence?" instead of "Do you want to delete this geofence?"_

Any additional information to the headline was deemed unnecessary, as there are no actions in the app that are complex or abstract enough to require a detailed explanation. This way, the headline is also stronger because there are less other elements in the dialog that the user could focus on.


#### Button texts
The principles for headlines also apply to the buttons in the dialog. Specifically, their meaning should be clear without additional context or significant thinking. To achieve this, descriptive verbs are used instead of generic options.\
_Example: "Delete" and "Cancel" instead of "Yes" and "No"_ 


### Use of plural forms
In software, when a label refers to a variable number of items, usually greater than or equal to one, the plural form of the item is often written statically with an "s" in brackets to account for all possibilities, e.g. _geofence(s)_. This is usually only a minor inconvenience for the user, but fixing it can make an application look more professional and completed. This can be done with minimal effort, by using the singular form if the number of items equals one, and using the plural form otherwise [@UIPlurals].

Additionally, in the app, when the geofence bulk delete function (chapter _Bulk operations_) is used with only one item (geofence) selected, the confirmation dialog is displayed like it would be for a conventional, single delete operation, including the name of the geofence instead of the number of geofences to be deleted.


### Word choice for deletion
The _New York State User Experience Toolkit_[@nysuxtoolkitref] defines the difference between the words as follows:\

"Remove and Delete are defined quite similarly, but the main difference between them is that delete means erase (i.e. rendered nonexistent or nonrecoverable), while remove denotes take away and set aside (but kept in existence)." (Source: [@NYStateUXToolkit])

Since all deletion actions in the app are destructive without an undo-option, as described in chapter _Confirm vs. Undo_, "Delete" is used in all cases, for geofences as well as metadata entries.


### Word choice for creation
Like with deletion, there are also different words that can be used to describe a creation process. The following cases were differentiated in the app:

- All buttons that enable the user to create a geofence on the map, by placing points or via route finding, are labelled with "Draw". Once the drawing process is finished, "Create" indicates the actual creation of the geofence with the drawn geometry.
- The action for creating a geofence from a preset is marked as "Generate", to indicate that it is not created from scratch, but as a copy of an already existing preset geofence.
- In the geofence metadata dialog, the action to create a new entry is called "Add", because since metadata is a simple list of strings, no new item is _created_, and the text input itself is _added_ to the list as an item.


### Search bar design
The _Salesforce Style Guide_[@salesforcestyleguideref] suggests using ellipses at the end of text prompts, unless the text ends with a question mark [@SalesforceEllipses]. Accordingly, ellipses are used in the search bar for geofence metadata ("Search ...") as well as the map location search bar ("Search a place ...").

The geofence metadata search bar is not visible by default, but can be toggled on with a button. It then takes the place of the pagination functions. This  is done to clear up the interface, since search and pagination can functionally not be used at the same time.

When the search bar is shown, it includes a "Search"-button, which is connected to the search prompt input field, and a "Clear"-button, which is only shown once at least one character has been entered. The "Clear"-button only clears the text in the input field, but does not reset the actual search. This is only done once the search bar is toggled off, to reduce the chance of accidental resets and unnecessary backend calls.


## Multi-language support
To comply with the already existing Drivebox-App, the user interface is offered in both English and German. This includes all texts, like labels, tooltips, error messages, and also native texts used by libraries such as labels in the _Leaflet_-map, wherever they could be changed.

The language is selected by the user in the Drivebox-App and is then handed to the Geofencing application.


## Integration into DriveBox
Since the Geofencing app was developed to be integrated into the DriveBox application by the company, the look and feel of the User Interface had to be adapted. This mainly meant three things:

- Using a light theme instead of a dark theme
- Using shadows instead of borders for cards
- Using the color blue for accents

The specific shades of blue that were used were derived from the _Drivebox_ application logo, but were altered in some places to increase readability and to make the user interface visually more appealing. Figure 4.2 shows the user interface before adaptations were made, while figure 4.3 contains all changes made to the UI.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/UI_Integration_before.png}
	\caption{UI mockup before adaptations for integration}
	\label{fig4_2}
\end{figure}

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/UI_Integration_after.png}
	\caption{UI mockup adapted for integration into the existing Drivebox application}
	\label{fig4_3}
\end{figure}