`timescale 1ns / 1ps

module twobyfour_mux #(parameter SIZE = 1)(

     input [SIZE-1:0] x0,x1,x2,x3,
     input [1:0] InsSel,
     output reg [SIZE-1:0]y
  
    );
    always @(*)
        begin
            case (InsSel)
                    2'b00: y = x0;
                    2'b01: y = x1;
                    2'b10: y = x2;
                    2'b11: y = x3;
            endcase
        end
endmodule
    