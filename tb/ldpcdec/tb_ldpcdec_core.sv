//==============================================================================
// tb_ldpcdec_core.sv
//
// Testbench for module ldpcdec_core.
//------------------------------------------------------------------------------
// Copyright (c) 2026 Guangxi Liu
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//==============================================================================


`timescale 1 ns / 1 ps


`include "ldpcdec_cfg.vh"


module tb_ldpcdec_core;

//------------------------------------------------------------------------------
// Parameters
parameter real ClkPeriod = 10.0;
parameter real Dly = 1.0;
parameter string TcDir = "../../case/ldpcdec";


// Global variables
string testfile;
int mode;
int nb;
int kb;
int maxit;
bit sc;
bit et;
bit [`W_IN*27-1:0] din [200];
bit [5:0] num_iter_ref, num_iter_rtl;
bit pc_ref, pc_rtl;
bit [26:0] dout_ref [200];
bit [26:0] dout_rtl [200];
int fp_tc;
int num_test;
int num_fail;


// Signals
logic clk;                      // system clock
logic rst_n;                    // system asynchronous reset, active low
logic srst;                     // synchronous reset
logic vld_in;                   // input data valid
logic sop_in;                   // input start of packet
logic [3:0] mode_in;            // decoder mode, [1:0]:rate, [3:2]:codeword length
logic [5:0] max_iter;           // maximum iteration, 1 - 63
logic sc_sel;                   // scaling factor for normalized min-sum
logic early_term;               // early terminate decoding
logic [`W_IN*27-1:0] data_in;   // input LLR data
logic rdy_in;                   // ready to receive input data
logic vld_out;                  // output data valid
logic sop_out;                  // output start of packet
logic eop_out;                  // output end of packet
logic [5:0] num_iter;           // output actual number of iterations
logic pc;                       // output parity check result
logic [26:0] data_out;          // output data
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Instance
ldpcdec_core dut (.*);


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
    for (n = 0; n < nb; n++) begin
        @(posedge clk);    #Dly;
        vld_in = 1'b1;
        sop_in = (n == 0) ? 1'b1 : 1'b0;
        mode_in = mode;
        max_iter = maxit;
        sc_sel = sc;
        early_term = et;
        data_in = din[n];
    end
    @(posedge clk);    #Dly;
    vld_in = 1'b0;
    sop_in = 1'b0;
    mode_in = 4'h0;
    max_iter = 6'd0;
    sc_sel = 1'b0;
    early_term = 1'b0;
    data_in = 27'h0;
endtask


// Monitor
task automatic monitor;
    int n;

    n = 0;
    forever begin
        @(negedge clk);
        if (vld_out) begin
            if (sop_out) begin
                num_iter_rtl = num_iter;
                pc_rtl = pc;
            end
            dout_rtl[n] = data_out;
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

    if (num_iter_ref != num_iter_rtl)
        $display("[SIM]  Fail! num_iter mismatch");
    else
        $display("[SIM]  Output: num_iter = %0d", num_iter_rtl);

    if (pc_ref != pc_rtl)
        $display("[SIM]  Fail! pc mismatch");
    else
        $display("[SIM]  Output: pc = %0d", pc_rtl);

    for (n = 0; n < kb; n++) begin
        if (dout_ref[n] != dout_rtl[n]) begin
            $display("[SIM]  Fail! data_out[%0d] mismatch", n);
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
    int cwlen;
    int rate;
    bit [`W_IN-1:0] llr [27];
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
        else if (state_rd == 1) begin    // read `mode_in`
            code = $sscanf(str_line, "%d", mode);
            if (mode < 0 || mode > 11) begin
                $display("[ERROR]  Invalid mode value %0d, should be 0 ~ 11.", mode);
                $finish;
            end
            cwlen = mode / 4;
            rate = mode % 4;
            $display("[SIM]  Input: mode_in = %0d", mode);
            nb = VecNb[cwlen];
            kb = (rate == 0) ? nb/2 : (rate == 1) ? nb*2/3 : (rate == 2) ? nb*3/4 : nb*5/6;
            state_rd = 2;
        end
        else if (state_rd == 2) begin    // read `max_iter`
            code = $sscanf(str_line, "%d", maxit);
            if (maxit < 0 || maxit > 63) begin
                $display("[ERROR]  Invalid max_iter value %0d, should be 0 ~ 63.", maxit);
                $finish;
            end
            $display("[SIM]  Input: max_iter = %0d", maxit);
            state_rd = 3;
        end
        else if (state_rd == 3) begin    // read `sc_sel`
            code = $sscanf(str_line, "%d", sc);
            if (sc != 0 && sc != 1) begin
                $display("[ERROR]  Invalid sc_sel value %0d, should be 0 or 1.", sc);
                $finish;
            end
            $display("[SIM]  Input: sc_sel = %0d", sc);
            state_rd = 4;
        end
        else if (state_rd == 4) begin    // read `early_term`
            code = $sscanf(str_line, "%d", et);
            if (et != 0 && et != 1) begin
                $display("[ERROR]  Invalid early_term value %0d, should be 0 or 1.", et);
                $finish;
            end
            $display("[SIM]  Input: early_term = %0d", et);
            cnt = 0;
            state_rd = 5;
        end
        else if (state_rd == 5) begin    // read `data_in`
            code = $sscanf(str_line, "%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x",
                llr[0], llr[1], llr[2], llr[3], llr[4], llr[5], llr[6], llr[7], llr[8],
                llr[9], llr[10], llr[11], llr[12], llr[13], llr[14], llr[15], llr[16], llr[17],
                llr[18], llr[19], llr[20], llr[21], llr[22], llr[23], llr[24], llr[25], llr[26]);
            din[cnt] = {
                llr[26], llr[25], llr[24], llr[23], llr[22], llr[21], llr[20], llr[19], llr[18],
                llr[17], llr[16], llr[15], llr[14], llr[13], llr[12], llr[11], llr[10], llr[9],
                llr[8], llr[7], llr[6], llr[5], llr[4], llr[3], llr[2], llr[1], llr[0]
            };
            cnt++;
            if (cnt == nb) begin
                state_rd = 6;
            end
        end
        else if (state_rd == 6) begin    // read `num_iter`
            code = $sscanf(str_line, "%d", num_iter_ref);
            state_rd = 7;
        end
        else if (state_rd == 7) begin    // read `pc`
            code = $sscanf(str_line, "%d", pc_ref);
            cnt = 0;
            state_rd = 8;
        end
        else if (state_rd == 8) begin    // read `data_out`
            code = $sscanf(str_line, "%x", dout_ref[cnt]);
            cnt++;
            if (cnt == kb) begin
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
    max_iter = 6'd0;
    sc_sel = 1'b0;
    early_term = 1'b0;
    data_in = 'h0;

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
