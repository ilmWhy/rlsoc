module maze_display_tb_2(input [7:0] state);
   
   reg [3:0] in_map_maze[0:99];
   reg [7:0] out_agent_lok, out_goal_lok ;
   integer i;
   integer j;
   initial
   begin
   out_agent_lok = 8'b00000000;
   out_goal_lok = 8'b01100011;
   end
   always @(state)
      begin
      out_agent_lok = state; 
	  j=0;
		for (i=0; i < 100; i=i+1)
		begin
			if (i == out_agent_lok)
			  begin
				$write(" 1 ");
			end else if (i == out_goal_lok)
			  begin
				$write(" 2 ");
			end else
			  begin
				$write(" 0 ");
			end
			if ( j == 4'b1001 )
			  begin
				$display("");
				j = 0;
			end else begin
				j = j+1;
			end
		end
      end
endmodule
