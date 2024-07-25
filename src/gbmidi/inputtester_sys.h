/*============================================================================
	Input Test - Custom system functions

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

#ifndef INPUTTESTER_SYS_H
#define INPUTTESTER_SYS_H

// Application states
#define STATE_START_INPUTTESTER 1
#define STATE_INPUTTESTER 2

#define STATE_START_INPUTTESTERADVANCED 3
#define STATE_INPUTTESTERADVANCED 4

#define STATE_START_INPUTTESTERANALOG 5
#define STATE_INPUTTESTERANALOG 6

#define STATE_START_BTNTEST 7
#define STATE_BTNTEST 8

#define STATE_START_GUNSIGHT 9
#define STATE_GUNSIGHT 10

#define STATE_START_MENU 11
#define STATE_MENU 12

#define STATE_FADEOUT 20
#define STATE_START_FADEIN 21
#define STATE_FADEIN 22

#define STATE_START_ATTRACT 30
#define STATE_ATTRACT 31

#define STATE_START_GAME_SNEK 40
#define STATE_GAME_SNEK 41

#define STATE_START_CREDITS 42

#define STATE_START_ZORBLAXX 43

#define GET_TIMER ((unsigned short)timer[1] << 8) | (unsigned char)timer[0]

// DPAD tracker
extern bool input_left;
extern bool input_left_last;
extern bool input_right;
extern bool input_right_last;
extern bool input_up;
extern bool input_up_last;
extern bool input_down;
extern bool input_down_last;
extern bool input_start;
extern bool input_start_last;
extern bool input_select;
extern bool input_select_last;
extern bool input_a;
extern bool input_a_last;
extern bool input_b;
extern bool input_b_last;
extern bool input_x;
extern bool input_x_last;
extern bool input_y;
extern bool input_y_last;

// Mouse tracker
extern bool input_mouse_left;
extern bool input_mouse_left_last;
extern bool input_mouse_right;
extern bool input_mouse_right_last;

// Input tester application state
extern char state;
extern char defaultstate;
extern char nextstate;

// Track joypad 1 directions and start for menu control
extern void basic_input();

#endif