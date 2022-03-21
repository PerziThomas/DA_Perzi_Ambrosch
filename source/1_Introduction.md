# Introduction
This thesis describes the development of a geofencing application for the iLogs Drivebox GmbH by giving an overview and further descriptions about the technologies used, the implementation of those technologies as well as descriptions and graphics of the result. The system was created in eight weeks by David Ambrosch and Thomas Perzi while working as interns at the aforementioned company.

## Idea
The company iLogs has a subsidiary called iLogs Drivebox GmbH. This company sells GPS tracking boxes for cars of business to keep track of routes taken by their employees. To provide these customers a way of being alerted if their vehicles left a specifically defined area, the idea of a geofencing system was pitched. Geofences are areas in which cars can enter, leave or stay in. According to those events, a specific action should be performed (e.g. an SMS or an Email is sent). The customer should be provided with the ability to create and manage his geofences in an easy-to-use web interface. Additionally there should be a feature to only make geofences fire events on certain days of the week, configurable by the customer. Finally, the new application should be integrated seamlessly into the existing Drivebox application. 

To summarize, the app possessed three main requirements. Firstly, it needed to be able to handle a load of up to 1000 points of data in a second. Secondly, the user interface needed to be usable without external instruction. And finally, the calculation of the geofence events needed to be correct and fast.

After the original pitch by the managing director, DI Klaus Kienzl, the idea was further developed in weekly meetings and occasional informal talks by the two inters, DI Klaus Kienzl, head of sales Heinz Kienzl and senior developer Christian Polanc.

## Way of working
At iLogs, a SCRUM-like framework was used to define project goals. Every week on monday a longer spring meeting was held to discuss the goals for the coming week, with daily stand up meetings defining daily goals and progress. These meetings had no defined time frame and were held as long as they needed to be.

Version control was handled using a Git server hosted on a Microsoft Azure instance. No git flow was followed while working on the project due to it being an overengineered solution for a project with only two people working on it. 

## Overview
The contents of the thesis are structured into several chapters. Chapter 2 describes the technologies and software engineering techniques used in the front- and backend parts of the application. Furthermore, algorithms and performance optimizations are described. Chapter 3 highlights the importance of testing in this application and shows the several testing frameworks implemented into it. Chapter 5 describes the various considerations that were taken to evaluate requirements and improve usability and user experience of the frontend. Chapter 6 is a resume which summarizes the projects and the learnings taken from it.