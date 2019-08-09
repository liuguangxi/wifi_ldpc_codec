//==============================================================================
// tb_ldpcenc.sv
//
// Testbench for module ldpcenc.
//------------------------------------------------------------------------------
// Copyright (c) 2019 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


`timescale 1 ns / 1 ps


module tb_ldpcenc;

// Parameters
parameter real ClkPeriod = 10.0;
parameter real Dly = 1.0;


// Local signals
logic clk;                  // system clock
logic rst_n;                // system asynchronous reset, active low
logic srst;                 // synchronous reset
logic vld_in;               // input data valid
logic sop_in;               // input start of packet
logic [3:0] mode_in;        // input encoder mode, [1:0]:rate, [3:2]:codeword length
logic [26:0] data_in;       // input data
logic rdy_in;               // ready to receive input data
logic vld_out;              // output data valid
logic sop_out;              // output start of packet
logic [26:0] data_out;      // output data


// Instances
ldpcenc u_ldpcenc (.*);


// System signals
initial begin
    clk <= 1'b0;
    forever #(ClkPeriod/2) clk = ~clk;
end

initial begin
    rst_n <= 1'b0;
    #(ClkPeriod*2) rst_n = 1'b1;
end


// Testcases
task tc_c648_r12();

for (int i = 0; i < 12; i++) begin
    @(posedge clk)    #Dly;
    if (i == 0) begin
        sop_in = 1'b1;
        mode_in = 4'b00_00;
    end
    else begin
        sop_in = 1'b0;
        mode_in = 4'b00_00;
    end
    vld_in = 1'b1;
    data_in = $urandom;
end
@(posedge clk)    #Dly;
vld_in = 0;
sop_in = 0;
mode_in = 0;
data_in = 0;

#(ClkPeriod*24);

endtask


task tc_c648_r23();

for (int i = 0; i < 16; i++) begin
    @(posedge clk)    #Dly;
    if (i == 0) begin
        sop_in = 1'b1;
        mode_in = 4'b00_01;
    end
    else begin
        sop_in = 1'b0;
        mode_in = 4'b00_00;
    end
    vld_in = 1'b1;
    data_in = $urandom;
end
@(posedge clk)    #Dly;
vld_in = 0;
sop_in = 0;
mode_in = 0;
data_in = 0;

#(ClkPeriod*24);

endtask


task tc_c648_r34();

for (int i = 0; i < 18; i++) begin
    @(posedge clk)    #Dly;
    if (i == 0) begin
        sop_in = 1'b1;
        mode_in = 4'b00_10;
    end
    else begin
        sop_in = 1'b0;
        mode_in = 4'b00_00;
    end
    vld_in = 1'b1;
    data_in = $urandom;
end
@(posedge clk)    #Dly;
vld_in = 0;
sop_in = 0;
mode_in = 0;
data_in = 0;

#(ClkPeriod*24);

endtask


task tc_c648_r56();

for (int i = 0; i < 20; i++) begin
    @(posedge clk)    #Dly;
    if (i == 0) begin
        sop_in = 1'b1;
        mode_in = 4'b00_11;
    end
    else begin
        sop_in = 1'b0;
        mode_in = 4'b00_00;
    end
    vld_in = 1'b1;
    data_in = $urandom;
end
@(posedge clk)    #Dly;
vld_in = 0;
sop_in = 0;
mode_in = 0;
data_in = 0;

#(ClkPeriod*24);

endtask


task tc_c1296_r12();

for (int i = 0; i < 24; i++) begin
    @(posedge clk)    #Dly;
    if (i == 0) begin
        sop_in = 1'b1;
        mode_in = 4'b01_00;
    end
    else begin
        sop_in = 1'b0;
        mode_in = 4'b00_00;
    end
    vld_in = 1'b1;
    data_in = $urandom;
end
@(posedge clk)    #Dly;
vld_in = 0;
sop_in = 0;
mode_in = 0;
data_in = 0;

#(ClkPeriod*48);

endtask


task tc_c1296_r23();

for (int i = 0; i < 32; i++) begin
    @(posedge clk)    #Dly;
    if (i == 0) begin
        sop_in = 1'b1;
        mode_in = 4'b01_01;
    end
    else begin
        sop_in = 1'b0;
        mode_in = 4'b00_00;
    end
    vld_in = 1'b1;
    data_in = $urandom;
end
@(posedge clk)    #Dly;
vld_in = 0;
sop_in = 0;
mode_in = 0;
data_in = 0;

#(ClkPeriod*48);

endtask


task tc_c1296_r34();

for (int i = 0; i < 36; i++) begin
    @(posedge clk)    #Dly;
    if (i == 0) begin
        sop_in = 1'b1;
        mode_in = 4'b01_10;
    end
    else begin
        sop_in = 1'b0;
        mode_in = 4'b00_00;
    end
    vld_in = 1'b1;
    data_in = $urandom;
end
@(posedge clk)    #Dly;
vld_in = 0;
sop_in = 0;
mode_in = 0;
data_in = 0;

#(ClkPeriod*48);

endtask


task tc_c1296_r56();

for (int i = 0; i < 40; i++) begin
    @(posedge clk)    #Dly;
    if (i == 0) begin
        sop_in = 1'b1;
        mode_in = 4'b01_11;
    end
    else begin
        sop_in = 1'b0;
        mode_in = 4'b00_00;
    end
    vld_in = 1'b1;
    data_in = $urandom;
end
@(posedge clk)    #Dly;
vld_in = 0;
sop_in = 0;
mode_in = 0;
data_in = 0;

#(ClkPeriod*48);

endtask


task tc_c1944_r12();

for (int i = 0; i < 36; i++) begin
    @(posedge clk)    #Dly;
    if (i == 0) begin
        sop_in = 1'b1;
        mode_in = 4'b10_00;
    end
    else begin
        sop_in = 1'b0;
        mode_in = 4'b00_00;
    end
    vld_in = 1'b1;
    data_in = $urandom;
end
@(posedge clk)    #Dly;
vld_in = 0;
sop_in = 0;
mode_in = 0;
data_in = 0;

#(ClkPeriod*72);

endtask


task tc_c1944_r23();

for (int i = 0; i < 48; i++) begin
    @(posedge clk)    #Dly;
    if (i == 0) begin
        sop_in = 1'b1;
        mode_in = 4'b10_01;
    end
    else begin
        sop_in = 1'b0;
        mode_in = 4'b00_00;
    end
    vld_in = 1'b1;
    data_in = $urandom;
end
@(posedge clk)    #Dly;
vld_in = 0;
sop_in = 0;
mode_in = 0;
data_in = 0;

#(ClkPeriod*72);

endtask


task tc_c1944_r34();

for (int i = 0; i < 54; i++) begin
    @(posedge clk)    #Dly;
    if (i == 0) begin
        sop_in = 1'b1;
        mode_in = 4'b10_10;
    end
    else begin
        sop_in = 1'b0;
        mode_in = 4'b00_00;
    end
    vld_in = 1'b1;
    data_in = $urandom;
end
@(posedge clk)    #Dly;
vld_in = 0;
sop_in = 0;
mode_in = 0;
data_in = 0;

#(ClkPeriod*72);

endtask


task tc_c1944_r56();

for (int i = 0; i < 60; i++) begin
    @(posedge clk)    #Dly;
    if (i == 0) begin
        sop_in = 1'b1;
        mode_in = 4'b10_11;
    end
    else begin
        sop_in = 1'b0;
        mode_in = 4'b00_00;
    end
    vld_in = 1'b1;
    data_in = $urandom;
end
@(posedge clk)    #Dly;
vld_in = 0;
sop_in = 0;
mode_in = 0;
data_in = 0;

#(ClkPeriod*72);

endtask


// Main process
int fpIn, fpOut;

initial begin
    fpIn = $fopen("ldpcenc_in.txt", "w");
    fpOut = $fopen("ldpcenc_out.txt", "w");

    srst = 0;
    vld_in = 0;
    sop_in = 0;
    mode_in = 0;
    data_in = 0;
    #(ClkPeriod*50)

    //tc_c648_r12();
    //tc_c648_r23();
    //tc_c648_r34();
    //tc_c648_r56();
    //tc_c1296_r12();
    //tc_c1296_r23();
    //tc_c1296_r34();
    //tc_c1296_r56();
    //tc_c1944_r12();
    //tc_c1944_r23();
    //tc_c1944_r34();
    tc_c1944_r56();

    #(ClkPeriod*50)
    $fclose(fpIn);
    $fclose(fpOut);
    $stop;
end


// Record data
always_ff @ (negedge clk) begin
    if (vld_in) begin
        for (int i = 0; i < 27; i++)
            $fwrite(fpIn, "%0d\n", data_in[i]);
    end
    if (vld_out) begin
        for (int i = 0; i < 27; i++)
            $fwrite(fpOut, "%0d\n", data_out[i]);
    end
end


endmodule
