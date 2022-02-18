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

A pagination feature, as described in chapter _Pagination_, splits the total collection of geofences and only displays a portion in the frontend list and map. The feature also allows the user to change the number of geofences to be displayed per page, which can be chosen higher if performance allows it or lower if otherwise.

A geofence hiding feature, as described in chapter _Geofence visibility_, also makes it possible to hide specific geofences from the map, which cleans up the view for the user, but can also improve performance by not rendering particularly complex geofences.


### Reduction of editable geometries
While the edit mode provided by _leaflet-draw_ is enabled in the _leaflet_ map, all editable polygons are shown with draggable edit markers for each point of their geometry. These edit markers, when present in large quantities, cause considerably lag when edit mode is enabled. To improve this, certain geofences are marked as non-editable and are not shown in the map's edit mode, as described in chapter _Non-editable geofences_.


### Reduction of backend calls
geofence locks move up to home to avoid polling

