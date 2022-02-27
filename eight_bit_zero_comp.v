`timescale 1ns / 1ps



module eight_bit_zero_comp(

       input    [7:0] a,
       output reg   z
    );
    
    always @(*) begin
    
     if (a == 0)
        z = 1'b1;
     else
        z = 1'b0;
    end     
endmodule
