module tb_FIR();
	reg clk,rst;
	reg [31:0] data_in;
	wire [31:0] data_out;
	wire busy;
	
	FIR FIR_0(
		.clk(clk),
		.rst(rst),
		.data_in(data_in),
		.data_out(data_out),
		.busy(busy)
	);
	
	always #5 clk = ~clk;
	
	initial begin
		clk = 0;
		rst = 0;
		#10; rst = 1;
		#10;
		     data_in = 32'b00111111100000000000000000000000;		
		#10; data_in = 32'b00111111000000000000000000000000;
		#10; data_in = 32'b10111111000000000000000000000000;
		#10; data_in = 32'b00111110100110011001100110011010;
		#10; data_in = 32'b10111110100110011001100110011010;
		#10; data_in = 32'b00111110010011001100110011001101;
		#10; data_in = 32'b10111110010011001100110011001101;
		#10; data_in = 32'b00000000000000000000000000000000;


		
		$finish;
	end
endmodule