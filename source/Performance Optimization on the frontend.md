## Performance optimization on the frontend
Lorem Ipsum


### Reduction of component rerenders
One of the biggest factors affecting performance of the React app is the number of component rerenders, especially ones which happen after changes to parameters of a component, that have no effect on the state of that component. Reducing the number of these unnecessary rerenders is important to improve frontend performance and therefore usability.


#### Measuring component render times
To improve frontend performance, the render times of all components have to be recorded in order to find out which elements cause the most lag.

_React Developer Tools_ is a _Chrome_ extension that adds React debugging tools to the browser's Developer Tools. There are two added tabs, _Components_ and _Profiler_, the latter of which is used for recording and inspecting performance data. [@reactDevToolsChrome]

The _Profiler_ uses React's Profiler API to measure timing data for each component that is rendered. The workflow to use it will be briefly described here.\
After navigating to the _Profiler_ tab in the browser's Developer Tools, a recording can either be started immediately or set to be started once the page is reloaded. Once the developer has finished performing any actions in the app that they suspect could be impacting performance, the recording can be stopped again. [@reactProfilerIntro]

The recorded data can be viewed in different graphical representations, including the render durations of each individual element. When testing performance for this app, mostly the _Ranked Chart_ was used, because it is ordered by the time taken to rerender for each component and gives the developer a quick overview where improvements need to be made.


#### Avoiding unnecessary rerenders
By looking at a graph of the geofence management app recorded with the _Profiler_, it can be seen that the _LeafletMap_ component takes significantly more time to rerender than all other components and should therefore be optimized.\

![React Profiler View before implementing performance optimizations.](source/figures/React_Profiler_before.png "Screenshot"){#fig:stress_one width=90%}
\  

The map component is wrapped in _React.memo_ in order to rerender only when relevant props have changed. In the case of this app, that means a change in the collection of geofences to be displayed, a change regarding road geofence creation that is displayed in the map, polygon colour or some meta settings.\

With a custom check function _isEqual_, the _React.memo_ function can be set to rerender only when one of these props changes.

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
The render duration of the map component has been reduced from 585.6 ms to a value clearly below 0.5 ms, where it does not show up at the top of the _Profiler_'s ranked chart anymore.
This has the effect that the application now runs noticeably smoother, especially when handling the map, since the _LeafletMap_ component does not update every time the map position or the zoom is changed.

![React Profiler View after implementing performance optimizations.](source/figures/React_Profiler_after.png "Screenshot"){#fig:stress_one width=90%}
\ 

Similar changes are also applied to other components that cause lag or rerender unnecessarily.


### Reduction of loaded geofences
During testing of the app, it became clear that frontend performance is connected to the number of geofences that are loaded at any given point in time. This effect was magnified when multiple geofences with high point counts, like state presets or road geofences, were displayed at once. This appears to be a limitation inherent to the _leaflet_ map that cannot be fixed in itself. Instead, the user of the app is given the option to have less geofences shown on the map at once.

A pagination feature, as described in chapter [TODO: link/number] _Pagination_, splits the total collection of geofences and only displays a portion in the frontend list and map. The feature also allows the user to change the number of geofences to be displayed per page, which can be chosen higher if performance allows it or lower if otherwise.

A geofence hiding feature, as described in chapter [TODO: link/number] _Geofence visibility_, also makes it possible to hide specific geofences from the map, which cleans up the view for the user, but can also improve performance by not rendering particularly complex geofences.


### Reduction of editable geometries
While the edit mode provided by _leaflet-draw_ is enabled in the _leaflet_ map, all editable polygons are shown with draggable edit markers for each point of their geometry. These edit markers, when present in large quantities, cause considerably lag when edit mode is enabled. To improve this, certain geofences are marked as non-editable and are not shown in the map's edit mode, as described in chapter [TODO: link/number] _Non-editable geofences_.


### Reduction of backend calls
Performance of the frontend interface is improved by minimizing the number of requests made to the backend, by avoiding techniques like polling. This reduces the total loading times and load on the network, and also making some UI elements more responsive by not relying on backend data for updates.


#### Polling geofence locks
In the initial implementation of the bulk operations for locking (chapters [TODO: link/number] _Locking_ and [TODO: link/number] _Bulk operations_), when an action was performed, the weekday/locking buttons for each affected geofence did not update as expected.\
The reason was that the locks for each geofence were stored in the React state of that geofence's _GeoFenceListItem_ component and were fetched for that geofence alone only once on initial loading of that component. This means that, when a bulk operation is performed in the parent _GeoFenceList_ component, no rerender is triggered and the locks are not updated in the _GeoFenceListItem_, since non of its props have changed.

To solve this problem, a polling mechanism was implemented, where the _GeoFenceListItems_ repeatedly call the backend after a fixed interval of time. Any updates that happen in the backend are now displayed in the frontend, but can be delayed depending on the interval set for polling.\
Performance is notably affected by this approach, due to the high number of network calls, even when no locking data has changed.


#### Lifting state up
While there are workarounds to force a child component to rerender from its parent [@reactForceChildRerender], in this case, it is more elegant to __lift the state__ of the geofence locks from the _GeoFenceListItems_ to a parent component like _GeoFenceList_ or even _Home_.\
Now, when the state changes in the parent component, for example through _geofence bulk locking operations_, all child components are automatically updated by React and the the changes to geofence locks can be seen immediately. [@reactLiftingStateUp]

