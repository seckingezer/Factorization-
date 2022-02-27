`timescale 1ns / 1ps

module fourbysixteen_mux #(parameter SIZE = 1)(

    input [SIZE-1:0] x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15, 
    input [3:0] OutMuxAdd,                     
    output reg [SIZE-1:0]y                    
    );
    
     always @(*)
        begin
            case (OutMuxAdd)
                    4'b0000: y = x0;
                    4'b0001: y = x1;
                    4'b0010: y = x2;
                    4'b0011: y = x3;
                    4'b0100: y = x4;
                    4'b0101: y = x5;
                    4'b0110: y = x6;
                    4'b0111: y = x7;
                    4'b1000: y = x8;
                    4'b1001: y = x9;
                    4'b1010: y = x10;
                    4'b1011: y = x11;
                    4'b1100: y = x12;
                    4'b1101: y = x13;
                    4'b1110: y = x14;
                    4'b1111: y = x15;
            endcase
        end
    
endmodule
