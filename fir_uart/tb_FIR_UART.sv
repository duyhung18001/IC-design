module tb_uart_fir;

    reg clk = 0, rst = 0;
    reg start = 0;
    reg rx_in = 1;
    wire tx_out;
    wire rx_done;
    wire busy;

    // Instantiate the uart module
    uart uut (
        .clk(clk),
        .rst(rst),
        .rx_in(rx_in),
        .start(start),
        .busy(busy),
        .tx_out(tx_out),
        .rx_done(rx_done)
    );

    localparam BAUD_RATE = 115200;     
    localparam CYCLE = 50000000 / BAUD_RATE; // 50MHz clock, tính số chu kỳ giữa các bit

    // Clock generation
    always #10 clk = ~clk; // 50MHz

    // Task gửi 1 byte qua rx_in (UART RX)
    task send_byte(input [7:0] data); 
        integer i; 
        begin 
            rx_in = 0; // start bit
            repeat(CYCLE) @(posedge clk); 
            for (i = 0; i < 8; i = i + 1) begin 
                rx_in = data[i]; 
                repeat(CYCLE) @(posedge clk);  
            end 
            rx_in = 1; // stop bit
            repeat(CYCLE) @(posedge clk);  
        end 
    endtask

    initial begin
        // Reset
        rst = 0;
        #100;
        rst = 1;

        start = 1;

        #200;
        
        send_byte(8'b01000000);
        send_byte(8'b01000110);
        send_byte(8'b01100110);
        send_byte(8'h01100110);

        // Đợi xử lý và truyền ngược
        #1000000;

        $stop;
    end

endmodule