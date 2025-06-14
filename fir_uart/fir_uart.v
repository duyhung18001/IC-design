module uart#(
	parameter CLK_FRE = 50000000, BAUD_RATE = 115200)(
	input clk,rst,rx_in,start,
	output reg busy,
	output  tx_out,
	output rx_done
	);
	reg flag7;
	reg [7:0] temp_data;
	reg [7:0] counter_rx;
	wire [7:0] temp_text;
	wire [31:0] temp_result;
	reg start_handle;
	wire busy_handle;
	reg [31:0] data_in,temp_data_in;
	reg [31:0] delay_counter1 ,delay_counter3,delay_counter4;
	reg [31:0] delay_counter2; 
	reg [15:0] delay_counter;
	wire tx_done_tx;
	reg tx_en1,tx_en;
	reg flag,flag1,flag2,flag3,flag4,flag5,flag6,flag9,flag10,flag11;
	reg [7:0] flag8;
	wire tx_out1,tx_in;
	uart_rx u0(
		.clk(clk),
		.rst(rst),
		.rx(rx_in),
		.enable(1'b1),
		.rx_done(rx_done),
		.rx_out(temp_text)
	);
	
	FIR u1(
		.clk(clk),
		.data_in(data_in),
		.rst(rst),
		.start(start_handle),
		.busy(busy_handle),
		.data_out(temp_result)
	);
	reg enable_tx;
	uart_tx u3(
		.clk(clk),
		.rst(rst),
		.enable(enable_tx),
		.tx(tx_out1),
		.data_in(temp_result),
		.busy_tx(tx_done_tx)
	);
	assign tx_out  = tx_out1;
	always @(posedge clk or negedge rst) begin
		if (!rst || !start) begin
			start_handle <= 0;
			temp_data_in <= 0;
			data_in <= 0;
			enable_tx <= 0;
			busy <= 0;
			flag <= 0;
			flag1 <= 0;
			flag2 <= 0;
			flag3 <= 0;
			flag4 <= 0;
			flag5 <= 0;
			flag6 <=0;
			flag7 <= 0;
			flag8 <= 0;
			flag9 <= 0;
			flag10 <= 0;
			flag11 <= 0;
			tx_en <= 0;
			tx_en1 <= 0;
			counter_rx <= 0;
			delay_counter1 <= 32'd0;
			delay_counter <= 16'd0;
			delay_counter2 <= 32'd0;
			delay_counter3 <= 32'd0;
			delay_counter4 <=  32'd0;
		end else begin
			if (start && !busy) begin
				busy <= 1;
				flag <= 1;
				
			end else if (busy) begin
			      
				if(flag8 != 0) begin
				     case (flag8)
				        8'd4: begin
				                data_in[7:0] = temp_text;
				            end
				        8'd3: begin
				                data_in[15:8] = temp_text;
				            end
				        8'd2: begin
				                data_in[23:16] = temp_text ;
				            end
				        8'd1: begin
				                data_in[31:24] = temp_text ;
				            end 
				     endcase
				end 
				if (flag) begin
					// tx_out <= tx_in;
					if (counter_rx != 8'd4) begin
						if (rx_done) begin
							flag8 <= flag8 + 8'd1;		
							counter_rx <= counter_rx + 8'd1;
						end
                        end else begin
						counter_rx <= 0;
						flag <= 0;
						flag1 <= 1;
					end

				end else begin
				    if(flag1)begin
				        flag7 <= 1;
				        flag1 <= 0;
				        start_handle <= 1;
				    end 
				    if(flag7)begin
				        flag7<= 0;
				        start_handle <= 1;
				        flag2 <= 1;
				    end
				    if(flag2&&!busy_handle)begin
                            flag2 <= 0;
                            start_handle <= 0;
                            flag3 <= 1;
				    end 
				    if(flag3)begin
				        enable_tx <= 1;
				        flag3 <= 0;
				        flag4 <= 1;
				    end
				    if(flag4&&tx_done_tx)begin
				        enable_tx <= 0;
				        flag4<= 0;
				        flag6<= 1;
				    end
				
					if (flag6) begin
						if (tx_out1) begin
							busy <= 0;
							start_handle <= 0;
							temp_data_in <= 0;
							counter_rx <= 0;
							data_in <= 0;
							flag <= 0;
							flag1 <= 0;
							flag2 <= 0;
							flag3 <= 0;
							flag4 <= 0;
							flag5 <= 0;
							flag6 <=0;
							flag7 <= 0;
						end
					end
				end
			end
		end
	end
	
endmodule 

module FIR(clk,rst,start,busy,data_in,data_out);
	input clk,rst,start;
	input [31:0] data_in;
	output reg [31:0] data_out;
	output reg busy;
	
	parameter w0 = 32'b00000000000000000000000000000000;//0
	parameter w1 = 32'b00111110101100001010001111010111;//0.345
	parameter w2 = 32'b00111111011001111010111000010100;//0.905
	parameter w3 = 32'b00111111011001111010111000010100;//0.905
	parameter w4 = 32'b00111110101100001010001111010111;//0.345
	parameter w5 = 32'b00000000000000000000000000000000;//0
	
	parameter hd0 = 32'b00111101110110010001011010000111;//0.106
	parameter hd1 = 32'b10111110000011010100111111011111;//-0.138
	parameter hd2 = 32'b00111110001000101101000011100101;//0.159
	parameter hd3 = 32'b00111111010101000111101011100001;//5/6
	parameter hd4 = 32'b00111110001000101101000011100101;//0.159
	parameter hd5 = 32'b10111110000011010100111111011111;//-0.138
	
	wire [31:0] x1,x2,x3,x4,x5,h0,h1,h2,h3,h4,h5,y0,y1,y2,y3,y4,y5,temp0,temp1,temp2,temp3,temp4;
	reg [3:0] delay;
	
	DFF DFF0(clk,1,data_in,x1); //x[n-1]
	DFF DFF1(clk,1,x1,x2);//x[n-2]
	DFF DFF2(clk,1,x2,x3);//x[n-3]
	DFF DFF3(clk,1,x3,x4);//x[n-4]
	DFF DFF4(clk,1,x4,x5);//x[n-5]
	
	fp_mul mul0(w0,hd0,h0);
	fp_mul mul1(w1,hd1,h1);
	fp_mul mul2(w2,hd2,h2);
	fp_mul mul3(w3,hd3,h3);
	fp_mul mul4(w4,hd4,h4);
	fp_mul mul5(w5,hd5,h5);
	
	fp_mul mul6(h0,data_in,y0);
	fp_mul mul7(h1,x1,y1);
	fp_mul mul8(h2,x2,y2);
	fp_mul mul9(h3,x3,y3);
	fp_mul mul10(h4,x4,y4);
	fp_mul mul11(h5,x5,y5);
	
	fp_add add0(y0,y1,temp0);
	fp_add add1(temp0,y2,temp1);  
	fp_add add2(temp1,y3,temp2);
	fp_add add3(temp2,y4,temp3);
	fp_add add4(temp3,y5,temp4);
	
	always @(posedge clk or negedge rst) begin
		if (!rst) begin
			data_out <= 0;
			busy <= 0;
			delay <= 0;
		end else if(!busy) begin
		    busy <= 1;
		end else if (busy) begin 
		    if (delay == 4'd5 && busy) begin
		       data_out <= temp4;
		       busy <= 0;
		       delay <= 0;
		    end else begin
		       delay <= delay + 4'd1;
		    end
		end
	end
endmodule

module DFF(clk, rst, data_in, data_delay);
	input clk,rst;
	input [31:0] data_in;
	output reg [31:0] data_delay;
	
	always @(posedge clk or negedge rst) begin
		if (!rst) begin
			data_delay <= 0;
		end else begin
			data_delay <= data_in;
		end
	end
endmodule

module fp_mul (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] result
);

    wire sign_a = a[31];
    wire sign_b = b[31];
    wire [7:0] exp_a = a[30:23];
    wire [7:0] exp_b = b[30:23];
    wire [23:0] mant_a = (exp_a == 0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
    wire [23:0] mant_b = (exp_b == 0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};

    wire sign_result = sign_a ^ sign_b;
    wire [47:0] mant_mult = mant_a * mant_b;
    wire [8:0] exp_sum = exp_a + exp_b - 8'd127;

    reg [7:0] exp_final;
    reg [22:0] mant_final;

    always @(*) begin
        if (mant_mult[47]) begin
            exp_final = exp_sum + 1;
            mant_final = mant_mult[46:24];
        end else begin
            exp_final = exp_sum;
            mant_final = mant_mult[45:23];
        end
    end

    assign result = {sign_result, exp_final, mant_final};

endmodule

module fp_add (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] result
);
    // Tách các phần
    wire sign_a = a[31];
    wire sign_b = b[31];
    wire [7:0] exp_a = a[30:23];
    wire [7:0] exp_b = b[30:23];
    wire [23:0] frac_a = (exp_a == 0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
    wire [23:0] frac_b = (exp_b == 0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};

    // Căn chỉnh phần mũ
    wire [7:0] exp_diff = (exp_a > exp_b) ? (exp_a - exp_b) : (exp_b - exp_a);
    wire [7:0] exp_max  = (exp_a > exp_b) ? exp_a : exp_b;
    wire [23:0] aligned_a = (exp_a > exp_b) ? frac_a : (frac_a >> exp_diff);
    wire [23:0] aligned_b = (exp_b > exp_a) ? frac_b : (frac_b >> exp_diff);

    // Cộng hoặc trừ phần đặc trị
    reg [24:0] mant_sum;
    reg result_sign;
    always @(*) begin
        if (sign_a == sign_b) begin
            mant_sum = aligned_a + aligned_b;
            result_sign = sign_a;
        end else begin
            if (aligned_a > aligned_b) begin
                mant_sum = aligned_a - aligned_b;
                result_sign = sign_a;
            end else begin
                mant_sum = aligned_b - aligned_a;
                result_sign = sign_b;
            end
        end
    end

    // Chuẩn hóa phần đặc trị
    reg [24:0] norm_mant;
    reg [7:0]  final_exp;
    reg [22:0] final_frac;
    integer shift_amt;
    
    always @(*) begin
        norm_mant = mant_sum;
        final_exp = exp_max;

        if (norm_mant[24]) begin
            norm_mant = norm_mant >> 1;
            final_exp = final_exp + 1;
        end else begin
            shift_amt = 0;
            if (norm_mant[23] == 0) begin
                if (!norm_mant[22]) shift_amt = shift_amt + 1;
                if (!norm_mant[21 - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[20 - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[19 - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[18 - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[17 - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[16 - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[15 - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[14 - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[13 - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[12 - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[11 - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[10 - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[9  - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[8  - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[7  - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[6  - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[5  - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[4  - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[3  - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[2  - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[1  - shift_amt]) shift_amt = shift_amt + 1;
                if (!norm_mant[0  - shift_amt]) shift_amt = shift_amt + 1;

                norm_mant = norm_mant << shift_amt;
                final_exp = final_exp - shift_amt;
            end
        end

        final_frac = norm_mant[22:0]; // bỏ bit ẩn
    end

    // Kiểm tra zero
    wire is_zero = (mant_sum == 0);
    assign result = is_zero ? 32'b0 : {result_sign, final_exp, final_frac};
endmodule

module uart_rx#(
		parameter CLK_FRE = 50000000, CLK_UART = 115200
)(
	input clk, rst, rx, enable,
	output reg rx_done,
	output reg [7:0] rx_out
);
	//parameter CLK_FRE = 50000000, CLK_UART = 115200;
	reg [15:0] counter;
	reg data_re, flag;
	reg [9:0] mem_buffer;
	
	always @(posedge clk or negedge rst) begin
		if (!rst) begin
			rx_done <= 0;
			mem_buffer <= 0;
			counter <= 0;
			data_re <= 0;
			rx_out <= 8'hff;
			flag <= 0;
		end else if (enable) begin
			if (counter == 16'd0 && rx == 1'b0) begin
				data_re <= 1'b1;
			end else if (data_re) begin
				case (counter) 
					CLK_FRE/(CLK_UART*2) * 1: mem_buffer[0] <= rx;
					CLK_FRE/(CLK_UART*2) * 3: mem_buffer[1] <= rx;
					CLK_FRE/(CLK_UART*2) * 5: mem_buffer[2] <= rx;
					CLK_FRE/(CLK_UART*2) * 7: mem_buffer[3] <= rx;
					CLK_FRE/(CLK_UART*2) * 9: mem_buffer[4] <= rx;
					CLK_FRE/(CLK_UART*2) * 11: mem_buffer[5] <= rx;
					CLK_FRE/(CLK_UART*2) * 13: mem_buffer[6] <= rx;
					CLK_FRE/(CLK_UART*2) * 15: mem_buffer[7] <= rx;
					CLK_FRE/(CLK_UART*2) * 17: mem_buffer[8] <= rx;
					CLK_FRE/(CLK_UART*2) * 19: begin
						mem_buffer[9] <= rx;
						data_re <= 1'b0;
						flag <= 1;
						rx_done <= 1;
					end
				endcase
			end
			if (data_re) begin
				counter <= counter + 1;
			end else begin
				rx_done <= 0;
				counter <= 0;
				if (flag) begin
					rx_out <= mem_buffer[8:1];
					flag <= 0;
				end
				mem_buffer <= 0;
			end
		end
	end

endmodule

module uart_tx( 
     
    input clk, rst, enable, 
    input [31:0] data_in, 
    output reg busy_tx, tx 
); 
    parameter CLK_FRE = 50000000, CLK_UART = 115200;
    reg [15:0] counter2, counter4; 
    reg flag; 
    reg [7:0] mem[3:0]; 
    reg mem_buffer;
    reg [7:0] mem_buffer1; 
    reg [15:0] tx_counter; 
    always @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            mem [0]<= 8'b00000000; 
            mem [1]<= 8'b00000000; 
            mem [2]<= 8'b00000000; 
            mem [3]<= 8'b00000000; 
            busy_tx <= 0; 
            mem_buffer1 <= 0; 
            tx <= 1'b1;    
            counter2 <= 16'd0; 
            counter4 <= 16'd0;   
            flag <= 0; 
            tx_counter <= 4'd0;    
        end else if (enable) begin 
            mem [0]<= data_in[31:24];  
            mem [1]<= data_in[23:16];   
            mem [2]<= data_in[15:8];   
            mem [3]<= data_in[7:0];    
            if (tx_counter < 16'd4) begin 
                mem_buffer1 <= mem[tx_counter]; 
                counter2 <= counter2 + 16'd1; 
                    case (counter2)  
                        CLK_FRE/CLK_UART * 0 : tx <= 0; 
                        CLK_FRE/CLK_UART * 1 : tx <= mem_buffer1[0]; 
                        CLK_FRE/CLK_UART * 2 : tx <= mem_buffer1[1]; 
                        CLK_FRE/CLK_UART * 3 : tx <= mem_buffer1[2]; 
                        CLK_FRE/CLK_UART * 4 : tx <= mem_buffer1[3]; 
                        CLK_FRE/CLK_UART * 5 : tx <= mem_buffer1[4]; 
                        CLK_FRE/CLK_UART * 6 : tx <= mem_buffer1[5]; 
                        CLK_FRE/CLK_UART * 7 : tx <= mem_buffer1[6]; 
                        CLK_FRE/CLK_UART * 8 : tx <= mem_buffer1[7]; 
                        CLK_FRE/CLK_UART * 9 : begin 
                        tx <= 1; 
                        counter2 <= 16'd0; 
                        tx_counter <= tx_counter + 1; 
// counter4 <= counter4 + 1;  
                        end 
                    endcase 
                     
            end else begin 
                tx <= 1; 
                busy_tx <= 1; 
            end 
        end  else begin 
           tx    <= 1'b1;  
           counter2  <= 16'd0; 
           counter4  <= 16'd0;   
           flag   <= 0; 
           busy_tx  <= 0; 
           tx_counter  <= 16'd0;   
           mem [0]<= 8'b00000000; 
           mem [1]<= 8'b00000000; 
           mem [2]<= 8'b00000000; 
           mem [3]<= 8'b00000000; 
       end 
end

endmodule 