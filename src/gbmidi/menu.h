/*============================================================================
	Aznable OS - Popup menu functions 

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.0
	Date: 2021-07-13

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

#ifndef MENU_H
#define MENU_H

// Menu constants
#define menu_tx 12
#define menu_bx 28
#define menu_my 15
#define menu_openholdtime 60
#define menu_count 6

#define menu_panel_outline_high 0xFF
#define menu_panel_outline_mid 0b00110110
#define menu_panel_outline_low 0b00100100
#define menu_panel_back 0x00

#define menu_outline_high 0b10111111
#define menu_outline_mid 0b10110110
#define menu_outline_low 0b01100100
#define menu_text 0b10110110
#define menu_back 0x00

#define menu_sel_outline_high 0b01011111
#define menu_sel_outline_mid 0b00010110
#define menu_sel_outline_low 0b00010100
#define menu_sel_text 0xFF
#define menu_sel_back 0b00001001

// Menu variables
extern unsigned char menu_timer;
extern unsigned char menu_index;
extern unsigned char menu_dirty;
extern unsigned char menu_ready;
extern char *menu_string[];

// Initialise menu state
extern void start_menu();

// Menu state
extern void menu();

#endif