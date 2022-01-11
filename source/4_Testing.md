# Testing
This chapter describes the use of common testing techniques and methods as well as the technologies used during development
to ensure a stable and secure application which is ready to be used by the company clients.\
Testing is an important aspect of every piece of software, as it ensures the functionality, security and the coverage
of the implemented code. Software testing is generally organised into two categories, functional and non-functional testing,
with both types being used to test the DriveBox Geofencing software. [@testingTypes]


## Functional Testing
There are several ways to test a piece of software on its functionality, with Unit- and Integration-Testing being the most
broadly used examples of these, with those methods also being used to test the back- and frontend parts of the Geofencing
application.


### REST Endpoint Functionality
Web endpoints using the REST architecture were tested using \textbf{xUnit} as a general testing framework and the \textbf{Microsoft ASP.NET CoreMVC Testing package} to send Web Requests to the server. 
These tools were used due to the backend being written in C# on top of the ASP.NET Core web framework, keeping up a consistency in the used technologies, ensuring a higher maintainability of all parts of thesource code, 
as well as the ability to use tools developed by Microsoft themselves. \

#### xUnit
The xUnit Framework is a testing tool officially recommended by Microsoft for the use of testing
ASP.NET Core projects. While its name implies the usage of Unit Testing, it can be used to run
integration tests as well with the use of other tools like the ASP.NET Core MVC Testing package, as
was done in this project. \

##### Fact vs. Theory \
Unlike other testing frameworks, which use attributes like [Test], xUnit uses [Fact] and [Theory]. \
\textbf{Facts} are tests which use constant data throughout each running, they are inflexible and always test the same thing.

\begin{lstlisting}[caption=Sample of a Fact, label=lst:test, language={[Sharp]C}]
        // A sample Fact Test which ensures a succesful connection & authorization to the backend server.
        [Fact]
        public async Task SampleTestAsync()
        {
            HttpClient client = _factory.CreateClient();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("sampleJWT");
            HttpResponseMessage response = await client.GetAsync("api/geoFences");

            response.EnsureSuccessStatusCode();
        }
\end{lstlisting} \

\textbf{Theories} on the other hand are tests which use parameters, this is used for test cases in which 
one might wish to test a function which has a binary result with several values without the need to write
multiple tests for it. Theories are also suitable when testing frontend functionality using different browsers
such as Firefox and Google Chrome. [@xUnitIntro] \

\begin{lstlisting}[caption=Sample of a Theory used to test the Frontend in several browsers., label=lst:theory]
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

##### xUnit and MVC Testing \
Microsoft provides the *Microsoft.AspNetCore.Mvc.Testing* package for integration testing of applications
developed on top of ASP.NET Core, such as RESTful services. Using the **WebApplicationFactory** as well as the
**HttpClient** provided by this package one is able to test their RESTful applications. \

\begin{lstlisting}[caption=Basic usage of the MVC Testing package in conjunction with xUnit., label=lst:mvcTest]
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
Testing the functionality of the React Frontend part of the application was achieved using the **Selenium**
Framework, specifically the Selenium WebDriver. Selenium, being the industry standard for browser automation
provides the ability to automate the actions a user would take in a browser, such as clicking, going to a specific URL or reading values of a web page. \

Selenium runs on a system based on drivers for each individual browser, such as Google Chrome, Firefox or
Safari, with these drivers being maintained by the browsers developers. 
Selenium commands are a unified way of communicating with any of these drivers, providing the developer
with the ability to run the same testing code for multiple browsers. Selenium only provides the framework
to automate the browser, checking values still had to be done using xUnit. \

Creating tests using Selenium is comparable to writing code in a sequential way, as the drivers are being
instructed to execute a sequence of statement, similar to how a real user would do it.

\begin{lstlisting}[caption=Code which tests if the sidebar is openable in both browsers., label=lst:selenium]
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

Firefox and Google Chrome were chosen as the testing browsers due to those two making up a large share of the
Windows web userbase. While Safari does have a higher market share than Firefox, the Selenium WebDriver for 
it is only available for MacOS systems. 

In some cases, especially when the drawing of shapes was being tested, it was not possible to reuse the same test case for both browsers, in which case individual ones had to be written, due to the way that the Firefox
driver handles mouse movement differently than the Chrome driver.


### Backend Algorithms
To unit test the algorithms functionality there was a need to mock out the required
components in normal application use. This was achieved using the **Moq** library,
which is used to mock objects in C# for unit tests. \

Mock testing is about only testing one thing in isolation, forcing all other dependecies
of this component to work in a set way. This is achieved due to most components of the
application making use of dependency injection, which allows for easy mocking. [@moqTutorial] \


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
Simulations were done for the collission detection algorithms as well as the database which
handled all the geofence data.


### MS SQL
The open source tool **SQLQueryStress** provides the ability to test an SQL Servers ability
to operate under a constant stream of requests, achieved by making several threads execute
SQL commands. \

![Using the Stress Tool.](source/figures/sqlstress1.png "Screenshot"){#fig:stress_one width=50%} \

### ASP.NET
Lorem Ipsum