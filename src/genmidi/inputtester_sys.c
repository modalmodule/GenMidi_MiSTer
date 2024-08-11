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

#include "../shared/sys.h"
#include "../shared/ps2.h"
#include "inputtester_sys.h"

// DPAD tracker
bool input_left = 0;
bool input_left_last = 0;
bool input_right = 0;
bool input_right_last = 0;
bool input_up = 0;
bool input_up_last = 0;
bool input_down = 0;
bool input_down_last = 0;
bool input_start;
bool input_start_last = 0;
bool input_select;
bool input_select_last = 0;
bool input_a;
bool input_a_last = 0;
bool input_b;
bool input_b_last = 0;
bool input_x;
bool input_x_last = 0;
bool input_y;
bool input_y_last = 0;

// Mouse tracker
bool input_mouse_left;
bool input_mouse_left_last;
bool input_mouse_right;
bool input_mouse_right_last;

// Input tester application state
char state = 3;
char defaultstate = STATE_START_INPUTTESTERADVANCED;//STATE_START_INPUTTESTER;
char nextstate = 3;

// Track joypad 1 directions and start for menu control
void basic_input()
{
	input_up_last = input_up;
	input_down_last = input_down;
	input_left_last = input_left;
	input_right_last = input_right;
	input_start_last = input_start;
	input_select_last = input_select;
	input_a_last = input_a;
	input_b_last = input_b;
	input_x_last = input_x;
	input_y_last = input_y;
	input_mouse_left_last = input_mouse_left;
	input_mouse_right_last = input_mouse_right;

	input_right = CHECK_BIT(joystick[0], 0) || kbd_down[KEY_RIGHT];
	input_left = CHECK_BIT(joystick[0], 1) || kbd_down[KEY_LEFT];
	input_down = CHECK_BIT(joystick[0], 2) || kbd_down[KEY_DOWN];
	input_up = CHECK_BIT(joystick[0], 3) || kbd_down[KEY_UP];
	input_a = CHECK_BIT(joystick[0], 4) || kbd_down[KEY_ENTER];
	input_b = CHECK_BIT(joystick[0], 5) || kbd_down[KEY_SPACE];
	input_x = CHECK_BIT(joystick[0], 6);
	input_y = CHECK_BIT(joystick[0], 7);
	input_start = CHECK_BIT(joystick[1], 3) || kbd_down[KEY_1]|| mse_button1;
	input_select = CHECK_BIT(joystick[1], 2) || kbd_down[KEY_ESC] || mse_button2;
}
