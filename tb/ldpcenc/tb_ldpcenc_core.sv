//==============================================================================
// tb_ldpcenc_core.sv
//
// Testbench for module ldpcenc_core.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


`timescale 1 ns / 1 ps


module tb_ldpcenc_core;

//------------------------------------------------------------------------------
// Parameters
parameter real ClkPeriod = 10.0;
parameter real Dly = 1.0;
parameter string TcDir = "../../case/ldpcenc";


// Global variables
string testfile;
int cwlen;
int rate;
int nb;
int kb;
bit [26:0] cw_ref [200];
bit [26:0] cw_rtl [200];
int fp_tc;
int num_test;
int num_fail;


// Signals
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
logic eop_out;              // output end of packet
logic [26:0] data_out;      // output data
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Instance
ldpcenc_core dut (.*);


// System signals
initial begin
    clk = 1'b0;
    forever #(ClkPeriod/2)    clk = ~clk;
end

initial begin
    rst_n = 1'b0;
    #(ClkPeriod*4);
    rst_n = 1'b1;
end
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Driver
task automatic driver;
    int n;

    wait (rdy_in);
    for (n = 0; n < kb; n++) begin
        @(posedge clk);    #Dly;
        vld_in = 1'b1;
        sop_in = (n == 0) ? 1'b1 : 1'b0;
        mode_in = cwlen * 4 + rate;
        data_in = cw_ref[n];
    end
    @(posedge clk);    #Dly;
    vld_in = 1'b0;
    sop_in = 1'b0;
    mode_in = 4'h0;
    data_in = 27'h0;
endtask


// Monitor
task automatic monitor;
    int n;

    n = 0;
    forever begin
        @(negedge clk);
        if (vld_out) begin
            cw_rtl[n] = data_out;
            if (eop_out)
                break;
            else
                n++;
        end
    end
endtask


// Compare reference and RTL data
task automatic compare;
    int n;

    num_test++;
    for (n = 0; n < nb; n++) begin
        if (cw_ref[n] != cw_rtl[n]) begin
            $display("[SIM]  Fail");
            num_fail++;
            return;
        end
    end
    $display("[SIM]  Pass");
endtask


// Run each testcase data
task automatic run_tc;
    fork
        driver;
        monitor;
    join
    #(ClkPeriod*10);
    compare;
endtask


// Parse testcase file
task automatic parse_tc;
    const int VecNb[3] = '{24, 48, 72};
    string fn_tc;
    string str_line;
    int code;
    int idx;
    int state_rd;
    int case_num;
    int cnt;

    fn_tc = {TcDir, "/", testfile};
    fp_tc = $fopen(fn_tc, "r");
    if (fp_tc == 0) begin
        $display("[ERROR]  Fail to open file %s for reading.", fp_tc);
        $finish;
    end

    state_rd = 0;
    forever begin
        code = $fgets(str_line, fp_tc);
        if ($feof(fp_tc) || (code == 0))    break;
        idx = str_line.len() - 1;
        while (idx >= 0 && str_line.getc(idx) < 32)    idx--;
        if (idx < 0)    continue;    // blank line
        str_line = str_line.substr(0, idx);    // drop newline
        if (str_line.substr(0, 0) == "#")    continue;    // comment line

        if (state_rd == 0) begin    // read "Case n"
            code = $sscanf(str_line, "Case %d", case_num);
            $display("[SIM]  Running testcase #%0d", case_num);
            state_rd = 1;
        end
        else if (state_rd == 1) begin    // read CwLen
            code = $sscanf(str_line, "%d", cwlen);
            if (cwlen < 0 || cwlen > 2) begin
                $display("[ERROR]  Invalid cwlen value %0d, should be 0 ~ 2.", cwlen);
                $finish;
            end
            $display("[SIM]  CwLen = %0d", cwlen);
            nb = VecNb[cwlen];
            state_rd = 2;
        end
        else if (state_rd == 2) begin    // read Rate
            code = $sscanf(str_line, "%d", rate);
            if (rate < 0 || rate > 3) begin
                $display("[ERROR]  Invalid rate value %0d, should be 0 ~ 3.", rate);
                $finish;
            end
            $display("[SIM]  Rate = %0d", rate);
            cnt = 0;
            kb = (rate == 0) ? nb/2 : (rate == 1) ? nb*2/3 : (rate == 2) ? nb*3/4 : nb*5/6;
            state_rd = 3;
        end
        else if (state_rd == 3) begin    // read CW[i]
            code = $sscanf(str_line, "%x", cw_ref[cnt]);
            cnt++;
            if (cnt == nb) begin
                run_tc;
                state_rd = 0;
            end
        end
        else begin
            $display("[ERROR]  Invalid state_rd value %0d.", state_rd);
            $finish;
        end
    end

    $fclose(fp_tc);
endtask


// Run simulation
task automatic run_sim;
    parameter string StrPass = {
        "                   \n",
        "               #   \n",
        "              #    \n",
        "             #     \n",
        "     #      #      \n",
        "      #    #       \n",
        "       #  #        \n",
        "        ##         \n",
        "                   \n"
    };
    parameter string StrFail = {
        "                   \n",
        "    #           #  \n",
        "      #       #    \n",
        "        #   #      \n",
        "          #        \n",
        "        #   #      \n",
        "      #       #    \n",
        "    #           #  \n",
        "                   \n"
    };

    num_test = 0;
    num_fail = 0;

    srst = 1'b0;
    vld_in = 1'b0;
    sop_in = 1'b0;
    mode_in = 4'h0;
    data_in = 27'h0;

    #(ClkPeriod*10);

    parse_tc;

    $display("[INFO]  Simulation complete.");
    if (num_fail == 0) begin
        $display("%s", StrPass);
        $display("PASS  (Total %0d)", num_test);
    end
    else begin
        $display("%s", StrFail);
        $display("FAIL  (Total %0d / Fail %0d)", num_test, num_fail);
    end
endtask
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Main process
initial begin
    if ($value$plusargs("TESTFILE=%s", testfile)) begin
        $display("[INFO]  Test file \"%s\" is loaded.", testfile);
    end
    else begin
        $display("[ERROR]  Test file is not specified. Should use runtime option \"+TESTFILE=testfile\"");
        $finish;
    end

    run_sim;

    #(ClkPeriod*100);
    $finish;
end
//------------------------------------------------------------------------------


endmodule
