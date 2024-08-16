
module adctest
(
	input         clk,
	input         reset,
	
	input         scandouble,

	input  [23:0] adc_value,
	input         range,

	/*output reg    ce_pix,

	output reg    HBlank,
	output reg    HSync,
	output reg    VBlank,
	output reg    VSync,*/

	input [9:0] hc,
	input [9:0] vc,

	output reg [7:0] video_r,
	output reg [7:0] video_g,
	output reg [7:0] video_b
);

//reg   [9:0] hc;
//reg   [9:0] vc;
reg ce_pix, HBlank, HSync, VBlank, VSync;

// For audio line level, this is AC coupling; we must determine 'swing' from average value
// samples are taken at the beginning of each scanline (adc_val[n]), and
// a running total is kept in adc_total - which is 256 times the average amount
// The average is snapshotted once per frame (vsync), but can honestly be taken at any time

integer ii=0;
reg [11:0] adc_val_l[0:255];
reg [11:0] adc_val_r[0:255];
reg [20:0] adc_total_l = 0;
reg [20:0] adc_total_r = 0;
reg [11:0] adc_avg_l;
reg [11:0] adc_avg_r;



// For the 3.3V scale, we remove 4 bits of precision from the value
// this gives us a range of 208 pix/3.3V, or ~63 pix per volt
// Note: the raw reading is roughly in millivolts

reg [8:0] left_edge_3v3 = 33; //159
reg [8:0] limit_3v3 = 288; //208
reg [8:0] pervolt_3v3 = 63;

reg [8:0] start_l_3v3;
reg [8:0] end_l_3v3;
reg [8:0] start_r_3v3;
reg [8:0] end_r_3v3;


// line level for consumer equipment is 0.894V peak-to-peak; for this reduced scale,
// we will only drop 2 bits of precision, but will constantly need to determine
// average value in order to center the image in the scale

reg [8:0] left_edge_audio = 106;
reg [8:0] red_zone_l_audio = 152;
reg [8:0] red_zone_r_audio = 378;
reg [8:0] limit_audio = 500; //318
reg [8:0] half_limit_audio = 250; //159

reg [9:0] start_l_line;
reg [9:0] end_l_line;
reg [9:0] start_r_line;
reg [9:0] end_r_line;


reg[8:0] left_edge;
reg[8:0] limit;



always @(posedge clk) begin
	if(scandouble) ce_pix <= 1;
		else ce_pix <= ~ce_pix;

	if(reset) begin
		//hc <= 0;
		//vc <= 0;
	end
	else if(ce_pix) begin
		if(hc == 532) begin		//637							// at end of line, get ready for next line

			adc_val_l[0] <= adc_value[11:0];
			adc_total_l  <= adc_total_l - adc_val_l[255] + adc_value[11:0];

			adc_val_r[0] <= adc_value[23:12];
			adc_total_r  <= adc_total_r - adc_val_r[255] + adc_value[23:12];

			for (ii=0; ii<255; ii=ii+1) begin			// keep running FIFO queue of 256 values for averaging
				adc_val_l[ii+1] <= adc_val_l[ii];
				adc_val_r[ii+1] <= adc_val_r[ii];
			end
			
			//hc <= 0;

			if(vc == (scandouble ? 524 : 262)) begin //523 261
				//vc <= 0;
				adc_avg_l <= adc_total_l[19:8];			// grab average value once per VSYNC
				adc_avg_r <= adc_total_r[19:8];			// grab average value once per VSYNC
			end
			else begin
				//vc <= vc + 1'd1;
			end
		end
		else begin
			//hc <= hc + 1'd1;
		end

	end
end

always @(posedge clk) begin
	
	if (hc == 320) //529
		HBlank <= 1;
	else if (hc == 0)
		HBlank <= 0;

	if (hc == 388) begin //544
		HSync <= 1;

		if(vc == (scandouble ? 488 : 244)) VSync <= 1; //490 245
			else if (vc == (scandouble ? 494 : 247)) VSync <= 0; //496 248

		if(vc == (scandouble ? 480 : 240)) VBlank <= 1;
			else if (vc == 0) VBlank <= 0;
	end


	video_r <= 0;
	video_g <= 0;
	video_b <= 0;

	if (hc == 2) begin								// beginning of scanline: determine range
		if (range == 0) begin
			limit			<= limit_3v3;
			left_edge	<= left_edge_3v3;
		end else begin
			limit			<= limit_audio;
			left_edge	<= left_edge_audio;
		end
	end

	if (hc == 3) begin								// next pixel: determine start/end values for this line
	
		// We're going to draw a horizontal line from old value to new value
		// First find which is the leftmost dot

		// Do the calculations for the 3.3V scale here
		
		start_l_3v3 <= adc_val_l[0][11:4] + left_edge_3v3;
		end_l_3v3   <= adc_val_l[1][11:4] + left_edge_3v3;

	   start_r_3v3 <= adc_val_r[0][11:4] + left_edge_3v3;
		end_r_3v3   <= adc_val_r[1][11:4] + left_edge_3v3;

		
		// Now, do the calculations for the line level

		// Left channel:
	
		if (adc_val_l[0] > adc_avg_l) begin
			if (adc_val_l[0][11:2] - adc_avg_l[11:2] > half_limit_audio)
				start_l_line <= limit_audio + left_edge_audio;
			else
				start_l_line <= left_edge_audio + adc_val_l[0][11:2] - adc_avg_l[11:2] + half_limit_audio;
				
		end else begin
		
			if (adc_avg_l[11:2] - adc_val_l[0][11:2] > half_limit_audio)
				start_l_line <= left_edge_audio;
			else
				start_l_line <= left_edge_audio + adc_val_l[0][11:2] - adc_avg_l[11:2] + half_limit_audio;
		end

		if (adc_val_l[1] > adc_avg_l) begin
			if (adc_val_l[1][11:2] - adc_avg_l[11:2] > half_limit_audio)
				end_l_line <= limit_audio + left_edge_audio;
			else
				end_l_line <= left_edge_audio + adc_val_l[1][11:2] - adc_avg_l[11:2] + half_limit_audio;
				
		end else begin
		
			if (adc_avg_l[11:2] - adc_val_l[1][11:2] > half_limit_audio)
				end_l_line <= left_edge_audio;
			else
				end_l_line <= left_edge_audio + adc_val_l[1][11:2] - adc_avg_l[11:2] + half_limit_audio;
		end

		
		// Right channel:
		
		if (adc_val_r[0] > adc_avg_r) begin
			if (adc_val_r[0][11:2] - adc_avg_r[11:2] > half_limit_audio)
				start_r_line <= limit_audio + left_edge_audio;
			else
				start_r_line <= left_edge_audio + adc_val_r[0][11:2] - adc_avg_r[11:2] + half_limit_audio;
				
		end else begin
		
			if (adc_avg_r[11:2] - adc_val_r[0][11:2] > half_limit_audio)
				start_r_line <= left_edge_audio;
			else
				start_r_line <= left_edge_audio + adc_val_r[0][11:2] - adc_avg_r[11:2] + half_limit_audio;
		end

		if (adc_val_r[1] > adc_avg_r) begin
			if (adc_val_r[1][11:2] - adc_avg_r[11:2] > half_limit_audio)
				end_r_line <= limit_audio + left_edge_audio;
			else
				end_r_line <= left_edge_audio + adc_val_r[1][11:2] - adc_avg_r[11:2] + half_limit_audio;
				
		end else begin
		
			if (adc_avg_r[11:2] - adc_val_r[1][11:2] > half_limit_audio)
				end_r_line <= left_edge_audio;
			else
				end_r_line <= left_edge_audio + adc_val_r[1][11:2] - adc_avg_r[11:2] + half_limit_audio;
		end

	end

	
	if (hc == 4) begin						// clamping (for exceeding the range)

		// Do the calculations for the 3.3V scale here

		if (start_l_3v3 > (left_edge_3v3 + limit_3v3))
		   start_l_3v3 <= (left_edge_3v3 + limit_3v3);
			
		if (end_l_3v3 > (left_edge_3v3 + limit_3v3))
		   end_l_3v3 <= (left_edge_3v3 + limit_3v3);

		if (start_r_3v3 > (left_edge_3v3 + limit_3v3))
		   start_r_3v3 <= (left_edge_3v3 + limit_3v3);
			
		if (end_r_3v3 > (left_edge_3v3 + limit_3v3))
		   end_r_3v3 <= (left_edge_3v3 + limit_3v3);		
		
	end

	if (hc == 5) begin						// now to get the order correct, check if they are correct

		// Do the calculations for the 3.3V scale here

		if (start_l_3v3 > end_l_3v3) begin
			start_l_3v3 <= end_l_3v3;
			end_l_3v3   <= start_l_3v3;
		end

		if (start_r_3v3 > end_r_3v3) begin
			start_r_3v3 <= end_r_3v3;
			end_r_3v3   <= start_r_3v3;
		end

		// Do the calculations for the line-level scale here

		if (start_l_line > end_l_line) begin
			end_l_line		<= start_l_line;
			start_l_line	<= end_l_line;
		end

		if (start_r_line > end_r_line) begin
			end_r_line		<= start_r_line;
			start_r_line	<= end_r_line;
		end
		
	end


	if (range == 0) begin				// Scale of 3.3V
	
		if ((hc == left_edge_3v3 + pervolt_3v3) ||
			 (hc == left_edge_3v3 + (pervolt_3v3 << 1)) ||
			 (hc == left_edge_3v3 + (pervolt_3v3 << 1) + pervolt_3v3))							// Green gradations at each volt
		begin
			video_r <= 8'h00;
			video_g <= 8'h3F;
			video_b <= 8'h00;
		end
		
		if (vc & 2) begin
			if ((hc == left_edge_3v3 + (pervolt_3v3 >> 1)) ||
			    (hc == left_edge_3v3 + pervolt_3v3 + (pervolt_3v3 >> 1)) ||
				 (hc == left_edge_3v3 + (pervolt_3v3 << 1) + (pervolt_3v3 >> 1)) )			// dotted line at each half-volt
			begin
				video_r <= 8'h00;
				video_g <= 8'h1F;
				video_b <= 8'h00;
			end
		end

		if (hc == (left_edge_3v3 + adc_avg_l[11:4])) begin											// light grey line for average (left)
			//video_r <= 8'h4F;
			video_g <= 8'h4F;
			video_b <= 8'h4F;
		end

		if (hc == (left_edge_3v3 + adc_avg_r[11:4])) begin											// light red line for average (right)
			//video_r <= 8'h7F;
			video_g <= 8'h00;
			video_b <= 8'h00;
		end


		if ((hc >= start_l_3v3) && (hc <= end_l_3v3)) begin										// draw the voltage measurement in white (left)
			//video_r <= 8'hBF;
			video_g <= 8'hBF;
			video_b <= 8'hBF;
		end

		if ((hc >= start_r_3v3) && (hc <= end_r_3v3)) begin										// draw the voltage measurement in red (right)
			video_r <= 8'hFF;
			video_g <= 8'h00;
			video_b <= 8'h00;
		end
		
	end
	else begin								// Line-level display
	
		if ((vc & 2) && (hc == left_edge + (limit >> 1)) ) begin									// halfway point - dotted line
			video_r <= 8'h00;
			video_g <= 8'h3F;
			video_b <= 8'h00;
		end

		if ((hc >= left_edge_audio) && (hc <= red_zone_l_audio)) begin							// shaded left red zone
			//video_r <= 8'h1F;
			video_g <= 8'h00;
			video_b <= 8'h00;
		end

		if ((hc >= red_zone_r_audio) && (hc <= (left_edge_audio + limit_audio))) begin	// shaded right red zone
			//video_r <= 8'h1F;
			video_g <= 8'h00;
			video_b <= 8'h00;
		end

		if ((hc >= start_l_line) && (hc <= end_l_line))														// draw wave in white (left)
		begin
			//video_r <= 8'hBF;
			video_g <= 8'hBF;
			video_b <= 8'hBF;
		end

		if ((hc >= start_r_line) && (hc <= end_r_line))														// draw wave in red (right)
		begin
			video_r <= 8'hFF;
			video_g <= 8'h00;
			video_b <= 8'h00;
		end

	end

	if (hc == left_edge) begin				// left edge marker
		//video_r <= 8'hFF;
		video_g <= 8'hFF;
		video_b <= 8'h00;
	end

	if (hc == left_edge + limit) begin	// right edge marker
		//video_r <= 8'hFF;
		video_g <= 8'hFF;
		video_b <= 8'h00;
	end


	if (hc == 427) HSync <= 0; //590
end


endmodule
