/*============================================================================
	Aznable OS - Casval (sprite engine)

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

#include "sys.h"
#include "sprite.h"

#define const_sprite_max 32
unsigned char sprite_max = const_sprite_max;
unsigned char spr_x_l[const_sprite_max];
unsigned char spr_x_h[const_sprite_max];
unsigned char spr_y_l[const_sprite_max];
unsigned char spr_y_h[const_sprite_max];
bool spr_on[const_sprite_max];
bool spr_collide[const_sprite_max];
unsigned char spr_palette_index[const_sprite_max];
unsigned char spr_index[const_sprite_max];
unsigned char spr_size[const_sprite_max];

unsigned char spr_highbits[const_sprite_max]; // Temp cache of high bits excluding upper 2 Y bits

void set_sprite_position(unsigned char sprite, unsigned short x, unsigned short y)
{
	spr_x_h[sprite] = x >> 8;
	spr_x_l[sprite] = (unsigned char)x;
	spr_y_h[sprite] = y >> 8;
	spr_y_l[sprite] = (unsigned char)y;
}
void set_sprite_position_x(unsigned char sprite, unsigned short x)
{
	spr_x_h[sprite] = x >> 8;
	spr_x_l[sprite] = (unsigned char)x;
}

void update_sprites()
{
	unsigned char s = 0;
	for (unsigned char sprite = 0; sprite < sprite_max; sprite++)
	{
		if (spr_on[sprite])
		{
			// Set sprite properties
			spriteram[s++] = spr_highbits[sprite] | spr_y_h[sprite];   // Enabled (1 bit) + Collide (1 bit) + Size (2 bits) + Palette Index (2 bits) + Position Y (upper 2 bits)
			spriteram[s++] = spr_y_l[sprite];						   // Position Y (lower 8 bits)
			spriteram[s++] = spr_index[sprite] << 2 | spr_x_h[sprite]; // Sprite Index (6 bits) + Position X (upper 2 bits)
			spriteram[s++] = spr_x_l[sprite];						   // Position X (lower 8 bits)
		}
		else
		{
			// Clear first sprite byte to disable
			spriteram[s] = 0;
			s += 4;
		}
	}
}

void enable_sprite(unsigned char sprite, unsigned char palette_index, unsigned char size, unsigned char collide)
{
	spr_on[sprite] = 1;
	spr_collide[sprite] = collide;
	spr_palette_index[sprite] = palette_index;
	spr_size[sprite] = size;
	spr_highbits[sprite] = 1 << 7 | collide << 6 | palette_index << 4 | size << 2;
}

void clear_sprites()
{
	for (unsigned char sprite = 0; sprite < sprite_max; sprite++)
	{
		spr_on[sprite] = 0;
	}
}
void clear_sprites_range(unsigned char first, unsigned char last)
{
	for (unsigned char sprite = first; sprite <= last; sprite++)
	{
		spr_on[sprite] = 0;
	}
}