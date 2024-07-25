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

#include "sys.h"
#include "tilemap.h"

signed char tilemap_offset_x = 0;
signed char tilemap_offset_y = 0;

void update_tilemap_offset()
{
	tilemapctl[0] = tilemap_offset_x;
	tilemapctl[1] = tilemap_offset_y;
}

void scroll_tilemap_left()
{
	tilemapctl[2] = 1;
	while (tilemapctl[2] != 0)
	{
	}
}
void scroll_tilemap_right()
{
	tilemapctl[2] = 2;
	while (tilemapctl[2] != 0)
	{
	}
}
void scroll_tilemap_up()
{
	tilemapctl[2] = 3;
	while (tilemapctl[2] != 0)
	{
	}
}
void scroll_tilemap_down()
{
	tilemapctl[2] = 4;
	while (tilemapctl[2] != 0)
	{
	}
}
void clear_tilemap()
{
	tilemapctl[2] = 5;
	while (tilemapctl[2] != 0)
	{
	}
}