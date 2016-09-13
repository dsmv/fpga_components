-------------------------------------------------------------------------------
--
-- Title       : ctrl_dcm_phase_v6
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
-- E-mail      : dsmv@insys.ru
--
-- Version     : 1.5
--
-------------------------------------------------------------------------------
--
-- Description :  Узел автоподстройки фазы тактовой частоты
--
--				Сигнал входной тактовой частоты поступает на триггер во входном буфере.
--				Выходной сигнал DCM сдвигается до тех пор, пока фаза сигнала не попадёт
--				в область нестабильного защёлкивания сигнала входной тактовой частоты.
--				Автомат подсчитывает число 1 и 0 на интервале 1024 такта, и принимает
--				решение о сдвиге фазы. При достижении максимального или минимального 
--				значения сдвига производится инверсия сигнала поступающего на DCM,
--				сброс DCM и автомата управления в начальное состояние.
--
--				Узел включает в себя автомат определения изменения тактовой частоты.
--				При изменении входной тактовой частоты происходит сброс DCM и
--				начинается новый цикл подстройки фазы
--
--				Тактовая частота clk используется для определения изменения тактовой
--				частоты. На входе clk частота должна быть всегда
--
-------------------------------------------------------------------------------
--
--  Version 1.5  17.05.2011   Dmitry Smekhov
--				  Добавлен вход phase_tuning_disable - запрет подстройки фазы 
--				  
--
-------------------------------------------------------------------------------
--
--  Version 1.4  12.05.2011   Dmitry Smekhov
--				  Добавлен выход phase_locked - произведена подстройка частоты
--				  
--
-------------------------------------------------------------------------------
--
--  Version 1.3  01.03.2011   Dmitry Smekhov
--				  Параметр DCM_ADV изменён на USE_DCM_ADV из за конфликта
--				  с Active-HDL 8.3
--				  
--
-------------------------------------------------------------------------------
--
--  Version 1.2  27.12.2010   Dmitry Smekhov
--				  Добавлен параметр	CLK_FALLING - под спадающий фронт
--				  
--
-------------------------------------------------------------------------------
--
--  Version 1.1  20.05.2010   Eugene Voronkov
--				  Добавлен выход clk2x180
--				  
--
-------------------------------------------------------------------------------
--
--  Version 1.0   26.05.2009   Dmitry Smekhov
--				  Создан из ctrl_dcm_phase_v1 v2.3
--				  
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package ctrl_dcm_phase_v6_pkg	 is
											   
component ctrl_dcm_phase_v6 is
	generic (				
	
		is_simulation			: in integer:=0;			-- 1 - режим моделирования
		is_chipscope			: in integer:=0;			-- 1 - использовать ChipScope
		t_sim					: in time:=0 ns;			-- Задержка прохождения тактвого сигнала 
															-- (только для моделирования)
	    CLKIN_PERIOD 			: real := 10.0;             -- значение тактовой частоты [MHz]
	    DCM_PERFORMANCE_MODE 	: string := "MAX_SPEED";	-- параметр DCM_ADV
	    DFS_FREQUENCY_MODE 		: string := "LOW";			-- диапазон DCM
	    DLL_FREQUENCY_MODE 		: string := "LOW";			-- диапазон DCM
	    PHASE_SHIFT 			: integer := 0;				-- начальное значение сдвига
	    CLKDV_DIVIDE 			: real := 2.0;				-- коэффициент деления clkdv
	    CLKFX_DIVIDE 			: integer := 1;				-- коэффициент умножения clkfx
	    CLKFX_MULTIPLY 			: integer := 4;				-- коэффициент умножения clkfx
		CNT_N					: integer := 4;				-- номер разряда счётчика накопления
		USE_DCM_ADV				: integer := 0;				-- 0 - используется DCM, 1 - используется DCM_ADV
		CLK_FALLING				: integer := 0				-- 1 - подстройка под спадающий фронт
	);
	port(
		---- GLOBAL ----
		reset		: in std_logic;		-- 0 - сброс 
		clk			: in std_logic;		-- тактовая частота работы автомата подстройки фазы, 
										
		clk_in		: in std_logic;		-- исходная тактовая частота
		clk_fd		: in std_logic;		-- защёлкнутая тактовая частота
		
		phase_tuning_disable	: in std_logic:='0';	-- 1 - запрет подстройки фазы тактовой частоты
		
		shift		: out std_logic_vector(15 downto 0);	-- значение сдвига фазы
		
		---- Выходы тактовой частоты ----
		clk_out		: out std_logic;   --clk0	- глобальный тактовый сигнал
		clk0_out	: out std_logic;   --clk0	- не глобальный
		clk90		: out std_logic;   --clk90
		clk180		: out std_logic;   --clk180
		clk270		: out std_logic;   --clk270
		clk2x		: out std_logic;   --clk2x
		clk2x180	: out std_logic;   --clk2x180	
		clkdv		: out std_logic;   	
		clkfx		: out std_logic;
		locked		: out std_logic;	-- 1 - захват частоты DCM
		phase_locked: out std_logic;	-- 1 - произведена подстройка частоты 
		test		: out std_logic_vector(7 downto 0);
		
		t45			: in std_logic:='0';	-- вход 45 ChipScope
		t46			: in std_logic:='0'		-- вход 46 ChipScope

		);
end component;

end package ctrl_dcm_phase_v6_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library	unisim;
use unisim.vcomponents.all;

use work.ctrl_clk_detect_v1_pkg.all;

entity ctrl_dcm_phase_v6 is
	generic (				
	
		is_simulation			: in integer:=0;			-- 1 - режим моделирования
		is_chipscope			: in integer:=0;			-- 1 - использовать ChipScope
		t_sim					: in time:=0 ns;			-- Задержка прохождения тактвого сигнала 
															-- (только для моделирования)
	    CLKIN_PERIOD 			: real := 10.0;             -- значение тактовой частоты [MHz]
	    DCM_PERFORMANCE_MODE 	: string := "MAX_SPEED";	-- параметр DCM_ADV
	    DFS_FREQUENCY_MODE 		: string := "LOW";			-- диапазон DCM
	    DLL_FREQUENCY_MODE 		: string := "LOW";			-- диапазон DCM
	    PHASE_SHIFT 			: integer := 0;				-- начальное значение сдвига
	    CLKDV_DIVIDE 			: real := 2.0;				-- коэффициент деления clkdv
	    CLKFX_DIVIDE 			: integer := 1;				-- коэффициент умножения clkfx
	    CLKFX_MULTIPLY 			: integer := 4;				-- коэффициент умножения clkfx
		CNT_N					: integer := 4;				-- номер разряда счётчика накопления
		USE_DCM_ADV				: integer := 0;				-- 0 - используется DCM, 1 - используется DCM_ADV
		CLK_FALLING				: integer := 0				-- 1 - подстройка под спадающий фронт
	);
	port(
		---- GLOBAL ----
		reset		: in std_logic;		-- 0 - сброс 
		clk			: in std_logic;		-- тактовая частота работы автомата подстройки фазы, 
										
		clk_in		: in std_logic;		-- исходная тактовая частота
		clk_fd		: in std_logic;		-- защёлкнутая тактовая частота
		
		phase_tuning_disable	: in std_logic:='0';	-- 1 - запрет подстройки фазы тактовой частоты
		
		shift		: out std_logic_vector(15 downto 0);	-- значение сдвига фазы
		
		---- Выходы тактовой частоты ----
		clk_out		: out std_logic;   --clk0	- глобальный тактовый сигнал
		clk0_out	: out std_logic;   --clk0	- не глобальный
		clk90		: out std_logic;   --clk90
		clk180		: out std_logic;   --clk180
		clk270		: out std_logic;   --clk270
		clk2x		: out std_logic;   --clk2x
		clk2x180	: out std_logic;   --clk2x180	
		clkdv		: out std_logic;   	
		clkfx		: out std_logic;
		locked		: out std_logic;	-- 1 - захват частоты DCM
		phase_locked: out std_logic;	-- 1 - произведена подстройка частоты 
		test		: out std_logic_vector(7 downto 0);
		
		t45			: in std_logic:='0';	-- вход 45 ChipScope
		t46			: in std_logic:='0'		-- вход 46 ChipScope

		);
end ctrl_dcm_phase_v6;


architecture ctrl_dcm_phase_v6 of ctrl_dcm_phase_v6 is	
component icon
port
(
  control0    :   inout std_logic_vector(35 downto 0)
);
end component;
  

component ila48
port
(
  control     : inout std_logic_vector(35 downto 0);
  clk         : in    std_logic;
  trig0       : in    std_logic_vector(47 downto 0)
);
end component;
signal control0    	: std_logic_vector(35 downto 0);
signal trig0      	: std_logic_vector(47 downto 0);	   


signal clk_in0				: std_logic;
signal clkfb,clk0			: std_logic;
signal psen,psincdec,psdone	: std_logic;
signal locked0				: std_logic; 
signal reset_dcm,reset_ps	: std_logic;

signal shift0: std_logic_vector(15 downto 0); 


signal	cnt_interval		: std_logic_vector( 10 downto 0 );
signal	cnt_0				: std_logic_vector( 10 downto 0 );
signal	cnt_1		    	: std_logic_vector( 10 downto 0 );
signal	cnt_rst				: std_logic_vector( 4 downto 0 );

signal	cnt_reset			: std_logic;
signal	cnt_enable0			: std_logic; -- разрешение счёта на clk
signal	cnt_enable1			: std_logic; -- разрешение счёта на clk_in

signal	cnt_dec				: std_logic_vector( 10 downto 0 );

signal	cnt_dec_int			: integer;

signal	cnt_interval10_z	: std_logic;

type	st_type is ( s0, s1, s2, s3, s4 );
signal	stp					: st_type;			 

signal	cnt_0s				: std_logic;
signal	cnt_1s				: std_logic;	  

signal	reset_roc			: std_logic;
signal	reset_stp			: std_logic;	 

signal	clk_in_n			: std_logic;			 

signal	cnt0_x				: std_logic_vector( 10 downto 0 ); 
signal	clk_in_z			: std_logic;	  	 

signal	shift_max			: std_logic;
signal	shift_min			: std_logic;  

signal	change_clk			: std_logic;
signal	change_clk_z		: std_logic;
signal	sel_clk				: std_logic;			   
signal	clkb				: std_logic;	

signal	clk_in_change		: std_logic;	 -- 1 - изменение входной тактовой частоты

signal	clk_fd_z			: std_logic;

signal	pl_enable			: std_logic;	-- 1 - разрешение анализа pl_psincdec
signal	pl_psincdec			: std_logic;	-- предыдущее значение psincdec 
signal	pl_cnt				: std_logic_vector( 4 downto 0 );	-- счётчик изменения psincdec 

signal	pht_dis				: std_logic;

begin  
	
pht_dis <= phase_tuning_disable after 1 ns when rising_edge( clk );

	
gen_rising: if( CLK_FALLING=0 ) generate
	clk_fd_z <= clk_fd after 0.1 ns when rising_edge( clkfb );
end generate;

gen_falling: if( CLK_FALLING=1 ) generate
	clk_fd_z <= not clk_fd after 0.1 ns when rising_edge( clkfb );
end generate;
	
detect: ctrl_clk_detect_v1 
    port map(
            reset           => reset,                 -- 0 - общий сброс
            clk             => clk,	                 -- тактовая частота    
            
            clk_test        => clk_in,
            reset_dcm       => clk_in_change
            
                
);	
	
clk_in_z <= transport clk_in xor sel_clk after t_sim;	
	
pr_cnt_01: process( clkfb	) begin
	if( rising_edge( clkfb ) ) then
		if( cnt_reset='1' ) then
			cnt_0 <= (others=>'0') after 1 ns;
			cnt_1 <= (others=>'0') after 1 ns;
			cnt_interval <= (others=>'0') after 1 ns;
		else
			if( cnt_enable1='1' and cnt_interval(10)='0' ) then
				if( clk_fd_z='1' and cnt_1(10)='0' ) then
					cnt_1 <= cnt_1 + 1 after 1 ns;
				end if;
				
				if( clk_fd_z='0' and cnt_0(10)='0') then
					cnt_0 <= cnt_0 + 1 after 1 ns;		
				end if;	
				
				cnt_interval <= cnt_interval + 1 after 1 ns;
			end if;
		end if;
	end if;
end process;
		
cnt_interval10_z <= cnt_interval(10) after 1 ns when rising_edge( clk );

cnt_enable1 <= cnt_enable0 after 1 ns when rising_edge( clkfb );
cnt_reset <= not cnt_rst(4) after 1 ns when rising_edge( clkfb );

cnt_enable0 <= cnt_rst(4) and cnt_rst(3) when rising_edge( clk );
--cnt_enable0 <= '0', '1' after 10 us, '0' after 50 us;
--cnt_reset <= '0', '1' after 5 us, '0' after 6 us;



pr_state: process( reset_stp, clk ) begin
	if( reset_stp='0' ) then
		stp <= s0 after 1 ns;
		cnt_rst <= (others=>'0') after 1 ns;
		psen <= '0' after 1 ns;
		change_clk <= '0' after 1 ns;
		pl_enable <= '0' after 1 ns;			
		pl_cnt <= (others=>'0') after  1 ns;
		phase_locked <= '0' after 1 ns;
	elsif( rising_edge( clk ) ) then
		case( stp ) is
			when s0 =>
				cnt_rst <= (others=>'0') after 1 ns;
				if( pht_dis='0' ) then
					stp <= s1 after 1 ns;		 
				end if;
				psen <= '0' after 1 ns;
				
				
				
			when s1 => 
				if( cnt_rst( 4 )='1' and cnt_rst(3)='1' ) then
					stp <= s2 after 1 ns;
				else
					cnt_rst <= cnt_rst + 1 after 1 ns;
				end if;	
				
			when s2 => -- счёт
				if( cnt_interval10_z='1' ) then
					stp <= s3 after 1 ns;
				end if;
				
			when s3 => -- принятие решения
			--if( cnt_0( 10 downto 9 )="00" ) then
--				if( cnt_dec_int<0 ) then
--					psincdec <= '0' after 1 ns;
--				else
--					psincdec <= '1' after 1 ns;
--				end if;	
--				
--				--if( abs( cnt_dec_int ) < 128  ) then
--				if( cnt_0( 10 downto 8 )/="000" or
--					cnt_1( 10 downto 8 )/="000"	) then
--					
--					psen <= '1' after 1 ns;
--					stp <= s4 after 1 ns;  
--				else
--					psen <= '0' after 1 ns;
--					stp <= s0 after 1 ns;
--				end if;

				cnt0_x <= cnt_0;
				if( cnt_0 > 576  ) then
					if( shift_max='0' ) then
						psincdec <= '1' after 1 ns;
						psen <= '1' after 1 ns;
						stp <= s4 after 1 ns;  
					else
						change_clk <= '1' after 1 ns;
					end if;
				elsif( cnt_0 <448  ) then
					if( shift_min='0') then
						psincdec <= '0' after 1 ns;
						psen <= '1' after 1 ns;
						stp <= s4 after 1 ns;  
					else
						change_clk <= '1' after 1 ns;
					end if;
				else
					psen <= '0' after 1 ns;
					stp <= s0 after 1 ns; 
					
					phase_locked <= '1' after 1 ns;
					
				end if;
					
				
			when s4 =>
				psen <= '0' after 1 ns;	  
				if( psdone='1' and pl_enable='1' and (pl_psincdec xor psincdec)='1' ) then
					
					if( pl_cnt(4)='0' ) then
						pl_cnt <= pl_cnt + 1 after 1 ns;
					else
						phase_locked <= '1' after 1 ns;
					end if;
					
					
				end if;
				
				if( psdone='1' ) then
					pl_psincdec <= psincdec after 1 ns;
					pl_enable <= '1' after 1 ns;
					stp <= s0 after 1 ns;
				end if;
			--when others=> null;
		end case;
		
	end if;
end process;
		
--
--cnt_0s <= cnt_0(10) or cnt_0(9);
--cnt_1s <= cnt_1(10) or cnt_1(9);
--

--reset_dcm<= change_clk_z or not reset; 
reset_dcm<= change_clk_z or (not reset) or clk_in_change; 



xchange_clk:	srl16 port map( d=>change_clk, clk=>clk, a0=>'1', a1=>'1', a2=>'1', a3=>'1',
							q=>change_clk_z );

							
						
							
--reset_dcm <= not reset_roc;							

pr_clk_sel: process( change_clk ) begin
	if( reset='0' ) then
		sel_clk <= '0' after 1 ns;
	elsif( rising_edge( change_clk ) ) then
		sel_clk <= not sel_clk after 1 ns;
	end if;
end process;



pr_reset_stp: process( reset, change_clk_z, clk_in_change, clk ) begin
	if( reset='0' or change_clk_z='1' or clk_in_change='1' ) then
		reset_stp <='0' after 1 ns;
	elsif( rising_edge( clk ) ) then
		if( locked0='1' ) then
			reset_stp <= '1' after 1 ns;
		end if;
	end if;
end process;
	
		
		

clk_out	<= clkfb;						
clk_in_n <= not clk;

gen_dcm_adv: if	USE_DCM_ADV=1 generate 

xclkdcm: 	dcm_adv 
	generic map (						 
		DCM_AUTOCALIBRATION 	=> FALSE,
	    CLKIN_PERIOD 			=> CLKIN_PERIOD, 			  
	    CLKOUT_PHASE_SHIFT 		=> "VARIABLE_CENTER", 		  
	    DCM_PERFORMANCE_MODE 	=> DCM_PERFORMANCE_MODE, 	    
	    DFS_FREQUENCY_MODE 		=> DFS_FREQUENCY_MODE, 		  
	    DLL_FREQUENCY_MODE 		=> DLL_FREQUENCY_MODE, 		  
	    CLKDV_DIVIDE 			=> CLKDV_DIVIDE,			-- коэффициент деления clkdv
	    CLKFX_DIVIDE 			=> CLKFX_DIVIDE,			-- коэффициент умножения clkfx
	    CLKFX_MULTIPLY 			=> CLKFX_MULTIPLY,			-- коэффициент умножения clkfx
	    PHASE_SHIFT 			=> PHASE_SHIFT
)
port  map ( 
				clkin 		=> clk_in_z, --clk_in_n,
				clkfb 		=> clkfb,  
				
				clk0 		=> clk0, 
				clk90		=> clk90,
				clk180		=> clk180,
				clk2x180	=> clk2x180,
				clk270		=> clk270, 
				clk2x		=> clk2x,
				clkdv		=> clkdv,
				clkfx		=> clkfx,
				
				
				psclk		=> clk,
				psen		=> psen,
				psincdec	=> psincdec,
				psdone		=> psdone,
				
				rst 		=> reset_dcm, 
				locked 		=> locked0
			); 	 
			
end generate;

gen_dcm: if	USE_DCM_ADV=0 generate 

xclkdcm: 	dcm
	generic map (						 
		--DCM_AUTOCALIBRATION 	=> FALSE,
	    CLKIN_PERIOD 			=> CLKIN_PERIOD, 			  
	    CLKOUT_PHASE_SHIFT 		=> "VARIABLE", 		  
	    --DCM_PERFORMANCE_MODE 	=> DCM_PERFORMANCE_MODE, 	    
	    DFS_FREQUENCY_MODE 		=> DFS_FREQUENCY_MODE, 		  
	    DLL_FREQUENCY_MODE 		=> DLL_FREQUENCY_MODE, 		  
	    CLKDV_DIVIDE 			=> CLKDV_DIVIDE,			-- коэффициент деления clkdv
	    CLKFX_DIVIDE 			=> CLKFX_DIVIDE,			-- коэффициент умножения clkfx
	    CLKFX_MULTIPLY 			=> CLKFX_MULTIPLY,			-- коэффициент умножения clkfx
	    PHASE_SHIFT 			=> PHASE_SHIFT
)
port  map ( 
				clkin 		=> clk_in_z, --clk_in_n,
				clkfb 		=> clkfb,  
				
				clk0 		=> clk0, 
				clk90		=> clk90,
				clk180		=> clk180,
				clk2x180	=> clk2x180,
				clk270		=> clk270, 
				clk2x		=> clk2x,
				clkdv		=> clkdv,
				clkfx		=> clkfx,
				
				
				psclk		=> clk,
				psen		=> psen,
				psincdec	=> psincdec,
				psdone		=> psdone,
				
				rst 		=> reset_dcm, 
				locked 		=> locked0
			); 	 
			
end generate;


xclkfb:	bufg port map( i=>clk0, o=>clkfb );	  
locked<= locked0;



reset_ps<= reset and locked0;


pr_shif: process( clk ) begin
	if( rising_edge( clk ) ) then
		if( reset_stp='0' ) then
			shift0 <= conv_std_logic_vector( PHASE_SHIFT, 16 ) after 1 ns;
		elsif( psen='1' ) then
			if( psincdec='1' ) then
				shift0 <= signed(shift0) + 1 after 1 ns;
			else
				shift0 <= signed(shift0) - 1 after 1 ns;
			end if;
		end if;
	end if;
end process;

shift_max <= '1' when shift0( 8 downto 0 )= '0' & x"FF" else '0';
shift_min <= '1' when shift0( 8 downto 0 )= '1' & x"00" else '0';
			
shift( 15 downto 8 ) <= (others=>'0');
shift( 7 downto 0 ) <= shift0( 7 downto 0 );
--test<= psen;


--test(3)<= ind_l;
--test(4)<= reset_ps;
--test(5)<= ind_or;
--test(6)<= st(0);
--test(7)<= st(1);
--
--	

--cnt_dec <= cnt_0 - cnt_1 when rising_edge( clk ) and stp=s2 and cnt_interval(10)='1';
--
--cnt_dec_int <= conv_integer( signed( cnt_dec ) ) ;


test(0)<= psincdec;
test(1)<= psdone;
test(2)<= psen;
test( 7 downto 3 ) <= (others=>'0');  



gen_chipscope: if( is_chipscope=1 ) generate

xclkb: bufg port map( clkb, clk_in );

--gen_chipscope: if( is_chipscope=1 ) generate
--	i_icon : icon
--	port map
--	(
--	  control0    => control0
--	);
--	
--		
--	i_ila48 : ila48
--	port map
--	(
--	  control   => control0,
--	  clk       => clkb ,
--	  trig0     => trig0
--	);					 
--
--	
--end generate;

trig0(15 downto 0)	<=shift0;
trig0(26 downto 16)	<=cnt_0;

trig0(32)			<=psincdec; 
trig0(33)			<=psdone;   
trig0(34)			<=psen; 
trig0(35)			<=shift_min; 
trig0(36)			<=shift_max; 
trig0(37)			<=sel_clk; 
trig0(38)	<= change_clk;
trig0(39)	<= change_clk_z;		 
trig0(40)	<= reset_dcm;				
trig0(41) <= reset_stp;
trig0( 44 downto 42 ) <= "000" when stp=s0 else
						 "001" when stp=s1 else
						 "010" when stp=s2 else
						 "011" when stp=s3 else
						 "100" ;
trig0(45) <=	t45;
trig0(46) <=	t46;
trig0(47) <=	reset;
--trig0(47 downto 45)	<=(others=>'0');

--trig0(31 downto 0)	<=dio_out_dataf;--dsp_data_f(31 downto 0);	--data_64(31 downto 0);
--trig0(32)			<=dio_out_val;--dsp_data_f(32); 			--dio_in_wr_t;
--trig0(47 downto 33)	<=(others=>'0');


end generate;

clk0_out <= clk0;

end ctrl_dcm_phase_v6;

