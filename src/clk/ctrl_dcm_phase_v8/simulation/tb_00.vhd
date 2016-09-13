-------------------------------------------------------------------------------
--
-- Title       : tb_00
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
-- E-mail      : dsmv@insys.ru
--
-- Version     : 1.0
--
-------------------------------------------------------------------------------
--
-- Description :  �������� ctrl_dcm_phase_v8
--										   
--			����������� ���� ������� ������� �� ������� phase_locked
--
--			clk_in1 - ������� ������� � ���������� ��������
--			clk_in2 - ������������ �������� ����������� ������� � ����
--			clk0	- ����� DCM, � ���������� ���������� 
--					  ������ ��������� � clk_in1

-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all; 

package tb_00_pkg is
	
component tb_00 is	   
	generic(   
	    CLKFBOUT_MULT_F 	: in real := 10.000;
	    DIVCLK_DIVIDE 		: in integer := 1;	
		
	    CLKIN1_PERIOD 		: in real := 10.000;
		
	    CLKOUT0_DIVIDE_F 	: in real := 1.000;		-- ������� �������
        CLKOUT1_DIVIDE 		: in integer := 4;		-- ������������� �������
		
		clk_in_change		: in  std_logic:='0';	-- 1 - ��������� ������� �������
		
		max_time			: in time:=100 ms;		-- ������������ ����� ����� 
		clk_delay			: in time:=1 ns;		-- �������� �������� �������
		period_clk			: in time:=10 ns		-- ������ �������� �������
	
	);
end component;

end package;


library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library	unisim;
use unisim.vcomponents.all;

library std;
use std.textio.all;
use work.pck_fio.all;	   
use work.utils_pkg.all;

--- Component ---
use work.ctrl_dcm_phase_v8_pkg.all;
use work.model_line_v1_pkg.all;


entity tb_00 is	   
	generic(   
	    CLKFBOUT_MULT_F 	: in real := 10.000;
	    DIVCLK_DIVIDE 		: in integer := 1;	
		
	    CLKIN1_PERIOD 		: in real := 10.000;
		
	    CLKOUT0_DIVIDE_F 	: in real := 1.000;		-- ������� �������
        CLKOUT1_DIVIDE 		: in integer := 4;		-- ������������� �������
		
		clk_in_change		: in  std_logic:='0';	-- 1 - ��������� ������� �������
		
		max_time			: in time:=100 ms;		-- ������������ ����� ����� 
		clk_delay			: in time:=1 ns;		-- �������� �������� �������
		period_clk			: in time:=10 ns		-- ������ �������� �������
	
	);
end tb_00;


architecture tb_00 of tb_00 is			

constant	half_period	: time:=period_clk/2;


-- �����
signal reset 				: std_logic;			-- 0 - �����

signal	clk					: std_logic:='0';
signal	clk_in0				: std_logic:='0';
signal	clk_in1				: std_logic;
signal	clk_in2				: std_logic;
signal	clk_in4				: std_logic:='0';
signal	clk_fd				: std_logic;
signal	clk0				: std_logic;
signal	clk90				: std_logic;
signal	clk2x				: std_logic;
signal	phase_locked		: std_logic;	
signal	phase_shift			: std_logic_vector( 15 downto 0 );

signal	locked				: std_logic;	-- 1 - ������ ������� DCM
signal	dcm_sel_clk		 	: std_logic;	-- 1 - �������� ������� ������� ��� MMCM
signal	dcm_rstp			: std_logic;	-- 1 - ����� MMCM					
signal	dcm_psincdec		: std_logic;	-- ����������� ��������� ����
signal	dcm_psen			: std_logic;	-- 1 - ��� ��������� ����
signal	dcm_psdone			: std_logic;	-- 1 - ��������� ���������� ����

signal	clkfb				: std_logic;
signal	clk0_pll			: std_logic;
signal	clk1_pll			: std_logic;
signal	clk1				: std_logic;


	
begin
	
	
reset <= '0', '1' after 1000 ns;
clk <= not clk after 5 ns;	 

---- ������������ �������� ������� ----
clk_in0 <= not clk_in0 after half_period;
	

---- ������������ �������� �������� ������� ----
x_clk: model_line_v1 
--	generic(
--		Seed1			: in integer:=5;
--		Seed2			: in integer:=7;  
--		delay_min		: in real:=1.0;  --�������� � ns
--		delay_max		: in real:=3.0;  --�������� � ns
--		jitter			: in real:=50.0);--�������� � ps
	port map(  
		const			=> 10,
		d_in			=> clk_in0,
		d_out			=> clk_in1
	);
	
	
---- ������������ �������� ������� ----	
clk_fd <= clk_in1 after 0.1 ns when rising_edge( clk1 );
--clk_fd <= clk_in1 after 0.1 ns when falling_edge( clk0 );

---- �������� ��������������� �������� ������� ----
clk_in2 <= transport clk_in1 xor dcm_sel_clk  after clk_delay;	



xpll: MMCM_ADV
  generic map(
     BANDWIDTH 			=> "OPTIMIZED",
     CLKFBOUT_MULT_F  	=> CLKFBOUT_MULT_F,  	
	 CLKOUT0_DIVIDE_F	=> CLKOUT0_DIVIDE_F,
     CLKOUT1_DIVIDE 	=> CLKOUT1_DIVIDE,			-- ������������� �������
     CLKIN1_PERIOD 		=> CLKIN1_PERIOD, 		
     CLKIN2_PERIOD 		=> CLKIN1_PERIOD, 		
     DIVCLK_DIVIDE 		=> DIVCLK_DIVIDE,
	 
--	CLKOUT0_USE_FINE_PS => TRUE,
--	CLKOUT1_USE_FINE_PS => TRUE
	CLKFBOUT_USE_FINE_PS => TRUE

  )
  port map(
     CLKFBOUT 	=> clkfb,
     CLKOUT0 	=> clk0_pll,
     CLKOUT1 	=> clk1_pll,
     CLKFBIN 	=> clkfb,
     CLKIN1 	=> clk_in2,
     CLKIN2 	=> '0',
     CLKINSEL 	=> '1',
     PWRDWN 	=> '0',		
	 LOCKED 	=> locked,
     RST 		=> dcm_rstp,	  
     PSDONE 	=> dcm_psdone,
     DADDR 		=> (others=>'0'),
     DCLK 		=> '0',
     DEN 		=> '0',
     DI 		=> (others=>'0'),
     DWE 		=> '0',
     PSCLK 		=> clk,
     PSEN 		=> dcm_psen,
     PSINCDEC 	=> dcm_psincdec
	 
	 					    
  );  
  
xclk0:	bufg port map( clk0, clk0_pll );
xclk1:	bufg port map( clk1, clk1_pll );

uut: ctrl_dcm_phase_v8 
	generic map(				
		CLK_FALLING				=> 1						-- 1 - ���������� ��� ��������� �����
	)
	port map(
		---- GLOBAL ----
		reset			=> reset,		-- 0 - ����� 
		clk				=> clk,			-- �������� ������� ������ �������� ���������� ����, 
										
		clk_in_change	=> clk_in_change,	-- 1 - ��������� ������� �������
		clk_in			=> clk1,		-- �������� �������� �������
		clk_fd			=> clk_fd,		-- ����������� �������� �������
		
		shift			=> phase_shift,	-- �������� ������ ����
		
		locked			=> locked,						-- 1 - ������ ������� DCM
		phase_locked	=> phase_locked,  	 		    -- 1 - ����������� ���������� ������� 
						                
		dcm_sel_clk		=> dcm_sel_clk,		 			-- 1 - �������� ������� ������� ��� MMCM
		dcm_rstp		=> dcm_rstp,					-- 1 - ����� MMCM					
		dcm_psincdec	=> dcm_psincdec,				-- ����������� ��������� ����
		dcm_psen		=> dcm_psen,					-- 1 - ��� ��������� ����
		dcm_psdone		=> dcm_psdone					-- 1 - ��������� ���������� ����
		
		
		

		);	

		
pr_check: process 

variable	index				: integer;
variable	flag_error			: integer;
variable	tm_start			: time;
variable	tm_stop				: time;


variable L 	: line;

begin
	
	wait for 200 ns;
	
	loop

		if( phase_locked='1' ) then
			fprint( output, L, "���������� ��������� %r\n", fo(now) );
			for ii in 0 to 31 loop
				fprint( output, L, "time:%r  shift: %r\n", fo(now), fo(phase_shift) );
				wait for 15 us;
			end loop;
			exit;
			
		end if;
		
			
			
		if( now>max_time ) then
			 exit;
		end if;
		
		
		wait for 200 ns;
	end loop;	  
	
	tm_stop:=now;
	

	if( phase_locked='1' ) then
		flag_error:=0;
	else			  		   
		fprint( output, L, "�� ������� �������� ���������� �������\n", fo(now) );
		flag_error:=1;
	end if;

	
	if( flag_error=0   ) then
		fprint( output, L, "\n\nTEST finished successfully\n\n" );
	else
		fprint( output, L, "\n\nTEST finished with ERR\n\n" );
	end if;
	
	utils_stop_simulation;
	
	wait;
	
end process;	
	


end tb_00;
