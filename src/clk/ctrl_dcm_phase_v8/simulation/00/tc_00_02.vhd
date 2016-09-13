-------------------------------------------------------------------------------
--
-- Title       : tc_00_02
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
-- E-mail      : dsmv@insys.ru
--
-- Version     : 1.0
--
-------------------------------------------------------------------------------
--
-- Description :  �������� ������ ���� 3 ��
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use work.tb_00_pkg.all;

entity tc_00_02 is
end tc_00_02;


architecture bhv of tc_00_02 is
begin
	
	
tc: tb_00 
	generic map(
	    CLKFBOUT_MULT_F 	=> 10.000,
	    DIVCLK_DIVIDE 		=> 5,		 
	    CLKIN1_PERIOD 		=> 2.000,	-- 500 MHz
		
	    CLKOUT0_DIVIDE_F 	=> 2.000, 	-- 500 MHz - ������� �������
		CLKOUT1_DIVIDE 		=> 8,		-- 125 MHz - ������������� �������

		clk_in_change		=> '0',	-- 1 - ��������� ������� �������
	
		max_time		=> 5 ms,		-- ������������ ����� ����� 
		clk_delay		=> 2.2 ns,		-- �������� �������� �������
		period_clk		=> 2 ns			-- ������ �������� �������
		);	


end bhv;
