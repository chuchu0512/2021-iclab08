`timescale 1ns / 1ps
module tb(

    );
    
    wire clk ;
    wire rstn ;
    wire in_valid ;
    wire [15:0] in_data ;
    wire [2:0] in_mode ;
    wire out_valid ;
    wire [15:0] out_data ;
    
    SP m0(.clk(clk), .rstn(rstn), .in_valid(in_valid), .in_data(in_data), .in_mode(in_mode), .out_valid(out_valid), .out_data(out_data)) ;
    pattern m1(.clk(clk), .rstn(rstn), .in_valid(in_valid), .in_data(in_data), .in_mode(in_mode), .out_valid(out_valid), .out_data(out_data)) ;

endmodule
