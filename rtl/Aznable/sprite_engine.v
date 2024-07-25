`timescale 1ps / 1ps
/*============================================================================
	Aznable (custom 8-bit computer system) - Comet (sprite engine)

	Author: Jim Gregory - https://github.com/JimmyStones/
	Version: 0.1
	Date: 2021-10-31

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

module sprite_engine #(
	parameter SPRITE_RAM_WIDTH = 7,			
	parameter SPRITE_ROM_WIDTH = 14,		
	parameter SPRITE_POSITION_WIDTH = 9,	
	parameter SPRITE_COLRAM_WIDTH = 5,		
	parameter SPRITE_SIZE_WIDTH = 5			// Width of sprite size related operations 
)(
	input				clk,
	input				reset,
	input				pause,
	input				hsync,
	input				vsync,
	input				vblank,
	input	[SPRITE_POSITION_WIDTH-1:0]	hcnt,
	input	[SPRITE_POSITION_WIDTH-1:0]	vcnt,
	
	input		[7:0]	spriterom_data_out,
	input		[7:0]	spriteram_data_out,
	input		[15:0]	palrom_data_out,
	input		[15:0]	spritelbram_data_out,
	input				spritecollisionram_data_out,

	output reg 	[SPRITE_RAM_WIDTH-1:0]	spriteram_addr,
	output reg 	[SPRITE_COLRAM_WIDTH-1:0]	spritecollisionram_addr,
	output reg			spritecollisionram_data_in,
	output reg	[SPRITE_ROM_WIDTH-1:0]	sprom_addr,
	output reg 	[7:0]	palrom_addr,
	output 		[SPRITE_POSITION_WIDTH:0]	spritelbram_rd_addr,
	output reg	[SPRITE_POSITION_WIDTH:0]	spritelbram_wr_addr,

	output reg			spritelbram_wr,
	output reg	[15:0]	spritelbram_data_in,

	output reg			spritecollisionram_wr,

`ifdef DEBUG_SPRITE_COLLISION
	output reg	[16:0]	spritedebugram_addr_b,
	output reg	 [7:0]	spritedebugram_data_in_b,
	input		 [7:0]	spritedebugram_data_out_b,
	output reg			spritedebugram_wr_b,
`endif

	output		[7:0]	spr_r,
	output		[7:0]	spr_g,
	output		[7:0]	spr_b,
	output				spr_a
);

// State machine constants
localparam SE_INIT = 0;
localparam SE_IDLE = 1;
localparam SE_WAIT = 2;
localparam SE_RESET = 3;
localparam SE_CLEAR_BUFFER = 4;
localparam SE_SETUP_READ_Y = 5;
localparam SE_READ_Y_UPPER = 6;
localparam SE_READ_Y_LOWER = 7;
localparam SE_CHECK_Y = 8;
localparam SE_READ_X_UPPER = 9;
localparam SE_READ_X_LOWER = 10;
localparam SE_SETUP_WRITE = 11;
localparam SE_GET_PIXEL = 12;
localparam SE_STAGE_PIXEL = 13;
localparam SE_WRITE_PIXEL = 14;
localparam SE_LINE_COMPLETE = 15;

localparam SE_SETUP_LOAD_8x8_UPPER = 20;
localparam SE_SETUP_LOAD_8x8_LOWER = 21;
localparam SE_SETUP_LOAD_16x16_UPPER = 22;
localparam SE_SETUP_LOAD_16x16_LOWER = 23;
localparam SE_SETUP_LOAD_32x32_UPPER = 24;
localparam SE_SETUP_LOAD_32x32_LOWER = 25;


// Sprite line buffer has two slots - read and write.  They alternate when hsync goes high.
reg					spritelb_slot_rd = 1'b0;
reg					spritelb_slot_wr = 1'b1;

// Track last hsync value
reg					hsync_last;

// Sprite state machine control
reg			 [4:0]	spr_state;
reg			 [4:0]	spr_state_next;
// Sprite index counter and maximum sprite limit
reg			 [5:0]	spr_index;
localparam			spr_index_max = 6'd31;
// Sprite maximum sizes
localparam	 [6:0]	spr_ram_item_width = 4;
localparam	 [SPRITE_POSITION_WIDTH-1:0]	spr_line_max = 352;
reg	 		 [SPRITE_POSITION_WIDTH-1:0]	spr_size;		// Size of sprite in pixels (always square)
reg			 [SPRITE_POSITION_WIDTH-1:0]	spr_x;			// Sprite X position
reg			 [SPRITE_POSITION_WIDTH-1:0]	spr_y;			// Sprite Y position 
reg					spr_enable;								// Sprite visibility enabled
reg					spr_collide;							// Sprite collision enabled
reg			 [1:0]	spr_palette_index;						// Sprite palette index
reg			 [5:0]	spr_image_index;						// Sprite image index
localparam   [SPRITE_POSITION_WIDTH-1:0]	spr_border_size = 32; // Sprite screen border width
reg			 [SPRITE_POSITION_WIDTH-1:0]	spr_active_y;	// Current active sprite engine Y
reg			 [SPRITE_SIZE_WIDTH:0]			spr_pixel_index;// Current sprite X pixel
reg			 [SPRITE_ROM_WIDTH-1:0]			spr_rom_offset; // Offset for current sprite size in image ROM
reg			 [9:0]	spr_rom_y_offset;						// Offset for current sprite Y line in image ROM

localparam   [SPRITE_POSITION_WIDTH-1:0] spr_size_8x8 = {{SPRITE_POSITION_WIDTH-5{1'b0}}, 5'd7};
localparam   [SPRITE_POSITION_WIDTH-1:0] spr_size_16x16 = {{SPRITE_POSITION_WIDTH-5{1'b0}}, 5'd15};
localparam   [SPRITE_POSITION_WIDTH-1:0] spr_size_32x32 = {{SPRITE_POSITION_WIDTH-5{1'b0}}, 5'd31};
reg			 [SPRITE_ROM_WIDTH-1:0]		 spr_rom_offset_8x8;
reg			 [SPRITE_ROM_WIDTH-1:0]		 spr_rom_offset_16x16;
reg			 [SPRITE_ROM_WIDTH-1:0]		 spr_rom_offset_32x32;

 //`define CASVAL_DEBUG
 //`define CASVAL_DEBUG_TIMES
 //`define CASVAL_DEBUG_OUTLINE

`ifdef CASVAL_DEBUG_TIMES
parameter SPR_TIMER_WIDTH = 11;
reg [SPR_TIMER_WIDTH-1:0] spr_timer_idle;
reg [SPR_TIMER_WIDTH-1:0] spr_linetime_max;
reg [SPR_TIMER_WIDTH-1:0] spr_timer_line;
`endif

// Sprite engine outputs
assign spritelbram_rd_addr = {spritelb_slot_rd, (hcnt + spr_border_size)};
assign spr_r = {spritelbram_data_out[4:0],spritelbram_data_out[4:2]};
assign spr_g = {spritelbram_data_out[9:5],spritelbram_data_out[9:7]};
assign spr_b = {spritelbram_data_out[14:10],spritelbram_data_out[14:12]};
assign spr_a = spritelbram_data_out[15];

// Collision system
localparam CP_IDLE = 0;
localparam CP_WAIT = 1;
localparam CP_STAGE_PIXEL = 2;
localparam CP_CHECK_PIXEL = 3;
localparam CP_WRITE_PIXEL = 4;

localparam CS_IDLE = 0;
localparam CS_WAIT = 1;
localparam CS_DETECT_BEGIN = 2;
localparam CS_DETECT = 3;
localparam CS_DETECT_COMPLETE = 4;

reg [3:0] col_primary_state = CP_IDLE;
reg [3:0] col_primary_state_next;

reg [3:0] col_secondary_state = CS_IDLE;
reg [3:0] col_secondary_state_next;

reg			[SPRITE_POSITION_WIDTH-1:0]	col_x;
reg			[4:0]	col_spriteindex;

reg			[SPRITE_POSITION_WIDTH-1:0]	col_buffer_primary_addr;
reg					col_buffer_primary_wr;
reg			[31:0]	col_buffer_primary_data_in;
wire		[31:0]	col_buffer_primary_data_out;

reg			[SPRITE_POSITION_WIDTH-1:0]	col_buffer_secondary_addr;
reg					col_buffer_secondary_wr;
reg			[31:0]	col_buffer_secondary_data_in;
wire		[31:0]	col_buffer_secondary_data_out;

reg			[31:0]	col_buffer_secondary_collisions;
wire 		 [4:0]  col_buffer_secondary_collisions_count1;
wire 		 [4:0]  col_buffer_secondary_collisions_count2;

count count1 (
	.clk(clk),
	.a(col_buffer_secondary_collisions),
	.sum(col_buffer_secondary_collisions_count1)
);
count count2 (
	.clk(clk),
	.a(col_buffer_secondary_data_out),
	.sum(col_buffer_secondary_collisions_count2)
);

reg 				col_buffer_primary_is_a;

//`define CASVAL_COLLISION_PRIMARY_DEBUG
//`define CASVAL_COLLISION_SECONDARY_DEBUG
reg 		[15:0]	col_secondary_timer;

always @(posedge clk)
begin

	if(reset)
	begin
		spr_state <= SE_IDLE;
	end

	hsync_last <= hsync;

	if(!pause)
	begin
		// Primary collision state machine - Takes stage pixel instruction from sprite engine state machine
		col_secondary_timer <= col_secondary_timer + 16'd1;
		case (col_primary_state)

			CP_IDLE:
			begin
				
			end

			CP_WAIT:
			begin
				col_primary_state <= col_primary_state_next;
			end

			CP_STAGE_PIXEL:
			begin
`ifdef CASVAL_COLLISION_PRIMARY_DEBUG
				$display("CP_STAGE_PIXEL: x=%d i=%d", col_x, col_spriteindex);
`endif
				// Set primary buffer to read existing pixel
				col_buffer_primary_addr <= col_x;
				col_buffer_primary_wr <= 1'b0;
				
				//col_primary_state <= CP_CHECK_PIXEL;
				col_primary_state_next <= CP_CHECK_PIXEL;
				col_primary_state <= CP_WAIT;
			end

			CP_CHECK_PIXEL:
			begin
`ifdef CASVAL_COLLISION_PRIMARY_DEBUG
				$display("CP_CHECK_PIXEL: x,y=%d,%d i=%d ra=%x do=%b m=%b di=%", col_x, spr_active_y, col_spriteindex, col_buffer_primary_addr, col_buffer_primary_data_out, (32'b1 << col_spriteindex),col_buffer_primary_data_out | (32'b1 << col_spriteindex));
`endif
				col_buffer_primary_data_in <= col_buffer_primary_data_out | (32'b1 << col_spriteindex);
				col_buffer_primary_wr <= 1'b1;
				col_primary_state <= CP_WRITE_PIXEL;
			end

			CP_WRITE_PIXEL:
			begin
`ifdef CASVAL_COLLISION_PRIMARY_DEBUG
				$display("CP_WRITE_PIXEL: x,y=%d,%d i=%d - wa=%x di=%x do=%x", col_x, spr_active_y,  col_spriteindex, col_buffer_primary_addr, col_buffer_primary_data_in, col_buffer_primary_data_out);
`endif
				col_buffer_primary_wr <= 1'b0;
				col_buffer_primary_data_in <= 32'b0;
				col_primary_state <= CP_IDLE;
			end
		endcase
	end
// Sprite engine state machine
`ifdef CASVAL_DEBUG_TIMES
	spr_timer_line <= spr_timer_line + 1'b1;
`endif
	case (spr_state)
		SE_INIT:
		begin
`ifdef CASVAL_DEBUG_TIMES
			// Reset line timer maximum
			spr_linetime_max <= {{SPR_TIMER_WIDTH-1{1'b0}},1'b1};
`endif
			// Start loading sprite ROM offsets
			sprom_addr <= {SPRITE_ROM_WIDTH{1'b0}};
			spr_state <= SE_WAIT;
			spr_state_next <= SE_SETUP_LOAD_32x32_UPPER;
		end

		SE_SETUP_LOAD_32x32_UPPER:
		begin
`ifdef CASVAL_DEBUG
			$display("CASVAL->SE_SETUP_LOAD_32x32_UPPER: addr=%x  dout=%x", sprom_addr, spriterom_data_out);
`endif
			// Load upper byte of 32x32 image offset
			spr_rom_offset_32x32[SPRITE_ROM_WIDTH-1:8] <= spriterom_data_out[SPRITE_ROM_WIDTH-9:0];
			// Increment sprite ROM address
			sprom_addr <= sprom_addr + {{SPRITE_ROM_WIDTH-1{1'b0}},1'b1};
			// Move to next state
			spr_state <= SE_WAIT;
			spr_state_next <= SE_SETUP_LOAD_32x32_LOWER;
		end
		SE_SETUP_LOAD_32x32_LOWER:
		begin
`ifdef CASVAL_DEBUG
			$display("CASVAL->SE_SETUP_LOAD_32x32_LOWER: addr=%x  dout=%x", sprom_addr, spriterom_data_out);
`endif
			// Load lower byte of 32x32 image offset
			spr_rom_offset_32x32[7:0] <= spriterom_data_out;
			// Increment sprite ROM address
			sprom_addr <= sprom_addr + {{SPRITE_ROM_WIDTH-1{1'b0}},1'b1};
			// Move to next state
			spr_state <= SE_WAIT;
			spr_state_next <= SE_SETUP_LOAD_16x16_UPPER;
		end
		
		SE_SETUP_LOAD_16x16_UPPER:
		begin
`ifdef CASVAL_DEBUG
			$display("CASVAL->SE_SETUP_LOAD_16x16_UPPER: addr=%x  dout=%x", sprom_addr, spriterom_data_out);
`endif
			// Load upper byte of 16x16 image offset
			spr_rom_offset_16x16[SPRITE_ROM_WIDTH-1:8] <= spriterom_data_out[SPRITE_ROM_WIDTH-9:0];
			// Increment sprite ROM address
			sprom_addr <= sprom_addr + {{SPRITE_ROM_WIDTH-1{1'b0}},1'b1};
			// Move to next state
			spr_state <= SE_WAIT;
			spr_state_next <= SE_SETUP_LOAD_16x16_LOWER;
		end
		SE_SETUP_LOAD_16x16_LOWER:
		begin
`ifdef CASVAL_DEBUG
			$display("CASVAL->SE_SETUP_LOAD_16x16_LOWER: addr=%x  dout=%x", sprom_addr, spriterom_data_out);
`endif
			// Load lower byte of 16x16 image offset
			spr_rom_offset_16x16[7:0] <= spriterom_data_out;
			// Increment sprite ROM address
			sprom_addr <= sprom_addr + {{SPRITE_ROM_WIDTH-1{1'b0}},1'b1};
			// Move to next state
			spr_state <= SE_WAIT;
			spr_state_next <= SE_SETUP_LOAD_8x8_UPPER;
		end

		SE_SETUP_LOAD_8x8_UPPER:
		begin
`ifdef CASVAL_DEBUG
			$display("CASVAL->SE_SETUP_LOAD_8x8_UPPER: addr=%x  dout=%x", sprom_addr, spriterom_data_out);
`endif
			// Load upper byte of 8x8 image offset
			spr_rom_offset_8x8[SPRITE_ROM_WIDTH-1:8] <= spriterom_data_out[SPRITE_ROM_WIDTH-9:0];
			// Increment sprite ROM address
			sprom_addr <= sprom_addr + {{SPRITE_ROM_WIDTH-1{1'b0}},1'b1};
			// Move to next state
			spr_state <= SE_WAIT;
			spr_state_next <= SE_SETUP_LOAD_8x8_LOWER;
		end
		SE_SETUP_LOAD_8x8_LOWER:
		begin
`ifdef CASVAL_DEBUG
			$display("CASVAL->SE_SETUP_LOAD_8x8_LOWER: addr=%x  dout=%x", sprom_addr, spriterom_data_out);
`endif
			// Load lower byte of 8x8 image offset
			spr_rom_offset_8x8[7:0] <= spriterom_data_out;
			// Increment sprite ROM address
			sprom_addr <= sprom_addr + {{SPRITE_ROM_WIDTH-1{1'b0}},1'b1};
			// Move to next state
			spr_state <= SE_IDLE;
		end

		SE_IDLE:
		begin
			// Wait for hsync to go high outside of reset
			if(reset == 1'b0 && hsync && !hsync_last)
			begin
				// Rotate line buffer slots
				spritelb_slot_rd <= spritelb_slot_rd + 1'b1;
				spritelb_slot_wr <= spritelb_slot_wr + 1'b1;
				// Calculate active Y line
				spr_active_y <= (vcnt == 9'd255) ? spr_border_size : (vcnt + spr_border_size) + 9'd1;	

				spr_state <= SE_RESET;
			end
`ifdef CASVAL_DEBUG_TIMES
			else
			begin
				spr_timer_idle <= spr_timer_idle + 1'b1;
			end
`endif
		end

		SE_WAIT:
		begin
			spr_state <= spr_state_next;
		end

		SE_RESET:
		begin
			// Reset sprite index
			spr_index <= 6'd0;

`ifdef CASVAL_DEBUG_TIMES
					$display("CASVAL->LEAVING SE_IDLE: vcnt = %d  spr_active_y = %d", vcnt, spr_active_y);
					$display("CASVAL->LEAVING SE_IDLE: spr_timer_idle = %d, spr_linetime_max=%d", spr_timer_idle, spr_linetime_max);
					spr_timer_line <= {SPR_TIMER_WIDTH{1'b0}};
`endif

			// Setup line buffer RAM for clear operation
			spritelbram_wr_addr <= {spritelb_slot_wr, {SPRITE_POSITION_WIDTH{1'b0}}};
			spritelbram_wr <= 1'b1;
			spritelbram_data_in <= 16'b0;

			spr_state <= SE_CLEAR_BUFFER;
		end

		SE_CLEAR_BUFFER:
		begin
			if(spritelbram_wr_addr[8:0] < spr_line_max[8:0])
			begin
				spritelbram_wr_addr <= spritelbram_wr_addr + 1'b1;
			end
			else
			begin
				// Disable line buffer write
				spritelbram_wr <= 1'b0;

				spr_state <= SE_SETUP_READ_Y;
			end
		end

		SE_SETUP_READ_Y:
		begin
			// Setup address to read Y from sprite RAM
			spriteram_addr <= spr_index * spr_ram_item_width;

			spr_state <= SE_WAIT;
			spr_state_next <= SE_READ_Y_UPPER;
		end
		SE_READ_Y_UPPER:
		begin
`ifdef CASVAL_DEBUG
			$display("CASVAL->SE_READ_Y_UPPER: spr: %d  addr=%x  dout=%x", spr_index, spriteram_addr, spriteram_data_out);
`endif
			// Read enable bit from sprite RAM
			spr_enable <= spriteram_data_out[7];
			// Read collide bit from sprite RAM
			spr_collide <= spriteram_data_out[6];
			// Read palette index bits from sprite RAM
			spr_palette_index <= spriteram_data_out[5:4];
			// Read size bits from sprite RAM
			spr_size <= (spriteram_data_out[3:2] == 2'd2 ? spr_size_8x8 :
								spriteram_data_out[3:2] == 2'd1 ? spr_size_16x16 :
								spriteram_data_out[3:2] == 2'd0 ? spr_size_32x32 : {SPRITE_POSITION_WIDTH{1'b0}});
			// Read Y upper 1 bit from sprite RAM
			spr_y[8] <= spriteram_data_out[0];
			// Increment sprite RAM address
			spriteram_addr <= spriteram_addr + 1'b1;

			spr_state <= SE_WAIT;
			spr_state_next <= SE_READ_Y_LOWER;
		end
		SE_READ_Y_LOWER:
		begin
`ifdef CASVAL_DEBUG
			$display("CASVAL->SE_READ_Y_LOWER:  spr: %d  addr=%x dout=%x", spr_index, spriteram_addr, spriteram_data_out);
`endif
			// Read Y lower 8 bits from sprite RAM
			spr_y[7:0] <= spriteram_data_out;
			// Increment sprite RAM address
			spriteram_addr <= spriteram_addr + 1'b1;

			spr_state <= SE_CHECK_Y;
		end

		SE_CHECK_Y:
		begin
`ifdef CASVAL_DEBUG
			//$display("CASVAL->SE_CHECK_Y: spr_index=%d  y: %d", spr_index, spr_y);
`endif
			//// If this sprite is enabled and current line is within sprite Y area
			if(spr_enable==1'b1 && spr_active_y >= spr_y && spr_active_y <= spr_y + spr_size)
			begin
`ifdef CASVAL_DEBUG
				$display("SE_CHECK_Y PASSED: spr_index=%d", spr_index);
`endif
				spr_state <= SE_READ_X_UPPER;
			end
			else
			begin
				// If no then move to next sprite or finish
				if(spr_index == spr_index_max)
				begin
					spr_state <= SE_LINE_COMPLETE;
				end
				else
				begin
					// Increment sprite index
					spr_index <= spr_index + 1'd1;

					spr_state <= SE_SETUP_READ_Y;
				end
			end
		end

		SE_READ_X_UPPER:
		begin
`ifdef CASVAL_DEBUG
			$display("CASVAL->SE_READ_X_UPPER:  addr=%x dout=%x", spriteram_addr, spriteram_data_out);
`endif
			// Read image index 6 bits from sprite RAM
			spr_image_index <= spriteram_data_out[7:2];
			
			// Read X upper 1 bit from sprite RAM
			spr_x[8] <= spriteram_data_out[0];
			// Increment sprite RAM address
			spriteram_addr <= spriteram_addr + 1'b1;

			spr_state <= SE_WAIT;
			spr_state_next <= SE_READ_X_LOWER;
		end
		SE_READ_X_LOWER:
		begin
`ifdef CASVAL_DEBUG
			$display("CASVAL->SE_READ_X_LOWER:  addr=%x dout=%x", spriteram_addr, spriteram_data_out);
`endif
			// Read X lower 8 bits from sprite RAM
			spr_x[7:0] <= spriteram_data_out;
			// Set up offset for sprite ROM read
			spr_rom_y_offset <= spr_active_y - spr_y;
			// Set up ROM offset for sprite size
			case(spr_size)
				spr_size_32x32: spr_rom_offset <= spr_rom_offset_32x32;
				spr_size_16x16: spr_rom_offset <= spr_rom_offset_16x16;
				default: spr_rom_offset <= spr_rom_offset_8x8;
			endcase

			spr_state <= SE_SETUP_WRITE;
		end

		SE_SETUP_WRITE:
		begin
`ifdef CASVAL_DEBUG
			$display("CASVAL->SE_SETUP_WRITE: AY: %d   Y: %d   X: %d   I: %d   O: %d", spr_active_y, spr_y, spr_x, spr_image_index, spr_rom_y_offset);
`endif
			// Enable line buffer write
			spritelbram_wr <= 1'b0;
			// Setup line buffer write address
		 	spritelbram_wr_addr <= {spritelb_slot_wr, spr_x};
			// Set sprite rom read address
			case(spr_size)
				spr_size_32x32:
				begin
					sprom_addr <= spr_rom_offset + { spr_image_index[3:0], 10'b0} + { spr_rom_y_offset[7:0], 5'b0};
				end
				spr_size_16x16: 
				begin
					sprom_addr <= spr_rom_offset + { spr_image_index[5:0], 8'b0} + { spr_rom_y_offset[8:0], 4'b0};
				end
				default:
				begin
					// Default to 8x8
					sprom_addr <= spr_rom_offset + { 2'b0, spr_image_index[5:0], 6'b0} + { spr_rom_y_offset[9:0], 3'b0};
				end
			endcase
					 	
			// Reset sprite pixel index and count
		 	spr_pixel_index <= {SPRITE_SIZE_WIDTH+1{1'b0}};

			spr_state <= SE_WAIT;
			spr_state_next <= SE_GET_PIXEL;
		end

		SE_GET_PIXEL:
		begin
			if(spr_pixel_index > spr_size[SPRITE_SIZE_WIDTH:0])
		 	begin
		 		// Move to next sprite or finish
		 		if(spr_index == spr_index_max)
		 		begin
		 			spr_state <= SE_LINE_COMPLETE;
		 		end
		 		else
		 		begin
		 			spr_index <= spr_index + 5'd1;
		 			spr_state <= SE_SETUP_READ_Y;
		 		end
		 	end
			else
			begin
`ifdef CASVAL_DEBUG
				$display("CASVAL->SE_GET_PIXEL: y: %d, x: %d i: %d, sprom_addr < %x, palrom_addr < %x", spr_y, spr_pixel_index, spr_image_index, sprom_addr, {spriterom_data_out[4:0],1'b0});
`endif
				// Setup palette address to read pixel colour
				palrom_addr <= {spr_palette_index, spriterom_data_out[4:0],1'b0};
				// Increment sprite ROM address
				sprom_addr <= sprom_addr + 1'b1;
				// Disable line buffer write
				spritelbram_wr <= 1'b0;

				spr_state <= SE_WAIT;
				spr_state_next <= SE_STAGE_PIXEL;
			end
		end

		SE_STAGE_PIXEL:
		begin

`ifdef CASVAL_DEBUG_OUTLINE
			/* verilator lint_off WIDTH */
			if(spr_pixel_index == 0 || spr_pixel_index == spr_size || spr_active_y == spr_y || spr_active_y == (spr_y + spr_size)) begin
				spritelbram_data_in <= 16'hFFFF;
				spritelbram_wr <= 1'b1;
				spr_state <= SE_WRITE_PIXEL;
			end
			/* verilator lint_on WIDTH */
			else
			begin
`endif
				// Get pixel colour from palette rom
				if(palrom_data_out[15])
				begin
					// If palette colour alpha is high, stage input to line buffer
`ifdef CASVAL_DEBUG
					$display("CASVAL->SE_STAGE_PIXEL: ay: %d y: %d, x: %d i: %d, spritelbram_data_in < %x", spr_active_y, spr_y, spr_pixel_index, spr_image_index, palrom_data_out);
`endif
					// Enable line buffer write
					spritelbram_wr <= 1'b1;
					// Fill line buffer data in with palette ROM data out
					spritelbram_data_in <= palrom_data_out;

					// Trigger collision check (not in vblank)
					if(!vblank && spr_collide)
					begin
						col_spriteindex <= spr_index[4:0];
						col_x <= spr_x + {{(SPRITE_POSITION_WIDTH-SPRITE_SIZE_WIDTH)-1{1'b0}}, spr_pixel_index};
						col_primary_state <= CP_STAGE_PIXEL;
					end
					// Move to write pixel state
					spr_state <= SE_WRITE_PIXEL;
				end
				else
				begin
					// Pixel is transparent so move to next
`ifdef CASVAL_DEBUG
					$display("CASVAL->SE_STAGE_PIXEL: y: %d, x: %d i: %d, spritelbram_data_in < %x - FAIL ALPHA  CHECK", spr_y,spr_pixel_index, spr_image_index, palrom_data_out);
`endif
					// Increment line buffer write address
					spritelbram_wr_addr <= spritelbram_wr_addr + 1'b1;
					// Increment sprite pixel index
					spr_pixel_index <= spr_pixel_index + 1'b1;

					spr_state <= SE_GET_PIXEL;
				end
			end
`ifdef CASVAL_DEBUG_OUTLINE
		end
`endif

		SE_WRITE_PIXEL:
		begin
			// Get pixel colour from palette rom and stage input to line buffer
`ifdef CASVAL_DEBUG
			$display("CASVAL->SE_WRITE_PIXEL: y: %d, x: %d i: %d, spritelbram_wr_addr < %d, spritelbram_data_in=%b", spr_y, spr_pixel_index, spr_image_index, spritelbram_wr_addr[SPRITE_POSITION_WIDTH-1:0], spritelbram_data_in);
`endif
			// Disable line buffer write
			spritelbram_wr <= 1'b0;
			// Increment line buffer write address
			spritelbram_wr_addr <= spritelbram_wr_addr + 1'b1;
			// Increment sprite pixel index
			spr_pixel_index <= spr_pixel_index + 1'b1;

			spr_state <= SE_GET_PIXEL;
		end

		SE_LINE_COMPLETE:
		begin
			// Once all sprites have been processed for each pixel return to idle
`ifdef CASVAL_DEBUG_TIMES
			$display("CASVAL->SE_LINE_COMPLETE: counter=%d", spr_timer_line);
			// Update slowest line counter
			if(spr_timer_line > spr_linetime_max)
			begin
				spr_linetime_max <= spr_timer_line;
			end
			// Reset idle timer
			spr_timer_idle <= {SPR_TIMER_WIDTH{1'b0}};
`endif
			spr_state <= SE_IDLE;
		end
	endcase


	if(!pause)
	begin

		// Collision FSM
		// When hsync goes high, rotate collision buffers and start detection pass for previous line
		if(hsync && !hsync_last)
		begin
			col_secondary_state <= CS_DETECT_BEGIN;
			col_buffer_primary_is_a <= ~col_buffer_primary_is_a;
		end

		case (col_secondary_state)
		CS_WAIT:
		begin
			col_secondary_state <= col_secondary_state_next;
		end
		CS_DETECT_BEGIN:
		begin
			// Reset address and write states for secondary buffer
			col_buffer_secondary_addr <= 9'b0;
			col_buffer_secondary_data_in <= 32'b0;
			col_buffer_secondary_wr <= 1'b1;
			col_buffer_secondary_collisions <= 32'b0;

			col_secondary_timer <= 16'b0;

			col_secondary_state <= CS_DETECT;

`ifdef CASVAL_COLLISION_SECONDARY_DEBUG
			$display("CS_DETECT_BEGIN t=%d  hc=d%", col_secondary_timer, hcnt);
`endif

		end

		CS_DETECT:
		begin
`ifdef CASVAL_COLLISION_SECONDARY_DEBUG
			$display("CS_DETECT t=%d : x=%d c=%d cc1=%d", col_secondary_timer, col_buffer_secondary_addr,  col_buffer_secondary_collisions, col_buffer_secondary_collisions_count1,);
`endif

			// Check each pixel for a collision
			if(col_buffer_secondary_collisions_count2 > 5'd1)
			begin
				//$display("CS_DETECT t=%d : x=%d c=%d cc1=%d", col_secondary_timer, col_buffer_secondary_addr, col_buffer_secondary_collisions, col_buffer_secondary_collisions_count1);
				col_buffer_secondary_collisions <= col_buffer_secondary_collisions | col_buffer_secondary_data_out;

`ifdef DEBUG_SPRITE_COLLISION
				//$display("CS_DETECT_DEBUG_OUT t=%d : a=%x", col_secondary_timer, ((spr_active_y) * 9'd320) + {8'b0, col_buffer_secondary_addr});
				spritedebugram_data_in_b <= 8'hFF;
				spritedebugram_wr_b <= 1'b1;
				spritedebugram_addr_b <= ((spr_active_y) * 9'd320) + {8'b0, col_buffer_secondary_addr};
`endif
			end

			if(col_buffer_secondary_addr == spr_line_max - 1'b1)
			begin
				spritecollisionram_wr <= 1'b0;
				spritecollisionram_addr <= {SPRITE_COLRAM_WIDTH{1'b0}};
`ifdef CASVAL_COLLISION_SECONDARY_DEBUG
				$display(">CS_DETECT_COMPLETE t=%d : y=%d hc=%d vc=%d", col_secondary_timer, spr_active_y, hcnt, vcnt);
`endif
				col_secondary_state <= CS_DETECT_COMPLETE;
			end
			else
			begin
				col_buffer_secondary_addr <= col_buffer_secondary_addr + 9'b1;
			end
		end

		CS_DETECT_COMPLETE:
		begin
			// Copy individual bits from col_buffer_secondary_collisions into sprite collision ram
			if(spritecollisionram_wr == 1'b0)
			begin
`ifdef CASVAL_COLLISION_SECONDARY_DEBUG
				$display("CS_DETECT_COMPLETE t=%d : RD b=%b c=%d x=%d col=%d y=%d do=%d di=%d", col_secondary_timer, col_buffer_secondary_collisions, col_buffer_secondary_collisions_count1, spritecollisionram_addr, col_buffer_secondary_collisions[spritecollisionram_addr], spr_active_y, spritecollisionram_data_out, col_buffer_secondary_collisions[spritecollisionram_addr] | spritecollisionram_data_out);
`endif
				if(col_buffer_secondary_collisions_count1 > 5'b0)
				begin
					spritecollisionram_data_in <= col_buffer_secondary_collisions[spritecollisionram_addr] | spritecollisionram_data_out;
				end
				else
				begin
					spritecollisionram_data_in <= spritecollisionram_data_out;
				end
				spritecollisionram_wr <= 1'b1;
				col_secondary_state <= CS_WAIT;
				col_secondary_state_next <= CS_DETECT_COMPLETE;
			end
			else
			begin
`ifdef CASVAL_COLLISION_SECONDARY_DEBUG
				$display("CS_DETECT_COMPLETE WR t=%d : x=%d b=%b c=%d col=%d y=%d do=%d di=%d", col_secondary_timer, spritecollisionram_addr, col_buffer_secondary_collisions, col_buffer_secondary_collisions_count1, col_buffer_secondary_collisions[spritecollisionram_addr], spr_active_y, spritecollisionram_data_out, col_buffer_secondary_collisions[spritecollisionram_addr] | spritecollisionram_data_out);
`endif
				if(spritecollisionram_addr == {SPRITE_COLRAM_WIDTH{1'b1}})
				begin
`ifdef CASVAL_COLLISION_SECONDARY_DEBUG
					$display("CS_DETECT_COMPLETE FINISHED t=%d  hc=d%", col_secondary_timer, hcnt);
					$display("CS_DETECT_COMPLETE FINISHED t=%d : b=%b bc=%d col=%d y=%d do=%d di=%d", col_secondary_timer, col_buffer_secondary_collisions,  col_buffer_secondary_collisions_count1, col_buffer_secondary_collisions[spritecollisionram_addr], spr_active_y, spritecollisionram_data_out, col_buffer_secondary_collisions[spritecollisionram_addr] | spritecollisionram_data_out);
`endif
					spritecollisionram_addr <= {SPRITE_COLRAM_WIDTH{1'b0}};
					col_secondary_state <= CS_IDLE;
				end
				else
				begin
					spritecollisionram_addr <= spritecollisionram_addr + {{SPRITE_COLRAM_WIDTH-1{1'b0}},1'b1};
					col_secondary_state <= CS_WAIT;
					col_secondary_state_next <= CS_DETECT_COMPLETE;
				end
				spritecollisionram_wr <= 1'b0;
			end
		end
		endcase
	end
end

wire [31:0]	col_buffer_data_out_a;
wire [31:0]	col_buffer_data_out_b;

assign col_buffer_primary_data_out = col_buffer_primary_is_a ? col_buffer_data_out_a : col_buffer_data_out_b;
assign col_buffer_secondary_data_out = !col_buffer_primary_is_a ? col_buffer_data_out_a : col_buffer_data_out_b;

// Sprite Collision Buffer RAM A
spram #(9,32) spritecollisionbufferram_a
(
	.clock(clk),
	.address(col_buffer_primary_is_a ? col_buffer_primary_addr : col_buffer_secondary_addr),
	.wren(col_buffer_primary_is_a ? col_buffer_primary_wr : col_buffer_secondary_wr),
	.data(col_buffer_primary_is_a ? col_buffer_primary_data_in : col_buffer_secondary_data_in),
	.q(col_buffer_data_out_a)
);
// Sprite Collision Buffer RAM B
spram #(9,32) spritecollisionbufferram_b
(
	.clock(clk),
	.address(!col_buffer_primary_is_a ? col_buffer_primary_addr : col_buffer_secondary_addr),
	.wren(!col_buffer_primary_is_a ? col_buffer_primary_wr : col_buffer_secondary_wr),
	.data(!col_buffer_primary_is_a ? col_buffer_primary_data_in : col_buffer_secondary_data_in),
	.q(col_buffer_data_out_b)
);

endmodule


module count
(
	input 			clk,
	input [31:0]	a,
	output reg [4:0] sum
);

reg [5:0] n;

always @(negedge clk) begin
	
	sum = 0;
	for (n=0; n<=6'd31; n=n+6'd1) begin
		sum = sum + {4'b0,a[n[4:0]]};
	end
	
end
endmodule