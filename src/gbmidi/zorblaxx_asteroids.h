
/*============================================================================
	Aznable OS - Zorblaxx demo application - Asteroid routines

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

#ifndef ZORBLAXX_ASTEROIDS_H
#define ZORBLAXX_ASTEROIDS_H

extern unsigned char asteroids_max;
extern unsigned short asteroids_x[];
extern unsigned short asteroids_y[];
extern signed char asteroids_xs[];
extern signed char asteroids_ys[];
extern unsigned char asteroids_timer[];
extern unsigned short asteroids_y_max;
extern unsigned char asteroids_active_max;
extern unsigned char asteroids_active;
extern unsigned char asteroids_difficulty;
extern unsigned char asteroids_difficulty_speedspread;
extern unsigned short asteroids_evaded;

extern void setup_asteroids();

extern void handle_asteroids(unsigned char spawn_enabled);

#endif