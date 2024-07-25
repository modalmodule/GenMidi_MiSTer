/*============================================================================
	Aznable OS - Zorblaxx demo application - Trail routines

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2021-11-27

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

#ifndef ZORBLAXX_TRAILS_H
#define ZORBLAXX_TRAILS_H

// Trails
extern unsigned char trail_max;
extern unsigned short trail_x[];
extern unsigned short trail_y[];
extern signed char trail_xs[];
extern signed char trail_ys[];
extern unsigned char trail_timer[];
extern unsigned short trail_y_max;

extern void setup_trails();

extern void add_player_trail();

extern void handle_trails();

#endif