`timescale 1ns / 1ps
module Merge2#(
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst,
    input full,
    input men_from_local,
    input men_from_routing,
    input [DATA_WIDTH-1:0] din_from_local,
    input [DATA_WIDTH-1:0] din_from_routing,
    output reg [DATA_WIDTH-1:0] merge_out,
    output reg merge_wen,
    output reg wait_to_routing,
    output reg wait_to_local
);

//reg wait_local, wait_routing;
//assign wait_merge = wait_local | wait_routing;//いまはべつのモジュールからのパケット取り込み中だから新しくパケット読まないでとrenGenに伝える

always @(negedge clk) begin
    if(rst)begin
        merge_out <= 0;
        merge_wen <= 0;
        wait_to_local <= 0;
        wait_to_routing <= 0;
    end
    else if(!full)begin
        if(men_from_routing)begin//このフラグが立ってるあいだはパケット取り込める
            if(men_from_local)begin//外部パケット取り込み中にローカルパケットの取り込みのリクエストがきたとき
                wait_to_local <= 1;
            end
            merge_out <= din_from_routing;//外部パケット取り込み
            merge_wen <= 1;//バッファへの書き込み許可
            wait_to_routing <= 0;
        end
        else if(men_from_local)begin
            if(men_from_routing)begin
                wait_to_routing <= 1;
            end
            merge_out <= din_from_local;
            merge_wen <= 1;
            wait_to_local <= 0;
        end
        else begin
            merge_wen <= 0;
            //merge_out <= 0;
            wait_to_local <= 0;
            wait_to_routing <= 0;
        end
    end
end

endmodule