/*============================================================================
	Input Test - Fader

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
#ifndef FADER_H
#define FADER_H

// Fade in/out constants
#define fadefreq 4
// Fade in/out variables
extern unsigned char fade;
extern unsigned char fadetimer;

// Initialise fadeout state
extern void start_fadeout();

// Initialise fadein state
extern void start_fadein();

// Fade out state
extern void fadeout();

// Fade in state
extern void fadein();

#endif