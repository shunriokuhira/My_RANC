`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Scheduler.v
//
// Created for Dr. Akoglu's Reconfigurable Computing Lab
//  at the University of Arizona
// 
// Handles reads and writes to the SchedulerSRAM
// スケジューラSRAMへの読み書きを処理する。
//////////////////////////////////////////////////////////////////////////////////

module Scheduler #(
    parameter NUM_AXONS = 256,
    parameter NUM_TICKS = 16
)(
    input clk,
    input rst,
    input wen,//from router
    input set,//from controller
    input clr,
    input [$clog2(NUM_AXONS) + $clog2(NUM_TICKS) - 1:0] packet,//from router
    output [NUM_AXONS-1:0] axon_spikes,//to controller
    output error//to testbench
);
    
    wire [$clog2(NUM_TICKS)-1:0] read_address;
    wire read_equal_write;
    wire read_equal_write_and_not_set;
    
    assign read_equal_write = read_address == (packet[3:0] + read_address + 1) ? 1'b1 : 1'b0;//(packet[3:0] + read_address + 1)はwrite_addressそのもの
    assign read_equal_write_and_not_set = read_equal_write & ~set;//setが来てなくてreadとwriteが同じ値
    assign error = read_equal_write_and_not_set & wen;//
    
    SchedulerSRAM #(
        .NUM_AXONS(NUM_AXONS),
        .NUM_TICKS(NUM_TICKS)
    ) SRAM (
        .packet(packet),
        .clr(clr),
        .read_address(read_address),
        .rst(rst),
        .wen(wen),
        .out(axon_spikes),
        .clk(clk)
    );
    
    Counter #(
        .DATA_WIDTH($clog2(NUM_TICKS))
    ) counter (
        .wen(set),
        .clk(clk),
        .out(read_address)//ここでread_addressは作られる。setに反応してインクリメント
    );
    
endmodule
