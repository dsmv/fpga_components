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
		max_time		=> 5 ms,		-- ������������ ����� ����� 
		clk_delay		=> 7 ns,		-- �������� �������� �������
		period_clk		=> 8 ns			-- ������ �������� �������
	
	);	


end bhv;
