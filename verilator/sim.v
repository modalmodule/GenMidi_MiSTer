`timescale 1ns / 1ps
/*============================================================================
	Aznable (custom 8-bit computer system) - Verilator emu module

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.1
	Date: 2021-10-17

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

module emu (

	input clk_sys,
	input reset,
	input menu,
	
	input [31:0] joystick_0,
	input [31:0] joystick_1,
	input [31:0] joystick_2,
	input [31:0] joystick_3,
	input [31:0] joystick_4,
	input [31:0] joystick_5,
	
	input [15:0] joystick_l_analog_0,
	input [15:0] joystick_l_analog_1,
	input [15:0] joystick_l_analog_2,
	input [15:0] joystick_l_analog_3,
	input [15:0] joystick_l_analog_4,
	input [15:0] joystick_l_analog_5,
	
	input [15:0] joystick_r_analog_0,
	input [15:0] joystick_r_analog_1,
	input [15:0] joystick_r_analog_2,
	input [15:0] joystick_r_analog_3,
	input [15:0] joystick_r_analog_4,
	input [15:0] joystick_r_analog_5,

	input [7:0] paddle_0,
	input [7:0] paddle_1,
	input [7:0] paddle_2,
	input [7:0] paddle_3,
	input [7:0] paddle_4,
	input [7:0] paddle_5,

	input [8:0] spinner_0,
	input [8:0] spinner_1,
	input [8:0] spinner_2,
	input [8:0] spinner_3,
	input [8:0] spinner_4,
	input [8:0] spinner_5,

	// ps2 alternative interface.
	// [8] - extended, [9] - pressed, [10] - toggles with every press/release
	input [10:0] ps2_key,

	// [24] - toggles with every event
	input [24:0] ps2_mouse,
	input [15:0] ps2_mouse_ext, // 15:8 - reserved(additional buttons), 7:0 - wheel movements

	// [31:0] - seconds since 1970-01-01 00:00:00, [32] - toggle with every change
	input [32:0] timestamp,

	output [7:0] VGA_R,
	output [7:0] VGA_G,
	output [7:0] VGA_B,
	
	output VGA_HS,
	output VGA_VS,
	output VGA_HB,
	output VGA_VB,
	
	output	[15:0]	AUDIO_L,
	output	[15:0]	AUDIO_R,
	
	input			ioctl_download,
	input			ioctl_wr,
	input [24:0]	ioctl_addr,
	input [7:0]		ioctl_dout,
	input [7:0]		ioctl_index,
	output reg		ioctl_wait=1'b0
);

// Clock divider from JTFRAME
wire ce_6;
wire ce_2;
/* verilator lint_off PINMISSING */
jtframe_cen24 divider
(
	.clk(clk_sys),
	//.cen12(ce_6), // <-- dodgy video speed for faster simulation, will cause graphical corruption
	.cen6(ce_6), // <-- correct video speed
	.cen2(ce_2)
);
/* verilator lint_on PINMISSING */

// Debug defines
`define DEBUG_SIMULATION

system system(
	.clk_24(clk_sys),
	.ce_6(ce_6),
	.ce_2(ce_2),
	.reset(reset | ioctl_download),
	.pause(1'b0),
	.menu(menu),
	.VGA_HS(VGA_HS),
	.VGA_VS(VGA_VS),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_HB(VGA_HB),
	.VGA_VB(VGA_VB),
	.dn_addr(ioctl_addr[16:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr),
	.dn_index(ioctl_index),
	
	.joystick({joystick_5,joystick_4,joystick_3,joystick_2,joystick_1,joystick_0}),
	.analog_l({joystick_l_analog_5,joystick_l_analog_4,joystick_l_analog_3,joystick_l_analog_2,joystick_l_analog_1,joystick_l_analog_0}),
	.analog_r({joystick_r_analog_5,joystick_r_analog_4,joystick_r_analog_3,joystick_r_analog_2,joystick_r_analog_1,joystick_r_analog_0}),
	.paddle({paddle_5,paddle_4,paddle_3,paddle_2,paddle_1,paddle_0}),
	.spinner({7'b0,spinner_5,7'b0,spinner_4,7'b0,spinner_3,7'b0,spinner_2,7'b0,spinner_1,7'b0,spinner_0}),
	.ps2_key(ps2_key),
	.ps2_mouse({ps2_mouse_ext,7'b0,ps2_mouse}),
	.timestamp(timestamp),
	.AUDIO_L(AUDIO_L),
	.AUDIO_R(AUDIO_R)
);

endmodule 

