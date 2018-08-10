-------------------------------------------------------------------------------
--
-- Title       : delta_delay
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
-- E-mail      : dsmv@insys.ru
--
-- Version     : 1.0
--
-------------------------------------------------------------------------------
--
-- Description : ������������ ������� ������ ��������
--
-------------------------------------------------------------------------------
--
-- Version 1.0  
--
-------------------------------------------------------------------------------



library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity delta_delay is
end delta_delay;


architecture delta_delay of delta_delay is

signal	clk1		: std_logic:='0';
signal	clk2		: std_logic;
alias	clk3		: std_logic is clk1;	-- ���������� ������� ����� ������� clk1

signal	a			: std_logic;
signal	b			: std_logic;
signal	c			: std_logic;
signal	d			: std_logic;


begin							
	
--- ������������ �������� �������� ---

clk1 <= not clk1 after 5 ns;

pr_a: process begin
	a <= '0' after 1 ns;
	wait until rising_edge( clk1 );
	wait until rising_edge( clk1 );
	a <= '1' after 1 ns;
	wait until rising_edge( clk1 );
	wait until rising_edge( clk1 );
	wait until rising_edge( clk1 );
	wait until rising_edge( clk1 );
end process;	
	

--- ������������� ����� - �������������� ��������� �������  ---
clk2 <= clk1; -- ��� � ���� ��������, �� ���� ��� ������ ��� ������� �������������

--- ������� 1 - ������������� ����� ��� ��������  ---


b <= a when rising_edge( clk1 );
c <= b when rising_edge( clk1 );
d <= b when rising_edge( clk2 );


--- ������� 2 - ������������� ����� � �����������  ---
--
--clk2 <= clk1;
--b <= a after 1 ns when rising_edge( clk1 );
--c <= b after 1 ns when rising_edge( clk1 );
--d <= b after 1 ns when rising_edge( clk2 );


--- ������� 3 - ������������� ����� ��� �������� �� � ��������������� ������� ����� alias  ---
--b <= a when rising_edge( clk1 );
--c <= b when rising_edge( clk1 );
--d <= b when rising_edge( clk3 );

end delta_delay;
