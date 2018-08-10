//-----------------------------------------------------------------------------
//
// Title       : delta_delay_2
// Design      : fpga_components
// Author      : 
// Company     : 
//
//-----------------------------------------------------------------------------
//
// Description : 
//
//-----------------------------------------------------------------------------
`timescale 1 ns / 1 ps

module delta_delay_2 ();
	
reg  clk1 = 1'b0;	 
reg  clk2;
wire clk3;		

reg a = 1'b0;
reg b;
reg c;
reg d;

initial begin
forever clk1 = #5 ~clk1;
end 

initial begin
repeat(10)
begin

#20 a = 1'b1;
#60 a = 1'b0;
end


end

/// ������������� ����� - �������������� ��������� �������  ---
always @(clk1) clk2 <= clk1;	
	
/// ������� 1 - ������������� ����� ��� ��������  
	
always 	@(posedge clk2)	d <= b;			
	
always 	@(posedge clk1)
begin	
	c <= b;		
	b <= a;
end				  

/// ������� 2 - ������������� ����� � �����������  
    
//always 	@(posedge clk1)	b = #1 a;	
//	
//always 	@(posedge clk1)	c = #1 b;		
//	
//always 	@(posedge clk2)	d = #1 b;			
	
/// ������� 3 - ������������� ����� ��� �������� �� � ��������������� ������� ����� assign  ---
//assign clk3 = clk1;		
//
//always 	@(posedge clk3)	d <= b;			
//	
//always 	@(posedge clk1)
//begin	
//	c <= b;		
//	b <= a;
//end	
	
endmodule
