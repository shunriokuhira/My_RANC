`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// NeuronBlock.v
//
// Created for Dr. Akoglu's Reconfigurable Computing Lab
//  at the University of Arizona
// 
// Performs the leaky integrate and fire operation for each core.
//////////////////////////////////////////////////////////////////////////////////

module NeuronBlock #(
    parameter LEAK_WIDTH = 9,
    parameter WEIGHT_WIDTH = 9,
    parameter THRESHOLD_WIDTH = 9,
    parameter POTENTIAL_WIDTH = 9,
    parameter NUM_WEIGHTS = 4,
    parameter NUM_RESET_MODES = 2
)(
    input clk,
    input signed [LEAK_WIDTH-1:0] leak,//from CSRAM
    input [WEIGHT_WIDTH*NUM_WEIGHTS-1:0] weights,//from CSRAM
    input [THRESHOLD_WIDTH-1:0] positive_threshold,//from CSRAM
    input [THRESHOLD_WIDTH-1:0] negative_threshold,//from CSRAM
    input [POTENTIAL_WIDTH-1:0] reset_potential,//from CSRAM
    input [POTENTIAL_WIDTH-1:0] current_potential,//from CSRAM
    input [$clog2(NUM_WEIGHTS)-1:0] neuron_instruction,//from contoroller
    input [$clog2(NUM_RESET_MODES)-1:0] reset_mode,//from CSRAM
    input next_neuron,//from controller
    input integrator_reg_en,//from contoroller
    input write_current_potential,//from controller
    output [POTENTIAL_WIDTH-1:0] write_potential,//to CSRAM
    output spike_out//to controller
);

    generate
        if (WEIGHT_WIDTH > POTENTIAL_WIDTH) begin
            // Weight width cannot be greater than potential width
            // 重み幅はポテンシャル幅より大きくはできない
            weight_width_greater_than_potential_width error();
        end
    endgenerate
   
    wire [WEIGHT_WIDTH-1:0] weight;
    wire signed [POTENTIAL_WIDTH-1:0] integrator_potential;
    wire signed [POTENTIAL_WIDTH-1:0] leaked_potential;

    /*
    If write_current_potential is high we want the weight to be zero so the current potential of the neuron can be written
    to the register in the Integrator Unit
    write_current_potentialがHighの場合、重みをゼロにしたいので、
    ニューロンの現在のポテンシャルを積分発火ユニットのレジスタに書き込むことができる。

    This assumes that weights are formatted as {w0, w1, w2, ...}
    これは、重みが {w0, w1, w2, ...} のようにフォーマットされていると仮定している。
    */
    //weightsは36bit幅ある。weightは9bit幅ある。36÷9=4で、weigthsのなかに4つのwight情報を格納している
    //そして、neuron_instructionの値によりwightsからどの範囲だけビットを切り出すか決め、wightsからwightを抽出する
    //write_current_potentialがONならweightは0になり、ニューロンの現在の電位を積分発火ユニットのレジスタに書き込む
    assign weight = write_current_potential ? {WEIGHT_WIDTH{1'b0}} : weights[WEIGHT_WIDTH*(NUM_WEIGHTS-neuron_instruction)-1 -: WEIGHT_WIDTH];
   
    IntegratorUnit #(
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .POTENTIAL_WIDTH(POTENTIAL_WIDTH)
    ) IntegratorUnit_i (
        .clk(clk),
        .next_neuron(next_neuron),
        .integrator_reg_en(integrator_reg_en),
        .weight(weight),
        .current_potential(current_potential),//
        .integrator_potential(integrator_potential)
    );

    assign leaked_potential = integrator_potential + leak;
    
    ThresholdResetUnit #(
        .THRESHOLD_WIDTH(THRESHOLD_WIDTH),
        .POTENTIAL_WIDTH(POTENTIAL_WIDTH),
        .NUM_RESET_MODES(NUM_RESET_MODES)
    ) ThresholdResetUnit_i ( 
        .potential_in(leaked_potential),
        .positive_threshold(positive_threshold),
        .negative_threshold(negative_threshold),
        .reset_potential(reset_potential),
        .reset_mode(reset_mode),
        .potential_out(write_potential),
        .spike(spike_out)
    );

endmodule