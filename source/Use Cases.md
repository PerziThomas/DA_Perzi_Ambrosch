## Use Cases
To summarize all functionality of the app, a use case diagram is used which shows all the ways a user can interact with the application.\
The use cases have been grouped into categories for visual clarity and easier understanding. These basic groups and their use cases will be described below.
The boundary of system in all the following diagrams is considered to be the Geofencing application.

The first category contains all use cases for geofence creation. Since geofences can be created in several ways, which are fundamentally different in the way they work, multiple use cases are displayed that are generalized under a parent use case "Create Geofence".

![Use cases for geofence creation](source/figures/Use_Cases/Geofence_creation.png "Diagram"){#fig:stress_one width=90%}
\ 

The geofence locking functions include viewing and toggling locks, as well as bulk operations, which make use of the toggle feature and are therefore associated.

![Use cases for geofence locking](source/figures/Use_Cases/Geofence_locking.png "Diagram"){#fig:stress_one width=90%}
\ 

Geofence metadata can be viewed, created, deleted or used to filter the list of geofences.

![Use cases for geofence metadata](source/figures/Use_Cases/Geofence_metadata.png "Diagram"){#fig:stress_one width=90%}
\ 

Use cases for geofence functions consist of all remaining functions that are directly related to geofences, but are not covered by the previous categories. This includes view, edit and delete operations as well as the geofence edit history and visibility features.

![Use cases for geofence functions](source/figures/Use_Cases/Geofence_functions.png "Diagram"){#fig:stress_one width=90%}
\ 

Two use cases are provided by the program in the form of API services not connected to any frontend, a feature to get all intersections between a path and geofences, and a feature that shows geofence entry or exit events.

![Use cases for API services](source/figures/Use_Cases/API_Services.png "Diagram"){#fig:stress_one width=90%}
\ 

Miscellaneous use cases are not covered by any of the categories above and include geofence color selection as well as a map search.

![Use cases for miscellaneous functions](source/figures/Use_Cases/Miscellaneous.png "Diagram"){#fig:stress_one width=90%}
\ 
