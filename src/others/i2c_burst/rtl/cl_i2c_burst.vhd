-------------------------------------------------------------------------------
--
-- Title       : cl_i2c_burst
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
-- E-mail      : dsmv@insys.ru
--
-- Version     : 1.0
--
--
-------------------------------------------------------------------------------
--
-- Description : 	Узел подключения к шине I2C
--					Используется только один регистр для подключение
--
--		Формат регистра на запись:
--			7..0:	DATA:	байт данных
--			13..8:	-		- резерв
--			14:	  	REQ_TS	- 1 - запрос на выполнение транзакции
--			15:		REQ_BUS	- 1 - запрос на обращение к шине
--
--		Формат регистра на чтение:
--			7..0:	DATA:	байт данных
--			11..8:	CNT:	номер байта
--			12:		DATA_ACK	- занчение бита ACK
--			13:		PAF:		- 1 - разрешение передачи одного байта
--			14:		RUN:		- 1 - выполнение транзакции
--			15:		GRANT_BUS:	- 1 - разрешение доступа к шине
--			31..16: SIG:		- 0x12C0 - сигнатура, признак наличия узла
--																		  
--
--		Алгоритм работы:
--			Сформировать пакет данных.
--			В цикле проводить запись пакета в регистр и чтение данных из регистра.
--			  Запись можно проводить только при значении PAF=1
--			  При чтении надо контролировать поле CNT. При изменении значения поля следует
--			  сохранить байт данных в выходном пакете.
--			После получения всех ожидаемых данных надо дождаться RUN=0 и записать 0 в регистр.
--			Провести анализ принятого пакета данных.
--												   
--
--
--		Узел не поддерживает приостановку обмена через удержание SCL=0 со стороны SLAVE
--
-------------------------------------------------------------------------------
--
--  Version 1.0   
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;


entity cl_i2c_burst is	   
	port(
		reset				: in std_logic;	-- 0 - сброс
		clk					: in std_logic;
		clkx				: in std_logic;
		
		data_o				: out std_logic_vector( 31 downto 0 );
		data_i				: in  std_logic_vector( 31 downto 0 );
		data_we				: in  std_logic;		
		data_rd				: in  std_logic;
		
		scl_o				: out std_logic;
		sda_o				: out std_logic;
		sda_i				: in  std_logic;
		i2c_req				: out std_logic;
		i2c_ack				: in  std_logic
	
	);
end cl_i2c_burst;


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
--use work.cl_fifo_m12_pkg.all;	 
use work.adm2_pkg.all;

architecture cl_i2c_burst of cl_i2c_burst is

signal	rstp0					: std_logic;
signal	rstp1					: std_logic;
signal	rstp					: std_logic;
signal	reg_rstp				: std_logic;

signal	fi_flag_wr 				: bl_fifo_flag;
signal	fi_flag_rd  			: bl_fifo_flag;
signal	fi_data					: std_logic_vector( 15 downto 0 );    	
signal	fi_data_i				: std_logic_vector( 15 downto 0 );    	
signal	fi_fifo_rd				: std_logic; 

signal	data_i_rp				: std_logic_vector( 15 downto 0 );
signal	data_we_z				: std_logic;
signal	data_we_rp				: std_logic;		 
signal	data_rd_z				: std_logic;

type	stp_type				is ( s0, s1, s2, s3, s4, s5, s6, s7, s8 );
signal	stp						: stp_type;

type	stw_type				is ( s0, s1, s2, s3_0, s4_1, s3, s4, s5, s6, s6_1, s7, s8, s9 );
signal	stw						: stw_type;

signal i2c_ack_z				: std_logic;
signal stp_rstp 					: std_logic;

signal	state_tz				: std_logic;	-- 1 - идёт операция
signal	state_rw				: std_logic; 	-- 1 - чтение, 0 - запись

signal	clkx_z1					: std_logic;
signal	clkx_z2					: std_logic;
signal	clkx_z3					: std_logic;

signal	clk_step_cnt			: std_logic_vector( 1 downto 0 ):="00";
signal	clk_step_0				: std_logic;
signal	clk_step_1				: std_logic;
signal	clk_step_r				: std_logic;
signal	clk_step_f				: std_logic;
signal	clk_step				: std_logic;

signal	tz_start_req 				: std_logic;
signal  tz_start_complete			: std_logic;
signal	tz_send_req 				: std_logic;
signal  tz_send_complete			: std_logic;
signal	tz_stop_req 				: std_logic;
signal  tz_stop_complete			: std_logic;

signal	reg_shift					: std_logic_vector( 7 downto 0 );
signal	cnt_sda						: std_logic_vector( 3 downto 0 );

signal	first_byte					: std_logic; -- 1 - переадача первого байта (байта команды)
signal	cmd_ack						: std_logic;
signal	data_ack					: std_logic;	  
signal	reg_shift_in				: std_logic_vector( 8 downto 0 );
signal	dataw_cnt					: std_logic_vector( 3 downto 0 );

signal	fo_data_we					: std_logic;
signal	fo_data_we_z				: std_logic;
signal	fo_data_i					: std_logic_vector( 12 downto 0 );
signal	fo_data_i_z					: std_logic_vector( 12 downto 0 );
signal	fo_flag_rd					: bl_fifo_flag;
signal	fo_data_o					: std_logic_vector( 12 downto 0 );
signal	fo_data_rd					: std_logic;

signal	first_bit 					: std_logic;
signal	sda_i_z						: std_logic;



begin
	
clkx_z1 <=	clkx after 1 ns when rising_edge( clk );
clkx_z2 <=	clkx_z1 after 1 ns when rising_edge( clk );
clkx_z3 <=	clkx_z2 after 1 ns when rising_edge( clk );

clk_step <= clkx_z2 and not clkx_z3 after 1 ns when rising_edge( clk );

clk_step_cnt <= clk_step_cnt+1 after 1 ns when rising_edge( clk ) and clk_step='1';
clk_step_0  <= clk_step and  not clk_step_cnt(1) and  not clk_step_cnt(0) after 1 ns when rising_edge( clk );	  -- clk_step_cnt="00"
clk_step_1  <= clk_step and      clk_step_cnt(1) and  not clk_step_cnt(0) after 1 ns when rising_edge( clk );	  -- clk_step_cnt="10"
clk_step_r  <= clk_step and  not clk_step_cnt(1) and      clk_step_cnt(0) after 1 ns when rising_edge( clk );	  -- clk_step_cnt="01"
clk_step_f  <= clk_step and      clk_step_cnt(1) and      clk_step_cnt(0) after 1 ns when rising_edge( clk );	  -- clk_step_cnt="11"

sda_i_z <= sda_i after 1 ns when rising_edge( clk );
	
rstp0 <= not reset after 1 ns when rising_edge( clk );
rstp1 <= rstp0 after 1 ns when rising_edge( clk );

rstp <= rstp1 or reg_rstp after 1 ns when rising_edge( clk );

i2c_req <= not rstp after 1 ns when rising_edge( clk );

pr_reg_rstp: process( clk ) begin
	if( rising_edge( clk ) ) then
		if( rstp1='1' ) then
			reg_rstp <= '1' after  ns ;
		elsif( data_we='1' ) then
			reg_rstp <= not data_i(15) after 1 ns;
		end if;
	end if;
end process;			

--data_we_z <= data_we after 1 ns when rising_edge( clk );
--data_we_rp <= data_we or data_we_z after 1 ns when rising_edge( clk );
--
--pr_data_i_rp: process( clk ) begin
--	if( rising_edge( clk ) ) then
--		if(  data_we_z='0' ) then
--			data_i_rp <= data_i( 15 downto 0 ) after 1 ns;
--		else
--			data_i_rp <= data_i( 16+15 downto 16+0 ) after 1 ns;
--		end if;
--	end if;
--end process;
--

--fifo_i: cl_fifo_m12 
--	generic map(
--	    FIFO_WIDTH          => 16,     -- ширина FIFO
--	    FIFO_SIZE           => 64,     -- размер FIFO 
--	    FIFO_PAF            => 4,      -- уровень срабатывания флага PAF  
--	    FIFO_PAE            => 4       -- уровень срабатывания флага PAE  
-- )
-- port map(                
--     reset_p            => rstp,
--     clk_wr             => clk,
----     data_in            => data_i_rp,
----     data_en            => data_we_rp,
--     data_in            => data_i( 15 downto 0 ),
--     data_en            => data_we,
--
--     flag_wr            => fi_flag_wr,
--     clk_rd             => clk,
--     data_out           => fi_data,
--     data_rd            => fi_fifo_rd,
--     flag_rd            => fi_flag_rd
--     
--    );
--	

pr_fifo_i: process( clk ) begin
	if( rising_edge( clk ) ) then
		if( rstp='1' ) then
			fi_data_i <= (others=>'0') after 1 ns;
		elsif( data_we='1' ) then
			fi_data_i <= data_i( 15 downto 0 ) after 1 ns;
		end if;
		
		if( rstp='1' or fi_fifo_rd='1' ) then
			fi_flag_rd.ef <= '0' after 1 ns;
		elsif( data_we='1' ) then
			fi_flag_rd.ef <= '1' after 1 ns;
		end if;

		if( rstp='1' ) then 
			fi_data <= (others=>'0') after 1 ns;
		elsif( fi_fifo_rd='1' ) then
			fi_data <= fi_data_i after 1 ns; 
		end if;
		
	end if;
end process;

i2c_ack_z <= i2c_ack	after 1 ns when rising_edge( clk ); 	
stp_rstp <= rstp or not i2c_ack_z after 1 ns when rising_edge( clk ); 	
	
pr_stp: process( clk ) begin
	if( rising_edge( clk ) ) then
		case( stp ) is
			when s0 =>				
				tz_start_req <= '0' after 1 ns;
				tz_stop_req <= '0' after 1 ns;
				tz_send_req <= '0' after 1 ns;
				if(  fi_flag_rd.ef='1'  and fo_flag_rd.hf='1' ) then -- передача начинается когда есть данные во входном регистре и место в выходном регистре
					fi_fifo_rd <= '1' after 1 ns;
					stp <= s1 after 1 ns;
				end if;
				
			when s1 =>
				fi_fifo_rd <= '0' after 1 ns;
				stp <= s2 after 1 ns;

			when s2 =>
				fi_fifo_rd <= '0' after 1 ns;
				stp <= s3 after 1 ns;
				
			when s3 =>
				stp <= s4 after 1 ns;

			when s4 =>
				if( state_tz='0' ) then			
					--- На данный момент нет операции ---
					if( fi_data(14)='1' ) then
						--- Начало операции ---
						state_rw <= fi_data(0) after 1 ns;
						
						stp <= s5 after 1 ns;
						tz_start_req <= '1' after 1 ns;
						
						state_tz <= '1' after 1 ns;
					else   
						--- Пропуск слова ---
						stp <= s0 after 1 ns;
					end if;
				else
					--- На данный момент идёт операция ----
					
					if( fi_data(14)='1' ) then
						--- Начало очередной операции ---
						stp <= s6 after 1 ns;
					else   	   
						if( state_rw='1' ) then
							--- Если это операция чтения, то её нужно выполнить ---
							stp <= s6 after 1 ns;
						else
							--- Завершение операции ---
							stp <= s8 after 1 ns;
						end if;
					end if;
					
				end if;
				
			when s5 =>
				if( tz_start_complete='1' ) then	  
					tz_start_req <= '0' after 1 ns;
					stp <= s6 after 1 ns;
				end if;
				
			when s6 =>
				tz_send_req <= '1' after 1 ns;
				stp <= s7 after 1 ns;
			when s7 =>
				if( tz_send_complete='1' ) then
					tz_send_req <= '0' after 1 ns;
					stp <= s0 after 1 ns;
					if( fi_data(14)='0' ) then
						stp <= s8 after 1 ns;
					else
						stp <= s0 after 1 ns;
					end if;
				end if;	   
				
			when s8 =>
				tz_stop_req <= '1' after 1 ns;
				if( tz_stop_complete='1' ) then
					tz_stop_req <= '0' after 1 ns;
					stp <= s0 after 1 ns;
					state_tz <= '0' after 1 ns;
				end if;
				
				
			when others => null;				
				
			
		end case;
		
		if( stp_rstp='1' ) then	
			state_tz <= '0';
			state_rw <= '0';
			fi_fifo_rd <= '0' after 1 ns;
			stp <= s0 after 1 ns;
		end if;
	end if;
end process;


pr_stw: process( clk ) begin
	if( rising_edge( clk ) ) then
		case( stw ) is
			when s0 =>				   
				first_bit <= '0' after 1 ns;
				tz_start_complete <= '0' after 1 ns;
				tz_stop_complete <= '0' after 1 ns;
				tz_send_complete <= '0' after 1 ns;
				fo_data_we <= '0' after 1 ns;
				
				if( tz_start_req='1' and  clk_step_0='1' ) then
					stw <= s1 after 1 ns;
				end if;		   
				
				reg_shift <= fi_data( 7 downto 0 ) after 1 ns;
				cnt_sda <= "0000" after 1 ns;
				
				if( tz_send_req='1' and clk_step_0='1' ) then
					if( first_byte='1' ) then
						stw <= s3 after 1 ns;
					else
						stw <= s3_0 after 1 ns;
					end if;
				end if;			
				
				if( tz_stop_req='1' and clk_step_0='1' ) then
					stw <= s7 after 1 ns;
				end if;
					
				
			when s1 => -- START
				if( clk_step_1='1' ) then
					sda_o <= '0' after 1  ns;  
				end if;
				first_byte <= '1' after 1 ns;
				cmd_ack <= '0' after 1 ns;
				data_ack <= '0' after  1 ns;
				if( clk_step_f='1' ) then
					scl_o <= '0' after 1 ns;
					stw <= s2 after 1 ns;
				end if;
				
			when s2 =>
				tz_start_complete <= '1' after 1 ns;
				if( tz_start_req='0' ) then
					stw <= s0 after 1 ns;
				end if;
				
			when s3_0 =>
				if( clk_step_0='1' ) then
					stw <= s3 after 1 ns;
					scl_o <= '0' after 1 ns;
				end if;		 
				first_bit <= '1' after 1 ns;
			
				
			when s3 =>								  
				if( state_rw='0'  or first_byte='1' ) then
					-- цикл записи или команда --	
					sda_o <= reg_shift(7) or cnt_sda(3) after 1 ns; -- 9-й бит не передаётся
				else			
					if( cnt_sda(3)='0' ) then
						sda_o <= '1' after 1 ns;	-- читаем данные
					else   
						sda_o <= not fi_data(14) after 1 ns; -- для последнего слова в пакете не даём подтверждения
					end if;
				end if;
				stw <= s4 after 1 ns;
				
			when s4 =>
				reg_shift <= reg_shift( 6 downto 0 ) & '0' after 1 ns;
				cnt_sda <= cnt_sda+1 after 1 ns;
				if( first_bit='1' ) then 
					stw <= s4_1 after 1 ns;
				else
					stw <= s5 after 1 ns;
				end if;
			when s4_1 =>
				if( clk_step_0='1' ) then
					stw <= s5 after 1 ns;
				end if;
				
			when s5 =>		 
				first_bit <= '0' after 1 ns;
				if( clk_step_r='1' ) then
					scl_o <= '1' after 1 ns;
					
					if( cnt_sda(3)='1' and cnt_sda(0)='1' ) then  -- cnt_sda="1001"
						stw <= s6 after 1 ns;
						
						
						data_ack <=  sda_i_z after 1 ns;
--						if( first_byte='1' ) then
--							cmd_ack <= sda_i_z after 1 ns;
--						else
--							data_ack <=  sda_i_z after 1 ns;
--						end if;
						
						dataw_cnt <= dataw_cnt + 1 after 1 ns;
						fo_data_we <= '1' after 1 ns;
					end if;
					
					
					reg_shift_in <= reg_shift_in( 7 downto 0 ) & sda_i_z after 1 ns;
					
				end if;
				
				if( clk_step_f='1' ) then
					scl_o <= '0' after 1 ns;
				end if;
				
				if( clk_step_0='1' ) then
					stw <= s3 after 1 ns;
				end if;
				
			when s6 => 	  	
				fo_data_we <= '0' after 1 ns;
				first_byte <= '0' after 1 ns;			   
				if( clk_step_f='1' ) then
					scl_o <= '0' after 1 ns;
					stw <= s6_1 after 1 ns;
				end if;
				
				
			when s6_1 =>
				tz_send_complete <= '1' after 1 ns;
				if( tz_send_req='0' ) then
					stw <= s0 after 1 ns;
				end if;
				
			when s7 => --- STOP ---
				sda_o <= '0' after 1 ns;
				if( clk_step_r='1' ) then
					scl_o <= '1' after  1 ns;
					stw <= s8 after 1 ns;
				end if;
				
			when s8 =>
				if( clk_step_1='1' ) then
					stw <= s9 after 1 ns;
				end if;						   
			
			when s9 =>
				sda_o <= '1' after 1 ns;
				tz_stop_complete <= '1' after 1 ns;
				if( tz_stop_req='0' ) then
					stw <= s0 after 1 ns;
				end if;
				
			when others => null;
				
					
		
		end case;
		
		if( stp_rstp='1' ) then
			first_byte <= '0' after 1 ns;
			scl_o 	<= '1' after 1 ns;
			sda_o  	<= '1' after 1 ns;	
			stw <= s0 after 1 ns;  
			dataw_cnt <= "0000" after 1 ns;
		end if;
		
	end if;
end process;

fo_data_i( 7 downto 0 ) <= reg_shift_in( 8 downto 1 );
fo_data_i( 11 downto 8 ) <= dataw_cnt;
fo_data_i(12) <= data_ack;

--fifo_0: cl_fifo_m12 
--	generic map(
--	    FIFO_WIDTH          => 13,     -- ширина FIFO
--	    FIFO_SIZE           => 64,     -- размер FIFO 
--	    FIFO_PAF            => 4,      -- уровень срабатывания флага PAF  
--	    FIFO_PAE            => 4       -- уровень срабатывания флага PAE  
-- )
-- port map(                
--     reset_p            => rstp,
--     clk_wr             => clk,
--     data_in            => fo_data_i,
--     data_en            => fo_data_we_z,
--     --flag_wr            => fi_flag_wr,
--     clk_rd             => clk,
--     data_out           => fo_data_o,
--     data_rd            => fo_data_rd,
--     flag_rd            => fo_flag_rd
--     
--    );	

pr_fo_data_i_z: process( clk ) begin
	if( rising_edge( clk ) ) then
		if( rstp='1' ) then
			fo_data_i_z <= (others=>'0') after 1 ns;
		elsif( fo_data_we_z='1' ) then
			fo_data_i_z <= fo_data_i after 1 ns;
		end if;
	end if;
end process;

pr_fo_data_o: process( clk ) begin
	if( rising_edge( clk ) ) then
		if( rstp='1' ) then
			fo_data_o <= (others=>'0') after 1 ns;
		elsif( fo_data_rd='1' ) then
			fo_data_o <= fo_data_i_z after 1 ns;
		end if;
	end if;
end process;	  

pr_fo_flag_hf: process( clk )  begin
	if( rising_edge( clk ) ) then
		if( rstp='1' or fo_data_rd='1' ) then
			fo_flag_rd.hf <= '1' after 1 ns;
		elsif( fo_data_we_z='1' ) then
			fo_flag_rd.hf <= '0' after 1 ns;
		end if;
	end if;
end process;
	
fo_flag_rd.ef <= not fo_flag_rd.hf after 1 ns when rising_edge( clk ); -- это нужно что бы исключить одновременное появление fo_data_rd и fo_data_we_z

data_rd_z <= data_rd after 1 ns when rising_edge( clk );
fo_data_rd <= data_rd and not data_rd_z and fo_flag_rd.ef after 1 ns when rising_edge( clk );
--fo_data_rd <= data_rd and not data_rd_z after 1 ns when rising_edge( clk );

fo_data_we_z <= fo_data_we after 1 ns when rising_edge( clk );

data_o( 31 downto 16 ) <= x"12C0";
data_o( 15 ) <= i2c_ack_z after 1 ns when rising_edge( clk );
data_o( 14 ) <= state_tz after 1 ns when rising_edge( clk ); 
--data_o( 13 ) <= fo_flag_rd.hf and fi_flag_wr.hf after 1 ns when rising_edge( clk ); -- операции разрешены когда есть место в обоих FIFO
data_o( 13 ) <= not fi_flag_rd.ef after 1 ns when rising_edge( clk ); -- операции разрешены когда записанное слово ушло в сдвиговый регистр на передачу в I2C
data_o( 12 downto 0 ) <= fo_data_o;

end cl_i2c_burst;
