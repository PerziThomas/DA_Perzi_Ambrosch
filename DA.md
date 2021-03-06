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


# Introduction
Lorem Ipsum


## Use Cases
Lorem Ipsum


# Architecture
Lorem Ipsum


## Project Structure
Lorem Ipsum


## Technical Structure
Lorem Ipsum


# Implementation
Lorem Ipsum


## Backend Technologies used
Lorem Ipsum


### ASP.NET Core
Lorem Ipsum


### MS SQL
Lorem Ipsum


#### T-SQL
Lorem Ipsum


#### SQL Spatial
Lorem Ipsum


### Ado.Net
Lorem Ipsum


#### Comparison with Entity Framework
Lorem Ipsum


### NetTopologySuite
Lorem Ipsum


## Frontend Technologies used


### React
Lorem Ipsum


### Axios
Lorem Ipsum


### React-localize-redux
Lorem Ipsum


### Material UI
Lorem Ipsum


### Leaflet
Lorem Ipsum


#### Road extension
Lorem Ipsum


#### Search extension
Lorem Ipsum


### OpenStreetMap
Lorem Ipsum


### GeoJSON
Lorem Ipsum


## Communication between Frontend and Drivebox Server
Lorem Ipsum


## Calculation Algorithm for intersections
Lorem Ipsum


### Point based
Lorem Ipsum


### Route based
Lorem Ipsum


## Polygon Creating
Lorem Ipsum


## Performance optimization on the backend
Lorem Ipsum


### Caching in ASP.NET
Lorem Ipsum


### Using Geo-Indexes in MS SQL
Lorem Ipsum


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
<MapContainer ... >
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

TODO

... default Method
... display as separate react element necessary
... tooltip precision problem

#### Finding optimum label position
... problem with complex shapes -> outside
... custom calculation


### Geofence deletion
Lorem Ipsum


### Geofence update history
Lorem Ipsum


### Geofence visibility
Lorem Ipsum


### Geofence highlighting
Lorem Ipsum


### Geofence renaming
Lorem Ipsum


### Geofence metadata
Lorem Ipsum


### Geofence locking
Lorem Ipsum


### Pagination
Lorem Ipsum


### Geofence display colour
Lorem Ipsum


## Performance optimization on the frontend
Lorem Ipsum


### Reduction of component rerenders
One of the biggest performance factors affecting performance of the React app are component rerenders. By using the profiler from _React Developer Tools_, a list of all component rerenders within the page can be shown ranked by the time taken.

By looking at the graph for the geofence management app, it can be seen that the _LeafletMap_ component takes significantly more time reloading than all other components and should be optimized.\

![React Profiler View before implementing performance optimizations.](source/figures/React_Profiler_before.png "Screenshot"){#fig:stress_one width=90%}
\  

The map component is then wrapped in _React.memo_ to rerender only when relevant props have changed. In the case of this app, that means a change in the collection of geofences to be displayed, a change regarding road geofence creation that is displayed in the map, or some meta settings like the colour of polygons.\

With a custom check function _isEqual_, the _React.memo_ function can be set to react only when one of these props changes.

```jsx
export default withLocalize(React.memo(LeafletMap, isEqual));

function isEqual(prevProps, nextProps) {
    if (compareByReference(prevProps.geoFences, nextProps.geoFences) &&
        objAreEqual(prevProps.currentUserName, nextProps.currentUserName) &&
        objAreEqual(prevProps.swapLatLngOnExport, nextProps.swapLatLngOnExport) &&
        objAreEqual(prevProps.selectedRoute, nextProps.selectedRoute) &&
        objAreEqual(prevProps.routeMode, nextProps.routeMode) &&
        objAreEqual(prevProps.polygonColor, nextProps.polygonColor)) {
        return true;
    }
    return false;
}
```

After making these changes, a new graph is recorded for the same actions.\

![React Profiler View after implementing performance optimizations.](source/figures/React_Profiler_after.png "Screenshot"){#fig:stress_one width=90%}
\ 

The render duration of the map component has been reduced from 585.6 ms to clearly below 0.5 ms, where it does not show up in the ranked list of the profiler anymore.
This also has the effect that the application now runs noticeably smoother, especially when handling the map.

Similar changes are also applied to other components that cause lag or rerender unnecessarily.


### Reduction of loaded geofences
Lorem Ipsum


# Testing
Lorem Ipsum


## Functional Testing
Lorem Ipsum


### Frontend Functionality
Lorem Ipsum


### Backend Algorithms
Lorem Ipsum


## Stress Testing
Lorem Ipsum


### MS SQL
Lorem Ipsum


### ASP.NET
Lorem Ipsum


# User Interface and User Experience
The frontend should be an easily usable web-interface for managing geofences. It should also have a slick and smart user interface that can be integrated into the existing _DriveBox_-application.


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
