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
		max_time		=> 5 ms,		-- максимальное время теста 
		clk_delay		=> 1 ns,		-- задержка тактовой частоты
		period_clk		=> 8 ns			-- период тактовой частоты
	
	);	


end bhv;
