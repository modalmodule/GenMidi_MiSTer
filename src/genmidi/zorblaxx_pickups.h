/*============================================================================
	Aznable OS - Zorblaxx demo application - Pickup routines

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

#ifndef ZORBLAXX_PICKUPS_H
#define ZORBLAXX_PICKUPS_H

// Pickups
extern unsigned char pickup_max;
extern unsigned char pickup_type_count;
extern unsigned char pickup_state[];
extern unsigned char pickup_value[];
extern unsigned char pickup_timer[];

extern void spawn_pickup();

extern void setup_pickups();

extern void handle_pickups();

#endif