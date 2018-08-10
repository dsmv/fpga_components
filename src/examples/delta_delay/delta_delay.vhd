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
-- Description : Демонстрация влияния дельта задержки
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
alias	clk3		: std_logic is clk1;	-- назначение другого имени сигналу clk1

signal	a			: std_logic;
signal	b			: std_logic;
signal	c			: std_logic;
signal	d			: std_logic;


begin							
	
--- Формирование тестовых сигналов ---

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
	

--- Синтезируемая часть - переназначение тактового сигнала  ---
clk2 <= clk1; -- вот в этом проблема, не надо так делать без крайней необходимости

--- Вариант 1 - Синтезируемая часть без задержек  ---


b <= a when rising_edge( clk1 );
c <= b when rising_edge( clk1 );
d <= b when rising_edge( clk2 );


--- Вариант 2 - Синтезируемая часть с задержеками  ---
--
--clk2 <= clk1;
--b <= a after 1 ns when rising_edge( clk1 );
--c <= b after 1 ns when rising_edge( clk1 );
--d <= b after 1 ns when rising_edge( clk2 );


--- Вариант 3 - Синтезируемая часть без задержек но с переназначением сигнала через alias  ---
--b <= a when rising_edge( clk1 );
--c <= b when rising_edge( clk1 );
--d <= b when rising_edge( clk3 );

end delta_delay;
