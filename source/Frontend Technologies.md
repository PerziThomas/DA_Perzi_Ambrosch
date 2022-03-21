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


### React-localize-redux
React-localize-redux is a localization library that enables easier handling of translations in React applications. It is built on the native React _Context_, but understanding or using context is not necessary when using the library.\
The extension allows developers to define texts for different languages in JSON files, which can then be loaded and displayed depending on the selected language.


#### Initialization
All child components of the _LocalizeProvider_ component can work with the _localize_ function. Therefore, it makes sense to place this high in the hierarchy by wrapping the application in an instance of _LocalizeProvider_.

Localize has to be initialized with settings, which must include an array of supported languages, and can include translation settings and initialization options, such as the default language or different rendering options.


#### Adding translation data
There are two different ways to add translations:
- The _addTranslation_ method is used to add translation data in an _all languages_ format, which means the translations for all languages are stored together in a single file.
- The _addTranslationForLangage_ method adds translation data in _single language_ format, meaning that there is one resource file for each supported language.

Translation data is stored in JSON files which are then imported and added to localize. When using the _single language_ format, each translation consists of a property name and the translation for that language. When using the all languages_ format, for every property name, an array of translation texts for the different languages is used instead, in the order used for initialization.\
In both cases, translation data can be nested for easier naming and grouping of properties. This nested structure is represented via periods (".") in the id when calling the translation values.

An example of a resource file in _all languages_ format could be called _translations.json_ and would look as follows:

```json
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
```

With _single language format_, this would instead be split in two files, _en.translations.json_:

```json
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
```

and _de.translations.json_:

```json
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
```


#### Using translations in components
There are two notably different ways in which translations can be integrated in the React code.

- The _Translate_ tag can be used in a self-closing form, with an _id_ prop referencing the translation property name in the resource files.

```jsx
<Translate id="units.length.meter.plural" /> /* will be replaced with "meters" or "Meter" depending on language */
```

- The _translate_ function is given the _id_ as a parameter and returns the translation depending on the currently active language. This function based approach is generally more flexible and allows the translation to be used more easily for situations like usage in string manipulation or when passing component props.

```jsx
translate("units.length.meter.plural") /* returns "meters" or "Meter" */
```


### Leaflet
Lorem Ipsum


#### React Leaflet


#### Leaflet Draw


#### React Leaflet Draw


#### Road extension
Lorem Ipsum


#### Search extension
Lorem Ipsum


### OpenStreetMap
Lorem Ipsum


### GeoJSON
Lorem Ipsum