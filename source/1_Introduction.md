# Introduction
\fancyfoot[L]{Ambrosch/Perzi}
This thesis describes the development of a geofencing application for the ilogs DRiVEBOX GmbH by giving an overview and further descriptions about the technologies used, the implementation of those technologies as well as descriptions and graphics of the result. The system was created in eight weeks by David Ambrosch and Thomas Perzi during the internship at the aforementioned company.

## Idea
The company ilogs has a subsidiary called ilogs DRiVEBOX GmbH. This company sells GPS tracking boxes for cars with which businesses can keep track of routes taken by their employees. To provide these customers a way of being alerted if their vehicles left a specifically defined area, the idea of a geofencing system was pitched. Geofences are areas which cars can enter, leave or stay in. According to those events, a specific action should be performed (e.g. an SMS or an Email is sent). The customer should be provided with the ability to create and manage his geofences in an easy-to-use web interface. Additionally there should be a feature to only make geofences fire events on certain days of the week, configurable by the customer. Finally, the new application should be integrated seamlessly into the existing Drivebox application. 

To summarize, the app possessed three main requirements. Firstly, it needed to be able to handle a load of up to 1000 points of data in a second. Secondly, the user interface needed to be usable without external instruction. And finally, the calculation of the geofence events needed to be correct and fast.

After the original pitch by the managing director, DI Klaus Kienzl, the idea was further developed in weekly meetings and occasional informal talks by the two inters, DI Klaus Kienzl, head of sales Heinz Kienzl and senior developer Christian Polanc.

## Way of working
At ilogs, a SCRUM-like framework was used to define project goals. Every week on Monday a longer sprint meeting was held to discuss the goals for the coming week, with daily stand up meetings defining daily goals and progress. These meetings had no defined time frame and were held as long as they needed to be.

Version control was handled using a Git server hosted on a Microsoft Azure instance. No git flow was followed while working on the project due to it being an overengineered solution for a project with only two people working on it. 

## Overview
The content of this thesis is structured into several chapters. Chapter 2 describes the technologies and software engineering techniques used in the front- and backend parts of the application. Furthermore, algorithms and performance optimizations are described. Chapter 3 highlights the importance of testing in this application and shows the several testing frameworks implemented into it. Chapter 5 describes the various considerations that were taken to evaluate requirements and improve usability and user experience of the frontend. Chapter 6 is a resume which summarizes the projects and the learnings taken from it.

## Use Cases
\fancyfoot[L]{Ambrosch}
To summarize all functionality of the app, a use case diagram is used which shows all the ways a user can interact with the application.\
The use cases have been grouped into categories for visual clarity and easier understanding. These basic groups and their use cases will be described below.
The boundary of system in all the following diagrams is considered to be the Geofencing application.

The category _Geofence creation_ (figure 1.1) contains all use cases for geofence creation. Since geofences can be created in several ways, which are fundamentally different in the way they work, multiple use cases are displayed that are generalized under a parent use case "Create Geofence".

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/Use_Cases/Geofence_creation.png}
	\caption{Use cases for geofence creation}
	\label{fig1_1}
\end{figure}

The _Geofence locking_ category (figure 1.2) includes functions for viewing and toggling locks, as well as bulk operations, which make use of the toggle feature and are therefore associated.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/Use_Cases/Geofence_locking.png}
	\caption{Use cases for geofence locking}
	\label{fig1_2}
\end{figure}

_Geofence metadata_ (figure 1.3) can be viewed, created, deleted or used to filter the list of geofences.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.70\textwidth]{source/figures/Use_Cases/Geofence_metadata.png}
	\caption{Use cases for geofence metadata}
	\label{fig1_3}
\end{figure}

Use cases for _Geofence functions_ (figure 1.4) consist of all remaining functions that are directly related to geofences, but are not covered by the previous categories. This includes view, edit and delete operations as well as the geofence edit history and visibility features.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.90\textwidth]{source/figures/Use_Cases/Geofence_functions.png}
	\caption{Use cases for geofence functions}
	\label{fig1_4}
\end{figure}

Two use cases are provided by the program in the form of _API services_ (figure 1.5) not connected to any frontend, a feature to get all intersections between a path and geofences, and a feature that shows geofence entry or exit events.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.60\textwidth]{source/figures/Use_Cases/API_Services.png}
	\caption{Use cases for API services}
	\label{fig1_5}
\end{figure}

_Miscellaneous_ use cases (figure 1.6) are not covered by any of the categories above and include geofence color selection as well as a map search.

\begin{figure}[H]
	\centering
  \includegraphics[width=0.60\textwidth]{source/figures/Use_Cases/Miscellaneous.png}
	\caption{Use cases for miscellaneous functions}
	\label{fig1_6}
\end{figure}
