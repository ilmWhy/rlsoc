//Andi Muhammad Riyadhus Ilmy (13217053)
//Tyfan Juliano (13217063)
//Yafie Abdillah (13217091)
//Evan Robert (13217057)
//Building Blocks for Q Learning Accelerator with 16 bit data

//=========================================================================
//=========================================================================
//Q LEARNING ACCELERATOR MODULES===========================================
//=========================================================================
//=========================================================================

//VALIDATION MODULE========================================================
//Prevent Q Table from being Updated if Finished (State = 99)
module isFinished(
 input signed [15:0] qValue,
 input [7:0] currentState,
 output signed [15:0] out
);
  assign out = (currentState != 8'd99) ? qValue:  
                                          16'd0; 
endmodule

//DECODER MODULE===========================================================
//Send enable signal to control Action RAM Write Mode.
//Use 2 bit input for 4 outputs.
module decoder( 
 input stateRst,
 input rst,
 input [1:0] act,
 output en0,
 output en1,
 output en2,
 output en3
);

reg [3:0] enTemp;

 always @(*) begin
     //RESET
     if (rst == 1'b1 || stateRst == 1'b1) begin  
             enTemp <= 4'b0000;
     end
     else begin
         if (act == 2'd0) begin
             enTemp <= 4'b0001;   
         end
         else if  (act == 2'd1) begin
             enTemp <= 4'b0010;    
         end
         else if  (act == 2'd2) begin
             enTemp <= 4'b0100;    
         end
         else if  (act == 2'd3) begin
             enTemp <= 4'b1000;        
         end
         else  begin
             enTemp <= 4'b0000;    
         end
     end
 end

 assign en0 = enTemp[0];
 assign en1 = enTemp[1];
 assign en2 = enTemp[2];
 assign en3 = enTemp[3];
endmodule

//ACTION RAM MODULE========================================================
//Access memory to get Q value. Each RAM represent 1 action.
//Module always out Read value. Module only write if WR_EN = HIGH
module ram1_16bit (
 input [7:0] WR_ADDR, RD_ADDR,
 input signed [15:0] D_IN,
 input WR_EN,
 output signed [15:0] D_OUT
);
 reg [15:0] tempMem[0:255];

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

module ram2_16bit (
 input [7:0] WR_ADDR, RD_ADDR,
 input signed[15:0] D_IN,
 input WR_EN,
 output signed[15:0] D_OUT
);
 reg [15:0] tempMem[0:255];

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

module ram3_16bit (
 input [7:0] WR_ADDR, RD_ADDR,
 input signed[15:0] D_IN,
 input WR_EN,
 output signed[15:0] D_OUT
);
 reg [15:0] tempMem[0:255];

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

module ram4_16bit (
 input [7:0] WR_ADDR, RD_ADDR,
 input signed[15:0] D_IN,
 input WR_EN,
 output signed[15:0] D_OUT
);
 reg [15:0] tempMem[0:255];

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

//MULTIPLEXER MODULE=======================================================
//Select Q Value, based on action taken by agents.
//Use 2 bit selector that represent action taken by the agent.
module mux4to1_16bit(
 input [15:0] in0, in1, in2, in3,
 input [1:0] sel,
 output [15:0] out
);
 assign out =
  (sel == 2'd0) ? in0 :
  (sel == 2'd1) ? in1 :
  (sel == 2'd2) ? in2 :
  (sel == 2'd3) ? in3 :
                16'd00;
endmodule

//MAX MODULE===============================================================
//Compare 4 value and choose the highest value
module max4to1_16bit(
 input [15:0] D1, D2, D3, D4,
 output [15:0] Y
);
 wire [15:0] max0_out, max1_out;
//portmap
 compMax_16bit max0(.A(D1), .B(D2), .C(max0_out));
 compMax_16bit max1(.A(D3), .B(D4), .C(max1_out));
 compMax_16bit max2(.A(max0_out), .B(max1_out), .C(Y));
endmodule

//COMPARATOR===============================================================
//Act as basic module for building MAX MODULE
//Compare 2 value and choose the highest value
module compMax_16bit (
 input signed[15:0] A, B,
 output signed[15:0] C
);
 assign C = (A > B) ? A: 
            (A < B) ? B:
                      B;
endmodule

//Q UPDATER MODULE=========================================================
//Implement equation to update Q Value based on Alfa, Gamma, and Reward 
module qUpdater_16bit(
 input signed [15:0] Q, Qmax, rt,
 input signed [7:0] alfa_i, alfa_j, alfa_k, 
 input signed [7:0] gamma_i, gamma_j, gamma_k,
 output signed[15:0] Qnew
);
 wire signed [15:0] yi_a0, yj_a0, yk_a1;
 wire signed [15:0] a0_a1, a1_a2, a2_s0;
 wire signed [15:0] s0_alfa, ai_a3, aj_a3, ak_a4;
 wire signed [15:0] a3_a4, Qn;

//PortMap
 rShift_16bit yi(.Q(Qmax), .S(gamma_i), .Y(yi_a0));
 rShift_16bit yj(.Q(Qmax), .S(gamma_j), .Y(yj_a0));
 rShift_16bit yk(.Q(Qmax), .S(gamma_k), .Y(yk_a1));
 add_16bit a0(.in0(yi_a0), .in1(yj_a0), .out(a0_a1));
 add_16bit a1(.in0(a0_a1), .in1(yk_a1), .out(a1_a2));
 
 add_16bit a2(.in0(a1_a2), .in1(rt), .out(a2_s0));
 sub_16bit s0(.in0(a2_s0), .in1(Q), .out(s0_alfa));
 
 rShift_16bit ai(.Q(s0_alfa), .S(alfa_i), .Y(ai_a3));
 rShift_16bit aj(.Q(s0_alfa), .S(alfa_j), .Y(aj_a3));
 rShift_16bit ak(.Q(s0_alfa), .S(alfa_k), .Y(ak_a4));
 add_16bit a3(.in0(ai_a3), .in1(aj_a3), .out(a3_a4));
 add_16bit a4(.in0(a3_a4), .in1(ak_a4), .out(Qn));
 add_16bit a5(.in0(Q), .in1(Qn), .out(Qnew));
endmodule

//RIGHT SHIFTER============================================================
//Act as basic module for building Q UPDATER MODULE
//Implement right shift as approximated multiplier
module rShift_16bit (
 input signed [15:0] Q,
 input signed [7:0] S,
 output signed [15:0] Y
);
 assign Y = (S == 8'sd0) ? 16'sd0 :
                ((Q >>> S));
endmodule

//ADDER====================================================================
//Act as basic module for building Q UPDATER MODULE
//Implement addition
module add_16bit(
 input signed[15:0] in0, in1,
 output signed[15:0] out
);
 assign out = $signed(in0) + $signed(in1);
endmodule

//SUBSTRACTOR==============================================================
//Act as basic module for building Q UPDATER MODULE
//Implement substraction
module sub_16bit(
 input signed[15:0] in0, in1,
 output signed[15:0] out
);
 assign out = $signed(in0) - $signed(in1);
endmodule

//=========================================================================
//=========================================================================
//POLICY GENERATOR MODULES=================================================
//=========================================================================
//=========================================================================

//GREEDY ALGORITHM MODULE==================================================
//Choose next action based on highest Q Value
module greedAction(
 input [15:0] qAct0, qAct1, qAct2, qAct3,
 output [1:0] nextAction
);
 wire [15:0] maxValue;

 max4to1_16bit max(
  .D1(qAct0),
  .D2(qAct1),
  .D3(qAct2),
  .D4(qAct3),
  .Y(maxValue)
 );

 assign nextAction =
  (maxValue == qAct0) ? 2'd0:
  (maxValue == qAct1) ? 2'd1:
  (maxValue == qAct2) ? 2'd2:
  (maxValue == qAct3) ? 2'd3:
                        2'd0; 
endmodule

//PSEUDO RANDOM MODULE=====================================================
//Generate pseudo-random next action based on fibonacci LSFR
//Also generate 10 bit random value for epsilon calculation
module lsfr_16bit(
 input clk,
 output [1:0] nextAction,
 output [9:0] randomValue //maximum value is 2^9 = 512
);
 reg [15:0] shiftReg;
 reg shiftVal, val0, val1, val2, val3;
 
 //set seed value
 parameter [15:0] seed = 16'h69CD;
 initial begin
  shiftReg = seed;
 end
 
 //fibonacci lsfr
 always @(posedge clk)
 begin
  shiftReg = shiftReg << 1; //Left shift 1 bit
  
  //XOR taps sequentially
  val0 = shiftReg[15] ^ shiftReg[13];
  val1 = val0 ^ shiftReg[12];
  val2 = val1 ^ shiftReg[10];

  //assign taps-XOR to inputs
  shiftReg[0] = val2; 
 end

 assign nextAction = shiftReg[2:1];
 assign randomValue = shiftReg[9:0];
endmodule

//NEXT ACTION DECIDER MODULE===============================================
//Decide next action from greedy algorithm or LSFR
//Decision based on selector input from CU
module decideNextAct(
 input [1:0] greedAct, lsfrAct,
 input sel,
 output [1:0] nxtAct
);
//Decide Next Action
 assign nxtAct = (sel == 1'd1) ? lsfrAct:
                                  greedAct;
endmodule


//=========================================================================
//=========================================================================
//WALL DETECT SUBMODULES===================================================
//=========================================================================
//=========================================================================

//WALL DETECTION MODULE====================================================
//determine agent's next state after taking certain action 
//based on current state (see maze walls)

//WALLH MODULE========================================================
//
//
module wallH_16bit (
 input [7:0] RD_ADDR,
 output signed [15:0] D_OUT
);
 reg [15:0] tempMem[0:255];

//Read memory initiation file
 initial begin
  $readmemh("wallH.list", tempMem);
 end

  assign D_OUT = tempMem[RD_ADDR];
endmodule

//WALLV MODULE========================================================
//
//
module wallV_16bit (
 input [7:0] RD_ADDR,
 output signed [15:0] D_OUT
);
 reg [15:0] tempMem[0:255];

//Read memory initiation file
 initial begin
  $readmemh("wallV.list", tempMem);
 end

  assign D_OUT = tempMem[RD_ADDR];
endmodule


//WALL DETECTOR MODULE ===========================================
//
//
module wallDetector (
 input [7:0] currentState,
 input [1:0] nxtAct,
 output [15:0] hitWallfin
);
reg [15:0] hitWall;
wire [7:0] rdAddrH, rdAddrV;
wire [15:0] wallH_det, wallV_det;
assign hitWallfin = hitWall;

assign rdAddrH = (nxtAct == 2'd2) ? currentState:           //kiri
                 (nxtAct == 2'd0) ? (currentState + 8'd1):  //kanan
                 8'd0;

assign rdAddrV = (nxtAct == 2'd1) ? currentState:           //atas
                 (nxtAct == 2'd3) ? (currentState + 8'd10): //bawah
                 8'd0;
                 
wallV_16bit wallV_16bit(
 .RD_ADDR(rdAddrV),
 .D_OUT(wallV_det)
 );

wallH_16bit wallH_16bit(
 .RD_ADDR(rdAddrH),
 .D_OUT(wallH_det)
 );
 
always @(*) begin
    if(nxtAct == 2'd0) begin
        if((currentState == 8'd9) && (currentState == 8'd19) && (currentState == 8'd29) && (currentState == 8'd39) && (currentState == 8'd49) && (currentState == 8'd59) && (currentState == 8'd69) && (currentState == 8'd79) && (currentState == 8'd89) && (currentState == 8'd99)) begin
            hitWall = 16'd1;
        end
        else begin
            hitWall = wallH_det;
        end
    end
    else if(nxtAct == 2'd1) begin
        hitWall = wallV_det;
    end 
    else if(nxtAct == 2'd2) begin
        hitWall = wallH_det;
    end 
    else begin
        hitWall = wallV_det;
          
    end
end
endmodule



//STATE GENERATOR MODULE=======================================================
//determine agent's next action after taking certain action from certain state
module stategen(
    input [7:0] currentState ,
    input [15:0] hitWall,
    input [1:0] nxtAction ,
    output [7:0] nxtState
//batas undo
);
reg [7:0] out;
assign nxtState = (currentState == 8'd99) ? currentState : out;

always @(*) begin
    if(hitWall == 8'd0) begin
        if (nxtAction == 2'd0) begin
            out = currentState + 8'd1;
        end
        else if (nxtAction == 2'd1) begin
            out = currentState - 8'd10;
        end
        else if (nxtAction == 2'd2) begin
            out = currentState - 8'd1;
        end
        else if (nxtAction == 2'd3) begin
            out = currentState + 8'd10;       
        end
    end
    else begin
        out = currentState;
    end
end
 
endmodule


module wallDetect (
 input [7:0] currentState,
 input [1:0] nxtAction,
 output [7:0] nxtState
);

wire [15:0] hitWall;

wallDetector wallDetector (
 .currentState(currentState),
 .nxtAct(nxtAction),
 .hitWallfin(hitWall)
);

stategen stategen(
  .currentState(currentState) ,
  .hitWall(hitWall),
  .nxtAction(nxtAction),
  .nxtState(nxtState)
);

endmodule
//=========================================================================
//=========================================================================
//END OF WALL DETECT SUBMODULES============================================
//=========================================================================
//=========================================================================

//STATE RESET MODULE=======================================================
//Reset State to zero if given HIGH inputs
module resetState(
 input [7:0] inState,
 input stateRst,
 output [7:0] outState
);
 assign outState =
  (stateRst == 1'd0) ? inState :
                            8'd0;
endmodule

//=========================================================================
//=========================================================================
//REWARD GENERATOR MODULE==================================================
//=========================================================================
//=========================================================================

//REWARD CONTROLLER MODULE=================================================
//Generate Reward Selector Based on states
module rewardSelect(
 input [7:0] prevState,
 input [7:0] nxtState,
 input [7:0] currentState ,
 output reg [1:0] rwSel
);
 
 reg [9:0] count = 10'b0; //For debugging
 
 always @(*) begin
  if(currentState == 8'd99) begin
      count = count + 10'b1; //Count how many times reach finish line
  end
  if (nxtState == 8'd99) begin
   //Reward for finish line
   rwSel = 2'd3;
  end
  else if (nxtState == 0) begin
   //Punishment if return to START
   rwSel = 2'd2;
  end
  else if (nxtState != currentState) begin
   if(nxtState != prevState) begin
    //No Reward or Punishment
    rwSel = 2'd0;
   end
   else begin
    //Punishment for returning to previous location
    rwSel = 2'd1;
   end
  end
  else begin
   //Punishment for hitting wall
   rwSel = 2'd2;
  end
 end 
endmodule

//REWARD MULTIPLEXER MODULE=======================================================
//select reward according to reward selector
module rewardMux_16bit(
 input signed [15:0] rw0, rw1, rw2, rw3,
 input [1:0] rwSel,
 input staterst,
 output signed [15:0] out
);
 assign out =
  (rwSel == 2'd1 && staterst == 1'd0) ? rw1 :  //-50
  (rwSel == 2'd2 && staterst == 1'd0) ? rw2 :  //-100
  (rwSel == 2'd3 && staterst == 1'd0) ? rw3 : //100
                                        rw0; //0 
endmodule
