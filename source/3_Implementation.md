# Implementation
This chapter describes the concrete implementation of the software. This includes technologies as well as the technical implementation in the ASP.NET Core backend, the Microsoft SQL Server as well as the React frontend. Frameworks as well as major third party libraries are explained alongside standardized formats. Certain technologies will also be compared with similar alternatives to achieve the desired results as well as explanations given on why one was chosen. Furthermore algorithms to calculate intersections with geofences will be explained. 


## Backend Technologies used
The backend consists of two major parts, those being the ASP.NET Core webservice and the Microsoft SQL Server database. With ASP.NET Core running on top of the C# programming language, third party libraries are obtainable using the NuGet package manager. All functionality on the database is natively provided and doesn't require the installation of any further extensions. To work with the database and geographical objects the webservice needed to be extended with libraries such as ADO.NET and NetTopologySuite.


### ASP.NET Core
ASP.NET Core is a framework for building web apps and services, IoT apps as well as mobile backends developed by Microsoft as an evolution of ASP.NET 4.x. Unlike its predecessor ASP.NET Core is multiplatform (contrary to just being working on Windows) and open source. Besides creating traditional webservices, such as RESTful webapps, it can also be used to create other webapps using technologies like Razor Pages and Blazor. [@aspintro]

#### Project Creation
When creating a new project using Visual Studio 2019's template of a ASP.NET Core webservice, a workspace is created included a project. This project additionally includes two files, *Program.cs* and *Startup.cs*. Program.cs includes the basic instructions needed to get a ASP.NET Core application running additionally to defining which Startup object should be used. Logging behavior can also be defined in this file. The web application is created by using the default *WebHostBuilder*.

\begin{lstlisting}[caption=The backends Programm.cs file., label=lst:programmcs, language={[Sharp]C}]
      public class Program
      {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                    webBuilder.ConfigureLogging((hostingContext, logging) =>
                    {
                        logging.AddConfiguration(hostingContext.Configuration.GetSection("Logging"));
                        logging.AddConsole();
                        logging.AddDebug();
                    });
                });
      }
\end{lstlisting} \

To setup the REST endpoints of the webservice the Startup.cs file needs to be modified. Furthermore the method *ConfigureSerivces* is provided, which is used to register controllers, services, singletons and the cache to the application at runtime. Additionally HTTP typical functionality such as authorization and CORS are also configurable in Startup.cs.

\begin{lstlisting}[caption=The backends Startup.cs file shortened for readability., label=lst:startupcs, language={[Sharp]C}]
      public class Startup
      {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {

            services.AddControllers();
            services.AddHttpContextAccessor();
            services.AddScoped<ICollisionDetector, TripCollisionDetectionService>(); //Add a new Service for each Request via Dependency Injection
            
            services.AddMemoryCache(); // Create the cache
            services.AddSwaggerGen(c =>
            {
                c.SwaggerDoc("v1", new OpenApiInfo { Title = "DriveboxGeofencingBackend", Version = "v1" });
                var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
                var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
                c.IncludeXmlComments(xmlPath);
            }); // Initialize Swagger documentation
            services.AddDbContext<ApplicationDbContext>(o => o.UseSqlServer(Configuration.GetConnectionString("sqlServer"), x => x.UseNetTopologySuite()));
            services.AddCors(o => o.AddPolicy("wildcardCors", builder =>
            {
                builder.AllowAnyOrigin()
                       .AllowAnyHeader()
                       .AllowAnyMethod();
            }));
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
                app.UseSwagger();
                app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "Drivebox Geofencing Backend v1"));
            }

            app.UseHttpsRedirection();
            app.UseRouting();
            app.UseAuthorization();
            app.UseCors("wildcardCors");
            app.UseAuthHeaderMiddleware();
            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }
      }
\end{lstlisting} \

#### Services
Services are classes serviced by the application by making use of Dependency Injection. After registering a service in the Startup.cs file, it can be accessed from anywhere within the application using the associated interface. To define a service, it must simply be registered in Startup.cs, the service itself therefore does not "know" of itself as being one. Services consist of two files, an interface and an associated class which implements the defined methods. 

When registering a service there are three different options to choose from. These options are also defined as lifetimes.
1. Transient
   : Whenever this service is requested a new instance is created. This lifetime works best for non resource intensive services. Once a request ends these services are disposed.
2. Scoped
   : Scoped services are created once per client request meaning that they have the same behavior as transient services in a web application.
3. Singleton
   : Singleton services are created once the first time they are requested. When the service is requested again the same instance is provided to the requesting object. Singleton objects are disposed once the application shuts down. These services are used when there has to be exactly one instance of a service, for the geofencing application this was chosen when creating the database manager service.
[@servicelife]

To request a service from the application a class must simple include the services interface in its constructor. Providing the associated service object is then handled by ASP.NET Core.

\begin{lstlisting}[caption=The TimePointController requesting two services., label=lst:servicereq, language={[Sharp]C}]
         public TimePointController(ICollisionDetector collisionDetector, IPointAnalyzer pointAnalyzer)
         {
            this.collisionDetectorService = collisionDetector;
            this.pointAnalyzer = pointAnalyzer;
         }
\end{lstlisting} \

#### Middleware
To handle requests in a common way regardless of routes the concept of middleware can be used. ASP.NET Core works on a concept of a request entering the system, getting processed by middleware and then returning a response. Therefore the acts of routing a request, checking CORS, authorization and authentication as well as handling the request on an endpoint is considered middleware. The developer now has the ability to insert custom middleware into this pipeline. Middleware can either pass along the request to the next middleware and the pipeline or terminate the request. When a request is terminated it is passed back in the reverse order of operations before being returned as a response. To pass a request along the call *await next.Invoke()* is used. [@middleware]

![Example of a middleware workflow.](source/figures/middleware_pipe.png "Screenshot"){#fig:middleware width=90%}
\  

To add custom middleware into the ASP.NET Core pipeline, the developer must simply register it in the Startup.cs file. To do this the *IApplicationBuilder* interface must be extended with a method registering the middleware. This methods is then called in the startup file.

\begin{lstlisting}[caption=Extending the IApplicationBuilder interface., label=lst:middlewareext, language={[Sharp]C}]
      // Extension method used to add the middleware to the HTTP request pipeline.
      public static class AuthHeaderMiddlewareExtensions
      {
        public static IApplicationBuilder UseAuthHeaderMiddleware(this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<AuthHeaderMiddleware>();
        }
      }
\end{lstlisting} \

#### Controller
Controllers are classes which handle the routing and processing of requests to the web service. When using the annotation *[ApiController]* a controller is declared as an API controller. This holds the benefit of automatically converting responses to a requested format like JSON or XML. Alongside the ApiController annotation the *[Route(route)]* annotation is used to set a general route for all requests going into this controller. An example of this would to use *[Route("api/v1")]* resulting in every request to https://driver.box/api/v1 being routed through this controller.

To map methods to routes and HTTP methods a different set of annotations needs to be used on the desired methods. To associate a method with a route and a method, two annotations need to be used. Firstly, the *[Route(route)]* annotation is reused from the controller. To register the method to a specific HTTP methods ASP.NET Core provides several annotation.
- HttpGet
- HttpPost
- HttpPut
- HttpPatch
- HttpDelete
- HttpOptions
- HttpHead

Each annotation corresponds to the HTTP method with the same name. Apart from routing purposes they do not provide any functionality to the developer. Building the application according to REST and HTTP principles therefore remains a responsibility of the developer.

Controllers provide the ability to plainly return objects as a JSON representation by setting the associated class as a return type. To receive more control over the response the return type must be set to *IActionResult*. This interface is implemented by several classes representing HTTP status codes. If there is no such classes implemented for a specific status code then *StatusCode* can be used as a code can be customly assigned to it.

\begin{lstlisting}[caption=Return a No Content response., label=lst:nocontent, language={[Sharp]C}]
       return StatusCode(204);
\end{lstlisting} \

\begin{lstlisting}[caption=Return an OK response with status code 200., label=lst:okaycode, language={[Sharp]C}]
       return Ok(databaseManager.GeoFenceHistoryById(idGeoFence));
\end{lstlisting} \

### Microsoft SQL Server
SQL Server is a relations database management system developed by Microsoft. Similar to other systems such as Oracle, MySQL and PostgreSQL is runs on top of SQL. Additionally it uses Microsofts own SQL dialect for instructions. Transact-SQL, also known as T-SQL. To work with SQL Server a tool such as SQL Server Management Studio (SSMS) is required, this is also provided by Microsoft. SSMS provides a view of all functionality provided by SQL Server in a directory like view. The developer is able to easily create plain T-SQL statements in the editor as well as procedures and triggers.

#### Transact-SQL
T-SQL is an extension of the standard SQL language. It provides further features to the developer when creating database statement to increase the simplicity and performance of queries. The basic syntax of querying data and defining statements remains the same. An example of this is the *TOP* keyword which is used to only displayed the first x results of a query. This keyword only exists within T-SQL and is not usable when working the standard SQL. [@tsql]

\begin{lstlisting}[caption=Example of using the TOP keyword., label=lst:topkeyword, language={SQL}]
    SELECT TOP 12 Id, Name, Description 
    FROM Products ORDER BY Name;
\end{lstlisting} \

##### Tables
To create tables with T-SQL a syntax similar to the SQL one is required. Tables consist of attributes and constraints. Each attribute in a table has a name and a datatype alongside information if it is allowed to be NULL. Attributes may also be referred to as columns. Constraints are special conditions data must fulfill to be insert into the table. The most important constraints in a table are the following:

1. Primary Key
   : Primary keys are indexes applied to a single or multiple columns in a table. These columns are often also seen as the identifying columns of a table used to reference data inside this table in a different one. There can only be one primary key per table.
2. Unique
   : Functionally has the same behavior as a primary key. The only difference being that there can be multiple unique constraints and the values of the affected columns may be NULL.
3. Foreign Key
   : Foreign key constrains are used to associate a column with another column in a different table. This may only be done if the column(s) on the referenced table are either part of a primary key or a unique constraint. When data related to the foreign key is deleted on the associated table there are different handling approaches. Firstly nothing can be done about it at all and the values of the foreign key columns stay the same. Secondly the delete may be cascaded downwards and the row referencing the deleted row is also deleted. Finally the value of the foreign key columns can also be set to NULL.
4. Check 
   : The check constraint is used to check if a certain condition applies. This can be used to specify a certain allowed age range as an example.

In the geofencing application a combination of several constraints was used to create the tables needed for the application to function. The relationships are best described using an UML-diagram.

![Logical Model of the Database.](source/figures/db_model.png "Screenshot"){#fig:dbmodel width=90%}
\ 

##### Procedures
Stored procedures are segments of code which are compiled and executed on the database server. Contrary to a function, a procedure does not have a return value and processed values can only be passed along using out variables. Creating a procedure on SQL Server is simplified by using the GUI of SSMS to create a template of a procedure. Inside the procedure a sequence of T-SQL commands is being executed. Procedures provide the ability to make use of typical programming control structures such as conditions and loops. To execute a stored procedure the *EXEC* command can be used in the SQL editor or the functions provided by libraries in C# like ADO.NET. 

Variables can be declared inside the body of a stored procedure. These can have a name and a datatype. A special useable datatype for these variables is *TABLE* which creates a temporary table for results of a select to be saved in. Normal select queries can then be performed on this temporary table.

The geofencing application makes use of stored procedures in several ways. A main application is the creation of special geofences such as circles and roads, as those need a special type of processing. Next the logic for locking geofences on certain days of the weeks is also implemented using stored procedures. 

\begin{lstlisting}[caption=Procedure to create a circle geofence., label=lst:procCircle, language={SQL}]
    CREATE PROCEDURE [dbo].[createCircle] (@lat DECIMAL(18,10), @long DECIMAL(18,10), @radius INT, @title VARCHAR(300), @idUser uniqueidentifier(100))
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @idGeoFence INT;
        SET @idGeoFence = NEXT VALUE FOR SQGeoFence;
        INSERT INTO geoFence VALUES (@idGeoFence, @title, geography::Point(@lat, @long, 4326).STBuffer(@radius), 0, 1, @idUser);
        INSERT INTO geoFenceHistory VALUES (@idGeoFence, DATEDIFF(s, '1970-01-01', GETUTCDATE()));
        SELECT id, geoObj FROM geoFence WHERE id = @idGeoFence;
    END
    GO
\end{lstlisting} \

##### Trigger
Triggers are pieces of code that are executed when data in a table is modified. This can apply for adding, deleting or modifying rows. Triggers are created in a similar way to stored procedures and creation is equally simplified by SSMS. Contrary to procedures, triggers are assigned to a table along a specification if the code should be executed before or after data is inserted. On which action the code should be executed can also be specified. These actions can be specified as *INSERT*, *UPDATE* or *DELETE*. Triggers can be used to block data from being inserted into a table or insert data into another table based on the incoming data.

In the final version of the geofencing application, triggers are not used. They were implemented when calculation of intersections was still based on the database.

#### SQL Spatial
The spatial extension was an addition provided to SQL Server by Microsoft in 2008. It essentially adds two datatypes to the software, *geometry* and *geography*. These datatypes are provided along a set of functionality to perform spatial calculations and queries on the database. Spatial data is data with geometrical or geographical information attached to it. In most cases those are coordinates. Geometry and geography are different in the fact that geometry is indented for use in a flat coordinate system like a plane. Geography on the other hand is intended for use with globe like coordinates to reflect real world locations and objects. For persisting geofences in the database, geography was chosen, as it makes use of real world GPS coordinates. [@spatext]

On top of the basic data types, there are two mains groups of object types provided by the spatial extension. These objects are available for both geometry and geography-
1. Simple objects
   : Simple, single spatial objects that are completely connected in their instance. These include *Points*, *LineStrings* and *Polygons*.
2. Collection objects
   : Collections of simple objects with multiple independent instances. These include *MultiPoints*, *MultiLineStrings* and *MultiPolygons*.

To create these spatial objects the well-known-text (WKT) format is used. The spatial extension provides methods to create objects from WKT. To create a polygon from a WKT source, the method *geography::STPolyFromText(wkt, 4326)* is used. To create a point object, the method *geography::Point(lat, long, 4326)* is used. To create any other geography object the method *geography::STGeomFromText(wkt, 4326)* can be used. The number 4326 at the end of every methods specifies the coordinate system used for the object. This number is specified as the Spatial Referencing System Identifier (SRID). SRID 4326 is the system that specifies the latitudes and longitudes along the entire globe. For applications working in a specific area of the world which need an additional grade of coordinate accuracy another SRID can be chosen. Due to drivebox not needing accuracy in the range of centimeters and the market being open to grow the global SRID 4326 was chosen.

To manipulate and work with geographical data the extension provides a variety of methods. The geofencing application mainly makes use of the *STBuffer()* method on objects. This method increases the size of a object in every direction, turning it either into a Polygon or a MultiPolygon, depending on the initial object. It is used to create circle and road geofences on the database, as these use a Point and a LineString as a base respectively. These Polygons often have over one hundred points, resulting in a loss of performance on the frontend and when calculating intersections. To simplify these shapes, the method *Reduce(1)* is used. It removes unnecessary points of a Polygon and returns a new, more performant object with less points.

\begin{lstlisting}[caption=Creating of a circle., label=lst:statCircle, language={SQL}]   
    geography::Point(@lat, @long, 4326).STBuffer(@radius)
\end{lstlisting} \

### ADO.NET
To establish a connection from the ASP.NET Core application to the database a library is needed. Microsoft provides two options to implement these connections, *ADO.NET* and the *Entity Framework*. ADO.NET provides a selection of methods to work with SQL databases of all kinds. To work with a database a provider is needed. In case of SQL Server this is the Microsoft ADO.NET for SQL Server provider. For a database like Oracle another one would be used.

In the ASP.NET Core application database operations are managed by a *DatabaseManager* object. This object is created and distributed as a singleton service by making use of Dependency Injection. This way the existence of exactly one instance of the class is guaranteed across the whole application at runtime.

To create a connection to the database a new instance of the class *SqlConnection* is created. Passed along as a construction parameter is a connection string to specify the server and the database user credentials. To work with this connection it needs to be opened after creation.

\begin{lstlisting}[caption=Creating and opening a connection., label=lst:adoOpen, language={[Sharp]C}]   
                using (SqlConnection connection = new SqlConnection(SQL_STRING))
                {
                    connection.Open();
                }
\end{lstlisting} \

To send SQL command to the server a new instance of the *SqlCommand* class is created. This instance is constructed with a SQL command in form of a string as a construction parameter. To avoid the risk of SQL-Injection vulnerabilities variables defined by user inputs are being substituted by placeholders in the initial string. To specify a placeholder in a SQL string a variable name with an @ in front is used. An example of this would be using @geofenceName when inserting a new geofence into the database. To use the actual value instead of the placeholder a new parameter needs to be added to the SqlCommand object. This way no string concatenation is used and the data is handled directly by ADO.NET.

\begin{lstlisting}[caption=Creating a command to delete a geofence by id while using a placeholder for the id., label=lst:adoPlaceholder, language={[Sharp]C}]       
            SqlCommand cmd = new SqlCommand("DELETE FROM geoFence WHERE id = @id", connection);
            cmd.Parameters.Add(new SqlParameter("@id", System.Data.SqlDbType.Int));
            cmd.Parameters["@id"].Value = idGeoFence;
\end{lstlisting} \

There are two ways of executing a SqlCommand, with or without a query. Commands that are executed without a query do not return anything upon execution. This is used for operations or procedures that do not involve a SELECT statement. Commands can be executed with a query in several ways, with a *SqlDataReader* being the most frequent one. A data reader provides the ability to iterate over every row of the returned table and process the data. After a command is executed and the query, if existing, is processed the connection is closed again to prevent any possible memory leaks. 

\begin{lstlisting}[caption=Executing a command with and without query., label=lst:adoQuery, language={[Sharp]C}]
            // Reading every selected row to get geofences       
            using (SqlDataReader rdr = cmd.ExecuteReader())
            {
                while (rdr.Read())
                {
                    geos.Add(new GeoFence()
                    {
                        Id = rdr.GetInt32(0),
                        Title = rdr.GetString(1),
                        GeoObj = (Polygon)serverBytesReader.Read(rdr.GetSqlBytes(2).Value)
                    });
                }
            }

            // Executing a command that selects nothing
            cmd.ExecuteNonQuery();

            //Closing the connection
            connection.Close();
\end{lstlisting} \

To execute stored procedures from the webapp a command needs to be created with the name of the procedure as it's construction parameter. Next the commands *CommandType* needs to be set as *CommandType.StoredProcedure* to flag it as a procedure. Finally to set the variables of the procedure the same approach as using placeholders is done. Parameters are added to the command and given a value. Procedures are then executed the same way as normal SQL statements, with or without a query depending on the fact of data being selected.

\begin{lstlisting}[caption=Creating a command of a procedure and setting the variables., label=lst:adoProcedure, language={[Sharp]C}]       
            SqlCommand cmd = new SqlCommand("createCircle", connection);

            cmd.CommandType = System.Data.CommandType.StoredProcedure;
            cmd.Parameters.Add(new SqlParameter("@lat", p.Lat.Value));
            cmd.Parameters.Add(new SqlParameter("@long", p.Long.Value));
            cmd.Parameters.Add(new SqlParameter("@radius", p.Radius.Value));
            cmd.Parameters.Add(new SqlParameter("@title", p.Title));
\end{lstlisting} \

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
   : Optionally, code can be downloaded to extend a clients functionality. 

A REST resource is defined as a combination of data, the corresponding metadata as well as links leading to another associated state. Resources should be self-descriptive. Resources can be represented through any kind of format. [@restful]

### Controllers
Using ASP.NET Cores controller classes, to create high level routing of incoming HTTP-Requests, the web service is divided into three main components.

1. Geofences
   : General interaction with geofence objects, providing actions such as adding, deleting, modifying and reading them (CRUD). Furthermore, options to lock geofences on certain days of the week are also provided.
2. TimePoints
    : Used to analyze trips either in real time or after the completion of one.
3. Geofence Metadata
    : This data is used to sort Geofences using attributes set by the user. For example, Geofences can be attributed to a worker or a company. Metadata is only used for filtering Geofences.

Controllers provide the ability to create API-Endpoints for all commonly used HTTP methods (GET, POST, DELETE, etc...) using annotations. Methods annotated as such supply ready-to-use objects needed for the processing of requests. Such as request and response objects, as well as automatic parsing of the request body to a C# object.

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
Requests onto the server were made according to the HTTP protocol, with a token included in the Authorization header to authenticate a user on the backend. Data is transmitted using JSON objects in the request body, as well as the GeoJSON format in the special case of geofence communication. (See GeoJSON chapter).

To avoid a constant repetition of boilerplate code inside each controller, ASP.NET Core middleware is used to authenticate the user using the token provided in each request.

![A sample sequence diagram of how the two applications communicate with each other. In this case fetching a list of geofences and afterwards adding a new one.](source/figures/seq_rest.png "Screenshot"){#fig:stress_one width=90%}
\  

-- TODO (David) - Describe Frontend part of communication



## Calculation Algorithm for intersections
To calculate intersections between geofences and points in time (POI), two opportunities presented itself. First, manual calculation of intersection was possible with the use of a raycasting algorithm. The other way of checking if a point is within a polygon was to use methods and functions provided by Microsoft or other third party libraries.

### Raycasting
Raycasting is an algorithm which uses the Odd-Even rule to check if a point is inside a given polygon. To calculate the containment of a point one just needs to pick another point clearly outside of the space around the polygon. Next, after drawing a straight line from the POI to the picked point, one must count how often the line intersects with the polygon borders. If the number of intersections is even, the point is outside the polygon, otherwise it is inside. 

![An example of how a raycasting algorithm works with a polygon.](source/figures/raycasting_polygon.png "Screenshot"){#fig:ray_poly width=90%}
\  

This algorithm comes with some drawbacks. First, having to implement it by hand and second, needing to implement every kind of error check that might be needed. Additionally, the speed of calculations is not acceptable for time critical applications, such as Drivebox, and would need even more manual optimizations to match the speed of the methods provided by third party libraries. [@raycasting]

### Third Party Methods
Microsoft provides methods to calculate intersection points in geographical objects inside the spatial data package. In particular, the methods **STContains** and **STIntersects** are used to check if a point is inside a polygon. The difference in the two being that STIntersects returns true for a point which is exactly on the edge of a polygon. For the implementation, STContains was picked, as the increase in speed had a greater benefit than detecting points on the very edge of a polygon, as polygons are saved with an accuracy of less than a meter.

Using these methods either required doing all calculations inside the database, or to use ASP.NET instead of ASP.NET Core. Both of which were not viable approaches, as the database did not fulfil the time critical requirements of the application, and ASP.NET Core was needed for integration into the rest of the system.

To calculate intersections on the webserver, a third party library was needed. **NETTopologySuite** was picked, as it provides the same functionality as the spatial data package. Additionally, due to the initial higher speed of C#, it was picked for the needed calculations. (See NETTopologySuite chapter)

### Point based
To notify businesses of their vehicles leaving a certain area defined by a geofence, the system needed the ability to work and calculate intersections in real-time. To achieve this, a specification was chosen to receive the last two points from the main Drivebox server, and calculate which polygons these points are interacting with. Practically, this could be done using three calculations.

To avoid unnecessary calculations with polygons that are outside of a points scope, all polygons are filtered into two collections, each having all the polygons a point is inside of included.

\begin{lstlisting}[caption=Filter polygons., label=lst:polyfilter, language={[Sharp]C}]
         List<PolygonData> geoFencesPointOne = _databaseManager
            .GetPolygons(true, true, (Guid)_contextAccessor.HttpContext.Items["authKey"])
            .Where(p => p.Polygon.Contains(p1)).ToList(); //Get all polygons point 1 is in
         List<PolygonData> geoFencesPointTwo = _databaseManager
            .GetPolygons(true, true, (Guid)_contextAccessor.HttpContext.Items["authKey"])
            .Where(p => p.Polygon.Contains(p2)).ToList(); // Do the same for point 2
\end{lstlisting} \

Afterwards, the only other requirement was to compare the collections and determine which polygons are being entered, left or stayed in. The webservice then returns a collection of all affected polygons with information about which event is happening currently. The processing of this information is handled by the main Drivebox server.

### Route based
Businesses are also interested in analysis of the trips their vehicles take. To achieve this, the webservice needs to process a trip sent to it by the main Drivebox server and return a collection of all polygons it enters and leaves, as well as the associated timestamps. 

The web service receives a list of coordinates from the Drivebox server, and processes those into a **LineString** object for easier calculation of intersections. To minify the number of calculations, all polygons that are not being intersected by the LineString are filtered out as the first step.

Next, a new LineString object is built, including a representation of the initial LineStrings part inside the polygon. This is done for each polygon, and in cases in which a line string leaves and enters a polygon multiple times, it is converted in a MultiLineString and processed in a special way. Otherwise it can be added to the intersection collection.
If a MultiLineString is simple, it has no intersection points with itself. If this holds true, then it can be simply be split into multiple LineStrings and added to the list of intersections, otherwise it needs to be processed in a special way.

To analyze a non simple MultiLineString, a list of intersection points of the MultiLineString and the outside bounds of a polygon is created. Next, the MultiLineString is split into points as well, and each point is associated with the nearest point on the bounding of the polygon. This way, an accurate approximation of the crossing points can be found.

As a final step, each intersection is processed and modified with information if it enters or leaves a polygon, and when this happened, calculated by using the two coordinates with timestamp happening immediately after an event occurs. Using the distance between these points and the intersection point an approximate crossing time can also be interpolated. Entry and leave events are associated with each other and returned as a collection. If the leave and enter events are equal to the beginning and end of a trip, the trip as classified as staying inside a polygon.

![Processing of a trip as an UML Activity Diagram.](source/figures/acdia_trips.png "Screenshot"){#fig:dia_trips width=90%}
\  

## Polygon Creating
To create a polygon which can be saved in the database, some processing of the input data needs to be done. As there are three kinds of polygons, there are also three different way to process the data received from the frontend.

To send a NETTopologySuite geometric object to the database, it first needs to be converted into SQLBytes. This is done by using a **SqlServerBytesWriter** object to serialize the object.

\begin{lstlisting}[caption=Converting a Geometry object to SqlBytes, label=lst:polyfilter, language={[Sharp]C}]
         public byte[] ConvertGeometryToBytes(Geometry geometry)
         {
            SqlServerBytesWriter writer = new SqlServerBytesWriter();
            byte[] bytes = writer.Write(geometry);
            return bytes;
         }
\end{lstlisting} \

### Polygons
Normal polygons are polygons which are neither a circle nor a road. These are created by reading the coordinated provided in the input GeoJSON file and creating a **Polygon** with the use of a **GeometryFactoryEX** object, provided by NETTopologySuite. 

\begin{lstlisting}[caption=Building a Polygon which can be saved in the Database., label=lst:polyfilter, language={[Sharp]C}]
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
To create a circle, only two parameters are required. The center point of the circle, as well as a radius in meters. Creation of the actual circle object is done inside a T-SQL procedure, and achieved using the **Point.STBuffer(radius)** call, which build a circle from a given point.

### Roads
To create a road, a line of coordinates, similar to how trips are processed, is provided in the request to the web server. Alongside these coordinates a road width is provided, which in turn serves as the parameter provided to the **STBuffer(width)** method. The resulting object has a **.Reduce(1)** method applied to itself afterwards, which is used to simplify the road polygon and optimize performance across the whole system.

## Performance optimization on the backend
After performing multiple tests using various tools as described in the chapter *Testing*, a conclusion was reached that the database bottlenecked the system the most. Therefore, two ways were found to counteract this issue.

### Caching in ASP.NET
First, minimizing the number of requests made to the database could decrease the average response times for the trade-off of not always having completely correct geofence data in the frontend. Due to the vitality of correct data when calculating intersections, caching could only be performed for operations with frontend communication.

To cache polygon data, the **MemoryCache** object provided by ASP.NET Core through dependency injection was used. Data is saved in the cache either for an absolute maximum of 30 minutes or one minute without it being accessed. These numbers were arbitrarily picked and will likely be changed in the final production version according to user numbers and feedback.

\begin{lstlisting}[caption=Set a new cache entry, label=lst:polyfilter, language={[Sharp]C}]
      MemoryCacheEntryOptions entryOptions = new MemoryCacheEntryOptions()
         {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(30),
            SlidingExpiration = TimeSpan.FromMinutes(1)
         };

         _cache.Set("dbPolygons", polygons, entryOptions);
\end{lstlisting} \


### Using Geo-Indexes in MS SQL
Using Geo-Indexes for more effective calculation of intersections on the database was an option first considered to be implemented. When creating a Spatial Index, grid levels are set to **Medium** by default, when doing calculations with point data, setting these to **High** can have a positive performance impact.

This only led to a marginal increase in performance after testing it with practical data, hence why further research into the topic was abandoned.


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
