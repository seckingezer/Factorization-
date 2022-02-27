`timescale 1ns / 1ps

module ALU(
    
    input [7:0] ALUinA,
    input [7:0] ALUinB,
    input [1:0] InsSel,
    output[7:0] ALUout,
    output CO,
    output Z
    );
    
    wire [7:0] mux11,mux12,mux13,mux14;
    wire       mux23,mux24;
    
eight_bit_AND eight_bit_AND (ALUinA,ALUinB,mux11);
eight_bit_XOR eight_bit_XOR (ALUinA,ALUinB,mux12);
eight_bit_ADD eight_bit_ADD (ALUinA,ALUinB,mux13,mux23);
eight_bit_CLS eight_bit_CLS (ALUinA,mux14,mux24);
eight_bit_zero_comp eight_bit_zero_comp (ALUout,Z);
twobyfour_mux#(8) mux (mux11,mux12,mux13,mux14,InsSel,ALUout);
twobyfour_mux#(1) mux2 (1'b0,1'b1,mux23,mux24,InsSel,CO);
endmodule
