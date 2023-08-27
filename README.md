In this project hardware implemetation of 8-bit factorizing using wheel factorization algorithm is applied. The goal of the project is creating a Arithmetic Logic Unit and Register Block with verilog and
using Final State Machines in Control Unit block, implementing a algorithm that factorize any given 8-bit positive number.  

Main algorithm flow of the project goes like this; 

![adad](https://user-images.githubusercontent.com/92468688/155897815-6ada59c4-b1eb-47dc-9f10-a90e16a50eb1.jpg)


In the hardware division is executed with consecutive subtractions so here is the division algorithm for any number. 

NOTE: Since the biggest 8-bit number is 255 and the 17x17 > 255. Only the 2,3,5,7,11,13 should be checked according to wheel factorization. 

![ada](https://user-images.githubusercontent.com/92468688/155897967-d1aed60b-d370-4d13-bd1d-0695e6a1d673.jpg)



There are 16 registers in this design and reg0 goes to output, reg1 and reg2 goes as an operand to the ALU. 
Table dictates the usage of registers;


![reg all](https://user-images.githubusercontent.com/92468688/155898032-76e1641d-21b3-4ed1-9588-caebdcf183be.png)


Results should be interpreted as; 

Input = Out x 2^((reg [14])) x 3^((reg [13])) x 5^((reg[12])) x 7^((reg[11])) x 11^((reg[10])) x 13^((reg[9]))
