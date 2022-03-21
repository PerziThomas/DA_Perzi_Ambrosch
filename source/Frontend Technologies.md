## Frontend Technologies used
The frontend part of the app is a user interface for managing geofences, which was realized as a React web application. The main part of the interface consists of a map provided by _Leaflet_. Due to its open-source nature, additional functionality can be added thanks to a large number of available extensions.


### React
React is a JavaScript library that allows developers to build declarative and component-based user interfaces. Complex UIs can be built with modular, reusable components, which are automatically rendered and updated by React.


#### Create React App
React can be integrated into existing websites easily by using script-tags and creating components through JS code. However, when starting from scratch or when creating a more complex application, it is advantageous to use additional tools.

_Create React App_ is an officially supported setup tool without configuration and builds a small one-page example application as a starting point.

To start, if npm is used as a package manager, the command _npx create-react-app my-app_ is run, where _my-app_ is replaced with then name of the application. This creates a directory of that name at the current location which contains the example application.

After navigating to the app with _cd my-app_, it can be executed by running _npm start_. The app will then by default be available at _http://localhost:3000/_. [@createReactApp]


### Axios
Axios is a JavaScript library for making promise-based HTTP requests. It uses _XMLHttpRequests_ when used in the browser, and the native _http_ package when used with node.js. [@axios]


### Comparison with fetch
The Fetch API provides the _fetch()_ method to make promise-based API requests via the HTTP protocol.\
Fetch and axios are very similar to use, with the main difference being different syntax and property names.\
Both fetch and axios provide all basic functionality needed for making and handling API requests, but axios provides some additional features: [@axiosVsFetch]
- built-in XSRF protection
- automatic JSON conversion of the message body
- request cancelling and request timeout
- interception of HTTP requests
- built-in support for download progress
- wider range of supported browsers

An example GET request, including an Authorization header and handling of the request promise, is written with _fetch_ as demonstrated below.

```jsx
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
```

The same request with _axios_ can be rewritten as follows:

```jsx
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
```

For the purposes of the Geofence management application described in this thesis, the difference is neglectable, as only basic requests are used and there is no significant benefit from the additional features. Axios was chosen to comply with standards of the company, and because it was used in the existing parts of the Drivebox application.


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