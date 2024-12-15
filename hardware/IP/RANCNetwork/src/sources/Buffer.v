`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// buffer.v
//
// A simple buffer.
// Reads and writes are synchronous 読み取りと書き込みは同期
// Reset is synchronous active high. リセットは同期アクティブ・ハイ。
//
// NOTE: BUFFER_DEPTH has to be a power of 2  注意：BUFFER_DEPTHは2のべき乗でなければならない。
// (Don't forget 1 is also a power of 2 :-) ).
//////////////////////////////////////////////////////////////////////////////////


module buffer#(
    parameter DATA_WIDTH = 32,
    parameter BUFFER_DEPTH = 4
)(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] din,
    input din_valid,
    input read_en,
    output [DATA_WIDTH-1:0] dout,
    output empty,
    output full
);
    
    localparam BUFFER_WIDTH = $clog2(BUFFER_DEPTH);

    /* 
    If BUFFER_DEPTH is 1 the logic needs to be different
    as read_pointer / write_pointer should not be used. Using
    generate statement to correctly generate logic 
    BUFFER_DEPTHが1の場合、read_pointer / write_pointerを使用しないため、
    ロジックを変える必要がある。generateステートメントを使用してロジックを正しく生成する
    */
    generate
        if (BUFFER_DEPTH != 1) begin
            reg [DATA_WIDTH-1:0] data [BUFFER_DEPTH-1:0];
            reg [BUFFER_WIDTH-1:0] read_pointer, write_pointer;
            reg [BUFFER_WIDTH:0] status_counter;//どんくらい溜まってるか状態を保存
            reg [DATA_WIDTH-1:0] output_data;
            
            assign empty = status_counter == 0;//バッファ内部が完全に空っぽ
            assign full = status_counter == BUFFER_DEPTH;//満タン
            assign dout = output_data;//データは流しとく(初期値ゼロ)

            integer i;
            initial begin
                for (i = 0; i < BUFFER_DEPTH; i = i + 1)
                    data[i] <= 0;
                read_pointer <= 0;
                write_pointer <= 0;
                status_counter <= 0;
                output_data <= 0;
            end


            always@(posedge clk) begin
                if (rst) begin
                    data[0] <= 0;
                    read_pointer <= 0;
                    write_pointer <= 0;
                    status_counter <= 0;
                    output_data <= 0;
                end
                else begin
                    if (!full && din_valid) begin//満タンでないかつ書き込み許可信号が来ている
                        data[write_pointer] = din;
                        write_pointer = write_pointer + 1;
                        status_counter = status_counter + 1;
                    end
                    if (read_en && !empty) begin//epmtyは完全に空になったときのみtrueになる。それ以外はfalse
                        output_data = data[read_pointer];
                        read_pointer = read_pointer + 1;
                        status_counter = status_counter - 1;
                    end
                end
            end
        end
        else begin//↓↓以下はバッファの深さが1のときの話なのでいまあまり関係ない
            reg [DATA_WIDTH-1:0] data;
            reg status_counter;
            reg [DATA_WIDTH-1:0] output_data;
            
            assign empty = status_counter == 0;
            assign full = status_counter == BUFFER_DEPTH;
            assign dout = output_data;

            integer i;
            initial begin
                data <= 0;
                status_counter <= 0;
                output_data <= 0;
            end


            always@(posedge clk) begin
                if (rst) begin
                    data <= 0;
                    status_counter <= 0;
                    output_data <= 0;
                end
                else begin
                    if (!full && din_valid) begin
                        data = din;
                        status_counter = status_counter + 1;
                    end
                    if (read_en && !empty) begin
                        output_data = data;
                        status_counter = status_counter - 1;
                    end
                end
            end
        end
    endgenerate

    //デバッグ用
    // wire [DATA_WIDTH-1:0] buff_0, buff_1, buff_2, buff_3;
    // assign buff_0 = data[0];
    // assign buff_1 = data[1];
    // assign buff_2 = data[2];
    // assign buff_3 = data[3];
endmodule
