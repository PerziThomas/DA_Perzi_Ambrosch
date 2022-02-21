## Geofence Management Web-Interface
The frontend provides full CRUD operations for geofences.

It is implemented as a React Web-Interface using Leaflet and extensions to work with maps and geographical data.

The frontend was developed as a stand-alone application to be later integrated into the already existing DriveBox application by the company.


### Interactive Map
The central part of the Frontend is an interactive map that can be used to view, create and edit geofences.\
Interactive, in this case, means that all operations that involve direct interaction with the underlying geographical data, can be carried out directly on the map, instead of, for example, by entering coordinates in an input field.


#### Leaflet
Leaflet is the leading open-source JavaScript library for interactive maps. It is a technology used by the company for maps in existing apps, and is also ideal for testing applications, since it is free to use with no restrictions regarding time, data, or features. [@leafletOverview]

Because Leaflet is open-source, a lot of additional libraries exist, some of which were used in the app and will now be described.


#### React Leaflet
React Leaflet is a node library that offers React components for Leaflet maps, making it easier to use in a React context. It is responsible for things such as providing hooks or rendering Leaflet layers by itself to avoid updating the DOM tree. [@reactLeafletIntro]

React Leaflet does not replace Leaflet, but it is used in conjunction with it. While the application is written with React Leaflet where possible, in some cases, solutions involving the standard Leaflet have to be used to achieve a specific task.


#### Leaflet Draw
Leaflet Draw is a node library that adds interactive drawing features to Leaflet maps. The library can be used to add a toolbar to Leaflet maps, containing options for drawing different shapes, as well as editing them.\
The toolbar can also be customized with regards to what features are available. [@leafletDrawDocumentation]


#### React Leaflet Draw
React Leaflet Draw is a node library for using Leaflet Draw features with React Leaflet. It achieves this by providing an _EditControl_ component that is used in the Leaflet Map and can then be used to customize the Leaflet Draw toolbar or to overwrite event handlers. [@reactLeafletDrawIntro]

In the app, the event handlers by Leaflet Draw for creating and editing shapes are overwritten and used to handle things such as confirmation or persistence.


### Geofence creation
Geofences can be created as polygons, rectangles, circles or as road geofences by routes. Circle creation is handled separately and will be discussed in chapter _Circle geofences_. All other types can be converted to and created as polygons.

Any created geofence is checked for self-intersections.\
[@codeSelfIntersection]
[@codeLineIntersection]

If an error occurs, the creation process is aborted. Since the Leaflet map only reacts to its own errors, not those in the custom code, the drawn geometry needs to be manually removed from the map.

```jsx
createdLayer._map.removeLayer(createdLayer);
```

If no error is found, the geofence is converted into a JSON object and sent to the POST endpoint _/geoFences/_ of the backend.

If the backend returns a success, the geofence is added directly into the collection in the state of the React app, to avoid having to reload the entire page.

If a backend error occurs, the creation process is once again aborted.


### Generation of geofences from presets
Geofences can be created from a list of presets, which allows the user to use more complex geofences, like countries or states, without significant drawing effort.

The available presets with their geometry are stored in the Database. A POST request is sent to the endpoint _/geoFences/createPreset?preset=${id}_ of the backend. This creates a new geofence in the Database with a copy of the preset's geometry. The geometry is also sent back to the frontend in the response, where the new geofence can be added directly in the React state.


### Geofence editing
The geometry of geofences that are drawn or loaded from the backend can be changed by the user.\

The basic editing itself is provided by _leaflet-draw_. The map can be put into an edit mode, where individual points of polygons can be moved by the user. After this, the editing action can be confirmed or cancelled.\
The confirm action _onEdit_ is overwritten to take care of confirmation and persistence.

Since multiple polygons can be edited at once, all actions need to be performed iteratively for an array of edited layers.

Each geofence is converted to a JSON object and send to the PATCH endpoint _/geoFences/{id}_

In case of a backend error, since the Leaflet map has already saved the changes to the polygons, the window has to be reloaded to restore the correct state of all geofences before editing.


#### Single edit functionality
It was considered to have only one geofence be editable at a time.\
This would have performance benefits, since a smaller number of draggable markers for editable geometry would be rendered at once.

This functionality would be achieved by storing an _editable_ flag for that geofence, and then only rendering geofences that have this flag inside the _FeatureGroup_.

This feature did not work as intended, since the _Leaflet_ map did not rerender correctly. Also, the performance benefit became less of a priority after implementing pagination.


#### Making loaded geofences editable
To make all geofences editable (not just those that were drawn, but also those that were loaded from the backend), all geofences are stored in a collection, which is then used to render all editable geometry inside a _FeatureGroup_ of the map.

```jsx
for (let elem of res.data.geoJson) {
  let currentGeoFence = JSON.parse(elem);

  // swap lat and long
  for (let subArr of currentGeoFence.Polygon.coordinates) {
    for (let e of subArr) {
      let temp = e[0];
      e[0] = e[1];
      e[1] = temp;
    }
  }

  currentGeoFence.Hidden = tempVisibilityObj[`id_${currentGeoFence.ID}`] || false;
  let newPoly = L.polygon(currentGeoFence.Polygon.coordinates);
  newPoly.geoFence = currentGeoFence;
  newGeoFences.set(currentGeoFence.ID, newPoly);
}
```

```jsx
<FeatureGroup>
    <MyEditComponent
        currentUserName={currentUserName}
        geoFences={geoFences}
        map={map}
        addGeoFenceInState={addGeoFenceInState}
        {...props}
    ></MyEditComponent>

    {/*display editable geofences (not circles or roads) inside edit-featuregroup*/}
    {[...geoFences.keys()].filter(id => {
        return (geoFences.get(id) && !geoFences.get(id).geoFence.SystemGeoFence && !geoFences.get(id).geoFence.IsNotEditable)
    }).map(id => {
        return (
            <MyPolygon
                polygon={geoFences.get(id)}
                idGeoFence={id}
                key={'editPoly_' + id}
                hidden={geoFences.get(id).geoFence.Hidden}
                pathOptions={geoFences.get(id).pathOptions || (geoFences.get(id).geoFence.Highlighted ? highlightedPolyOptions : polygonColor)}
                {...props}
            ></MyPolygon>
        );
    })}
</FeatureGroup>
```


#### Non-editable geofences
Circle geofences and road geofences cannot be edited, since changing individual points would be useless for these cases.

To achieve this, all geofences are given a Boolean property _isNotEditable_, which is set to true in the backend for geofences created via the circle or road endpoints.

This property is then used to separate all editable from all non-editable geofences, and render only those that can be edited inside the edit-_FeatureGroup_ of the map.

```jsx
<MapContainer [TODO: code abbreviations?] ... >
    ...
    {/*display non-editable geofences (circles or roads)*/}
    {[...geoFences.keys()].filter(id => {
        return (geoFences.get(id).geoFence.SystemGeoFence || geoFences.get(id).geoFence.IsNotEditable)
    }).map(id => {
        return (
            <MyPolygon ... ></MyPolygon>
        );
    })}

    <FeatureGroup>
        <MyEditComponent ... ></MyEditComponent>

        {/*display editable geofences (not circles or roads) inside edit-featuregroup*/}
        {[...geoFences.keys()].filter(id => {
            return (geoFences.get(id) && !geoFences.get(id).geoFence.SystemGeoFence && !geoFences.get(id).geoFence.IsNotEditable)
        }).map(id => {
            return (
                <MyPolygon ... ></MyPolygon>
            );
        })}
    </FeatureGroup>
</MapContainer>
```

### Circle geofences
Circles, when created with _leaflet-draw_, have a centre point defined by a latitude, a longitude and a radius. This information is sent to the backend.

In the backend, the circle is converted into a polygon, which can be saved to the Database. The geometry is also returned to the frontend, where it is then used to add the circle directly in the React state.


### Road geofences
Geofences can be created by setting waypoints, calculating a route and giving it width to make it a road.

The routing function is provided by the node package _leaflet-routing-machine_. The package calculates a route between multiple waypoints on the map using road data. Waypoints can be dragged around on the map, and additional via points can be added by clicking or dragging to alter the route.

Every time the selected route changes, it is stored in a React state variable.

When the button to create a new road geofence based on the current route is clicked, a dialog is shown, where a name can be given to the geofence. Also, the width of the road can be selected.

The route stored in state and the given name, are sent to the backend endpoint _/geoFences/road?roadType=?_. RoadType refers to the width of the road to be created, by tracing a circle of a certain radius along the path. All accepted values for roadType are:

- roadType=1: 3 meters
- roadType=2: 7 meters
- roadType=3: 10 meters

The geofence is created in the backend, and the geometry of the new polygon is returned to the frontend. If a successful response is received, the geofence is added directly in state to avoid reloading.


### Map search
A search function exists, to make it easier to find places on the map by searching for names or addresses.

This function is provided by the package _leaflet-geosearch_, which can be easily used and was only slightly customized.

A custom React component _GeoSearchField_ is used. In it, an instance of _GeoSearchControl_ provided by _leaflet-geosearch_ is created with customization options. This is then added to the map in the _useEffect_ hook.

The component _GeoSearchField_ is also used inside the _LeafletMap_ in order to make the search button available on the map.

```jsx
import { GeoSearchControl, OpenStreetMapProvider } from 'leaflet-geosearch';
import { useMap } from 'react-leaflet';
import { useEffect } from 'react';
import { withLocalize } from 'react-localize-redux';
import '../../css/GeoSearch.css';

const GeoSearchField = ({translate, activeLanguage}) => {
    let map = useMap();

    // @ts-ignore
    const searchControl = new GeoSearchControl({
        provider: new OpenStreetMapProvider({params: {'accept-language': activeLanguage.code.split("-")[0]}}),
        autoComplete: true,
        autoCompleteDelay: 500,
        showMarker: false,
        showPopup: false,
        searchLabel: translate("searchGeo.hint"),
        classNames: {
            resetButton: 'gs-resetButton',
        }
    });

    useEffect(() => {
        map?.addControl(searchControl);
        return () => map?.removeControl(searchControl);
    }, [map])

    return null;
}

export default withLocalize(GeoSearchField);
```


### Geofence labels
A label is displayed for every geofence in the map to make it easier to associate a geofence with its corresponding polygon.

Leaflet can display labels for polygons, however, these default labels have some problems.\
The precision with which the position of the label is calculated seems to be limited by the initial zoom value set for the map, meaning that with a lower default zoom, the label is sometimes either not centred within or completely outside its polygon. 

![Labels (top left) are displayed at the same point outside their corresponding polygons (bottom right).](source/figures/Label_precision_problem.png "Screenshot"){#fig:stress_one width=90%}
\ 

This problem can be solved by starting at a higher initial zoom level, but to keep flexibility in this regard, labels are added manually by rendering a marker on the map for each polygon at a calculated position.


#### Finding optimum label position
Since the default labels were replaced with custom markers, the position of these relative to the rectangle has to be calculated manually. There are several ways in which this can be done, which will be described in detail.


##### Average of points
The label position can be calculated by taking an average of the coordinates of all points of the polygon. This is a good approximation for simple, convex shapes with evenly distributed points.

If points are distributed unevenly, meaning there is more detail on one side than the other, the average will shift to that side, and the calculated point will not appear centred anymore.

This approach can also lead to problems with concave geometry, like for example a U-shaped polygon. The calculated centre lies in the middle of the shape, which in this case is not part of the polygon, causing the label to appear outside the geometry.

![Geofence label is displayed outside the concave polygon's geometry](source/figures/Label_outside_concave_geometry.png "Screenshot"){#fig:stress_one width=90%}
\ 


##### Center of bounding box
The label can be placed at the centre of the bounding box of the polygon, which can easily be done by using basic leaflet methods.

```jsx
polygon.getBounds().getCenter()
```

This approach solves the problem with unevenly distributed points, because the centre is always calculated from a rectangle with exactly four points. However, it is not a solution for concave polygons like the U-shape described above.


##### Pole of inaccessibility
The node package _polylabel_ uses an algorithm to calculate a polygon's _pole of inaccessibility_, defined as "the most distant internal point from the polygon outline". [@polylabelIntro]

This approach solves the problem with concave shapes, because the calculated point always lies inside the polygon, and for this reason, it was used to calculate the label positions in the app.

![Geofence label placed at the pole of inaccessibility](source/figures/Label_pole_of_inaccessibility.png "Screenshot"){#fig:stress_one width=90%}
\ 


#### Dynamic label size
The size of the geofence labels changes depending on the current zoom level of the map, getting smaller as the user zooms out further, and is hidden for any zoom level smaller than or equal to 6.

This dynamic sizing is achieved by using a CSS class selector that includes the current zoom level to select the corresponding option from the CSS classes _zoom6_ to _zoom13_.

```jsx
return L.divIcon({
    className: "",
    html: `<div class="tooltipMarker ${"zoom" + (zoomLevel > 6 ? zoomLevel : 6)}">${title}</div>`,
});
```


### Geofence deletion
All geofences, whether they were created by drawing, route creation or from a system geofence, can be deleted via the user interface. 

The geofence is first deleted from the database by sending a request to the DELETE endpoint _/geoFences/${id}_ of the backend. In case of a success, the geofence is also deleted from the React state to avoid having to re-fetch all geofences.


### Geofence edit history
It was initially planned to display a list of all changes made to a geofence made to a geofence, containing the username of the editor and a timestamp.\
This was later changed to just a timestamp after the company changed some demands regarding how the login and user management would work.

In the backend, a timestamp is added every time a geofence is created or an updated.

The edit history is accessed in the frontend when the geoFences are fetched from the server, and is then filtered and passed to the corresponding geofence list item to be displayed in an info card.


### Geofence visibility
Specific geofences can be hidden from the map to make it visually clearer.

For any geofence with a Boolean tag _Hidden_ set to true, no _react-leaflet_ Polygon is rendered in the map, and it is instead replaced with an empty tag. This has the added benefit of not rendering the polygon and therefore improving frontend performance when geofences with large numbers of points are hidden.


#### Storing geofence visibilities
The information on which geofences are hidden is stored for the convenience of the user. Since most geofences that are hidden can be assumed to stay hidden for the majority of the time, like system geofences, geofences with a large number of points or generally rarely used ones, this is done with _localStorage_, meaning that, contrary to _sessionStorage_, the information is stored not just on page reloads, but in entirely new sessions.

```jsx
let obj = {...visibilityObj};

newGeoFences.forEach(e => {
    obj[`id_${e.geoFence.ID}`] = e.geoFence.Hidden || false;
});

setVisibilityObj(obj);
localStorage.setItem("visibility", JSON.stringify(obj));
```


### Geofence highlighting
Any geofence can be highlighted, setting the map view to show it, as well as changing it to a highlight colour (green).

The map movement is done by using the _Leaflet_ function _map.flyToBounds_, which changes the map's centre and zoom level with a smooth animation to fit the bounds of given geometry. [@leafletDocumentation]

A Boolean tag _Highlighted_ is stored for every geofence. Some special cases have to be considered in combination with the _Geofence visibility_ feature:\
- If a geofence is highlighted, and its tag therefore set to be true, the tag of all other geofences is set to be false, to ensure that only one geofence is highlighted at a time.
- If a hidden geofence is highlighted, it is also unhidden.
- If a highlighted geofence is hidden, it is also set to not be highlighted.


### Geofence renaming
Any geofence can be renamed in the Web-Interface.\
The user is shown a text dialog to enter a title. A request with this new title is then sent to the PATCH endpoint _/geoFences/${id}_ of the backend, where the database entry is updated. In case of a success, the title is also changed in the React state directly.


### Geofence metadata
While working on the app, the company decided to market the app to smaller districts and specifically, to be used for tracking road maintenance and snow clearing vehicles, which would make it necessary to store additional data for a geofence, like the workers tasked with clearing it.

A metadata system was added, which allows for different metadata categories in which data entries can be added in the form of a collection of strings.\
The app contains two categories, _Workers_ and _Others_, which are hardcoded in both the frontend and backend, since the company did not see the necessity to have a dynamic system for this.

Metadata can be viewed and edited in a dialog window for each geofence. Selecting one of the categories shows all entries for that geofence in that category. New entries can also be created in this category, and existing entries can be deleted. The ability to edit entries is deliberately omitted because they are strings and usually very short, making it just as easy to delete and re-enter incorrect metadata.

All geofence metadata is stored in an array separate from the geofences themselves, and is fetched from the GET endpoint _/GeoFenceMetadata_ on application start or reload. The data is filtered by _id_ of the geofence for display in the dialog.

On adding a new entry, a POST request is sent to the _/GeoFenceMetadata_ endpoint, which in case of a success returns the _id_ of the new database object, which can be sent to the DELETE endpoint, enabling an entry to be deleted from the database directly after creation without the need to re-fetch the data.


#### Metadata search
The app includes a search bar, to filter geofences based on their metadata entries, which consists of a selection of the metadata category and a text field to enter a search string.

When the search button is pressed, a GET request is sent to the backend containing the category as well as the search term, to the endpoint _/geoFences/search?searchTerm=\${searchTerm}&metadataCategory=${category}_, which returns a collection of all geofences that fit the search. The actual search process is handled on the backend.\
The React state is then updated to include the returned geofences, and only these geofences are displayed in the user interface.


### Geofence locking
One of the main use cases of the app is for theft protection. An object (a car or machine) can be tracked with the _DriveBox_, and if it leaves a geofence, an alarm can be sent out. For this feature, there is also the option to lock geofences on certain days of the week, so that for example no alarm is triggered on the weekend.

In the app, every geofence has a button for each weekday, which shows the current state and allows the user to toggle the lock on or off. When one of these buttons is pressed, a GET request is sent to the endpoint _/geoFences/${id}/${weekday}/2_, including the _id_ of the geofence, the weekday and the locking method, with the following options:

- 0: lock
- 1: unlock
- 2: toggle locking

All geofence locks are fetched on app start or reload from the GET endpoint _/geoFences/timelocks_, which returns a map object containing all geofences that have locks, each with a list of all weekdays that are locked. This map is stored in the React state separate from the geofence and metadata collections.

### Pagination
The geofence list in the app includes a pagination feature, to reduce the number of loaded geofences for performance improvement, and to make the user experience clearer by showing less elements at once. The feature includes buttons to go to the next and previous as well as to the first and last page, an input to go to a specific page requested by number, and the option to set the number of elements that should be displayed on every page.

The currently selected page and page size are stored in React state and in a site cookie, so the user can stay on the same page when reloading. When a new page is requested by pressing a button or entering a page number, or when the page size is changed, a GET request is sent to the endpoint _/geoFences?size=\${size}&page=${page}_, which returns a collection of geofences corresponding to the page number of the given page size, and the total page count, which is used in the frontend for display and for checking if a next or specific page can be requested.

The task of determining what geofences should be returned in which page is handled by the backend, eliminating the need to have all geofences available in the frontend, and therefore improving frontend performance.


### Geofence display colour
The user can select from a variety of display colours for the geofences on the map, for better contrast and visibility or for personal preference. This is a global setting, meaning that the colour can be changed for all geofences at once. It is not possible to set different colours for individual geofences.

The currently selected colour is stored in a React state variable and used when drawing the Polygons on the map.

Highlighted geofences are always coloured green, overriding the global geofence display colour.


### Bulk operations
The app includes the option to perform certain actions for multiple geofences at once, including locking actions and geofence deletion. Backend requests are sent for each selected geofence individually, which is not problematic in terms of performance, but allows further room for improvement, for example by implementing a special endpoint for bulk operations to be handled by the backend.


#### Selection checkboxes
To allow the user to select geofences for which the bulk operations should be performed, a checkbox is added to each geofence in the list. An array of all currently selected geofences' ids is stored in React state, and if a geofence is selected or deselected, its id is pushed into this array or removed from it.

Because the checkboxes are part of custom list elements, a select-all-checkbox also has to be added manually. The current _selectAllState_ (NONE, SOME or ALL) is determined after every clickEvent on a checkbox by counting the number of selected geofences, and is used to show an unchecked, indeterminate or checked select-all-checkbox respectively. This checkbox can also be clicked itself to select all loaded geofences if none are selected, or to deselect all if some or all are selected.

```jsx
<Checkbox
    id="cb_all"
    style={{ color: buttonColors.bright }}
    indeterminate={selectAllState === selectionState.SOME}
    checked={selectAllState !== selectionState.NONE}
    onChange={() => onSelectAllChanged()}
></Checkbox>
```


#### Bulk locking
Bulk actions are available for locking, unlocking and toggling locks for geofences on any weekday individually or on all weekdays at once. A function is called with the weekday and the lockMethod (0 for locking, 1 for unlocking and 2 for toggling). For all selected geofences, the locking is performed as described in chapter _Geofence locking_.

If the action should be performed for all weekdays, indicated by a value for _weekday_ of -1, the function _lockActionMulti_ is called recursively for every weekday value from 0 to 6.

```jsx
function lockActionMulti(weekday, lockMethod) {
    let weekdaysToLock = [];
    if (weekday === -1)
        weekdaysToLock = [1, 2, 3, 4, 5, 6, 0];
    else
        weekdaysToLock = [weekday];

    let newGeoFenceLocks = geoFenceLocks;
    for (let currentDayToLock of weekdaysToLock) {
        for (let id of selection) {
            switch (lockMethod) {
                case 0: lockDay(newGeoFenceLocks, id, currentDayToLock);     break;
                case 1: unlockDay(newGeoFenceLocks, id, currentDayToLock);   break;
                case 2: toggleDay(newGeoFenceLocks, id, currentDayToLock);   break;
                default: return;
            }

            callBackendLocking(id, weekday, lockMethod);
        }
    }
    setGeoFenceLocks({...newGeoFenceLocks});
}
```
