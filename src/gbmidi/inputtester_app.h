/*============================================================================
    Input Test - Input test state handlers

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

#ifndef INPUTTESTER_H
#define INPUTTESTER_H

// Mode switcher variables
extern char modeswitchtimer_select;
extern char modeswitchtimer_start;

#define PAD_COUNT 2
#define BUTTON_COUNT 12

#define color_button_active 0xFF
#define color_button_inactive 0b01010010
#define analog_size 18
#define analog_ratio 15 // 256 / 17;
#define timestamp_clock_index 32
#define timestamp_index_1 8
#define timestamp_index_2 16
#define timestamp_index_3 24
// Button test constants
#define btntest_mode_select 0
#define btntest_mode_ready 1
#define btntest_mode_test 2
#define btntest_mode_results 3
#define btntest_timer_start 60    // vblanks to wait before first prompt
#define btntest_timer_interval 90 // vblanks to wait between prompts
#define btntest_timer_visible 30  // vblanks to wait between prompts
#define btntest_counter_max 5     // Number of button presses required
#define btntest_max 255
#define btntest_highlight_start 2
#define btntest_highlight_end 35

// Initialise digital inputtester state and draw static elements
extern void start_inputtester_digital();

// Initialise analog inputtester state and draw static elements
extern void start_inputtester_analog();

// Initialise advanced inputtester state and draw static elements
extern void start_inputtester_advanced();

// Initialise button test state and draw static elements
extern void start_btntest();

// Initialise Gunsight test state and draw static elements
extern void start_gunsight();

// Digital input tester state
extern void inputtester_digital();

// Analog input tester state
extern void inputtester_analog();

// Advanced input tester state
extern void inputtester_advanced();

// Button test - mode handler
extern void btntest();

// Gunsight test - mode handler
extern void gunsight();


#endif