## Frontend Technologies used
The frontend part of the app is a user interface for managing geofences, which was realized as a React web application. The main part of the interface consists of a map provided by _Leaflet_. Due to its open-source nature, additional functionality can be added thanks to a large number of available extensions.


### React
React is a JavaScript library that allows developers to build declarative and component-based user interfaces. Complex UIs can be built with modular, reusable components, which are automatically rendered and updated by React.


#### React app creation
The _create-react-app_ tool is an officially supported


### Axios
Axios is a JavaScript library for making promise-based HTTP requests. It uses _XMLHttpRequests_ when used in the browser, and the native _http_ package when used with node.js.

The package can be installed by using _node package manager_ with the command _npm install axios_.


### Comparison with the Fetch API
The Fetch API provides the _fetch()_ method to make promise-based API requests via the HTTP protocol.\
Fetch and axios are very similar to use, with the main difference being different syntax and property names.\
Both fetch and axios provide all basic functionality needed for making and handling API requests, but axios provides some additional features: [@axiosVsFetch]
- built-in XSRF protection
- automatic JSON conversion of the message body
- request cancelling and request timeout
- interception of HTTP requests
- built-in support for download progress
- wider range of supported browsers

An example GET request, including a header and handling of the request promise, will be demonstrated with _fetch_ below.

```jsx
const headersObj = new Headers({
    'Authorization': 'OTE2MTcyNDgtRDFDMy00QzcwLTg0OTYtMEY5QUYwMUI2NDlE'
});

const reqObj = new Request('https://locahost:44301/api', {
    method: 'get',
    headers: headersObj
})

await axios(reqObj)
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