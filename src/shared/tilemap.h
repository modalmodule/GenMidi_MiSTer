/*============================================================================
	Aznable OS - Zechs (tilemap engine)

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2022-01-03

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
#ifndef TILEMAP_H
#define TILEMAP_H

extern signed char tilemap_offset_x;
extern signed char tilemap_offset_y;

extern void update_tilemap_offset();
extern void scroll_tilemap_left();
extern void scroll_tilemap_right();
extern void scroll_tilemap_up();
extern void scroll_tilemap_down();
extern void clear_tilemap();

#endif