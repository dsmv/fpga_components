-------------------------------------------------------------------------------
--
-- Title       : ctrl_dcm_phase_v8
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
-- E-mail      : dsmv@insys.ru
--
-- Version     : 1.0
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
--  Version 1.0   17.03.2014   Dmitry Smekhov
--				  Создан из ctrl_dcm_phase_v6 v1.5
--				  
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package ctrl_dcm_phase_v8_pkg	 is
											   
component ctrl_dcm_phase_v8 is
	generic (				
		CNT0_MIN				: in integer := 448;	-- нижнее значения зоны подстройки
		CNT0_MAX				: in integer := 576;	-- верхнее значение зоны подстройки
	    PHASE_SHIFT 			: in integer := 0;				-- начальное значение сдвига
		CLK_FALLING				: in integer := 0				-- 1 - подстройка под спадающий фронт
	);
	port(
		---- GLOBAL ----
		reset					: in std_logic;		-- 0 - сброс 
		clk						: in std_logic;		-- тактовая частота работы автомата подстройки фазы, 
										
		clk_in_change			: in  std_logic;	-- 1 - изменение входной частоты
		clk_in					: in std_logic;		-- глобальная тактовая частота
		
		clk_fd					: in std_logic;		-- защёлкнутая тактовая частота
		
		phase_tuning_disable	: in std_logic:='0';	-- 1 - запрет подстройки фазы тактовой частоты
		
		shift					: out std_logic_vector(15 downto 0);	-- значение сдвига фазы
		
		locked					: in  std_logic;	-- 1 - захват частоты DCM
		phase_locked			: out std_logic;	-- 1 - произведена подстройка частоты 
		
		dcm_sel_clk		 		: out std_logic;	-- 1 - инверсия входной частоты для MMCM
		dcm_rstp				: out std_logic;	-- 1 - сброс MMCM					
		dcm_psincdec			: out std_logic;	-- направление изменения фазы
		dcm_psen				: out std_logic;	-- 1 - шаг изменения фазы
		dcm_psdone				: in  std_logic;	-- 1 - завершена подстройка фазы
		
		
		test					: out std_logic_vector(7 downto 0)
		
		);
end component;

end package ctrl_dcm_phase_v8_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library	unisim;
use unisim.vcomponents.all;

use work.ctrl_clk_detect_v1_pkg.all;

entity ctrl_dcm_phase_v8 is
	generic (			
		CNT0_MIN				: in integer := 448;	-- нижнее значения зоны подстройки
		CNT0_MAX				: in integer := 576;	-- верхнее значение зоны подстройки
	    PHASE_SHIFT 			: in integer := 0;				-- начальное значение сдвига
		CLK_FALLING				: in integer := 0				-- 1 - подстройка под спадающий фронт
	);
	port(
		---- GLOBAL ----
		reset					: in std_logic;		-- 0 - сброс 
		clk						: in std_logic;		-- тактовая частота работы автомата подстройки фазы, 
										
		clk_in_change			: in  std_logic;	-- 1 - изменение входной частоты
		clk_in					: in std_logic;		-- глобальная тактовая частота
		
		clk_fd					: in std_logic;		-- защёлкнутая тактовая частота
		
		phase_tuning_disable	: in std_logic:='0';	-- 1 - запрет подстройки фазы тактовой частоты
		
		shift					: out std_logic_vector(15 downto 0);	-- значение сдвига фазы
		
		locked					: in  std_logic;	-- 1 - захват частоты DCM
		phase_locked			: out std_logic;	-- 1 - произведена подстройка частоты 
		
		dcm_sel_clk		 		: out std_logic;	-- 1 - инверсия входной частоты для MMCM
		dcm_rstp				: out std_logic;	-- 1 - сброс MMCM					
		dcm_psincdec			: out std_logic;	-- направление изменения фазы
		dcm_psen				: out std_logic;	-- 1 - шаг изменения фазы
		dcm_psdone				: in  std_logic;	-- 1 - завершена подстройка фазы
		
		
		test					: out std_logic_vector(7 downto 0)
		
		);
end ctrl_dcm_phase_v8;


architecture ctrl_dcm_phase_v8 of ctrl_dcm_phase_v8 is	


--signal clk_in0				: std_logic;
signal clkfb				: std_logic;
signal psen,psincdec,psdone	: std_logic:='0';
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

signal	clk_fd_z			: std_logic;

signal	pl_enable			: std_logic;	-- 1 - разрешение анализа pl_psincdec
signal	pl_psincdec			: std_logic;	-- предыдущее значение psincdec 
signal	pl_cnt				: std_logic_vector( 4 downto 0 );	-- счётчик изменения psincdec 

signal	pht_dis				: std_logic;

begin  
	
psdone <= dcm_psdone;
dcm_psincdec <= psincdec;
dcm_psen <= psen;	 
dcm_sel_clk <= sel_clk;		 
dcm_rstp <= reset_dcm;

pht_dis <= phase_tuning_disable after 1 ns when rising_edge( clk );
locked0 <= locked  after 1 ns when rising_edge( clk );
	
clkfb <= clk_in;	
--clk_fd_z <= clk_fd after 1 ns when rising_edge( clkfb );

gen_rising: if( CLK_FALLING=0 ) generate
	clk_fd_z <= clk_fd after 0.1 ns when rising_edge( clkfb );
end generate;

gen_falling: if( CLK_FALLING=1 ) generate
	clk_fd_z <= not clk_fd after 0.1 ns when rising_edge( clkfb );
end generate;
	
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

				cnt0_x <= cnt_0;
				if( cnt_0 > CNT0_MAX  ) then
					if( shift_max='0' ) then
						psincdec <= '1' after 1 ns;
						psen <= '1' after 1 ns;
						stp <= s4 after 1 ns;  
					else
						change_clk <= '1' after 1 ns;
					end if;
				elsif( cnt_0 <CNT0_MIN  ) then
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
		
reset_dcm<= change_clk_z or (not reset) or clk_in_change; 



xchange_clk:	srl16 port map( d=>change_clk, clk=>clk, a0=>'1', a1=>'1', a2=>'1', a3=>'1',
							q=>change_clk_z );

							
						
							

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
	
		

reset_ps<= reset and locked;


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
   

end ctrl_dcm_phase_v8;

