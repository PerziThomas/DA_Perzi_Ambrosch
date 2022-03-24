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
The extension allows developers to define texts for different languages in JSON files, which can then be loaded and displayed depending on the selected language. [@reactLocalizeRedux]


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

- The _translate_ function is given the _id_ as a parameter and returns the translation depending on the currently active language. This function based approach is generally more flexible and allows the translation to be used more easily for situations like usage in string manipulation or when passing component props. [@reactLocalizeRedux]

```jsx
translate("units.length.meter.plural") /* returns "meters" or "Meter" */
```


#### Leaflet
_Leaflet_ is the leading open-source JavaScript library for interactive maps. It is a technology used by the company for maps in existing apps, and is also ideal for testing applications, since the library - including all of its features - is free to use, with no restrictions like monthly time or data limits for the map services. [@leafletOverview]

Because Leaflet is open-source, a lot of additional libraries exist, some of which were used in the app and will be described in the following sections.


#### React Leaflet
_React Leaflet_ is a node library that offers React components for Leaflet maps, making it easier to use in a React context. It is responsible for things such as providing hooks or rendering Leaflet layers by itself to avoid updating the DOM tree. [@reactLeafletIntro]

React Leaflet does not replace Leaflet, but it is used in conjunction with it. While the application is written with React Leaflet where possible, in some cases, solutions involving the standard Leaflet have to be used to achieve a specific task.


##### Setup
After installing the required dependencies _react, react-dom_ and _leaflet_, a simple map can be added to a React application by adding the following code:

```jsx
<MapContainer center={[0, 0] /* initial coordinates of map bounds */} zoom={13}>
	<TileLayer
		attribution='&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
		url="https://{s}.tile.openstreetmap.de/{z}/{x}/{y}.png" // use openstreetmap.org for international tiles
	/>

	<Polygon positions={coordinates /* lat lng coordinate array */} />
</MapContainer>
```


#### Leaflet Draw
The JavaScript library _Leaflet Draw_ adds interactive drawing features to Leaflet maps. The library can be used to add a toolbar to Leaflet maps, containing options for drawing different shapes, as well as editing them.\
The toolbar can also be customized with regards to what features are available. [@leafletDrawDocumentation]


#### React Leaflet Draw
_React Leaflet Draw_ is a library for using Leaflet Draw features with React Leaflet. It achieves this by providing an _EditControl_ component that is used in the Leaflet Map and can then be used to customize the Leaflet Draw toolbar or to overwrite event handlers. [@reactLeafletDrawIntro]


##### Setup
To be able to include drawing functions in a map, the _leaflet-draw_ styles have to be added to the project by including

```jsx
<link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/leaflet.draw/1.0.4/leaflet.draw.css"/>
```

or

```
node_modules/leaflet-draw/dist/leaflet.draw.css
```

Afterwards, an _EditControl_ component can be added to a map to enable drawing features to be used. This component must be placed in a _FeatureGroup_ component, and all geometry that is drawn inside this FeatureGroup will be made editable by the extension once the "edit"-button is clicked.\
The EditControl component provides event handlers for all events related to the drawing functions, like _onCreated, onEdited_ and _onDeleted_, which can be overwritten by the developer to add custom functionality.\
The _draw_ property allows the developer to enable or disable certain features or buttons in the extension's toolbar.

Adding _React Leaflet Draw_ to the map example given above in the chapter _React Leaflet_ would produce the following code:

```jsx
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
```


#### Leaflet Routing Machine
Leaflet Routing Machine is a Leaflet extension that adds routing tools to the standard map. It offers route finding with start, destination and via points, with integrated map controls for adding, editing and removing waypoints. [@leafletRoutingMachine]


##### Getting started
The package has to be installed in the project, with the use of a script tag or by installing _leaflet-routing-machine_ with a package manager such as npm.\
A basic example of the routing machine with two initial waypoints can be added as follows:

```jsx
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
```


#### Leaflet Geosearch
Lorem Ipsum [@leafletGeosearch]


### OpenStreetMap
OpenStreetMap is a community driven project to provide geographical map data. This data can be used for any purpose without any costs, as long as credit is given. Since map data is provided by a great variety of contributors, a special emphasis is placed on local knowledge. A combination of technologies like aerial photography, GPS and maps is used to verify the accuracy of geographical entries. [@openStreetMapAbout]

OpenStreetMap is the default map provider used by the _Leaflet_ extension.


### GeoJSON
GeoJSON is a format for encoding geospatial data based on _JavaScript Object Notation_. It defines various types of objects to represent geographic objects and their properties. The latest standard for the format is specified in _RFC 7946_, which was published in August 2016.

The format supports seven different geometry objects as well as _Feature_ objects, which can have additional information, and collection objects to group sets of features.


#### Geometry object
There are seven basic geometry objects types:

1. Position
: an array of two or more numbers, representing longitude, latitude and optionally height

For the remaining six types, the explanation refers to the content of that objects "coordinates" property:

2. Point
: a single position
3. MultiPoint
: an array of positions
4. LineString
: an array of two or more points
5. MultiLineString
: an array of LineString coordinate arrays
6. Polygon
: an array of linear ring coordinate arrays
7. MultiPolygon
: an array of Polygon coordinate arrays


##### Polygon
A polygon consists of one or more coordinate arrays that should be linear rings. A linear ring is a closed LineString, meaning the first and last position share the same coordinates. It must have a minimum of four positions, which would describe a triangle.

If multiple coordinate rings are used in a polygon, the first one must be an outer exterior ring. All other rings must be interior rings that describe holes in the previously defined exterior ring.


#### Geometry collection
A GeometryCollection has a member "geometries" which contains an array of geometry objects as described above, which can also be empty.\
GeometryCollections can be used to describe geometry not possible with the normal geometry types, like polygons that consist of multiple exterior rings.


#### Feature object
Features are objects that represent a thing that is spatially bounded. They contain geometry information, but do not represent the geometry itself.

A Feature has a member "geometry" which can be either a geometry object or null if no location is specified.


#### Feature collection
A FeatureCollection can be used to group different features together. It has a member "features", which is an array where each element is a Feature object as described above. This array can also be empty. [@geoJsonSpecification]


#### Example
The following example of a GeoJSON objects consists of a FeatureCollection, which includes five features with different geometries: one LineString, two Points and one Polygon.

```json
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
```
