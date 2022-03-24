## Performance optimization on the frontend
Lorem Ipsum


### Reduction of component rerenders
One of the biggest performance factors affecting performance of the React app are component rerenders. By using the profiler from _React Developer Tools_, a list of all component rerenders within the page can be shown ranked by the time taken.

By looking at the graph for the geofence management app, it can be seen that the _LeafletMap_ component takes significantly more time reloading than all other components and should be optimized.\

![React Profiler View before implementing performance optimizations.](source/figures/React_Profiler_before.png "Screenshot"){#fig:stress_one width=90%}
\  

The map component is then wrapped in _React.memo_ to rerender only when relevant props have changed. In the case of this app, that means a change in the collection of geofences to be displayed, a change regarding road geofence creation that is displayed in the map, or some meta settings like the colour of polygons.\

With a custom check function _isEqual_, the _React.memo_ function can be set to react only when one of these props changes.

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

![React Profiler View after implementing performance optimizations.](source/figures/React_Profiler_after.png "Screenshot"){#fig:stress_one width=90%}
\ 

The render duration of the map component has been reduced from 585.6 ms to clearly below 0.5 ms, where it does not show up in the ranked list of the profiler anymore.
This also has the effect that the application now runs noticeably smoother, especially when handling the map.

Similar changes are also applied to other components that cause lag or rerender unnecessarily.


### Reduction of loaded geofences
Lorem Ipsum (pagination)


### Reduction of backend calls
geofence locks move up to home to avoid polling

