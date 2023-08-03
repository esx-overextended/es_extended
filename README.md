<h1 align='center'>ESX Overextended</a></h1>
<p align='center'><a href='https://esx-overextended.github.io/es_extended/installation'>Documentation</a></b></h5>

<hr>

### 📝 Significant changes in compare to ESX Legacy v1.9.4

- Resolved Lua Lint CI Pipeline Issues: Fixed the problems with the Lua Lint CI pipeline to ensure smooth code analysis and validation.

- Updated Interface Functions: Modified various interface-related functions to utilize ox_lib's modern UIs, such as Notification, TextUI, and ProgressBar. This enhances the user experience and gives a more contemporary look and feel.

- Improved Client-side Event Security: Implemented enhanced security measures for client-side events responsible for receiving players' object data from the server. This focuses on strengthening the events to reduce potential vulnerabilities and abuses.

- Streamlined Player Coordinates Tracking: Overhauled the tracking of player object's coordinates by removing the recursive thread creation approach. The new method maintains backward compatibility while improving efficiency and performance. _(This change becomes more impactful as the number of players increases)_

- Enhanced Menu Functionality: Adapted context menu, default menu, and dialog menu related functions to utilize ox_lib's UI while ensuring full backward compatibility. This update allows users to continue using the previous esx_context, esx_menu_default, and esx_menu_dialog if desired, while benefiting from ox_lib's modern UI look.

- Added Some Modules and Functions: Included some modules such as safe event, onesync scope, and routing bucket for better management and consistency across all external resources that utilize ESX object.

- Reduced Framework Dependency Resources: This aims to streamline resource allocation by minimizing the framework's dependency resources.

- Enhanced Some Modules/Functions: Took steps to further improve some already existing functionalities such as including response await for callback calls, integrating pre-defined job duties and job types, etc...

- Revived Some Previous ESX Functions: Reinstated the original ESX HUD and reintroduced the esx:getSharedObject event for loading of the ESX object in external resources

- Multiple Group Support: Implemented a comprehensive multiple group support system that remains fully backward compatibile with ESX Legacy. This enhancement enables player objects to seamlessly associate with multiple groups such as administrators, gangs, VIPs, and more, expanding the flexibility and functionality of the system.

- Server-Side Vehicle Class: Spawned vehicles now possess their own class, providing a plethora of methods to efficiently utilize and manipulate vehicle data. This represents a significant advancement, surpassing the limitations of the previous server-side vehicle spawning system found in esx-legacy.

- Enhanced Extendability: Unlike esx-legacy, where only limited overrides were possible for player objects, the esx-overextended introduces extensive extendability. With this enhanced functionality, developers have the freedom to override existing methods, functions, and fields or even add new ones within the player class, the vehicle class, and of course the ESX object! This flexibility extends to both internal modifications, as simple as adding a new module/file within the framework, as well as external resources through cross-platform `exports`. This breakthrough allows for seamless expansion of customization options without the need to modify core code and functions, providing a more efficient and highly versatile system.

### ℹ Information

ESX is the leading framework, trusted By thousands of commmunities for the highest quality roleplay servers on FiveM, a GTA V (Grand Theft Auto) modification platform.

ESX was initially developed by Gizz back in 2017 for his friend as they were creating a FiveM server and there wasn't any economy roleplaying frameworks available. The original code was written within a week or two and later open sourced. Since then, ESX has undergone continuous enhancements and improvements, with some parts being entirely rewritten to enhance its functionality.

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
