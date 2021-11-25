---
title: Development of a Full-Stack Geofencing Application 
author: David Ambrosch & Thomas Perzi
...

# Backend Technologies used
Lorem Ipsum


## ASP.NET Core
Lorem Ipsum


## MS SQL
Lorem Ipsum


### T-SQL
Lorem Ipsum


### SQL Spatial
Lorem Ipsum


## Ado.Net
Lorem Ipsum


### Comparison with Entity Framework
Lorem Ipsum


## NetTopologySuite
Lorem Ipsum


# Architecture
Lorem Ipsum


# Implementation
Lorem Ipsum


## REST Api communication with Frontend and Drivebox Server
Lorem Ipsum


## Calculation Algorithm for intersections
Lorem Ipsum


### Point based
Lorem Ipsum


### Route based
Lorem Ipsum


## Polygon Creating
Lorem Ipsum


# Performance optimization on the backend
Lorem Ipsum


## Caching in ASP.NET
Lorem Ipsum


## Using Geo-Indexes in MS SQL
Lorem Ipsum


# Testing
This chapter will describe the multiple ways used to test the application. Besides testing the functionality of the classes and methods like it is common in every commercial
application, the stressability of the application is critical in this particular use case, as it needs to be able to handle the positional data of up to 1000 cars in the span
of a few seconds. Hence why it was vital to assure that each component of the applications architecture was able to perform under the heaviest load and ensure scalability
in the future if more cars are added to the service.


## Functional Testing
There are several methods which are used when testing the functionality of an application, with four being the de-facto industry standard.

1. Unit Testing
2. Integration Testing
3. System Testing
4. Acceptance Testing


### Frontend using Selenium
Lorem Ipsum


### Backend Algorithms using Moq
Lorem Ipsum


## Stress Testing
Lorem Ipsum


### MS SQL using SQLQueryStress and Performance Monitor
Lorem Ipsum


### ASP.NET using Apache JMeter
Lorem Ipsum


# Frontend Technologies used
Lorem Ipsum


## React
Lorem Ipsum


### Axios
Lorem Ipsum


### React-localize-redux
Lorem Ipsum


## Material UI
Lorem Ipsum


## Leaflet
Lorem Ipsum


### Road extension
Lorem Ipsum


### Search extension
Lorem Ipsum


## OpenStreetMap
Lorem Ipsum


## GeoJSON
Lorem Ipsum


# Project Structure
Lorem Ipsum


# Geofence Management Web-Interface
Lorem Ipsum


## Geofence creation
Lorem Ipsum


## Geofence editing
Lorem Ipsum


## Circle geofences
Lorem Ipsum


## Road geofences
Lorem Ipsum


## Geofence locking
Lorem Ipsum


## Geofence highlighting
Lorem Ipsum


## Pagination
Lorem Ipsum


## Geofence metadata filtering
Lorem Ipsum


# User Interface & User Experience
Lorem Ipsum


## Requirements
Lorem Ipsum


## Mockup
Lorem Ipsum


## Specific elements
Lorem Ipsum


## Integration into DriveBox
Lorem Ipsum


# Performance optimization on the frontend
Lorem Ipsum


## Reducing component reloads (React.memo + move up state variables)
Lorem Ipsum


## Reducing number of points for road geofences
Lorem Ipsum


## Reducing number of loaded geofences (pagination + visibility)
Lorem Ipsum


