/*============================================================================
	Aznable OS - Zorblaxx demo application - Explosion routines

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

#ifndef ZORBLAXX_EXPLOSIONS_H
#define ZORBLAXX_EXPLOSIONS_H

// Explosions
extern unsigned char explosion_max;
extern unsigned char explosion_timer[];
extern unsigned char explosion_frame[];
extern unsigned char explosion_type[];
extern const unsigned char explosion_lifespan;

extern void setup_explosions();

extern void add_explosion(unsigned type, unsigned char count);

extern void handle_explosions();

#endif