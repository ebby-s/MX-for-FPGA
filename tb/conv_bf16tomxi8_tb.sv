module conv_bf16tomxi8_tb();

    // Generate clock and reset.
    logic clk;
    logic rst_n;

    initial begin
        clk = 0;
        forever
            #10 clk = ~clk;
    end

    initial begin
        rst_n = 0;
        #10
        rst_n = 1;
    end










endmodule
