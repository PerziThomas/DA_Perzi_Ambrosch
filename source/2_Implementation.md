# Implementation
This chapter describes the concrete implementation of the software. This includes technologies as well as the technical implementation in the ASP.NET Core backend, the Microsoft SQL Server as well as the React frontend. Frameworks as well as major third party libraries are explained alongside standardized formats. Certain technologies will also be compared with similar alternatives to achieve the desired results as well as explanations given on why one was chosen. Furthermore algorithms to calculate intersections with geofences will be explained. 

## Architecture
To create maintainable and extendable software it must be designed in such ways. to architect a software that fulfils the aforementioned criteria a certain set of principles needs to be followed. The geofencing application was built with architectural principles in mind to guarantee the continuation of the development at iLogs.

Firstly, general principles such as *Separation of concerns* and *Encapsulation* were implemented. Separation of concerns defines that pieces of software should only be doing their own designated work. A service that processes pictures should only process these pictures and not handle anything regarding display on the screen. Developing software according to this principle is simplified due to React and ASP.NET Core providing a clear structure for pieces of software. With controllers, services and middleware in ASP.NET Core and components in React providing structures to separate application concerns. Encapsulation is a way of developing software that only exposes certain parts of itself to other software. In a practical sense this is achieved by limiting the scope of properties in classes with keywords such as *private* and *protected*. This way as long as the defined results of exposed methods and properties are not changed, the internal structure of a class can be changed without outside notice. [@architectureMS]

### Dependency Injection
To pass components along inside the application in a managed way, Dependency Injection is implemented by ASP.NET Core. Dependency Injection is a software design pattern used to achieve the Inversion of Control architectural principle. 

Typically, applications are written with a direct way of executing dependencies. This means that classes are directly dependent on other classes at compile time. To invert this structure, interfaces are added which are implemented by the previously depended on classes and called by the depending classes. This way the first class calls the second one at runtime, while the second class depends on the interface controlled by the first class, thus inverting the control flow. This provides the ability to easily plug in new implementations of the interfaces methods. [@architectureMS]

Dependency Injection adds onto that by also wanting to remove the associated creation of an object when depending on an interface. Additional to the two classes and one interface an injector is created. In the example of ASP.NET Core, this task is handled by the framework. The injector serves the role of creating an instance of the class implementing the interface and injects it into the depending class. [@dependencyinj]

In ASP.NET Core, Dependency Injection is mainly used when creating and implementing service classes. For further information on the creation, injection and lifetime of these services see the according sub-chapter in the ASP.NET Core chapter.

### Project structure
The entire geofencing application runs on a client-server architecture. The React frontend and the existing Drivebox application are served as clients by the geofencing backend server built on ASP.NET Core. Communication between the clients and the server is entirely REST and HTTP based. 

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/architecture.png}
	\caption{Architecture of the entire Drivebox application with the geofencing included.}
	\label{fig2_1}
\end{figure}

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

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/middleware_pipe.png}
	\caption{Example of a middleware workflow.\protect\autocite{middleware}}
	\label{fig2_2}
\end{figure}

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

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/db_model.png}
	\caption{Logical Model of the Database.}
	\label{fig2_3}
\end{figure}

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

On top of the basic data types, there are two mains groups of object types provided by the spatial extension. These objects are available for both geometry and geography.

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

To send SQL command to the server a new instance of the *SqlCommand* class is created. This instance is constructed with a SQL command in form of a string as a construction parameter. To avoid the risk of SQL-Injection vulnerabilities variables defined by user inputs are being substituted by placeholders in the initial string. To specify a placeholder in a SQL string a variable name with an @ in front is used. An example of this would be using '(at)geofenceName' when inserting a new geofence into the database. To use the actual value instead of the placeholder a new parameter needs to be added to the SqlCommand object. This way no string concatenation is used and the data is handled directly by ADO.NET.

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
The Entity Framework (EF), being the Entity Framework Core when using with a .NET Core application, is a higher level database access library by Microsoft for .NET applications. It is built on top of ADO.NET and provides the developer with a higher level object-relational mapper to work with objects retrieved from a database. Entity Framework Core provides two ways of creating models, a database-first and a code-first model, generating the other part from the given one. To map classes to database tables and vice-versa, scaffoldings and migrations are used.

Compared to ADO.NET, EF provides a higher abstraction of database operations to the developer. Operations such as SELECT and INSERT are being handled by the library instead of the developer. To filter selected data, LINQ [@linq] is used. In contrary when doing operations in ADO.NET, commands and connections need to be defined by the developer manually, giving greater control about the processing of data. [@efcore]

Due to Microsoft phasing out spatial support in EF Core and the official recommended library for spatial processing being NetTopologySuite, ADO.NET was chosen in the geofencing application. EF Core not providing any native support resulted in operations needing an equal amount of manual processing as in ADO.NET, but with the drawback of additional overhead. Furthermore the low level of ADO.NET allowed for much more performance to be extracted out of the application, contributing positively to the time critical requirement.

### NetTopologySuite
NetTopologySuite [@nts] (NTS) is a .NET implementation of the JTS Topology Suite software for Java. It implements the Open Geospatial Consortiums (OGC) Simple Features Specification for SQL like the spatial extension of SQL Server. Due to this a base compatibility is given between the two pieces of software, making communication possible and straightforward. The OGC specification defines a set of objects and methods for geometrical data, all of which are implemented in NTS.

As NTS provides the same functionality when processing geographical data as does SQL Server, it can be used to calculate intersections of driveboxes and geofences. Furthermore it offers ways to convert GeoJSON data into NTS objects, as well as those objects into SQL Bytes to be persisted in the database. Geographical objects follow the OGC specification and have the same labels as described in the Spatial Extension chapter.

To work with NTS a simple installation from the NuGet package manager has to be made. After the installation NTS functionality is accessible from the entire project. To convert a geographical object from SQL Server to one readable by NTS, a new instance of the *SqlServerBytesReader* class needs to be created. To specify the data to be of the geography datatype the parameter *IsGeography* needs to be set to true.

\begin{lstlisting}[caption=Reading geographical objects from the database., label=lst:sqlbytesreader, language={[Sharp]C}]       
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
\end{lstlisting} \

To then relay this information to the React webapp, it needs to be converted into a readable format for Leaflet. To convert a NTS geographical object to GeoJSON, the NTS GeoJSON extension needs to be installed via NuGet. This extension provides the *GeoJsonSerializer* class to create a JSON.NET serializer that works with GeoJSON. Geographical objects processed by this object get serialized into a GeoJSON which is put in the HTTP Response body.

\begin{lstlisting}[caption=Get all geofences and convert them to GeoJSON., label=lst:geojsonget, language={[Sharp]C}]       
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
\end{lstlisting} \

Creation of polygons and the calculation of intersections are described in the according chapters.

## Frontend Technologies
The frontend part of the app is a user interface for managing geofences, which was realized as a _React_[@react] web application. The main part of the interface consists of a map provided by _Leaflet_[@leafletOverview]. Due to its open-source nature, additional functionality can be added thanks to a large number of available extensions.


### React
React is a JavaScript library that allows developers to build declarative and component-based user interfaces. Complex UIs can be built with modular, reusable components, which are automatically rendered and updated by React.

React can be integrated into existing websites easily by using script-tags and creating components through JS code. However, when starting from scratch or when creating a more complex application, it is advantageous to use additional tools.

_Create React App_[@createReactApp] is an officially supported setup tool without configuration and builds a small one-page example application as a starting point.\
To start, if npm is used as a package manager, the command _npx create-react-app my-app_ is run, where _my-app_ is replaced with then name of the application. This creates a directory of that name at the current location which contains the example application.\
After navigating to the app with _cd my-app_, it can be executed by running _npm start_. The app will then by default be available at _http://localhost:3000/_. [@createReactAppGettingStarted]


### Axios
Axios is a JavaScript library for making promise-based HTTP requests. It uses _XMLHttpRequests_ when used in the browser, and the native _http_ package when used with node.js. [@axios]


#### Comparison with fetch
The _Fetch API_[@fetchAPI] provides the _fetch()_ method to make promise-based API requests via the HTTP protocol. Fetch and axios are very similar to use, with the main difference being different syntax and property names. Both fetch and axios provide all basic functionality needed for making and handling API requests, but axios provides some additional features: [@axiosVsFetch]

- built-in XSRF protection
- automatic JSON conversion of the message body
- request cancelling and request timeout
- interception of HTTP requests
- built-in support for download progress
- wider range of supported browsers

An example GET request, including an Authorization header and handling of the request promise, is written with _fetch_ as demonstrated below.

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
\end{lstlisting} \

The same request with _axios_ can be rewritten as follows:

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
\end{lstlisting} \


### React-localize-redux
_React-localize-redux_ is a localization library that enables easy handling of translations in React applications. It is built on the native React _Context_[@reactContext], but understanding or using context is not necessary when using the library. The extension allows developers to define texts for different languages in JSON files, which can then be loaded and displayed depending on the selected language. [@reactLocalizeRedux]


#### Initialization
All child components of the _LocalizeProvider_ component can work with the _localize_ function. Therefore, it makes sense to place this high in the hierarchy by wrapping the application in an instance of _LocalizeProvider_.

Localize has to be initialized with settings, which must include an array of supported languages, and can include translation settings and initialization options, such as the default language or different rendering options. [@reactLocalizeRedux]


#### Adding translation data
There are two different ways to add translations:

- The _addTranslation_ method is used to add translation data in an _all languages_ format, which means the translations for all languages are stored together in a single file.
- The _addTranslationForLangage_ method adds translation data in _single language_ format, meaning that there is one resource file for each supported language.

Translation data is stored in JSON files which are then imported and added to localize. When using the _single language_ format, each translation consists of a property name and the translation for that language. When using the all languages_ format, for every property name, an array of translation texts for the different languages is used instead, in the order used for initialization.\
In both cases, translation data can be nested for easier naming and grouping of properties. This nested structure is represented via periods (".") in the id when calling the translation values. [@reactLocalizeRedux]

An example of a resource file in _all languages_ format could be called _translations.json_ and would look as follows:

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
\end{lstlisting} \

With _single language format_, this would instead be split in two files, _en.translations.json_:

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
\end{lstlisting} \

and _de.translations.json_:

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
\end{lstlisting} \


#### Using translations in components
There are two notably different ways in which translations can be integrated in the React code:

- The \lstinline!Translate! tag can be used in a self-closing form with a property \lstinline!id! referencing the translation property name in the resource files.

\begin{lstlisting}[caption=Translation using tag, label=lst:translateTag, language={JavaScript}]
<Translate id="units.length.meter.plural" /> /* will be replaced with "meters" or "Meter" depending on language */
\end{lstlisting} \

- The \lstinline!translate! function is given the _id_ as a parameter and returns the translation depending on the currently active language. This function based approach is generally more flexible and allows the translation to be used more easily for situations like usage in string manipulation or when passing component props. [@reactLocalizeRedux]

\begin{lstlisting}[caption=Translation using function, label=lst:translateFunction, language={JavaScript}]
translate("units.length.meter.plural") /* returns "meters" or "Meter" */
\end{lstlisting} \


### Leaflet
_Leaflet_ is the leading open-source JavaScript library for interactive maps. It is a technology used by the company for maps in existing apps, and is also ideal for testing applications, since the library - including all of its features - is free to use, with no restrictions like monthly time or data limits for the map services. [@leafletOverview]

Because Leaflet is open-source, a lot of additional libraries exist, some of which were used in the app and will be described in the following sections.


### React Leaflet
_React Leaflet_ is a node library that offers React components for Leaflet maps, making it easier to use in a React context. It is responsible for things such as providing hooks or rendering Leaflet layers by itself to avoid updating the DOM tree. [@reactLeafletIntro]

React Leaflet does not replace Leaflet but it is used in conjunction with it. While the application is written with React Leaflet where possible, in some cases solutions involving standard Leaflet have to be used to achieve a specific task.


#### Setup
After installing the required dependencies _react, react-dom_ and _leaflet_, a simple map can be added to a React application by adding the following code:

\begin{lstlisting}[caption=Simple React Leaflet map, label=lst:leafletSetup, language={JavaScript}]
<MapContainer center={[0, 0] /* initial coordinates of map bounds */} zoom={13}>
	<TileLayer
		attribution='&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
		url="https://{s}.tile.openstreetmap.de/{z}/{x}/{y}.png" // use openstreetmap.org for international tiles
	/>

	<Polygon positions={coordinates /* lat lng coordinate array */} />
</MapContainer>
\end{lstlisting} \


### Leaflet Draw
The JavaScript library _Leaflet Draw_ adds interactive drawing features to Leaflet maps. The library can be used to add a toolbar to Leaflet maps, containing options for drawing different shapes, as well as editing them.\
The toolbar can also be customized with regards to what features are available. [@leafletDrawDocumentation]


### React Leaflet Draw
_React Leaflet Draw_ is a library for using Leaflet Draw features with React Leaflet. It achieves this by providing an \lstinline!EditControl! component that is used in the Leaflet Map and can then be used to customize the Leaflet Draw toolbar or to overwrite event handlers. [@reactLeafletDrawIntro]


#### Setup
To be able to include drawing functions in a map, the _leaflet-draw_ styles have to be added to the project by including

\begin{lstlisting}[caption=Adding styles via link, label=lst:leafletDrawStyles, language={JavaScript}]
<link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/leaflet.draw/1.0.4/leaflet.draw.css"/>
\end{lstlisting} \

or

\begin{lstlisting}[caption=Adding styles via import, label=lst:leafletDrawStyles, language={JavaScript}]
node_modules/leaflet-draw/dist/leaflet.draw.css
\end{lstlisting} \

Afterwards, an \lstinline!EditControl! component can be added to a map to enable drawing features to be used. This component must be placed in a \lstinline!FeatureGroup! component, and all geometry that is drawn inside this FeatureGroup will be made editable by the extension once the "edit"-button is clicked.

Adding _React Leaflet Draw_ to the map example given above in the chapter _React Leaflet_ would produce the following code:

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
\end{lstlisting} \

The EditControl component provides event handlers for all events related to the drawing functions, like \lstinline!onCreated, onEdited! and \lstinline!onDeleted!, which can be overwritten by the developer to add custom functionality.\
The \lstinline!draw! property allows the developer to enable or disable certain features or buttons in the extension's toolbar.


### Leaflet Geosearch
_Leaflet Geosearch_ is an extension that adds geosearch functions to a web application, with functions including coordinate search as well as address lookup. The data for this is supplied by a provider, with default options such as _Google,_ or _OpenStreetMap_. The library supports easy integration with Leaflet maps, but the functionality can also be used without Leaflet. [@leafletGeosearch]


#### Usage with react-leaflet
To start using Geosearch with React Leaflet, a component for the search field has to be written. The following code shows a simple example of such a component called \lstinline!GeoSearchField!, where a \lstinline!GeoSearchControl! element is first defined with options and is then added to the map. The options object requires the provider to be set and includes optional arguments for things like render style, autocompletion options and display of the search result.

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
\end{lstlisting} \

This component is then added in the Leaflet \lstinline!MapContainer! component. Since the search is added as a component, this component can be rendered conditionally to show or hide the search bar in the map.

\begin{lstlisting}[caption=Adding Geosearch to Leaflet map, label=lst:geosearchSetup, language={JavaScript}]
<MapContainer center={[0, 0] /* initial coordinates of map bounds */} zoom={13}>
	<TileLayer
		attribution='&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
		url="https://{s}.tile.openstreetmap.de/{z}/{x}/{y}.png" // use openstreetmap.org for international tiles
	/>

	{ showSearch && <GeoSearchField /> /* geosearch, conditionally rendered */ }

	<Polygon positions={coordinates /* lat lng coordinate array */} />
</MapContainer>
\end{lstlisting} \


### Leaflet Routing Machine
_Leaflet Routing Machine_ is a Leaflet extension that adds routing tools to the standard map. It offers route finding with start, destination and via points, with integrated map controls for adding, editing and removing waypoints. [@leafletRoutingMachine]


#### Setup
The package has to be installed in the project, with the use of a script tag or by installing \lstinline!leaflet-routing-machine! with a package manager such as npm. A basic example of the routing machine with two initial waypoints can be added as follows:

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
\end{lstlisting} \

### OpenStreetMap
_OpenStreetMap_ is a community driven project to provide geographical map data. This data can be used for any purpose without any costs, as long as credit is given. Since map data is provided by a great variety of contributors, a special emphasis is placed on local knowledge. A combination of technologies like aerial photography, GPS and maps is used to verify the accuracy of geographical entries. [@openStreetMapAbout]

OpenStreetMap is the default map provider used by the _Leaflet_ extension.


### GeoJSON
GeoJSON is a format for encoding geospatial data based on _JavaScript Object Notation_. It defines various types of objects to represent geographic objects and their properties. The latest standard for the format is specified in _RFC 7946_[@geoJsonSpecification], which was published in August 2016. The format supports seven different geometry objects as well as _Feature_ objects, which can have additional information, and collection objects to group sets of features.


#### Geometry object
There are seven basic geometry objects types:

1. _Position_
: an array of two or more numbers, representing longitude, latitude and optionally height

For the remaining six types, the explanation refers to the content of that objects \lstinline!coordinates! property:

2. _Point_
: a single position
3. _MultiPoint_
: an array of positions
4. _LineString_
: an array of two or more points
5. _MultiLineString_
: an array of LineString coordinate arrays
6. _Polygon_
: an array of linear ring coordinate arrays

A linear ring is a closed LineString, meaning the first and last position share the same coordinates. It must have a minimum of four positions, which would describe a triangle.

If multiple coordinate rings are used in a polygon, the first one must be an outer exterior ring. All other rings must be interior rings that describe holes in the previously defined exterior ring.

7. _MultiPolygon_
: an array of Polygon coordinate arrays


#### Geometry collection
A GeometryCollection has a \lstinline!geometries! which contains an array of geometry objects as described above, which can also be empty. GeometryCollections can be used to describe geometry not possible with the normal geometry types, like polygons that consist of multiple exterior rings.


#### Feature object
Features are objects that represent a thing that is spatially bounded. They contain geometry information, but do not represent the geometry itself. A Feature has a member \lstinline!geometry! which can be either a geometry object or null if no location is specified.


#### Feature collection
A FeatureCollection can be used to group different features together. It has a member \lstinline!features!, which is an array where each element is a Feature object as described above. This array can also be empty. [@geoJsonSpecification]


#### Example
The following example of a GeoJSON objects consists of a FeatureCollection, which includes five features with different geometries: one LineString, two Points and one Polygon.

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
					[-122.48373985290527, 37.82632787689904],
					[-122.48425483703613, 37.82680244295304],
					[-122.48605728149415, 37.82639567223645],
					[-122.4898338317871, 37.82663295542695],
					[-122.4930953979492, 37.82415839321614],
					[-122.49700069427489, 37.821887146654376],
					[-122.4991464614868, 37.82171764783966],
					[-122.49850273132326, 37.81798857543524],
					[-122.50923156738281, 37.82090404811055],
					[-122.51232147216798, 37.823344820392535],
					[-122.50150680541992, 37.8271414168374],
					[-122.48743057250977, 37.83093781796035],
					[-122.48313903808594, 37.82822612280363],
					[-122.48043537139893, 37.82564992009924]
				]
			]
		}
	}
	]
}
\end{lstlisting} \

## Communication between Frontend and Drivebox Server
To handle the required communication between the frontend and backend applications of the geofence system, a RESTful webservice was implemented using the ASP.NET Core framework. This service provides the capability to use HTTP for exchanging the information about geofences required to create and modify geofences, as well as calculating intersections.

### REST
REST (Representational State Transfer) is a software architectural style which defines several principles which makes a service RESTful.

For a service to be considered RESTful, it must fulfil six criteria:

1. Uniform Interface
   : This defines the need for all components of the system to follow the same set of rules and thus allows for a standard way of communication.
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

Controllers provide the ability to create API-Endpoints for all commonly used HTTP methods (GET, POST, DELETE, etc...) using annotations. Methods annotated as such supply ready-to-use objects needed for the processing of requests, such as request and response objects, as well as automatic parsing of the request body to a C# object.

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

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/seq_rest.png}
	\caption{A sample sequence diagram of how the two applications communicate with each other. In this case fetching a list of geofences and afterwards adding a new one.}
	\label{fig2_4}
\end{figure}


### Sending requests from the frontend
The requests were initially sent from the frontend by using the Fetch API, but this was later changed to axios to comply with the company's standards and the existing Drivebox application. Since only basic requests were made, switching from one technology to the other was fairly trivial, as the changes mainly affected property names and object syntax. An example comparison between fetch and axios is given in the chapter _Comparison between fetch and axios_.

Requests for geofences are made once on initial loading of the application. A polling solution was considered, but was not implemented, as it would have negatively affected performance. Also, it was not seen as necessary to have geofences update in real time, because geofences would normally only be viewed and managed by a single user.\
Request polling was initially implemented for geofence locks because individual geofence's locks did not update when using bulk locking operations. This was later found to be a problem with React not re-rendering and was solved by moving the React state up.

When making requests to create resources such as geofences or metadata, the resource already exists in the frontend and is therefore added directly in the React state. For this reason, the _id_ of the object that is created in the database must be returned to the frontend, where it is added to the resource in the state, so that further requests, like for updates or deletion, can be made for that resource.


## Calculation Algorithm for intersections
To calculate intersections between geofences and points in time (POI), two opportunities presented themselves. First, manual calculation of intersection was possible with the use of a raycasting algorithm. The other way of checking if a point is within a polygon was to use methods and functions provided by Microsoft or other third party libraries.

### Raycasting
Raycasting is an algorithm which uses the Odd-Even rule to check if a point is inside a given polygon. To calculate the containment of a point one just needs to pick another point clearly outside of the space around the polygon. Next, after drawing a straight line from the POI to the picked point, one must count how often the line intersects with the polygon borders. If the number of intersections is even, the point is outside the polygon, otherwise it is inside. 

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/raycasting_polygon.png}
	\caption{An example of how a raycasting algorithm works with a polygon.\protect\autocite{raycasting}}
	\label{fig2_5}
\end{figure}

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

The web service receives a list of coordinates from the Drivebox server, and processes those into a **LineString** object for easier calculation of intersections. To minimize the number of calculations, all polygons that are not being intersected by the LineString are filtered out as the first step.

Next, a new LineString object is built, including a representation of the initial LineStrings part inside the polygon. This is done for each polygon, and in cases in which a line string leaves and enters a polygon multiple times, it is converted in a MultiLineString and processed in a special way. Otherwise it can be added to the intersection collection.
If a MultiLineString is simple, it has no intersection points with itself. If this holds true, then it can simply be split into multiple LineStrings and added to the list of intersections, otherwise it needs to be processed in a special way.

To analyze a non simple MultiLineString, a list of intersection points of the MultiLineString and the outside bounds of a polygon is created. Next, the MultiLineString is split into points as well, and each point is associated with the nearest point on the bounding of the polygon. This way, an accurate approximation of the crossing points can be found.

As a final step, each intersection is processed and modified with information if it enters or leaves a polygon, and when this happened, calculated by using the two coordinates with timestamp happening immediately after an event occurs. Using the distance between these points and the intersection point an approximate crossing time can also be interpolated. Entry and leave events are associated with each other and returned as a collection. If the leave and enter events are equal to the beginning and end of a trip, the trip is classified as staying inside a polygon.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/acdia_trips.png}
	\caption{Processing of a trip as an UML Activity Diagram.}
	\label{fig2_6}
\end{figure}

## Polygon Creation
To create a polygon which can be saved in the database, some processing of the input data needs to be done. As there are three kinds of polygons, there are also three different ways to process the data received from the frontend.

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
Normal polygons are polygons which are neither a circle nor a road. These are created by reading the coordinates provided in the input GeoJSON file and creating a **Polygon** with the use of a **GeometryFactoryEX** object, provided by NETTopologySuite. 

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
To create a circle, only two parameters are required. The center point of the circle, as well as a radius in meters. Creation of the actual circle object is done inside a T-SQL procedure, and achieved using the **Point.STBuffer(radius)** call, which builds a circle from a given point.

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
The frontend provides operations for viewing, creating, updating and deleting geofences. It is used by administrators in the companies that use the _DriveBox_. The application is implemented as a React Web-Interface using Leaflet and extensions to work with maps and geographical data. The frontend was developed as a stand-alone application to be later integrated into the already existing Drivebox application by the company.


### Interactive Map
The central part of the frontend is an interactive map that can be used to view, create and edit geofences. Interactive, in this case, means that all operations that involve direct interaction with the underlying geographical data, can be carried out directly on the map, instead of, for example, by entering coordinates in an input field.

The map is provided by _Leaflet_. Since this library is open-source, a lot of additional libraries exist, some of which are used to extend the functionality of the app.

_React Leaflet_ is also used to enable working with _Leaflet_ in React components more easily. While the application is written with React Leaflet where possible, in some cases, solutions involving the standard Leaflet have to be used to achieve a specific task.

_Leaflet Draw_ and _React Leaflet Draw_ are used to add drawing functions in the map. These libraries offer event handlers for creating and editing shapes, which are overwritten in the app to handle custom behavior like confirmation dialogs and communication with the backend.


### Geofence creation
Geofences can be created as polygons, rectangles, circles or as road geofences by routes. Circle creation is handled separately and will be discussed in chapter _Circular geofences_. All other types are converted to polygons when created. The different types of geofences are shown in a class diagram below. The meaning of non-editable geofences will be described in chapter _Non-editable geofences_.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/Geofence_types_class_diagram.png}
	\caption{The different types of geofences}
	\label{fig2_7}
\end{figure}

Any created geofence is checked for self-intersections. [@codeSelfIntersection] [@codeLineIntersection] If no problems are found, the geofence is converted into a JSON object and sent in a POST request to the endpoint _/geoFences/_ of the backend.

If an error occurs in the backend, the creation process is aborted. Because the error did not occur in the frontend, Leaflet does not react to it, and the new geofence is added to the map. The drawn geometry therefore needs to be manually removed from the map.

\begin{lstlisting}[caption=Removing geometry from map, label=lst:geofenceCreation, language={JavaScript}]
createdLayer._map.removeLayer(createdLayer);
\end{lstlisting} \

If the backend returns a success, the geofence is added directly into the collection in the state of the React app, to avoid having to reload the entire page or re-fetch all geofences.


### Generation of geofences from presets
Geofences can be created from a list of presets, which allows the user to use more complex geofences that are created and offered by the provider of Drivebox, like countries or states, without significant drawing effort.

The available presets with their geometry are stored in the backend. To generate a geofence from a preset, a POST request is sent to the endpoint _/geoFences/createPreset?preset=${id}_ of the backend. This creates a new geofence with a copy of the preset's geometry. The geometry is also sent back to the frontend in the response, where the new geofence can be added directly in the React state.


### Circular geofences
Circles, when created with _leaflet-draw_, have a center point defined by a latitude, a longitude and a radius. This information is sent to the backend, where the circle is converted into a polygon, which can be saved to the database. The coordinates of this polygon are returned to the frontend, where they are used to add the circle directly in the React state.


### Road geofences
Geofences can be created by setting waypoints, calculating a route and giving it width to make it a road.

The routing function is provided by the node package _leaflet-routing-machine_. This package includes functions for calculating a route between multiple waypoints on a map using real world road data. Waypoints can be dragged around on the map, and additional via points can be added by clicking or dragging to alter the route.

In the app, every time the selected route changes, it is stored in a React state variable. When the button to create a new road geofence based on the current route is clicked, a dialog is shown, where a name can be given to the geofence. Also, the width of the road can be selected. The route stored in state and the given name are sent to the backend endpoint _/geoFences/road?roadType=?_. RoadType refers to the width of the road to be created, by tracing a circle of a certain radius along the path. The accepted values for roadType are:

- roadType=1: 3 meters
- roadType=2: 7 meters
- roadType=3: 10 meters

The geofence is created in the backend, and the geometry of the new polygon is returned to the frontend. If a successful response is received, the geofence is added directly in state to avoid reloading.


### Geofence editing
The geometry of geofences that are drawn or loaded from the backend can be changed by the user. The basic editing itself is provided by _leaflet-draw_. The map can be put into an edit mode, where individual points of polygons can be moved by the user. After this, the editing action can be confirmed or cancelled.

Since multiple polygons can be edited at once, all actions need to be performed iteratively for an array of edited layers. Each geofence is converted to a JSON object and sent in a PATCH request to the endpoint _/geoFences/{id}_.

In case of a backend error, the window is reloaded to restore the correct state of all geofences before editing, since the Leaflet map has already saved the changes to the polygons. A more complex solution, like saving a copy of the geofences' geometries before changes are made and then overwriting the map's geometry with this copy in case of an error, would remove the need for a complete reload, but was considered too complex to implement.


#### Single edit functionality
It was considered to implement the edit feature in a way that individual geofences could be set to edit mode, instead of having a global edit mode that can be toggled for all geofences at once. This would likely have performance benefits, since it was observed in manual testing that response times of the interface increased together with the number and complexity of loaded geofences, particularly when edit mode was enabled. 

The functionality would be achieved by storing an _editable_ flag for that geofence, and then only rendering geofences that have this flag inside the _FeatureGroup_.

This feature did not work as intended, since the _Leaflet_ map did not re-render correctly. Also, the performance benefit became less of a priority after pagination was implemented.


#### Making loaded geofences editable
To make all geofences editable (not just those that were drawn, but also those that were loaded from the backend), all geofences are stored in a collection, which is then used to render all editable geometry inside a separate _FeatureGroup_ in the map.

The geofences fetched from the backend are iterated over and a new _Leaflet_ polygon (L.polygon) is created in the frontend from each geofence's coordinates.

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

The _LeafletMap_ component contains a _FeatureGroup_, which includes the component _MyEditComponent_ from _Leaflet Draw_. This means that all geofences that are rendered in this same _FeatureGroup_ are affected by _Leaflet Draw_ and can therefore be edited.

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

To achieve this, all geofences are given a boolean property _isNotEditable_, which is set to true in the backend for geofences created via the circle or road endpoints. This property is then used to separate all editable from all non-editable geofences, and render only those that can be edited inside the edit-_FeatureGroup_ in the map.

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

A custom React component _GeoSearchField_ is used. In it, an instance of _GeoSearchControl_ provided by _leaflet-geosearch_ is created with customization options, which is then added to the map in the _useEffect_ hook. The component _GeoSearchField_ also has to be used inside the _LeafletMap_ in order to make the search button available on the map.

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
A label is displayed for every geofence in the map to make it easier to associate a geofence with its corresponding polygon. Leaflet itself can display labels for polygons, however, these default labels have some problems. The precision with which the position of the label is calculated appears to be limited by the initial zoom value set for the map, meaning that with a lower default zoom, the label is sometimes either not centered within or completely outside its polygon. 

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/Label_precision_problem.png}
	\caption{Labels (top left) are displayed at the same point and outside their corresponding polygons (bottom right)}
	\label{fig2_8}
\end{figure}

This problem can be solved by starting at a higher initial zoom level, but to keep flexibility in this regard, labels are added manually by rendering a marker on the map for each polygon at a calculated position.


#### Finding optimum label position
Since the default labels were replaced with custom markers, the position of these relative to the rectangle has to be calculated manually. There are several ways in which this can be done, which will be described in detail.


##### Average of points
The label position can be calculated by taking an average of the coordinates of all points of the polygon. This is a good approximation for simple, convex shapes with evenly distributed points. However, if points are distributed unevenly, meaning there is more detail on one side than the other, the average will shift to that side, and the calculated point will not appear centered anymore.

This approach can also lead to problems with concave geometry, when the calculated center is not part of the polygon, causing the label to appear outside the geometry. This is especially relevant for road geofences, but can also affect simpler geometries like a U-shape as demonstrated in the image below.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/Label_outside_concave_geometry.png}
	\caption{Geofence label displayed outside a concave polygon's geometry}
	\label{fig2_9}
\end{figure}

##### Center of bounding box
The label can be placed at the center of the bounding box of the polygon, which can easily be done by using basic leaflet methods.

\begin{lstlisting}[caption=Get center of bounding box, label=lst:labelPosition, language={JavaScript}]
polygon.getBounds().getCenter()
\end{lstlisting} \

This approach solves the problem with unevenly distributed points, because the center is always calculated from a rectangle with exactly four points. However, it is not a solution for concave polygons like the U-shape described above.


##### Pole of inaccessibility
The node package _polylabel_ uses an algorithm to calculate a polygon's _pole of inaccessibility_, defined as "the most distant internal point from the polygon outline". (Source: [@polylabelIntro])

This approach solves the problem with concave shapes, because the calculated point always lies inside the polygon, and for this reason, it was used to calculate the label positions in the app.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/Label_pole_of_inaccessibility.png}
	\caption{Geofence label placed at the pole of inaccessibility}
	\label{fig2_10}
\end{figure}

#### Dynamic label size
The size of the geofence labels changes depending on the current zoom level of the map, getting smaller as the user zooms out further, and is hidden for any zoom level smaller than or equal to 6. This dynamic sizing is achieved by using a CSS class selector that includes the current zoom level to select the corresponding option from the CSS classes _zoom6_ to _zoom13_.

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
Individual geofences can be hidden from the map to make it visually clearer. To achieve this, a boolean tag _Hidden_ is stored for each geofence. For any geofence where this tag is set to true, no _react-leaflet_ Polygon is rendered in the map, and it is instead replaced with an empty tag. This has the added benefit of not rendering the polygon's geometry on the map, which was found to improve frontend performance significantly when geofences with large numbers of points are hidden.

#### Storing geofence visibilities
The information on which geofences are hidden is stored for the convenience of the user. Since most geofences that are hidden can be assumed to stay hidden for the majority of the time, like system geofences, geofences with a large number of points or generally rarely used ones, this is done with _localStorage_, meaning that, contrary to _sessionStorage_, the information is stored not just on page reloads, but in entirely new sessions.

\begin{lstlisting}[caption=Geofence visibility is saved to localStorage, label=lst:geofenceVisibility, language={JavaScript}]
let obj = {...visibilityObj};

newGeoFences.forEach(e => {
    obj[`id_${e.geoFence.ID}`] = e.geoFence.Hidden || false; // if no value is stored, set as not hidden
});

setVisibilityObj(obj);
localStorage.setItem("visibility", JSON.stringify(obj)); // save to localStorage
\end{lstlisting} \


### Geofence highlighting
Any geofence can be highlighted, setting the map view to show it, as well as changing it to a highlight color (green). The action of moving the map to the location of the highlighted geofence is achieved by using the _Leaflet_ function _map.flyToBounds_, which changes the map's center and zoom level to fit the bounds of the given geometry and also includes a smooth animation. [@leafletDocumentation]

A boolean tag _Highlighted_ is stored for every geofence. Some special cases have to be considered in combination with the _Geofence visibility_ feature:

- If a geofence is highlighted, and its tag therefore set to be true, the tag of all other geofences is set to be false, to ensure that only one geofence is highlighted at a time.
- If a hidden geofence is highlighted, it is also unhidden.
- If a highlighted geofence is hidden, it is also set to not be highlighted.

The following state chart describes the different states a geofence can have regarding hiding and highlighting, as well as the actions that lead to changes.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/Geofence_visibility_state_chart.png}
	\caption{Geofence visibility states and their interaction}
	\label{fig2_11}
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

When the search button is pressed, a GET request is sent to the backend containing the category as well as the search term, to the endpoint _/geoFences/search?searchTerm=\${searchTerm}&metadataCategory=${category}_, which returns a collection of all geofences that fit the search. The actual search process is handled on the backend. The React state is then updated to include the returned geofences, and only these geofences are displayed in the user interface.


### Geofence locking
One of the main use cases of the app is for theft protection. An object (a car or machine) can be tracked with the _DriveBox_, and if it leaves a geofence, an alarm can be sent out. For this feature, there is also the option to lock geofences on certain days of the week, so that for example no alarm is triggered on the weekend.

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
The user can select from a variety of display colors for the geofences on the map, for better contrast and visibility or for personal preference. This is a global setting, meaning that the color can be changed for all geofences at once. It is not possible to set different colors for individual geofences.

The currently selected color is stored in a React state variable and used when drawing the Polygons on the map. Highlighted geofences are always colored green, overriding the global geofence display color.


### Bulk operations
The app includes the option to perform certain actions for multiple geofences at once, including locking actions and geofence deletion. Backend requests are sent for each selected geofence individually, which is not problematic in terms of performance, but allows further room for improvement, for example by implementing a special endpoint for bulk operations to be handled by the backend.


#### Selection checkboxes
To allow the user to select geofences for which the bulk operations should be performed, a checkbox is added to each geofence in the list. An array of all currently selected geofences' ids is stored in the React state, and if a geofence is selected or deselected, its id is pushed into this array or removed from it.

Because the checkboxes are part of custom list elements, a select-all-checkbox also has to be added manually. The current _selectAllState_ (NONE, SOME or ALL) is determined after every clickEvent on a checkbox by counting the number of selected geofences, and is used to show an unchecked, indeterminate or checked select-all-checkbox respectively. This checkbox can also be clicked itself to select all loaded geofences if none are selected, or to deselect all if some or all are selected.

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
Bulk actions are available for locking, unlocking and toggling locks for geofences on any weekday individually or on all weekdays at once. A function is called with the weekday and the lockMethod (0 for locking, 1 for unlocking and 2 for toggling). For all selected geofences, the locking is performed as described in chapter _Geofence locking_. If it should be performed for all weekdays, indicated by a value for _weekday_ of -1, the function _lockActionMulti_ is called recursively for every weekday value from 0 to 6.

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
A bit mask is a technique used to store and access data as individual bits, which can be useful for storing certain types of data more efficiently than would normally be possible.

This could be used as an alternative way to store the days on which a geofence is locked. Since there are seven days, a mask with at least seven bits has to be used, where the first bit represents Monday, the second bit represents Tuesday, and so on. Each bit can be either true (1) or false (0), indicating if that day of the week is locked or not. This way, every combination of locked days can be represented by using one number between 0 (0000000) and 127 (1111111).

- To set an individual bit (set it to 1/true), an OR operation is used on the storage variable and the value 2^n, where n is the number of the bit starting from the least significant bit on the right at n=0.
- To delete an individual bit (set it to 0/false), an AND operation is used on the storage variable and the inverse of 2^n (the value after a NOT operation).
- A bit can be toggled with an XOR operation on the storage variable and the value 2^n.
- By using an AND operation on the storage variable and 2^n, the value of an individual bit can be read. [@bitmasks]


## Performance optimization on the frontend
This chapter describes the considerations made to improve performance of the React app. This includes the methods used to record performance data and find potential issues, as well as and the changes made to the application to fix those issues. Optimizing performance of the frontend can have several positive effects, including, but not limited to:

- minimizing lag and making the UI more responsive.
- minimizing loading times and load on the network by reducing the number of backend calls.
- allowing the app to run on less powerful devices.

Hereafter, some particular solutions that are used in the geofence web-interface are described in greater detail.


### Reduction of component rerenders
One of the biggest factors affecting performance of the React app is the number of component rerenders, especially ones which happen after changes to parameters of a component, that have no effect on the state of that component. Reducing the number of these unnecessary rerenders is important to improve frontend performance and therefore usability.


#### Measuring component render times
To improve frontend performance, the render times of all components have to be recorded in order to find out which elements contain potential bottlenecks and must therefore be optimized.

_React Developer Tools_ is a _Chrome_ extension that adds React debugging tools to the browser's Developer Tools. There are two added tabs, _Components_ and _Profiler_, the latter of which is used for recording and inspecting performance data. [@reactDevToolsChrome]

The _Profiler_ uses React's Profiler API to measure timing data for each component that is rendered. The workflow to use it will be briefly described here.

- After navigating to the _Profiler_ tab, a recording can either be started immediately or set to be started once the page is reloaded.
- During the recording, the actions for which performance needs to be analyzed are performed in the React app.
- Once all actions are completed, the recording can be stopped again. [@reactProfilerIntro]

The recorded data can be viewed in different graphical representations, including the render durations of each individual element. When testing performance for this app, mostly the _Ranked Chart_ was used, because it orders all components by the time taken to rerender, which gives the developer a quick overview of where improvements need to be made.


#### Avoiding unnecessary rerenders
By looking at a graph of the geofence management app recorded with the _Profiler_, it can be seen that the _LeafletMap_ component takes significantly more time to rerender than all other components and should therefore be optimized.\

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/React_Profiler_before.png}
	\caption{Ranked profiler chart shows long render times for LeafletMap}
	\label{fig2_12}
\end{figure}

The map component is wrapped in _React.memo_ in order to rerender only when relevant props have changed. In the case of this app, that means a change in the collection of geofences to be displayed, a change regarding road geofence creation that is displayed in the map, polygon color or some meta settings. With a custom check function _isEqual_, the _React.memo_ function can be set to rerender only when one of these props changes.

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

After making these changes, a new graph is recorded for the same actions. The render duration of the map component has been reduced from 585.6 ms to a value clearly below 0.5 ms, where it does not show up at the top of the _Profiler_'s ranked chart anymore. This has the effect that the application now runs noticeably smoother, especially when handling the map, since the _LeafletMap_ component does not update every time the map position or the zoom changes.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/React_Profiler_after.png}
	\caption{Ranked chart after implementation of performance optimizations}
	\label{fig2_13}
\end{figure}

Similar changes are also applied to other components that cause lag or rerender unnecessarily.


### Reduction of loaded geofences
During manual testing of the app, it became clear that frontend performance is connected to the number of geofences that are loaded at any given point in time. This effect was magnified when multiple geofences with high point counts, like state presets or road geofences, were displayed at once. This appears to be a limitation inherent to the _leaflet_ map that cannot be fixed in itself. Instead, the user of the app is given the option to have less geofences shown on the map at once.

A pagination feature, as described in chapter _Pagination_, splits the total collection of geofences and only displays a portion in the frontend list and map. The feature also allows the user to change the number of geofences to be displayed per page, which can be chosen higher if performance allows it or lower if otherwise.

A geofence hiding feature, as described in chapter  _Geofence visibility_, also makes it possible to hide specific geofences from the map, which cleans up the view for the user, but can also improve performance by not rendering particularly complex geofences.


### Reduction of editable geometries
While the edit mode provided by _leaflet-draw_ is enabled in the _leaflet_ map, all editable polygons are shown with draggable edit markers for each point of their geometry. These edit markers, when present in large quantities, cause considerably lag when edit mode is enabled. To improve this, certain geofences are marked as non-editable and are not shown in the map's edit mode, as described in chapter _Non-editable geofences_.


### Reduction of backend calls
Performance of the frontend interface is improved by minimizing the number of requests made to the backend, by avoiding techniques like polling. This reduces the total loading times and load on the network, and also making some UI elements more responsive by not relying on backend data for updates.


#### Polling geofence locks
In the initial implementation of the bulk operations for locking (chapters _Locking_ and  _Bulk operations_), when an action was performed, the weekday/locking buttons for each affected geofence did not update as expected.\
The reason was that the locks for each geofence were stored in the React state of that geofence's _GeoFenceListItem_ component and were fetched for that geofence alone only once on initial loading of that component. This means that, when a bulk operation is performed in the parent _GeoFenceList_ component, no rerender is triggered and the locks are not updated in the _GeoFenceListItem_, since non of its props have changed.

To solve this problem, a polling mechanism was implemented, where the _GeoFenceListItems_ repeatedly call the backend after a fixed interval of time. Any updates that happen in the backend are now displayed in the frontend, albeit with a slight delay depending on the interval set for polling.\
Performance is notably affected by this approach, due to the high number of network calls, even when no locking data has changed.


#### Lifting state up
While there are workarounds to force a child component to rerender from its parent [@reactForceChildRerender], in this case, it is more elegant to __lift the state__ of the geofence locks from the _GeoFenceListItems_ to a parent component like _GeoFenceList_ or _Home_.\
Now, when the state changes in the parent component, for example through _geofence bulk locking operations_, all child components are automatically updated by React and the changes to geofence locks can be seen immediately. [@reactLiftingStateUp]

