/*============================================================================
	Input Test - Mouse ping animations

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2021-12-22

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

#ifndef INPUTTESTER_PINGS_H
#define INPUTTESTER_PINGS_H

extern unsigned char ping_max;
extern unsigned char ping_sprite_first;
extern unsigned char ping_timer[];
extern unsigned char ping_frame[];
extern unsigned char ping_type[];
extern const unsigned char ping_lifespan;

extern void setup_pings();

extern void add_ping(unsigned type, unsigned short x, unsigned short y);

extern void handle_pings();

#endif