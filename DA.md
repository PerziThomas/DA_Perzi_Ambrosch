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

The frontend was developed as a quasi-stand-alone application to be later integrated into the already existing DriveBox application by iLogs.

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
Circle geofences and road geofences cannot be edited, since changing individual points would be useless for these cases.

The basic editing itself is provided by _leaflet-draw_. The map can be put into an edit mode, where individual points of polygons can be moved by the user. After this, the editing action can be confirmed or cancelled.\
The confirm action _onEdit_ is overwritten to take care of confirmation and persistancy.

Since multiple polygons can be edited at once, all actions need to be performed iteratively for an array of edited layers.

Each geofence is converted to a JSON object and send to the PATCH endpoint _/geoFences/{id}_

In case of a backend error, since the Leaflet map has already saved the changes to the polygons, the window is reloaded to restore the correct state of all geofences before editing.


### Circle geofences
Lorem Ipsum


### Road geofences
Lorem Ipsum


### Geofence locking
Lorem Ipsum


### Geofence highlighting
Lorem Ipsum


### Pagination
Lorem Ipsum


### Geofence metadata filtering
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
Lorem Ipsum


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
Lorem Ipsum


## Requirements
Lorem Ipsum


## Mockup
Lorem Ipsum


## Specific elements
Lorem Ipsum


## Integration into DriveBox
Lorem Ipsum


