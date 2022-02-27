`timescale 1ns / 1ps

module fourbysixteen_decoder(

    input WE,
    input [3:0] RegAdd,
    output reg [15:0] EN
    );
    
    always @(*)
        begin
        if (WE) begin
            case (RegAdd)
                 4'd0:  EN  = 16'h0001;
                 4'd1:  EN  = 16'h0002;
                 4'd2:  EN  = 16'h0004;
                 4'd3:  EN  = 16'h0008;
                 4'd4:  EN  = 16'h0010;
                 4'd5:  EN  = 16'h0020;
                 4'd6:  EN  = 16'h0040;
                 4'd7:  EN  = 16'h0080;
                 4'd8:  EN  = 16'h0100;
                 4'd9:  EN  = 16'h0200;
                 4'd10: EN  = 16'h0400;
                 4'd11: EN  = 16'h0800;
                 4'd12: EN  = 16'h1000;
                 4'd13: EN  = 16'h2000;
                 4'd14: EN  = 16'h4000;
                 4'd15: EN  = 16'h8000; 
             endcase
         end
     end
endmodule
