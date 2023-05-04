<h1 align='center'>ESX Overextended</a></h1>
<p align='center'><a href='https://documentation.esx-framework.org/legacy/installation'>Documentation</a></b></h5>

<hr>

### 📝 Significant changes in compare to ESX Legacy v1.9.4 (WIP)
* Resolved Lua Lint CI Pipeline Issues: Fixed the problems with the Lua Lint CI pipeline to ensure smooth code analysis and validation.

* Updated Interface Functions: Modified various interface-related functions to utilize ox_lib's modern UIs, such as Notification, TextUI, and ProgressBar. This enhances the user experience and gives a more contemporary look and feel.

* Improved Client-side Event Security: Implemented enhanced security measures for client-side events responsible for receiving players' object data from the server. This focuses on strengthening the events to reduce potential vulnerabilities and abuses.

* Streamlined Player Coordinates Tracking: Overhauled the tracking of player object's coordinates by removing the recursive thread creation approach. The new method maintains backward compatibility while improving efficiency and performance. *(This change becomes more impactful as the number of players increases)*

* Enhanced Context Menu Functionality: Adapted context-menu-related functions to utilize ox_lib's UI while ensuring backward compatibility. This update allows users to continue using the previous esx_context if desired, while benefiting from ox_lib's context UI look.

* Reduced Framework Dependency Resources: This aims to streamline resource allocation by minimizing the framework's dependency resources. **(WIP)**


### ℹ Information

ESX is the leading framework, trusted By thousands of commmunitys for the heighest quality roleplay servers on FiveM, a GTA V (Grand Theft Auto) modification platform.

ESX was initially developed by Gizz back in 2017 for his friend as the were creating an FiveM server and there wasn't any economy roleplaying frameworks available. The original code was written within a week or two and later open sourced. Since then, ESX has undergone continuous enhancements and improvements, with some parts being entirely rewritten to enhance its functionality.


### 📌Legal Notices

<table>
<tr>
<td>

es_extended - ESX framework for FiveM

Copyright (C) 2015-2023 ESX-Framework (Jérémie N'gadi)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

</td>
</tr>

<tr>
<td>

You should have received a copy of the GNU General Public License along with this program.
If not, see https://www.gnu.org/licenses/

</td>
</tr>
</table>
