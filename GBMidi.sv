
/*============================================================================
	Game Boy Midi Core - emu module

	Aruthor: ModalModule - https://github.com/modalmodule/
	Version: 0.1
	Date: 2024-02-19

	Based on aznable/InputTest core
	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 1.1
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

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_DTR} = 1; //UART_TXD,
assign UART_TXD = 0; // not driven currently
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign FB_FORCE_BLANK = 0;
assign VGA_F1 = 0;
assign VGA_SCALER = 0;
assign HDMI_FREEZE = 0;
assign VGA_DISABLE = 0;

assign AUDIO_MIX = 0;

assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

wire [1:0] ar = 0;//status[9:8];

assign VIDEO_ARX = (!ar) ? 12'd4 : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? 12'd3 : 12'd0;

`include "build_id.v"
localparam CONF_STR = {
	"GenMidi;UART31250,MIDI;",
	"-;",
	"D1O[2],Midi Source,USB,Din;",
	"-,FOR USB SETUP UART (PRESS->);",
	"-;",
	"O[3],Musical Gamepad,Off,On;",
	"-;",
	"DBO[68:67],Midi Ch 1 Voice,FM,PSG,Noise;",
	"-;",
	"P1,FM0 Settings;",
	"P1-;",
	"P1O[21:19],Patch,Lead 1,Bass 1,Bell Lead,Custom;",  
	"D3P1F1,TFI,Load Custom Patch;",
	"P1O[14],Vibrato,Off,On;",  
	"P1-;",
	"P2,FM1 Settings;",
	"P2-;",
	"P2O[38:36],Patch,Lead 1,Bass 1,Bell Lead,Custom;", 
	"D4P2F2,TFI,Load Custom Patch;",
	"P2O[31],Vibrato,Off,On;",  
	"P2-;",
	"P3,FM2 Settings;",
	"P3-;",
	"P3O[51:49],Patch,Lead 1,Bass 1,Bell Lead,Custom;", 
	"D6P3F3,TFI,Load Custom Patch;",
	"P3O[56],Vibrato,Off,On;",
	"P3-;",
	"P4,FM3 Settings;",
	"P4-;",
	"P4O[71:69],Patch,Lead 1,Bass 1,Bell Lead,Custom;", 
	"D7P4F4,TFI,Load Custom Patch;",
	"P4O[78],Vibrato,Off,On;",
	"P4-;",
	"P5,FM4 Settings;",
	"P5-;",
	"P5O[74:72],Patch,Lead 1,Bass 1,Bell Lead,Custom;", 
	"D8P5F5,TFI,Load Custom Patch;",
	"P5O[79],Vibrato,Off,On;",
	"P5-;",
	"P6,FM5 Settings;",
	"P6-;",
	"P6O[77:75],Patch,Lead 1,Bass 1,Bell Lead,Custom;", 
	"D9P6F6,TFI,Load Custom Patch;",
	"P6O[80],Vibrato,Off,On;",
	"P6-;",
	"P7,PSG0 Settings;",
	"P7-;",
	//"P7O[77:75],Patch,Lead 1,Bass 1,Bell Lead,Custom;", 
	"P7O[81],Vibrato,Off,On;",
	"P7-;",
	"P8,PSG1 Settings;",
	"P8-;",
	//"P7O[77:75],Patch,Lead 1,Bass 1,Bell Lead,Custom;", 
	"P8O[82],Vibrato,Off,On;",
	"P8-;",
	"P9,PSG2 Settings;",
	"P9-;",
	//"P7O[77:75],Patch,Lead 1,Bass 1,Bell Lead,Custom;", 
	"P9O[83],Vibrato,Off,On;",
	"P9-;",
	"-;",
	"O[16],Echo FM0 to FM1,Off,On;",
	"O[84],Echo PSG0 to PSG1,Off,On;",
	"O[85],Unison FM0 + PSG0,Off,On;",
	"D1D5O[7],Auto-Polyphony (FM),Off,On;",
	"-;",
	"F0,BIN,Load BIOS;",
	"-;",
	"R0,Reset;",
	"J,A,B,X,Y,L,R,Select,Start;",
	"V,v",`BUILD_DATE
};

wire [127:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;
wire [21:0] gamma_bus;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_index;

wire [31:0] joystick_0;
wire [15:0] joystick_l_analog_0;
wire [15:0] joystick_r_analog_0;
wire [10:0] ps2_key;
wire [24:0] ps2_mouse;
wire [15:0] ps2_mouse_ext;
wire [32:0] timestamp;

//blip, echo, auto-duty, vib, cc1>duty, fade speed (4), fade_en, auto-poly, set duty (2)
reg[12:0] lead_patch = 'b0111000011000; //Pulse
reg[12:0] pad_patch  = 'b0000000011101;
reg[12:0] blip_patch = 'b1100010011010;
reg[12:0] leadp2_patch = 'b0011000011000;
reg[12:0] padp2_patch  = 'b0000000011001;
reg[12:0] blipp2_patch = 'b1000010011010;
//fadespeed(4), fade_en, fallspeed(3), fall_en, blip_en, vib, wave(4)
reg[14:0] Wlead_patch = 'b000010000010001; //Wave
reg[14:0] Wkick_patch = 'b010011011000100;
//fadespeed(4), fade_en, fallspeed(3), fall_en, noi_type
reg[9:0] Ndrum_patch = 'b1001101010;
reg[9:0] Ncrash_patch = 'b0100100000;
reg[12:0] patch;
reg patch_set;
reg[2:0] patch_reg;
reg[12:0] patch2;
reg patch2_set;
reg[2:0] patch2_reg;
reg[14:0] patch3;
reg patch3_set;
reg[2:0] patch3_reg;
reg[9:0] patch4;
reg patch4_set;
reg[2:0] patch4_reg;
/*always @ (posedge clk_sys) begin
	//pulse 1
	if (patch_reg != status[21:19]) begin
		patch_reg <= status[21:19];
		case(status[21:19])
			'd0: begin
				patch <= 0;
				patch_set <= 1;
			end
			'd1: begin
				patch <= lead_patch;
				patch2 <= leadp2_patch;
				patch_set <= 1;
			end
			'd2: begin
				patch <= pad_patch;
				patch2 <= pad_patch;
				patch_set <= 1;
			end
			'd3: begin
				patch <= blip_patch;
				patch2 <= blipp2_patch;
				patch_set <= 1;
			end
		endcase
	end
	if (patch_set) patch_set <= 0;
	//pulse 2
	if (patch2_reg != status[38:36]) begin
		patch2_reg <= status[38:36];
		case(status[38:36])
			'd0: begin
				patch2 <= 0;
				patch2_set <= 1;
			end
			'd1: begin
				patch2 <= leadp2_patch;
				patch2_set <= 1;
			end
			'd2: begin
				patch2 <= padp2_patch;
				patch2_set <= 1;
			end
			'd3: begin
				patch2 <= blipp2_patch;
				patch2_set <= 1;
			end
		endcase
	end
	if (patch2_set) patch2_set <= 0;
	//wav
	if (patch3_reg != status[51:49]) begin
		patch3_reg <= status[51:49];
		case(status[51:49])
			'd0: begin
				patch3 <= 0;
				patch3_set <= 1;
			end
			'd1: begin
				patch3 <= Wlead_patch;
				patch3_set <= 1;
			end
			'd2: begin
				patch3 <= Wkick_patch;
				patch3_set <= 1;
			end
		endcase
	end
	if (patch3_set) patch3_set <= 0;
	//noi
	if (patch4_reg != status[71:69]) begin
		patch4_reg <= status[71:69];
		case(status[71:69])
			'd0: begin
				patch4 <= 0;
				patch4_set <= 1;
			end
			'd1: begin
				patch4 <= Ndrum_patch;
				patch4_set <= 1;
			end
			'd2: begin
				patch4 <= Ncrash_patch;
				patch4_set <= 1;
			end
		endcase
	end
	if (patch4_set) patch4_set <= 0;
end*/

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),
	.gamma_bus(),

	.buttons(buttons),
	.status(status),
	.status_in ({status[127:0]}),
	.status_set (patch_set | patch2_set | patch3_set | patch4_set),
					//status[58],status[40],status[68]|status[67],status[7],status[62],status[44],status[25],status[32],status[30],status[16],status[15],status[13],status[8],status[3],status[5]
	.status_menumask({status[58],status[40],status[68]|status[67],status[7],status[62],(status[77:75] != 3'd3),(status[74:72] != 3'd3),(status[71:69] != 3'd3),(status[51:49] != 3'd3),status[16],(status[38:36] != 3'd3),(status[21:19] != 3'd3),status[8],status[3],status[5]}),
	//.status_menumask({direct_video}),
	.forced_scandoubler(forced_scandoubler),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_index(ioctl_index),

	.joystick_0(joystick_0),

	.joystick_l_analog_0(joystick_l_analog_0),

	.joystick_r_analog_0(joystick_r_analog_0),

	.ps2_key(ps2_key),
	.ps2_mouse(ps2_mouse),
	.ps2_mouse_ext(ps2_mouse_ext),

	.TIMESTAMP(timestamp)
);


////////////////////   CLOCKS   ///////////////////
wire clk_sys;
//wire clk_vga; 
pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),
	//.outclk_1(clk_vga)
);

///////////////////   CLOCK DIVIDERS   ////////////////////
reg ce_pix;
always @(posedge clk_sys) begin //clk_vga
	reg [1:0] div4;
	div4 <= div4 + 1'd1;
	ce_pix <= !div4;
end

reg ce_2;
always @(posedge clk_sys) begin
	reg [3:0] div16;
	div16 <= div16 + 1'd1;
	ce_2 <= !div16;
end

reg FM_CLKEN, PSG_CLKEN;

always @(negedge clk_sys) begin
	reg [3:0] FCLKCNT = 0;
	reg [3:0] PCLKCNT = 0;

	FM_CLKEN <= 0;
	FCLKCNT <= FCLKCNT + 1'b1;
	if (FCLKCNT == 6) begin
		FCLKCNT <= 0;
		FM_CLKEN <= 1;
	end

	PSG_CLKEN <= 0;
	PCLKCNT <= PCLKCNT + 1'b1;
	if (PCLKCNT == 14) begin
		PCLKCNT <= 0;
		PSG_CLKEN <= 1;
	end
end

///////////////////   VIDEO   ////////////////////
wire hblank, vblank, hs, vs;
wire [7:0] r, g, b;

wire [23:0] rgb = {r,g,b};
wire rotate_ccw = 0;
wire no_rotate = 1;
wire flip = 0;
wire video_rotated;
screen_rotate screen_rotate (.*);
arcade_video #(320,24) arcade_video
(
	.*,
	.clk_video(clk_sys),
	.RGB_in(rgb),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(hs),
	.VSync(vs),
	.fx(0)//status[5:3])
);

///////////////////   MAIN CORE   ////////////////////
wire rom_download = ioctl_download && (ioctl_index < 8'd2);
wire reset = (RESET | status[0] | rom_download);
assign LED_USER = rom_download;

system system(
	.clk_24(clk_sys),
	//.clk_vga(clk_vga),
	.ce_6(ce_pix),
	.ce_2(ce_2),
	.reset(reset),
	.pause(1'b0),
	//.menu(status[10] || buttons[1]),
	.VGA_HS(hs),
	.VGA_VS(vs),
	.VGA_R(r),
	.VGA_G(g),
	.VGA_B(b),
	.VGA_HB(hblank),
	.VGA_VB(vblank),
	//.dn_addr(ioctl_addr[16:0]),
	//.dn_data(ioctl_dout),
	//.dn_wr(ioctl_wr),
	//.dn_index(ioctl_index),
	.joystick(0),
	.analog_l(poly_note),
	.analog_r(0),
 	.paddle(0),
	.spinner(0),
	.sq1(note),
	.sq2(note2),
	.wave(note3),
	.noise(note4),
	.poly_en(status[7]),
	.timestamp(timestamp),
	.AUDIO_L(0),
	.AUDIO_R(0)
);

//My Clock Divider//
wire ce, ce_2x;
speedcontrol speedcontrol
(
	.clk_sys(clk_sys),
	.ce(ce),
	.ce_2x(ce_2x)
);

//GB Midi//
/*wire [15:0] gb_audio_l;
wire [15:0] gb_audio_r;
wire [10:0] note;
wire [10:0] note2;
wire [10:0] note3;
wire [10:0] note4;
wire[255:0] poly_note;
GBMidi GBMidi
(
	.clk(clk_sys),
	.ce(ce),
	.ce_2x(ce_2x),
	.reset(reset),
	.status(status),

	.joystick_0(joystick_0),

	.midi_data(midi_data),
	.midi_send(midi_send),
	.midi_ready(midi_ready),

	.note_out(note),
	.note_out2(note2),
	.note_out3(note3),
	.note_out4(note4),
	.poly_note_out(poly_note),

	.audio_l(gb_audio_l),
	.audio_r(gb_audio_r)
);

assign AUDIO_L = gb_audio_l;
assign AUDIO_R = gb_audio_r;
assign AUDIO_S = 1;*/

//Genesis Midi//
wire fm0_patch_download = ioctl_download & (ioctl_index[5:0] == 6'h01 || (ioctl_index[7:6] == 1 && ~|ioctl_index));
wire fm1_patch_download = ioctl_download & (ioctl_index[5:0] == 6'h02 || (ioctl_index[7:6] == 1 && ~|ioctl_index));
wire fm2_patch_download = ioctl_download & (ioctl_index[5:0] == 6'h03 || (ioctl_index[7:6] == 1 && ~|ioctl_index));
wire fm3_patch_download = ioctl_download & (ioctl_index[5:0] == 6'h04 || (ioctl_index[7:6] == 1 && ~|ioctl_index));
wire fm4_patch_download = ioctl_download & (ioctl_index[5:0] == 6'h05 || (ioctl_index[7:6] == 1 && ~|ioctl_index));
wire fm5_patch_download = ioctl_download & (ioctl_index[5:0] == 6'h06 || (ioctl_index[7:6] == 1 && ~|ioctl_index));
wire signed [15:0] FM_right;
wire signed [15:0] FM_left;
wire signed [15:0] FM_LPF_right;
wire signed [15:0] FM_LPF_left;
wire signed [15:0] PRE_LPF_L;
wire signed [15:0] PRE_LPF_R;
wire [10:0] note;
wire [10:0] note2;
wire [10:0] note3;
wire [10:0] note4;
wire[255:0] poly_note;
GenMidi GenMidi
(
	.clk(clk_sys),
	.ce(ce),
	.gencen(FM_CLKEN),
	.psgcen(PSG_CLKEN),
	.reset(reset),
	.status(status),

	.joystick_0(joystick_0),

	.midi_data(midi_data),
	.midi_send(midi_send),
	.midi_ready(midi_ready),

	.note_out(note),
	.note_out2(note2),
	.note_out3(note3),
	.note_out4(note4),
	.poly_note_out(poly_note),

	.fm0_patch_download(fm0_patch_download),
	.fm1_patch_download(fm1_patch_download),
	.fm2_patch_download(fm2_patch_download),
	.fm3_patch_download(fm3_patch_download),
	.fm4_patch_download(fm4_patch_download),
	.fm5_patch_download(fm5_patch_download),
	.ioctl_dout(ioctl_dout),
	.ioctl_wr(ioctl_wr),

	.FM_audio_l(FM_left),
	.FM_audio_r(FM_right),
	.PSG_SND(PSG_SND)
);

wire signed [15:0] fm_adjust_l = (FM_left  << 4) + (FM_left  << 2) + (FM_left  << 1) + (FM_left  >>> 2);
wire signed [15:0] fm_adjust_r = (FM_right << 4) + (FM_right << 2) + (FM_right << 1) + (FM_right >>> 2);
wire signed [10:0] PSG_SND;



genesis_fm_lpf fm_lpf_l
(
	.clk(clk_sys),
	.reset(reset),
	.in(fm_adjust_l),
	.out(FM_LPF_left)
);

genesis_fm_lpf fm_lpf_r
(
	.clk(clk_sys),
	.reset(reset),
	.in(fm_adjust_r),
	.out(FM_LPF_right)
);

wire signed [15:0] fm_select_l = (fm_adjust_l);
wire signed [15:0] fm_select_r = (fm_adjust_r);

wire signed [10:0] psg_adjust = PSG_SND - (PSG_SND >>> 5);

jt12_genmix genmix
(
	.rst(reset),
	.clk(clk_sys),
	.fm_left(fm_select_l),
	.fm_right(fm_select_r),
	.psg_snd(psg_adjust),
	.fm_en(1),
	.psg_en(1),
	.snd_left(PRE_LPF_L),
	.snd_right(PRE_LPF_R)
);

wire signed [15:0] DAC_RDATA;
wire signed [15:0] DAC_LDATA;

genesis_lpf lpf_right
(
	.clk(clk_sys),
	.reset(reset),
	.lpf_mode(0), //LPF_MODE[1:0]),
	.in(PRE_LPF_R),
	.out(DAC_RDATA)
);

genesis_lpf lpf_left
(
	.clk(clk_sys),
	.reset(reset),
	.lpf_mode(0), //LPF_MODE[1:0]),
	.in(PRE_LPF_L),
	.out(DAC_LDATA)
);

assign AUDIO_L = DAC_LDATA;
assign AUDIO_R = DAC_RDATA;
assign AUDIO_S = 1;

//Uart

wire uart = status[2]? USER_IN[0]: UART_RXD;
wire[15:0] prescale = 15'd215; //status[15]?15'd134:15'd537; //1718 would be 53.693175Mhz clock/31.25Khz baud
wire[7:0] midi_data;
wire midi_send;
wire midi_ready;

uart_rx #(.DATA_WIDTH(24)) uart_rx //status[15]? 8:
(
	.clk(clk_sys),
	.rst(reset),
	.m_axis_tdata(midi_data),
	.m_axis_tvalid(midi_send),
	.m_axis_tready(midi_ready),
	.rxd(uart),
	.prescale(prescale)
);
endmodule
