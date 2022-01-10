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
Lorem Ipsum


### Backend Algorithms
Lorem Ipsum


## Stress Testing
Lorem Ipsum


### MS SQL
Lorem Ipsum


### ASP.NET
Lorem Ipsum