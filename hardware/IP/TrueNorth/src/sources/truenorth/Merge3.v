`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Merge3.v
//
// A three input "non-deterministic" merge.
// Arbitrates reads between three buffers.
// Port a is given priority over port b, port b is given priority over port c.
//////////////////////////////////////////////////////////////////////////////////


module Merge3#(
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] din_a,
    input buffer_a_empty,
    input men_a, //wen_a からwen_cはマージモジュールに対する書き込み許可。バッファではない

    input [DATA_WIDTH-1:0] din_b,
    input buffer_b_empty,
    input men_b,

    input [DATA_WIDTH-1:0] din_c,
    input buffer_c_empty,
    input men_c,

    input buffer_out_full,
    output reg read_en_a,
    output reg read_en_b,
    output reg read_en_c,
    output reg [DATA_WIDTH-1:0] dout,
    output reg wen
    );
    
    initial begin
        read_en_a <= 0;
        read_en_b <= 0;
        read_en_c <= 0;
        dout <= 0;
        wen <= 0;
    end
    
    always@(negedge clk) begin
        if (rst) begin
            read_en_a <= 0;
            read_en_b <= 0;
            read_en_c <= 0;
            dout <= 0;
            wen <= 0;
        end
        else if (!buffer_out_full) begin
            if (read_en_a) begin
                if(men_a)begin
                    dout <= din_a;
                end
                wen <= 1;
                read_en_a <= 0;
            end
            else if (read_en_b) begin
                if(men_b)begin
                    dout <= din_b;
                end
                wen <= 1;
                read_en_b <= 0;
            end
            else if (read_en_c) begin
                if(men_c)begin
                    dout <= din_c;
                end
                wen <= 1;
                read_en_c <= 0;
            end
            else begin
                wen <= 0;
                if (!buffer_a_empty) begin
                    read_en_a <= 1;
                end
                else if (!buffer_b_empty) begin
                    read_en_b <= 1;
                end
                else if (!buffer_c_empty) begin
                    read_en_c <= 1;
                end
            end
        end
    end
   
endmodule
