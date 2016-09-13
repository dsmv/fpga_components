---------------------------------------------------------------------------------------------------
--
-- Title       : ctrl_clk_detect_v1
-- Author      : Ilya Ivanov
-- Company     : Instrumental System
--
-- Version     : 1.4
---------------------------------------------------------------------------------------------------
--
-- Description : Узел контролирует частоту clk_test и сравнивает ее с частотой clk
--                              если частота clk_test < 0.1 clk или clk < 2 clk_test, или если частота clk_test меняется
--                              узел формирует сигнал сброса для DCM
--         
---------------------------------------------------------------------------------------------------
--                                      
-- Version 1.0  06.09.2006
--                              начальная версия                                                  
--                                      

---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

use work.adm2_pkg.all;


package ctrl_clk_detect_v1_pkg is
        
component ctrl_clk_detect_v1 is   

        port(
                reset           : in std_logic;                 -- 0 - общий сброс
                clk             : in std_logic;                 -- тактовая частота    
                
                clk_test        : in std_logic;
                reset_dcm       : out std_logic
                
                
        );
end component;

end package ctrl_clk_detect_v1_pkg;



library IEEE;
use IEEE.STD_LOGIC_1164.all;  
use ieee.std_logic_unsigned.all;
use work.adm2_pkg.all;
 
entity ctrl_clk_detect_v1 is 
        
        port(
                reset           : in std_logic;                 -- 0 - общий сброс
                clk             : in std_logic;                 -- тактовая частота      
                
                clk_test        : in std_logic;
				test			: out std_logic_vector(63 downto 0);
                reset_dcm       : out std_logic
                
                
        );
end ctrl_clk_detect_v1;


architecture ctrl_clk_detect_v1 of ctrl_clk_detect_v1 is  




signal cnt_clk  : std_logic_vector(14 downto 0); 
signal cnt_clk_test,cnt_clk_test0       : std_logic_vector(15 downto 0); 
signal a,b,a_sub,b_sub: std_logic_vector(15 downto 0); 
signal c_res: std_logic_vector(15 downto 0); 
signal st_sub: std_logic_vector(1 downto 0);
signal cnt_sub: std_logic_vector(3 downto 0);
signal start_sub: std_logic;
signal cary: std_logic;
signal ready_sub,less: std_logic;
signal cnt_m: std_logic;  
signal st: std_logic_vector(1 downto 0); 


signal reset_dcm0: std_logic;  


begin  

pr_cnt: process(clk,reset,cnt_m)
begin           
        if(reset='0' or cnt_m='1')then       
                cnt_clk<=(others=>'0');
        elsif(rising_edge(clk))then       
                cnt_clk<=cnt_clk+'1';
        end if;
end process;

pr_cnt_test: process(clk_test,cnt_m,reset)
begin           
        if(reset='0' or cnt_m='1' )then       
                cnt_clk_test<=(others=>'0');
        elsif(rising_edge(clk_test))then        
	        cnt_clk_test<=cnt_clk_test+'1';
        end if;
end process;

pr_reset: process(clk,reset) 
variable v_cnt_m,v_start_sub: std_logic;
begin           
        if(reset='0')then       
                cnt_clk_test0<=(others=>'0');
                reset_dcm0<='1';
                start_sub<='0';
                cnt_m<='0';  
				st<=(others=>'0');
        elsif(rising_edge(clk))then      
                v_start_sub:='0';v_cnt_m:='0';
                case st is                        
                when "00"=> if(cnt_clk(14)='1')then
                                                cnt_clk_test0<=cnt_clk_test;
                                                a<=cnt_clk_test0;
                                                b<=cnt_clk_test;
                                                v_start_sub:='1';
                                                st(0)<='1';
                                        end if; 
                when "01"=> if(ready_sub='1')then 
                                v_cnt_m:='1';
								b<=c_res;
								v_start_sub:='1'; 
								st(1)<='1'; 
								a(10 downto 0)<= a(15 downto 5);
								a(15 downto 11)<= "00000";
				
							end if;	 
				
                when "11"=> if(ready_sub='1')then 
								if(cnt_clk_test0(15 downto 8)=x"00")then
									reset_dcm0<= '1'; 
								else
									
									reset_dcm0<= less; 
								end if;	 
								st<="00";
				
							end if;
                    
                        
                when others=>null;
 	            end case;
                
                
                start_sub<=v_start_sub;
                cnt_m<=v_cnt_m;
        end if;  
        
end process;  

 reset_dcm<=reset_dcm0;

pr_sub: process(clk,reset)
begin           
        if(reset='0')then  
                cnt_sub<=(others=>'0'); 
                ready_sub<='0';
                less<='0';
                st_sub<=(others=>'0'); 
				c_res<=(others=>'0'); 
				cary<='0';
        elsif(rising_edge(clk))then     
                case st_sub is
                when "00"=>     if(start_sub='1')then b_sub<=not b; a_sub<=a;st_sub(0)<='1'; end if;
								ready_sub<='0';less<='0';
                when "01"=>     b_sub<=b_sub+'1';st_sub(1)<='1';cary<='0';
                when "11"=>	    cnt_sub<=cnt_sub+'1';
                                        a_sub(14 downto 0)<=a_sub(15 downto 1);
                                        b_sub(14 downto 0)<=b_sub(15 downto 1);
                                        c_res(14 downto 0)<=c_res(15 downto 1); 
                                        c_res(15)<=     a_sub(0) xor b_sub(0) xor cary;
                                        cary<=(a_sub(0) and b_sub(0)) or (a_sub(0) and cary) or (b_sub(0)and cary); 
                                        
                                        if(cnt_sub=x"f")then st_sub(0)<='0'; end if;  
                        
                when "10"=>     if(c_res(15)='1')then c_res<= not c_res -'1';  less<='1'; end if;
					ready_sub<='1';st_sub(1)<='0';
                        
                        when others=>null;
                end case;
        end if;
end process;   


end ctrl_clk_detect_v1;