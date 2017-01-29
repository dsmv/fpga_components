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
		max_time		=> 2 ms,		-- максимальное время теста 
		period_wr		=> 10 ns,	 	-- период частоты записи
		period_rd		=> 21 ns,		-- период частоты чтения
		fifo_size		=> 1024,		-- размер FIFO 
		FIFO_PAF		=> 128,			-- уровень срабатывания флага PAF  
		FIFO_PAE		=> 16,			-- уровень срабатывания флага PAE  
		max_fifo0_pkg	=> 256			-- число пакетов для приёма
	
	);	


end bhv;
