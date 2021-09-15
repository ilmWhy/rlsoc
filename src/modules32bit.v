//15 September 2021

//DECODER MODULE===========================================================
//Send enable signal to control Action RAM Write Mode.
//Use 2 bit input for 4 outputs.
module decoder( 
 input [1:0] act,
 output en0,
 output en1,
 output en2,
 output en3
);

reg [3:0] temp;

always @(*) begin
    if (act == 2'd0) begin
        temp <= 4'b0001;   
    end
    else if  (act == 2'd1) begin
        temp <= 4'b0010;    
    end
    else if  (act == 2'd2) begin
        temp <= 4'b0100;    
    end
    else if  (act == 2'd3) begin
        temp <= 4'b1000;        
    end
    else  begin
        temp <= 4'b0000;    
    end
end

 assign en0 = temp[0];
 assign en1 = temp[1];
 assign en2 = temp[2];
 assign en3 = temp[3];
endmodule

//MULTIPLEXER MODULE=======================================================
//Select Q Value, based on action taken by agents.
//Use 2 bit selector that represent action taken by the agent.
module mux4to1_32bit(
 input [31:0] in0, in1, in2, in3,
 input [1:0] sel,
 output [31:0] out
);
 assign out =
  (sel == 2'd0) ? in0 :
  (sel == 2'd1) ? in1 :
  (sel == 2'd2) ? in2 :
  (sel == 2'd3) ? in3 :
                31'd00;
endmodule

//MAX MODULE===============================================================
//Compare 4 value and choose the highest value
module max4to1_32bit(
 input [31:0] D1, D2, D3, D4,
 output [31:0] Y
);
 wire [32:0] max0_out, max1_out;
//portmap
 compMax_32bit max0(.A(D1), .B(D2), .C(max0_out));
 compMax_32bit max1(.A(D3), .B(D4), .C(max1_out));
 compMax_32bit max2(.A(max0_out), .B(max1_out), .C(Y));
endmodule

//COMPARATOR===============================================================
//Act as basic module for building MAX MODULE
//Compare 2 value and choose the highest value
module compMax_32bit (
 input [31:0] A, B,
 output [31:0] C
);
 assign C = (A > B) ? A: 
            (A < B) ? B:
                      B;
endmodule

//Q UPDATER MODULE=========================================================
//Implement equation to update Q Value based on Alfa, Gamma, and Reward 
module qUpdater_32bit(
 input [31:0] Q, Qmax, rt,
 input [7:0] alfa_i, alfa_j, alfa_k, 
 input [7:0] gamma_i, gamma_j, gamma_k,
 output [31:0] Qnew
);
 wire [31:0] yi_a0, yj_a0, yk_a1;
 wire [31:0] a0_a1, a1_a2, a2_s0;
 wire [31:0] s0_alfa, ai_a3, aj_a3, ak_a4;
 wire [31:0] a3_a4, Qn;

//PortMap
 rShift_32bit yi(.Q(Qmax), .S(gamma_i), .Y(yi_a0));
 rShift_32bit yj(.Q(Qmax), .S(gamma_j), .Y(yj_a0));
 rShift_32bit yk(.Q(Qmax), .S(gamma_k), .Y(yk_a1));
 add_32bit a0(.in0(yi_a0), .in1(yj_a0), .out(a0_a1));
 add_32bit a1(.in0(a0_a1), .in1(yk_a1), .out(a1_a2));
 
 add_32bit a2(.in0(a1_a2), .in1(rt), .out(a2_s0));
 sub_32bit s0(.in0(a2_s0), .in1(Q), .out(s0_alfa));
 
 rShift_32bit ai(.Q(s0_alfa), .S(alfa_i), .Y(ai_a3));
 rShift_32bit aj(.Q(s0_alfa), .S(alfa_j), .Y(aj_a3));
 rShift_32bit ak(.Q(s0_alfa), .S(alfa_k), .Y(ak_a4));
 add_32bit a3(.in0(ai_a3), .in1(aj_a3), .out(a3_a4));
 add_32bit a4(.in0(a3_a4), .in1(ak_a4), .out(Qn));
 add_32bit a5(.in0(Q), .in1(Qn), .out(Qnew));
endmodule

//RIGHT SHIFTER============================================================
//Act as basic module for building Q UPDATER MODULE
//Implement right shift as approximated multiplier
module rShift_32bit (
 input [31:0] Q,
 input [7:0] S,
 output [31:0] Y
);
 assign Y = (S == 8'sd0) ? 31'sd0 :
                ((Q >>> S));
endmodule

//ADDER====================================================================
//Act as basic module for building Q UPDATER MODULE
//Implement addition
module add_32bit(
 input [31:0] in0, in1,
 output [31:0] out
);
 assign out = in0 + in1;
endmodule

//SUBSTRACTOR==============================================================
//Act as basic module for building Q UPDATER MODULE
//Implement substraction
module sub_32bit(
 input [31:0] in0, in1,
 output [31:0] out
);
 assign out = in0 - in1;
endmodule

//ACTION RAM MODULE========================================================
//Access memory to get Q value. Each RAM represent 1 action.
//Module always out Read value. Module only write if WR_EN = HIGH
module ram1_32bit (
 input [7:0] WR_ADDR, RD_ADDR,
 input [31:0] D_IN,
 input WR_EN,
 output [31:0] D_OUT
);
 reg [31:0] tempMem[0:255];

 //Read memory initiation file
 initial begin
  $readmemh("mem_in_row1.list", tempMem);
 end

 //Write if EN = 1
 always @(WR_ADDR or RD_ADDR or WR_EN) begin
   #1 if (WR_EN) begin
   tempMem[WR_ADDR] <= D_IN;
   $writememh("mem_out_row1.list", tempMem);
  end
 end

 assign D_OUT = tempMem[RD_ADDR];
endmodule

module ram2_32bit (
 input [7:0] WR_ADDR, RD_ADDR,
 input [31:0] D_IN,
 input WR_EN,
 output [31:0] D_OUT
);
 reg [31:0] tempMem[0:255];

 //Read memory initiation file
 initial begin
  $readmemh("mem_in_row2.list", tempMem);
 end

 //Write if EN = 1
 always @(WR_ADDR or RD_ADDR or WR_EN) begin
  #1 if (WR_EN) begin
   tempMem[WR_ADDR] <= D_IN;
   $writememh("mem_out_row2.list", tempMem);
  end
 end

 assign D_OUT = tempMem[RD_ADDR];
endmodule

module ram3_32bit (
 input [7:0] WR_ADDR, RD_ADDR,
 input [31:0] D_IN,
 input WR_EN,
 output [31:0] D_OUT
);
 reg [31:0] tempMem[0:255];

//Read memory initiation file
 initial begin
  $readmemh("mem_in_row3.list", tempMem);
 end

//Write if EN = 1
 always @(WR_ADDR or RD_ADDR or WR_EN) begin
  #1 if (WR_EN) begin
   tempMem[WR_ADDR] <= D_IN;
   $writememh("mem_out_row3.list", tempMem);
  end
 end

 assign D_OUT = tempMem[RD_ADDR];
endmodule

module ram4_32bit (
 input [7:0] WR_ADDR, RD_ADDR,
 input [31:0] D_IN,
 input WR_EN,
 output [31:0] D_OUT
);
 reg [31:0] tempMem[0:255];

//Read memory initiation file
 initial begin
  $readmemh("mem_in_row4.list", tempMem);
 end

//Write if EN = 1
 always @(WR_ADDR or RD_ADDR or WR_EN) begin
  #1 if (WR_EN ) begin
   tempMem[WR_ADDR] <= D_IN;
   $writememh("mem_out_row4.list", tempMem);
  end
 end

 assign D_OUT = tempMem[RD_ADDR];
endmodule
