`timescale 1ns / 1ps
//
//////////////////////////////////////////////////////////////////////////////////
// IntegratorUnit.v
//
// Created for Dr. Akoglu's Reconfigurable Computing Lab
//  at the University of Arizona
// 
// Performs an integration operation. 統合(積分)操作を行う。
//////////////////////////////////////////////////////////////////////////////////

module IntegratorUnit #(
    parameter WEIGHT_WIDTH = 9,
    parameter POTENTIAL_WIDTH = 9
)(
    input clk,
    input next_neuron,
    input integrator_reg_en,
    input [WEIGHT_WIDTH-1:0] weight,
    input [POTENTIAL_WIDTH-1:0] current_potential,
    output [POTENTIAL_WIDTH-1:0] integrator_potential
);
    
    wire [POTENTIAL_WIDTH-1:0] potential_mux_out;
    wire [POTENTIAL_WIDTH-1:0] add_out;
    
    Mux2to1 #(
        .DATA_WIDTH(POTENTIAL_WIDTH)
    ) PotentialMux (
        .a(integrator_potential),//next_neuron = 0
        .b(current_potential),//next_neuron = 1 
        .sel(next_neuron),//from controller
        .out(potential_mux_out)
    );
    
    Adder #(
        .DATA_WIDTH_A(WEIGHT_WIDTH),
        .DATA_WIDTH_B(POTENTIAL_WIDTH),
        .DATA_WIDTH_OUT(POTENTIAL_WIDTH)
    ) Adder (
        .a(weight),
        .b(potential_mux_out),
        .out(add_out)// weight + potential_mux_out
    );
    
    EnReg #(
        .DATA_WIDTH(POTENTIAL_WIDTH)
    ) EnReg(
        .en(integrator_reg_en),
        .clk(clk),
        .d(add_out),
        .q(integrator_potential)
    );
       
endmodule
