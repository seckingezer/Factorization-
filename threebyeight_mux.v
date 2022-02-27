`timescale 1ns / 1ps


module threebyeight_mux #(parameter SIZE = 1)(

       input [SIZE-1:0] x0,x1,x2,x3,x4,x5,x6,x7,
       input [2:0] InMuxAdd,          
       output reg [SIZE-1:0]y       

    );
         always @(*)
        begin
            case (InMuxAdd)
                    3'b000: y = x0;
                    3'b001: y = x1;
                    3'b010: y = x2;
                    3'b011: y = x3;
                    3'b100: y = x4;
                    3'b101: y = x5;
                    3'b110: y = x6;
                    3'b111: y = x7;
            endcase
        end
    
endmodule
