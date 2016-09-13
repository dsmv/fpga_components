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
-- Description :   Задержка внутри ПЛИС 7 нс
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
		
	    CLKOUT0_DIVIDE_F 	=> 10.000, 	-- 100 MHz - рабочая частота
		CLKOUT1_DIVIDE 		=> 10,		-- 100 MHz - измерительная частота

		clk_in_change		=> '0',	-- 1 - изменение входной частоты
	
		max_time		=> 5 ms,		-- максимальное время теста 
		clk_delay		=> 2 ns,		-- задержка тактовой частоты
		period_clk		=> 10 ns			-- период тактовой частоты
	
	);	


end bhv;
