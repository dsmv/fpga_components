-------------------------------------------------------------------------------
--
-- Title       : model_line_v1
-- Design      : equator_nb
-- Author      : Ivanov Ilya
-- Company     : InSys
-- E-MAIL      : ivanov@insys.ru
--
-- Version     : 1.0

-------------------------------------------------------------------------------
--
-- Description :  осуществляет задержку входного сигнала на случайную величину от delay_min до delay_max
-- задержка принимает фиксированное значение втечении всего моделирования. при новом моделировании задержка меняется
-- jitter-- задержка при каждой смене данных
--

-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package model_line_v1_pkg is 	
component model_line_v1 is 
	generic(
		Seed1			: in integer:=5;
		Seed2			: in integer:=7;  
		delay_min		: in real:=1.0;  --задержка в ns
		delay_max		: in real:=3.0;  --задержка в ns
		jitter			: in real:=50.0);--задержка в ps
	port(  
		const			: in integer;
		d_in			: in std_logic;	
		d_out			: out std_logic);
		
end component;
end model_line_v1_pkg; 

library IEEE;
use IEEE.STD_LOGIC_1164.all; 
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;


entity model_line_v1 is	
	generic(
		Seed1			: in integer:=5;
		Seed2			: in integer:=7;  
		delay_min		: in real:=1.0;  --задержка в ns
		delay_max		: in real:=3.0;  --задержка в ns
		jitter			: in real:=50.0);--задержка в ps
	port(  
		const			: in integer;
		d_in			: in std_logic;	
		d_out			: out std_logic);

end model_line_v1;

architecture model_line_v1 of model_line_v1 is 	  

signal	delay: real;  
signal d_out_loc: std_logic;   


begin 
	

	
pr_jitter : process(d_in)
variable Seed1o : integer:=Seed1;
variable Seed2o : integer:=Seed2;
variable jit : real;
begin
	 if (d_in'event) then
		UNIFORM(Seed1o, Seed2o, jit);
		d_out_loc <= d_in after jitter*jit*1 ps;
	end if;
end process;

pr_delay : process
variable Seed1o : integer:=Seed1*const;
variable Seed2o : integer:=Seed2*const; 
variable del: real;

begin	
	wait for 20 ps;	
	Seed1o:=Seed1*const;
	Seed2o:=Seed2*const;  
	for ii in 0 to const loop
	UNIFORM(Seed1o, Seed2o, del); 
	end loop;
	delay<=	delay_min+del*(delay_max-delay_min);
	wait;
end process;	 

pr_dout : process(d_out_loc)
begin
	 if (d_out_loc'event) then
		d_out <= transport d_out_loc after delay*1 ns;
	end if;
end process;

	

end model_line_v1;