`timescale 1ns/1ps

module example_tb;

    logic clk;
    logic rst_n;
    logic data_in;
    logic data_out;

    example dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (data_in),
        .data_out (data_out)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n   = 1'b0;
        data_in = 1'b0;

        #20;
        rst_n = 1'b1;

        #20;
        data_in = 1'b1;

        #20;
        data_in = 1'b0;

        #20;
        $finish;
    end

endmodule