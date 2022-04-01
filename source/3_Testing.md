# Testing
\fancyfoot[L]{Perzi}
This chapter describes the use of common testing techniques and methods as well as the technologies used during development
to ensure a stable and secure application which is ready to be used by the company clients.\
Testing is an important aspect of every piece of software, as it ensures the functionality, security and the coverage
of the implemented code. Software testing is generally organized into two categories, functional and non-functional testing,
with both types being used to test the DriveBox Geofencing software [@testingTypes].

Functional testing will be described in its own sub chapter, while non functional testing will mainly be described in the form of stress testing.


## Functional Testing
There are several ways to test a piece of software on its functionality. Unit- and Integration-Testing make up the majority of these methods. These methods also implemented to test the back- and frontend parts of the Geofencing application. 


### REST Endpoint Functionality
Web endpoints using the REST architecture were tested using xUnit [@xunitref] as a general testing framework and the Microsoft ASP.NET Core MVC Testing package [@mvctestref]
to send Web Requests to the server. 
These tools were used due to the backend being written in C# on top of the ASP.NET Core web framework, keeping up a consistency in the used technologies, 
ensuring a higher maintainability of all parts of the source code, as well as the ability to use tools developed by Microsoft themselves. \

#### xUnit
The xUnit Framework is a testing tool officially recommended by Microsoft for the use of testing
ASP.NET Core projects. While its name implies the usage of Unit Testing, it can be used to run
integration tests as well with the use of other tools like the ASP.NET Core MVC Testing package, as it
was done in this project. \

\newpage

##### Fact vs. Theory \
Unlike other testing frameworks, which use attributes like [Test], xUnit uses [Fact] and [Theory]. 
*Facts* are tests which use constant data throughout each running, they are inflexible and always test the same thing. A fact to test if a \lstinline!HttpClient! can connect to the server is shown is Listing 3.1.

\begin{lstlisting}[caption=Example of a Fact, label=lst:test, language={[Sharp]C}]
    // A sample Fact Test which ensures a successful connection & authorization to the backend server.
    [Fact]
    public async Task SampleTestAsync()
    {
        HttpClient client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("sampleJWT");
        HttpResponseMessage response = await client.GetAsync("api/geoFences")
        response.EnsureSuccessStatusCode();
    }
\end{lstlisting} \

*Theories* on the other hand, are tests which use parameters. This is used for test cases in which 
one might wish to test a function which has a binary result with several values without the need to write
multiple tests for it. Theories are also suitable when testing frontend functionality using different browsers
such as Firefox and Google Chrome [@xUnitIntro]. Usage of a theory is shown in Listing 3.2.\

\begin{lstlisting}[caption=Example of a Theory used to test the Frontend in several browsers, label=lst:theory, language={[Sharp]C}]
    //A connectivity test to check if both Selenium Browser drivers are working.
    [Theory]
    [InlineData("chrome")]
    [InlineData("firefox")]
    public void ConnectivityTest(string driverName)
    {
        //Receive a Browser Driver using a helper function.
        IWebDriver driver = GetDriverByString(driverName); 
        const string url = "https://www.google.at/";
        driver.Url = url;
        string newUrl = driver.Url;
        driver.Quit();
        // Check if Browser navigated to provided URL.
        Assert.Equal(url, newUrl);
    }
\end{lstlisting} \

\newpage

##### xUnit and MVC Testing \
Microsoft provides the Microsoft.AspNetCore.Mvc.Testing package for integration testing of applications
developed on top of ASP.NET Core, such as RESTful services. Using the \lstinline!WebApplicationFactory! as well as the
\lstinline!HttpClient! provided by this package one is able to test their RESTful applications. Listing 3.3 shows how to use the MVC testing package alongside xUnit to test if a \lstinline!HttpClient! can to the server. \

\begin{lstlisting}[caption=Basic usage of the MVC Testing package in conjunction with xUnit., label=lst:mvcTest, language={[Sharp]C}]
    //A Factory to build instances of the application to test.
    private readonly WebApplicationFactory<DriveboxGeofencingBackend.Startup> _factory;
    //Using Dependency Injection at the creation of the Test file to create the
    //WebApplicationFactory instance which in turn will create HttpClients later.
    public TripTestFixture(WebApplicationFactory<DriveboxGeofencingBackend.Startup> factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task SampleTestAsync()
    {
        //Create a HttpClient from the factory, automatically configured for
        //the application which is being tested.
        HttpClient client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("sampleJWT");
        HttpResponseMessage response = await client.GetAsync("api/geoFences");
        response.EnsureSuccessStatusCode();
    }
\end{lstlisting} \

### Frontend Functionality
Testing the functionality of the React Frontend part of the application was achieved using the Selenium [@seleniumref]
Framework, specifically the Selenium WebDriver. Selenium, being the industry standard for browser automation
provides the ability to automate the actions a user would take in a browser, such as clicking, going to a specific URL or reading values of a web page. \

Selenium runs on a system based on drivers for each individual browser, such as Google Chrome, Firefox or
Safari, with these drivers being maintained by the browsers developers. 
Selenium commands are a unified way of communicating with any of these drivers, providing the developer
with the ability to run the same testing code for multiple browsers. Selenium only provides the framework
to automate the browser, checking values still had to be done using xUnit. \

Creating tests using Selenium is comparable to writing code in a sequential way, as the drivers are being
instructed to execute a sequence of statement, similar to how a real user would do it. The following listing shows how to create a Selenium client which checks if the sidebar of a webpage can be opened.

\begin{lstlisting}[caption=Selenium example, label=lst:selenium, language={[Sharp]C}]
    [Theory]
    [InlineData("chrome")]
    [InlineData("firefox")]
    public void OpenSideBarTest(string driverName)
    {
        IWebDriver driver = GetDriverByString(driverName);
        driver.Url = URL;
        // Check if navigation worked
        Assert.Equal(URL, driver.Url);
        // Set a timeout to wait for new elements to appear, simulating a real user wait time
        driver.Manage().Timeouts().ImplicitWait = TimeSpan.FromSeconds(10);
        driver.FindElement(By.Id("leaflet-map"));
        Thread.Sleep(1000);
        // Check if close button of the sidebar is visible to Selenium.
        bool displayed = driver.FindElement(By.Id("btn_closeDock")).Displayed;
        driver.Quit();
        Assert.True(displayed);  
    }
\end{lstlisting} \

Firefox and Google Chrome were chosen as the browsers for testing due to those two making up a large share of the
Windows web user base. While Safari does have a higher market share than Firefox, the Selenium WebDriver for 
it is only available for MacOS systems, meaning it could not be used since the testing suite was developed
on Microsoft Windows. 

In some cases, especially when the drawing of shapes was being tested, it was not possible to reuse the same test case for both browsers, in which case individual ones had to be written, due to the way that the Firefox
driver handles mouse movement differently than the Chrome driver.


### Backend Algorithms
For unit testing the algorithms functionality there was a need to mock out the required
components in normal application use. This was achieved using the Moq [@moqref] library,
which is used to mock objects in C# for unit tests. \

Mock testing is about only testing one thing in isolation, forcing all other dependencies
of this component to work in a set way. This is achieved due to most components of the
application making use of dependency injection, which allows for easy mocking [@moqTutorial]. Listing 3.5 shows how to mock the database service used in the backend. \


\begin{lstlisting}[caption=Mocking the database access, label=lst:test, language={[Sharp]C}]
    var databaseMock = new Mock<IDatabaseManager>();
    //Setup the object to return a specific object on a specific call.
    databaseMock.Setup(db => db.GetWeekdaysByGeoFence(47))
    .Returns(new List<int> { 0, 3, 4 });
\end{lstlisting} \

Testing was done using the same classes as the main application used, to put the focus
on the algorithm functionality, with routes and geofences being entered by hand to ensure
clear test data. \


## Stress Testing
Due to the company's need to handle the data coming from over 1000 Driveboxes at the same
time, it was critical to ensure that the software is able to run under such circumstances.
Simulations were done for the collision detection algorithms as well as the database which
handled all the geofence data.


### MS SQL
The open source tool SQLQueryStress [@sqlstressref] provides the ability to test an SQL Servers ability
to operate under a constant stream of requests, achieved by making several threads execute
SQL commands. The following figure shows an overview of the application as well as the results of testing a procedure under heavy load. \

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/sqlstress1.png}
	\caption{Testing an procedure}
	\label{fig3_1}
\end{figure}

After testing the pure procedures in the database alone, disregarding any other bottleneck which
could come up due to the network, it was concluded that the Microsoft SQL Geospatial functions were
not able to provide the efficiency needed to satisfy the Drivebox demands in scalability, as the company
is looking to expand the pool of vehicles in the future. The results of the final tests with optimised procedures are displayed in figure 3.2.\

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/sqlstress2.png}
	\caption{Testing the calculation implementation}
	\label{fig3_2}
\end{figure}

With the final and most accurate implementation of the algorithm being able to handle requests at an acceptable rate,
it became clear that response times were rising exponentially with an increasing number of clients, which would not be
acceptable in a scaling production environment. After tests were done using NetTopologySuite in the 
ASP.NET Core backend, which proved to be much more efficient at handling the necessary calculations,
it was decided to abandon the optimization of the database based algorithm.

### ASP.NET
To test the performance of the RESTful endpoints written in ASP.NET Core, the Apache JMeter [@jmeterref] tool was used,
checking the efficiency of the collision detection algorithm as well as the server's ability to run under load. \

JMeter uses _Test Plans_ to send requests to servers, using a basic _Thread Group_ to assign the number of clients
accessing the server at the same time. Besides setting the number of simultaneous threads running, developers are
also able to make these threads start up after a certain amount of time (Ramp-Up Period), as well as setting the
amount of requests each thread sends. An example of such a test plan is shown in figure 3.3.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/jmeter1.png}
	\caption{Creating a Test Group in JMeter\protect\autocite{jmeterPic1}}
	\label{fig3_3}
\end{figure}

Following that, the developer must add a _HTTP Request Defaults_ object which provides JMeter with the basic
information about the server to be tested, such as the base hostname, the port and the protocol, as well as
parameters and body data. Figure 3.4 shows an example of the interface used to set these options.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/jmeter2.png}
	\caption{Setting the base HTTP options\protect\autocite{jmeterPic2}}
	\label{fig3_4}
\end{figure}

Next, the specific _HTTP Request_ details need to be specified, mainly the used HTTP Method, as well as
the destination path, which is appended to the base host. This part should mainly take over the settings set
in the _HTTP Request Defaults_ object, but if needed, some of those can be edited. The interface is shown in the following figure.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/jmeter3.png}
	\caption{Specifying Request options\protect\autocite{jmeterPic3}}
	\label{fig3_5}
\end{figure}

Finally, to display the results of the Test Plan, the developer needs to use a _Listener_. Listeners
are mainly grouped into two categories, tables and graphs, depending on which is needed, with the
table based reports being more detailed [@jmeterTutorial]. An example of how the result of a graph based listener could look like is provided in figure 3.6.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/jmeter4.png}
	\caption{Example of a graph based listener\protect\autocite{jmeterPic4}}
	\label{fig3_6}
\end{figure}

Test procedures in JMeter were designed similarly to the ones made in SQLQueryStress, with a main focus
on operation during a constant load and occasional spike testing to estimate the approximate scale of
Driveboxes the system would be able to handle and calculate collisions for. 