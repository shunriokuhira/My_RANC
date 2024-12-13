`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Merge2.v
//
// A two input "non-deterministic" merge.
// Arbitrates reads between two buffers.
// Port a is given priority over port b.
//////////////////////////////////////////////////////////////////////////////////


module Merge2#(
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] din_a,//東または西からのパケット
    input buffer_a_empty,//東または西コアのバッファが空かどうかをマージに知らせる信号
    input [DATA_WIDTH-1:0] din_b,//Fromlocalモジュールからのパケット
    input buffer_b_empty,//fromローカルモジュールのバッファが空かどうかをマージに知らせる信号
    input buffer_out_full,//routing_buffer_full | north_buffer_full | south_buffer_full 全員満タンであることをしめす
    output reg read_en_a,//ルーター外に送信する信号で、宛先コアのバッファへの書き込み許可信号
    output reg read_en_b,//ルーター外に送信する信号で、フロムローカルモジュール内バッファへの書き込み許可信号。　トークンコントローラに渡る
    output reg [DATA_WIDTH-1:0] dout,
    output reg wen
    );
    
    initial begin
        read_en_a <= 0;
        read_en_b <= 0;
        dout <= 0;
        wen <= 0;
    end
    
    always@(negedge clk) begin
        if (rst) begin
            read_en_a <= 0;
            read_en_b <= 0;
            dout <= 0;
            wen <= 0;
        end
        else if (!buffer_out_full) begin//routing_buffer、north_buffer、south_bufferが満タンでない
            if (read_en_a || read_en_b) begin
                wen <= 1;
                dout <= read_en_a ? din_a : din_b;//din_aは外からのパケット、din_bはCSRAMからのパケット
                read_en_a <= 0;
                read_en_b <= 0;
            end
            else begin
                wen <= 0;
                if (!buffer_a_empty) begin//buffer_aが空でない？
                    read_en_a <= 1;
                end
                else if (!buffer_b_empty) begin
                    read_en_b <= 1;
                end
            end
        end
    end
   
endmodule
