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
-- Description : 
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
		max_time		=> 2 ms,		-- ������������ ����� ����� 
		period_wr		=> 22 ns,	 	-- ������ ������� ������
		period_rd		=> 10 ns,		-- ������ ������� ������
		fifo_size		=> 1024,		-- ������ FIFO 
		FIFO_PAF		=> 16,			-- ������� ������������ ����� PAF  
		FIFO_PAE		=> 128,			-- ������� ������������ ����� PAE  
		max_fifo0_pkg	=> 256			-- ����� ������� ��� �����
	
	);	


end bhv;
