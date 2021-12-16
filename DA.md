---
title: Development of a Full-Stack Geofencing Application 
author: David Ambrosch & Thomas Perzi
...

# I. Eidesstattliche Erklarung {-}

# II. Acknowledgment {-}

# III. Abstract {-}

# IV. Kurzfassung {-}

# Backend Technologies used
Lorem Ipsum


## ASP.NET Core
Lorem Ipsum


## MS SQL
Lorem Ipsum


### T-SQL
Lorem Ipsum


### SQL Spatial
Lorem Ipsum


## Ado.Net
Lorem Ipsum


### Comparison with Entity Framework
Lorem Ipsum


## NetTopologySuite
Lorem Ipsum


# Architecture
Lorem Ipsum


# Implementation
Lorem Ipsum


## REST Api communication with Frontend and Drivebox Server
Lorem Ipsum


## Calculation Algorithm for intersections
Lorem Ipsum


### Point based
Lorem Ipsum


### Route based
Lorem Ipsum


## Polygon Creating
Lorem Ipsum


# Performance optimization on the backend
Lorem Ipsum


## Caching in ASP.NET
Lorem Ipsum


## Using Geo-Indexes in MS SQL
Lorem Ipsum


# Testing
Lorem Ipsum


## Functional Testing
Lorem Ipsum

### Frontend using Selenium
Lorem Ipsum


### Backend Algorithms using Moq
Lorem Ipsum


## Stress Testing
Lorem Ipsum


### MS SQL using SQLQueryStress and Microsoft Performance Monitor
Lorem Ipsum


### ASP.NET using Apache JMeter
Lorem Ipsum


# Frontend Technologies used
Lorem Ipsum


## React
Lorem Ipsum


### Axios
Lorem Ipsum


### React-localize-redux
Lorem Ipsum


## Material UI
Lorem Ipsum


## Leaflet
Lorem Ipsum


### Road extension
Lorem Ipsum


### Search extension
Lorem Ipsum


## OpenStreetMap
Lorem Ipsum


## GeoJSON
Lorem Ipsum


# Project Structure
Lorem Ipsum


# Geofence Management Web-Interface
Lorem Ipsum


## Geofence creation
Lorem Ipsum


## Geofence editing
Lorem Ipsum


## Circle geofences
Lorem Ipsum


## Road geofences
Lorem Ipsum


## Geofence locking
Lorem Ipsum


## Geofence highlighting
Lorem Ipsum


## Pagination
Lorem Ipsum


## Geofence metadata filtering
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


# Performance optimization on the frontend
Lorem Ipsum


## Reducing component rerenders with React.memo
One of the biggest performance factors affecting performance of the React app are component rerenders. By using the profiler from _React Developer Tools_, a list of all component rerenders within the page can be shown ranked by the time taken.

By looking at the graph for our app, we can see that the _LeafletMap_ component takes significantly longer than all other components and should be optimized.\
_[Image of graph]_

The component is then wrapped in _React.memo_ with a custom check function _isEqual_ to rerender only when relevant props have changed. In this case, that means either the map, the map zoom or the geofence collection have changed.\
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
_[Image of new graph]_

The number of rerenders of the component has been reduced from … to …, saving loading times of …s, and the app also runs noticeably smoother.\
Similar changes are also applied to other components that cause lag or rerender unnecessarily.
 
_(exact numbers and code need to be taken from the app itself)_


## Reducing number of points for road geofences
Lorem Ipsum


## Reducing number of loaded geofences (pagination + visibility)
Lorem Ipsum


