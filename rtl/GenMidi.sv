/*============================================================================
	Game Boy Midi Core - GBMidi module

	Aruthor: ModalModule - https://github.com/modalmodule/
	Version: 0.1
	Date: 2024-02-19

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

module GenMidi
(
    input          clk,
    input          ce,
    input          gencen,
	input          psgcen,
    input          reset,
    input  [127:0] status,

    input   [15:0] joystick_0,

    input    [7:0] midi_data,
    input          midi_send, 
    output         midi_ready,

    output  [10:0] note_out0,
    output  [10:0] note_out1,
	output  [10:0] note_out2,
	output  [10:0] note_out3,
	output  [10:0] note_out4,
    output  [10:0] note_out5,
	output  [10:0] note_out6,
	output  [10:0] note_out7,
	output  [10:0] note_out8,
    output  [10:0] note_out9,
    output [255:0] poly_note_out,
	output [6:0] patch_display,

	input fm0_patch_download,
	input fm1_patch_download,
	input fm2_patch_download,
	input fm3_patch_download,
	input fm4_patch_download,
	input fm5_patch_download,
	input p_bank_download,
	input [7:0] ioctl_dout,
	input ioctl_wr,

    // audio
    output  [15:0] FM_audio_l,
    output  [15:0] FM_audio_r,
	output [10:0] PSG_SND

);

assign note_out0 = (note_on_reg[0]<<9) + (note_reg[0]);
assign note_out1 = (note_on_reg[1]<<9) + (note_reg[1]);
assign note_out2 = (note_on_reg[2]<<9) + (note_reg[2]);
assign note_out3 = (note_on_reg[3]<<9) + (note_reg[3]);
assign note_out4 = (note_on_reg[4]<<9) + (note_reg[4]);
assign note_out5 = (note_on_reg[5]<<9) + (note_reg[5]);
assign note_out6 = (note_on_reg[6]<<9) + (note_reg[6]);
assign note_out7 = (note_on_reg[7]<<9) + (note_reg[7]);
assign note_out8 = (note_on_reg[8]<<9) + (note_reg[8]);
assign note_out9 = (note_on_reg[9]<<9) + (note_reg[9]);
assign poly_note_out = poly_note_out_combined[max];
assign patch_display = p_change_reg[0];

//OSD labels
wire auto_poly_set = status[7];
reg auto_poly;
wire gamepadtoNotes = status[3];
wire echo_en = status[16]; //& !status[68:67];
wire psg_echo_en = status[84];
wire unison_en = status[85];
wire[1:0] mchannel1_choice = status[68:67];
reg[3:0] mchannel1_choice_reg;
//pulse 1
wire [2:0] fm0_patch = status[21:19];
//wire duty_switch_en = status[15];
wire vibrato[0:8] = '{status[14] | cc1_reg[0], status[31] | cc1_reg[1], status[56] | cc1_reg[2], status[78] | cc1_reg[3], status[79] | cc1_reg[4], status[80] | cc1_reg[5], status[81] | cc1_reg[6], status[82] | cc1_reg[7], status[83] | cc1_reg[8]};
//wire blip_en = status[17];
wire fade_en[4] = '{status[8], status[25], status[62], status[44]};
wire [3:0] fade_speed[4] = '{status[12:9], status[29:26], status[66:63], status[48:45]};
//pulse 2
wire [2:0] fm1_patch = status[38:36];
wire [2:0] fm2_patch = status[51:49];
wire [2:0] fm3_patch = status[71:69];
wire [2:0] fm4_patch = status[74:72];
wire [2:0] fm5_patch = status[77:75];
wire DACen = status[86];
wire [3:0] DTen [4] = '{0, status[87]<<3, 0, 0};
wire modto = status[88];

///FROM GBMidi
/*wire [1:0] duty_set = status[6:5];
wire modtoDuty = status[13];
wire [1:0] duty_set2 = status[23:22];
wire modtoDuty2 = status[30];
wire duty_switch_en2 = status[32];
wire blip_en2 = status[34];
//wave
wire [3:0] waveform = status[55:52];
wire blip_en3 = status[57];
wire fall2_en = status[58];
wire [2:0] fall2_speed = status[61:59];
//noise
wire noi_type = status[39];
wire fall_en = status[40];
wire [2:0] fall_speed = status[43:41];*/
////


//Midi translator//
wire note_on;
wire note_off;
wire [3:0] mchannel;
wire [6:0] note;
wire [6:0] velocity;
wire cc_send;
wire [6:0] cc;
wire [6:0] cc_val;
wire pb_send;
wire [13:0] pb_val;
wire pc_send;
wire [6:0] pc_val;

midi_trans midi_trans (
	.clk(clk),
	.reset(reset),
	.midi_send(midi_send),
	.midi_data(midi_data),
	.note_on(note_on),
	.note_off(note_off),
	.mchannel(mchannel),
	.note(note),
	.velocity(velocity),
	.cc_send(cc_send),
	.cc(cc),
	.cc_val(cc_val),
	.pb_send(pb_send),
	.pb_val(pb_val),
	.pc_send(pc_send),
	.pc_val(pc_val)
);

//GB SOUND//
reg[10:0] frequencies[0:71] = '{
	11'd44, 11'd156, 11'd262, 11'd363, 11'd457, 11'd547, 11'd631, 11'd710, 11'd786, 11'd854, 11'd923, 11'd986,
  	11'd1046, 11'd1102, 11'd1155, 11'd1205, 11'd1253, 11'd1297, 11'd1339, 11'd1379, 11'd1417, 11'd1452, 11'd1486, 11'd1517,
  	11'd1546, 11'd1575, 11'd1602, 11'd1627, 11'd1650, 11'd1673, 11'd1694, 11'd1714, 11'd1732, 11'd1750, 11'd1767, 11'd1783,
  	11'd1798, 11'd1812, 11'd1825, 11'd1837, 11'd1849, 11'd1860, 11'd1871, 11'd1881, 11'd1890, 11'd1899, 11'd1907, 11'd1915,
  	11'd1923, 11'd1930, 11'd1936, 11'd1943, 11'd1949, 11'd1954, 11'd1959, 11'd1964, 11'd1969, 11'd1974, 11'd1978, 11'd1982,
  	11'd1985, 11'd1988, 11'd1992, 11'd1995, 11'd1998, 11'd2001, 11'd2004, 11'd2006, 11'd2009, 11'd2011, 11'd2013, 11'd2015
};

reg[3:0] wave_bass[0:31] = '{
	4'h8, 4'hF, 4'hF, 4'hE, 4'hD, 4'hC, 4'hA, 4'h9, 4'h8, 4'h6, 4'h5, 4'h4, 4'h2, 4'h1, 4'h0, 4'h0,
	4'h0, 4'h4, 4'hD, 4'hF, 4'hF, 4'hE, 4'hD, 4'hB, 4'hA, 4'h9, 4'h7, 4'h6, 4'h5, 4'h4, 4'h2, 4'h1
};
reg[3:0] wave_lead[0:31] = '{
	4'h8, 4'h8, 4'h8, 4'h8, 4'h4, 4'h4, 4'h5, 4'h3, 4'h1, 4'h0, 4'h2, 4'h6, 4'h6, 4'h8, 4'hB, 4'hE,
	4'hF, 4'hD, 4'hA, 4'h9, 4'h8, 4'h7, 4'h6, 4'h5, 4'h8, 4'hB, 4'hB, 4'hB, 4'hB, 4'hC, 4'hD, 4'h8
};
reg[3:0] wave_triangle[0:31] = '{
	4'h8, 4'h9, 4'hA, 4'hB, 4'hC, 4'hD, 4'hE, 4'hF, 4'hE, 4'hD, 4'hC, 4'hB, 4'hA, 4'h9, 4'h8, 4'h8,
	4'h7, 4'h6, 4'h5, 4'h4, 4'h3, 4'h2, 4'h1, 4'h0, 4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8
};
reg[3:0] wave_saw[0:31] = '{
	4'hE, 4'hC, 4'hD, 4'hC, 4'hC, 4'hB, 4'hB, 4'hB, 4'hA, 4'hA, 4'hA, 4'h9, 4'h9, 4'h8, 4'h8, 4'h8,
	4'h7, 4'h7, 4'h6, 4'h6, 4'h6, 4'h5, 4'h5, 4'h5, 4'h4, 4'h4, 4'h3, 4'h3, 4'h2, 4'h3, 4'h1, 4'h8
};
reg[3:0] wave_square[0:31] = '{
	4'hF, 4'hD, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hE, 4'hD, 4'hF, 4'h8,
	4'h0, 4'h2, 4'h1, 4'h1, 4'h1, 4'h1, 4'h1, 4'h1, 4'h1, 4'h1, 4'h1, 4'h1, 4'h1, 4'h2, 4'h0, 4'h8
};
////

reg[13:0] Genfrequencies[120] = '{
	256, 271, 287, 304, 322, 342, 362, 383, 406, 430, 456, 483, 
	512, 542, 574, 609, 645, 683, 724, 767, 812, 861, 912, 966,
	1024, 1084, 1149, 1217, 1290, 1366, 1447, 1534, 1625, 1721, 1824, 1932, 
	3072, 3132, 3197, 3265, 3338, 3414, 3495, 3582, 3673, 3769, 3872, 3980, 
	5120, 5180, 5245, 5313, 5386, 5462, 5543, 5630, 5721, 5817, 5920, 6028, 
	7168, 7228, 7293, 7361, 7434, 7510, 7591, 7678, 7769, 7865, 7968, 8076, 
	9216, 9276, 9341, 9409, 9482, 9558, 9639, 9726, 9817, 9913, 10016, 10124, 
	11264, 11324, 11389, 11457, 11530, 11606, 11687, 11774, 11865, 11961, 12064, 12172, 
	13312, 13372, 13437, 13505, 13578, 13654, 13735, 13822, 13913, 14009, 14112, 14220, 
	15360, 15420, 15485, 15553, 15626, 15702, 15783, 15870, 15961, 16057, 16160, 16268
};

reg[9:0] PSGfrequencies[0:59] = '{
	1012, 954, 900, 851, 803, 758, 715, 675, 637, 601, 568, 536, 
	506, 477, 450, 426, 402, 379, 358, 338, 318, 300, 284, 268,
	253, 238, 225, 213, 201, 190, 179, 169, 159, 150, 142, 134,
	126, 119, 112, 106, 100, 95, 90, 84, 80, 75, 71, 67,
	63, 60, 56, 53, 50, 48, 45, 42, 40, 38, 36, 34
};

reg[7:0] noisefreqs[6] = '{'hE6, 'hE5, 'hE4, 'hE2, 'hE1, 'hE0};
/*
	algorithm = 0
    feedback = 1

	MUL = 2
	DT1 = 3
	TL = 4   0(loud)-127(muted)
	RS = 5
	AR = 6
	D1R = 7
	D2R = 8
	RR = 9
	D1L = 10
*/

/*reg[7:0] GenPatch[0:3][0:41] = '{ 
	///JLead
	'{
		'h00, 'h04, 
		'h02, 'h03, 'h21, 'h00, 'h1F, 'h02, 'h01, 'h00, 'h02, 'h00,
		'h02, 'h06, 'h1F, 'h00, 'h14, 'h04, 'h03, 'h00, 'h02, 'h00, 
		'h01, 'h04, 'h14, 'h00, 'h1F, 'h03, 'h02, 'h00, 'h02, 'h00, 
		'h01, 'h06, 'h07, 'h00, 'h12, 'h04, 'h03, 'h07, 'h02, 'h00
	},
	///RKA_Bass
	'{
		'h03, 'h07, 
		'h0D, 'h03, 'h22, 'h02, 'h1F, 'h0E, 'h00, 'h0F, 'h0D, 'h00,
		'h00, 'h03, 'h18, 'h00, 'h1F, 'h09, 'h00, 'h07, 'h0D, 'h00, 
		'h01, 'h03, 'h18, 'h00, 'h1F, 'h0D, 'h00, 'h0F, 'h0D, 'h00, 
		'h00, 'h03, 'h08, 'h00, 'h1F, 'h09, 'h00, 'h08, 'h0D, 'h00
	},
	//Bell Lead
	'{
		'h04, 'h05, 
		'h06, 'h02, 'h16, 'h00, 'h1F, 'h05, 'h06, 'h04, 'h0C, 'h00,
		'h06, 'h00, 'h14, 'h00, 'h1F, 'h05, 'h06, 'h04, 'h0D, 'h00, 
		'h02, 'h01, 'h08, 'h00, 'h1F, 'h06, 'h05, 'h07, 'h0C, 'h00, 
		'h02, 'h05, 'h08, 'h00, 'h1F, 'h06, 'h06, 'h07, 'h0C, 'h00
	},
	//Brass
	'{
		'h05, 'h07, 
		'h01, 'h03, 'h13, 'h01, 'h10, 'h0F, 'h04, 'h07, 'h01, 'h00,
		'h03, 'h03, 'h12, 'h01, 'h18, 'h02, 'h00, 'h09, 'h01, 'h00, 
		'h01, 'h03, 'h0A, 'h01, 'h12, 'h02, 'h00, 'h09, 'h00, 'h00, 
		'h01, 'h03, 'h0A, 'h01, 'h19, 'h02, 'h00, 'h09, 'h01, 'h00
	}
};*/

wire [7:0] pb_data_out;
//bit[12:0] pb_in_address;
wire[12:0] pb_in_address = fm0_patch_download? 126 + c_patch_i[0] :
						   fm1_patch_download? 126 + c_patch_i[1] + 42 :
						   fm2_patch_download? 126 + c_patch_i[2] + 84 :
						   fm3_patch_download? 126 + c_patch_i[3] + 126 :
						   fm4_patch_download? 126 + c_patch_i[4] + 168 :
						   fm5_patch_download? 126 + c_patch_i[5] + 210 :
						   p_bank_download? 378 + p_bank_i : 0;
localparam pb_width = 13;
reg[pb_width-1:0] pb_out_address;
wire pb_wr = ioctl_wr && (fm0_patch_download || fm1_patch_download || fm2_patch_download || fm3_patch_download || fm4_patch_download || fm5_patch_download || p_bank_download);
reg[1:0] pb_address_sent;


dpram #(pb_width,8, "init.hex") pbrom
(
	.clock_a(clk),
	.address_a(pb_out_address[pb_width-1:0]),
	.wren_a(1'b0),
	.data_a(),
	.q_a(pb_data_out),

	.clock_b(clk),
	.address_b(pb_in_address[pb_width-1:0]),
	.wren_b(pb_wr),
	.data_b(ioctl_dout),
	.q_b()
); 

localparam sb_width = 15;
wire [7:0] sb_data_out;
reg[sb_width-1:0] sb_out_address;
reg[sb_width-1:0] sb_in_address;
wire sb_wr = 0;

dpram #(sb_width,8, "GenSamples.hex") sbrom
(
	.clock_a(clk),
	.address_a(sb_out_address[sb_width-1:0]),
	.wren_a(1'b0),
	.data_a(),
	.q_a(sb_data_out),

	.clock_b(clk),
	.address_b(sb_in_address[sb_width-1:0]),
	.wren_b(sb_wr),
	.data_b(ioctl_dout),
	.q_b()
); 


reg[6:0] VelLut[0:127] = '{
	122, 117, 112, 108, 104, 99, 95, 92, 88, 84, 81, 78, 75, 72, 
	69, 66, 63, 61, 58, 56, 54, 52, 50, 48, 46, 44, 42, 40, 39, 
	37, 36, 34, 33, 32, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 
	20, 19, 19, 18, 17, 16, 16, 15, 15, 14, 13, 13, 12, 12, 11, 
	11, 11, 10, 10, 9, 9, 9, 8, 8, 8, 7, 7, 7, 6, 6, 6, 6, 5, 5, 
	5, 5, 5, 4, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1
};

reg[2:0] dtTableFMP[7] = '{
  7,6,5,0,1,2,3
};

reg[7:0] sample_speed = 240;
reg[sb_width-1:0] sample_length[0:1] = '{5838, 15104};

reg[2:0] rst_timer = 1; 

wire [7:0] snd_d_out;
reg audio_wr;
reg [1:0] myaddress = 1;
reg [7:0] myvalue;
reg [2:0] myseq[0:5];
reg [13:0] sq1_freq;
reg [10:0] sq2_freq = 11'b11010011110;
reg [10:0] wav_freq = 11'b010100000000;
reg [5:0] noi_freq = 6'b100000;
reg [1:0] sq1_duty;
reg [1:0] sq2_duty;
reg sq1_on;
reg sq2_on;
reg wav_on;
reg noi_on;
reg sq1_sent = 1;
reg sq2_sent = 1;
reg wav_sent = 1;
reg noi_sent = 1;
reg sq1_duty_sent = 1;
reg sq2_duty_sent = 1;
reg wav_ram_sent;
reg wav_ram_start;
reg wav_ram_end;
reg[3:0] wav_ram_init;
reg[5:0] wav_ram_count;
reg wav_dac_en;
reg sq1_trig = 1;
reg sq2_trig = 1;
reg wav_trig = 1;
reg noi_trig = 1;
reg [10:0] freq_temp;
reg [13:0] sq1_freq_pb;
reg [10:0] sq2_freq_pb;
reg [10:0] wav_freq_pb;
reg[3:0] waveform_reg;
reg mono_kill;


//POLY
localparam int max = 3; //Max instances of gbc_snd
/*reg audio_wrP[0:max-1];
reg [6:0] myaddressP[0:max-1];
reg [7:0] myvalueP[0:max-1];
reg [2:0] myseqP[0:max-1];
reg [10:0] sq1_freqP[0:max-1];
reg [10:0] sq2_freqP[0:max-1];
reg [1:0] sq1_dutyP[0:max-1];
reg [1:0] sq2_dutyP[0:max-1];
reg sq1_onP[0:max-1];
reg sq2_onP[0:max-1];
reg sq1_sentP[0:max-1];
reg sq2_sentP[0:max-1];
reg sq1_duty_sentP[0:max-1];
reg sq2_duty_sentP[0:max-1];
reg Pinit;
reg sq1_trigP[0:max-1];
reg sq2_trigP[0:max-1];
reg [10:0] sq1_freq_pbP[0:max-1];
reg [10:0] sq2_freq_pbP[0:max-1];*/
reg poly_kill;

//GAMEPAD
reg [3:0] last_joy = 8;

//MIDI REGS
localparam int sq1_channel = 0; // midi channel for pulse 1, 0 = channel 1
localparam int sq2_channel = 1; // midi channel for pulse 2, 1 = channel 2
localparam int wav_channel = 2;
localparam int noi_channel = 3;
reg note_on_reg[0:9];
reg [6:0] note_reg[0:9];
reg [6:0] old_note_reg[0:9];
reg repeat_note[0:9];
reg [6:0] velocity_reg[0:9];
reg [6:0] old_velocity_reg[0:9];
reg sustain[0:9];
reg note_sus_on[0:9];
reg [1:0] cc1_reg[0:8];
reg [6:0] cc1mod_reg[0:5];
reg [6:0] old_mod_reg[0:5];
reg [8:0] pb_reg[0:9];
reg [8:0] pb_old_reg[0:9];
reg [3:0] pb_count[0:9];
reg [13:0] pb_lookup[0:5];
localparam int pb_div = 128; //pitch bend values divide a half step by 128
reg [3:0] mchan_pl_choice;

reg [6:0] note_tmp;
reg [6:0] velocity_tmp;
reg [3:0] channel_tmp;

//POLY for GBMidi
/*reg poly_note_on_reg[0:15][0:max+max-1];
reg poly_repeat_note[0:15][0:max+max-1];
reg [6:0] poly_note_reg[0:15][0:max+max-1];
reg [3:0] poly_velocity_reg[0:15][0:max+max-1];
reg poly_note_sus_on[0:15][0:max+max-1];*/
reg [4:0] poly_max_voice = max+max-'b1;
reg [4:0] poly_replace;
reg [4:0] poly_cvoice;
reg vfound = 1;
//reg [13:0] poly_pb_lookup[0:15][0:max+max-1];
//reg [max-1:0] poly_reset;

reg midi_ready_reg = 1;
assign midi_ready = midi_ready_reg;
reg[10:0] init_patch_sent[0:5];
reg patch_sent[0:5];
reg[6:0] patch_index[0:5];
reg[1:0] opoffset[0:5];
reg[7:0] genready;
reg[2:0] patch_sel_reg[0:5];
reg vel_sent[0:5];
reg car2[0:5];
reg[1:0] car3[0:5];
reg[1:0] car4[0:5];

reg mod_sent[0:5];
reg[1:0] mod2[0:5];
reg[1:0] mod3[0:5];

reg fm_trig[0:5];
reg fm_sent[0:5];
reg fm_on[0:5];
reg[13:0] fm_freq[0:5];
reg[13:0] fm_freq_pb[0:5];
reg[3:0] i;
reg send_custom_patch[0:5];
reg c_patch_sent[0:5] = '{1,1,1,1,1,1};
reg[6:0] c_patch_i[0:5];
reg[7:0] c_offset[0:5];
reg[6:0] p_change_reg[0:5];
reg send_p_change[0:5];
reg[12:0] p_bank_i;
reg[1:0] pan_reg[0:5] = '{2'b11, 2'b11, 2'b11, 2'b11, 2'b11, 2'b11};
reg[1:0] old_pan_reg[0:5] = '{2'b11, 2'b11, 2'b11, 2'b11, 2'b11, 2'b11};
reg pan_sent[0:5];

reg psg_sent[0:3];
reg psg_on[0:3];
reg[9:0] psg_freq[0:3];
reg[9:0] psg_freq_pb[0:2];
reg[1:0] psg_i;
reg [13:0] psg_pb_lookup[0:2];
reg [7:0] psgvalue;
reg [1:0] psgseq[0:3];
reg psg_wr;
reg psgnotrig[0:3];

reg[7:0] ActivePatch[252];
reg a_patch_upd[0:5];
reg[5:0] a_patch_i[0:5];

//bit[11:0] p_address;
localparam vib_depth = 20;

reg DACen_reg;
reg DACen_sent = 1;
reg DACen_seq;
reg DAC_seq;
reg[7:0] sample_tick;
reg tick_hold = 1;
reg[sb_width-1:0] sample_i;
reg sample_sent = 1;
reg sample_on;
reg[1:0] sample_c;

reg[6:0] gamepad_p_change;
reg r_hold;
reg l_hold;

localparam noteoffset = 4;
localparam psgnoteoffset = 45;

reg[2:0] osd_patch_override[6];

//int i;
always @ (posedge clk) begin
	if (joystick_0[9]) begin
		if (!r_hold) begin
			gamepad_p_change = gamepad_p_change + 1;
			r_hold <= 1;
			p_change_reg[0] <= gamepad_p_change;
			send_p_change[0] <= 1;
		end
	end
	else r_hold <= 0;
	if (joystick_0[8]) begin
		if (!l_hold) begin
			gamepad_p_change = gamepad_p_change - 1;
			l_hold <= 1;
			p_change_reg[0] <= gamepad_p_change;
			send_p_change[0] <= 1;
		end
	end
	else l_hold <= 0;

	if (DACen_reg != DACen) begin
		DACen_sent <= 0;
		patch_sent[5] <= 1;
		vel_sent[5] <= 1;
		fm_sent[5] <= 1;
		DACen_seq <= 0;
		DACen_reg <= DACen;
	end
	if (!fm0_patch_download) begin
		c_patch_i[0] <= 0;
		if (!c_patch_sent[0]) begin
			send_custom_patch[0] <= 1;
			c_patch_sent[0] <= 1;
		end
	end
	if (!fm1_patch_download) begin
		c_patch_i[1] <= 0;
		if (!c_patch_sent[1]) begin
			send_custom_patch[1] <= 1;
			c_patch_sent[1] <= 1;
		end
	end
	if (!fm2_patch_download) begin
		c_patch_i[2] <= 0;
		if (!c_patch_sent[2]) begin
			send_custom_patch[2] <= 1;
			c_patch_sent[2] <= 1;
		end
	end
	if (!fm3_patch_download) begin
		c_patch_i[3] <= 0;
		if (!c_patch_sent[3]) begin
			send_custom_patch[3] <= 1;
			c_patch_sent[3] <= 1;
		end
	end
	if (!fm4_patch_download) begin
		c_patch_i[4] <= 0;
		if (!c_patch_sent[4]) begin
			send_custom_patch[4] <= 1;
			c_patch_sent[4] <= 1;
		end
	end
	if (!fm5_patch_download) begin
		c_patch_i[5] <= 0;
		if (!c_patch_sent[5]) begin
			send_custom_patch[5] <= 1;
			c_patch_sent[5] <= 1;
		end
	end
	if (!p_bank_download) begin
		p_bank_i <= 0;
	end
	if (p_change_reg[0] && osd_patch_override[0] != fm0_patch) begin
		p_change_reg[0] <= 0;
		gamepad_p_change = 0;
	end
	if (!auto_poly) begin
			if (p_change_reg[1] && osd_patch_override[1] != fm1_patch) begin
				p_change_reg[1] <= 0;
			end
			if (p_change_reg[2] && osd_patch_override[2] != fm2_patch) begin
				p_change_reg[2] <= 0;
			end
			if (p_change_reg[3] && osd_patch_override[3] != fm3_patch) begin
				p_change_reg[3] <= 0;
			end
			if (p_change_reg[4] && osd_patch_override[4] != fm4_patch) begin
				p_change_reg[4] <= 0;
			end
			if (p_change_reg[5] && osd_patch_override[5] != fm5_patch) begin
				p_change_reg[5] <= 0;
			end
			if ((patch_sel_reg[0] != fm0_patch && !p_change_reg[0]) || send_custom_patch[0] || send_p_change[0]) begin
				patch_sent[0] <= 0;
				patch_index[0] <= 0;
				myaddress <= 1;
				opoffset[0] <= 0;
				patch_sel_reg[0] <= fm0_patch;
				if (!p_change_reg[0]) osd_patch_override[0] <= fm0_patch;
				a_patch_upd[0] <= 0;
				a_patch_i[0] <= 0;
				send_p_change[0] <= 0;
				if (send_custom_patch[0]) begin
					send_custom_patch[0] <= 0;
					c_offset[0] <= 0; 
				end
				else c_offset[0] <= 0; 
			end
			if (!echo_en && ((patch_sel_reg[1] != fm1_patch && !p_change_reg[1]) || send_custom_patch[1] || send_p_change[1])) begin
				patch_sent[1] <= 0;
				patch_index[1] <= 0;
				myaddress <= 1;
				opoffset[1] <= 0;
				patch_sel_reg[1] <= fm1_patch;
				if (!p_change_reg[1]) osd_patch_override[1] <= fm1_patch;
				a_patch_upd[1] <= 0;
				a_patch_i[1] <= 0;
				send_p_change[1] <= 0;
				if (send_custom_patch[1]) begin
					send_custom_patch[1] <= 0;
					c_offset[1] <= 42; 
				end
				else c_offset[1] <= 0; 
			end
			if ((patch_sel_reg[2] != fm2_patch && !p_change_reg[2]) || send_custom_patch[2] || send_p_change[2]) begin
				patch_sent[2] <= 0;
				patch_index[2] <= 0;
				myaddress <= 1;
				opoffset[2] <= 0;
				patch_sel_reg[2] <= fm2_patch;
				if (!p_change_reg[2]) osd_patch_override[2] <= fm2_patch;
				a_patch_upd[2] <= 0;
				a_patch_i[2] <= 0;
				send_p_change[2] <= 0;
				if (send_custom_patch[2]) begin
					send_custom_patch[2] <= 0;
					c_offset[2] <= 84; 
				end
				else c_offset[2] <= 0; 
			end
			if ((patch_sel_reg[3] != fm3_patch && !p_change_reg[3]) || send_custom_patch[3] || send_p_change[3]) begin
				patch_sent[3] <= 0;
				patch_index[3] <= 0;
				myaddress <= 3;
				opoffset[3] <= 0;
				patch_sel_reg[3] <= fm3_patch;
				if (!p_change_reg[3]) osd_patch_override[3] <= fm3_patch;
				a_patch_upd[3] <= 0;
				a_patch_i[3] <= 0;
				send_p_change[3] <= 0;
				if (send_custom_patch[3]) begin
					send_custom_patch[3] <= 0;
					c_offset[3] <= 126; 
				end
				else c_offset[3] <= 0; 
			end
			if ((patch_sel_reg[4] != fm4_patch && !p_change_reg[4]) || send_custom_patch[4] || send_p_change[4]) begin
				patch_sent[4] <= 0;
				patch_index[4] <= 0;
				myaddress <= 3;
				opoffset[4] <= 0;
				patch_sel_reg[4] <= fm4_patch;
				if (!p_change_reg[4]) osd_patch_override[4] <= fm4_patch;
				a_patch_upd[4] <= 0;
				a_patch_i[4] <= 0;
				send_p_change[4] <= 0;
				if (send_custom_patch[4]) begin
					send_custom_patch[4] <= 0;
					c_offset[4] <= 168; 
				end
				else c_offset[4] <= 0; 
			end
			if ((patch_sel_reg[5] != fm5_patch && !p_change_reg[5]) || send_custom_patch[5] || send_p_change[5]) begin
				patch_sent[5] <= 0;
				patch_index[5] <= 0;
				myaddress <= 3;
				opoffset[5] <= 0;
				patch_sel_reg[5] <= fm5_patch;
				if (!p_change_reg[5]) osd_patch_override[5] <= fm5_patch;
				a_patch_upd[5] <= 0;
				a_patch_i[5] <= 0;
				send_p_change[5] <= 0;
				if (send_custom_patch[5]) begin
					send_custom_patch[5] <= 0;
					c_offset[5] <= 210; 
				end
				else c_offset[5] <= 0; 
			end
			if (echo_en && (patch_sel_reg[1] != fm0_patch || send_custom_patch[0] || send_p_change[0])) begin
				c_offset[1] <= 0;
				patch_sent[1] <= 0;
				patch_index[1] <= 0;
				myaddress <= 1;
				opoffset[1] <= 0;
				patch_sel_reg[1] <= fm0_patch;
				if (!p_change_reg[1]) osd_patch_override[1] <= fm0_patch;
				p_change_reg[1] <= p_change_reg[0];
				a_patch_upd[1] <= 0;
				a_patch_i[1] <= 0;
			end
	end
	else if (patch_sel_reg[0] != fm0_patch || patch_sel_reg[1] != fm0_patch || patch_sel_reg[2] != fm0_patch || patch_sel_reg[3] != fm0_patch || patch_sel_reg[4] != fm0_patch || patch_sel_reg[5] != fm0_patch || send_custom_patch[0] || send_p_change[0]) begin
		for (int ii = 0; ii < 6; ii = ii + 1) begin
			c_offset[ii] <= 0; 
			patch_sent[ii] <= 0;
			patch_index[ii] <= 0;
			opoffset[ii] <= 0;
			patch_sel_reg[ii] <= fm0_patch;
			p_change_reg[ii] <= p_change_reg[0];
			a_patch_upd[ii] <= 0;
			a_patch_i[ii] <= 0;
		end
		myaddress <= 1;
		send_custom_patch[0] <= 0;
		send_p_change[0] <= 0;
		if (!p_change_reg[0]) osd_patch_override[0] <= fm0_patch;
	end

	///Update Active Patch///
	if (!a_patch_upd[i]) begin
		if (a_patch_i[i] < 42) begin
			if (pb_address_sent < 2) begin
				if (!pb_address_sent) pb_out_address = (p_change_reg[i]? (378+((p_change_reg[i]-1)*42)) : ((patch_sel_reg[i]*42)+c_offset[i])) +a_patch_i[i];
				pb_address_sent <= pb_address_sent + 1;
			end
			else begin
				ActivePatch[(i*42)+a_patch_i[i]] <= pb_data_out; 
				a_patch_i[i] <= a_patch_i[i] + 1;
				pb_address_sent <= 0;
			end
		end
		else a_patch_upd[i] <= 1;
	end

	if (ioctl_wr) begin
		if (fm0_patch_download) begin
			c_patch_i[0] <= c_patch_i[0] + 1;
			c_patch_sent[0] <= 0;
		end
		if (fm1_patch_download) begin
			c_patch_i[1] <= c_patch_i[1] + 1;
			c_patch_sent[1] <= 0;
		end
		if (fm2_patch_download) begin
			c_patch_i[2] <= c_patch_i[2] + 1;
			c_patch_sent[2] <= 0;
		end
		if (fm3_patch_download) begin
			c_patch_i[3] <= c_patch_i[3] + 1;
			c_patch_sent[3] <= 0;
		end
		if (fm4_patch_download) begin
			c_patch_i[4] <= c_patch_i[4] + 1;
			c_patch_sent[4] <= 0;
		end
		if (fm5_patch_download) begin
			c_patch_i[5] <= c_patch_i[5] + 1;
			c_patch_sent[5] <= 0;
		end
		if (p_bank_download) begin
			p_bank_i <= p_bank_i + 1;
		end
	end

	if (reset) begin
    	myaddress <= 7'b0000000;
    	myvalue   <= 8'b00000000;
		audio_wr <= 0;
		//myaddress <= 0;
		myvalue <= 0;
		//myseq <= 3'b000;
		sq1_freq <= 11'b11010011110;
		sq2_freq <= 11'b11010011110;
		sq1_on <= 0;
		sq2_on <= 0;
		sq1_sent <= 1;
		sq2_sent <= 1;
		/*for (i = 0; i < 4; i= i + 1) begin
			note_on_reg[i] <= 0;
			note_reg[i] <= 0;
			velocity_reg[i] <= 0;
		end*/
		midi_ready_reg <= 1;
	end
	/*if (!Pinit) begin
		for (int ii = 0; ii < max; ii = ii + 1) begin
			sq1_sentP[ii] <= 1;
			sq2_sentP[ii] <= 1;
			sq1_duty_sentP[ii] <= 1;
			sq2_duty_sentP[ii] <= 1;
		end
		note_reg[sq1_channel] <= 'd60;
	end
	if (sq1_sentP[max-1] == 1) Pinit <= 1;*/
	if (!auto_poly) begin
		if (!gamepadtoNotes) begin    ///VOICE PER CHANNEL///
			//if (mchannel < 4) begin
				/*if (mchannel1_choice_reg != mchannel1_choice) begin
					note_on_reg[sq1_channel] <= 0;
					note_on_reg[sq2_channel] <= 0;
					note_on_reg[wav_channel] <= 0;
					note_on_reg[noi_channel] <= 0;
					if (!sq1_on && !sq2_on && !wav_on && !noi_on && sq1_sent && sq2_sent && wav_sent && noi_sent) begin
						mchannel1_choice_reg <= mchannel1_choice;
					end
				end
				else*/ begin
					if (!mchannel) begin
						case(mchannel1_choice)
							0 : mchan_pl_choice <= 0;
							1 : mchan_pl_choice <= 5;
							2 : mchan_pl_choice <= 6;
							3 : mchan_pl_choice <= 9;
						endcase
					end
					else mchan_pl_choice <= mchannel1_choice + mchannel;
					if (note_on || note_off) begin
						if (note_on) begin
							note_on_reg[mchan_pl_choice] <= 1;
							note_reg[mchan_pl_choice] <= note;
							velocity_reg[mchan_pl_choice] <= velocity;//>>3;
							note_sus_on[mchan_pl_choice] <= 0;	
						end
						if (note_off && note_reg[mchan_pl_choice] == note) begin
							if (!sustain[mchan_pl_choice]) begin
								note_on_reg[mchan_pl_choice] <= 0;
							end
							else note_sus_on[mchan_pl_choice] <= 1;
						end
					end
					else if (cc_send) begin
						if (cc == 'd64) begin
							if (cc_val >= 'd64) sustain[mchan_pl_choice] <= 1;
							else if (sustain[mchan_pl_choice]) begin
								sustain[mchan_pl_choice] <= 0;
								if (note_sus_on[mchan_pl_choice]) begin
									note_sus_on[mchan_pl_choice] <= 0;
									note_on_reg[mchan_pl_choice] <= 0;
								end
							end
						end
						if (cc == 'd1) begin		// && modtoDuty
							if (!modto) begin
								if (cc_val < 43) cc1_reg[mchan_pl_choice] <= 'd0;
								else if (cc_val < 86) cc1_reg[mchan_pl_choice] <= 'd1;
								else cc1_reg[mchan_pl_choice] <= 'd1;
							end
							else cc1mod_reg[mchan_pl_choice] <= cc_val;
						end
						if (cc == 'd2) begin
							cc1mod_reg[mchan_pl_choice] <= cc_val;
						end
						if (cc == 10) begin
							if (cc_val < 43) pan_reg[mchan_pl_choice] <= 2'b10;
							else if (cc_val < 86) pan_reg[mchan_pl_choice] <= 2'b11;
							else pan_reg[mchan_pl_choice] <= 2'b01;
						end
					end
					else if (pc_send) begin
						p_change_reg[mchan_pl_choice] <= pc_val;
						send_p_change[mchan_pl_choice] <= 1;
					end
					else if (pb_send) begin
						pb_count[mchan_pl_choice] <= pb_count[mchan_pl_choice] + 'b1;
						pb_reg[mchan_pl_choice] <= pb_val>>5;
					end
				end
			//end
			if (auto_poly != auto_poly_set) begin
				/*note_on_reg[0] <= 0;
				note_on_reg[1] <= 0;
				note_on_reg[2] <= 0;
				note_on_reg[3] <= 0;
				note_on_reg[4] <= 0;
				note_on_reg[5] <= 0;
				mono_kill <= 1;
				if (!fm_on[0] && !fm_on[1] && !fm_on[2] && !fm_on[3] && !fm_on[4] && !fm_on[5] && fm_sent[0] && fm_sent[1] && fm_sent[2] && fm_sent[3] && fm_sent[4] && fm_sent[5]) begin
				*/	auto_poly <= auto_poly_set;
					//poly_reset <= 0;
					//mono_kill <= 0;
				//end
			end
		end
		else begin
			case(mchannel1_choice)
				0 : mchan_pl_choice <= 0;
				1 : mchan_pl_choice <= 5;
				2 : mchan_pl_choice <= 6;
				3 : mchan_pl_choice <= 9;
			endcase
			if (joystick_0) begin
				if (!joystick_0[last_joy]) begin
					note_on_reg[mchan_pl_choice] <= 1;
					if (joystick_0[0]) begin
						if (!DACen || mchan_pl_choice != 5) note_reg[mchan_pl_choice] <= 60;
						else note_reg[mchan_pl_choice] <= 36;
						last_joy <= 0;
					end
					else if (joystick_0[1]) begin
						if (!DACen || mchan_pl_choice != 5) note_reg[mchan_pl_choice] <= 62;
						else note_reg[mchan_pl_choice] <= 38;
						last_joy <= 1;
					end
					else if (joystick_0[2]) begin
						if (!DACen || mchan_pl_choice != 5) note_reg[mchan_pl_choice] <= 63;
						else note_reg[mchan_pl_choice] <= 36;
						last_joy <= 2;
					end
					else if (joystick_0[3]) begin
						if (!DACen || mchan_pl_choice != 5) note_reg[mchan_pl_choice] <= 65;
						else note_reg[mchan_pl_choice] <= 38;
						last_joy <= 3;
					end
					else if (joystick_0[4]) begin
						if (!DACen || mchan_pl_choice != 5) note_reg[mchan_pl_choice] <= 67;
						else note_reg[mchan_pl_choice] <= 36;
						last_joy <= 4;
					end
					else if (joystick_0[5]) begin
						if (!DACen || mchan_pl_choice != 5) note_reg[mchan_pl_choice] <= 68;
						else note_reg[mchan_pl_choice] <= 38;
						last_joy <= 5;
					end
					else if (joystick_0[6]) begin
						if (!DACen || mchan_pl_choice != 5) note_reg[mchan_pl_choice] <= 70;
						else note_reg[mchan_pl_choice] <= 36;
						last_joy <= 6;
					end
					else if (joystick_0[7]) begin
						if (!DACen || mchan_pl_choice != 5) note_reg[mchan_pl_choice] <= 72;
						else note_reg[mchan_pl_choice] <= 38;
						last_joy <= 7;
					end
					velocity_reg[mchan_pl_choice] <= 100;
				end
			end
			else begin
				note_on_reg[mchan_pl_choice] <= 0;
				last_joy <= 8;
			end
		end
	end
	else begin ////////POLY/////
		if (poly_replace > poly_max_voice) poly_replace <= 0;
		if (poly_cvoice) begin
			note_on_reg[poly_cvoice-'b1] <= 1;
			note_reg[poly_cvoice-'b1] <= note_tmp;
			velocity_reg[poly_cvoice-'b1] <= velocity_tmp;//>>3;
			poly_cvoice <= 0;
		end
		else if (!vfound) begin
			note_on_reg[poly_replace] <= 1;
			note_reg[poly_replace] <= note_tmp;
			velocity_reg[poly_replace] <= velocity_tmp;//>>3;
			poly_replace <= poly_replace + 1'b1;
			vfound <= 1;
			note_sus_on[poly_replace] <= 0;
		end
		if (note_on || note_off) begin
			if (note_on) begin
				vfound <= 0;
				note_tmp <= note;
				velocity_tmp <= velocity;
				channel_tmp <= mchannel;
				for (int ii = 0; ii < max+max; ii = ii + 1) begin: vcheck
					if (note_reg[ii] == note && note_on_reg[ii]) begin
						poly_cvoice <= ii + 'b1;
						vfound <= 1;
						note_sus_on[ii] <= 0;
						repeat_note[ii] <= 1;
						disable vcheck;
					end
					else if (note_on_reg[ii] == 0) begin
						poly_cvoice <= ii + 'b1;
						vfound <= 1;
						note_sus_on[ii] <= 0;
						disable vcheck;
					end
				end

			end
			if (note_off) begin
				for (int ii = 0; ii < max+max; ii = ii + 1) begin: ncheck
					if (note_reg[ii] == note) begin
						if (!sustain[mchannel]) begin
							note_on_reg[ii] <= 0;
							poly_replace <= ii;
						end
						else note_sus_on[ii] <= 1;
					end
					disable ncheck;
				end
			end
		end
		else if (cc_send) begin
			if (cc == 'd64) begin
				if (cc_val >= 'd64) sustain[mchannel] <= 1;
				else if (sustain[mchannel]) begin
					sustain[mchannel] <= 0;
					for (int ii = 0; ii < max+max; ii = ii + 1) begin
						if (note_sus_on[ii]) begin
							note_sus_on[ii] <= 0;
							note_on_reg[ii] <= 0;
						end
					end
				end
			end
			if (cc == 'd1) begin  //&& modtoDuty
				if (!modto) begin
					if (cc_val < 43) cc1_reg[0] <= 'd0;
					else if (cc_val < 86) cc1_reg[0] <= 'd1;
					else cc1_reg[0] <= 'd1;
				end
				else cc1mod_reg[0] <= cc_val;
			end
		end
		else if (pb_send) begin
			pb_count[0] <= pb_count[0] + 'b1;
			pb_reg[0] <= pb_val>>5;
		end
		if (auto_poly != auto_poly_set) begin
			//wav_dac_en <= 1;
			//wav_sent <= 0;
			//if (poly_reset != 'b1111) begin
				/*poly_kill <= 1;
				for (int ii = 0; ii < max; ii = ii + 1) begin
					note_on_reg[ii+ii] <= 0;
					note_on_reg[ii+ii+1] <= 0;
					if (!sq1_onP[ii] && !sq2_onP[ii] && sq1_sentP[ii] && sq2_sentP[ii]) begin
						poly_reset[ii] <= 1'b1;
					end
				end
			//end
			else begin
				poly_reset <= 0;
				poly_kill <= 0;*/
				auto_poly <= auto_poly_set;
			//end
		end
		for (int ii = 1; ii < 6; ii = ii + 1) begin
			pb_count[ii] <= pb_count[0];
			pb_reg[ii] <= pb_reg[0];
			cc1_reg[ii] <= cc1_reg[0];
			cc1mod_reg[ii] <= cc1mod_reg[0];
		end
	end

	if (gencen) begin
		///VOICE PER CHANNEL///
			/// FM ///
			for (int ii = 0; ii < 6; ii = ii + 1) begin
				if (!DACen || ii < 5) begin
					if (note_on_reg[ii]) begin
						if (!fm_on[ii]) begin
							if (init_patch_sent[ii] < 1) begin
								if (init_patch_sent[0]+init_patch_sent[1]+init_patch_sent[2]+init_patch_sent[3]+init_patch_sent[4]+init_patch_sent[5] == 0) rst_timer <= 1;
								patch_sent[ii] <= 0;
								patch_index[ii] <= 0;
								opoffset[ii] <= 0;
								a_patch_upd[ii] <= 0;
								a_patch_i[ii] <= 0;
								init_patch_sent[ii] <= init_patch_sent[ii] + 1;
								myaddress <= 1;
							end
							if (pb_count[ii]) begin
								pb_lookup[ii] <= ((note_reg[ii]+noteoffset-2)<<7)+pb_reg[ii];
								fm_freq[ii] <= fm_freq_pb[ii];
								pb_count[ii] <= 'b1;
								pb_old_reg[ii] <= pb_reg[ii];
							end
							else fm_freq[ii] <= Genfrequencies[note_reg[ii]+noteoffset];
							fm_on[ii] <= 1;
							fm_sent[ii] <= 0;
							myseq[ii] <= 'd0;
							fm_trig[ii] <= 1;
							old_note_reg[ii] <= note_reg[ii];
						end
						else if (pb_count[ii]) begin
								pb_lookup[ii] <= ((note_reg[ii]+noteoffset-2)<<7)+pb_reg[ii]+(vibrato[ii]?(vib[ii]-vib_depth):0);
								if (fm_freq[ii] != fm_freq_pb[ii]) begin
									fm_freq[ii] <= fm_freq_pb[ii];
									fm_sent[ii] <= 0;
									myseq[ii] <= 'd0;
									if (old_note_reg[ii] != note_reg[ii]) begin
										fm_trig[ii] <= 1;
										old_note_reg[ii] <= note_reg[ii];
									end
									else if (fm_sent[ii]) fm_trig[ii] <= 0;
								end
							pb_count[ii] <= 'b1;
						end
						else if (vibrato[ii]) begin
							pb_lookup[ii] <= ((note_reg[ii]+noteoffset)<<7)+(vib[ii]-vib_depth);
							if (fm_freq[ii] != fm_freq_pb[ii]) begin
								fm_freq[ii] <= fm_freq_pb[ii];
								fm_sent[ii] <= 0;
								myseq[ii] <= 'd0;
								if (old_note_reg[ii] != note_reg[ii]) begin
									fm_trig[ii] <= 1;
									old_note_reg[ii] <= note_reg[ii];
								end
								else if (fm_sent[ii]) fm_trig[ii] <= 0;
							end
						end
						else if (fm_freq[ii] != Genfrequencies[note_reg[ii]+noteoffset]) begin
							fm_freq[ii] <= Genfrequencies[note_reg[ii]+noteoffset];
							fm_sent[ii] <= 0;
							myseq[ii] <= 'd0;
							if (old_note_reg[ii] != note_reg[ii]) begin
								fm_trig[ii] <= 1;
							old_note_reg[ii] <= note_reg[ii];
							end
							else fm_trig[ii] <= 0;
						end
						if (old_velocity_reg[ii] != velocity_reg[ii]) begin
							old_velocity_reg[ii] <= velocity_reg[ii];
							vel_sent[ii] <= 0;
							car2[ii] <= 0;
							car3[ii] <= 0;
							car4[ii] <= 0;
							myaddress <= 1;
						end
						if (old_mod_reg[ii] != cc1mod_reg[ii]) begin
							old_mod_reg[ii] <= cc1mod_reg[ii];
							mod_sent[ii] <= 0;
							mod2[ii] <= 0;
							mod3[ii] <= 0;
							myaddress <= 1;
						end
						if (old_pan_reg[ii] != pan_reg[ii]) begin
							old_pan_reg[ii] <= pan_reg[ii];
							pan_sent[ii] <= 0;
							myaddress <= 1;
						end
						if (repeat_note[ii]) begin
							fm_sent[ii] <= 0;
							myseq[ii] <= 'd0;
							fm_trig[ii] <= 1;
							repeat_note[ii] <= 0;
						end
					end
					else begin
						if (fm_on[ii]) begin
							fm_on[ii] <= 0;
							fm_sent[ii] <= 0;
							myseq[ii] <= 'd0;
							fm_trig[ii] <= 1;
						end
					end
				end
			end

			if (DACen) begin
				if (note_on_reg[5]) begin
					if (!sample_on) begin
						sample_c <= (note_reg[5] < 37? 0: 1);
						DAC_seq <= 0;
						sample_tick <= sample_speed - 2;
						sample_i <= 0;
						tick_hold <= 0;
						sample_sent <= 0;
						sample_on <= 1;
					end
				end
				else sample_on <= 0;
			end


			/// FM1 Echo from FM0
			if (echo_en) begin
				note_on_reg[1] <= echo_note_on_reg;
				note_reg[1] <= echo_note_reg;
				velocity_reg[1] <= echo_velocity_reg;
				cc1_reg[1] <= echo_cc1_reg;
				cc1mod_reg[1] <= echo_cc1mod_reg;
				if (echo_pb_reg) begin
					if (!pb_count[1]) pb_count[1] <= pb_count[1] + 'b1;
					pb_reg[1] <= echo_pb_reg;
				end
				if (pb_count[1]) pb_reg[1] <= echo_pb_reg;
			end

			/// PSG0 Unison from FM0
			if (unison_en) begin
				note_on_reg[6] <= note_on_reg[0];
				note_reg[6] <= note_reg[0];
				if (!fade_en[0] | !note_on_reg[6]) velocity_reg[6] <= velocity_reg[0];
				cc1_reg[6] <= cc1_reg[0];
				if (pb_reg[0]) begin
					pb_count[6] <= pb_count[6] + 'b1;
					pb_reg[6] <= pb_reg[0];
				end
				if (pb_count[6]) pb_reg[6] <= pb_reg[0];
			end
			

			//// PSG ///
			for (int ii = 6; ii < 10; ii = ii + 1) begin
				if (note_on_reg[ii]) begin
					if (!psg_on[ii-6]) begin
						if (pb_count[ii] && ii < 9) begin
							psg_pb_lookup[ii-6] <= ((note_reg[ii]+psgnoteoffset-2)<<7)+pb_reg[ii]-DTen[ii-6]; 
							psg_freq[ii-6] <= psg_freq_pb[ii-6];
							pb_count[ii] <= 'b1;
							pb_old_reg[ii] <= pb_reg[ii];
						end
						else psg_freq[ii-6] <= PSGfrequencies[note_reg[ii]-psgnoteoffset];
						psg_on[ii-6] <= 1;
						psg_sent[ii-6] <= 0;
						psgseq[ii-6] <= 'd0;
					end
					else begin
						if (ii < 9) begin
							if (pb_count[ii]) begin
									psg_pb_lookup[ii-6] <= ((note_reg[ii]-psgnoteoffset-2)<<7)+pb_reg[ii]+(vibrato[ii]?(vib[ii]-vib_depth):0)-DTen[ii-6]; 
									if (psg_freq[ii-6] != psg_freq_pb[ii-6]) begin
										psg_freq[ii-6] <= psg_freq_pb[ii-6];
										psg_sent[ii-6] <= 0;
										psgseq[ii-6] <= 'd0;
										if (pb_old_reg[ii] != pb_reg[ii]) begin
											pb_old_reg[ii] <= pb_reg[ii];
										end
									end
								pb_count[ii] <= 'b1;
							end
							else if (vibrato[ii]) begin
								psg_pb_lookup[ii-6] <= ((note_reg[ii]-psgnoteoffset)<<7)+(vib[ii]-vib_depth)-DTen[ii-6]; 
								if (psg_freq[ii-6] != psg_freq_pb[ii-6]) begin
									psg_freq[ii-6] <= psg_freq_pb[ii-6];
									psg_sent[ii-6] <= 0;
									psgseq[ii-6] <= 'd0;
								end
							end
							else if (DTen[ii-6]) begin
								psg_pb_lookup[ii-6] <= ((note_reg[ii]-psgnoteoffset)<<7)-DTen[ii-6]; 
								if (psg_freq[ii-6] != psg_freq_pb[ii-6]) begin
									psg_freq[ii-6] <= psg_freq_pb[ii-6];
									psg_sent[ii-6] <= 0;
									psgseq[ii-6] <= 'd0;
								end
							end
							else if (psg_freq[ii-6] != PSGfrequencies[note_reg[ii]-psgnoteoffset]) begin
								psg_freq[ii-6] <= PSGfrequencies[note_reg[ii]-psgnoteoffset]; 
								psg_sent[ii-6] <= 0;
								psgseq[ii-6] <= 'd0;
							end
						end
						if (velocity_reg[ii] != adjusted_vel[ii-6] && fade_en[ii-6]) begin
							if (adjusted_vel[ii-6]) begin
								velocity_reg[ii] <= adjusted_vel[ii-6];
								psg_sent[ii-6] <= 0;
								psgseq[ii-6] <= 'd0;
								psgnotrig[ii-6] <= 1;
							end
							else begin
								note_on_reg[ii] <= 0;
								if (psg_on[ii-6]) begin
									psg_on[ii-6] <= 0;
									psg_sent[ii-6] <= 0;
									psgseq[ii-6] <= 'd0;
								end
							end
						end
					end
					if (repeat_note[ii]) begin
						psg_sent[ii-6] <= 0;
						psgseq[ii-6] <= 'd0;
						repeat_note[ii] <= 0;
					end
				end
				else begin
					if (psg_on[ii-6]) begin
						psg_on[ii-6] <= 0;
						psg_sent[ii-6] <= 0;
						psgseq[ii-6] <= 'd0;
					end
				end
			end

			/// PSG1 Echo from PSG0
			if (psg_echo_en) begin
				note_on_reg[7] <= psg_echo_note_on_reg;
				note_reg[7] <= psg_echo_note_reg;
				velocity_reg[7] <= psg_echo_velocity_reg;
				cc1_reg[7] <= psg_echo_cc1_reg;
				if (psg_echo_pb_reg) begin
					pb_count[7] <= pb_count[7] + 'b1;
					pb_reg[7] <= psg_echo_pb_reg;
				end
				if (pb_count[7]) pb_reg[7] <= psg_echo_pb_reg;
			end

			///// Sending data to Chips ////
			if (rst_timer) begin
				rst_timer <= rst_timer + 1;
			end
			else begin //for (int i = 0; i < 12; i = i + 1) begin
				//// FM /////
				if (patch_sent[i] && vel_sent[i] && mod_sent[i] && fm_sent[i] && pan_sent[i]) i <= i + 1;
				if (i > (DACen & DACen_sent? 4 : 5)) i <= 0;
				if (!patch_sent[i]) begin
					if (a_patch_upd[i]) begin
						if (!audio_wr) begin //else
							if (myaddress == 0 || myaddress == 2) begin
								case(patch_index[i])
									0 : begin
										myvalue <= ((ActivePatch[(i*42)+patch_index[i]+1]) << 3) | (ActivePatch[(i*42)+patch_index[i]] & 'h7); //feedback algorithm
										patch_index[i] <= 2;
									end
									2, 12, 22, 32 : begin
										myvalue <= (dtTableFMP[(ActivePatch[(i*42)+patch_index[i]+1])] << 4) | (ActivePatch[(i*42)+patch_index[i]] & 'hF); //Detune Multiplier
										patch_index[i] <= patch_index[i] + 2;
									end
									4, 14, 24, 34 : begin
										myvalue <= ActivePatch[(i*42)+patch_index[i]] & 'h7F; //Total Level
										patch_index[i] <= patch_index[i] + 1;
									end
									5, 15, 25, 35 : begin
										myvalue <= (ActivePatch[(i*42)+patch_index[i]] << 6) | ((ActivePatch[(i*42)+patch_index[i]+1]) & 'h1F); //RS AR
										patch_index[i] <= patch_index[i] + 2;
									end
									7, 17, 27, 37 : begin
										myvalue <= (0 << 7) | (ActivePatch[(i*42)+patch_index[i]] & 'h1F); //Amplitude by LFO D1R
										patch_index[i] <= patch_index[i] + 1;
									end
									8, 18, 28, 38 : begin
										myvalue <= (ActivePatch[(i*42)+patch_index[i]] & 'h1F); //D2R
										patch_index[i] <= patch_index[i] + 1;
									end
									9, 19, 29, 39 : begin
										myvalue <= ((ActivePatch[(i*42)+patch_index[i]+1]) << 4) | (ActivePatch[(i*42)+patch_index[i]] & 'hF); //D1L RR
										patch_index[i] <= patch_index[i] + 3;
										if (patch_index[i] == 39) patch_index[i] <= 40; //wav_ram_sent <= 1;
									end
									40 : begin
										myvalue <= 'hC0;
										patch_sent[i] <= 1;
									end
								endcase
								myaddress <= (i) < 3? 1 : 3;
							end
							else begin
								case(patch_index[i])
									0 : myvalue <= 'hB0 + (i) - ((i) > 2? 3 : 0); //feedback algorithm
									2, 12, 22, 32 : myvalue <= 'h30 + (opoffset[i]<<2) + (i) - ((i) > 2? 3 : 0); //Detune Multiplier
									4, 14, 24, 34 : myvalue <= 'h40 + (opoffset[i]<<2) + (i) - ((i) > 2? 3 : 0); //Total Level
									5, 15, 25, 35 : myvalue <= 'h50 + (opoffset[i]<<2) + (i) - ((i) > 2? 3 : 0); //RS AR
									7, 17, 27, 37 : myvalue <= 'h60 + (opoffset[i]<<2) + (i) - ((i) > 2? 3 : 0); //Amplitude by LFO D1R
									8, 18, 28, 38 : myvalue <= 'h70 + (opoffset[i]<<2) + (i) - ((i) > 2? 3 : 0); //D2R
									9, 19, 29, 39 : begin
										myvalue <= 'h80 + (opoffset[i]<<2) + (i) - ((i) > 2? 3 : 0); //D1L RR
										opoffset[i] <= opoffset[i] + 1;
									end
									40 : myvalue <= 'hB4;
								endcase
								myaddress <= (i) < 3? 0 : 2;
							end
							audio_wr <= 1;
						end
						else if (myaddress == 0 || myaddress == 2 || !genready[7]) audio_wr <= 0;
					end
				end
				else if (!vel_sent[i]) begin
					if (!audio_wr) begin
						if (myaddress == 1 || myaddress == 3) begin
							myaddress <= (i) < 3? 0 : 2;
							case(ActivePatch[(i*42)])
								0, 1, 2, 3, : begin
									myvalue <= 'h4C + (i) - ((i) > 2? 3 : 0);
								end
								4 : begin
									if (!car2[i]) begin
										myvalue <= 'h48 + (i) - ((i) > 2? 3 : 0);
									end
									else begin
										myvalue <= 'h4C + (i) - ((i) > 2? 3 : 0);
									end
								end
								5, 6 : begin
									case(car3[i])
										0 : begin
											myvalue <= 'h44 + (i) - ((i) > 2? 3 : 0);
										end
										1 : begin
											myvalue <= 'h48 + (i) - ((i) > 2? 3 : 0);
										end
										2 : begin
											myvalue <= 'h4C + (i) - ((i) > 2? 3 : 0);
										end
									endcase
								end
								7 : begin
									case(car4[i])
										0 : begin
											myvalue <= 'h40 + (i) - ((i) > 2? 3 : 0);
										end
										1 : begin
											myvalue <= 'h44 + (i) - ((i) > 2? 3 : 0);
										end
										2 : begin
											myvalue <= 'h48 + (i) - ((i) > 2? 3 : 0);
										end
										3 : begin
											myvalue <= 'h4C + (i) - ((i) > 2? 3 : 0);
										end
									endcase
								end
							endcase
						end
						else begin
							myaddress <= (i) < 3? 1 : 3;
							case(ActivePatch[(i*42)])
								0, 1, 2, 3, : begin
									myvalue <= VelLut[velocity_reg[i]] + (velocity_reg[i] > ActivePatch[(i*42)+34]? ActivePatch[(i*42)+34] : velocity_reg[i]);
									vel_sent[i] <= 1;
								end
								4 : begin
									if (!car2[i]) begin
										myvalue <= VelLut[velocity_reg[i]] + (velocity_reg[i] > ActivePatch[(i*42)+24]? ActivePatch[(i*42)+24] : velocity_reg[i]);
										car2[i] <= 1;
									end
									else begin
										myvalue <= VelLut[velocity_reg[i]] + (velocity_reg[i] > ActivePatch[(i*42)+34]? ActivePatch[(i*42)+34] : velocity_reg[i]);
										vel_sent[i] <= 1;
									end
								end
								5, 6 : begin
									case(car3[i])
										0 : begin
											myvalue <= VelLut[velocity_reg[i]] + (velocity_reg[i] > ActivePatch[(i*42)+14]? ActivePatch[(i*42)+14] : velocity_reg[i]);
											car3[i] <= 1;
										end
										1 : begin
											myvalue <= VelLut[velocity_reg[i]] + (velocity_reg[i] > ActivePatch[(i*42)+24]? ActivePatch[(i*42)+24] : velocity_reg[i]);
											car3[i] <= 2;
										end
										2 : begin
											myvalue <= VelLut[velocity_reg[i]] + (velocity_reg[i] > ActivePatch[(i*42)+34]? ActivePatch[(i*42)+34] : velocity_reg[i]);
											vel_sent[i] <= 1;
										end
									endcase
								end
								7 : begin
									case(car4[i])
										0 : begin
											myvalue <= VelLut[velocity_reg[i]] + (velocity_reg[i] > ActivePatch[(i*42)+4]? ActivePatch[(i*42)+4] : velocity_reg[i]);
											car4[i] <= 1;
										end
										1 : begin
											myvalue <= VelLut[velocity_reg[i]] + (velocity_reg[i] > ActivePatch[(i*42)+14]? ActivePatch[(i*42)+14] : velocity_reg[i]);
											car4[i] <= 2;
										end
										2 : begin
											myvalue <= VelLut[velocity_reg[i]] + (velocity_reg[i] > ActivePatch[(i*42)+24]? ActivePatch[(i*42)+24] : velocity_reg[i]);
											car4[i] <= 3;
										end
										3 : begin
											myvalue <= VelLut[velocity_reg[i]] + (velocity_reg[i] > ActivePatch[(i*42)+34]? ActivePatch[(i*42)+34] : velocity_reg[i]);
											vel_sent[i] <= 1;
										end
									endcase
								end
							endcase
						end
						audio_wr <= 1;
					end
					else if (myaddress == 0 || myaddress == 2 || !genready[7]) audio_wr <= 0;
				end
				else if (!mod_sent[i]) begin
					if (!audio_wr) begin
						if (myaddress == 1 || myaddress == 3) begin
							myaddress <= (i) < 3? 0 : 2;
							case(ActivePatch[(i*42)])
								0, 1, 2, 3, : begin
									case(mod3[i])
										0 : begin
											myvalue <= 'h40 + (i) - ((i) > 2? 3 : 0);
										end
										1 : begin
											myvalue <= 'h44 + (i) - ((i) > 2? 3 : 0);
										end
										2 : begin
											myvalue <= 'h48 + (i) - ((i) > 2? 3 : 0);
										end
									endcase
								end
								4 : begin
									if (!mod2[i]) begin
										myvalue <= 'h40 + (i) - ((i) > 2? 3 : 0);
									end
									else begin
										myvalue <= 'h44 + (i) - ((i) > 2? 3 : 0);
									end
								end
								5, 6 : begin
									myvalue <= 'h40 + (i) - ((i) > 2? 3 : 0);
								end
							endcase
						end
						else begin
							myaddress <= (i) < 3? 1 : 3;
							case(ActivePatch[(i*42)])
								0, 1, 2, 3, : begin
									case(mod3[i])
										0 : begin
											myvalue <= (127 - cc1mod_reg[i]) + (cc1mod_reg[i] > ActivePatch[(i*42)+4]? ActivePatch[(i*42)+4] : cc1mod_reg[i]);
											mod3[i] <= 1;
										end
										1 : begin
											myvalue <= (127 - cc1mod_reg[i]) + (cc1mod_reg[i] > ActivePatch[(i*42)+14]? ActivePatch[(i*42)+14] : cc1mod_reg[i]);
											mod3[i] <= 2;
										end
										2 : begin
											myvalue <= (127 - cc1mod_reg[i]) + (cc1mod_reg[i] > ActivePatch[(i*42)+24]? ActivePatch[(i*42)+24] : cc1mod_reg[i]);
											mod_sent[i] <= 1;
										end
									endcase
								end
								4 : begin
									if (!mod2[i]) begin
										myvalue <= (127 - cc1mod_reg[i]) + (cc1mod_reg[i] > ActivePatch[(i*42)+4]? ActivePatch[(i*42)+4] : cc1mod_reg[i]);
										mod2[i] <= 1;
									end
									else begin
										myvalue <= (127 - cc1mod_reg[i]) + (cc1mod_reg[i] > ActivePatch[(i*42)+14]? ActivePatch[(i*42)+14] : cc1mod_reg[i]);
										mod_sent[i] <= 1;
									end
								end
								5, 6 : begin
									myvalue <= (127 - cc1mod_reg[i]) + (cc1mod_reg[i] > ActivePatch[(i*42)+4]? ActivePatch[(i*42)+4] : cc1mod_reg[i]);
									mod_sent[i] <= 1;
								end
								7 : mod_sent[i] <= 1;
							endcase
						end
						audio_wr <= 1;
					end
					else if (myaddress == 0 || myaddress == 2 || !genready[7]) audio_wr <= 0;
				end
				else if (!pan_sent[i]) begin
					if (!audio_wr) begin
						if (myaddress == 1 || myaddress == 3) begin
							myaddress <= (i) < 3? 0 : 2;
							myvalue <= 'hB4 + + i - (i > 2? 3 : 0);
						end
						else begin
							myaddress <= (i) < 3? 1 : 3;
							myvalue <= pan_reg[i]<<6;
							pan_sent[i] <= 1;
						end
						audio_wr <= 1;
					end
					else if (myaddress == 0 || myaddress == 2 || !genready[7]) audio_wr <= 0;
				end
				else if (!fm_sent[i]) begin
					if (!audio_wr) begin
						case(myseq[i])
							'd0 : begin
								if (fm_trig[i]) begin
									myaddress <= 0;
									myvalue <= ('h28); //gen note off REG
								end
								myseq[i] <= 'd1;
							end
							'd1 : begin
								if (fm_trig[i]) begin
									myaddress <= 1;
									myvalue <= 0 + ((i) < 3? (i) : (i) + 1); //gen note off VAL
								end
								if (!fm_on[i]) fm_sent[i] <= 1;
								else myseq[i] <= 'd2;
							end
							'd2 : begin
								myaddress <= (i) < 3? 0 : 2;
								myvalue <= 'hA4 + (i) - ((i) > 2? 3 : 0); //gen freq1 REG
								myseq[i] <= 'd3;
							end
							'd3 : begin
								myaddress <= (i) < 3? 1 : 3;
								myvalue <= fm_freq[i] >> 8; //gen freq1 VAL
								myseq[i] <= 'd4;
							end
							'd4 : begin
								myaddress <= (i) < 3? 0 : 2;
								myvalue <= 'hA0 + (i) - ((i) > 2? 3 : 0); //gen freq2 REG
								myseq[i] <= 'd5; 
							end
							'd5 : begin
								myaddress <= (i) < 3? 1 : 3;
								myvalue <= fm_freq[i] & 'hFF; //gen freq2 VAL
								myseq[i] <= 'd6;
							end
							'd6 : begin
								if (fm_trig[i]) begin
									myaddress <= 0;
									myvalue <= 'h28; //gen note on REG
								end
								myseq[i] <= 'd7;
							end
							'd7 : begin
								if (fm_trig[i]) begin
									myaddress <= 1;
									myvalue <= 'hF0 + ((i) < 3? (i) : (i) + 1); //gen note on VAL
								end
								fm_sent[i] <= 1;
							end
						endcase
						audio_wr <= 1;
					end
					else if (myaddress == 0 || myaddress == 2 || !genready[7]) audio_wr <= 0;
				end
				else if (!DACen_sent) begin
					if (i == 5) begin
						if (!audio_wr) begin
							if (!DACen_seq) begin
								myaddress <= 0;
								myvalue <= 'h2B;
								DACen_seq <= 1;
							end
							else begin
								myaddress <= 1;
								myvalue <= (DACen? 'h80 : 0);
								DACen_sent <= 1;
							end
							audio_wr <= 1;
						end
						else if (myaddress == 0 || !genready[7]) audio_wr <= 0;
					end
				end
				else if (DACen && DACen_sent && !sample_sent) begin
					if (!sample_tick) begin
						if (!audio_wr) begin
							if (!DAC_seq) begin
								myaddress <= 0;
								myvalue <= 'h2A;
								DAC_seq <= 1;
							end
							else begin
								myaddress <= 1;
								myvalue <= sb_data_out;
								sample_i <= sample_i + 1;
								tick_hold <= 0;
								if (sample_i > sample_length[sample_c]) sample_sent <= 1;
							end
							audio_wr <= 1;
						end
						else if (myaddress == 0 || !genready[7]) audio_wr <= 0;
					end
					if (sample_tick < sample_speed) begin
						if (!tick_hold) sample_tick <= sample_tick + 1;
						if (sample_tick == sample_speed - 2) begin
							sb_out_address = sample_i+(sample_c? sample_length[0]: 0);
						end
					end
					else begin
						sample_tick <= 0;
						DAC_seq <= 0;
						tick_hold <= 1;
					end
				end

				//// PSG ////
				if (psg_sent[psg_i]) psg_i <= psg_i + 1;
				else begin
					if (!psg_wr) begin
						case(psgseq[psg_i])
							'd0 : begin
								psgvalue <= 'h90 | (psg_i << 5) | (psg_on[psg_i]? (VelLut[velocity_reg[psg_i+6]]>>3) : 15); //psg volume $90 OR (channel << 5) OR attenuation
								if (!psg_on[psg_i] || psgnotrig[psg_i]) begin
									psg_sent[psg_i] <= 1;
									psgnotrig[psg_i] <= 0;
								end
								else psgseq[psg_i] <= 'd1;
							end
							'd1 : begin
								if (psg_i < 3) begin
									psgvalue <= 'h80 | (psg_i << 5) | (psg_freq[psg_i] & 'hF); //psg freq $80 OR (channel << 5) OR (frequency AND 'h0F)
									psgseq[psg_i] <= 'd2; 
								end
								else begin
									psgvalue <= noisefreqs[note_reg[psg_i+6][2:0]];
									psg_sent[psg_i] <= 1;
								end
							end
							'd2 : begin
								psgvalue <= psg_freq[psg_i] >> 4;
								psg_sent[psg_i] <= 1;
							end
						endcase
						psg_wr <= 1;
					end
					else psg_wr <= 0;
				end
			end
	end
end

reg [6:0] adjusted_vel[4];
envelope envelope (
	.clk			(clk),
	.en (fade_en[0]),
	.decay (fade_speed[0]),
	.note_on (note_on_reg[6]),
	.note_start (note_reg[6]),
	.vel_start (velocity_reg[6]),
	.adjusted_vel (adjusted_vel[0])
);
envelope envelope2 (
	.clk			(clk),
	.en (echo_en? fade_en[0] : fade_en[1]),
	.decay (echo_en? fade_speed[0] : fade_speed[1]),
	.note_on (note_on_reg[7]),
	.note_start (note_reg[7]),
	.vel_start (velocity_reg[7]),
	.adjusted_vel (adjusted_vel[1])
);
envelope envelope3 (
	.clk			(clk),
	.en (fade_en[2]),
	.decay (fade_speed[2]),
	.note_on (note_on_reg[8]),
	.note_start (note_reg[8]),
	.vel_start (velocity_reg[8]),
	.adjusted_vel (adjusted_vel[2])
);
envelope envelopenoise (
	.clk			(clk),
	.en (fade_en[3]),
	.decay (fade_speed[3]),
	.note_on (note_on_reg[9]),
	.note_start (note_reg[9]),
	.vel_start (velocity_reg[9]),
	.adjusted_vel (adjusted_vel[3])
);

/*midipb_to_gbfreq_LUT midipb_to_gbfreq_LUT (
	.address (pb_lookup[sq1_channel]),
	.clock (clk),
	.q (sq1_freq_pb)
);
midipb_to_gbfreq_LUT midipb_to_gbfreq_LUT2 (
	.address (pb_lookup[sq2_channel]),
	.clock (clk),
	.q (sq2_freq_pb)
);
midipb_to_gbfreq_LUT midipb_to_gbfreq_LUT3 (
	.address (pb_lookup[wav_channel]),
	.clock (clk),
	.q (wav_freq_pb)
);*/
midipb_to_Genfreq_LUT midipb_to_Genfreq_LUT0 (
	.address (pb_lookup[0]),
	.clock (gencen),
	.q (fm_freq_pb[0])
);
midipb_to_Genfreq_LUT midipb_to_Genfreq_LUT1 (
	.address (pb_lookup[1]),
	.clock (gencen),
	.q (fm_freq_pb[1])
);
midipb_to_Genfreq_LUT midipb_to_Genfreq_LUT2 (
	.address (pb_lookup[2]),
	.clock (gencen),
	.q (fm_freq_pb[2])
);
midipb_to_Genfreq_LUT midipb_to_Genfreq_LUT3 (
	.address (pb_lookup[3]),
	.clock (gencen),
	.q (fm_freq_pb[3])
);
midipb_to_Genfreq_LUT midipb_to_Genfreq_LUT4 (
	.address (pb_lookup[4]),
	.clock (gencen),
	.q (fm_freq_pb[4])
);
midipb_to_Genfreq_LUT midipb_to_Genfreq_LUT5 (
	.address (pb_lookup[5]),
	.clock (gencen),
	.q (fm_freq_pb[5])
);

midipb_to_PSGfreq_LUT midipb_to_PSGfreq_LUT0 (
	.address (psg_pb_lookup[0]),
	.clock (gencen),
	.q (psg_freq_pb[0])
);
midipb_to_PSGfreq_LUT midipb_to_PSGfreq_LUT1 (
	.address (psg_pb_lookup[1]),
	.clock (gencen),
	.q (psg_freq_pb[1])
);
midipb_to_PSGfreq_LUT midipb_to_PSGfreq_LUT2 (
	.address (psg_pb_lookup[2]),
	.clock (gencen),
	.q (psg_freq_pb[2])
);

reg [8:0] vib[0:15];
reg vib_start[0:8];
vibrato_gen #(.depth(vib_depth)) vibrato_gen0 (
	.en (vibrato[0]),
	.clk (clk),
	.note_on (note_on_reg[0]),
	.note_start (note_reg[0]),
	.wheel(cc1_reg[0]),
	.vib_out (vib[0]),
	.vib_start (vib_start[0])
);
vibrato_gen #(.depth(vib_depth)) vibrato_gen1 (
	.en (auto_poly? vibrato[0] : vibrato[1]),
	.clk (clk),
	.note_on (note_on_reg[1]),
	.note_start (note_reg[1]),
	.wheel(cc1_reg[1]),
	.vib_out (vib[1]),
	.vib_start (vib_start[1])
);
vibrato_gen #(.depth(vib_depth)) vibrato_gen2 (
	.en (auto_poly? vibrato[0] : vibrato[2]),
	.clk (clk),
	.note_on (note_on_reg[2]),
	.note_start (note_reg[2]),
	.wheel(cc1_reg[2]),
	.vib_out (vib[2]),
	.vib_start (vib_start[2])
);
vibrato_gen #(.depth(vib_depth)) vibrato_gen3 (
	.en (auto_poly? vibrato[0] : vibrato[3]),
	.clk (clk),
	.note_on (note_on_reg[3]),
	.note_start (note_reg[3]),
	.wheel(cc1_reg[3]),
	.vib_out (vib[3]),
	.vib_start (vib_start[3])
);
vibrato_gen #(.depth(vib_depth)) vibrato_gen4 (
	.en (auto_poly? vibrato[0] : vibrato[4]),
	.clk (clk),
	.note_on (note_on_reg[4]),
	.note_start (note_reg[4]),
	.wheel(cc1_reg[4]),
	.vib_out (vib[4]),
	.vib_start (vib_start[4])
);
vibrato_gen #(.depth(vib_depth)) vibrato_gen5 (
	.en (auto_poly? vibrato[0] : vibrato[5]),
	.clk (clk),
	.note_on (note_on_reg[5]),
	.note_start (note_reg[5]),
	.wheel(cc1_reg[5]),
	.vib_out (vib[5]),
	.vib_start (vib_start[5])
);

vibrato_gen #(.depth(vib_depth)) vibrato_genPSG0 (
	.en (vibrato[6]),
	.clk (clk),
	.note_on (note_on_reg[6]),
	.note_start (note_reg[6]),
	.wheel(cc1_reg[6]),
	.vib_out (vib[6]),
	.vib_start (vib_start[6])
);
vibrato_gen #(.depth(vib_depth)) vibrato_genPSG1 (
	.en (vibrato[7]),
	.clk (clk),
	.note_on (note_on_reg[7]),
	.note_start (note_reg[7]),
	.wheel(cc1_reg[7]),
	.vib_out (vib[7]),
	.vib_start (vib_start[7])
);
vibrato_gen #(.depth(vib_depth)) vibrato_genPSG2 (
	.en (vibrato[8]),
	.clk (clk),
	.note_on (note_on_reg[8]),
	.note_start (note_reg[8]),
	.wheel(cc1_reg[8]),
	.vib_out (vib[8]),
	.vib_start (vib_start[8])
);

/*reg [1:0] duty_switch_reg[0:15];
duty_switch duty_switch (
	.en (duty_switch_en),
	.clk (clk),
	.note_on (note_on_reg[sq1_channel]),
	.note_start (note_reg[sq1_channel]),
	.duty_out (duty_switch_reg[sq1_channel])
);
duty_switch duty_switch2 (
	.en (duty_switch_en2),
	.clk (clk),
	.note_on (note_on_reg[sq2_channel]),
	.note_start (note_reg[sq2_channel]),
	.duty_out (duty_switch_reg[sq2_channel])
);

reg [6:0] fall_amount_reg;
pitchfall pitchfall (
	.clk			(clk),
	.en (fall_en),
	.speed (fall_speed),
	.note_on (note_on_reg[noi_channel]),
	.note_start (note_reg[noi_channel]),
	.fall_amount (fall_amount_reg)
);

reg [12:0] fall2_amount_reg;
pitchfallW pitchfall2 (
	.clk			(clk),
	.en (fall2_en),
	.speed (fall2_speed),
	.note_on (note_on_reg[wav_channel]),
	.note_start (note_reg[wav_channel]),
	.fall_amount (fall2_amount_reg)
);*/

reg echo_note_on_reg;
reg [6:0] echo_note_reg;
reg [6:0] echo_velocity_reg;
//reg [3:0] echo_prev_vel_reg;
reg [8:0] echo_pb_reg;
reg [1:0] echo_cc1_reg;
reg [6:0] echo_cc1mod_reg;

echo_gen echo_gen (
	.en (echo_en),
	.clk (clk),
	.note_on (note_on_reg[0]),
	.note_start (note_reg[0]),
	.vel_start (velocity_reg[0]),
	.pb_start (pb_reg[0]),
	.cc1_start (cc1_reg[0]),
	.cc1mod_start (cc1mod_reg[0]),
	.echo_on (echo_note_on_reg),
	.echo_note (echo_note_reg),
	.echo_vel (echo_velocity_reg),
	.echo_pb (echo_pb_reg),
	.echo_cc1 (echo_cc1_reg),
	.echo_cc1mod (echo_cc1mod_reg)
);

reg psg_echo_note_on_reg;
reg [6:0] psg_echo_note_reg;
reg [6:0] psg_echo_velocity_reg;
reg [8:0] psg_echo_pb_reg;
reg [1:0] psg_echo_cc1_reg;
echo_gen psg_echo_gen (
	.en (psg_echo_en),
	.clk (clk),
	.note_on (note_on_reg[6]),
	.note_start (note_reg[6]),
	.vel_start (velocity_reg[6]),
	.pb_start (pb_reg[6]),
	.cc1_start (cc1_reg[6]),
	.echo_on (psg_echo_note_on_reg),
	.echo_note (psg_echo_note_reg),
	.echo_vel (psg_echo_velocity_reg),
	.echo_pb (psg_echo_pb_reg),
	.echo_cc1 (psg_echo_cc1_reg)
);

/*reg [3:0] blip[0:15];
blip_gen blip_gen (
	.en (blip_en),
	.clk (clk),
	.note_on (note_on_reg[sq1_channel]),
	.note_start (note_reg[sq1_channel]),
	.blip_out (blip[sq1_channel])
);
blip_gen blip_gen2 (
	.en (blip_en2),
	.clk (clk),
	.note_on (note_on_reg[sq2_channel]),
	.note_start (note_reg[sq2_channel]),
	.blip_out (blip[sq2_channel])
);
blip_gen blip_gen3 (
	.en (blip_en3),
	.clk (clk),
	.note_on (note_on_reg[wav_channel]),
	.note_start (note_reg[wav_channel]),
	.blip_out (blip[wav_channel])
);*/

wire signed [15:0] audio_l1;
wire signed [15:0] audio_r1;

/*gbc_snd audio (
	.clk			(clk),
	.ce             (gencen),
	.reset			(reset),

	.is_gbc         (0),

	.s1_read  		(0),
	.s1_write 		(audio_wr),
	.s1_addr    	(myaddress),
    .s1_readdata 	(snd_d_out),
	.s1_writedata   (myvalue),

    .snd_left 		(audio_l1),
	.snd_right  	(audio_r1)
);*/

jt12 jt12 (
	.rst			(rst_timer? 1 : 0),
	.clk			(clk),
	.cen            (gencen),
	.din   			(myvalue),
	.addr    		(myaddress),
	.wr_n 			(~audio_wr),
	.cs_n			(0),
 
	.en_hifi_pcm 	(1),
	.ladder			(1),

	.dout     		(genready),
	

    .snd_left 		(audio_l1),
	.snd_right  	(audio_r1)
);

wire signed [10:0] psg_sound;
jt89 psg
(
	.rst(rst_timer? 1 : 0),
	.clk(clk),
	.clk_en(psgcen),

	.wr_n(~psg_wr),
	.din(psgvalue),

	.sound(psg_sound)
);
assign PSG_SND = psg_sound;

reg [3:0] poly_adjusted_vel[0:15][0:max+max-1];
reg [8:0] poly_vib[0:15][0:max+max-1];
reg [1:0] poly_duty_switch_reg[0:15][0:max+max-1];
reg [3:0] poly_blip[0:15][0:max+max-1];

wire [15:0] audio_lP[0:max-1];
wire [15:0] audio_rP[0:max-1];
wire [15:0] audio_combined_l[0:max];
wire [15:0] audio_combined_r[0:max];

wire [255:0] poly_note_out_combined[0:max];

/*generate
	genvar ii;
	for (ii = 0; ii < max; ii = ii + 1) begin: ingbs
		envelope envelope (
			.clk			(clk),
			.en (fade_en),
			.decay (fade_speed),
			.note_on (poly_note_on_reg[sq1_channel][ii+ii]),
			.note_repeat (poly_repeat_note[sq1_channel][ii+ii]),
			.note_start (poly_note_reg[sq1_channel][ii+ii]),
			.vel_start (poly_velocity_reg[sq1_channel][ii+ii]),
			.adjusted_vel (poly_adjusted_vel[sq1_channel][ii+ii])
		);
		envelope envelope2 (
			.clk			(clk),
			.en (fade_en),
			.decay (fade_speed),
			.note_on (poly_note_on_reg[sq1_channel][ii+ii+1]),
			.note_repeat (poly_repeat_note[sq1_channel][ii+ii+1]),
			.note_start (poly_note_reg[sq1_channel][ii+ii+1]),
			.vel_start (poly_velocity_reg[sq1_channel][ii+ii+1]),
			.adjusted_vel (poly_adjusted_vel[sq1_channel][ii+ii+1])
		);
		midipb_to_gbfreq_LUT midipb_to_gbfreq_LUT (
			.address (poly_pb_lookup[sq1_channel][ii+ii]),
			.clock (clk),
			.q (sq1_freq_pbP[ii])
		);
		midipb_to_gbfreq_LUT midipb_to_gbfreq_LUT2 (
			.address (poly_pb_lookup[sq1_channel][ii+ii+1]),
			.clock (clk),
			.q (sq2_freq_pbP[ii])
		);
		vibrato_gen vibrato_gen (
			.en (vibrato),
			.clk (clk),
			.note_on (poly_note_on_reg[sq1_channel][ii+ii]),
			.note_repeat (poly_repeat_note[sq1_channel][ii+ii]),
			.note_start (poly_note_reg[sq1_channel][ii+ii]),
			.vib_out (poly_vib[sq1_channel][ii+ii])
		);
		vibrato_gen vibrato_gen2 (
			.en (vibrato),
			.clk (clk),
			.note_on (poly_note_on_reg[sq1_channel][ii+ii+1]),
			.note_repeat (poly_repeat_note[sq1_channel][ii+ii+1]),
			.note_start (poly_note_reg[sq1_channel][ii+ii+1]),
			.vib_out (poly_vib[sq1_channel][ii+ii+1])
		);
		duty_switch duty_switch (
			.en (duty_switch_en),
			.clk (clk),
			.note_on (poly_note_on_reg[sq1_channel][ii+ii]),
			.note_repeat (poly_repeat_note[sq1_channel][ii+ii]),
			.note_start (poly_note_reg[sq1_channel][ii+ii]),
			.duty_out (poly_duty_switch_reg[sq1_channel][ii+ii])
		);
		duty_switch duty_switch2 (
			.en (duty_switch_en),
			.clk (clk),
			.note_on (poly_note_on_reg[sq1_channel][ii+ii+1]),
			.note_repeat (poly_repeat_note[sq1_channel][ii+ii+1]),
			.note_start (poly_note_reg[sq1_channel][ii+ii+1]),
			.duty_out (poly_duty_switch_reg[sq1_channel][ii+ii+1])
		);
		blip_gen blip_gen (
			.en (blip_en),
			.clk (clk),
			.note_on (poly_note_on_reg[sq1_channel][ii+ii]),
			.note_repeat (poly_repeat_note[sq1_channel][ii+ii]),
			.note_start (poly_note_reg[sq1_channel][ii+ii]),
			.blip_out (poly_blip[sq1_channel][ii+ii])
		);
		blip_gen blip_gen2 (
			.en (blip_en),
			.clk (clk),
			.note_on (poly_note_on_reg[sq1_channel][ii+ii+1]),
			.note_repeat (poly_repeat_note[sq1_channel][ii+ii+1]),
			.note_start (poly_note_reg[sq1_channel][ii+ii+1]),
			.blip_out (poly_blip[sq1_channel][ii+ii+1])
		);
		gbc_snd audio (
			.clk			(clk),
			.ce             (gencen),
			.reset			(reset),

			.is_gbc         (0),

			.s1_read  		(0),
			.s1_write 		(audio_wrP[ii]),
			.s1_addr    	(myaddressP[ii]),
			.s1_readdata 	(snd_d_out),
			.s1_writedata   (myvalueP[ii]),

			.snd_left 		(audio_lP[ii]),
			.snd_right  	(audio_rP[ii])
		);
		mixer mix (
			.clk (clk),
			.gencen (gencen),
			.aa_l_in (audio_lP[ii]),
			.aa_r_in (audio_rP[ii]),
			.ac_l_in (audio_combined_l[ii]),
			.ac_r_in (audio_combined_r[ii]),
			.ac_l_out (audio_combined_l[ii+1]),
			.ac_r_out (audio_combined_r[ii+1])
		);
		poly_disp poly_disp (
			.clk(clk),
			.sq1_no_in (poly_note_on_reg[sq1_channel][ii+ii]),
			.sq2_no_in (poly_note_on_reg[sq1_channel][ii+ii+1]),
			.sq1_n_in (poly_note_reg[sq1_channel][ii+ii]),
			.sq2_n_in (poly_note_reg[sq1_channel][ii+ii+1]),
			.ii_in (ii),
			.pd_in (poly_note_out_combined[ii]),
			.pd_out (poly_note_out_combined[ii+1])
		);
	end
endgenerate*/

assign FM_audio_l = audio_l1; // + audio_combined_l[max];
assign FM_audio_r = audio_r1; // + audio_combined_r[max];

endmodule
