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
-- Description : 
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use work.tb_00_pkg.all;

entity tc_00_01 is
end tc_00_01;


architecture bhv of tc_00_01 is
begin
	
	
tc: tb_00 
	generic map(

	    CLKFBOUT_MULT_F 	=> 8.000,
	    DIVCLK_DIVIDE 		=> 2,		 
	    CLKIN1_PERIOD 		=> 4.000,	-- 250 MHz
		
	    CLKOUT0_DIVIDE_F 	=> 4.000, 	-- 250 MHz - рабочая частота
		CLKOUT1_DIVIDE 		=> 8,		-- 125 MHz - измерительная частота

		clk_in_change		=> '0',	-- 1 - изменение входной частоты
	
		max_time		=> 5 ms,		-- максимальное время теста 
		clk_delay		=> 2 ns,		-- задержка тактовой частоты
		period_clk		=> 4 ns			-- период тактовой частоты
	
	);	


end bhv;
