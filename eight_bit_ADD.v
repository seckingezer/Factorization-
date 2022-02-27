`timescale 1ns / 1ps

module eight_bit_ADD(

        input  [7:0] a,
        input  [7:0] b,
        output [7:0] r,
        output      co
    );
    
    assign {co,r} = a + b;
endmodule
