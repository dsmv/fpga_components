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
-- Description :  �������� ctrl_dcmphase_v6
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
		max_time		: in time:=100 ms;		-- ������������ ����� ����� 
		clk_delay		: in time:=1 ns;		-- �������� �������� �������
		period_clk		: in time:=10 ns		-- ������ �������� �������
	
	);
end component;

end package;


library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library std;
use std.textio.all;
use work.pck_fio.all;	   
use work.utils_pkg.all;

--- Component ---
use work.ctrl_dcm_phase_v6_pkg.all;
use work.model_line_v1_pkg.all;


entity tb_00 is	   
	generic(
		max_time		: in time:=100 ms;		-- ������������ ����� ����� 
		clk_delay		: in time:=1 ns;		-- �������� �������� �������
		period_clk		: in time:=10 ns		-- ������ �������� �������
	
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


	
begin
	
	
reset <= '0', '1' after 200 ns;
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
clk_fd <= clk_in1 after 0.1 ns when rising_edge( clk0 );
--clk_fd <= clk_in1 after 0.1 ns when falling_edge( clk0 );

---- �������� ��������������� �������� ������� ----
clk_in2 <= transport clk_in1 after clk_delay;	



uut: ctrl_dcm_phase_v6 
	generic map(				
--	
--		is_simulation			: in integer:=0;			-- 1 - ����� �������������
--		is_chipscope			: in integer:=0;			-- 1 - ������������ ChipScope
--		t_sim					: in time:=0 ns;			-- �������� ����������� �������� ������� 
--															-- (������ ��� �������������)
--	    CLKIN_PERIOD 			: real := 10.0;             -- �������� �������� ������� [MHz]
--	    DCM_PERFORMANCE_MODE 	: string := "MAX_SPEED";	-- �������� DCM_ADV
--	    DFS_FREQUENCY_MODE 		: string := "LOW";			-- �������� DCM
--	    DLL_FREQUENCY_MODE 		: string := "LOW";			-- �������� DCM
--	    PHASE_SHIFT 			: integer := 0;				-- ��������� �������� ������
--	    CLKDV_DIVIDE 			: real := 2.0;				-- ����������� ������� clkdv
--	    CLKFX_DIVIDE 			: integer := 1;				-- ����������� ��������� clkfx
--	    CLKFX_MULTIPLY 			: integer := 4;				-- ����������� ��������� clkfx
--		CNT_N					: integer := 4;				-- ����� ������� �������� ����������
--		DCM_ADV					: integer := 0				-- 0 - ������������ DCM, 1 - ������������ DCM_ADV
		CLK_FALLING				=> 0						-- 1 - ���������� ��� ��������� �����
	)
	port map(
		---- GLOBAL ----
		reset		=> reset,		-- 0 - ����� 
		clk			=> clk,			-- �������� ������� ������ �������� ���������� ����, 
										
		clk_in		=> clk_in2,		-- �������� �������� �������
		clk_fd		=> clk_fd,		-- ����������� �������� �������
		
		shift		=> phase_shift,	-- �������� ������ ����
		
		---- ������ �������� ������� ----
		clk_out		=> clk0,   --clk0	- ���������� �������� ������
		clk90		=> clk90,   --clk90
		--clk180		: out std_logic;   --clk180
		--clk270		: out std_logic;   --clk270
		clk2x		=> clk2x,	   --clk2x	  
		--clkdv		: out std_logic;   	
		--clkfx		: out std_logic;
		phase_locked => phase_locked
		--test		: out std_logic_vector(7 downto 0);
		
		--t45			: in std_logic:='0';	-- ���� 45 ChipScope
		--t46			: in std_logic:='0'		-- ���� 46 ChipScope

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
