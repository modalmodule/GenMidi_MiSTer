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

module GBMidi
(
    input          clk,
    input          ce,
    input          ce_2x,
    input          reset,
    input  [127:0] status,

    input   [15:0] joystick_0,

    input    [7:0] midi_data,
    input          midi_send,
    output         midi_ready,

    output  [10:0] note_out,
    output  [10:0] note_out2,
	output  [10:0] note_out3,
	output  [10:0] note_out4,
    output [255:0] poly_note_out,

    // audio
    output  [15:0] audio_l,
    output  [15:0] audio_r
);

assign note_out = (note_on_reg[sq1_channel]<<9) + (note_reg[sq1_channel]-36);
assign note_out2 = (note_on_reg[sq2_channel]<<9) + (note_reg[sq2_channel]-36);
assign note_out3 = (note_on_reg[wav_channel]<<9) + (note_reg[wav_channel]-36);
assign note_out4 = (note_on_reg[noi_channel]<<9) + (note_reg[noi_channel]-36);
assign poly_note_out = poly_note_out_combined[max];

//OSD labels
wire auto_poly_set = status[7];
reg auto_poly;
wire gamepadtoNotes = status[3];
wire echo_en = status[16] & !status[68:67];
wire[1:0] mchannel1_choice = status[68:67];
reg[1:0] mchannel1_choice_reg;
//pulse 1
wire [1:0] duty_set = status[6:5];
wire modtoDuty = status[13];
wire duty_switch_en = status[15];
wire vibrato = status[14];
wire blip_en = status[17];
wire fade_en = status[8];
wire [3:0] fade_speed = status[12:9];
//pulse 2
wire [1:0] duty_set2 = status[23:22];
wire modtoDuty2 = status[30];
wire duty_switch_en2 = status[32];
wire vibrato2 = status[31];
wire blip_en2 = status[34];
wire fade_en2 = status[25];
wire [3:0] fade_speed2 = status[29:26];
//wave
wire [3:0] waveform = status[55:52];
wire vibrato3 = status[56];
wire blip_en3 = status[57];
wire fall2_en = status[58];
wire [2:0] fall2_speed = status[61:59];
wire fade_en3 = status[62];
wire [3:0] fade_speed3 = status[66:63];
//noise
wire noi_type = status[39];
wire fall_en = status[40];
wire [2:0] fall_speed = status[43:41];
wire fade_en4 = status[44];
wire [3:0] fade_speed4 = status[48:45];


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
	.pb_val(pb_val)
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


wire [7:0] snd_d_out;
reg audio_wr;
reg [6:0] myaddress;
reg [7:0] myvalue;
reg [2:0] myseq = 3'b000;
reg [10:0] sq1_freq = 11'b11010011110;
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
reg[4:0] wav_ram_count;
reg wav_dac_en;
reg sq1_trig = 1;
reg sq2_trig = 1;
reg wav_trig = 1;
reg noi_trig = 1;
reg [10:0] freq_temp;
reg [10:0] sq1_freq_pb;
reg [10:0] sq2_freq_pb;
reg [10:0] wav_freq_pb;
reg[3:0] waveform_reg;
reg mono_kill;


//POLY
localparam int max = 4; //Max instances of gbc_snd
reg audio_wrP[0:max-1];
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
reg [10:0] sq2_freq_pbP[0:max-1];
reg poly_kill;

//GAMEPAD
reg [3:0] last_joy = 8;

//MIDI REGS
reg note_switch;
localparam int sq1_channel = 0; // midi channel for pulse 1, 0 = channel 1
localparam int sq2_channel = 1; // midi channel for pulse 2, 1 = channel 2
localparam int wav_channel = 2;
localparam int noi_channel = 3;
reg note_on_reg[0:3];
reg [6:0] note_reg[0:3];
reg [6:0] old_note_reg[0:3];
reg [3:0] velocity_reg[0:3];
reg sustain[0:3];
reg note_sus_on[0:3];
reg [1:0] cc1_reg[0:3];
reg [8:0] pb_reg[0:3];
reg [8:0] pb_old_reg[0:3];
reg [3:0] pb_count[0:3];
reg [13:0] pb_lookup[0:3];
localparam int pb_div = 128; //pitch bend values divide a half step by 128
reg [1:0] mchan_pl_choice;

reg [6:0] note_tmp;
reg [6:0] velocity_tmp;
reg [3:0] channel_tmp;

//POLY
reg poly_note_on_reg[0:15][0:max+max-1];
reg poly_repeat_note[0:15][0:max+max-1];
reg [6:0] poly_note_reg[0:15][0:max+max-1];
reg [3:0] poly_velocity_reg[0:15][0:max+max-1];
reg poly_note_sus_on[0:15][0:max+max-1];
reg [4:0] poly_max_voice = max+max-'b1;
reg [4:0] poly_replace;
reg [4:0] poly_cvoice;
reg vfound;
reg [13:0] poly_pb_lookup[0:15][0:max+max-1];
reg [max-1:0] poly_reset;

reg midi_ready_reg = 1;
assign midi_ready = midi_ready_reg;

int i;
always @ (posedge clk) begin
	if (reset) begin
    	myaddress <= 7'b0000000;
    	myvalue   <= 8'b00000000;
		audio_wr <= 0;
		myaddress <= 0;
		myvalue <= 0;
		myseq <= 3'b000;
		sq1_freq <= 11'b11010011110;
		sq2_freq <= 11'b11010011110;
		sq1_on <= 0;
		sq2_on <= 0;
		sq1_sent <= 1;
		sq2_sent <= 1;
		for (i = 0; i < 4; i= i + 1) begin
			note_on_reg[i] <= 0;
			note_reg[i] <= 0;
			velocity_reg[i] <= 0;
		end
		midi_ready_reg <= 1;
	end
	if (!Pinit) begin
		for (int ii = 0; ii < max; ii = ii + 1) begin
			sq1_sentP[ii] <= 1;
			sq2_sentP[ii] <= 1;
			sq1_duty_sentP[ii] <= 1;
			sq2_duty_sentP[ii] <= 1;
		end
		note_reg[sq1_channel] <= 'd60;
	end
	if (sq1_sentP[max-1] == 1) Pinit <= 1;
	if (!auto_poly) begin
		if (!gamepadtoNotes) begin    ///VOICE PER CHANNEL///
			if (mchannel < 4) begin
				if (mchannel1_choice_reg != mchannel1_choice) begin
					note_on_reg[sq1_channel] <= 0;
					note_on_reg[sq2_channel] <= 0;
					note_on_reg[wav_channel] <= 0;
					note_on_reg[noi_channel] <= 0;
					if (!sq1_on && !sq2_on && !wav_on && !noi_on && sq1_sent && sq2_sent && wav_sent && noi_sent) begin
						mchannel1_choice_reg <= mchannel1_choice;
					end
				end
				else begin
					mchan_pl_choice <= mchannel1_choice + mchannel;
					if (note_on || note_off) begin
						if (note_on) begin
							note_on_reg[mchan_pl_choice] <= 1;
							note_reg[mchan_pl_choice] <= note;
							velocity_reg[mchan_pl_choice] <= velocity>>3;
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
						if (cc == 'd1 && modtoDuty) begin
							if (cc_val < 43) cc1_reg[mchan_pl_choice] = 'd0;
							else if (cc_val < 86) cc1_reg[mchan_pl_choice] = 'd1;
							else cc1_reg[mchan_pl_choice] = 'd2;
						end
					end
					else if (pb_send) begin
						pb_count[mchan_pl_choice] <= pb_count[mchan_pl_choice] + 'b1;
						pb_reg[mchan_pl_choice] <= pb_val>>5;
					end
				end
			end
			if (auto_poly != auto_poly_set) begin
				note_on_reg[sq1_channel] <= 0;
				note_on_reg[sq2_channel] <= 0;
				note_on_reg[wav_channel] <= 0;
				note_on_reg[noi_channel] <= 0;
				mono_kill <= 1;
				if (!sq1_on && !sq2_on && !wav_on && !noi_on && sq1_sent && sq2_sent && wav_sent && noi_sent) begin
					auto_poly <= auto_poly_set;
					poly_reset <= 0;
					mono_kill <= 0;
				end
			end
		end
		else begin
			if (joystick_0) begin
				if (!joystick_0[last_joy]) begin
					note_on_reg[sq1_channel] <= 1;
					if (joystick_0[0]) begin
						note_reg[sq1_channel] <= 60;
						last_joy <= 0;
					end
					else if (joystick_0[1]) begin
						note_reg[sq1_channel] <= 62;
						last_joy <= 1;
					end
					else if (joystick_0[2]) begin
						note_reg[sq1_channel] <= 63;
						last_joy <= 2;
					end
					else if (joystick_0[3]) begin
						note_reg[sq1_channel] <= 65;
						last_joy <= 3;
					end
					else if (joystick_0[4]) begin
						note_reg[sq1_channel] <= 67;
						last_joy <= 4;
					end
					else if (joystick_0[5]) begin
						note_reg[sq1_channel] <= 68;
						last_joy <= 5;
					end
					else if (joystick_0[6]) begin
						note_reg[sq1_channel] <= 70;
						last_joy <= 6;
					end
					else if (joystick_0[7]) begin
						note_reg[sq1_channel] <= 72;
						last_joy <= 7;
					end
					velocity_reg[sq1_channel] <= 'd100>>3;
				end
			end
			else begin
				note_on_reg[sq1_channel] <= 0;
				last_joy <= 8;
			end
		end
	end
	else begin ////////POLY/////
		if (poly_replace > poly_max_voice) poly_replace <= 0;
		if (poly_cvoice) begin
			poly_note_on_reg[channel_tmp][poly_cvoice-'b1] <= 1;
			poly_note_reg[channel_tmp][poly_cvoice-'b1] <= note_tmp;
			poly_velocity_reg[channel_tmp][poly_cvoice-'b1] <= velocity_tmp>>3;
			poly_cvoice <= 0;
		end
		else if (!vfound) begin
			poly_note_on_reg[channel_tmp][poly_replace] <= 1;
			poly_note_reg[channel_tmp][poly_replace] <= note_tmp;
			poly_velocity_reg[channel_tmp][poly_replace] <= velocity_tmp>>3;
			poly_replace <= poly_replace + 1'b1;
			vfound <= 1;
			poly_note_sus_on[channel_tmp][poly_replace] <= 0;
		end
		if (note_on || note_off) begin
			if (note_on) begin
				vfound <= 0;
				note_tmp <= note;
				velocity_tmp <= velocity;
				channel_tmp <= mchannel;
				for (int ii = 0; ii < max+max; ii = ii + 1) begin: vcheck
					if (poly_note_reg[mchannel][ii] == note && poly_note_on_reg[mchannel][ii]) begin
						poly_cvoice <= ii + 'b1;
						vfound <= 1;
						poly_note_sus_on[mchannel][ii] <= 0;
						poly_repeat_note[mchannel][ii] <= 1;
						disable vcheck;
					end
					else if (poly_note_on_reg[mchannel][ii] == 0) begin
						poly_cvoice <= ii + 'b1;
						vfound <= 1;
						poly_note_sus_on[mchannel][ii] <= 0;
						disable vcheck;
					end
				end

			end
			if (note_off) begin
				for (int ii = 0; ii < max+max; ii = ii + 1) begin: ncheck
					if (poly_note_reg[mchannel][ii] == note) begin
						if (!sustain[mchannel]) begin
							poly_note_on_reg[mchannel][ii] <= 0;
							poly_replace <= ii;
						end
						else poly_note_sus_on[mchannel][ii] <= 1;
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
						if (poly_note_sus_on[mchannel][ii]) begin
							poly_note_sus_on[mchannel][ii] <= 0;
							poly_note_on_reg[mchannel][ii] <= 0;
						end
					end
				end
			end
			if (cc == 'd1 && modtoDuty) begin
				if (cc_val < 43) cc1_reg[mchannel] = 'd0;
				else if (cc_val < 86) cc1_reg[mchannel] = 'd1;
				else cc1_reg[mchannel] = 'd2;
			end
		end
		else if (pb_send) begin
			pb_count[mchannel] <= pb_count[mchannel] + 'b1;
			pb_reg[mchannel] <= pb_val>>5;
		end
		if (auto_poly != auto_poly_set) begin
			wav_dac_en <= 1;
			wav_sent <= 0;
			if (poly_reset != 'b1111) begin
				poly_kill <= 1;
				for (int ii = 0; ii < max; ii = ii + 1) begin
					poly_note_on_reg[sq1_channel][ii+ii] <= 0;
					poly_note_on_reg[sq1_channel][ii+ii+1] <= 0;
					if (!sq1_onP[ii] && !sq2_onP[ii] && sq1_sentP[ii] && sq2_sentP[ii]) begin
						poly_reset[ii] <= 1'b1;
					end
				end
			end
			else begin
				poly_reset <= 0;
				poly_kill <= 0;
				auto_poly <= auto_poly_set;
			end
		end
	end

	if (ce_2x) begin
		///VOICE PER CHANNEL///
		if (!auto_poly) begin
			if (note_on_reg[sq1_channel]) begin
				if (!note_switch && !sq1_trig) note_switch <= 1;
				if (!sq1_on) begin
					if (pb_count[sq1_channel]) begin
						pb_lookup[sq1_channel] <= ((note_reg[sq1_channel]-36-2)*pb_div)+pb_reg[sq1_channel];
						sq1_freq <= sq1_freq_pb;
						pb_count[sq1_channel] <= 'b1;
						pb_old_reg[sq1_channel] <= pb_reg[sq1_channel];
					end
					else sq1_freq <= frequencies[note_reg[sq1_channel]-36];
					sq1_on <= 1;
					sq1_sent <= 0;
					if (sq2_sent) myseq <= 'd0;
					sq1_trig <= 1;
				end
				else if (pb_count[sq1_channel]) begin
						pb_lookup[sq1_channel] <= ((note_reg[sq1_channel]-36-2+blip[sq1_channel])*pb_div)+pb_reg[sq1_channel]+(vibrato?(vib[sq1_channel]-12):0);
						if (sq1_freq != sq1_freq_pb) begin
							sq1_freq <= sq1_freq_pb;
							sq1_sent <= 0;
							note_switch <= 0;
							if (sq2_sent) myseq <= 'd0;
							if (pb_old_reg[sq1_channel] != pb_reg[sq1_channel]) begin
								sq1_trig <= 0;
								pb_old_reg[sq1_channel] <= pb_reg[sq1_channel];
							end
							else if (vib[sq1_channel]-12 != 0) sq1_trig <= 0;
							else sq1_trig <= 1;
						end
						else note_switch <= 1;
					pb_count[sq1_channel] <= 'b1;
				end
				else if (vibrato) begin
					pb_lookup[sq1_channel] <= ((note_reg[sq1_channel]-36+blip[sq1_channel])*pb_div)+(vib[sq1_channel]-12);
					if (sq1_freq != sq1_freq_pb) begin
						sq1_freq <= sq1_freq_pb;
						sq1_sent <= 0;
						note_switch <= 0;
						if (sq2_sent) myseq <= 'd0;
						if (vib[sq1_channel]-12 != 0) sq1_trig <= 0;
						else sq1_trig <= 1;
					end
					else note_switch <= 1;
				end
				else if (sq1_freq != frequencies[note_reg[sq1_channel]-36+blip[sq1_channel]]) begin
					sq1_freq <= frequencies[note_reg[sq1_channel]-36+blip[sq1_channel]];
					sq1_sent <= 0;
					if (sq2_sent) myseq <= 'd0;
					sq1_trig <= 1;
					note_switch <= 0;
				end
				if (velocity_reg[sq1_channel] != adjusted_vel[sq1_channel] && fade_en && fade_speed < 4) begin
					if (adjusted_vel[sq1_channel]) begin
						velocity_reg[sq1_channel] <= adjusted_vel[sq1_channel];
						sq1_sent <= 0;
						if (sq2_sent) myseq <= 'd0;
						sq1_trig <= 1;
					end
					else begin
						note_on_reg[sq1_channel] <= 0;
						note_reg[sq1_channel] <= 0;
						if (sq1_on) begin
							sq1_on <= 0;
							sq1_sent <= 0;
							if (sq2_sent) myseq <= 'd0;
							sq1_trig <= 1;
						end
					end
				end
			end
			else begin
				if (sq1_on) begin
					sq1_on <= 0;
					sq1_sent <= 0;
					if (sq2_sent) myseq <= 'd0;
					sq1_trig <= 1;
				end
			end
			if (duty_switch_en) begin
				if (sq1_duty != duty_switch_reg[sq1_channel]) begin
					sq1_duty <= duty_switch_reg[sq1_channel];
					sq1_duty_sent <= 0;
				end
			end
			else if (modtoDuty) begin
				if (sq1_duty != cc1_reg[sq1_channel]) begin
					sq1_duty <= cc1_reg[sq1_channel];
					sq1_duty_sent <= 0;
				end
			end
			else if (sq1_duty != duty_set) begin
				sq1_duty <= duty_set;
				sq1_duty_sent <= 0;
			end

			///2nd pulse
			if (echo_en) begin
				note_on_reg[sq2_channel] <= echo_note_on_reg;
				note_reg[sq2_channel] <= echo_note_reg;
				velocity_reg[sq2_channel] <= echo_velocity_reg;
				if (echo_pb_reg) begin
					pb_count[sq2_channel] <= pb_count[sq2_channel] + 'b1;
					pb_reg[sq2_channel] <= echo_pb_reg;
				end
				if (pb_count[sq2_channel]) pb_reg[sq2_channel] <= echo_pb_reg;
			end
			if (note_on_reg[sq2_channel]) begin
				if (!sq2_on) begin
					if (pb_count[sq2_channel]) begin
						pb_lookup[sq2_channel] <= ((note_reg[sq2_channel]-36-2)*pb_div)+pb_reg[sq2_channel];
						sq2_freq <= sq2_freq_pb;
						pb_count[sq2_channel] <= 'b1;
						pb_old_reg[sq2_channel] <= pb_reg[sq2_channel];
					end
					else sq2_freq <= frequencies[note_reg[sq2_channel]-36];
					sq2_on <= 1;
					sq2_sent <= 0;
					if (sq1_sent) myseq <= 'd0;
					sq2_trig <= 1;
				end
				else if (pb_count[sq2_channel]) begin
						pb_lookup[sq2_channel] <= ((note_reg[sq2_channel]-36-2+blip[sq2_channel])*pb_div)+pb_reg[sq2_channel]+(vibrato2?(vib[sq2_channel]-12):0);
						if (sq2_freq != sq2_freq_pb) begin
							sq2_freq <= sq2_freq_pb;
							sq2_sent <= 0;
							if (sq1_sent) myseq <= 'd0;
							if (pb_old_reg[sq2_channel] != pb_reg[sq2_channel] && sq2_on) begin
								sq2_trig <= 0;
								pb_old_reg[sq2_channel] <= pb_reg[sq2_channel];
							end
							else if (vib[sq2_channel]-12 != 0) sq2_trig <= 0;
							else sq2_trig <= 1;
						end
					pb_count[sq2_channel] <= 'b1;
				end
				else if (vibrato2) begin
					pb_lookup[sq2_channel] <= ((note_reg[sq2_channel]-36+blip[sq2_channel])*pb_div)+(vib[sq2_channel]-12);
						if (sq2_freq != sq2_freq_pb) begin
							sq2_freq <= sq2_freq_pb;
							sq2_sent <= 0;
							if (sq1_sent) myseq <= 'd0;
							if (vib[sq2_channel]-12 != 0) sq2_trig <= 0;
							else sq2_trig <= 1;
						end
				end
				else if (sq2_freq != frequencies[note_reg[sq2_channel]-36+blip[sq2_channel]]) begin
					sq2_freq <= frequencies[note_reg[sq2_channel]-36+blip[sq2_channel]];
					sq2_sent <= 0;
					if (sq1_sent) myseq <= 'd0;
				end
				if (echo_en) begin
					if (echo_prev_vel_reg != velocity_reg[sq2_channel]) begin
						if (velocity_reg[sq2_channel]) begin
							echo_prev_vel_reg <= velocity_reg[sq2_channel];
							sq2_sent <= 0;
							if (sq1_sent) myseq <= 'd0;
							sq2_trig <= 1;
						end
						else begin
							note_on_reg[sq2_channel] <= 0;
							note_reg[sq2_channel] <= 0;
							if (sq2_on) begin
								sq2_on <= 0;
								sq2_sent <= 0;
								if (sq1_sent) myseq <= 'd0;
								sq2_trig <= 1;
							end
						end
					end
				end
				else if (velocity_reg[sq2_channel] != adjusted_vel[sq2_channel] && fade_en2 && fade_speed2 < 4) begin
					if (adjusted_vel[sq2_channel]) begin
						velocity_reg[sq2_channel] <= adjusted_vel[sq2_channel];
						sq2_sent <= 0;
						if (sq1_sent) myseq <= 'd0;
						sq2_trig <= 1;
					end
					else begin
						note_on_reg[sq2_channel] <= 0;
						note_reg[sq2_channel] <= 0;
						if (sq2_on) begin
							sq2_on <= 0;
							sq2_sent <= 0;
							if (sq1_sent) myseq <= 'd0;
							sq2_trig <= 1;
						end
					end
				end
			end
			else begin
				if (sq2_on) begin
					sq2_on <= 0;
					sq2_sent <= 0;
					if (sq1_sent) myseq <= 'd0;
					sq2_trig <= 1;
				end
			end
			if (duty_switch_en2) begin
				if (sq2_duty != duty_switch_reg[sq2_channel]) begin
					sq2_duty <= duty_switch_reg[sq2_channel];
					sq2_duty_sent <= 0;
				end
			end
			else if (modtoDuty2) begin
				if (sq2_duty != cc1_reg[sq2_channel]) begin
					sq2_duty <= cc1_reg[sq2_channel];
					sq2_duty_sent <= 0;
				end
			end
			else if (sq2_duty != duty_set2) begin
				sq2_duty <= duty_set2;
				sq2_duty_sent <= 0;
			end

			//Wave
			if (note_on_reg[wav_channel]) begin
				if (!wav_on) begin
					if (pb_count[wav_channel]) begin
						pb_lookup[wav_channel] <= ((note_reg[wav_channel]-36-2)*pb_div)+pb_reg[wav_channel];
						wav_freq <= wav_freq_pb;
						pb_count[wav_channel] <= 'b1;
						pb_old_reg[wav_channel] <= pb_reg[wav_channel];
					end
					else wav_freq <= frequencies[note_reg[wav_channel]-36];
					wav_on <= 1;
					wav_sent <= 0;
					if (wav_ram_init < 2) begin
						wav_ram_sent <= 0;
						wav_ram_init <= wav_ram_init + 'b1;
					end
					else if (waveform_reg != waveform) begin
						wav_ram_sent <= 0;
						waveform_reg <= waveform;
					end
					if (sq1_sent && sq2_sent) myseq <= 'd0;
					wav_trig <= 1;
				end
				else if (pb_count[wav_channel]) begin
						pb_lookup[wav_channel] <= ((note_reg[wav_channel]-36-2+blip[wav_channel])*pb_div)+pb_reg[wav_channel]+(vibrato3?(vib[wav_channel]-12):0)-(fall2_en?fall2_amount_reg:0);
						if (wav_freq != wav_freq_pb) begin
							wav_freq <= wav_freq_pb;
							wav_sent <= 0;
							if (sq1_sent && sq2_sent) myseq <= 'd0;
							if (pb_old_reg[wav_channel] != pb_reg[wav_channel] && wav_on) begin
								wav_trig <= 0;
								pb_old_reg[wav_channel] <= pb_reg[wav_channel];
							end
							else if (vib[wav_channel]-12 != 0) wav_trig <= 0;
							else if (fall2_amount_reg != 0) wav_trig <= 0;
							else wav_trig <= 1;
						end
					pb_count[wav_channel] <= 'b1;
				end
				else if (vibrato3) begin
					pb_lookup[wav_channel] <= ((note_reg[wav_channel]-36+blip[wav_channel])*pb_div)+(vib[wav_channel]-12)-(fall2_en?fall2_amount_reg:0);
						if (wav_freq != wav_freq_pb) begin
							wav_freq <= wav_freq_pb;
							wav_sent <= 0;
							if (sq1_sent && sq2_sent) myseq <= 'd0;
							if (vib[wav_channel]-12 != 0) wav_trig <= 0;
							else if (fall2_amount_reg != 0) wav_trig <= 0;
							else wav_trig <= 1;
						end
				end
				else if (fall2_en) begin
					pb_lookup[wav_channel] <= ((note_reg[wav_channel]-36+blip[wav_channel])*pb_div)-fall2_amount_reg;
						if (wav_freq != wav_freq_pb) begin
							wav_freq <= wav_freq_pb;
							wav_sent <= 0;
							if (sq1_sent && sq2_sent) myseq <= 'd0;
							if (fall2_amount_reg != 0) wav_trig <= 0;
							else wav_trig <= 1;
						end
				end
				else if (wav_freq != frequencies[note_reg[wav_channel]-36+blip[wav_channel]]) begin
					wav_freq <= frequencies[note_reg[wav_channel]-36+blip[wav_channel]];
					wav_sent <= 0;
					if (sq1_sent && sq2_sent) myseq <= 'd0;
				end
				if (velocity_reg[wav_channel] != adjusted_vel[wav_channel] && fade_en3) begin
					//if (adjusted_vel[wav_channel]) begin
						velocity_reg[wav_channel] <= adjusted_vel[wav_channel];
						wav_sent <= 0;
						if (sq1_sent && sq2_sent) myseq <= 'd0;
						wav_trig <= 1;
					//end
					/*else begin
						note_on_reg[wav_channel] <= 0;
						note_reg[wav_channel] <= 0;
						if (wav_on) begin
							wav_on <= 0;
							wav_sent <= 0;
							if (sq1_sent && sq2_sent) myseq <= 'd0;
							wav_trig <= 1;
						end
					end*/
				end
			end
			else begin
				if (wav_on) begin
					wav_on <= 0;
					wav_sent <= 0;
					if (sq1_sent && sq2_sent) myseq <= 'd0;
					wav_trig <= 1;
				end
			end

			///Noise
			if (note_on_reg[noi_channel]) begin
				if (!noi_on) begin
					noi_freq <= (63-(note_reg[noi_channel]-36));
					noi_on <= 1;
					noi_sent <= 0;
					if (sq1_sent && sq2_sent && wav_sent) myseq <= 'd0;
					noi_trig <= 1;
				end
				else if (noi_freq != (63-(note_reg[noi_channel]-36-(fall_en?fall_amount_reg:0)))) begin
					noi_freq <= (63-(note_reg[noi_channel]-36-(fall_en?fall_amount_reg:0)));
					noi_sent <= 0;
					if (sq1_sent && sq2_sent && wav_sent) myseq <= 'd0;
					if (old_note_reg[noi_channel] != note_reg[noi_channel]) begin
						noi_trig <= 1;
						old_note_reg[noi_channel] <= note_reg[noi_channel];
					end
					else noi_trig <= 0;
				end
				if (velocity_reg[noi_channel] != adjusted_vel[noi_channel] && fade_en4 && fade_speed4 < 4) begin
					if (adjusted_vel[noi_channel]) begin
						velocity_reg[noi_channel] <= adjusted_vel[noi_channel];
						noi_sent <= 0;
						if (sq1_sent && sq2_sent && wav_sent) myseq <= 'd0;
						noi_trig <= 1;
					end
					else begin
						note_on_reg[noi_channel] <= 0;
						note_reg[noi_channel] <= 0;
						if (noi_on) begin
							noi_on <= 0;
							noi_sent <= 0;
							if (sq1_sent && sq2_sent && wav_sent) myseq <= 'd0;
							noi_trig <= 1;
						end
					end
				end
			end
			else begin
				if (noi_on) begin
					noi_on <= 0;
					noi_sent <= 0;
					if (sq1_sent && sq2_sent && wav_sent) myseq <= 'd0;
					noi_trig <= 1;
				end
			end
		end
		else if (!echo_en) begin ////AUTO-POLY////
			if (Pinit) begin
				for (int ii = 0; ii < max; ii = ii + 1) begin
					if (poly_note_on_reg[sq1_channel][ii+ii]) begin
						if (!sq1_onP[ii]) begin
							if (pb_count[sq1_channel] && ((pb_reg[sq1_channel] > 'd256) || (pb_reg[sq1_channel] < 'd256))) begin
								poly_pb_lookup[sq1_channel][ii+ii] <= ((poly_note_reg[sq1_channel][ii+ii]-36-2)*pb_div)+pb_reg[sq1_channel]; //map function used to make LUT: (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
								sq1_freqP[ii] <= sq1_freq_pbP[ii];
								pb_old_reg[sq1_channel] <= pb_reg[sq1_channel];
								pb_count[sq1_channel] <= 'b1;
							end
							else sq1_freqP[ii] <= frequencies[poly_note_reg[sq1_channel][ii+ii]-36];
							sq1_onP[ii] <= 1;
							sq1_sentP[ii] <= 0;
							if (sq2_sentP[ii]) myseqP[ii] <= 'd0;
							sq1_trigP[ii] <= 1;
						end
						else if (pb_count[sq1_channel]) begin
							poly_pb_lookup[sq1_channel][ii+ii] <= ((poly_note_reg[sq1_channel][ii+ii]-36-2+poly_blip[sq1_channel][ii+ii])*pb_div)+pb_reg[sq1_channel]+(vibrato?(poly_vib[sq1_channel][ii+ii]-12):0);
							if (sq1_freqP[ii] != sq1_freq_pbP[ii]) begin
								sq1_freqP[ii] <= sq1_freq_pbP[ii];
								sq1_sentP[ii] <= 0;
								if (sq2_sentP[ii]) myseqP[ii] <= 'd0;
								if (pb_old_reg[sq1_channel] != pb_reg[sq1_channel] && sq1_onP[ii]) begin
									sq1_trigP[ii] <= 0;
									pb_old_reg[sq1_channel] <= pb_reg[sq1_channel];
								end
								else if (poly_vib[sq1_channel][ii+ii]-12 != 0) sq1_trigP[ii] <= 0;
								else sq1_trigP[ii] <= 1;
							end
							pb_count[sq1_channel] <= 'b1;
						end
						else if (vibrato) begin
							poly_pb_lookup[sq1_channel][ii+ii] <= ((poly_note_reg[sq1_channel][ii+ii]-36+poly_blip[sq1_channel][ii+ii])*pb_div)+(poly_vib[sq1_channel][ii+ii]-12);
							if (sq1_freqP[ii] != sq1_freq_pbP[ii]) begin
								sq1_freqP[ii] <= sq1_freq_pbP[ii];
								sq1_sentP[ii] <= 0;
								if (sq2_sentP[ii]) myseqP[ii] <= 'd0;
								if (poly_vib[sq1_channel][ii+ii]-12 != 0) sq1_trigP[ii] <= 0;
								else sq1_trigP[ii] <= 1;
							end
						end
						else if (sq1_freqP[ii] != frequencies[poly_note_reg[sq1_channel][ii+ii]-36+poly_blip[sq1_channel][ii+ii]]) begin
							sq1_freqP[ii] <= frequencies[poly_note_reg[sq1_channel][ii+ii]-36+poly_blip[sq1_channel][ii+ii]];
							sq1_sentP[ii] <= 0;
							if (sq2_sentP[ii]) myseqP[ii] <= 'd0;
							sq1_trigP[ii] <= 1;
						end
						if (poly_repeat_note[sq1_channel][ii+ii]) begin
							sq1_sentP[ii] <= 0;
							if (sq2_sentP[ii]) myseqP[ii] <= 'd0;
							sq1_trigP[ii] <= 1;
							poly_repeat_note[sq1_channel][ii+ii] <= 0;
						end
						if (poly_velocity_reg[sq1_channel][ii+ii] != poly_adjusted_vel[sq1_channel][ii+ii] && fade_en && fade_speed < 4) begin
							if (poly_adjusted_vel[sq1_channel][ii+ii]) begin
								poly_velocity_reg[sq1_channel][ii+ii] <= poly_adjusted_vel[sq1_channel][ii+ii];
								sq1_sentP[ii] <= 0;
								if (sq2_sentP[ii]) myseqP[ii] <= 'd0;
								sq1_trigP[ii] <= 1;
							end
							else begin
								poly_note_on_reg[sq1_channel][ii+ii] <= 0;
								if (sq1_onP[ii]) begin
									sq1_sentP[ii] <= 0;
									if (sq2_sentP[ii]) myseqP[ii] <= 'd0;
									sq1_trigP[ii] <= 1;
									sq1_onP[ii] <= 0;
								end
							end
						end
					end
					else begin
						if (sq1_onP[ii]) begin
							sq1_onP[ii] <= 0;
							sq1_sentP[ii] <= 0;
							if (sq2_sentP[ii]) myseqP[ii] <= 'd0;
							sq1_trigP[ii] <= 1;
						end
					end
					if (duty_switch_en) begin
						if (sq1_dutyP[ii] != poly_duty_switch_reg[sq1_channel][ii+ii]) begin
							sq1_dutyP[ii] <= poly_duty_switch_reg[sq1_channel][ii+ii];
							sq1_duty_sentP[ii] <= 0;
						end
					end
					else if (modtoDuty && sq1_dutyP[ii] != cc1_reg[sq1_channel]) begin
						sq1_dutyP[ii] <= cc1_reg[sq1_channel];
						sq2_dutyP[ii] <= cc1_reg[sq1_channel];
						sq1_duty_sentP[ii] <= 0;
						sq2_duty_sentP[ii] <= 0;
					end
					else if (sq1_dutyP[ii] != duty_set) begin
						sq1_dutyP[ii] <= duty_set;
						sq1_duty_sentP[ii] <= 0;
						sq2_dutyP[ii] <= duty_set;
						sq2_duty_sentP[ii] <= 0;
					end
					if (poly_note_on_reg[sq1_channel][ii+ii+1]) begin
						if (!sq2_onP[ii]) begin
							if (pb_count[sq1_channel] && ((pb_reg[sq1_channel] > 'd256) || (pb_reg[sq1_channel] < 'd256))) begin
								poly_pb_lookup[sq1_channel][ii+ii+1] <= ((poly_note_reg[sq1_channel][ii+ii+1]-36-2)*pb_div)+pb_reg[sq1_channel];
								sq2_freqP[ii] <= sq2_freq_pbP[ii];
								pb_old_reg[sq1_channel] <= pb_reg[sq1_channel];
								pb_count[sq1_channel] <= 'b1;
							end
							else sq2_freqP[ii] <= frequencies[poly_note_reg[sq1_channel][ii+ii+1]-36];
							sq2_onP[ii] <= 1;
							sq2_sentP[ii] <= 0;
							if (sq1_sentP[ii]) myseqP[ii] <= 'd0;
							sq2_trigP[ii] <= 1;
						end
						else if (pb_count[sq1_channel]) begin
							poly_pb_lookup[sq1_channel][ii+ii+1] <= ((poly_note_reg[sq1_channel][ii+ii+1]-36-2+poly_blip[sq1_channel][ii+ii+1])*pb_div)+pb_reg[sq1_channel]+(vibrato?(poly_vib[sq1_channel][ii+ii+1]-12):0);
							if (sq2_freqP[ii] != sq2_freq_pbP[ii]) begin
								sq2_freqP[ii] <= sq2_freq_pbP[ii];
								sq2_sentP[ii] <= 0;
								if (sq1_sentP[ii]) myseqP[ii] <= 'd0;
								if (pb_old_reg[sq1_channel] != pb_reg[sq1_channel] && sq2_onP[ii]) begin
									sq2_trigP[ii] <= 0;
									pb_old_reg[sq1_channel] <= pb_reg[sq1_channel];
								end
								else if (poly_vib[sq1_channel][ii+ii+1]-12 != 0) sq2_trigP[ii] <= 0;
								else sq2_trigP[ii] <= 1;
							end
							pb_count[sq1_channel] <= 'b1;
						end
						else if (vibrato) begin
							poly_pb_lookup[sq1_channel][ii+ii+1] <= ((poly_note_reg[sq1_channel][ii+ii+1]-36+poly_blip[sq1_channel][ii+ii+1])*pb_div)+(poly_vib[sq1_channel][ii+ii+1]-12);
							if (sq2_freqP[ii] != sq2_freq_pbP[ii]) begin
								sq2_freqP[ii] <= sq2_freq_pbP[ii];
								sq2_sentP[ii] <= 0;
								if (sq1_sentP[ii]) myseqP[ii] <= 'd0;
								if (poly_vib[sq1_channel][ii+ii+1]-12 != 0) sq2_trigP[ii] <= 0;
								else sq2_trigP[ii] <= 1;
							end
						end
						else if (sq2_freqP[ii] != frequencies[poly_note_reg[sq1_channel][ii+ii+1]-36+poly_blip[sq1_channel][ii+ii+1]]) begin
							sq2_freqP[ii] <= frequencies[poly_note_reg[sq1_channel][ii+ii+1]-36+poly_blip[sq1_channel][ii+ii+1]];
							sq2_sentP[ii] <= 0;
							if (sq1_sentP[ii]) myseqP[ii] <= 'd0;
							sq2_trigP[ii] <= 1;
						end
						if (poly_repeat_note[sq1_channel][ii+ii+1]) begin
							sq2_sentP[ii] <= 0;
							if (sq1_sentP[ii]) myseqP[ii] <= 'd0;
							sq2_trigP[ii] <= 1;
							poly_repeat_note[sq1_channel][ii+ii+1] <= 0;
						end
						if (poly_velocity_reg[sq1_channel][ii+ii+1] != poly_adjusted_vel[sq1_channel][ii+ii+1] && fade_en && fade_speed < 4) begin
							if (poly_adjusted_vel[sq1_channel][ii+ii+1]) begin
								poly_velocity_reg[sq1_channel][ii+ii+1] <= poly_adjusted_vel[sq1_channel][ii+ii+1];
								sq2_sentP[ii] <= 0;
								if (sq1_sentP[ii]) myseqP[ii] <= 'd0;
								sq2_trigP[ii] <= 1;
							end
							else begin
								poly_note_on_reg[sq1_channel][ii+ii+1] <= 0;
								if (sq2_onP[ii]) begin
									sq2_sentP[ii] <= 0;
									if (sq1_sentP[ii]) myseqP[ii] <= 'd0;
									sq2_trigP[ii] <= 1;
									sq2_onP[ii] <= 0;
								end
							end
						end
					end
					else begin
						if (sq2_onP[ii]) begin
							sq2_sentP[ii] <= 0;
							if (sq1_sentP[ii]) myseqP[ii] <= 'd0;
							sq2_trigP[ii] <= 1;
							sq2_onP[ii] <= 0;
						end
					end
					if (duty_switch_en) begin
						if (sq2_dutyP[ii] != poly_duty_switch_reg[sq1_channel][ii+ii+1]) begin
							sq2_dutyP[ii] <= poly_duty_switch_reg[sq1_channel][ii+ii+1];
							sq2_duty_sentP[ii] <= 0;
						end
					end
				end
			end
		end
		///////////SEQUENCING/////////
		if (!auto_poly) begin ///VOICE PER CHANNEL
			if (!wav_ram_sent) begin
				if (!audio_wr) begin
					if (!wav_ram_start) begin
						myaddress <= 7'h1A; //NR30 FF1A E--- ---- DAC power
						myvalue <= 0;
						audio_wr <= 1;
						wav_ram_start <= 1;
						wav_ram_count <= 0;
						wav_ram_end <= 0;
					end
					else if (wav_ram_count < 'd16) begin //FF30 to FF3F
						myaddress <= wav_ram_count+48; //NR21 FF16 DDLL LLLL Duty, Length load (64-L)
						case(waveform_reg)
							'd0: begin
								myvalue <= (wave_bass[wav_ram_count+wav_ram_count]<<4) + wave_bass[wav_ram_count+wav_ram_count+1];
							end
							'd1: begin
								myvalue <= (wave_lead[wav_ram_count+wav_ram_count]<<4) + wave_lead[wav_ram_count+wav_ram_count+1];
							end
							'd2: begin
								myvalue <= (wave_triangle[wav_ram_count+wav_ram_count]<<4) + wave_triangle[wav_ram_count+wav_ram_count+1];
							end
							'd3: begin
								myvalue <= (wave_saw[wav_ram_count+wav_ram_count]<<4) + wave_saw[wav_ram_count+wav_ram_count+1];
							end
							'd4: begin
								myvalue <= (wave_square[wav_ram_count+wav_ram_count]<<4) + wave_square[wav_ram_count+wav_ram_count+1];
							end
						endcase
						audio_wr <= 1;
						wav_ram_count <= wav_ram_count + 'b1;
					end
					else begin
						if (!wav_ram_end) begin
							myaddress <= 7'h1A; //NR30 FF1A E--- ---- DAC power
							myvalue <= 8'b10000000;
							audio_wr <= 1;
							wav_ram_end <= 1;
						end
						else begin
							wav_ram_sent <= 1;
							wav_ram_start <= 0;
						end
					end
				end
				else audio_wr <= 0;
			end
			else case(myseq)
				'd0 : begin
					if (!audio_wr) begin
						if (!sq1_sent) begin
							myaddress <= 7'h12; //NR12 FF12 VVVV APPP Starting volume, Envelope direction, Env speed
							if (sq1_on) begin
								myvalue <= (velocity_reg[sq1_channel]<<4)+(fade_en?(fade_speed>3?'d7-(fade_speed-3):0):0);
							end
							else if (mono_kill) myvalue <= 0;
							else myvalue <= 8'b00001000;
							myseq <= 'd1;
							audio_wr <= 1;
						end
						else if (!sq2_sent) begin
							myaddress <= 7'h17; //NR22 FF17 VVVV APPP Starting volume, Envelope direction, Env speed
							if (sq2_on) begin
								myvalue <= (velocity_reg[sq2_channel]<<4)+(fade_en2?(fade_speed2>3?'d7-(fade_speed2-3):0):0);
							end
							else if (mono_kill) myvalue <= 0;
							else myvalue <= 8'b00001000;
							myseq <= 'd1;
							audio_wr <= 1;
						end
						else if (!wav_sent) begin
							if (mono_kill || wav_dac_en) begin
								myaddress <= 7'h1A; //NR30 FF1A E--- ---- DAC power
								if (mono_kill) myvalue <= 0;
								else begin
									myvalue <= 8'b10000000;
									wav_dac_en <= 0;
								end
							end
							else begin 
								myaddress <= 7'h1C; //NR32 FF1C -VV- ---- Volume code (00=0%, 01=100%, 10=50%, 11=25%)
								if (wav_on) begin
									if (velocity_reg[wav_channel] > 'd10) myvalue <= 8'b00100000;
									else if (velocity_reg[wav_channel] > 'd5) myvalue <= 8'b01000000;
									else if (velocity_reg[wav_channel]) myvalue <= 8'b01100000;
									else myvalue <= 8'b00000000;
									//(2'b11 - (velocity_reg[wav_channel]>>2));//<<4)+(fade_en2?(fade_speed2>3?'d7-(fade_speed2-3):0):0);
								end
								else myvalue <= 8'b00000000;
							end
							myseq <= 'd1;
							audio_wr <= 1;
						end
						else if (!noi_sent) begin
							myaddress <= 7'h21; //NR42 FF21 VVVV APPP Starting volume, Envelope direction, Env speed
							if (noi_on) begin
								myvalue <= (velocity_reg[noi_channel]<<4)+(fade_en4?(fade_speed4>3?'d7-(fade_speed4-3):0):0);
							end
							else if (mono_kill) myvalue <= 0;
							else myvalue <= 8'b00001000;
							myseq <= 'd1;
							audio_wr <= 1;
						end
					end
					else audio_wr <= 0;
				end
				'd1 : begin
					if (!audio_wr) begin
						if (!sq1_sent) begin
							myaddress <= 7'h13; //NR13 FF13 FFFF FFFF Frequency LSB
							myvalue <= sq1_freq[7:0];
							myseq <= 'd2;
							audio_wr <= 1;
						end
						else if (!sq2_sent) begin
							myaddress <= 7'h18; //NR23 FF18 FFFF FFFF Frequency LSB
							myvalue <= sq2_freq[7:0];
							myseq <= 'd2;
							audio_wr <= 1;
						end
						else if (!wav_sent) begin
							myaddress <= 7'h1D; //NR33 FF1D FFFF FFFF Frequency LSB
							myvalue <= wav_freq[7:0];
							myseq <= 'd2;
							audio_wr <= 1;
						end
						else if (!noi_sent) begin
							myaddress <= 7'h22; //NR43 FF22 SSSS WDDD Clock shift, Width mode of LFSR, Divisor code
							myvalue <= (noi_freq[5:2]<<4)+(noi_type<<3)+(1'b1<<2)+noi_freq[1:0];
							myseq <= 'd2;
							audio_wr <= 1;
						end
					end
					else audio_wr <= 0;
				end
				'd2 : begin
					if (!audio_wr) begin
						if (!sq1_sent) begin
							myaddress <= 7'h14; //NR14 FF14 TL-- -FFF Trigger, Length enable, Frequency MSB
							if (!sq1_trig) begin
								myvalue <= sq1_freq[10:8];
								sq1_trig <= 1;
							end
							else myvalue <= (8'b10000000 + sq1_freq[10:8]);
							sq1_sent <= 1;
							if (!sq2_sent || !wav_sent || !noi_sent) myseq <= 'd0;
							audio_wr <= 1;
						end
						else if (!sq2_sent) begin
							myaddress <= 7'h19; //NR24 FF19 TL-- -FFF Trigger, Length enable, Frequency MSB
							if (!sq2_trig) begin
								myvalue <= sq2_freq[10:8];
								sq2_trig <= 1;
							end
							else myvalue <= (8'b10000000 + sq2_freq[10:8]);
							sq2_sent <= 1;
							if (!sq1_sent || !wav_sent || !noi_sent) myseq <= 'd0;
							audio_wr <= 1;
						end
						else if (!wav_sent) begin
							myaddress <= 7'h1E; //NR34 FF1E TL-- -FFF Trigger, Length enable, Frequency MSB
							if (!wav_trig) begin
								myvalue <= wav_freq[10:8];
								wav_trig <= 1;
							end
							else myvalue <= (8'b10000000 + wav_freq[10:8]);
							wav_sent <= 1;
							if (!sq1_sent || !sq2_sent || !noi_sent) myseq <= 'd0;
							audio_wr <= 1;
						end
						else if (!noi_sent) begin
							myaddress <= 7'h23; //NR44 FF23 TL-- ---- Trigger, Length enable
							myvalue <= noi_trig<<7;
							noi_sent <= 1;
							if (!sq1_sent || !sq2_sent || !wav_sent) myseq <= 'd0;
							audio_wr <= 1;
						end
					end
					else audio_wr <= 0;
				end
			endcase
			if (sq1_sent && sq2_sent && noi_sent && wav_sent) begin
				if (!audio_wr) begin
					if (!sq1_duty_sent) begin
						myaddress <= 7'h11; //NR11 FF11 DDLL LLLL Duty, Length load (64-L)
						myvalue <= sq1_duty << 6;
						sq1_duty_sent <= 1;
						audio_wr <= 1;
						//myseq <= 3'b011;
					end
					else if (!sq2_duty_sent) begin
						myaddress <= 7'h16; //NR21 FF16 DDLL LLLL Duty, Length load (64-L)
						myvalue <= sq2_duty << 6;
						sq2_duty_sent <= 1;
						audio_wr <= 1;
					end
				end
				else audio_wr <= 0;
			end
		end
		else begin ////AUTO-POLY////
			if (Pinit) begin
				for (int ii = 0; ii < max; ii = ii + 1) begin
					case(myseqP[ii])
						'd0: begin
							if (!audio_wrP[ii]) begin
								if (!sq1_sentP[ii]) begin
									myaddressP[ii] <= 7'h12; //NR12 FF12 VVVV APPP Starting volume, Envelope enable, Env speed
									if (sq1_onP[ii]) begin
										myvalueP[ii] <= (poly_velocity_reg[sq1_channel][ii+ii]<<4)+(fade_en?(fade_speed>3?'d7-(fade_speed-3):0):0);
									end
									else if (poly_kill) myvalueP[ii] <= 0;
									else myvalueP[ii] <= 8'b00001000;
									myseqP[ii] <= 'd1;
									audio_wrP[ii] <= 1;
								end
								else if (!sq2_sentP[ii]) begin
									myaddressP[ii] <= 7'h17; //NR22 FF17 VVVV APPP Starting volume, Envelope enable, Env speed
									if (sq2_onP[ii]) begin
										myvalueP[ii] <= (poly_velocity_reg[sq1_channel][ii+ii+1]<<4)+(fade_en?(fade_speed>3?'d7-(fade_speed-3):0):0);
									end
									else if (poly_kill) myvalueP[ii] <= 0;
									else myvalueP[ii] <= 8'b00001000;
									myseqP[ii] <= 'd1;
									audio_wrP[ii] <= 1;
								end
							end
							else audio_wrP[ii] <= 0;
						end
						'd1 : begin
							if (!audio_wrP[ii]) begin
								if (!sq1_sentP[ii]) begin
									myaddressP[ii] <= 7'h13; //NR13 FF13 FFFF FFFF Frequency LSB
									myvalueP[ii] <= sq1_freqP[ii][7:0];
									myseqP[ii] <= 'd2;
									audio_wrP[ii] <= 1;
								end
								else if (!sq2_sentP[ii]) begin
									myaddressP[ii] <= 7'h18; //NR23 FF18 FFFF FFFF Frequency LSB
									myvalueP[ii] <= sq2_freqP[ii][7:0];
									myseqP[ii] <= 'd2;
									audio_wrP[ii] <= 1;
								end
							end
							else audio_wrP[ii] <= 0;
						end
						'd2 : begin
							if (!audio_wrP[ii]) begin
								if (!sq1_sentP[ii]) begin
									myaddressP[ii] <= 7'h14; //NR14 FF14 TL-- -FFF Trigger, Length enable, Frequency MSB
									if (!sq1_trigP[ii]) begin
										myvalueP[ii] <= sq1_freqP[ii][10:8];
										sq1_trigP[ii] <= 1;
									end
									else myvalueP[ii] <= (8'b10000000 + sq1_freqP[ii][10:8]);
									sq1_sentP[ii] <= 1;
									if (!sq2_sentP[ii]) myseqP[ii] <= 'd0;
									audio_wrP[ii] <= 1;
								end
								else if (!sq2_sentP[ii]) begin
									myaddressP[ii] <= 7'h19; //NR24 FF19 TL-- -FFF Trigger, Length enable, Frequency MSB
									if (!sq2_trigP[ii]) begin
										myvalueP[ii] <= sq2_freqP[ii][10:8];
										sq2_trigP[ii] <= 1;
									end
									else myvalueP[ii] <= (8'b10000000 + sq2_freqP[ii][10:8]);
									sq2_sentP[ii] <= 1;
									if (!sq1_sentP[ii]) myseqP[ii] <= 'd0;
									audio_wrP[ii] <= 1;
								end
							end
							else audio_wrP[ii] <= 0;
						end
					endcase
					if (sq1_sentP[ii] && sq2_sentP[ii]) begin
						if (!audio_wrP[ii]) begin
							if (!sq1_duty_sentP[ii]) begin
								myaddressP[ii] <= 7'h11; //NR11 FF11 DDLL LLLL Duty, Length load (64-L)
								myvalueP[ii] <= sq1_dutyP[ii] << 6;
								sq1_duty_sentP[ii] <= 1;
								audio_wrP[ii] <= 1;
							end
							else if (!sq2_duty_sentP[ii]) begin
								myaddressP[ii] <= 7'h16; //NR21 FF16 DDLL LLLL Duty, Length load (64-L)
								myvalueP[ii] <= sq2_dutyP[ii] << 6;
								sq2_duty_sentP[ii] <= 1;
								audio_wrP[ii] <= 1;
							end
						end
						else audio_wrP[ii] <= 0;
					end
				end
			end
		end
	end
end

reg [3:0] adjusted_vel[0:15];
envelope envelope (
	.clk			(clk),
	.en (fade_en),
	.decay (fade_speed),
	.note_on (note_on_reg[sq1_channel]),
	.note_start (note_reg[sq1_channel]),
	.vel_start (velocity_reg[sq1_channel]),
	.adjusted_vel (adjusted_vel[sq1_channel])
);
envelope envelope2 (
	.clk			(clk),
	.en (fade_en2),
	.decay (fade_speed2),
	.note_on (note_on_reg[sq2_channel]),
	.note_start (note_reg[sq2_channel]),
	.vel_start (velocity_reg[sq2_channel]),
	.adjusted_vel (adjusted_vel[sq2_channel])
);
envelopeW envelope3 (
	.clk			(clk),
	.en (fade_en3),
	.decay (fade_speed3),
	.note_on (note_on_reg[wav_channel]),
	.note_start (note_reg[wav_channel]),
	.vel_start (velocity_reg[wav_channel]),
	.adjusted_vel (adjusted_vel[wav_channel])
);
envelope envelopenoise (
	.clk			(clk),
	.en (fade_en4),
	.decay (fade_speed4),
	.note_on (note_on_reg[noi_channel]),
	.note_start (note_reg[noi_channel]),
	.vel_start (velocity_reg[noi_channel]),
	.adjusted_vel (adjusted_vel[noi_channel])
);

midipb_to_gbfreq_LUT midipb_to_gbfreq_LUT (
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
);

reg [8:0] vib[0:15];
vibrato_gen vibrato_gen (
	.en (vibrato),
	.clk (clk),
	.note_on (note_on_reg[sq1_channel]),
	.note_start (note_reg[sq1_channel]),
	.vib_out (vib[sq1_channel])
);
vibrato_gen vibrato_gen2 (
	.en (vibrato2),
	.clk (clk),
	.note_on (note_on_reg[sq2_channel]),
	.note_start (note_reg[sq2_channel]),
	.vib_out (vib[sq2_channel])
);
vibrato_gen vibrato_gen3 (
	.en (vibrato3),
	.clk (clk),
	.note_on (note_on_reg[wav_channel]),
	.note_start (note_reg[wav_channel]),
	.vib_out (vib[wav_channel])
);

reg [1:0] duty_switch_reg[0:15];
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
);

reg echo_note_on_reg;
reg [6:0] echo_note_reg;
reg [3:0] echo_velocity_reg;
reg [3:0] echo_prev_vel_reg;
reg [8:0] echo_pb_reg;
echo_gen echo_gen (
	.en (echo_en),
	.clk (clk),
	.note_on (note_on_reg[sq1_channel]),
	.note_start (note_reg[sq1_channel]),
	.vel_start (velocity_reg[sq1_channel]),
	.pb_start (pb_reg[sq1_channel]),
	.echo_on (echo_note_on_reg),
	.echo_note (echo_note_reg),
	.echo_vel (echo_velocity_reg),
	.echo_pb (echo_pb_reg)
);

reg [3:0] blip[0:15];
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
);

wire [15:0] audio_l1;
wire [15:0] audio_r1;

gbc_snd audio (
	.clk			(clk),
	.ce             (ce_2x),
	.reset			(reset),

	.is_gbc         (0),

	.s1_read  		(0),
	.s1_write 		(audio_wr),
	.s1_addr    	(myaddress),
    .s1_readdata 	(snd_d_out),
	.s1_writedata   (myvalue),

    .snd_left 		(audio_l1),
	.snd_right  	(audio_r1)
);

reg [3:0] poly_adjusted_vel[0:15][0:max+max-1];
reg [8:0] poly_vib[0:15][0:max+max-1];
reg [1:0] poly_duty_switch_reg[0:15][0:max+max-1];
reg [3:0] poly_blip[0:15][0:max+max-1];

wire [15:0] audio_lP[0:max-1];
wire [15:0] audio_rP[0:max-1];
wire [15:0] audio_combined_l[0:max];
wire [15:0] audio_combined_r[0:max];

wire [255:0] poly_note_out_combined[0:max];

generate
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
			.ce             (ce_2x),
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
			.ce_2x (ce_2x),
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
endgenerate

assign audio_l = audio_l1 + audio_combined_l[max];
assign audio_r = audio_r1 + audio_combined_r[max];

endmodule
