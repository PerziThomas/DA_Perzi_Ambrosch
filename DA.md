---
title: Development of a Full-Stack Geofencing Application 
author: David Ambrosch & Thomas Perzi
...

# I. Eidesstattliche Erklarung {-}
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
Lorem Impsum


# Architecture
Lorem Ipsum


## Project Structure
Lorem Ipsum


## Technical Structure
Lorem Impsum


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

It is implemented as a React Web-Interface using Leaflet and related extensions to work with maps and geographical data.

The frontend was developed as a stand-alone application to be later integrated into the already existing DriveBox application by iLogs.

To give the user the ability to "draw" geofences directly on the map inside the application, the extension _react-leaflet-draw_ is used. This allows for a component _EditControl_ to be overwritten with custom draw controls and event handlers, which is then given to the _LeafletMap_ component.

```jsx
<EditControl
    position='topleft'
    draw={{
        marker: false,
        circlemarker: false,
        polyline: false,
        polygon: {
            allowIntersection: false,
        },
    }}
    edit={{
        remove: false,
    }}
    onCreated={e => _onCreated(e)}
    onEdited={e => _onEdited(e)}
/>
```


### Geofence creation
Geofences can be created as polygons, rectangles, circles or as road geofences by routes. Circle creation is handled seperately and will be discussed in chapter _Circle geofences_. All other types can be converted to and created as polygons.

Any created geofence is checked for self-intersections.\
_[Check self-intersection: https://stackoverflow.com/questions/4876065/is-there-an-easy-and-fast-way-of-checking-if-a-polygon-is-self-intersecting]_\
_[Check if two lines intersect: https://stackoverflow.com/questions/9043805/test-if-two-lines-intersect-javascript-function]_

If an error is found, the creation process is aborted. Since the Leaflet map only reacts to its own errors, the drawn geometry needs to be manually removed from the map.

```jsx
createdLayer._map.removeLayer(createdLayer);
```

If no error is found, the geofence is converted into a JSON object and sent to the POST endpoint _/geoFences/_ of the backend.

If the backend returns a result, the geofence is added directly into the collection in the state of the React app, to avoid having to reload the entire page.

If a backend error occurs, the creation process is once again aborted.


### Geofence editing
The geometry of geofences that are drawn or loaded from the backend can be changed by the user.\

The basic editing itself is provided by _leaflet-draw_. The map can be put into an edit mode, where individual points of polygons can be moved by the user. After this, the editing action can be confirmed or cancelled.\
The confirm action _onEdit_ is overwritten to take care of confirmation and persistancy.

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

To achieve this, all geofences are given a boolean property _isNotEditable_, which is set to true in the backend for geofences created via the circle or road endpoints.

This property is then used to seperate all editable from all non-editable geofences, and render only those that can be edited inside the edit-_FeatureGroup_ of the map.

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
Circles, when created with _leaflet-draw_, have a centerpoint defined by a lat- and a lng-coordinate, and a radius. This information is sent to the backend.

In the backend, the circle is converted into a polygon, which can be saved to the Database. The geometry is also returned to the frontend, where it is then used to add the circle directly in the React state.


### Road geofences
Lorem Ipsum


### Map search
Lorem Ipsum


### Geofence labels
Lorem Ipsum


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


### Geofence display color
Lorem Ipsum


## Performance optimization on the frontend
Lorem Ipsum


### Reduction of component rerenders
One of the biggest performance factors affecting performance of the React app are component rerenders. By using the profiler from _React Developer Tools_, a list of all component rerenders within the page can be shown ranked by the time taken.

By looking at the graph for the geofence management app, it can be seen that the _LeafletMap_ component takes significantly more time reloading than all other components and should be optimized.\

_[Image React_Profiler_before.png]_

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

_[Image React_Profiler_after.png]_

The render duration of the map component has been reduced from 585.6ms to clearly below 0.5ms, where it does not show up in the ranked list of the profiler anymore.
This also has the effect that the application now runs noticably smoother, especially when handling the map.

Similar changes are also applied to other components that cause lag or rerender unnecessarily.

### Reduction of points for road geofences
Lorem Ipsum (is acutally backend I think)


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


# User Interface & User Experience
The frontend should be an easily usable web-interface for managing geofences. It should also have a slick and smart user interface that can be integrated into the existing _DriveBox_-application.


## Requirements
To get an overview of all needed funcionality, a basic list of use-cases was written.

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

[comment]: <> (This is a list made when we started working, maybe it should be updated to include all current funcionality)


## Mockup
Lorem Ipsum


## Mobile compatibility
The geofence management application would mainly be used on PCs, and sometines on tablets. Smaller devices like smartphones could therefore be neglected.

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
Lorem Ipsum


