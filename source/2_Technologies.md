# Technologies
This chapter describes the technologies used for developing the application. This includes _ASP.NET Core_ [@aspref] for the backend, Microsoft _SQL Server_ [@sqlref] as a database as well as _React_ [@react] for the frontend web interface. Several third party libraries are described alongside these main technologies. Certain technologies are also compared with similar alternatives to achieve the desired results and explanations are given on why one was chosen.

## Backend Technologies
\fancyfoot[C]{Perzi}
The backend consists of two major parts, those being the ASP.NET Core webservice and the Microsoft SQL Server database. With ASP.NET Core running on top of the C# programming language, third party libraries are obtainable using the NuGet package manager. All functionality on the database is natively provided and doesn't require the installation of any further extensions. To work with the database and geographical objects the webservice needed to be extended with libraries such as ADO.NET and NetTopologySuite.


### ASP.NET Core
ASP.NET Core is a framework for building web apps and services, IoT apps as well as mobile backends developed by Microsoft as an evolution of ASP.NET 4.x. Unlike its predecessor ASP.NET Core is multiplatform (contrary to just being working on Windows) and open source. Besides creating traditional webservices, such as RESTful webapps, it can also be used to create other webapps using technologies like Razor Pages and Blazor [@aspintro].

#### Project Creation
When creating a new project using Visual Studio 2019's template of a ASP.NET Core webservice, a workspace is created included a project. This project additionally includes two files, \lstinline!Program.cs! and \lstinline!Startup.cs!. Program.cs includes the basic instructions needed to get a ASP.NET Core application running as well as defining which Startup object should be used. Logging behavior can also be defined in this file. The web application is created by using the default \lstinline!WebHostBuilder!. Listing 2.1 shows the contents of the Program.cs file.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption={Program.cs file of the backend}, label=lst:programmcs, language={[Sharp]C}]
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
\end{lstlisting} 
\end{minipage} \

To setup the REST endpoints of the webservice the Startup.cs file needs to be modified. Furthermore the method \lstinline!ConfigureServices! is provided, which is used to register controllers, services, singletons and the cache to the application at runtime. Additionally HTTP typical functionality such as authorization and CORS are also configurable in Startup.cs. The Startup.cs file is shown in a shortened form in listing 2.2.

\begin{lstlisting}[caption={[Startup.cs file of the backend]The Startup.cs file of the backend, shortened for readability}, label=lst:startupcs, language={[Sharp]C}]
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

   Whenever this service is requested a new instance is created. This lifetime works best for non resource intensive services. Once a request ends these services are disposed.
2. Scoped

   Scoped services are created once per client request meaning that they have the same behavior as transient services in a web application.
3. Singleton

   Singleton services are created once the first time they are requested. When the service is requested again the same instance is provided to the requesting object. Singleton objects are disposed once the application shuts down. These services are used when there has to be exactly one instance of a service, for the geofencing application this was chosen when creating the database manager service [@servicelife].


To request a service from the application a class must simply include the services interface in its constructor. Providing the associated service object is then handled by ASP.NET Core. A concrete implementation of this is shown using the \lstinline!TimePointController! in listing 2.3.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=The TimePointController requesting two services, label=lst:servicereq, language={[Sharp]C}]
    public TimePointController(ICollisionDetector collisionDetector, IPointAnalyzer pointAnalyzer)
    {
        this.collisionDetectorService = collisionDetector;
        this.pointAnalyzer = pointAnalyzer;
    }
\end{lstlisting}
\end{minipage} \

#### Middleware
To handle requests in a common way regardless of routes the concept of middleware can be used. ASP.NET Core works on a concept of a request entering the system, getting processed by middleware and then returning a response. Therefore the acts of routing a request, checking CORS, authorization and authentication as well as handling the request on an endpoint is considered middleware. The developer now has the ability to insert custom middleware into this pipeline. Middleware can either pass along the request to the next middleware on the pipeline or terminate the request. When a request is terminated it is passed back in the reverse order of operations before being returned as a response. To pass a request along the call *await next.Invoke()* is used [@middleware]. A simple graphical representation of this is displayed in figure 2.1.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/middleware_pipe.png}
	\caption[Example of a middleware workflow]%
    {Example of a middleware workflow\protect\autocite{middleware}}
	\label{fig2_1}
\end{figure}

To add custom middleware into the ASP.NET Core pipeline, the developer must simply register it in the Startup.cs file. To do this the \lstinline!IApplicationBuilder! interface must be extended with a method registering the middleware. This methods is then called in the startup file. Listing 2.4 shows the registration of a middleware for reading the Authorization header of a HTTP request.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Extending the IApplicationBuilder interface, label=lst:middlewareext, language={[Sharp]C}]
    // Extension method used to add the middleware to the HTTP request pipeline.
    public static class AuthHeaderMiddlewareExtensions
    {
        public static IApplicationBuilder UseAuthHeaderMiddleware(this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<AuthHeaderMiddleware>();
        }
    }
\end{lstlisting}
\end{minipage} \

#### Controller
Controllers are classes which handle the routing and processing of requests to the web service. When using the annotation \lstinline![ApiController]! a controller is declared as an API controller. This holds the benefit of automatically converting responses to a requested format like JSON or XML. Alongside the ApiController annotation the \lstinline![Route(route)]! annotation is used to set a general route for all requests going into this controller. An example of this would to use \lstinline![Route("api/v1")]! resulting in every request to *https://driver.box/api/v1* being routed through this controller.

To map methods to routes and HTTP methods a different set of annotations needs to be used on the desired methods. To associate a method with a route and a method, two annotations need to be used. Firstly, the \lstinline![Route(route)]! annotation is reused from the controller. To register the method to a specific HTTP methods ASP.NET Core provides several annotations.

Each annotation corresponds to the HTTP method with the same name. Apart from routing purposes they do not provide any functionality to the developer. Building the application according to REST and HTTP principles therefore remains a responsibility of the developer.

Controllers provide the ability to plainly return objects as a JSON representation by setting the associated class as a return type. To receive more control over the response the return type must be set to \lstinline!IActionResult!. This interface is implemented by several classes representing HTTP status codes. If there is no such classes implemented for a specific status code then \lstinline!StatusCode! can be used, as a code can be customly assigned to it.

### Microsoft SQL Server
SQL Server is a relational database management system developed by Microsoft. Similar to other systems such as Oracle, MySQL and PostgreSQL it uses the SQL standard as a querying language. Additionally it uses Microsofts own SQL dialect for instructions. Transact-SQL, also known as T-SQL. To work with SQL Server a tool such as *SQL Server Management Studio* (SSMS) [@ssmsref] is required, this is also provided by Microsoft. SSMS provides a view of all functionality provided by SQL Server in a directory like view. The developer is able to easily create plain T-SQL statements in the editor as well as procedures and triggers.

#### Transact-SQL
*T-SQL* [@tsqlref] is an extension of the standard SQL language. It provides further features to the developer when creating database statement to increase the simplicity and performance of queries. The basic syntax of querying data and defining statements remains the same. An example of this is the \lstinline!TOP! keyword which is used to only displayed the first x results of a query. This keyword only exists within T-SQL and is not usable when working the standard SQL [@tsql]. An example of this is shown in listing 2.5.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Example of using the TOP keyword, label=lst:topkeyword, language={SQL}]
    SELECT TOP 12 Id, Name, Description 
    FROM Products ORDER BY Name;
\end{lstlisting}
\end{minipage} \

##### Tables
To create tables with T-SQL a syntax similar to the SQL one is required. Tables consist of attributes and constraints. Each attribute in a table has a name and a datatype alongside information if it is allowed to be NULL. Attributes may also be referred to as columns. Constraints are special conditions data must fulfill to be insert into the table. The most important constraints in a table are the following:

1. Primary Key
   
   Primary keys are indexes applied to a single or multiple columns in a table. These columns are often also seen as the identifying columns of a table used to reference data inside this table in a different one. There can only be one primary key per table.
2. Unique
   
   Functionally has the same behavior as a primary key. The only difference being that there can be multiple unique constraints and the values of the affected columns may be NULL.
3. Foreign Key
   
   Foreign key constrains are used to associate a column with another column in a different table. This may only be done if the column(s) on the referenced table are either part of a primary key or a unique constraint. When data related to the foreign key is deleted on the associated table there are different handling approaches. Firstly nothing can be done about it at all and the values of the foreign key columns stay the same. Secondly the delete may be cascaded downwards and the row referencing the deleted row is also deleted. Finally the value of the foreign key columns can also be set to NULL.
4. Check 
   
   The check constraint is used to check if a certain condition applies. This can be used to specify a certain allowed age range as an example.

In the geofencing application a combination of several constraints was used to create the tables needed for the application to function. The relationships are best described using the ER-diagram displayed in figure 2.2. Attributes above the separator line are parts of the Primary Key. If there is no line, then all attributes are primary key parts.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/db_model.png}
	\caption{Logical Model of the Database}
	\label{fig2_2}
\end{figure}

##### Procedures
Stored procedures are segments of code which are compiled and executed on the database server. Contrary to a function, a procedure does not have a return value and processed values can only be passed along using out variables. Creating a procedure on SQL Server is simplified by using the GUI of SSMS to create a template of a procedure. Inside the procedure a sequence of T-SQL commands is being executed. Procedures provide the ability to make use of typical programming control structures such as conditions and loops. To execute a stored procedure the *EXEC* command can be used in the SQL editor or the functions provided by libraries in C# like ADO.NET. 

Variables can be declared inside the body of a stored procedure. These can have a name and a datatype. A special useable datatype for these variables is *TABLE* which creates a temporary table for results of a select to be saved in. Normal select queries can then be performed on this temporary table.

The geofencing application makes use of stored procedures in several ways. A main application is the creation of special geofences such as circles and roads, as those need a special type of processing. Next the logic for locking geofences on certain days of the weeks is also implemented using stored procedures. Listing 2.6 shows the structure of such a procedure which creates a circular geofence.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Circle geofence procedure, label=lst:procCircle, language={SQL}]
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
\end{lstlisting}
\end{minipage} \

##### Trigger
Triggers are pieces of code that are executed when data in a table is modified. This can apply for adding, deleting or modifying rows. Triggers are created in a similar way to stored procedures and creation is equally simplified by SSMS. Contrary to procedures, triggers are assigned to a table along a specification if the code should be executed before or after data is inserted. On which action the code should be executed can also be specified. These actions can be specified as *INSERT*, *UPDATE* or *DELETE*. Triggers can be used to block data from being inserted into a table or insert data into another table based on the incoming data.

In the final version of the geofencing application, triggers are not used. They were implemented when calculation of intersections was still handled on the database.

#### SQL Spatial
The spatial extension was an addition provided to SQL Server by Microsoft in 2008. It essentially adds two datatypes to the software, *geometry* and *geography*. These datatypes are provided a set of functionality to perform spatial calculations and queries on the database. Spatial data is data with geometrical or geographical information attached to it. In most cases those are coordinates. Geometry and geography are different in the fact that geometry is indented for use in a flat coordinate system like a plane. Geography on the other hand is intended for use with globe like coordinates to reflect real world locations and objects. For persisting geofences in the database, geography was chosen, as it makes use of real world GPS coordinates [@spatext].

On top of the basic data types, there are two main groups of object types provided by the spatial extension. These objects are available for both geometry and geography.

1. Simple objects
   
   Simple, single spatial objects that are completely connected in their instance. These include \lstinline!Points!, \lstinline!LineStrings! and \lstinline!Polygons!.
2. Collection objects
   
   Collections of simple objects with multiple independent instances. These include \lstinline!MultiPoints!, \lstinline!MultiLineStrings! and \lstinline!MultiPolygons!.

To create these spatial objects the well-known-text (WKT) format is used. The spatial extension provides methods to create objects from WKT. To create a polygon from a WKT source, the method \lstinline!geography::STPolyFromText(wkt, 4326)! is used. To create a point object, the method \lstinline!geography::Point(lat, long, 4326)! is used. To create any other geography object the method \lstinline!geography::STGeomFromText(wkt, 4326)! can be used. The number 4326 at the end of every methods specifies the coordinate system used for the object. This number is specified as the Spatial Referencing System Identifier (SRID). SRID 4326 is the system that specifies the latitudes and longitudes along the entire globe. For applications working in a specific area of the world which need an additional grade of coordinate accuracy another SRID can be chosen. Due to drivebox not needing accuracy in the range of centimeters and the market being open to grow the global SRID 4326 was chosen.

To manipulate and work with geographical data the extension provides a variety of methods. The geofencing application mainly makes use of the \lstinline!STBuffer()! method on objects. This method increases the size of a object in every direction, turning it either into a Polygon or a MultiPolygon, depending on the initial object. It is used to create circle and road geofences on the database, as these use a Point and a LineString as a base respectively. The command to create a circle is shown in listing 2.7. These Polygons often have over one hundred points, resulting in a loss of performance on the frontend and when calculating intersections. To simplify these shapes, the method \lstinline!Reduce(1)! is used. It removes unnecessary points of a Polygon and returns a new, more performant object with less points.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Creating of a circle, label=lst:statCircle, language={SQL}]   
    geography::Point(@lat, @long, 4326).STBuffer(@radius)
\end{lstlisting}
\end{minipage} \

### ADO.NET
To establish a connection from the ASP.NET Core application to the database a library is needed. Microsoft provides two options to implement these connections, *ADO.NET* [@adoref] and the *Entity Framework* [@efref]. ADO.NET provides a selection of methods to work with SQL databases of all kinds. To work with a database a provider is needed. In case of SQL Server this is the Microsoft ADO.NET for SQL Server provider. For a database like Oracle another one would be used.

In the ASP.NET Core application database operations are managed by a \lstinline!DatabaseManager! object. This object is created and distributed as a singleton service by making use of dependency injection. This way the existence of exactly one instance of the class is guaranteed across the whole application at runtime.

To create a connection to the database a new instance of the class \lstinline!SqlConnection! is created. Passed along as a construction parameter is a connection string to specify the server and the database user credentials. To work with this connection it needs to be opened after creation. This operation is shown in listing 2.8.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Creating and opening a connection, label=lst:adoOpen, language={[Sharp]C}]   
    using (SqlConnection connection = new SqlConnection(SQL_STRING))
    {
        connection.Open();
    }
\end{lstlisting} 
\end{minipage} \

To send SQL commands to the server a new instance of the \lstinline!SqlCommand! class is created. This instance is constructed with a SQL command in form of a string as a construction parameter. To avoid the risk of SQL-Injection vulnerabilities variables defined by user inputs are being substituted by placeholders in the initial string. To specify a placeholder in a SQL string a variable name with an @ in front is used. An example of this would be using \@geofenceName when inserting a new geofence into the database. To use the actual value instead of the placeholder a new parameter needs to be added to the \lstinline!SqlCommand! object. This way no string concatenation is used and the data is handled directly by ADO.NET. Listing 2.9 describes how a placeholder is used for deleting geofences by ids.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Deleting a geofence by id, label=lst:adoPlaceholder, language={[Sharp]C}]       
    SqlCommand cmd = new SqlCommand("DELETE FROM geoFence WHERE id = @id", connection);
    cmd.Parameters.Add(new SqlParameter("@id", System.Data.SqlDbType.Int));
    cmd.Parameters["@id"].Value = idGeoFence;
\end{lstlisting}
\end{minipage} \

There are two ways of executing a SqlCommand, with or without a query. Commands that are executed without a query do not return anything upon execution. This is used for operations or procedures that do not involve a SELECT statement. Commands can be executed with a query in several ways, with a \lstinline!SqlDataReader! being the most frequent one. A data reader provides the ability to iterate over every row of the returned table and process the data. After a command is executed and the query, if existing, is processed the connection is closed again to prevent any possible memory leaks. Both operations are described in listing 2.10.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Executing a command with and without query, label=lst:adoQuery, language={[Sharp]C}]
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
\end{lstlisting}
\end{minipage} \

To execute stored procedures from the application a command needs to be created with the name of the procedure as its construction parameter. Next the commands \lstinline!CommandType! needs to be set as \lstinline!CommandType.StoredProcedure! to flag it as a procedure. Finally to set the variables of the procedure the same approach as using placeholders is done. Parameters are added to the command and given a value. Procedures are then executed the same way as normal SQL statements, with or without a query depending on the fact of data being selected. Listing 2.11 describes this process on the example of creating a circular geofence.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Creating a command of a procedure and setting the variables, label=lst:adoProcedure, language={[Sharp]C}]       
    SqlCommand cmd = new SqlCommand("createCircle", connection);

    cmd.CommandType = System.Data.CommandType.StoredProcedure;
    cmd.Parameters.Add(new SqlParameter("@lat", p.Lat.Value));
    cmd.Parameters.Add(new SqlParameter("@long", p.Long.Value));
    cmd.Parameters.Add(new SqlParameter("@radius", p.Radius.Value));
    cmd.Parameters.Add(new SqlParameter("@title", p.Title));
\end{lstlisting}
\end{minipage} \

#### Comparison with Entity Framework
The Entity Framework (EF), being the Entity Framework Core when using with a .NET Core application, is a higher level database access library by Microsoft for .NET applications. It is built on top of ADO.NET and provides the developer with a higher level object-relational mapper to work with objects retrieved from a database. Entity Framework Core provides two ways of creating models, a database-first and a code-first model, generating the other part from the given one. To map classes to database tables and vice-versa, scaffoldings and migrations are used.

Compared to ADO.NET, EF provides a higher abstraction of database operations to the developer. Operations such as SELECT and INSERT are being handled by the library instead of the developer. To filter selected data, *LINQ* [@linq] is used. In contrary when doing operations in ADO.NET, commands and connections need to be defined by the developer manually, giving greater control about the processing of data [@efcore].

Due to Microsoft phasing out spatial support in EF Core and the official recommended library for spatial processing being NetTopologySuite [@efspatial], ADO.NET was chosen in the geofencing application. EF Core not providing any native support resulted in operations needing an equal amount of manual processing as in ADO.NET, but with the drawback of additional overhead. Furthermore the low level of ADO.NET allowed for much more performance to be extracted out of the application, contributing positively to the time critical requirement.

### NetTopologySuite
*NetTopologySuite* [@nts] (NTS) is a .NET implementation of the JTS Topology Suite software for Java. It implements the Open Geospatial Consortiums (OGC) Simple Features Specification [@ogcref] for SQL like the spatial extension of SQL Server. Due to this a base compatibility is given between the two pieces of software, making communication possible and straightforward. The OGC specification defines a set of objects and methods for geometrical data, all of which are implemented in NTS.

As NTS provides the same functionality when processing geographical data as does SQL Server, it can be used to calculate intersections of driveboxes and geofences. Furthermore it offers ways to convert GeoJSON data into NTS objects, as well as those objects into SQL Bytes to be persisted in the database. Geographical objects follow the OGC specification and have the same labels as described in the Spatial Extension chapter.

To work with NTS a simple installation from the NuGet package manager has to be made. After the installation NTS functionality is accessible from within the entire project. To convert a geographical object from SQL Server to one readable by NTS, a new instance of the \lstinline!SqlServerBytesReader! class needs to be created. To specify the data to be of the geography datatype the parameter \lstinline!IsGeography! needs to be set to true. Listing 2.12 shows how geofence data is read from the database and converted into NTS objects.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Reading geographical objects from the database, label=lst:sqlbytesreader, language={[Sharp]C}]       
    SqlServerBytesReader bytesReader = new SqlServerBytesReader() { IsGeography = true };
    cmd.Parameters.Add(new SqlParameter("@guid", userId))

    using (SqlDataReader rdr = cmd.ExecuteReader())
    {
        while (rdr.Read())
        {
            PolygonData p = new PolygonData()
            {
                Title = rdr.GetString(0),
                Polygon = (Polygon)bytesReader.Read(rdr.GetSqlBytes(1).Value),
                ID = rdr.GetInt32(2),
                SystemGeoFence = rdr.GetByte(3) == 1,
                IsNotEditable = rdr.GetByte(4) == 1
            };
            polygons.Add(p);
        }
    }
\end{lstlisting}
\end{minipage} \

To then relay this information to the React webapp, it needs to be converted into a readable format for Leaflet. To convert a NTS geographical object to GeoJSON, the NTS GeoJSON extension needs to be installed via NuGet. This extension provides the \lstinline!GeoJsonSerializer! class to create a JSON.NET serializer that works with GeoJSON, the usage of which is described in listing 2.13. Geographical objects processed by this object get serialized into a GeoJSON which is put in the HTTP Response body.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Get all geofences and convert them to GeoJSON, label=lst:geojsonget, language={[Sharp]C}]       
    List<PolygonDataWithHistory> polygonDataWithHistories = databaseManager.GetGeoFenceHistories(polys);
    List<string> geoJsons = new List<string>();
    JsonSerializer jsonWriter = GeoJsonSerializer.Create();
    using (StringWriter stringWriter = new StringWriter())
    using (JsonTextWriter jsonTextWriter = new JsonTextWriter(stringWriter))
    {
        foreach (PolygonDataWithHistory p in polygonDataWithHistories)
        {
            jsonWriter.Serialize(jsonTextWriter, p);
            geoJsons.Add(stringWriter.ToString());

            stringWriter.GetStringBuilder().Clear();
        }
    }
\end{lstlisting}
\end{minipage} \

The creation of polygons and the calculation of intersections are described in the according chapters.

## Frontend Technologies
\fancyfoot[C]{Ambrosch}
The frontend part of the app is a user interface for managing geofences, which was realized as a _React_ web application. The main part of the interface consists of a map provided by _Leaflet_ [@leafletOverview]. Due to its open-source nature, additional functionality can be added thanks to a large number of available extensions.


### React
React is a JavaScript library that allows developers to build declarative and component-based user interfaces. Complex UIs can be built with modular, reusable components, which are automatically rendered and updated by React.

React can be integrated into existing websites easily by using script-tags and creating components through JS code. However, when starting from scratch or when creating a more complex application, it is advantageous to use additional tools.

_Create React App_ [@createReactApp] is an officially supported setup tool without configuration and builds a small one-page example application as a starting point.\
To start, if npm is used as a package manager, the command _npx create-react-app my-app_ is run, where _my-app_ is replaced with then name of the application. This creates a directory of that name at the current location which contains the example application.\
After navigating to the app with _cd my-app_, it can be executed by running _npm start_. The app will then by default be available at _http://localhost:3000/_ [@createReactAppGettingStarted].


### Axios
_Axios_ [@axios] is a JavaScript library for making promise-based HTTP requests. It uses _XMLHttpRequests_ when used in the browser, and the native _http_ package when used with node.js.


#### Comparison with fetch
The _Fetch API_ [@fetchAPI] provides the _fetch()_ method to make promise-based API requests via the HTTP protocol. Fetch and axios are very similar to use, with the main difference being different syntax and property names. Both fetch and axios provide all basic functionality needed for making and handling API requests, but axios provides some additional features, which are listed below [@axiosVsFetch].

- built-in XSRF protection
- automatic JSON conversion of the message body
- request cancelling and request timeout
- interception of HTTP requests
- built-in support for download progress
- wider range of supported browsers

An example GET request, including an Authorization header and handling of the request promise, is written with fetch as demonstrated in listing 2.14.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Example GET request with fetch, label=lst:fetchExample, language={JavaScript}] 
    const headersObj = new Headers({
        'Authorization': 'OTE2MTcyNDgtRDFDMy00QzcwLTg0OTYtMEY5QUYwMUI2NDlE'
    });

    const request = new Request('https://locahost:44301/api', {
        method: 'get',
        headers: headersObj
    })

    await axios(request)
    .then((res) => res.json()) // convert response stream
    .then(data => {
        // work with response data
    }).catch(err => {
        // error handling
    })
\end{lstlisting}
\end{minipage} \

Listing 2.15 shows the same request rewritten with axios.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Example GET request with axios, label=lst:axiosExample, language={JavaScript}]
    const reqObj = {
        method: 'get',
        url: 'https://localhost:44301/api',
        headers: {
            Authorization: 'OTE2MTcyNDgtRDFDMy00QzcwLTg0OTYtMEY5QUYwMUI2NDlE'
        }
    }

    await axios(reqObj)
    .then(res => {
        let resObj = res.data; // access the response object
        // work with response data
    }).catch(err => {
        // error handling
    })
\end{lstlisting}
\end{minipage} \


### React-localize-redux
_React-localize-redux_ [@reactlocalizereduxref] is a localization library that enables easy handling of translations in React applications. It is built on the native React _Context_ [@reactContext], but understanding or using context is not necessary when using the library. The extension allows developers to define texts for different languages in JSON files, which can then be loaded and displayed depending on the selected language [@reactLocalizeRedux].


#### Initialization
All child components of the _LocalizeProvider_ component can work with the _localize_ function. Therefore, it makes sense to place this high in the hierarchy by wrapping the application in an instance of _LocalizeProvider_.

Localize has to be initialized with settings, which must include an array of supported languages, and can include translation settings and initialization options, such as the default language or different rendering options.


#### Adding translation data
There are two different ways to add translations:

- The _addTranslation_ method is used to add translation data in _all languages_ format, which means the translations for all languages are stored together in a single file.
- The _addTranslationForLangage_ method adds translation data in _single language_ format, meaning that there is one resource file for each supported language.

Translation data is stored in JSON files which are then imported and added to localize. When using the _single language_ format, each translation consists of a property name and the translation for that language. When using _all languages_ format, for every property name, an array of translation texts for the different languages is used instead, in the order used for initialization.\
In both cases, translation data can be nested for easier naming and grouping of properties. This nested structure is represented via periods (".") in the id when calling the translation values.

An example of a resource file in _all languages_ format could be called _translations.json_ and would look as demonstrated in listing 2.16:

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Resource file in all-languages format, label=lst:localizeReduxResource, language={JavaScript}]
    {
        "units": {
            "length": {
                "meter": {
                    "singular": [
                        "meter",    (en)
                        "Meter",    (de)
                    ],
                    "plural": [
                        "meters",   (en)
                        "Meter",    (de)
                    ],
                    "symbol": [
                        "m",        (en)
                        "m",        (de)
                    ],
                }
            },
            "time": {
                "second": {
                    "singular": [
                        "second",   (en)
                        "Sekunde",  (de)
                    ],
                    "plural": [
                        "seconds",  (en)
                        "Sekunden", (de)
                    ],
                    "symbol": [
                        "s",        (en)
                        "s",        (de)
                    ],
                }
            }
        }
    }
\end{lstlisting}
\end{minipage} \

With _single language format_, this would instead be split into two files, _en.translations.json_ (shown in listing 2.17):

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=English resource file in single-language format, label=lst:localizeReduxResource, language={JavaScript}]
    {
        "units": {
            "length": {
                "meter": {
                    "singular": "meter",
                    "plural": "meters",
                    "symbol": "m"
                }
            },
            "time": {
                "second": {
                    "singular": "second",
                    "plural": "seconds",
                    "symbol": "s"
                }
            }
        }
    }
\end{lstlisting}
\end{minipage} \

and _de.translations.json_ (shown in listing 2.18):

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=German resource file in single-language format, label=lst:localizeReduxResource, language={JavaScript}]
    {
        "units": {
            "length": {
                "meter": {
                    "singular": "Meter",
                    "plural": "Meter",
                    "symbol": "m"
                }
            },
            "time": {
                "second": {
                    "singular": "Sekunde",
                    "plural": "Sekunden",
                    "symbol": "s"
                }
            }
        }
    }
\end{lstlisting}
\end{minipage} \


#### Using translations in components
There are two notably different ways in which translations can be integrated in the React code:

- The \lstinline!Translate! tag can be used in a self-closing form, as shown in listing 2.19, with a property \lstinline!id! referencing the translation property name in the resource files.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Translation using tag, label=lst:translateTag, language={JavaScript}]
    <Translate id="units.length.meter.plural" /> /* will be replaced with "meters" or "Meter" depending on language */
\end{lstlisting}
\end{minipage} \

- The \lstinline!translate! function is given the _id_ as a parameter and returns the translation depending on the currently active language. This function based approach is generally more flexible and allows the translation to be used more easily for situations like usage in string manipulation or when passing component props. The use of this function is shown in listing 2.20.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Translation using function, label=lst:translateFunction, language={JavaScript}]
    translate("units.length.meter.plural") /* returns "meters" or "Meter" */
\end{lstlisting}
\end{minipage} \


### Leaflet
Leaflet is the leading open-source JavaScript library for interactive maps. It is a technology used by the company for maps in existing apps, and is also ideal for testing applications, since the library - including all of its features - is free to use, with no restrictions like monthly time or data limits for the map services [@leafletOverview].

Because Leaflet is open-source, a lot of additional libraries exist, some of which were used in the app and will be described in the following sections.


### React Leaflet
_React Leaflet_ [@reactleafletref] is a node library that offers React components for Leaflet maps, making it easier to use in a React context. It is responsible for things such as providing hooks or rendering Leaflet layers by itself to avoid updating the DOM tree.

React Leaflet does not replace Leaflet but it is used in conjunction with it. While the application is written with React Leaflet where possible, in some cases solutions involving standard Leaflet have to be used to achieve a specific task.


#### Setup
After installing the required dependencies _react, react-dom_ and _leaflet_, a simple map can be added to a React application by adding the code shown in listing 2.21.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Simple React Leaflet map, label=lst:leafletSetup, language={JavaScript}]
    <MapContainer center={[0, 0] /* initial coordinates of map bounds */} zoom={13}>
        <TileLayer
            attribution='&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.de/{z}/{x}/{y}.png" // use openstreetmap.org for international tiles
        />

        <Polygon positions={coordinates /* lat lng coordinate array */} />
    </MapContainer>
\end{lstlisting}
\end{minipage} \


### Leaflet Draw
The JavaScript library _Leaflet Draw_ [@leafletdrawref] adds interactive drawing features to Leaflet maps. The library can be used to add a toolbar to Leaflet maps, containing options for drawing different shapes, as well as editing them.\
The toolbar can also be customized with regards to what features are available [@leafletDrawDocumentation].


### React Leaflet Draw
_React Leaflet Draw_ [@reactleafletdrawref] is a library for using Leaflet Draw features with React Leaflet. It achieves this by providing an \lstinline!EditControl! component that is used in the Leaflet Map and can then be used to customize the Leaflet Draw toolbar or to overwrite event handlers [@reactLeafletDrawIntro].


#### Setup
To be able to include drawing functions in a map, the Leaflet Draw styles have to be added to the project by including a link tag as can be seen in listing 2.22

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Adding styles via link, label=lst:leafletDrawStyles, language={JavaScript}]
    <link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/leaflet.draw/1.0.4/leaflet.draw.css"/>
\end{lstlisting}
\end{minipage} \

or by using a dependency (shown in listing 2.23).

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Adding styles via import, label=lst:leafletDrawStyles, language={JavaScript}]
    node_modules/leaflet-draw/dist/leaflet.draw.css
\end{lstlisting}
\end{minipage} \

Afterwards, an \lstinline!EditControl! component can be added to a map to enable drawing features to be used. This component must be placed in a \lstinline!FeatureGroup! component, and all geometry that is drawn inside this FeatureGroup will be made editable by the extension once the "edit"-button is clicked.

Listing 2.24 shows the result of adding _React Leaflet Draw_ to the map example given above in chapter _React Leaflet_.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Adding React Leaflet Draw to Leaflet map, label=lst:leafletDrawSetup, language={JavaScript}]
    <MapContainer center={[0, 0] /* initial coordinates of map bounds */} zoom={13}>
        <TileLayer
            attribution='&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.de/{z}/{x}/{y}.png" // use openstreetmap.org for international tiles
        />

        <FeatureGroup>
            <EditControl
                position='topright' /* position of the leaflet-draw toolbar */
                onEdited={this._onEdited}
                onCreated={this._onCreate}
                onDeleted={this._onDeleted}
                draw={{
                    circle: false /* hide circle drawing function */
                }}
            />

            <Polygon positions={coordinates /* editable polygon */} />
        </FeatureGroup>

        <Polygon positions={coordinates /* non-editable polygon */} />
    </MapContainer>
\end{lstlisting}
\end{minipage} \

The \lstinline!EditControl! component provides event handlers for all events related to the drawing functions, like \lstinline!onCreated, onEdited! and \lstinline!onDeleted!, which can be overwritten by the developer to add custom functionality.\
The \lstinline!draw! property allows the developer to enable or disable certain features or buttons in the extension's toolbar.


### Leaflet Geosearch
_Leaflet Geosearch_ [@leafletGeosearch] is an extension that adds geosearch functions to a web application, with functions including coordinate search as well as address lookup. The data for this is supplied by a provider, with default options such as _Google,_ or _OpenStreetMap_. The library supports easy integration with Leaflet maps, but the functionality can also be used without Leaflet.


#### Usage with react-leaflet
To start using Geosearch with React Leaflet, a component for the search field has to be written. The code in listing 2.25 shows a simple example of such a component called \lstinline!GeoSearchField!, where a \lstinline!GeoSearchControl! element is first defined with options and is then added to the map. The options object requires the provider to be set and includes optional arguments for things like render style, autocompletion options and display of the search result.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Initializing geosearch component, label=lst:geosearchSetup, language={JavaScript}]
    const GeoSearchField = ({activeLanguage}) => {
        const map = useMap();

        const searchControl = new GeoSearchControl({ /* create control (with options) */
            provider: new OpenStreetMapProvider({params: {'accept-language': activeLanguage}}), /* required */
            showMarker: false,
            autoComplete: true,
        });

        useEffect(() => {
            map?.addControl(searchControl); /* add control to map */
            return () => map?.removeControl(searchControl);
        }, [map]);

        return null;
    };
\end{lstlisting}
\end{minipage} \

This component is then added in the Leaflet \lstinline!MapContainer! component. Since the search is added as a component, this component can be rendered conditionally to show or hide the search bar in the map. This is shown in listing 2.26.

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Adding Geosearch to Leaflet map, label=lst:geosearchSetup, language={JavaScript}]
    <MapContainer center={[0, 0] /* initial coordinates of map bounds */} zoom={13}>
        <TileLayer
            attribution='&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.de/{z}/{x}/{y}.png" // use openstreetmap.org for international tiles
        />

        { showSearch && <GeoSearchField /> /* geosearch, conditionally rendered */ }

        <Polygon positions={coordinates /* lat lng coordinate array */} />
    </MapContainer>
\end{lstlisting}
\end{minipage} \


### Leaflet Routing Machine
_Leaflet Routing Machine_ [@leafletRoutingMachine] is a Leaflet extension that adds routing tools to the standard map. It offers route finding with start, destination and via points, with integrated map controls for adding, editing and removing waypoints.


#### Setup
The package has to be installed in the project with the use of a script tag or by installing _leaflet-routing-machine_ with a package manager such as npm. A basic example of the routing machine with two initial waypoints can be added as described in listing 2.27:

\begin{minipage}[c]{1\textwidth} 
\begin{lstlisting}[caption=Initializing Routing Machine, label=lst:routingMachineSetup, language={JavaScript}]
    const instance = L.Routing.control({ // create an instance of routing machine
        waypoints: [
            map.getBounds().getCenter(), // set initial waypoints within current map bounds
            {
                lat: map.getBounds().pad(-0.6).getNorth(),
                lng: map.getBounds().pad(-0.6).getWest()
            },
        ]
    }

    instance.addTo(map); // add routing machine to leaflet map
\end{lstlisting}
\end{minipage} \

### OpenStreetMap
_OpenStreetMap_ [@openStreetMapAbout] is a community driven project to provide geographical map data. This data can be used for any purpose without any costs, as long as credit is given. Since map data is provided by a great variety of contributors, a special emphasis is placed on local knowledge. A combination of technologies like aerial photography, GPS and maps is used to verify the accuracy of geographical entries.

OpenStreetMap is the default map provider used by the Leaflet extension.


### GeoJSON
_GeoJSON_ is a format for encoding geospatial data based on _JavaScript Object Notation_. It defines various types of objects to represent geographic entities and their properties. The latest standard for the format is specified in _RFC 7946_ [@geoJsonSpecification], which was published in August 2016. The format supports seven different geometry objects as well as _Feature_ objects, which can have additional information, and collection objects to group sets of geometries or features.


#### Geometry object
There are seven basic geometry objects types:

1. Position

    an array of two or more numbers, representing longitude, latitude and optionally height

For the remaining six types, the explanation refers to the content of that objects \lstinline!coordinates! property:

2. Point

    a single position
3. MultiPoint

    an array of positions
4. LineString

    an array of two or more points
5. MultiLineString

    an array of LineString coordinate arrays
6. Polygon

    an array of linear ring coordinate arrays

A linear ring is a closed LineString, meaning the first and last position share the same coordinates. It must have a minimum of four positions, which would describe a triangle.

If multiple coordinate rings are used in a polygon, the first one must be an outer exterior ring. All other rings must be interior rings that describe holes in the previously defined exterior ring.

7. MultiPolygon

    an array of Polygon coordinate arrays


#### Geometry collection
A GeometryCollection has a property \lstinline!geometries! which contains an array of geometry objects as described above. This array can also be empty. GeometryCollections can be used to describe geometry not possible with the normal geometry types, like polygons that consist of multiple exterior rings.


#### Feature object
Features are objects that represent a thing that is spatially bounded. They contain geometry information, but do not represent the geometry itself. A Feature has a member \lstinline!geometry! which can be either a geometry object or null if no location is specified.


#### Feature collection
A FeatureCollection can be used to group different features together. It has a member \lstinline!features!, which is an array where each element is a Feature object as described above. This array can also be empty.


#### Example
Listing 2.28 shows an example GeoJSON object consisting of a FeatureCollection, which includes four features with different geometries: one LineString, two Points and one Polygon.

\begin{lstlisting}[caption=An example GeoJSON object, label=lst:geoJson, language={JavaScript}]
    {
        "type": "FeatureCollection", /* an array of features */
        "features": [
        {
            "type": "Feature", /* declared as feature */
            "properties": {}, /* no additional properties */
            "geometry": { /* geometry object*/
                "type": "LineString", /* geometry type*/
                "coordinates": [ /* coordinates depending on geometry type */
                    [-122.47979164123535, 37.830124319877235],
                    [-122.47721672058105, 37.809377088502615]
                ]
            }
        },
        {
            "type": "Feature",
            "properties": {},
            "geometry": {
                "type": "Point",
                "coordinates": [-122.48399734497069, 37.83466623607849] /* lat lng coordinate pair / position */
            }
        },
        {
            "type": "Feature",
            "properties": {},
            "geometry": {
                "type": "Point",
                "coordinates": [-122.47867584228514, 37.81893781173967]
            }
        },
        {
            "type": "Feature",
            "properties": {},
            "geometry": {
                "type": "Polygon",
                "coordinates": [
                    [
                        [-122.48043537139893, 37.82564992009924],
                        [-122.48129367828368, 37.82629397920697],
                        [-122.48240947723389, 37.82544653184479],
                        [-122.48743057250977, 37.83093781796035],
                        [-122.48313903808594, 37.82822612280363],
                        [-122.48043537139893, 37.82564992009924]
                    ]
                ]
            }
        }
        ]
    }
\end{lstlisting}