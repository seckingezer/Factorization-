`timescale 1ns / 1ps

module Register(
    
    input clk,en,reset,
    input [7:0] Rin,
    output reg [7:0] Rout
    );
    
    
    always @(posedge clk) begin
    
        if(reset)
            Rout <= 0;
        else 
        if(en) 
            Rout <= Rin;
    end
         
    
       
endmodule
