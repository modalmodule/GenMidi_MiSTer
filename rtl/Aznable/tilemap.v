`timescale 1ps / 1ps
/*============================================================================
	Aznable (custom 8-bit computer system) - Zechs (tilemap)

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 0.1
	Date: 2022-01-04

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

module tilemap #(
	parameter TILEMAP_ROM_WIDTH = 15,
	parameter TILEMAP_RAM_WIDTH = 10,
	parameter [9:0] TILEMAP_WIDTH = 10'd352,
	parameter [9:0] TILEMAP_HEIGHT = 10'd272,
	parameter [9:0] TILEMAP_BORDER = 10'd16,
	parameter [4:0] TILEMAP_CELLS_X = 5'd22,
	parameter [4:0] TILEMAP_CELLS_Y = 5'd17
)(
	input				clk,
	input				reset,
	input				pause,
	input		[8:0]	hcnt,
	input		[8:0]	vcnt,
	input				hblank,

	input		[1:0]	addr,
	input		[7:0]	data_in,
	input				write,
	
	input		[15:0]	tilemaprom_data_out,
	input		[7:0]	tilemapram_data_out,
	output		[7:0]	tilemapcontrol_data_out,
	output reg 	[TILEMAP_RAM_WIDTH-1:0]	tilemapram_addr,
	output reg	[TILEMAP_ROM_WIDTH-1:0]	tilemaprom_addr,
	output reg			tilemapram_ctl_wr,
	output reg	[7:0]	tilemapram_ctl_data_in,

	output reg [7:0]	tilemap_r,
	output reg [7:0]	tilemap_g,
	output reg [7:0]	tilemap_b,
	output reg			tilemap_a
);

// Tilemap control registers
// 0 - Tilemap offset X (signed)
// 1 - Tilemap offset Y (signed)
// 2 - Tilemap control trigger
// 		-> 0 = IDLE
//		-> 1 = SCROLL LEFT
//		-> 2 = SCROLL RIGHT
//		-> 3 = SCROLL UP
//		-> 4 = SCROLL DOWN
//		-> 5 = CLEAR
reg [7:0]	tilemapreg [3:0]; 
assign tilemapcontrol_data_out = tilemapreg[addr];

// Current tilemap read positions
reg [9:0] tilemap_pos_x;
reg [9:0] tilemap_pos_y;

// Current tilemap scroll offsets
/* verilator lint_off WIDTH */
wire signed [9:0] tilemap_offset_x = $signed(tilemapreg[0]); // Convert scroll control x register to signed
wire signed [9:0] tilemap_offset_y = $signed(tilemapreg[1]); // Convert scroll control y register to signed
/* verilator lint_on WIDTH */

// Tilemap read machine state
reg [1:0]	tilemap_read_state;
reg [15:0]	tilemap_read_cycles;

// Tilemap control state constants
localparam TM_CTL_IDLE = 0;
localparam TM_CTL_SCROLL = 1;
localparam TM_CTL_CLEAR = 2;

// Tilemap control machine
reg  [2:0] tilemap_ctl_state;
reg  [4:0] tilemap_ctl_x;
reg  [4:0] tilemap_ctl_y;
reg [15:0] tilemap_ctl_cycles;
reg  [8:0] tilemap_ctl_hstart;
reg  [8:0] tilemap_ctl_vstart;

// Tilemap scroll state constants
localparam TM_SCROLL_START = 0;
localparam TM_SCROLL_WAIT = 1;
localparam TM_SCROLL_GETINDEX = 2;
localparam TM_SCROLL_SETINDEX = 3;

// Tilemap scroll control
reg [4:0]	tilemap_scroll_state;
reg [4:0]	tilemap_scroll_state_next;
reg [4:0]	tilemap_scroll_start_pos;
reg [4:0]	tilemap_scroll_target_pos;
reg			tilemap_scroll_axis;
reg			tilemap_scroll_dir;

// Tilemap clear state constants
localparam TM_CLEAR_PREP = 0;
localparam TM_CLEAR_WRITE = 1;
localparam TM_CLEAR_DONE = 2;

// Tilemap clear control
reg [2:0]	tilemap_clear_state;

reg [8:0] hcnt_last;
reg 	  hblank_last;

//`define TM_DEBUG

always @(posedge clk) begin

	hblank_last <= hblank;

	if(reset)
	begin
		// Reset tilemap control registers
		tilemapreg[0] <= 8'b0;
		tilemapreg[1] <= 8'b0;
		tilemapreg[2] <= 8'b0;
		tilemapreg[3] <= 8'b0;
		tilemap_read_state <= 2'b0;

		// Start tilemap clear process
		tilemap_clear_state <= TM_CLEAR_PREP;
		tilemap_ctl_x = 5'd0;
		tilemap_ctl_y = 5'd0;
		tilemap_ctl_state <= TM_CTL_CLEAR;
	end
	else
	begin

		if(write)
		begin
			// Write tilemap control data from CPU
			tilemapreg[addr[1:0]] <= data_in;

			// If control trigger is set and control state machine is idle
			if(addr[1:0] == 2'd2 && tilemap_ctl_state == TM_CTL_IDLE)
			begin
`ifdef TM_DEBUG
				$display("TM WRITE: a=%x d=%x", addr[1:0], data_in);
`endif
				case(data_in)
					8'd1: // SCROLL LEFT
					begin
						tilemap_scroll_dir <= 1'b0;
						tilemap_scroll_axis <= 1'b0;
						tilemap_scroll_start_pos = 5'd1;
						tilemap_scroll_target_pos = TILEMAP_CELLS_X - 5'd1;
						tilemap_scroll_state <= TM_SCROLL_START;
						tilemap_ctl_x = tilemap_scroll_start_pos;
						tilemap_ctl_y = 5'd0;
						tilemap_ctl_state <= TM_CTL_SCROLL;
						tilemap_ctl_hstart <= hcnt;
						tilemap_ctl_vstart <= vcnt;
					end
					8'd2: // SCROLL RIGHT
					begin
						tilemap_scroll_dir <= 1'b1;
						tilemap_scroll_axis <= 1'b0;
						tilemap_scroll_start_pos = TILEMAP_CELLS_X - 5'd2;
						tilemap_scroll_target_pos = 5'd0;
						tilemap_scroll_state <= TM_SCROLL_START;
						tilemap_ctl_x = tilemap_scroll_start_pos;
						tilemap_ctl_y = 5'd0;
						tilemap_ctl_state <= TM_CTL_SCROLL;
						tilemap_ctl_hstart <= hcnt;
						tilemap_ctl_vstart <= vcnt;
					end
					8'd3: // SCROLL UP
					begin
						tilemap_scroll_dir <= 1'b0;
						tilemap_scroll_axis <= 1'b1;
						tilemap_scroll_start_pos = 5'd1;
						tilemap_scroll_target_pos = TILEMAP_CELLS_Y - 5'd1;
						tilemap_scroll_state <= TM_SCROLL_START;
						tilemap_ctl_x = 5'd0;
						tilemap_ctl_y = tilemap_scroll_start_pos;
						tilemap_ctl_state <= TM_CTL_SCROLL;
						tilemap_ctl_hstart <= hcnt;
						tilemap_ctl_vstart <= vcnt;
					end
					8'd4: // SCROLL DOWN
					begin
						tilemap_scroll_dir <= 1'b1;
						tilemap_scroll_axis <= 1'b1;
						tilemap_scroll_start_pos = TILEMAP_CELLS_Y - 5'd2;
						tilemap_scroll_target_pos = 5'd0;
						tilemap_scroll_state <= TM_SCROLL_START;
						tilemap_ctl_x = 5'd0;
						tilemap_ctl_y = tilemap_scroll_start_pos;
						tilemap_ctl_state <= TM_CTL_SCROLL;
						tilemap_ctl_hstart <= hcnt;
						tilemap_ctl_vstart <= vcnt;
					end
					8'd5: // CLEAR
					begin
						tilemap_clear_state <= TM_CLEAR_PREP;
						tilemap_ctl_x = 5'd0;
						tilemap_ctl_y = 5'd0;
						tilemap_ctl_state <= TM_CTL_CLEAR;
						tilemap_ctl_hstart <= hcnt;
						tilemap_ctl_vstart <= vcnt;
					end
					default:
					begin
						
					end
				endcase
			end
		end

		case(tilemap_ctl_state)
			TM_CTL_IDLE:
			begin
				tilemap_ctl_cycles <= 16'b0;
				hcnt_last <= hcnt;
				if(hcnt == 9'd395 && hcnt_last == 9'd394)
				begin
					// When end of HBLANK is reached, reset tilemap read state
					tilemap_read_state <= 2'b0;
					tilemap_read_cycles <= 16'b0;
				end
				else
				begin
					tilemap_read_cycles <= tilemap_read_cycles + 1'b1;
					tilemap_read_state <= tilemap_read_state + 2'b1;
					case(tilemap_read_state)
						2'b00:
						begin
							// - Calculate next pixel lookup address
							tilemap_pos_x = $signed($signed((hcnt == 9'd395 ? 9'd0 : hcnt + 9'd1)) + TILEMAP_BORDER) + $signed(tilemap_offset_x);
							tilemap_pos_y = $signed($signed((vcnt == 9'd255 ? 9'd0 : vcnt)) + TILEMAP_BORDER) + $signed(tilemap_offset_y);
							// - Set tilemapram lookup address
							tilemapram_addr <= { tilemap_pos_y[8:4], tilemap_pos_x[8:4] };
							// Set colour output for previous ROM lookup
							tilemap_r = {tilemaprom_data_out[4:0],tilemaprom_data_out[4:2]};
							tilemap_g = {tilemaprom_data_out[9:5],tilemaprom_data_out[9:7]};
							tilemap_b = {tilemaprom_data_out[14:10],tilemaprom_data_out[14:12]};
							tilemap_a = tilemaprom_data_out[15];
						end
						2'b10:
						begin
							// Set ROM lookup address based on index RAM and cell offset
							tilemaprom_addr <= { tilemapram_data_out[TILEMAP_ROM_WIDTH-10:0], tilemap_pos_y[3:0], tilemap_pos_x[3:0], 1'b0 };
						end
						default: begin end
					endcase
				end
			end
			TM_CTL_SCROLL: 
			begin
				tilemap_ctl_cycles <= tilemap_ctl_cycles + 16'b1;
				case(tilemap_scroll_state)
					TM_SCROLL_WAIT:
					begin
						tilemap_scroll_state <= tilemap_scroll_state_next;
					end
					TM_SCROLL_START:
					begin
`ifdef TM_DEBUG
						$display("TM_SCROLL_START: axis=%b dir=%b", tilemap_scroll_axis, tilemap_scroll_dir);
`endif
						tilemapram_addr <= { tilemap_ctl_y, tilemap_ctl_x };
						tilemap_scroll_state <= TM_SCROLL_WAIT;
						tilemap_scroll_state_next <= TM_SCROLL_GETINDEX;
					end
					TM_SCROLL_GETINDEX:
					begin
`ifdef TM_DEBUG
						$display("TM_SCROLL_GETINDEX: %d/%d - %x %d", tilemap_ctl_x, tilemap_ctl_y, tilemapram_addr, tilemapram_data_out);
`endif
						tilemapram_ctl_data_in <= tilemapram_data_out;
						if(tilemap_scroll_axis)
						begin
							tilemapram_addr <= { tilemap_scroll_dir ? tilemap_ctl_y + 5'd1 : tilemap_ctl_y - 5'd1, tilemap_ctl_x };
						end
						else
						begin
							tilemapram_addr <= { tilemap_ctl_y, tilemap_scroll_dir ? tilemap_ctl_x + 5'd1 : tilemap_ctl_x - 5'd1 };
						end
						tilemapram_ctl_wr <= 1'b1;
						tilemap_scroll_state <= TM_SCROLL_WAIT;
						tilemap_scroll_state_next <= TM_SCROLL_SETINDEX;
					end
					TM_SCROLL_SETINDEX:
					begin
`ifdef TM_DEBUG
						$display("TM_SCROLL_SETINDEX: %d/%d - %x %d", tilemap_ctl_x, tilemap_ctl_y, tilemapram_addr, tilemapram_ctl_data_in);
`endif
						tilemapram_ctl_wr <= 1'b0;
						if((tilemap_scroll_axis ? tilemap_ctl_y : tilemap_ctl_x) == tilemap_scroll_target_pos)
						begin
							if(!tilemap_scroll_axis ? (tilemap_ctl_y == TILEMAP_CELLS_Y - 5'd1) : (tilemap_ctl_x == TILEMAP_CELLS_X - 5'd1))
							begin
								// Scroll process completed
								tilemap_ctl_state <= TM_CTL_IDLE;
`ifdef TM_DEBUG
								$display("TM_SCROLL_COMPLETE - in %d | vstart: %d vend: %d | hstart: %d hend: %d", tilemap_ctl_cycles, tilemap_ctl_vstart, vcnt, tilemap_ctl_hstart, hcnt);
`endif
								// Clear trigger control register
								tilemapreg[2] <= 8'b0;
							end
							else
							begin
								if(tilemap_scroll_axis)
								begin
									tilemap_ctl_y = tilemap_scroll_start_pos;
									tilemap_ctl_x = tilemap_ctl_x + 5'd1;
								end
								else
								begin
									tilemap_ctl_x = tilemap_scroll_start_pos;
									tilemap_ctl_y = tilemap_ctl_y + 5'd1;
								end
								tilemapram_addr <= { tilemap_ctl_y, tilemap_ctl_x };
								tilemap_scroll_state <= TM_SCROLL_WAIT;
								tilemap_scroll_state_next <= TM_SCROLL_GETINDEX;
							end
						end
						else
						begin
							if(tilemap_scroll_axis)
							begin
								tilemap_ctl_y = tilemap_scroll_dir ? tilemap_ctl_y - 5'd1 : tilemap_ctl_y + 5'd1;
							end
							else
							begin
								tilemap_ctl_x = tilemap_scroll_dir ? tilemap_ctl_x - 5'd1 : tilemap_ctl_x + 5'd1;
							end
							tilemapram_addr <= { tilemap_ctl_y, tilemap_ctl_x };
							tilemap_scroll_state <= TM_SCROLL_WAIT;
							tilemap_scroll_state_next <= TM_SCROLL_GETINDEX;
						end
					end
				endcase
			end
			TM_CTL_CLEAR:
			begin
				case(tilemap_clear_state)
				TM_CLEAR_PREP:
				begin
`ifdef TM_DEBUG
					$display("TM_CLEAR_PREP tilemap_ctl_x=%d tilemap_ctl_y=%d", tilemap_ctl_x, tilemap_ctl_y);
`endif
					tilemapram_addr <= { tilemap_ctl_y, tilemap_ctl_x };
					tilemapram_ctl_wr <= 1'b1;
					tilemapram_ctl_data_in <= 8'b0;
					tilemap_clear_state <= TM_CLEAR_WRITE;
				end
				TM_CLEAR_WRITE:
				begin
`ifdef TM_DEBUG
					$display("TM_CLEAR_WRITE tilemap_ctl_x=%d tilemap_ctl_y=%d", tilemap_ctl_x, tilemap_ctl_y);
`endif
					tilemap_clear_state <= TM_CLEAR_PREP;
					tilemap_ctl_x = tilemap_ctl_x + 5'd1;
					if(tilemap_ctl_x == TILEMAP_CELLS_X)
					begin
						tilemap_ctl_x = 5'd0;
						if(tilemap_ctl_y == TILEMAP_CELLS_Y)
						begin
							tilemap_clear_state <= TM_CLEAR_DONE;
						end
						else
						begin
							tilemap_ctl_y = tilemap_ctl_y + 5'd1;
						end
					end
				end
				TM_CLEAR_DONE:
				begin
`ifdef TM_DEBUG
					$display("TM_CLEAR_DONE tilemap_ctl_x=%d tilemap_ctl_y=%d", tilemap_ctl_x, tilemap_ctl_y);
`endif
					tilemapram_ctl_wr <= 1'b0;
					tilemap_ctl_state <= TM_CTL_IDLE;
					// Clear trigger control register
					tilemapreg[2] <= 8'b0;
				end
				endcase
			end
		endcase
	end
end

endmodule