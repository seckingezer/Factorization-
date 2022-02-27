`timescale 1ns / 1ps

module eight_bit_CLS(

        input  [7:0] a,
        output [7:0] r,
        output       r0
    );
    
   assign  r = {a[6:0],a[7]};
   assign  r0 = r[0];     
        
endmodule
