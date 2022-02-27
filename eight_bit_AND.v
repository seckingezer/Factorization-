`timescale 1ns / 1ps

module eight_bit_AND(
        
        input  [7:0] a,
        input  [7:0] b,
        output [7:0] r
    );
    
    assign r = a & b;   
endmodule
