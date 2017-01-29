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
		max_time		=> 2 ms,		-- ������������ ����� ����� 
		period_wr		=> 10 ns,	 	-- ������ ������� ������
		period_rd		=> 21 ns,		-- ������ ������� ������
		fifo_size		=> 1024,		-- ������ FIFO 
		FIFO_PAF		=> 128,			-- ������� ������������ ����� PAF  
		FIFO_PAE		=> 16,			-- ������� ������������ ����� PAE  
		max_fifo0_pkg	=> 256			-- ����� ������� ��� �����
	
	);	


end bhv;
