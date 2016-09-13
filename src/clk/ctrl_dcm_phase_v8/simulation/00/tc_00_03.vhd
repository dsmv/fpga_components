-------------------------------------------------------------------------------
--
-- Title       : tc_00_01
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
-- E-mail      : dsmv@insys.ru
--
-- Version     : 1.0
--
-------------------------------------------------------------------------------
--
-- Description :   �������� ������ ���� 7 ��
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use work.tb_00_pkg.all;

entity tc_00_03 is
end tc_00_03;


architecture bhv of tc_00_03 is
begin
	
	
tc: tb_00 
	generic map(

	    CLKFBOUT_MULT_F 	=> 10.000,
	    DIVCLK_DIVIDE 		=> 1,		 
	    CLKIN1_PERIOD 		=> 10.000,	-- 100 MHz
		
	    CLKOUT0_DIVIDE_F 	=> 10.000, 	-- 100 MHz - ������� �������
		CLKOUT1_DIVIDE 		=> 10,		-- 100 MHz - ������������� �������

		clk_in_change		=> '0',	-- 1 - ��������� ������� �������
	
		max_time		=> 5 ms,		-- ������������ ����� ����� 
		clk_delay		=> 2 ns,		-- �������� �������� �������
		period_clk		=> 10 ns			-- ������ �������� �������
	
	);	


end bhv;
