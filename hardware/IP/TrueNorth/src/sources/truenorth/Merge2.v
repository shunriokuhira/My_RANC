`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Merge2.v
//
// A two input "non-deterministic" merge.
// Arbitrates reads between two buffers.2つのバッファ間のリードを調停する。
// Port a is given priority over port b.ポートaはポートbより優先される。
//////////////////////////////////////////////////////////////////////////////////


module Merge2#(
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] din_a,//東または西からのパケット
    input buffer_a_empty,//東または西コアのrootingバッファが空かどうかをマージ(このモジュール)に知らせる信号
    input men_a,

    input [DATA_WIDTH-1:0] din_b,//Fromlocalモジュールからのパケット
    input buffer_b_empty,//fromローカルモジュールのバッファが空かどうかをマージ(このモジュール)に知らせる信号
    input men_b,
    
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
    /*we信号はread_en信号に反応し、read_enはbuffer_empty信号に反応
    
    */
    always@(negedge clk) begin
        if (rst) begin
            read_en_a <= 0;
            read_en_b <= 0;
            dout <= 0;
            wen <= 0;
        end
        else if (!buffer_out_full) begin//routing_buffer、north_buffer、south_bufferが満タンでない
            if (read_en_a) begin
                if(men_a)begin
                    dout <= din_a;
                end
                wen <= 1;
                read_en_a <= 0;
            end
            else if(read_en_b)begin
                if(men_b)begin
                    dout <= din_b;
                end
                wen <= 1;
                read_en_b <= 0;
            end
            else begin
                wen <= 0;
                if (!buffer_a_empty) begin//東または西コアのrooting_bufferが空ではない(バッファの深さいっぱいにデータが溜まって初めて満タンとよべる。)
                    read_en_a <= 1;//外部からパケットとりにいく
                end
                else if (!buffer_b_empty) begin
                    read_en_b <= 1;
                end
            end
        end
    end
   
endmodule
