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
To handle the required communication between the frontend and backend applications of the geofence system, a RESTful webservice was implemented using the ASP.NET Core framework. This service provided the capability to use HTTP for exchanging the information about geofences required to create and modify geofences, as well as calculating intersections.

### REST
REST (Representational State Transfer) is a software architectural style which defines several principles which makes a service RESTful.

For a service to be considered RESTful, it must fulfil six criteria:

1. Uniform Interface
   : This defines the need for all components of the system to follow the same set of rules and thus allowing for a standard way of communication.
2. Client-Server
   : Tasks and concerns have to be strictly separated between the client and the server. 
3. Stateless
   : Each request sent to the server must provide enough information so that it can be processed without the need to consult any previous requests.
4. Cacheable
   : A response message must include a flag which provides information about it being cacheable.
5. Layered system
   : A system is composed of layers which are only able to interact with their next immediate neighbors and are unable to see further beyond that.
6. Code on demand 
   : Optionally, code can be download to extend a clients functionality. 

A REST resource is defined as a combination of data, the corresponding metadata as well as links leading to another associated state. Resources should be self-descriptive. Resources can be represented through any kind of format. [@restful]

### Controllers
Using ASP.NET Core's controller classes the creation of high level routing of HTTP-Requests, the web service is divided into three main components.

1. Geofences
   : General interaction with geofence objects, providing actions such as adding, deleting, modifying and reading them (CRUD). Furthermore, options to lock geofences on certain days of the week are also provided.
2. TimePoints
    : Used to analyze trips either in real time or after the completion of one.
3. Geofence Metadata
    : Lorem Ipsum

Controllers provide the ability to create API-Endpoints for all commonly used HTTP methods (GET, POST, DELETE, etc...) using annotations. Methods annotated as such supply ready to use objects needed for the processing of requests, such as request and response objects, as well as automatic parsing of the request body. 

\begin{lstlisting}[caption=A sample delete endpoint using a MVC approach to separate concerns., label=lst:restctrl, language={[Sharp]C}]
        [HttpDelete]
        [Route("{idGeoFence}")]
        public IActionResult DeleteGeofence(int idGeoFence)
        {
            databaseManager.DeleteGeofence(idGeoFence);
            return StatusCode(204);
        }
\end{lstlisting} \

### Requests
Requests onto the server were made according to HTTP, with a token included in the Authorization header to authenticate a user on the backend. Data was transmitted using JSON objects in the request body, as well as the GeoJSON format in the special case of geofence communication. (See GeoJSON chapter).

To avoid a constant repetition of boilerplate code inside each controller, ASP.NET Core middleware was used to authenticate the user using the token provided in each request.

![A sample sequence diagram of how the two applications communicate with each other. In this case fetching a list of geofences and afterwards adding a new one.](source/figures/seq_rest.png "Screenshot"){#fig:stress_one width=90%}
\  

-- TODO (David) - Describe Frontend part of communication



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
Lorem Ipsum


### Geofence creation
Lorem Ipsum


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
_[Image of graph]_

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
_[Image of new graph]_

The number of rerenders of the component has been reduced from … to …, saving loading times of …s, and the app runs noticeably smoother.\
Similar changes are also applied to other components that cause lag or rerender unnecessarily.
 
_(exact numbers need to be taken from the app itself)_


### Reduction of points for road geofences
Lorem Ipsum


### Reduction of loaded geofences
Lorem Ipsum
