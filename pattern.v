`timescale 1ns / 1ps
module pattern(
output reg clk,
output reg rstn,
output reg in_valid,
output reg [15:0] in_data,
output reg [2:0] in_mode,
input out_valid,
input [15:0] out_data
    );
    
    integer CYCLE = 60 ;
    integer input_file ;
    integer read ;
    integer k ;
    reg [15:0] input_data ;
    
    initial clk = 0 ;
    always #(CYCLE/2) clk = ~clk ;
    initial rstn = 0 ;
    
    initial begin
        rstn =  0 ;
        in_valid = 0 ;
        #(2.5*CYCLE) ;
        rstn = 1 ;
        #(2.5*CYCLE) ;
        in_valid = 1'b1 ;
        input_file = $fopen("D:/workspace/verilog practice/Vivado/0812_2021_iclab08/SP/in_file.txt", "r") ;
        @(negedge clk) ;
        for(k=0; k<3; k=k+1)begin
            @(negedge clk) ;
            input_mode ;
        end
        for(k=0; k<6; k=k+1)begin
            @(negedge clk) ;
            input_a ;
        end
        @(negedge clk) ;
        in_valid = 0 ;
        #(200*CYCLE) ;
        rstn = 1'b0 ;
        $finish ;
    end
    
    task input_mode ;
    begin
        read = $fscanf(input_file, "%d", input_data) ;
        in_mode = input_data ;
    end
    endtask
    
    task input_a ;
    begin
        read = $fscanf(input_file, "%d", input_data) ;
        in_data = input_data ;
    end
    endtask
    
endmodule
