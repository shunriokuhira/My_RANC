`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// SchedulerSRAM.v
//
// Created for Dr. Akoglu's Reconfigurable Computing Lab
//  at the University of Arizona
// 
// Stores spikes that are to be processed for a core.
// コアのために処理されるスパイクを格納する。
//////////////////////////////////////////////////////////////////////////////////

module SchedulerSRAM #(
    parameter NUM_AXONS = 256,
    parameter NUM_TICKS = 16
)(
    input clk,
    input rst,
    input clr,
    input wen,//from router
    input [$clog2(NUM_TICKS)-1:0] read_address,
    input [$clog2(NUM_AXONS) + $clog2(NUM_TICKS) - 1:0] packet,
    output reg [NUM_AXONS-1:0] out
);

    reg [NUM_AXONS-1:0] memory [0:NUM_TICKS-1]; // Internal memroy of the Core SRAM 
    
    wire [$clog2(NUM_TICKS)-1:0] write_address;
    
    integer i;
    
    initial begin
        out <= 0;
        for(i = 0; i < NUM_TICKS; i = i + 1)begin
            memory[i] <= 0;
        end
    end
    
    /*多分、NUM_TICKSは固定値で、read_addressが変わったタイミングで、wite_addressも変わる
    packet[$clog2(NUM_TICKS)-1:0]はpacket[3:0]で、パケット内のtick instance部に該当
    wite_addressはread_addressより(packet[3:0] + 1)分多い。その理由としてread_adressで読まれるメモリ内容はいま
    現在コントローラ側で処理最中なのでwrite_addressとread_addressがおんなじになると厄介。(読み出し中に書き込んじゃうと値かわるので)
    なのでwrite_addressとして指定してもいいのは、最低でもread_address + 1からであり、packet[3:0]というのは
    "read_adress + 1"を基準からのオフセット値である*/
    assign write_address = packet[$clog2(NUM_TICKS)-1:0] + read_address + 1;

    always@(posedge clk) begin
        if(rst || clr) begin
            memory[read_address] <= 0;
        end
        else if(wen) begin//wenはルーターからの信号
            memory[write_address][packet[$clog2(NUM_AXONS) + $clog2(NUM_TICKS)-1:$clog2(NUM_TICKS)]] <= 1'b1;
            /*packet[$clog2(NUM_AXONS) + $clog2(NUM_TICKS)-1:$clog2(NUM_TICKS)]とはpacket[11:4]の8bitのことであり、
            packet内のaxon destination部に等しい。packet[11:4]がmemory[write_adress]全体の、どこのビットを
            有効(1にすること)にするか決定ずける。なのでpacket[11:4]の値は0から255の中の範囲内、もしpacket[11:4]の値が4なら
            memory[write_adress]の4bit目を1にする。で、この操作そのものはどういうことを意味しているのか。
            packet[11:4]とweはルータからきた信号で、スパイクパケットの一種だとかんがえると、これらのスパイク信号が、
            ニューラルネットワークにおける入力軸索のどこへ入るかを決定ずけるのが、ここでの処理が意味するものかと思われる。*/
        end
    end

    always@(*) begin
        out <= memory[read_address];
    end 
    //↓↓gtkwaveからメモリ内見えないから無理やり出力
    wire [NUM_AXONS-1:0] mem_0, mem_1, mem_2, mem_3;
    assign mem_0 = memory[0];
    assign mem_1 = memory[1];
    assign mem_2 = memory[2];
    assign mem_3 = memory[3];

    wire [5:0] num_tick;
    assign num_tick = NUM_TICKS;
endmodule
