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


### Geofence creation
To give the user the ability to "draw" geofences directly on the map inside the application, the extension _react-leaflet-draw_ is used. This allows for a component _EditControl_ to be overwritten with custom draw controls and event handlers.


### Geofence editing
Lorem Ipsum


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

_[Code snippet of React.memo and isEqual]_

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


