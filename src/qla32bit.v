
//Modul QLearningAccel untuk LSI Design 2021
//Used module in modules16bit.v

module qLearningAccel_32bit(
 input clk,
 input [7:0] st,    //Current State
 input [7:0] nxtst, //Next State
 input [1:0] act,   // Current Action
 input [31:0] rt, //Reward or Punismnet Value
 input [23:0] alfa, gamma, //[23:16]for i, [15:8] for j, [7:0] for k
 output [31:0] qRow0, qRow1, qRow2, qRow3 //Row of Q Value
);

 wire wrEn1, wrEn2, wrEn3, wrEn4;                        //Decoder
 wire [31:0] datOut1, datOut2, datOut3, datOut4;   //Action RAM
 wire [7:0] alfai, alfaj, alfak, gammai, gammaj, gammak; //Q Updater
 wire [31:0] maxOut, muxOut, qOut, newQVal;        //Q Updater
 
 //Register to delay outputs from action ram
 reg [31:0] del0, del1, del2, del3;

 decoder decoder(
  .act(act),
  .en0(wrEn1),
  .en1(wrEn2),
  .en2(wrEn3),
  .en3(wrEn4)
 );

 ram1_32bit action1(
  .WR_ADDR(st), 
  .D_IN(qOut), 
  .RD_ADDR(nxtst), 
  .WR_EN(wrEn1), 
  .D_OUT(datOut1)
 );

 ram2_32bit action2(
  .WR_ADDR(st), 
  .D_IN(qOut), 
  .RD_ADDR(nxtst), 
  .WR_EN(wrEn2), 
  .D_OUT(datOut2)
 );

 ram3_32bit action3(
  .WR_ADDR(st), 
  .D_IN(qOut), 
  .RD_ADDR(nxtst), 
  .WR_EN(wrEn3), 
  .D_OUT(datOut3)
 );

 ram4_32bit action4(
  .WR_ADDR(st), 
  .D_IN(qOut), 
  .RD_ADDR(nxtst), 
  .WR_EN(wrEn4), 
  .D_OUT(datOut4)
 );

 mux4to1_32bit mux(
  .in0(del0),
  .in1(del1),
  .in2(del2),
  .in3(del3),
  .sel(act),
  .out(muxOut)
 );

 max4to1_32bit max(
  .D1(datOut1),
  .D2(datOut2),
  .D3(datOut3),
  .D4(datOut4),
  .Y(maxOut)
 );

 qUpdater_32bit main(
  .Q(muxOut),
  .Qmax(maxOut),
  .rt(rt),
  .alfa_i(alfai),
  .alfa_j(alfaj),
  .alfa_k(alfak),
  .gamma_i(gammai),
  .gamma_j(gammaj),
  .gamma_k(gammak),
  .Qnew(newQVal)
 );

 //Delay operation
 always @ (posedge clk)
 begin
  del0 = datOut1;
  del1 = datOut2;
  del2 = datOut3;
  del3 = datOut4;
 end
 
 //Leading one assignment for Alfa and Gamma
 assign alfai = alfa[23:16];
 assign alfaj = alfa[15:8];
 assign alfak = alfa[7:0];
 assign gammai = gamma[23:16];
 assign gammaj = gamma[15:8];
 assign gammak = gamma[7:0];

 //Assign Output for Policy Generator
 assign qRow0 = del0;
 assign qRow1 = del1;
 assign qRow2 = del2;
 assign qRow3 = del3; 
endmodule