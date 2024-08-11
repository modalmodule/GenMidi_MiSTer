/*============================================================================
	Input Test - Snek mini-game

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2021-07-12

	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the Free
	Software Foundation; either version 3 of the License, or (at your option)
	any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program. If not, see <http://www.gnu.org/licenses/>.
===========================================================================*/

#ifndef SNEK_H
#define SNEK_H

// SNEK constants
#define movefreqinit 14
#define movefreqdecfreq 200
#define playerchar 83
// SNEK variables
extern unsigned char movefreqdectimer;
extern unsigned char movefreq;
extern unsigned char movetimer;
extern signed int x;
extern signed int y;
extern signed char xd;
extern signed char yd;
extern signed char nxd;
extern signed char nyd;
extern unsigned int length;

// Attract mode variables
extern unsigned char attractstate;

// Initialise attract state and draw static elements
extern void start_snek_attract();

// Initialise attract state and draw static elements
extern void start_snek_gameplay();

// SNEK - gameplay state
extern void snek_gameplay();

// SNEK - attract state
extern void snek_attract();

#endif