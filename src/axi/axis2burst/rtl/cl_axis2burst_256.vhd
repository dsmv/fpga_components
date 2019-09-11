-------------------------------------------------------------------------------
--
-- Title       : cl_axis2burst
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
--
--  Version    : 1.0
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

use work.axis_pkg.all;

entity cl_axis2burst_256 is
	port(
		clk					: in std_logic;
		reset_p				: in std_logic;
		
		--- AXI Stream ---		
		s00_axis_m			: in   M_AXIS_256_TYPE;
		s00_tready			: out  std_logic;
		
		--- AXI Burst Stream ---			 
		m00_axis_m			: out M_AXIS_256U7_TYPE;
		m00_axis_s			: in  S_AXIS_256U1_TYPE 
	
	);
end cl_axis2burst_256;

library unisim;
use unisim.vcomponents.all;

library	ieee;
use	ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

architecture cl_axis2burst_256 of cl_axis2burst_256 is

signal	rstp						: std_logic;
signal	data_i						: std_logic_vector( 255 downto 0 );
signal	data_o						: std_logic_vector( 255 downto 0 );
signal	data_we						: std_logic;
signal	data_ready					: std_logic;
signal	data_we_z					: std_logic;

signal	cnt							: std_logic_vector( 3 downto 0 );
signal	adr							: std_logic_vector( 3 downto 0 );
signal	adr0z						: std_logic_vector( 3 downto 0 );
signal	adr1z						: std_logic_vector( 3 downto 0 );
signal	adr2z						: std_logic_vector( 3 downto 0 );
signal	adr3z						: std_logic_vector( 3 downto 0 );

signal	data_rd						: std_logic;

signal	m_valid						: std_logic;
signal	m_burst_ready				: std_logic;			

type	stp_type					is ( s0, s1 );
signal	stp							: stp_type;
signal	stw							: stp_type;

signal	cnt_rd						: std_logic_vector( 3 downto 0 );
begin
	
rstp <= reset_p	after 1 ns when rising_edge( clk );	
	
s00_tready <=data_ready;	  

data_we <= data_ready and s00_axis_m.tvalid;
data_i <= s00_axis_m.tdata;

data_we_z <= data_we after 1 ns when rising_edge( clk );

gen_srl: for ii in 0 to 63 generate
	
	xsrl0:  srl16e port map( q=> data_o( 0*64+ii ), clk=>clk, ce=>data_we, d=> data_i( 0*64+ii ), a3=>adr0z(3), a2=>adr0z(2), a1=>adr0z(1), a0=>adr0z(0) );
	xsrl1:  srl16e port map( q=> data_o( 1*64+ii ), clk=>clk, ce=>data_we, d=> data_i( 1*64+ii ), a3=>adr1z(3), a2=>adr1z(2), a1=>adr1z(1), a0=>adr1z(0) );
	xsrl2:  srl16e port map( q=> data_o( 2*64+ii ), clk=>clk, ce=>data_we, d=> data_i( 2*64+ii ), a3=>adr2z(3), a2=>adr2z(2), a1=>adr2z(1), a0=>adr2z(0) );
	xsrl3:  srl16e port map( q=> data_o( 3*64+ii ), clk=>clk, ce=>data_we, d=> data_i( 3*64+ii ), a3=>adr3z(3), a2=>adr3z(2), a1=>adr3z(1), a0=>adr3z(0) );

end generate;

--adr0z <= adr after 1 ns when rising_edge( clk );
--adr1z <= adr after 1 ns when rising_edge( clk );
--adr2z <= adr after 1 ns when rising_edge( clk );
--adr3z <= adr after 1 ns when rising_edge( clk );

adr0z <= adr;
adr1z <= adr;
adr2z <= adr;
adr3z <= adr;

pr_data_ready: process( clk ) begin
	if( rising_edge( clk ) ) then
		if( cnt(3)='1' and cnt(2)='1' ) then
			data_ready <= '0' after 1 ns;
		else
			data_ready <= '1' after 1 ns;
		end if;
	end if;
end process;

pr_adr: process( clk ) begin
	if( rising_edge( clk ) ) then
		if( rstp='1' ) then
			adr <= "0000" after 1 ns;
		elsif( data_rd='1' and data_we='0'  ) then
			adr <= adr - 1 after 1 ns;
		elsif( data_rd='0' and data_we='1' ) then
			adr <= adr + 1 after 1 ns;
		end if;
	end if;
end process;	

pr_cnt: process( clk ) begin
	if( rising_edge( clk ) ) then
		if( rstp='1' ) then
			cnt <= "0000" after 1 ns;
		elsif( data_we='1' and data_rd='0' ) then
			cnt <= cnt + 1 after 1 ns;
		elsif( data_we='0' and data_rd='1' ) then
			cnt <= cnt - 1 after 1 ns;
		end if;
	end if;
end process;			

--pr_data_rd: process begin
--	
--	data_rd <= '0' after 1 ns;
--	wait until rising_edge( clk ) and cnt(3)='1' and m_burst_ready='1';
--	data_rd <= '1'  after 1 ns;
--	for ii in 0 to 7 loop
--		wait until rising_edge( clk );
--	end loop;
--end process;	

pr_data_rd: process( clk ) begin
	if( rising_edge( clk )) then
--		if( rstp='1' or cnt_rd(3)='1' ) then
--			data_rd <= '0' after 1 ns;
--		elsif( cnt(3)='1' and m_burst_ready='1' ) then
--			data_rd <= '1' after 1 ns;
--		end if;
--		
--		if( data_rd='0' ) then
--			cnt_rd <= "0001" after 1 ns;
--		else
--			cnt_rd <= cnt_rd + 1 after 1 ns;
--		end if;
--		
		case( stw ) is
			when s0 =>				  
				
				if(  m_burst_ready='1' and cnt(3)='1' and cnt(2)='1' ) then
					data_rd <= '1' after 1 ns;
					stw <= s1 after 1 ns;
				else
					data_rd <= '0' after 1 ns;
				end if;					 
				
			when s1 =>
				if( cnt_rd(3)='1' )then
					if( m_burst_ready='0' or cnt<10 ) then
						data_rd <= '0' after 1 ns;
						stw <= s0 after 1 ns;
					end if;
				end if;
		end case;
		
		if( rstp='1' ) then
			stw <= s0 after 1 ns;
		end if;
				
					
	end if;
end process;				

pr_cnt_rd: process( clk ) begin
	if( rising_edge( clk ) ) then
		if( data_rd='0' or cnt_rd(3)='1' ) then
			cnt_rd <= "0001" after 1 ns;
		else
			cnt_rd <= cnt_rd + 1 after 1 ns;
		end if;
		
	end if;
end process;



pr_out: process( clk ) begin
	if( rising_edge( clk ) ) then
		m_valid 			<= data_rd after 1 ns;
		m00_axis_m.tvalid 	<= data_rd after 1 ns;
		m00_axis_m.tuser( 3 downto 0 ) <= (others=>data_rd) after 1 ns;		 
		m00_axis_m.tlast <= cnt_rd(3) after 1 ns;
	end if;
end process;	

m00_axis_m.tdata <= data_o;

pr_burst_ready: process( clk ) begin
	if( rising_edge( clk ) ) then
		case( stp ) is
			when s0 =>
				m_burst_ready <= '0' after 1 ns;
				if( m00_axis_s.tuser(0)='1' ) then
					stp <= s1 after 1 ns;
				end if;
				
			when s1 =>
				m_burst_ready <= '1' after 1 ns;
				if( m00_axis_s.tuser(0)='0' ) then
					stp <= s0 after 1 ns;
				end if;		 
		end case;
		
		if( rstp='1' ) then
			stp <= s0 after 1 ns;
		end if;
			
	end if;
end process;	

end cl_axis2burst_256;
