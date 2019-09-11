-------------------------------------------------------------------------------
--
-- Title       : tb_00
-- Author      : Dmitry Smekhov
-- Company     : Instrumental Systems
-- E-mail      : dsmv@insys.ru
--
-- Version     : 1.0
--
-------------------------------------------------------------------------------
--
-- Description :  �������� FIFO_v7
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all; 

package tb_00_pkg is
	
component tb_00 is	   
	generic(
		max_time		: in time:=100 us;			-- ������������ ����� ����� 
		period_wr		: in time;	 	-- ������ ������� ������
		period_rd		: in time;		-- ������ ������� ������
		fifo_size		: in integer;	-- ������ FIFO 
		FIFO_PAF		: in integer;	-- ������� ������������ ����� PAF  
		FIFO_PAE		: in integer;	-- ������� ������������ ����� PAE  
		max_fifo0_pkg	: in integer	-- ����� ������� ��� �����
	
	);
end component;

end package;


library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library std;
use std.textio.all;
use work.pck_fio.all;	   
use work.utils_pkg.all;

use work.cl_fifo_x64_v7_pkg.all;   
use work.cl_fifo_m14_pkg.all;   
use work.adm2_pkg.all;

entity tb_00 is	   
	generic(
		max_time		: in time:=100 us;			-- ������������ ����� ����� 
		period_wr		: in time;	 	-- ������ ������� ������
		period_rd		: in time;		-- ������ ������� ������
		fifo_size		: in integer;	-- ������ FIFO 
		FIFO_PAF		: in integer;	-- ������� ������������ ����� PAF  
		FIFO_PAE		: in integer;	-- ������� ������������ ����� PAE  
		max_fifo0_pkg	: in integer	-- ����� ������� ��� �����
	
	);
end tb_00;


architecture tb_00 of tb_00 is			

constant	half_period_wr	: time:=period_wr/2;
constant	half_period_rd	: time:=period_rd/2;



-- �����
signal reset 			: std_logic;			-- 0 - �����
 
-- ������
signal clk_wr 			: std_logic:='0';		-- �������� �������
signal data_in 			: std_logic_vector( 63 downto 0 ):=x"0A00000000000000"; -- ������
signal data_en			: std_logic;			-- 1 - ������ � fifo
signal flag_wr			: bl_fifo_flag;		-- ����� fifo, ��������� � clk_wr
signal cnt_wr			: std_logic_vector( 15 downto 0 ); -- ������� ����

signal f14_cnt_wr			: std_logic_vector( 18 downto 0 ); -- ������� ����
signal f14_cnt_rd			: std_logic_vector( 18 downto 0 ); -- ������� ����

 -- ������
signal clk_rd 			: std_logic:='0';			-- �������� �������
signal data_out 		: std_logic_vector( 63 downto 0 );   -- ������
signal data_cs			: std_logic;			-- 0 - ������ �� fifo
signal flag_rd			: bl_fifo_flag;		-- ����� fifo, ��������� � clk_rd
signal cnt_rd			: std_logic_vector( 15 downto 0 ); -- ������� ����

 
signal rt				: std_logic:='0';	-- 1 - ������� �� ������ � ������������ ������
signal rt_mode			: std_logic:='0';		-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
		 

type type_list_item is record
	
	n_block			: integer;	-- ����� �����
	index			: integer;	-- ������ ������ �����
	expect_data		: std_logic_vector( 63 downto 0 );	-- ��������� ��������
	read_data		: std_logic_vector( 63 downto 0 ); -- �������� ��������
	
end record;	

type type_list_error is array( 31 downto 0 ) of type_list_item;

type  type_result is record

	pkg_rd			: integer;	-- ����� �������� �������
	pkg_ok			: integer;	-- ����� ���������� �������
	pkg_error		: integer;	-- ����� ������������ �������
	total_error		: integer;	-- ����� ����� ������
	velocity		: real;		-- �������� �����/� 
	list_error		: type_list_error;	-- ������ ������
	
end record;	

signal	rx0_result		: type_result;

begin
	
reset <= '0', '1' after 101 ns;

clk_wr <= not clk_wr after half_period_wr;
clk_rd <= not clk_rd after half_period_rd;

pr_data_en: process begin
	data_en <= '0';
	wait for 201 ns;
	
	loop
		wait until rising_edge( clk_wr ) and  flag_wr.paf='1';
		for ii in 0 to FIFO_PAF-1 loop
			data_en <= '1' after 1 ns;
			wait until rising_edge( clk_wr );
		end loop;
		data_en <= '0' after 1 ns;
	end loop;
end process;	
		

pr_data: process( clk_wr ) begin
	if( rising_edge( clk_wr ) ) then
		if( data_en='1' ) then
			data_in <= data_in + 1 after 1 ns;
		end if;
	end if;
end process;	

fifo_7: cl_fifo_x64_v7 
	generic map(
		FIFO_SIZE 	=> fifo_size
	)
	 port map(				
	 	-- �����
		 reset 				=> reset,			-- 0 - �����
		 
	 	-- ������
		 clk_wr 			=> clk_wr,		-- �������� �������
		 data_in 			=> data_in, 	-- ������
		 data_en			=> data_en,		-- 1 - ������ � fifo
		 --flag_wr			=> flag_wr,		-- ����� fifo, ��������� � clk_wr
		 cnt_wr				=> cnt_wr,		-- ������� ����
		 
		 -- ������
		 clk_rd 			=> clk_rd,		-- �������� �������
		 --data_out 			=> data_out,	-- ������
		 data_cs			=> data_cs,		-- 0 - ������ �� fifo
		 --flag_rd			=> flag_rd,		-- ����� fifo, ��������� � clk_rd
		 cnt_rd				=> cnt_rd,			-- ������� ����

		 
		 rt					=> rt,			-- 1 - ������� �� ������ � ������������ ������
		 rt_mode			=> rt_mode		-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
		 
	    );	
		
fifo_14: cl_fifo_m14
	generic map(
		FIFO_WIDTH			=> 64,			-- ������ FIFO
		FIFO_SIZE			=> fifo_size,	-- ������ FIFO 
		FIFO_PAF			=> FIFO_PAF,	-- ������� ������������ ����� PAF  
		FIFO_PAE			=> FIFO_PAE		-- ������� ������������ ����� PAE  
		)
	 port map(				
	 	-- �����
		 reset 				=> reset,			-- 0 - �����
		 
	 	-- ������
		 clk_wr 			=> clk_wr,		-- �������� �������
		 data_in 			=> data_in, 	-- ������
		 data_en			=> data_en,		-- 1 - ������ � fifo
		 flag_wr			=> flag_wr,		-- ����� fifo, ��������� � clk_wr
		 cnt_wr				=> f14_cnt_wr,		-- ������� ����
		 
		 -- ������
		 clk_rd 			=> clk_rd,		-- �������� �������
		 data_out 			=> data_out,	-- ������
		 data_cs			=> data_cs,		-- 0 - ������ �� fifo
		 flag_rd			=> flag_rd,		-- ����� fifo, ��������� � clk_rd
		 cnt_rd				=> f14_cnt_rd,			-- ������� ����

		 
		 rt					=> rt,			-- 1 - ������� �� ������ � ������������ ������
		 rt_mode			=> rt_mode		-- 1 - ������� �� ������ ����� ������ ����� ����������� FIFO
		 
	    );			
		
pr_data_cs: process begin
	data_cs <= '1';
	wait for 201 ns;
	
	loop
		wait until rising_edge( clk_rd ) and  flag_rd.pae='1';
		for ii in 0 to FIFO_PAE-1 loop
			data_cs <= '0' after 1 ns;
			wait until rising_edge( clk_rd );
		end loop;
		data_cs <= '1' after 1 ns;
	end loop;
end process;




pr_rx0_data: process( clk_rd ) 

variable	rx0_data			: std_logic_vector( 63 downto 0 );
variable	index				: integer:=0;  
variable	index_error			: integer:=0;
variable	block_rd			: integer:=0;
variable	block_ok			: integer:=0;
variable	block_error			: integer:=0;	   
variable	flag_error			: integer:=0;

variable	tm_start			: time;
variable	tm_stop				: time;
variable	byte_send			: real;
variable	tm					: real;
variable	velocity			: real:=0.0;
variable	tm_pkg				: time:=0 ns;
variable	tm_pkg_delta		: time:=0 ns;
variable	block_for_rdy		: integer:=0;

variable L 	: line;

begin
	if( rising_edge( clk_rd ) ) then
		if( reset='0' ) then
			rx0_data( 63 downto 0 ) := x"0A00000000000000";
			
			rx0_result.pkg_rd <= 0;
			rx0_result.pkg_ok <= 0;
			rx0_result.pkg_error <= 0;
			rx0_result.total_error <= 0;
			rx0_result.velocity <= 0.0;
			rx0_result.list_error <= (others=>(	0, 0, (others=>'0'), (others=>'0')));
			
			
		elsif( data_cs='0' ) then
			
			if( data_out/=rx0_data ) then
				if( index_error < 32 ) then
					rx0_result.list_error( index_error ).n_block 	 <= block_rd;
					rx0_result.list_error( index_error ).index 		 <= index;
					rx0_result.list_error( index_error ).expect_data <= rx0_data;
					rx0_result.list_error( index_error ).read_data 	 <= data_out;
					
				fprint( output, L, "FIFO 0 - ERROR - Block: %5r Index: %5r Expected %20r   Read: %20r \n", 
				   fo(block_rd), fo(index), fo(rx0_data), fo(data_out) );
					
				end if;
				index_error:=index_error+1;		 
				rx0_result.total_error <= index_error;
				flag_error:=1;
			end if;
			
--			if( index=250 ) then
--				if( block_for_rdy=2 ) then
--					m2_fifo_rdy(2) <= '0', '1' after rx_fifo2_pause;
--					block_for_rdy:=0;
--				else
--					block_for_rdy:=block_for_rdy+1;
--				end if;
--			end if;
			
			if( index=255 ) then
				if( flag_error=0 ) then
					block_ok := block_ok + 1;
				else
					block_error := block_error + 1;
				end if;
				block_rd := block_rd + 1;
				
				rx0_result.pkg_rd <= block_rd;
				rx0_result.pkg_ok <= block_ok;
				rx0_result.pkg_error <= block_error;
				
				flag_error:=0;
				
				if( block_rd=1 ) then
					tm_start:=now;	 
					tm_pkg:=now;
				end if;
				
				if( block_rd>1 ) then
					byte_send:=real(block_rd-1)*256.0*32.0;
					tm := real(now / 1 ns )-real(tm_start/ 1 ns);
					velocity := byte_send*1000000000.0/(tm*1024.0*1024.0);
					rx0_result.velocity <= velocity;
				end if;				
				
				tm_pkg_delta := now - tm_pkg;
				fprint( output, L, "FIFO 0 - PKG=%3d  %10r ns %10r ns ERROR: %10r  SPEED: %10r\n", fo(block_rd), fo(now), fo(tm_pkg_delta), fo(index_error), fo(integer(velocity)) );
				tm_pkg:=now;
				index:=0;	
				
					
			else
				index:=index+1;
			end if;
			
			rx0_data := rx0_data + 1;		
			
		end if;
	end if;
end process;


pr_rx_data: process 

variable	expect_data 		: std_logic_vector( 31 downto 0 ):= x"AB000000";
variable	error_cnt			: integer:=0;
variable	pkg_cnt				: integer:=0;
variable	pkg_ok				: integer:=0;
variable	pkg_error			: integer:=0;
variable	index				: integer;
variable	flag_error			: integer;
variable	tm_start			: time;
variable	tm_stop				: time;
variable	byte_send			: real;
variable	tm					: real;
variable	velocity			: real;
variable	tm_pkg				: time:=0 ns;
variable	tm_pkg_delta		: time:=0 ns;


variable L 	: line;

begin
--	m2_rx_data_rd <= '0';  
--	m2_rx_data_eof <= '0'; 
	
	
--	tx1_data( 255 downto 32 ) <= (others=>'0');
--	tx1_data( 31 downto 0 ) <= x"F5000000";	
--	
	--fprint( output, L, "������ ������\n" );
	
	wait for 200 ns;
	
	loop

		if( now>max_time ) then
			 exit;
		end if;
		
		
		
		if( (rx0_result.pkg_rd >= max_fifo0_pkg)  ) then
			exit;
		end if;

		wait for 1 us;
	end loop;	  
	
	tm_stop:=now;
	
	fprint( output, L, "�������� ���� ������: %r ns\n", fo(now) );
	fprint( output, L, "FIFO 0 \n" );
	fprint( output, L, " ������� �������:    %d\n", fo( rx0_result.pkg_rd ) );
	fprint( output, L, " ����������:         %d\n", fo( rx0_result.pkg_ok ) );
	fprint( output, L, " ���������:          %d\n", fo( rx0_result.pkg_error ) );
	fprint( output, L, " ����� ����� ������: %d\n", fo( rx0_result.total_error ) );
	fprint( output, L, " �������� ��������: %r �����/�\n\n", fo( integer(rx0_result.velocity) ) );


	
--	byte_send:=real(pkg_cnt)*256.0*4.0;
--	tm := real(tm_stop/ 1 ns )-real(tm_start/ 1 ns);
--	velocity := byte_send*1000000000.0/(tm*1024.0*1024.0);
--	
--	fprint( output, L, " �������� ��������: %r �����/�\n", fo( integer(velocity) ) );
	
	flag_error:=0;
	if( max_fifo0_pkg>0 and rx0_result.pkg_rd<max_fifo0_pkg ) then
		flag_error:=1;
	end if;

	
--	if( fi0_ovr='1' ) then
--		fprint( output, L, "\n\nERROR - FIFO 0 overflow \n\n" );
--		flag_error:=1;
--	end if;
--
	

	
	if( flag_error=0 and rx0_result.total_error=0  ) then
		--fprint( output, L, "\n\n���� �������� �������\n\n" );
		fprint( output, L, "\n\nTEST finished successfully\n\n" );
	else
		--fprint( output, L, "\n\n���� �������� � ��������\n\n" );
		fprint( output, L, "\n\nTEST finished with ERR\n\n" );
	end if;
	
	utils_stop_simulation;
	
	wait;
	
end process;	
	


end tb_00;
