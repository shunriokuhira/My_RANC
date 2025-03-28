`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// buffer.v
//
// A simple buffer.
// Reads and writes are synchronous
// Reset is synchronous active high.
//
// NOTE: BUFFER_DEPTH has to be a power of 2 
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

    // reg[10:0] cnt;
    // wire clk2 = (cnt == 1);
    // always @(posedge clk) begin
    //     if(rst)begin
    //         cnt <= 0;
    //     end
    //     else if(clk2)begin
    //         cnt <= 0;
    //     end
    //     else begin
    //         cnt <= cnt + 1;
    //     end
    // end

    /* 
    If BUFFER_DEPTH is 1 the logic needs to be different
    as read_pointer / write_pointer should not be used. Using
    generate statement to correctly generate logic 
    */
    // generate
    //     if (BUFFER_DEPTH != 1) begin

        wire din_zero;
        assign din_zero = (din == 0) ? 1 : 0;
            reg [DATA_WIDTH-1:0] data [BUFFER_DEPTH-1:0];
            reg [BUFFER_WIDTH-1:0] read_pointer, write_pointer;
            reg [BUFFER_WIDTH:0] status_counter;
            reg [DATA_WIDTH-1:0] output_data;
            reg [DATA_WIDTH-1:0] din_before;
            wire [DATA_WIDTH-1:0] buff_0, buff_1, buff_2, buff_3;
            assign buff_0 = data[0];
            assign buff_1 = data[1];
            assign buff_2 = data[2];
            assign buff_3 = data[3];
            
            assign empty = status_counter == 0;
            assign full = status_counter == BUFFER_DEPTH;
            assign dout = output_data;

            wire write_twice;//バッファが同じパケットを二回連続して書き込もうとしたことを検知
            assign write_twice = (din == din_before) ? 1 : 0;
            always @(posedge clk) begin
                if(rst)begin
                    din_before <= 0;
                end
                else if(din_valid)begin
                    din_before <= din;
                end
            end

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
                    if (!full && din_valid && !din_zero && !write_twice) begin
                    //if (!full && din_valid) begin
                        data[write_pointer] = din;
                        write_pointer = write_pointer + 1;
                        status_counter = status_counter + 1;
                    end
                    if (read_en && !empty) begin
                        output_data = data[read_pointer];
                        //data[read_pointer] = 0;
                        read_pointer = read_pointer + 1;
                        status_counter = status_counter - 1;
                    end
                    // if(write_twice)begin
                    //     output_data <= 0;
                    // end
                end
            end
    //     end
    //     else begin
    //         reg [DATA_WIDTH-1:0] data;
    //         reg status_counter;
    //         reg [DATA_WIDTH-1:0] output_data;
            
    //         assign empty = status_counter == 0;
    //         assign full = status_counter == BUFFER_DEPTH;
    //         assign dout = output_data;

    //         integer i;
    //         initial begin
    //             data <= 0;
    //             status_counter <= 0;
    //             output_data <= 0;
    //         end


    //         always@(posedge clk) begin
    //             if (rst) begin
    //                 data <= 0;
    //                 status_counter <= 0;
    //                 output_data <= 0;
    //             end
    //             else begin
    //                 if (!full && din_valid) begin
    //                     data = din;
    //                     status_counter = status_counter + 1;
    //                 end
    //                 if (read_en && !empty) begin
    //                     output_data = data;
    //                     status_counter = status_counter - 1;
    //                 end
    //             end
    //         end
    //     end
    // endgenerate

endmodule
