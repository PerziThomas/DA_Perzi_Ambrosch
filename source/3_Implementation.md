# Implementation
This chapter describes the concrete implementation of the software in both the backend and the frontend. This includes the technical implementation of frameworks and major third party libraries described in the chapter *Technologies*. Furthermore, algorithms to calculate intersections with geofences are explained. Finally, ways of improving performance in all parts of the application are described.

## Architecture
\fancyfoot[L]{Perzi}
To create maintainable and extendable software it must be designed in such ways. To architect a software that fulfils the aforementioned criteria a certain set of principles needs to be followed. The geofencing application was built with architectural principles in mind to guarantee the continuation of the development at ilogs.

Firstly, general principles such as *separation of concerns* and *encapsulation* were implemented. Separation of concerns defines that pieces of software should only be doing their own designated work. A service that processes pictures should only process these pictures and not handle anything regarding display on the screen. Developing software according to this principle is simplified due to React and ASP.NET Core providing a clear structure for pieces of software. With controllers, services and middleware in ASP.NET Core and components in React providing structures to separate application concerns. Encapsulation is a way of developing software that only exposes certain parts of itself to other software. In a practical sense this is achieved by limiting the scope of properties in classes with keywords such as *private* and *protected*. This way as long as the defined results of exposed methods and properties are not changed, the internal structure of a class can be changed without outside notice [@architectureMS].

### Dependency Injection
To pass components along inside the application in a managed way, *dependency injection* is implemented by ASP.NET Core. Dependency Injection is a software design pattern used to achieve the Inversion of Control architectural principle. 

Typically, applications are written with a direct way of executing dependencies. This means that classes are directly dependent on other classes at compile time. To invert this structure, interfaces are added which are implemented by the previously depended on classes and called by the depending classes. This way the first class calls the second one at runtime, while the second class depends on the interface controlled by the first class, thus inverting the control flow. This provides the ability to easily plug in new implementations of the interfaces methods [@architectureMS].

Dependency Injection adds onto that by also wanting to remove the associated creation of an object when depending on an interface. Additional to the two classes and one interface an injector is created. In the example of ASP.NET Core, this task is handled by the framework. The injector serves the role of creating an instance of the class implementing the interface and injects it into the depending class [@dependencyinj].

In ASP.NET Core, dependency injection is mainly used when creating and implementing service classes. For further information on the creation, injection and lifetime of these services see the according sub-chapter in the ASP.NET Core chapter.

### Project structure
The entire geofencing application runs on a client-server architecture. The React frontend and the existing Drivebox application are served as clients by the geofencing backend server built on ASP.NET Core. Communication between the clients and the server is entirely REST and HTTP based. The following figure describes the architecture of the Drivebox application with the addition of the geofencing module.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.70\textwidth]{source/figures/architecture.png}
	\caption{Drivebox application architecture}
	\label{fig3_1}
\end{figure}

## Communication between Frontend and Drivebox Server
\fancyfoot[L]{Perzi}
To handle the required communication between the frontend and backend applications of the geofence system, a RESTful webservice was implemented using the ASP.NET Core framework. This service provides the capability to use HTTP for exchanging the information about geofences required to create and modify geofences, as well as calculating intersections.

### REST
REST (Representational State Transfer) is a software architectural style which defines several principles which make a service RESTful.

For a service to be considered RESTful, it must fulfil six criteria [@restful]:

1. Uniform Interface
   
   This defines the need for all components of the system to follow the same set of rules and thus allowing for a standard way of communication.
2. Client-Server
   
   Tasks and concerns have to be strictly separated between the client and the server. 
3. Stateless
   
   Each request sent to the server must provide enough information so that it can be processed without the need to consult any previous requests.
4. Cacheable
   
   A response message must include a flag which provides information about it being cacheable.
5. Layered system
   
   A system is composed of layers which are only able to interact with their next immediate neighbors and are unable to see further beyond that.
6. Code on demand
   
   Optionally, code can be downloaded to extend a client's functionality. 

A REST resource is defined as a combination of data, the corresponding metadata as well as links leading to another associated state. Resources should be self-descriptive. Resources can be represented through any kind of format [@restful].

### Controllers
Using ASP.NET Core's controller classes to create high level routing of incoming HTTP-Requests, the web service is divided into three main components.

1. Geofences
   
   General interaction with geofence objects, providing actions such as adding, deleting, modifying and reading them (CRUD). Furthermore, options to lock geofences on certain days of the week are also provided.
2. TimePoints
    
    Used to analyze trips either in real time or after the completion of one.
3. Geofence Metadata
    
    This data is used to sort geofences using attributes set by the user. For example, geofences can be attributed to a worker or a company. Metadata is only used for filtering geofences.

Controllers provide the ability to create API-Endpoints for all commonly used HTTP methods (GET, POST, DELETE, etc...) using annotations. Methods annotated as such supply ready-to-use objects needed for the processing of requests, such as request and response objects, as well as automatic parsing of the request body to a C# object. Processing is handled by services which receive data from controllers. An endpoint using DELETE is shown in listing 3.1.

\begin{lstlisting}[caption=Delete endpoint, label=lst:restctrl, language={[Sharp]C}]
    [HttpDelete]
    [Route("{idGeoFence}")]
    public IActionResult DeleteGeofence(int idGeoFence)
    {
        databaseManager.DeleteGeofence(idGeoFence);
        return StatusCode(204);
    }
\end{lstlisting} \

### Requests
Requests onto the server are made according to the HTTP protocol, with a token included in the Authorization header to authenticate a user on the backend. Data is transmitted using JSON objects in the request body, as well as the GeoJSON format in the special case of geofence communication (see GeoJSON chapter).

To avoid a constant repetition of boilerplate code inside each controller, ASP.NET Core middleware is used to authenticate the user using the token provided in each request. Figure 3.2 is a sequence diagram showing the communication between the front- and backend applications.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.75\textwidth]{source/figures/seq_rest.png}
	\caption{Communication between the two applications}
	\label{fig3_2}
\end{figure}


### Sending requests from the frontend
\fancyfoot[L]{Ambrosch/Perzi}
The requests were initially sent from the frontend by using the Fetch API, but this was later changed to axios to comply with the company's standards and the existing Drivebox application. Since only basic requests were made, switching from one technology to the other was fairly trivial, as the changes mainly affected property names and object syntax. An example comparison between fetch and axios is given in chapter _Comparison between fetch and axios_.

Requests for geofences are made once on initial loading of the application. A polling solution was considered, but was not implemented, as it would have negatively affected performance. Also, it was not seen as necessary to have geofences update in real time, because the same geofences would normally only be viewed and managed by a single user.\
Request polling was initially implemented for geofence locks because individual geofence's locks did not update when using bulk locking operations. This was later found to be a problem with React not re-rendering and was solved by moving the React state up.

When making requests to create resources such as geofences or metadata, the resource already exists in the frontend and is therefore added directly in the React state. To ensure that further requests, like for updates or deletion, can be made for that resource, the _id_ of the object that is created in the database must be returned to the frontend, where it is added to the resource in the state.


## Calculation Algorithm for intersections
\fancyfoot[L]{Perzi}
To calculate intersections between geofences and points in time, two methods were found during the research of possible approaches. First, manual calculation of intersections was possible with the use of a raycasting algorithm. The other way of checking if a point is within a polygon was to use methods and functions provided by Microsoft or other third party libraries.

### Raycasting
Raycasting is an algorithm which uses the Odd-Even rule to check if a point is inside a given polygon. This rule is explained in the remainder of this paragraph. To calculate the containment of a point one just needs to pick another point clearly outside of the space around the polygon. Next, after drawing a straight line from the point in time to the picked point, one must count how often the line intersects with the polygon borders. If the number of intersections is even, the point is outside the polygon, otherwise it is inside. Figure 3.3 shows a graphical representation of the algorithm.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/raycasting_polygon.png}
	\caption[Example of how a raycasting algorithm works with a polygon]%
    {Example of how a raycasting algorithm works with a polygon\protect\autocite{raycasting}}
	\label{fig3_3}
\end{figure}

This algorithm comes with some drawbacks. First, having to implement it by hand and second, needing to implement every kind of error check that might be needed. Additionally, the speed of calculations is not acceptable for time critical applications, such as Drivebox, and would need even more manual optimization to match the speed of the methods provided by third party libraries [@raycasting].

### Third Party Methods
Microsoft provides methods for calculating intersection points in geographical objects inside the spatial data package. In particular, the methods \lstinline!STContains! and \lstinline!STIntersects! are used to check if a point is inside a polygon, the difference in the two being that STIntersects returns true for a point which is exactly on the edge of a polygon. For the implementation, STContains was picked, as the increase in speed had a greater benefit than detecting points on the very edge of a polygon, as polygons are saved with an accuracy of less than a meter.

Using these methods either required doing all calculations inside the database, or to use ASP.NET instead of ASP.NET Core. Both of which were not viable approaches, as the database did not fulfil the time critical requirements of the application, and ASP.NET Core was needed for integration into the rest of the system.

To calculate intersections on the webserver, a third party library was needed. \lstinline!NETTopologySuite! was picked, as it provides the same functionality as the spatial data package. Additionally, due to the higher initial speed of C#, it was picked for the needed calculations. (See NETTopologySuite chapter)

### Point based calculation
To notify businesses of their vehicles leaving a certain area defined by a geofence, the system needed the ability to work and calculate intersections in real-time. To achieve this, a specification was chosen to receive the last two points from the main Drivebox server, and calculate which polygons these points are interacting with. Practically, this could be done using three calculations.

To avoid unnecessary calculations with polygons that are outside of a points scope, all polygons are filtered into two collections, each having all the polygons a point is inside of included. The following listing includes the code used to achieve this task.

\begin{lstlisting}[caption=Filter polygons, label=lst:polyfilter, language={[Sharp]C}]
    List<PolygonData> geoFencesPointOne = _databaseManager
       .GetPolygons(true, true, (Guid)_contextAccessor.HttpContext.Items["authKey"])
       .Where(p => p.Polygon.Contains(p1)).ToList(); //Get all polygons point 1 is in
    List<PolygonData> geoFencesPointTwo = _databaseManager
       .GetPolygons(true, true, (Guid)_contextAccessor.HttpContext.Items["authKey"])
       .Where(p => p.Polygon.Contains(p2)).ToList(); // Do the same for point 2
\end{lstlisting} \

Afterwards, the only other requirement was to compare the collections and determine which polygons are being entered, left or stayed in. The webservice then returns a collection of all affected polygons with information about which event is happening currently. The processing of this information is handled by the main Drivebox server.

### Route based calculation
Businesses are also interested in analysis of the trips their vehicles take. To achieve this, the webservice needs to process a trip sent to it by the main Drivebox server and return a collection of all polygons it enters or leaves, as well as the associated timestamps. 

The web service receives a list of coordinates from the Drivebox server, and processes those into a \lstinline!LineString! object for easier calculation of intersections. To minimize the number of calculations, all polygons that are not intersected by the LineString are filtered out in the first step.

Next, a new LineString object is built, including a representation of the initial LineString's part inside the polygon. This is done for each polygon, and in cases in which a line string leaves and enters a polygon multiple times, it is converted in a MultiLineString and processed in a special way. Otherwise it can be added to the intersection collection.
If a MultiLineString is simple, it has no intersection points with itself. If this holds true, then it can simply be split into multiple LineStrings and added to the list of intersections, otherwise it needs to be processed in a special way.

To analyze a non simple MultiLineString, a list of intersection points of the MultiLineString and the outside bounds of a polygon is created. Next, the MultiLineString is split into points as well, and each point is associated with the nearest point on the bounds of the polygon. This way, an accurate approximation of the crossing points can be found.

As a final step, each intersection is processed and modified with information on if it entered or left a polygon, and when this happened, calculated by using the two coordinates with timestamps happening immediately after an event occurs. Using the distance between these points and the intersection point, an approximate crossing time can also be interpolated. Entry and exit events are associated with each other and returned as a collection. If the entry and exit events are equal to the beginning and end of a trip, the trip is classified as staying inside a polygon. The process is described in the following figure in the form of a UML activity diagram.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/acdia_trips.png}
	\caption{Processing of a trip}
	\label{fig3_4}
\end{figure}

## Polygon Creation
To create a polygon which can be saved in the database, some processing of the input data needs to be done. As there are three kinds of polygons, there are also three different ways of processing the data received from the frontend. To send a NETTopologySuite geometric object to the database, it first needs to be converted into _SQLBytes_. This is done by using a \lstinline!SqlServerBytesWriter! object to serialize the object, the implementation of which is shown in listing 3.3.

\begin{lstlisting}[caption=Converting a Geometry object to SqlBytes, label=lst:polyfilter, language={[Sharp]C}]
    public byte[] ConvertGeometryToBytes(Geometry geometry)
    {
       SqlServerBytesWriter writer = new SqlServerBytesWriter();
       byte[] bytes = writer.Write(geometry);
       return bytes;
    }
\end{lstlisting} \

### Polygons
Normal polygons are polygons which are neither a circle nor a road. These are created by reading the coordinates provided in the input GeoJSON file and creating a \lstinline!Polygon! with the use of a \lstinline!GeometryFactoryEX! object, provided by NETTopologySuite. The creation of such a polygon is shown in the following listing.

\begin{lstlisting}[caption=Building a Polygon which can be saved in the Database, label=lst:polyfilter, language={[Sharp]C}]
    public Polygon BuildPolygonFromGeoPoints(List<GeoPoint> points)
    {
        Coordinate[] coordinates = new Coordinate[points.Count];
        for (int i = 0; i < points.Count; i++)
        {
            GeoPoint p = points[i];
            coordinates[i] = new Coordinate(p.Long.Value, p.Lat.Value);
        }

        GeometryFactoryEx factory = new GeometryFactoryEx() {
            OrientationOfExteriorRing = LinearRingOrientation.CCW 
           //Set a counter clockwise orientation to work on both
           // hemispheres.    
        };
        Polygon poly = factory.CreatePolygon(coordinates);
        poly.SRID = 4326; // Using the global coordinate system
        if(!poly.IsValid) //Throw error if data is processed wrong on the frontend
        {
            throw new TopologyException("Entered invalid Polygon");
        }
        return poly;
    }
\end{lstlisting} \

### Circles
To create a circle, only two parameters are required: the center point of the circle and the radius in meters. Creation of the actual circle object is done inside a T-SQL procedure, and achieved using the \lstinline!Point.STBuffer(radius)! call, which builds a circle from a given point.

### Roads
To create a road, a line of coordinates, similar to how trips are processed, is provided in the request to the web server. Alongside these coordinates a road width is provided, which in turn serves as the parameter provided to the \lstinline!STBuffer(width)! method. The resulting object has a \lstinline!.Reduce(1)! method applied to itself afterwards, which is used to simplify the road polygon and optimize performance across the whole system.

## Performance optimization on the backend
After performing multiple tests using various tools as described in the chapter *Testing*, a conclusion was reached that the database bottlenecked the system the most. Therefore, two ways were found to counteract this issue.

### Caching in ASP.NET
First, minimizing the number of requests made to the database could decrease the average response times for the trade-off of not always having completely correct geofence data in the frontend. Due to the vitality of correct data when calculating intersections, caching could only be performed for operations with frontend communication.

To cache polygon data, the \lstinline!MemoryCache! object provided by ASP.NET Core through dependency injection was used. Data is saved in the cache either for an absolute maximum of 30 minutes or one minute without it being accessed. The setting of these options as well as the persiting of data in the cache is shown in listing 3.5. These numbers were arbitrarily picked and will likely be changed in the final production version according to user numbers and feedback.

\begin{lstlisting}[caption=Set a new cache entry, label=lst:polyfilter, language={[Sharp]C}]
    MemoryCacheEntryOptions entryOptions = new MemoryCacheEntryOptions()
    {
          AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(30),
          SlidingExpiration = TimeSpan.FromMinutes(1)
    };

    _cache.Set("dbPolygons", polygons, entryOptions);
\end{lstlisting} \


### Using Geo-Indexes in MS SQL
Using Geo-Indexes for more effective calculation of intersections in the database was an option first considered to be implemented. When creating a Spatial Index, grid levels are set to *Medium* by default, when doing calculations with point data, setting these to *High* can have a positive performance impact.

This only led to a marginal increase in performance after testing it with practical data, hence further research into the topic was abandoned.


## Geofence Management Web-Interface
\fancyfoot[L]{Ambrosch}
The frontend provides operations for viewing, creating, updating and deleting geofences. It is used by administrators in the companies that use the _DriveBox_. The application is implemented as a React Web-Interface using Leaflet and extensions to work with maps and geographical data. The frontend was developed as a stand-alone application to be later integrated into the already existing Drivebox application by the company.


### Interactive Map
The central part of the frontend is an interactive map that can be used to view, create and edit geofences. Interactive, in this case, means that all operations that involve direct interaction with the underlying geographical data can be carried out directly on the map, instead of, for example, by entering coordinates in an input field.

The map is provided by Leaflet. Since this library is open-source, a lot of additional libraries exist, some of which are used to extend the functionality of the app.

_React Leaflet_ is also used to enable working with Leaflet in React components more easily. While the application is written with React Leaflet where possible, in some cases, solutions involving the standard Leaflet have to be used to achieve a specific task.

Leaflet Draw and React Leaflet Draw are used to add drawing functions in the map. These libraries offer event handlers for creating and editing shapes, which are overwritten in the app to handle custom behavior like confirmation dialogs and communication with the backend.


### Geofence creation
Geofences can be created as polygons, rectangles, circles or as road geofences by routes. Circle creation is handled separately and will be discussed in chapter _Circular geofences_. All other types are converted to polygons when created. The different types of geofences are shown in a class diagram in figure 3.5. The meaning of the term "non-editable geofences" in this diagram will be described in chapter _Non-editable geofences_.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/Geofence_types_class_diagram.png}
	\caption{The different types of geofences}
	\label{fig3_5}
\end{figure}

Any created geofence is checked for self-intersections [@codeSelfIntersection] [@codeLineIntersection]. If no problems are found, the geofence is converted into a JSON object and sent in a POST request to the endpoint _/geoFences/_ of the backend.

If an error occurs in the backend, the creation process is aborted. Because the error did not occur in the frontend, Leaflet does not react to it, and the new geofence is added to the map anyway. The drawn geometry therefore needs to be removed from the map manually. The code to do this is shown in listing 3.6.

\begin{lstlisting}[caption=Removing geometry from map, label=lst:geofenceCreation, language={JavaScript}]
createdLayer._map.removeLayer(createdLayer);
\end{lstlisting} \

If the backend returns a success, the geofence is added directly into the collection in the state of the React app, to avoid having to reload the entire page or re-fetch all geofences.


### Generation of geofences from presets
Geofences can be created from a list of presets, which allows the user to use more complex geofences like countries or states without significant drawing effort, since they can be created and offered by the provider of Drivebox.

The available presets with their geometry are stored in the backend. To generate a geofence from a preset, a POST request is sent to the endpoint _/geoFences/createPreset?preset=${id}_ of the backend. This creates a new geofence with a copy of the preset's geometry. The geometry is also sent back to the frontend in the response, where the new geofence can be added directly in the React state.


### Circular geofences
Circles, when created with _leaflet-draw_, have a center point defined by a latitude and a longitude, as well as a radius. This information is sent to the backend, where the circle is converted into a polygon, which can be saved to the database. The coordinates of this polygon are returned to the frontend, where they are used to add the circle directly in the React state.


### Road geofences
Geofences can be created by setting waypoints, calculating a route and giving it a width to make it a road.

The routing function is provided by the node package _leaflet-routing-machine_. This package includes functions for calculating a route between multiple waypoints on a map using real world road data. Waypoints can be dragged around on the map, and additional via points can be added by clicking or dragging to alter the route.

In the app, every time the selected route changes, it is stored in a React state variable. When the button to create a new road geofence based on the currently selected route is clicked, a dialog is shown, where a name can be given to the geofence. Also, the width of the road can be selected. The route stored in state and the given name are sent to the backend endpoint _/geoFences/road?roadType=?_. The parameter _roadType_ refers to the width of the road to be created, by tracing a circle of a certain radius along the path. The accepted values for roadType and their corresponding radii are:

- roadType=1: 3 meters
- roadType=2: 7 meters
- roadType=3: 10 meters

The geofence is created in the backend, and the geometry of the new polygon is returned to the frontend. If a successful response is received, the geofence is added directly in state to avoid reloading.


### Geofence editing
The geometry of geofences that are drawn or loaded from the backend can be changed by the user. The basic editing itself is provided by _leaflet-draw_. The map can be put into an edit mode, where individual points of polygons can be moved by the user. After this, the editing action can be confirmed or cancelled.

Since multiple polygons can be edited at once, all further actions need to be performed iteratively for an array of edited layers. Each geofence is converted to a JSON object and sent in a PATCH request to the endpoint _/geoFences/{id}_.

In case of a backend error, the window is reloaded to restore the correct state of all geofences before editing, since the Leaflet map has already saved the changes to the polygons. A more complex solution, like saving a copy of the geofences' geometries before changes are made and then overwriting the map's geometry with this copy in case of an error, would remove the need for a complete reload, but was considered too complex to implement.


#### Single edit functionality
It was considered to implement the edit feature in a way that individual geofences could be set to edit mode, instead of having a global edit mode that can be toggled for all geofences at once. This would likely have performance benefits, as it was observed in manual testing that response times of the interface increased with the number and complexity of loaded geofences, particularly when edit mode was enabled. 

The functionality would be achieved by storing an \lstinline!editable! flag for that geofence, and then only rendering geofences that have this flag inside the \lstinline!FeatureGroup!.

This feature did not work as intended, as the Leaflet map did not re-render the geofences correctly. Also, the performance benefit from this became less of a priority after pagination was implemented.


#### Making loaded geofences editable
To make all geofences editable (not just those that were drawn, but also those that were loaded from the backend), all geofences are stored in a collection, which is then used to render all editable geometry inside a separate \lstinline!FeatureGroup! in the map.

The geofences fetched from the backend are iterated over and a new Leaflet polygon (\lstinline!L.polygon!) is created in the frontend from each geofence's coordinates. The code for creating geofences from the backend data is shown in listing 3.7.

\begin{lstlisting}[caption=Geofences are fetched and added in frontend, label=lst:geofenceLoading, language={JavaScript}]
    for (let elem of res.data.geoJson) { // iterate fetched geofences
    let currentGeoFence = JSON.parse(elem);

    // swap lat and long
    for (let coordinateSubArray of currentGeoFence.Polygon.coordinates) {
        for (let coordinatePair of coordinateSubArray) {
        let temp = coordinatePair[0];
        coordinatePair[0] = coordinatePair[1];
        coordinatePair[1] = temp;
        }
    }

    currentGeoFence.Hidden = tempVisibilityObj[`id_${currentGeoFence.ID}`] || false;
    let newPoly = L.polygon(currentGeoFence.Polygon.coordinates); // create polygon from coordinates of fetched geofence
    newPoly.geoFence = currentGeoFence; // add geofence object in polygon object (for later use of metadata)
    newGeoFences.set(currentGeoFence.ID, newPoly);
    }
\end{lstlisting} \

The \lstinline!LeafletMap! component contains a \lstinline!FeatureGroup!, which includes the component \lstinline!MyEditComponent! from Leaflet Draw. This means that all geofences that are rendered in this same \lstinline!FeatureGroup! are affected by Leaflet Draw and can therefore be edited. Listing 3.8 shows this FeatureGroup, containing the EditComponent as well as the code for rendering the geofences.

\begin{lstlisting}[caption=Rendering editable geofences, label=lst:geofenceEditing, language={JavaScript}]
    <FeatureGroup>
        <MyEditComponent /* for on-map drawing functions */
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
                <MyPolygon /* custom polygon component for handling visibility and color */
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
\end{lstlisting} \


#### Non-editable geofences
Circular geofences and road geofences cannot be edited. Since all geofences are stored as polygons in the backend, circles are converted to an equilateral polygon with over 100 vertices. Moving individual points to change the circle's center or radius would be infeasible for the user. The same applies to road geofences, which, once stored as polygons, cannot be converted back to a route that can easily be changed.

To be able to make certain geofences not editable, all geofences are given a boolean property \lstinline!isNotEditable!, which is set to true in the backend for geofences created via the circle or road endpoints. This property is then used to separate all editable from all non-editable geofences, and render only those that can be edited inside the edit-FeatureGroup in the map. Listing 3.9 shows a simplified version of the map component, with individual rendering for editable and non-editable geofences.

\begin{lstlisting}[caption=Rendering non-editable geofences, label=lst:geofenceEditing, language={JavaScript}]
    <MapContainer /* shortened */ >
        {/* shortened */}

        {/*display non-editable geofences (circles, roads and geofences generated from presets)*/}
        {[...geoFences.keys()].filter(id => {
            return (geoFences.get(id).geoFence.SystemGeoFence || geoFences.get(id).geoFence.IsNotEditable)
        }).map(id => {
            return (
                <MyPolygon /* shortened */ ></MyPolygon>
            );
        })}

        <FeatureGroup>
            <MyEditComponent /* shortened */ ></MyEditComponent>

            {/*display editable geofences (not circles or roads) inside edit-featuregroup*/}
            {[...geoFences.keys()].filter(id => {
                return (geoFences.get(id) && !geoFences.get(id).geoFence.SystemGeoFence && !geoFences.get(id).geoFence.IsNotEditable)
            }).map(id => {
                return (
                    <MyPolygon /* shortened */ ></MyPolygon>
                );
            })}
        </FeatureGroup>
    </MapContainer>
\end{lstlisting} \


### Map search
A search function exists, to make it easier to find places on the map by searching for names or addresses. This function is provided by the package _leaflet-geosearch_, which can be used with minimal effort and was only slightly customized.

A custom React component \lstinline!GeoSearchField! is used, the code for which can be seen in listing 3.10. In this component, an instance of \lstinline!GeoSearchControl! provided by _leaflet-geosearch_ is created with customization options, which is then added to the map in the \lstinline!useEffect! hook. The component \lstinline!GeoSearchField! also has to be used inside the LeafletMap in order to make the search button available on the map.

\begin{lstlisting}[caption=addingMapSearch, label=lst:mapSearch, language={JavaScript}]
    import { GeoSearchControl, OpenStreetMapProvider } from 'leaflet-geosearch';
    import { useMap } from 'react-leaflet';
    import { useEffect } from 'react';
    import { withLocalize } from 'react-localize-redux';
    import '../../css/GeoSearch.css';

    const GeoSearchField = ({translate, activeLanguage}) => {
        let map = useMap();

        // @ts-ignore
        const searchControl = new GeoSearchControl({ // define search control with options
            provider: new OpenStreetMapProvider({params: {'accept-language': activeLanguage.code.split("-")[0]}}),
            autoComplete: true,
            autoCompleteDelay: 500,
            showMarker: false,
            showPopup: false,
            searchLabel: translate("searchGeo.hint"), // handle multi-language support
            classNames: { // used for custom styling
                resetButton: 'gs-resetButton',
            }
        });

        useEffect(() => {
            map?.addControl(searchControl); // add search control to map
            return () => map?.removeControl(searchControl);
        }, [map])

        return null;
    }

    export default withLocalize(GeoSearchField);
\end{lstlisting} \


### Geofence labels
A label is displayed for every geofence in the map to make it easier to associate a geofence with its corresponding polygon. Leaflet itself can display labels for polygons, however, these default labels have some problems. The precision with which the position of the label is calculated appears to be limited by the initial zoom value set for the map, meaning that with a lower default zoom, the label is sometimes either not centered within or completely outside its polygon. An example of this is shown in figure 3.6. 

\begin{figure}[H]
	\centering
  \includegraphics[width=0.70\textwidth]{source/figures/Label_precision_problem.png}
	\caption{Labels (top left) are displayed at the same point and outside their corresponding polygons (bottom right)}
	\label{3_6}
\end{figure}

This problem can be solved by starting at a higher initial zoom level, but to keep flexibility in this regard, labels are added manually by rendering a marker on the map for each polygon at a calculated position.


#### Finding optimum label position
Since the default labels were replaced with custom markers, the position of these relative to the rectangle has to be calculated manually. There are several ways in which this can be done, which will be described in detail.


##### Average of points
The label position can be calculated by taking an average of the coordinates of all points of the polygon. This is a good approximation for simple, convex shapes with evenly distributed points. However, if points are distributed unevenly, meaning there is more detail on one side than the other, the average will shift to that side, and the calculated point will not appear centered anymore.

This approach can also lead to problems with concave geometry, when the calculated center is not part of the polygon, causing the label to appear outside the geometry. This is especially relevant for road geofences, but can also affect simpler geometries like a U-shape as demonstrated in figure 3.7 below.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.70\textwidth]{source/figures/Label_outside_concave_geometry.png}
	\caption{Geofence label displayed outside a concave polygon's geometry}
	\label{fig3_7}
\end{figure}

\newpage

##### Center of bounding box
The label can be placed at the center of the bounding box of the polygon, which can easily be done by using basic leaflet methods, as shown in listing 3.11.

\begin{lstlisting}[caption=Get center of bounding box, label=lst:labelPosition, language={JavaScript}]
    polygon.getBounds().getCenter()
\end{lstlisting} \

This approach solves the problem with unevenly distributed points, because the center is always calculated from a rectangle with exactly four points. However, it is not a solution for concave polygons like the U-shape described above.


##### Pole of inaccessibility
The node package _polylabel_ [@polylabelIntro] uses an algorithm to calculate a polygon's _pole of inaccessibility_, defined as the point within the polygon's area with the largest distance to its outline.

This approach solves the problem with concave shapes, because the calculated point always lies inside the polygon, and for this reason, it was used to calculate the label positions in the app. Figure 3.8 shows the same concave geofence as above, but with the pole of inaccessibility used to calculate the label's position.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.70\textwidth]{source/figures/Label_pole_of_inaccessibility.png}
	\caption{Geofence label placed at the pole of inaccessibility}
	\label{fig3_8}
\end{figure}

#### Dynamic label size
The size of the geofence labels changes depending on the current zoom level of the map, getting smaller as the user zooms out further, and is hidden for any zoom level smaller than or equal to 6. This dynamic sizing is achieved by using a CSS class selector that includes the current zoom level to select the corresponding option from the CSS classes _zoom6_ to _zoom13_. The code for this icon, including said selector, is shown in listing 3.12.

\begin{lstlisting}[caption=Icon with dynamic class name, label=lst:dynamicLabelSize, language={JavaScript}]
    return L.divIcon({
        className: "",
        html: `<div class="tooltipMarker ${"zoom" + (zoomLevel > 6 ? zoomLevel : 6)}">${title}</div>`,
    });
\end{lstlisting} \


### Geofence deletion
All geofences, whether they were created by drawing, route creation or from a system geofence, can be deleted via the user interface. A geofence is first deleted from the database by sending a DELETE request to the endpoint _/geoFences/${id}_ of the backend. In case of a success, the geofence is then also deleted directly from the React state to avoid having to re-fetch geofences.


### Geofence edit history
It was initially planned to display when changes were made to a geofence, and by which user. This would be implemented as a list containing the username of the editor and a timestamp. Since the feature is not intended as a versioning system for geofences, the current state of the geofence or the changes to the geometry are not saved. The list was later changed to include only a timestamp after the company changed some demands regarding how the login and user management would work, and the username became redundant.

To keep track of edit events, a timestamp is added to a geofence every time it is created or updated in the backend.

The edit history is accessed in the frontend when the geoFences are fetched from the server, and is then filtered and passed to the corresponding geofence list item to be displayed in an info card.


### Geofence visibility
Individual geofences can be hidden from the map to make it visually clearer. To achieve this, a boolean tag \lstinline!Hidden! is stored for each geofence. For any geofence where this tag is set to true, no React Leaflet polygon is rendered in the map, and it is instead replaced with an empty tag. This has the added benefit of not rendering the polygon's geometry on the map, which was found to improve frontend performance significantly when geofences with large numbers of points are hidden.

#### Storing geofence visibility
It can be assumed that in most cases when the user hides a geofence, they want to do so permanently or at least indefinitely, for example with system geofences, geofences with a large number of points or generally rarely used ones. Therefore, it makes sense to store the information about which geofences are hidden even when the app is closed. This is achieved by using _localStorage_, which, in contrast to _sessionStorage_, persists data until it is explicitly deleted. Listing 3.13 shows the code for retrieving visibility information from localStorage.

\begin{lstlisting}[caption=Geofence visibility is saved to localStorage, label=lst:geofenceVisibility, language={JavaScript}]
    let obj = {...visibilityObj};

    newGeoFences.forEach(e => {
        obj[`id_${e.geoFence.ID}`] = e.geoFence.Hidden || false; // if no value is stored, set as not hidden
    });

    setVisibilityObj(obj);
    localStorage.setItem("visibility", JSON.stringify(obj)); // save to localStorage
\end{lstlisting} \


### Geofence highlighting
Any geofence can be highlighted, setting the map view to show it, as well as changing it to a highlight color (green). The action of moving the map to the location of the highlighted geofence is achieved by using the Leaflet function \lstinline!map.flyToBounds!, which changes the map's center and zoom level to fit the bounds of the given geometry and also includes a smooth animation.

A boolean tag \lstinline!Highlighted! is stored for every geofence. Some special cases have to be considered in combination with the geofence visibility feature:

- If a geofence is highlighted, and its tag therefore set to be true, the tag of all other geofences is set to be false, to ensure that only one geofence is highlighted at a time.
- If a hidden geofence is highlighted, it is also unhidden.
- If a highlighted geofence is hidden, it is also set to not be highlighted.

The state chart diagram in figure 3.9 describes the different states a geofence can have regarding hiding and highlighting, as well as the actions that lead to changes.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/Geofence_visibility_state_chart.png}
	\caption{Geofence visibility states and their interaction}
	\label{fig3_9}
\end{figure}

### Geofence renaming
Any geofence can be renamed in the Web-Interface. When the "Rename"-button is clicked, the user is shown a text dialog to enter a new title. A request with this new title is then sent in a PATCH request to the endpoint _/geoFences/${id}_ of the backend, where the database entry is updated. In case of a success, the title is also changed in the React state directly.


### Geofence metadata
During the internship, the company decided to market the app to smaller districts and specifically, to be used for tracking road maintenance and snow clearing vehicles, which would make it necessary to store additional data for a geofence, like the workers tasked with working on a particular road.

A metadata system was added, which allows for different metadata categories in which data entries can be added in the form of a collection of strings.\
The app contains two categories, _Workers_ and _Others_, which are hardcoded in both the frontend and backend because they are unlikely to change and can be added manually in the code if needed. If the number of categories unexpectedly increases, or if the user should be able to add categories by themselves, a dynamic management system would be advantageous.

Metadata can be viewed and edited in a dialog window for each geofence. Selecting one of the categories shows all entries for that geofence in that category. New entries can also be created in this category, and existing entries can be deleted. The ability to edit entries is deliberately omitted because they are strings and usually very short, making it just as easy to delete and re-enter incorrect metadata.

All geofence metadata is stored in an array separate from the geofences themselves, and is fetched with a GET request to the endpoint _/GeoFenceMetadata_ on application start or reload. The data is filtered by _id_ of the geofence for display in the dialog.

On adding a new entry, a POST request is sent to the _/GeoFenceMetadata_ endpoint, which in case of a success returns the _id_ of the new database object, which can be sent to the endpoint in a DELETE request, enabling an entry to be deleted from the database directly after creation without the need to re-fetch the data.


#### Metadata search
The app includes a search bar, to filter geofences based on their metadata entries, which consists of dropdown to select the metadata category, a text field to enter a search string, and a search button.

When the search button is pressed, a GET request is sent to the backend containing the category as well as the search term, to the endpoint\
_/geoFences/search?searchTerm=\${searchTerm}&metadataCategory=${category}_, which returns a collection of all geofences that fit the search. The actual search process is handled on the backend. The React state is then updated to include the returned geofences, and only these geofences are displayed in the user interface.


### Geofence locking
One of the main use cases of the app is theft protection. An object (a car or machine) can be tracked with the DriveBox, and if it leaves a geofence, an alarm can be sent out. For this feature, there is also the option to lock geofences on certain days of the week, so that for example no alarm is triggered on the weekend.

In the app, every geofence has a button for each weekday, which shows the current state and allows the user to toggle the lock on or off. When one of these buttons is pressed, a GET request is sent to the endpoint _/geoFences/${id}/${weekday}/2_, including the _id_ of the geofence, the weekday and the locking method, with the following options:

- 0: lock
- 1: unlock
- 2: toggle locking

All geofence locks are fetched on app start or reload with a GET request to the endpoint _/geoFences/timelocks_, which returns a map object containing all geofences that have locks, each with a list of all weekdays that are locked. This map is stored in the React state separate from the geofence and metadata collections.

### Pagination
The geofence list in the app includes a pagination feature, to reduce the number of loaded geofences for performance improvement, and to make the user experience clearer by showing less elements at once. The feature includes buttons to go to the next and previous as well as to the first and last page, an input to go to a specific page requested by number, and the option to set the number of elements that should be displayed on every page.

The currently selected page and page size are stored in the React state and in a site cookie, so the user can stay on the same page when reloading. When a new page is requested by pressing a button or entering a page number, or when the page size is changed, a GET request is sent to the endpoint _/geoFences?size=\${size}&page=${page}_, which returns a collection of geofences corresponding to the page number of the given page size, and the total page count, which is used in the frontend for display and for checking if a next or specific page can be requested.

The task of determining what geofences should be returned in which page is handled by the backend, eliminating the need to have all geofences available in the frontend, and therefore improving frontend performance.


### Geofence display color
The user can select from a variety of display colors for the geofences on the map, for better contrast and visibility or because of personal preference. This is a global setting, meaning that the color can be changed for all geofences at once. It is not possible to set different colors for individual geofences.

The currently selected color is stored in a React state variable and used when drawing the polygons on the map. Highlighted geofences are always colored green, overriding the global geofence display color.


### Bulk operations
The app includes the option to perform certain actions for multiple geofences at once, including locking actions and geofence deletion. Backend requests are sent for each selected geofence individually, which is not problematic in terms of performance, but allows further room for improvement, for example by implementing a special endpoint for bulk operations to be handled by the backend.


#### Selection checkboxes
To allow the user to select geofences for which the bulk operations should be performed, a checkbox is added to each geofence in the list. An array of all currently selected geofences' ids is stored in the React state, and if a geofence is selected or deselected, its id is pushed into this array or removed from it.

Because the checkboxes are part of custom list elements, a select-all-checkbox also has to be added manually. The current _selectAllState_ (NONE, SOME or ALL) is determined after every clickEvent on a checkbox by counting the number of selected geofences, and is used to show an unchecked, indeterminate or checked select-all-checkbox respectively. This checkbox can also be clicked itself to select all loaded geofences if none are selected, or to deselect all if some or all are selected. Listing 3.14 shows the customized checkbox component as it was used in the app.

\begin{lstlisting}[caption=Checkboxes are displayed depending on selectionState, label=lst:selectionCheckboxes, language={JavaScript}]
    <Checkbox
        id="cb_all"
        style={{ color: buttonColors.bright }}
        indeterminate={selectAllState === selectionState.SOME}
        checked={selectAllState !== selectionState.NONE}
        onChange={() => onSelectAllChanged()}
    ></Checkbox>
\end{lstlisting} \


#### Bulk locking
Bulk actions are available for locking, unlocking and toggling locks for geofences on any weekday individually or on all weekdays at once. A function, which is shown in listing 3.15, is called with the weekday and the lockMethod (0 for locking, 1 for unlocking and 2 for toggling). For all selected geofences, the locking is performed as described in chapter _Geofence locking_. If it should be performed for all weekdays, indicated by a value for _weekday_ of -1, the function \lstinline!lockActionMulti! is called recursively for every weekday value from 0 to 6.

\begin{lstlisting}[caption=The function for handling bulk locking operations, label=lst:bulkLockingFunction, language={JavaScript}]
    function lockActionMulti(weekday, lockMethod) {
        let weekdaysToLock = []; // use array to allow handling of multiple days
        if (weekday === -1) // all weekdays
            weekdaysToLock = [1, 2, 3, 4, 5, 6, 0];
        else
            weekdaysToLock = [weekday];

        let newGeoFenceLocks = geoFenceLocks;
        for (let currentDayToLock of weekdaysToLock) { // repeat for each weekday
            for (let id of selection) { // repeat for each selected geofence
                switch (lockMethod) {
                    case 0: lockDay(newGeoFenceLocks, id, currentDayToLock);     break;
                    case 1: unlockDay(newGeoFenceLocks, id, currentDayToLock);   break;
                    case 2: toggleDay(newGeoFenceLocks, id, currentDayToLock);   break;
                    default: return;
                }

                callBackendLocking(id, weekday, lockMethod); // locking on backend, separately from frontend in state
            }
        }
        setGeoFenceLocks({...newGeoFenceLocks});
    }
\end{lstlisting} \


#### Bit masking
A bit mask is a technique used to store and access data as individual bits, which can be useful for storing certain types of data more efficiently than would normally be possible [@bitmasks].

This could be used as an alternative way to store the days on which a geofence is locked. Since there are seven days, a mask with at least seven bits has to be used, where the first bit represents Monday, the second bit represents Tuesday, and so on. Each bit can be either true (1) or false (0), indicating if that day of the week is locked or not. This way, every combination of locked days can be represented by using one number between 0 (0000000) and 127 (1111111).

- To set an individual bit (set it to 1/true), an OR operation is used on the storage variable and the value 2^n, where n is the number of the bit starting from the least significant bit on the right at n=0.
- To delete an individual bit (set it to 0/false), an AND operation is used on the storage variable and the inverse of 2^n (the value after a NOT operation).
- A bit can be toggled with an XOR operation on the storage variable and the value 2^n.
- By using an AND operation on the storage variable and 2^n, the value of an individual bit can be read.


## Performance optimization on the frontend
\fancyfoot[L]{Ambrosch}
Optimizing frontend performance can have several positive effects, including, but not limited to:

- minimizing lag and making the UI more responsive.
- minimizing loading times and load on the network by reducing the number of backend calls.
- allowing the app to run on less powerful devices.

Hereafter, some particular considerations that were taken in the geofence web-interface are described in greater detail. This includes the methods used to record performance data and find potential issues as well as the changes made to fix those issues.


### Reduction of component re-renders
During testing, it was found that one of the biggest factors affecting performance of the React app is the number of component re-renders, especially unnecessary re-renders which happen after changes to parameters of a component that have no actual effect on that component. Reducing the number of these re-renders is important to improve frontend performance and therefore usability.


#### Measuring component render times
To improve frontend performance, the render times of all components have to be recorded in order to find out which elements contain potential bottlenecks and must therefore be optimized.

_React Developer Tools_ [@reactDevToolsChrome] is a _Chrome_ extension that adds React debugging tools to the browser's Developer Tools. There are two added tabs, _Components_ and _Profiler_, the latter of which is used for recording and inspecting performance data.

The _Profiler_ uses React's Profiler API to measure timing data for each component that is rendered. The workflow to use it will be briefly described here [@reactProfilerIntro].

- After navigating to the _Profiler_ tab, a recording can either be started immediately or set to be started once the page is reloaded.
- During the recording, the actions for which performance needs to be analyzed are performed in the React app.
- Once all actions are completed, the recording can be stopped again.

The recorded data can be viewed in different graphical representations, including the render durations of each individual element. When testing performance for this app, mostly the _Ranked Chart_ was used, because it orders all components by the time taken to re-render, which gives the developer a quick overview of where improvements need to be made.


#### Avoiding unnecessary re-renders
Figure 3.10 shows a graph of the geofence management app recorded with the _Profiler_. By looking at this graph, it can be seen that the _LeafletMap_ component takes significantly more time to re-render than all other components and should therefore be optimized.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/React_Profiler_before.png}
	\caption{Ranked profiler chart shows long render times for LeafletMap}
	\label{fig3_10}
\end{figure}

The map component is wrapped in _React.memo_ in order to re-render only when relevant props have changed. In the case of this app, that means a change in the collection of geofences to be displayed, a change regarding road geofence creation that is displayed in the map, polygon color or some meta settings. With a custom check function \lstinline!isEqual!, which can be seen in listing 3.16, the _React.memo_ function can be set to re-render only when one of these props changes.

\begin{lstlisting}[caption=Using React.memo with custom equality check, label=lst:reactMemo, language={JavaScript}]
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
\end{lstlisting} \

After making these changes, a new graph is recorded for the same actions, which can be seen in figure 3.11. The render duration of the map component has been reduced from 585.6 ms to a value clearly below 0.5 ms, where it does not show up at the top of the _Profiler_'s ranked chart anymore. This has the effect that the application now runs noticeably smoother, especially when handling the map, since the _LeafletMap_ component does not update every time the map position or the zoom changes.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/React_Profiler_after.png}
	\caption{Ranked chart after implementation of performance optimizations}
	\label{fig3_11}
\end{figure}

Similar changes are also applied to other components that were found to cause lag or re-render unnecessarily.


### Reduction of loaded geofences
During manual testing of the app, it became clear that frontend performance is connected to the number of geofences that are loaded at any given point in time. This effect was magnified when multiple geofences with high point counts, like state presets or road geofences, were displayed at once. This appears to be a limitation inherent to the Leaflet map that cannot be fixed in itself. Instead, the user of the app is given the option to have less geofences shown on the map at once.

A pagination feature, as described in chapter _Pagination_, splits the total collection of geofences and only displays a portion in the frontend list and map. The feature also allows the user to change the number of geofences to be displayed per page, which can be set higher if performance allows it or lowered if otherwise.

A geofence hiding feature, as described in chapter  _Geofence visibility_, also makes it possible to hide specific geofences from the map, which cleans up the view for the user, but can also improve performance by not rendering particularly complex geofences.


### Reduction of editable geometries
While the edit mode provided by Leaflet Draw is enabled in the Leaflet map, all editable polygons are shown with draggable edit markers for each point of their geometry. These edit markers, when present in large quantities, cause considerable lag when edit mode is enabled. To improve this, certain geofences are marked as non-editable and are not shown in the map's edit mode, as described in chapter _Non-editable geofences_.


### Reduction of backend calls
Performance of the frontend interface is improved by minimizing the number of requests made to the backend, by avoiding techniques like polling. This reduces the total loading times and load on the network, and also makes some UI elements more responsive by not relying on backend data for updates.


#### Polling geofence locks
In the initial implementation of the bulk operations for locking (chapters _Locking_ and  _Bulk operations_), when an action was performed, the weekday/locking buttons for each affected geofence did not update as expected.\
The reason was that the locks for each geofence were stored in the React state of that geofence's _GeoFenceListItem_ component and were fetched for that geofence alone only once on initial loading of that component. This means that, when a bulk operation is performed in the parent _GeoFenceList_ component, no re-render is triggered and the locks are not updated in the _GeoFenceListItem_, since non of its props have changed.

To solve this problem, a polling mechanism was implemented, where the _GeoFenceListItems_ repeatedly call the backend after a fixed interval of time. Any updates that happen in the backend are now displayed in the frontend, albeit with a slight delay depending on the interval set for polling.\
Performance is notably affected by this approach, due to the high number of network calls, even when no locking data has changed.


#### Lifting state up
While there are workarounds to force a child component to re-render from its parent [@reactForceChildRerender], in this case, it is more elegant to _lift the state_ of the geofence locks from the _GeoFenceListItems_ to a parent component like _GeoFenceList_ or _Home_.\
Now, when the state changes in the parent component, for example through geofence bulk locking operations, all child components are automatically updated by React and the changes to geofence locks can be seen immediately [@reactLiftingStateUp].

