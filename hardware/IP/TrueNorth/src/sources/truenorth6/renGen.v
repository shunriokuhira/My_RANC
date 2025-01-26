`timescale 1ns / 1ps
module renGen(
    input clk,
    input rst,
    input empty,
    input full,
    input wait_renGen,
    output reg ren
);


always @(negedge clk) begin
    if(rst)begin
        ren <= 0;
    end
    else if(!full & !wait_renGen)begin//外部のバッファ満タンでないかつwait信号きてない
        if(!empty)begin//自身のバッファが空でない
            ren <= 1;
        end
        else begin
            ren <= 0;
        end
    end
    else begin
        ren <= 0;
    end
end
endmodule